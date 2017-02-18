
require File.expand_path("../test_helper", __FILE__)

class FulltextTest < SearchCop::TestCase
  def test_complex
    product1 = create(:product, :title => "word1")
    product2 = create(:product, :title => "word2 word3")
    product3 = create(:product, :title => "word2")

    results = Product.search("word1 OR (title:word2 -word3)")

    assert_includes results, product1
    refute_includes results, product2
    assert_includes results, product3
  end

  def test_mixed
    expected = create(:product, :title => "Expected title", :stock => 1)
    rejected = create(:product, :title => "Expected title", :stock => 0)

    results = Product.search("Expected title:Title stock > 0")

    assert_includes results, expected
    refute_includes results, rejected
  end
end

