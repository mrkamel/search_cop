
require File.expand_path("../test_helper", __FILE__)

class AttrSearchableTest < AttrSearchable::TestCase
  def test_multi_associations
    product = create(:product, :comments => [
      create(:comment, :title => "Title1", :message => "Message1"),
      create(:comment, :title => "Title2", :message => "Message2")
    ])

    assert_includes Product.search("comment: Title1 comment: Message1"), product
    assert_includes Product.search("comment: Title2 comment: Message2"), product
  end

  def test_single_association
    expected = create(:comment, :user => create(:user, :username => "Expected"))
    rejected = create(:comment, :user => create(:user, :username => "Rejected"))

    results = Comment.search("user: Expected")

    assert_includes results, expected
    refute_includes results, rejected
  end

  def test_deep_associations
    expected = create(:product, :comments => [create(:comment, :user => create(:user, :username => "Expected"))])
    rejected = create(:product, :comments => [create(:comment, :user => create(:user, :username => "Rejected"))])

    results = Product.search("user: Expected")

    assert_includes results, expected
    refute_includes results, rejected
  end

  def test_multiple
    product = create(:product, :comments => [create(:comment, :title => "Title", :message => "Message")])

    assert_includes Product.search("comment: Title"), product
    assert_includes Product.search("comment: Message"), product
  end

  def test_default
    product1 = create(:product, :title => "Expected")
    product2 = create(:product, :description => "Expected")

    results = Product.search("Expected")

    assert_includes results, product1
    assert_includes results, product2
  end

  def test_custom_default
    product1 = create(:product, :title => "Expected")
    product2 = create(:product, :description => "Expected")
    product3 = create(:product, :brand => "Expected")

    results = with_attr_searchable_options(Product, :primary, :default => true) { Product.search "Expected" }

    assert_includes results, product1
    assert_includes results, product2
    refute_includes results, product3
  end

  def test_count
    create_list :product, 2, :title => "Expected"

    assert_equal 2, Product.search("Expected").count
  end
end

