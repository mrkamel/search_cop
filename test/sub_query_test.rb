
require File.expand_path("../test_helper", __FILE__)

class SubQueryTest < AttrSearchable::TestCase
  def test_subquery
    product1 = FactoryGirl.create(:product, :title => "Title1")
    product2 = FactoryGirl.create(:product, :title => "Title2")
    product3 = FactoryGirl.create(:product, :title => "TItle3")

    results = Product.search(:or => [{:query => "Title1"}, {:query => "Title2"}])

    assert_includes results, product1
    assert_includes results, product2
    refute_includes results, product3
  end
end

