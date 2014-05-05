
require File.expand_path("../test_helper", __FILE__)

class StringTest < MiniTest::Test
  def test_anywhere
    product = FactoryGirl.create(:product, :title => "Expected title")

    assert_includes Product.search("Expected"), product
    refute_includes Product.search("Rejected"), product
  end

  def test_includes
    product = FactoryGirl.create(:product, :title => "Expected title")

    assert_includes Product.search("title: Expected"), product
    refute_includes Product.search("title: Rejected"), product
  end

  def test_equals
    product = FactoryGirl.create(:product, :title => "Expected title")

    assert_includes Product.search("title = 'Expected title'"), product
    refute_includes Product.search("title = Expected"), product
  end

  def test_equals_not
    product = FactoryGirl.create(:product, :title => "Expected")

    assert_includes Product.search("title != Rejected"), product
    refute_includes Product.search("title != Expected"), product
  end

  def test_greater
    product = FactoryGirl.create(:product, :title => "Title B")

    assert_includes Product.search("title > 'Title A'"), product
    refute_includes Product.search("title > 'Title B'"), product
  end

  def test_greater_equals
    product = FactoryGirl.create(:product, :title => "Title A")

    assert_includes Product.search("title >= 'Title A'"), product
    refute_includes Product.search("title >= 'Title B'"), product
  end

  def test_less
    product = FactoryGirl.create(:product, :title => "Title A")

    assert_includes Product.search("title < 'Title B'"), product
    refute_includes Product.search("title < 'Title A'"), product
  end

  def test_less_or_greater
    product = FactoryGirl.create(:product, :title => "Title B")

    assert_includes Product.search("title <= 'Title B'"), product
    refute_includes Product.search("title <= 'Title A'"), product
  end
end

