
require File.expand_path("../test_helper", __FILE__)

class NotTest < MiniTest::Test
  def test_not
    expected = FactoryGirl.create(:product, :title => "Expected", :description => "Description")
    rejected = FactoryGirl.create(:product, :title => "Rejected", :description => "Description")

    results = Product.search("description: Description NOT title: Rejected")

    assert_includes results, expected
    refute_includes results, rejected

    assert_equal results, Product.search("description:Description -title: Rejected")
  end
end

