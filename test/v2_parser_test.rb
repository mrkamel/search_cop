
require File.expand_path("../test_helper", __FILE__)

class V2ParserTest < SearchCop::TestCase
  def test_anywhere
    expected = create(:product, title: "Expected title")

    assert_includes Product.search_v2("Expected"), expected
    refute_includes Product.search_v2("Rejected"), expected
  end

  def test_includes
    expected = create(:product, title: "Expected title")

    assert_includes Product.search_v2("title: Expected"), expected
    refute_includes Product.search_v2("title: Rejected"), expected
  end

  def test_equals
    expected = create(:product, price: 10)

    assert_includes Product.search_v2("price:=10"), expected
    refute_includes Product.search_v2("price:=20"), expected
  end

  def test_equals_not
    expected = create(:product, price: 10)

    assert_includes Product.search_v2("price:!=20"), expected
    refute_includes Product.search_v2("price:!=10"), expected
  end

  def test_less_than
    expected = create(:product, price: 10)

    assert_includes Product.search_v2("price:<20"), expected
    refute_includes Product.search_v2("price:<10"), expected
  end

  def test_less_than_or_equal
    expected = create(:product, price: 10)

    assert_includes Product.search_v2("price:<=20"), expected
    assert_includes Product.search_v2("price:<=10"), expected
    refute_includes Product.search_v2("price:<=9"), expected
  end

  def test_greater_than
    expected = create(:product, price: 10)

    assert_includes Product.search_v2("price:>5"), expected
    refute_includes Product.search_v2("price:>10"), expected
  end

  def test_greater_than_or_equal
    expected = create(:product, price: 10)

    assert_includes Product.search_v2("price:>=5"), expected
    assert_includes Product.search_v2("price:>=10"), expected
    refute_includes Product.search_v2("price:>=20"), expected
  end
end

