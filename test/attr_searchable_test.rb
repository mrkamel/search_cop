
require File.expand_path("../test_helper", __FILE__)
require "irb"

class AttrSearchableTest < MiniTest::Test
  def test_associations
    product = FactoryGirl.create(:product, :comments => [
      FactoryGirl.create(:comment, :title => "Title1", :message => "Message1"),
      FactoryGirl.create(:comment, :title => "Title2", :message => "Message2")
    ])

    assert_includes Product.search("comment: Title1 comment: Message1"), product
    assert_includes Product.search("comment: Title2 comment: Message2"), product
  end

  def test_multiple
    product = FactoryGirl.create(:product, :comments => [FactoryGirl.create(:comment, :title => "Title", :message => "Message")])

    assert_includes Product.search("comment: Title"), product
    assert_includes Product.search("comment: Message"), product
  end
end

