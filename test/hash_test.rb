
require File.expand_path("../test_helper", __FILE__)

class HashTest < AttrSearchable::TestCase
  def test_subquery
    product1 = create(:product, :title => "Title1", :description => "Description")
    product2 = create(:product, :title => "Title2", :description => "Description")
    product3 = create(:product, :title => "TItle3", :description => "Description")

    results = Product.search(:or => [{ :query => "Description Title1" }, { :query => "Description Title2" }])

    assert_includes results, product1
    assert_includes results, product2
    refute_includes results, product3
  end

  def test_matches
    expected = create(:product, :title => "Expected")
    rejected = create(:product, :title => "Rejected")

    results = Product.search(:title => { :matches => "Expected" })

    assert_includes results, expected
    refute_includes results, rejected
  end

  def test_matches_default
    expected = create(:product, :title => "Expected")
    rejected = create(:product, :title => "Rejected")

    results = Product.search(:title => "Expected")

    assert_includes results, expected
    refute_includes results, rejected
  end

  def test_eq
    expected = create(:product, :title => "Expected")
    rejected = create(:product, :title => "Rejected")

    results = Product.search(:title => { :eq => "Expected" })

    assert_includes results, expected
    refute_includes results, rejected
  end

  def test_not_eq
    expected = create(:product, :title => "Expected")
    rejected = create(:product, :title => "Rejected")

    results = Product.search(:title => { :not_eq => "Rejected" })

    assert_includes results, expected
    refute_includes results, rejected
  end

  def test_gt
    expected = create(:product, :stock => 1)
    rejected = create(:product, :stock => 0)

    results = Product.search(:stock => { :gt => 0 })

    assert_includes results, expected
    refute_includes results, rejected
  end

  def test_gteq
    expected = create(:product, :stock => 1)
    rejected = create(:product, :stock => 0)

    results = Product.search(:stock => { :gteq => 1 })

    assert_includes results, expected
    refute_includes results, rejected
  end

  def test_lt
    expected = create(:product, :stock => 0)
    rejected = create(:product, :stock => 1)

    results = Product.search(:stock => { :lt => 1 })

    assert_includes results, expected
    refute_includes results, rejected
  end

  def test_lteq
    expected = create(:product, :stock => 0)
    rejected = create(:product, :stock => 1)

    results = Product.search(:stock => { :lteq => 0 })

    assert_includes results, expected
    refute_includes results, rejected
  end
end

