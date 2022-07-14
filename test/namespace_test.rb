require File.expand_path("test_helper", __dir__)

class NamespaceTest < SearchCop::TestCase
  def test_model_namespace
    expected = create(:product, title: "Expected")
    rejected = create(:product, title: "Rejected")

    results = SomeNamespace::Product.search("Expected")

    assert_includes results.map(&:id), expected.id
    refute_includes results.map(&:id), rejected.id
  end

  def test_model_namespace_with_associations
    expected = create(:product, user: create(:user, username: "Expected"))
    rejected = create(:product, user: create(:user, username: "Rejected"))

    results = SomeNamespace::Product.search("user:Expected")

    assert_includes results.map(&:id), expected.id
    refute_includes results.map(&:id), rejected.id
  end
end
