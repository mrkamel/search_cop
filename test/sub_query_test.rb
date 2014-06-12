
require File.expand_path("../test_helper", __FILE__)

class SubQueryTest < AttrSearchable::TestCase
  def test_subquery
    product1 = create(:product, :title => "Title1", :description => "Description")
    product2 = create(:product, :title => "Title2", :description => "Description")
    product3 = create(:product, :title => "TItle3", :description => "Description")

    results = Product.search(:or => [{ :query => "Description Title1" }, { :query => "Description Title2" }])

    assert_includes results, product1
    assert_includes results, product2
    refute_includes results, product3
  end
end

