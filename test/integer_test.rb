
require File.expand_path("../test_helper", __FILE__)

class IntegerTest < AttrSearchable::TestCase
  def test_anywhere
    product = create(:product, :stock => 1)

    assert_includes Product.search("1"), product
    refute_includes Product.search("0"), product
  end

  def test_includes
    product = create(:product, :stock => 1)

    assert_includes Product.search("stock: 1"), product
    refute_includes Product.search("stock: 10"), product
  end

  def test_equals
    product = create(:product, :stock => 1)

    assert_includes Product.search("stock = 1"), product
    refute_includes Product.search("stock = 0"), product
  end

  def test_equals_not
    product = create(:product, :stock => 1)

    assert_includes Product.search("stock != 0"), product
    refute_includes Product.search("stock != 1"), product
  end

  def test_greater
    product = create(:product, :stock => 1)

    assert_includes Product.search("stock > 0"), product
    refute_includes Product.search("stock < 1"), product
  end

  def test_greater_equals
    product = create(:product, :stock => 1)

    assert_includes Product.search("stock >= 1"), product
    refute_includes Product.search("stock >= 2"), product
  end

  def test_less
    product = create(:product, :stock => 1)

    assert_includes Product.search("stock < 2"), product
    refute_includes Product.search("stock < 1"), product
  end

  def test_less_equals
    product = create(:product, :stock => 1)

    assert_includes Product.search("stock <= 1"), product
    refute_includes Product.search("stock <= 0"), product
  end

  def test_incompatible_datatype
    assert_raises AttrSearchable::IncompatibleDatatype do
      Product.unsafe_search "stock: Value"
    end
  end
end

