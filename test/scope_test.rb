require File.expand_path("test_helper", __dir__)

class ScopeTest < SearchCop::TestCase
  def test_scope_name
    expected = create(:product, title: "Expected")
    rejected = create(:product, notice: "Expected")

    results = Product.user_search("Expected")

    assert_includes results, expected
    refute_includes results, rejected
  end

  def test_options
    expected = create(:product, title: "Expected")
    rejected = create(:product, description: "Expected")

    results = Product.user_search("Expected")

    assert_includes results, expected
    refute_includes results, rejected
  end

  def test_custom_scope
    expected = create(:product, user: create(:user, username: "Expected"))
    rejected = create(:product, user: create(:user, username: "Rejected"))

    results = Product.user_search("user: Expected")

    assert_includes results, expected
    refute_includes results, rejected
  end

  def test_aliases_with_association
    expected = create(:product, user: create(:user, username: "Expected"))
    rejected = create(:product, user: create(:user, username: "Rejected"))

    results = Product.search("user: Expected")

    assert_includes results, expected
    refute_includes results, rejected
  end

  def test_aliases_with_model
    expected = create(:product, user: create(:user, username: "Expected"))
    rejected = create(:product, user: create(:user, username: "Rejected"))

    results = Product.user_search("user: Expected")

    assert_includes results, expected
    refute_includes results, rejected
  end
end
