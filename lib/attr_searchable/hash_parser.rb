
class AttrSearchable::HashParser
  attr_reader :query_info

  def initialize(query_info)
    @query_info = query_info
  end

  def parse(hash)
    res = hash.collect do |key, value|
      case key
        when :and
          value.collect { |val| parse val }.inject(:and)
        when :or
          value.collect { |val| parse val }.inject(:or)
        when :not
          parse(value).not
        when :query
          AttrSearchable::Parser.parse value, query_info
        else
          parse_attribute key, value
      end
    end

    res.inject :and
  end

  private

  def parse_attribute(key, value)
    collection = AttrSearchableGrammar::Attributes::Collection.new(query_info, key.to_s)

    if value.is_a?(Hash)
      raise(AttrSearchable::ParseError, "Unknown operator #{value.keys.first}") unless [:matches, :eq, :not_eq, :gt, :gteq, :lt, :lteq].include?(value.keys.first)

      collection.send value.keys.first, value.values.first.to_s
    else
      collection.send :matches, value.to_s
    end
  end
end

