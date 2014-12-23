require File.expand_path("../test_helper", __FILE__)

ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS accounts"
ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS shouts"
ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS text_shouts"
ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS picture_shouts"


ActiveRecord::Base.connection.create_table :accounts do |t|
end

ActiveRecord::Base.connection.create_table :shouts do |t|
  t.references :account
  t.string :content_type
  t.string :content_id
end

ActiveRecord::Base.connection.create_table :text_shouts do |t|
  t.text :text
end

ActiveRecord::Base.connection.create_table :picture_shouts do |t|
  t.text :url
end

class Shout < ActiveRecord::Base
  belongs_to :account
  belongs_to :content, :polymorphic => true
end

class TextShout < ActiveRecord::Base
  validates :text, :presence => true
end

class PictureShout < ActiveRecord::Base
  validates :url, :presence => true
end

class Account < ActiveRecord::Base

  has_many :shouts
  has_many :text_shouts, :through => :shouts, :source => :content, :source_type => TextShout
  has_many :picture_shouts, :through => :shouts, :source => :content, :source_type => PictureShout

  include SearchCop

  search_scope :search do
    attributes :text_shout => "text_shouts.text"
    attributes :picture_shout => "picture_shouts.url"
  end
end

class PolymorphicTest < SearchCop::TestCase
  def teardown
    Account.delete_all
    Shout.delete_all
    TextShout.delete_all
    PictureShout.delete_all
  end

  def test_polymorphic_associations
    account = Account.create!

    text_shout = TextShout.new(:text => "Hello")
    picture_shout = PictureShout.new(:url => "some url")

    account.shouts.create!(:content => text_shout)
    account.shouts.create!(:content => picture_shout)

    assert_includes Account.search("Hello"), account
    assert_includes Account.search("some"), account
  end
end