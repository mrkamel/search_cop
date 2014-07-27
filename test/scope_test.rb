
require File.expand_path("../test_helper", __FILE__)

class ScopeTest < AttrSearchable::TestCase
  def test_user_search
    expected = create(:product, :title => "Expected")
    rejected = create(:product, :notice => "Expected")

    results = Product.user_search("Expected")

    assert_includes results, expected
    refute_includes results, rejected
  end

  def test_options
    expected = create(:product, :title => "Expected")
    rejected = create(:product, :description => "Expected")

    results = Product.user_search("Expected")

    assert_includes results, expected
    refute_includes results, rejected
  end

  def test_aliases
    expected = create(:product, :comments => [create(:comment, :user => create(:user, :username => "Expected"))])
    rejected = create(:product, :comments => [create(:comment, :user => create(:user, :username => "Rejected"))])

    results = Product.search("user: Expected")

    assert_includes results, expected
    refute_includes results, rejected
  end
end

