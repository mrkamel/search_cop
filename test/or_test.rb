
require File.expand_path("../test_helper", __FILE__)

class OrTest < MiniTest::Test
  def test_or
    expected1 = FactoryGirl.create(:product, :title => "Product 1")
    expected2 = FactoryGirl.create(:product, :title => "Product 2")
    rejected = FactoryGirl.create(:product, :title => "Product 3")

    results = Product.search("title: 'Product 1' OR title: 'Product 2'")

    assert_includes results, expected1
    assert_includes results, expected2

    refute_includes results, rejected
  end
end

