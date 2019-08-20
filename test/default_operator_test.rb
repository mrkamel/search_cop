require File.expand_path('../test_helper', __FILE__)

class DefaultOperatorTest < SearchCop::TestCase

  def test_without_default_operator
    avengers = create(:product, title: "Title Avengers", description: "2012")
    inception = create(:product, title: "Title Inception", description: "2010")

    results = Product.search_multi_columns("Title Avengers")
    assert_includes results, avengers
    refute_includes results, inception

    results = Product.search_multi_columns("Title AND Avengers")
    assert_includes results, avengers
    refute_includes results, inception

    results = Product.search_multi_columns("Title OR Avengers")
    assert_includes results, avengers
    assert_includes results, inception

    results = Product.search(title: "Avengers", description: "2012")
    assert_includes results, avengers
    refute_includes results, inception
  end

  def test_with_specific_default_operator
    matrix = create(:product, title: "Matrix", description: "1999 Fantasy Sci-fi 2h 30m")
    start_wars = create(:product, title: "Start Wars", description: "2010 Sci-fi Thriller 2h 28m")

    results = Product.search_multi_columns("Matrix movie", default_operator: :or)
    assert_includes results, matrix
    refute_includes results, start_wars

    results = Product.search(title: "Matrix", description: "2000", default_operator: :or)
    assert_includes results, matrix
    refute_includes results, start_wars
  end

  def test_with_invalid_default_operator
    assert_raises SearchCop::UnknownDefaultOperator do
      Product.search_multi_columns('Matrix movie', default_operator: :xpto)
    end
    assert_raises SearchCop::UnknownDefaultOperator do
      Product.search_multi_columns(title: 'Matrix movie', default_operator: :xpto)
    end
  end
end