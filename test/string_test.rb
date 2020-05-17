require File.expand_path("test_helper", __dir__)

class StringTest < SearchCop::TestCase
  def test_anywhere
    product = create(:product, title: "Expected title")

    assert_includes Product.search("Expected"), product
    refute_includes Product.search("Rejected"), product
  end

  def test_anywhere_quoted
    product = create(:product, title: "Expected title")

    assert_includes Product.search("'Expected title'"), product
    assert_includes Product.search('"Expected title"'), product

    refute_includes Product.search("'Rejected title'"), product
    refute_includes Product.search('"Rejected title"'), product
  end

  def test_multiple
    product = create(:product, comments: [create(:comment, title: "Expected title", message: "Expected message")])

    assert_includes Product.search("Expected"), product
    refute_includes Product.search("Rejected"), product
  end

  def test_includes
    product = create(:product, title: "Expected")

    assert_includes Product.search("title: Expected"), product
    refute_includes Product.search("title: Rejected"), product
  end

  def test_query_string_wildcards
    product1 = create(:product, title: "First title")
    product2 = create(:product, title: "Second title")

    assert_equal Product.search("title: First*"), [product1]
    assert_equal Product.search("title: title*"), []
    assert_equal Product.search("title: *title*"), [product1, product2]
    assert_equal Product.search("title: *title"), [product1, product2]
  end

  def test_query_string_wildcards_with_left_wildcard_false
    product = create(:product, title: "Some title")

    with_options(Product.search_scopes[:search], :title, left_wildcard: false) do
      refute_includes Product.search("title: *title"), product
      assert_includes Product.search("title: Some"), product
    end
  end

  def test_query_string_wildcards_with_right_wildcard_false
    product = create(:product, title: "Some title")

    with_options(Product.search_scopes[:search], :title, right_wildcard: false) do
      refute_includes Product.search("title: Some*"), product
      assert_includes Product.search("title: title"), product
    end
  end

  def test_includes_with_left_wildcard
    product = create(:product, title: "Some title")

    assert_includes Product.search("title: Title"), product
  end

  def test_includes_with_left_wildcard_false
    expected = create(:product, brand: "Brand")
    rejected = create(:product, brand: "Rejected brand")

    results = with_options(Product.search_scopes[:search], :brand, left_wildcard: false) { Product.search "brand: Brand" }

    assert_includes results, expected
    refute_includes results, rejected
  end

  def test_includes_with_right_wildcard_false
    expected = create(:product, brand: "Brand")
    rejected = create(:product, brand: "Brand rejected")

    results = with_options(Product.search_scopes[:search], :brand, right_wildcard: false) { Product.search "brand: Brand" }

    assert_includes results, expected
    refute_includes results, rejected
  end

  def test_equals
    product = create(:product, title: "Expected title")

    assert_includes Product.search("title = 'Expected title'"), product
    refute_includes Product.search("title = Expected"), product
  end

  def test_equals_not
    product = create(:product, title: "Expected")

    assert_includes Product.search("title != Rejected"), product
    refute_includes Product.search("title != Expected"), product
  end

  def test_greater
    product = create(:product, title: "Title B")

    assert_includes Product.search("title > 'Title A'"), product
    refute_includes Product.search("title > 'Title B'"), product
  end

  def test_greater_equals
    product = create(:product, title: "Title A")

    assert_includes Product.search("title >= 'Title A'"), product
    refute_includes Product.search("title >= 'Title B'"), product
  end

  def test_less
    product = create(:product, title: "Title A")

    assert_includes Product.search("title < 'Title B'"), product
    refute_includes Product.search("title < 'Title A'"), product
  end

  def test_less_or_greater
    product = create(:product, title: "Title B")

    assert_includes Product.search("title <= 'Title B'"), product
    refute_includes Product.search("title <= 'Title A'"), product
  end
end
