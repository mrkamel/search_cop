
require "attr_searchable"

begin
  require "minitest"

  class AttrSearchable::TestCase < MiniTest::Test; end
rescue LoadError
  require "minitest/unit"

  class AttrSearchable::TestCase < MiniTest::Unit::TestCase; end
end

require "minitest/autorun"
require "active_record"
require "factory_girl"
require "yaml"

DATABASE = ENV["DATABASE"] || "sqlite"

ActiveRecord::Base.establish_connection YAML.load_file(File.expand_path("../database.yml", __FILE__))[DATABASE]

class User < ActiveRecord::Base; end

class Comment < ActiveRecord::Base
  include AttrSearchable

  belongs_to :user

  attr_searchable :user => "user.username"
  attr_searchable :title, :message
end

class Product < ActiveRecord::Base
  include AttrSearchable

  attr_searchable :title, :description, :brand, :notice, :stock, :price, :created_at, :created_on, :available
  attr_searchable :comment => ["comments.title", "comments.message"], :user => ["users.username", "users_products.username"]
  attr_searchable :primary => [:title, :description]

  attr_searchable_alias :users_products => :user

  if DATABASE != "sqlite"
    attr_searchable_options :title, :type => :fulltext
    attr_searchable_options :description, :type => :fulltext
    attr_searchable_options :comment, :type => :fulltext
  end

  if DATABASE == "postgres"
    attr_searchable_options :title, :dictionary => "english"
  end

  attr_searchable_scope :user_search do
    attr_searchable :title, :description
    attr_searchable :user => "users_products.username"

    attr_searchable_options :title, :default => true
    attr_searchable_alias :users_products => :user
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

class AttrSearchable::TestCase
  include FactoryGirl::Syntax::Methods

  def teardown
    Product.delete_all
    Comment.delete_all
  end

  def with_attr_searchable_options(model, scope, key, options = {})
    model.searchable_attribute_options[scope] ||= {}

    opts = model.searchable_attribute_options[scope][key.to_s] || {}

    model.searchable_attribute_options[scope][key.to_s] = opts.merge(options)

    yield
  ensure
    model.searchable_attribute_options[scope][key.to_s] = opts
  end
end

