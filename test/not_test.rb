
require File.expand_path("../test_helper", __FILE__)

class OrTest < MiniTest::Test
  def test_or
    expected = FactoryGirl.create(:product, :title => "Product 1", :description => "Description")
    rejected = FactoryGirl.create(:product, :title => "Product 3", :description => "Description")

    results = Product.search("description: Description NOT title: 'Product 1'")

    assert_includes results, expected
    refute_includes results, rejected

    assert_equal results, Product.search("description: Description -title:'Product 1'")
  end
end

