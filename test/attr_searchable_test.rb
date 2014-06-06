
require File.expand_path("../test_helper", __FILE__)

class AttrSearchableTest < AttrSearchable::TestCase
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

  def test_default
    product1 = FactoryGirl.create(:product, :title => "Expected")
    product2 = FactoryGirl.create(:product, :description => "Expected")

    results = Product.search("Expected")

    assert_includes results, product1
    assert_includes results, product2
  end

  def test_custom_default
    product1 = FactoryGirl.create(:product, :title => "Expected")
    product2 = FactoryGirl.create(:product, :description => "Expected")
    product3 = FactoryGirl.create(:product, :brand => "Expected")

    results = with_attr_searchable_options(Product, :primary, :default => true) { Product.search "Expected" }

    assert_includes results, product1
    assert_includes results, product2
    refute_includes results, product3
  end
end

