require File.expand_path("test_helper", __dir__)

class DatetimeTest < SearchCop::TestCase
  def test_mapping
    product = create(:product, created_at: Time.parse("2014-05-01 12:30:30"))

    assert_includes Product.search("created_at: 2014"), product
    assert_includes Product.search("created_at: 2014-05"), product
    assert_includes Product.search("created_at: 2014-05-01"), product
    assert_includes Product.search("created_at: '2014-05-01 12:30:30'"), product
  end

  def test_anywhere
    product = create(:product, created_at: Time.parse("2014-05-01"))

    assert_includes Product.search("2014-05-01"), product
    refute_includes Product.search("2014-05-02"), product
  end

  def test_includes
    product = create(:product, created_at: Time.parse("2014-05-01"))

    assert_includes Product.search("created_at: 2014-05-01"), product
    refute_includes Product.search("created_at: 2014-05-02"), product
  end

  def test_equals
    product = create(:product, created_at: Time.parse("2014-05-01"))

    assert_includes Product.search("created_at = 2014-05-01"), product
    refute_includes Product.search("created_at = 2014-05-02"), product
  end

  def test_equals_not
    product = create(:product, created_at: Time.parse("2014-05-01"))

    assert_includes Product.search("created_at != 2014-05-02"), product
    refute_includes Product.search("created_at != 2014-05-01"), product
  end

  def test_greater
    product = create(:product, created_at: Time.parse("2014-05-01"))

    assert_includes Product.search("created_at > 2014-04-01"), product
    refute_includes Product.search("created_at > 2014-05-01"), product
  end

  def test_greater_equals
    product = create(:product, created_at: Time.parse("2014-05-01"))

    assert_includes Product.search("created_at >= 2014-05-01"), product
    refute_includes Product.search("created_at >= 2014-05-02"), product
  end

  def test_less
    product = create(:product, created_at: Time.parse("2014-05-01"))

    assert_includes Product.search("created_at < 2014-05-02"), product
    refute_includes Product.search("created_at < 2014-05-01"), product
  end

  def test_less_equals
    product = create(:product, created_at: Time.parse("2014-05-02"))

    assert_includes Product.search("created_at <= 2014-05-02"), product
    refute_includes Product.search("created_at <= 2014-05-01"), product
  end

  def test_hours_ago
    product = create(:product, created_at: 5.hours.ago)

    assert_includes Product.search("created_at <= '4 hours ago'"), product
    refute_includes Product.search("created_at <= '6 hours ago'"), product
  end

  def test_days_ago
    product = create(:product, created_at: 2.days.ago)

    assert_includes Product.search("created_at <= '1 day ago'"), product
    refute_includes Product.search("created_at <= '3 days ago'"), product
  end

  def test_weeks_ago
    product = create(:product, created_at: 2.weeks.ago)

    assert_includes Product.search("created_at <= '1 weeks ago'"), product
    refute_includes Product.search("created_at <= '3 weeks ago'"), product
  end

  def test_months_ago
    product = create(:product, created_at: 2.months.ago)

    assert_includes Product.search("created_at <= '1 months ago'"), product
    refute_includes Product.search("created_at <= '3 months ago'"), product
  end

  def test_years_ago
    product = create(:product, created_at: 2.years.ago)

    assert_includes Product.search("created_at <= '1 years ago'"), product
    refute_includes Product.search("created_at <= '3 years ago'"), product
  end

  def test_no_overflow
    assert_nothing_raised do
      Product.search("created_at: 1000000").to_a
    end
  end

  def test_incompatible_datatype
    assert_raises SearchCop::IncompatibleDatatype do
      Product.unsafe_search "created_at: Value"
    end
  end
end
