
require File.expand_path("../test_helper", __FILE__)

class IntegerTest < AttrSearchable::TestCase
  def test_mapping
    product = FactoryGirl.create(:product, :created_at => Time.parse("2014-05-01 12:30:30"))

    assert_includes Product.search("created_at: 2014"), product
    assert_includes Product.search("created_at: 2014-05"), product
    assert_includes Product.search("created_at: 2014-05-01"), product
    assert_includes Product.search("created_at: '2014-05-01 12:30:30'"), product
  end

  def test_anywhere
    product = FactoryGirl.create(:product, :created_at => Time.parse("2014-05-01"))

    assert_includes Product.search("2014-05-01"), product
    refute_includes Product.search("2014-05-02"), product
  end

  def test_includes
    product = FactoryGirl.create(:product, :created_at => Time.parse("2014-05-01"))

    assert_includes Product.search("created_at: 2014-05-01"), product
    refute_includes Product.search("created_at: 2014-05-02"), product
  end

  def test_equals
    product = FactoryGirl.create(:product, :created_at => Time.parse("2014-05-01"))

    assert_includes Product.search("created_at = 2014-05-01"), product
    refute_includes Product.search("created_at = 2014-05-02"), product
  end

  def test_equals_not
    product = FactoryGirl.create(:product, :created_at => Time.parse("2014-05-01"))

    assert_includes Product.search("created_at != 2014-05-02"), product
    refute_includes Product.search("created_at != 2014-05-01"), product
  end

  def test_greater
    product = FactoryGirl.create(:product, :created_at => Time.parse("2014-05-01"))

    assert_includes Product.search("created_at < 2014-05-02"), product
    refute_includes Product.search("created_at < 2014-05-01"), product
  end

  def test_greater_equals
    product = FactoryGirl.create(:product, :created_at => Time.parse("2014-05-01"))

    assert_includes Product.search("created_at >= 2014-05-01"), product
    refute_includes Product.search("created_at >= 2014-05-02"), product
  end

  def test_less
    product = FactoryGirl.create(:product, :created_at => Time.parse("2014-05-01"))

    assert_includes Product.search("created_at < 2014-05-02"), product
    refute_includes Product.search("created_at < 2014-05-02"), product
  end

  def test_less_equals
    product = FactoryGirl.create(:product, :created_at => Time.parse("2014-05-02"))

    assert_includes Product.search("created_at <= 2014-05-02"), product
    refute_includes Product.search("created_at <= 2014-05-01"), product
  end
end

