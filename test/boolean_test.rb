
require File.expand_path("../test_helper", __FILE__)

class IntegerTest < MiniTest::Test
  def test_mapping
    product = FactoryGirl.create(:product, :available => true)

    assert_includes Product.search("available: 1"), product
    assert_includes Product.search("available: true"), product
    assert_includes Product.search("available: yes"), product

    product = FactoryGirl.create(:product, :available => false)

    assert_includes Product.search("available: 0"), product
    assert_includes Product.search("available: false"), product
    assert_includes Product.search("available: no"), product
  end

  def test_anywhere
    product = FactoryGirl.create(:product, :available => true)

    assert_includes Product.search("true"), product
    refute_includes Product.search("false"), product
  end

  def test_includes
    product = FactoryGirl.create(:product, :available => true)

    assert_includes Product.search("available: true"), product
    refute_includes Product.search("available: false"), product
  end

  def test_equals
    product = FactoryGirl.create(:product, :available => true)

    assert_includes Product.search("available"), product
    refute_includes Product.search("stock = 0"), product
  end

  def test_equals_not
    product = FactoryGirl.create(:product, :stock => 1)

    assert_includes Product.search("stock != 0"), product
    refute_includes Product.search("stock != 1"), product
  end
end

