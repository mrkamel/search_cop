
require File.expand_path("../test_helper", __FILE__)

class IntegerTest < MiniTest::Test
  def test_anywhere
    product = FactoryGirl.create(:product, :stock => 1)

    assert_includes Product.search("1"), product
    refute_includes Product.search("0"), product
  end

  def test_includes
    product = FactoryGirl.create(:product, :stock => 1)

    assert_includes Product.search("stock: 1"), product
    refute_includes Product.search("stock: 10"), product
  end

  def test_equals
    product = FactoryGirl.create(:product, :stock => 1)

    assert_includes Product.search("stock = 1"), product
    refute_includes Product.search("stock = 0"), product
  end

  def test_equals_not
    product = FactoryGirl.create(:product, :stock => 1)

    assert_includes Product.search("stock != 0"), product
    refute_includes Product.search("stock != 1"), product
  end

  def test_greater
    product = FactoryGirl.create(:product, :stock => 1)

    assert_includes Product.search("stock > 0"), product
    refute_includes Product.search("stock < 1"), product
  end

  def test_greater_equals
    product = FactoryGirl.create(:product, :stock => 1)

    assert_includes Product.search("stock >= 1"), product
    refute_includes Product.search("stock >= 2"), product
  end

  def test_less
    product = FactoryGirl.create(:product, :stock => 1)

    assert_includes Product.search("stock < 2"), product
    refute_includes Product.search("stock < 1"), product
  end

  def test_less_equals
    product = FactoryGirl.create(:product, :stock => 1)

    assert_includes Product.search("stock <= 1"), product
    refute_includes Product.search("stock <= 0"), product
  end
end

