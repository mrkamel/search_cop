require File.expand_path("test_helper", __dir__)

class ErrorTest < SearchCop::TestCase
  def test_parse_error
    assert_raises SearchCop::ParseError do
      Product.unsafe_search title: { unknown_operator: "Value" }
    end
  end

  def test_unknown_column
    assert_raises SearchCop::UnknownColumn do
      Product.unsafe_search "Unknown: Column"
    end
  end
end
