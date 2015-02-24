
require File.expand_path("../test_helper", __FILE__)

class DateTest < SearchCop::TestCase
  def test_mapping
    product = create(:product, :created_on => Date.parse("2014-05-01"))

    assert_includes Product.search("created_on: 2014"), product
    assert_includes Product.search("created_on: 2014-05"), product
    assert_includes Product.search("created_on: 2014-05-01"), product
  end

  def test_anywhere
    product = create(:product, :created_on => Date.parse("2014-05-01"))

    assert_includes Product.search("2014-05-01"), product
    refute_includes Product.search("2014-05-02"), product
  end

  def test_includes
    product = create(:product, :created_on => Date.parse("2014-05-01"))

    assert_includes Product.search("created_on: 2014-05-01"), product
    refute_includes Product.search("created_on: 2014-05-02"), product
  end

  def test_equals
    product = create(:product, :created_on => Date.parse("2014-05-01"))

    assert_includes Product.search("created_on = 2014-05-01"), product
    refute_includes Product.search("created_on = 2014-05-02"), product
  end

  def test_equals_not
    product = create(:product, :created_on => Date.parse("2014-05-01"))

    assert_includes Product.search("created_on != 2014-05-02"), product
    refute_includes Product.search("created_on != 2014-05-01"), product
  end

  def test_greater
    product = create(:product, :created_on => Date.parse("2014-05-01"))

    assert_includes Product.search("created_on > 2014-04-01"), product
    refute_includes Product.search("created_on > 2014-05-01"), product
  end

  def test_greater_equals
    product = create(:product, :created_on => Date.parse("2014-05-01"))

    assert_includes Product.search("created_on >= 2014-05-01"), product
    refute_includes Product.search("created_on >= 2014-05-02"), product
  end

  def test_less
    product = create(:product, :created_on => Date.parse("2014-05-01"))

    assert_includes Product.search("created_on < 2014-05-02"), product
    refute_includes Product.search("created_on < 2014-05-01"), product
  end

  def test_less_equals
    product = create(:product, :created_on => Date.parse("2014-05-02"))

    assert_includes Product.search("created_on <= 2014-05-02"), product
    refute_includes Product.search("created_on <= 2014-05-01"), product
  end

  def test_no_overflow
    assert_nothing_raised do
      Product.search("created_on: 1000000").to_a
    end
  end

  def test_incompatible_datatype
    assert_raises SearchCop::IncompatibleDatatype do
      Product.unsafe_search "created_on: Value"
    end
  end
end

