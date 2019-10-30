require File.expand_path("test_helper", __dir__)

class FloatTest < SearchCop::TestCase
  def test_anywhere
    product = create(:product, price: 10.5, created_at: Time.now - 1.day)

    assert_includes Product.search("10.5"), product
    refute_includes Product.search("11.5"), product
  end

  def test_includes
    product = create(:product, price: 10.5)

    assert_includes Product.search("price: 10.5"), product
    refute_includes Product.search("price: 11.5"), product
  end

  def test_equals
    product = create(:product, price: 10.5)

    assert_includes Product.search("price = 10.5"), product
    refute_includes Product.search("price = 11.5"), product
  end

  def test_equals_not
    product = create(:product, price: 10.5)

    assert_includes Product.search("price != 11.5"), product
    refute_includes Product.search("price != 10.5"), product
  end

  def test_greater
    product = create(:product, price: 10.5)

    assert_includes Product.search("price > 10.4"), product
    refute_includes Product.search("price < 10.5"), product
  end

  def test_greater_equals
    product = create(:product, price: 10.5)

    assert_includes Product.search("price >= 10.5"), product
    refute_includes Product.search("price >= 10.6"), product
  end

  def test_less
    product = create(:product, price: 10.5)

    assert_includes Product.search("price < 10.6"), product
    refute_includes Product.search("price < 10.5"), product
  end

  def test_less_equals
    product = create(:product, price: 10.5)

    assert_includes Product.search("price <= 10.5"), product
    refute_includes Product.search("price <= 10.4"), product
  end

  def test_negative
    product = create(:product, price: -10)

    assert_includes Product.search("price = -10"), product
    refute_includes Product.search("price = -11"), product
  end

  def test_incompatible_datatype
    assert_raises SearchCop::IncompatibleDatatype do
      Product.unsafe_search "price: Value"
    end
  end
end
