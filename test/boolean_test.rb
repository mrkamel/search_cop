
require File.expand_path("../test_helper", __FILE__)

class BooleanTest < SearchCop::TestCase
  def test_mapping
    product = create(:product, :available => true)

    assert_includes Product.search("available: 1"), product
    assert_includes Product.search("available: true"), product
    assert_includes Product.search("available: yes"), product

    product = create(:product, :available => false)

    assert_includes Product.search("available: 0"), product
    assert_includes Product.search("available: false"), product
    assert_includes Product.search("available: no"), product
  end

  def test_anywhere
    product = create(:product, :available => true)

    assert_includes Product.search("true"), product
    refute_includes Product.search("false"), product
  end

  def test_includes
    product = create(:product, :available => true)

    assert_includes Product.search("available: true"), product
    refute_includes Product.search("available: false"), product
  end

  def test_equals
    product = create(:product, :available => true)

    assert_includes Product.search("available = true"), product
    refute_includes Product.search("available = false"), product
  end

  def test_equals_not
    product = create(:product, :available => false)

    assert_includes Product.search("available != true"), product
    refute_includes Product.search("available != false"), product
  end

  def test_incompatible_datatype
    assert_raises SearchCop::IncompatibleDatatype do
      Product.unsafe_search "available: Value"
    end
  end
end

