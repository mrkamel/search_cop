
require File.expand_path("../test_helper", __FILE__)

class AndTest < SearchCop::TestCase
  def test_and_string
    expected = create(:product, :title => "Expected title", :description => "Description")
    rejected = create(:product, :title => "Rejected title", :description => "Description")

    results = Product.search("title: 'Expected title' description: Description")

    assert_includes results, expected
    refute_includes results, rejected

    assert_equal results, Product.search("title: 'Expected title' AND description: Description")
  end

  def test_and_hash
    expected = create(:product, :title => "Expected title", :description => "Description")
    rejected = create(:product, :title => "Rejected title", :description => "Description")

    results = Product.search(:and => [{:title => "Expected title"}, {:description => "Description"}])

    assert_includes results, expected
    refute_includes results, rejected
  end
end

