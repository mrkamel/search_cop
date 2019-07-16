require File.expand_path("../test_helper", __FILE__)

class DefaultOperatorTest < SearchCop::TestCase

  def test_default_operator_and
    expected = create(:product, :title => "Title Avengers")
    rejected = create(:product, :title => "Title Inception")

    results = Product.search_with_and_operator("Title Avengers")

    assert_includes results, expected
    refute_includes results, rejected
  end

  def test_default_operator_or
    expected = create(:product, :title => "Title Avengers")
    rejected = create(:product, :title => "Title Inception")

    results = Product.search_with_or_operator("Movie Avengers")

    assert_includes results, expected
    refute_includes results, rejected
  end

end