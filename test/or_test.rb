
require File.expand_path("../test_helper", __FILE__)

class OrTest < AttrSearchable::TestCase
  def test_or
    expected1 = FactoryGirl.create(:product, :title => "Expected1")
    expected2 = FactoryGirl.create(:product, :title => "Expected2")
    rejected = FactoryGirl.create(:product, :title => "Rejected")

    results = Product.search("title: Expected1 OR title: Expected2")

    assert_includes results, expected1
    assert_includes results, expected2

    refute_includes results, rejected
  end
end

