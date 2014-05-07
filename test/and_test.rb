
require File.expand_path("../test_helper", __FILE__)

class AndTest < MiniTest::Test
  def test_and
    expected = FactoryGirl.create(:product, :title => "Expected title", :description => "Description")
    rejected = FactoryGirl.create(:product, :title => "Rejected title", :description => "Description")

    results = Product.search("title: 'Expected title' description: Description")

    assert_includes results, expected
    refute_includes results, rejected

    assert_equal results, Product.search("title: 'Expected title' AND description: Description")
  end
end

