
require File.expand_path("../test_helper", __FILE__)

class FloatTest < AttrSearchable::TestCase
  def test_anywhere
    product = FactoryGirl.create(:product, :price => 10.5, :created_at => Time.now - 1.day)

    assert_includes Product.search("10.5"), product
    refute_includes Product.search("11.5"), product
  end

  def test_includes
    product = FactoryGirl.create(:product, :price => 10.5)

    assert_includes Product.search("price: 10.5"), product
    refute_includes Product.search("price: 11.5"), product
  end

  def test_equals
    product = FactoryGirl.create(:product, :price => 10.5)

    assert_includes Product.search("price = 10.5"), product
    refute_includes Product.search("price = 11.5"), product
  end

  def test_equals_not
    product = FactoryGirl.create(:product, :price => 10.5)

    assert_includes Product.search("price != 11.5"), product
    refute_includes Product.search("price != 10.5"), product
  end

  def test_greater
    product = FactoryGirl.create(:product, :price => 10.5)

    assert_includes Product.search("price > 10.4"), product
    refute_includes Product.search("price < 10.5"), product
  end

  def test_greater_equals
    product = FactoryGirl.create(:product, :price => 10.5)

    assert_includes Product.search("price >= 10.5"), product
    refute_includes Product.search("price >= 10.6"), product
  end

  def test_less
    product = FactoryGirl.create(:product, :price => 10.5)

    assert_includes Product.search("price < 10.6"), product
    refute_includes Product.search("price < 10.5"), product
  end

  def test_less_equals
    product = FactoryGirl.create(:product, :price => 10.5)

    assert_includes Product.search("price <= 10.5"), product
    refute_includes Product.search("price <= 10.4"), product
  end
end

