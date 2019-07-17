require File.expand_path("../test_helper", __FILE__)

class DefaultOperatorTest < SearchCop::TestCase

  def test_without_default_operator
    avengers = create(:product, :title => "Title Avengers")
    inception = create(:product, :title => "Title Inception")

    results = Product.search_multi_columns("Title Avengers")
    assert_includes results, avengers
    refute_includes results, inception

    results = Product.search_multi_columns("Title AND Avengers")
    assert_includes results, avengers
    refute_includes results, inception

    results = Product.search_multi_columns("Title OR Avengers")
    assert_includes results, avengers
    assert_includes results, inception
  end

  def test_with_specific_default_operator
    matrix = create(:product, :title => "Matrix")
    start_wars = create(:product, :title => "Start Wars")

    results = Product.search_multi_columns("Matrix movie", default_operator: :or)
    assert_includes results, matrix
    refute_includes results, start_wars
  end
end