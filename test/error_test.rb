
require File.expand_path("../test_helper", __FILE__)

class ErrorTest < AttrSearchable::TestCase
  def test_parse_error
    assert_raises AttrSearchable::ParseError do
      Product.unsafe_search :title => { :unknown_operator => "Value" }
    end
  end

  def test_unknown_column
    assert_raises AttrSearchable::UnknownColumn do
      Product.unsafe_search "Unknown: Column"
    end
  end
end

