
require File.expand_path("../test_helper", __FILE__)

class OrTest < SearchCop::TestCase
  def test_or_string
    product1 = create(:product, :title => "Title1")
    product2 = create(:product, :title => "Title2")
    product3 = create(:product, :title => "Title3")

    results = Product.search("title: Title1 OR title: Title2")

    assert_includes results, product1
    assert_includes results, product2
    refute_includes results, product3
  end

  def test_or_hash
    product1 = create(:product, :title => "Title1")
    product2 = create(:product, :title => "Title2")
    product3 = create(:product, :title => "Title3")

    results = Product.search(:or => [{:title => "Title1"}, {:title => "Title2"}])

    assert_includes results, product1
    assert_includes results, product2
    refute_includes results, product3
  end
end

