
require "search_cop"

begin
  require "minitest"

  class SearchCop::TestCase < MiniTest::Test; end
rescue LoadError
  require "minitest/unit"

  class SearchCop::TestCase < MiniTest::Unit::TestCase; end
end

require "minitest/autorun"
require "active_record"
require "factory_girl"
require "yaml"

DATABASE = ENV["DATABASE"] || "sqlite"

ActiveRecord::Base.establish_connection YAML.load_file(File.expand_path("../database.yml", __FILE__))[DATABASE]

class User < ActiveRecord::Base; end

class Comment < ActiveRecord::Base
  include SearchCop

  belongs_to :user

  search_scope :search do
    attributes :user => "user.username"
    attributes :title, :message
  end
end

class Product < ActiveRecord::Base
  include SearchCop

  search_scope :search do
    attributes :title, :description, :brand, :notice, :stock, :price, :created_at, :created_on, :available, :aggregated_column
    attributes :comment => ["comments.title", "comments.message"], :user => ["users.username", "users_products.username"]
    attributes :primary => [:title, :description]

    aliases :users_products => :user

    if DATABASE != "sqlite"
      options :title, :type => :fulltext
      options :description, :type => :fulltext
      options :comment, :type => :fulltext
    end

    if DATABASE == "postgres"
      options :title, :dictionary => "english"
    end

    type :aggregated_column, :float
  end

  search_scope :user_search do
    scope { joins "LEFT OUTER JOIN users users_products ON users_products.id = products.user_id" }

    attributes :title, :description
    attributes :user => "users_products.username"

    options :title, :default => true
    aliases :users_products => User
  end

  has_many :comments
  has_many :users, :through => :comments

  belongs_to :user
end

FactoryGirl.define do
  factory :product do
  end

  factory :comment do
  end

  factory :user do
  end
end

ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS products"
ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS comments"
ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS users"

ActiveRecord::Base.connection.create_table :products do |t|
  t.references :user
  t.string :title
  t.text :description
  t.integer :stock
  t.float :price
  t.datetime :created_at
  t.date :created_on
  t.boolean :available
  t.string :brand
  t.string :notice
end

ActiveRecord::Base.connection.create_table :comments do |t|
  t.references :product
  t.references :user
  t.string :title
  t.text :message
end

ActiveRecord::Base.connection.create_table :users do |t|
  t.string :username
end

if DATABASE == "mysql"
  ActiveRecord::Base.connection.execute "ALTER TABLE products ENGINE=MyISAM"
  ActiveRecord::Base.connection.execute "ALTER TABLE products ADD FULLTEXT INDEX(title), ADD FULLTEXT INDEX(description), ADD FULLTEXT INDEX(title, description)"

  ActiveRecord::Base.connection.execute "ALTER TABLE comments ENGINE=MyISAM"
  ActiveRecord::Base.connection.execute "ALTER TABLE comments ADD FULLTEXT INDEX(title, message)"
end

class SearchCop::TestCase
  include FactoryGirl::Syntax::Methods

  def teardown
    Product.delete_all
    Comment.delete_all
  end

  def with_options(scope, key, options = {})
    opts = scope.reflection.options[key.to_s] || {}

    scope.reflection.options[key.to_s] = opts.merge(options)

    yield
  ensure
    scope.reflection.options[key.to_s] = opts
  end

  def with_scope(scope, blk)
    orig = scope.reflection.scope

    scope.reflection.scope = blk

    yield
  ensure
    scope.reflection.scope = orig
  end

  def assert_not_nil(value)
    assert value
  end

  def assert_nothing_raised
    yield
  end

  def quote_table_name(name)
    ActiveRecord::Base.connection.quote_table_name name
  end

  def quote_column_name(name)
    ActiveRecord::Base.connection.quote_column_name name
  end

  def quote(object)
    ActiveRecord::Base.connection.quote object
  end
end

