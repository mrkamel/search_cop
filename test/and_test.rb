
require File.expand_path("../test_helper", __FILE__)

class AndTest < MiniTest::Test
  def test_and
    expected = FactoryGirl.create(:product, :title => "Product 1", :description => "Description")
    rejected = FactoryGirl.create(:product, :title => "Product 2", :description => "Description")

    results = Product.search("title: 'Product 1' description: Description")

    assert_includes results, expected
    refute_includes results, rejected

    assert_equal results, Product.search("title: 'Product 1' AND description: Description")
  end
end

