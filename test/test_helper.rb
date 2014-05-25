
require "attr_searchable"
require "minitest"
require "minitest/autorun"
require "active_record"
require "factory_girl"
require "yaml"

DATABASE = ENV["DATABASE"] || "sqlite"

ActiveRecord::Base.establish_connection YAML.load_file(File.expand_path("../database.yml", __FILE__))[DATABASE]

class Comment < ActiveRecord::Base; end

class Product < ActiveRecord::Base
  include AttrSearchable

  attr_searchable :title, :description, :brand, :stock, :price, :created_at, :available
  attr_searchable :comment => ["comments.title", "comments.message"]

  if DATABASE != "sqlite"
    attr_searchable_options :title, :type => :fulltext
    attr_searchable_options :comment, :type => :fulltext
  end

  if DATABASE == "postgres"
    attr_searchable_options :title, :dictionary => "english"
  end

  attr_searchable_options :brand, :left_wildcard => false

  has_many :comments
end

FactoryGirl.define do
  factory :product do
  end

  factory :comment do
  end
end

ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS products"
ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS comments"

ActiveRecord::Base.connection.create_table :products do |t|
  t.string :title
  t.text :description
  t.integer :stock
  t.float :price
  t.datetime :created_at
  t.boolean :available
  t.string :brand
end

ActiveRecord::Base.connection.create_table :comments do |t|
  t.references :product
  t.string :title
  t.text :message
end

if DATABASE == "mysql"
  ActiveRecord::Base.connection.execute "ALTER TABLE products ENGINE=MyISAM"
  ActiveRecord::Base.connection.execute "ALTER TABLE comments ENGINE=MyISAM"
end


