require File.expand_path("test_helper", __dir__)

class NamespaceTest < SearchCop::TestCase
  def test_model_namespace
    expected = create(:product, title: "Expected")
    rejected = create(:product, title: "Rejected")

    results = SomeNamespace::Product.search("Expected")

    assert_includes results, expected
    refute_includes results, rejected
  end
end
