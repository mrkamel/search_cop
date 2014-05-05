
require File.expand_path("../test_helper", __FILE__)

class AttrSearchableTest < MiniTest::Test
  def test_associations
    product = FactoryGirl.create(:product, :comments => [
      FactoryGirl.create(:comment, :title => "Title 1"),
      FactoryGirl.create(:comment, :title => "Title 2")
    ])

    assert_includes Product.search("comment: 'Title 1'"), product
    assert_includes Product.search("comment: 'Title 2'"), product
  end

  def test_multiple
    product = FactoryGirl.create(:product, :comments => [FactoryGirl.create(:comment, :title => "Title", :message => "Message")])

    assert_includes Product.search("comment: Title"), product
    assert_includes Product.search("comment: Message"), product
  end
end

