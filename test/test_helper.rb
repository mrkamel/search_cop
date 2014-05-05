
require "attr_searchable"
require "minitest"
require "minitest/autorun"
require "active_record"
require "factory_girl"
require "yaml"

config = YAML.load_file(File.expand_path("../database.yml", __FILE__))

ActiveRecord::Base.establish_connection(config["test"])

class Comment < ActiveRecord::Base
end

class Product < ActiveRecord::Base
  include AttrSearchable

  attr_searchable :title, :description, :stock, :price, :created_at, :available
  attr_searchable :comment => ["comments.title", "comments.message"]

  has_many :comments
end

FactoryGirl.define do
  factory :product do
  end

  factory :comment do
  end
end

ActiveRecord::Base.connection.create_table :products do |t|
  t.string :title
  t.text :description
  t.integer :stock
  t.float :price
  t.datetime :created_at
  t.boolean :available
end

ActiveRecord::Base.connection.create_table :comments do |t|
  t.references :product
  t.string :title
  t.text :message
end

