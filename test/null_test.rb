
require File.expand_path("../test_helper", __FILE__)

class NullTest < SearchCop::TestCase
  def test_null
    expected = create(:product, brand: nil)
    rejected = create(:product, brand: "brand")

    results = Product.search("brand = __null__")

    assert_includes results, expected
    refute_includes results, rejected
  end

  def test_not_null
    expected = create(:product, brand: "brand")
    rejected = create(:product, brand: nil)

    results = Product.search("brand != __null__")

    assert_includes results, expected
    refute_includes results, rejected
  end
end

