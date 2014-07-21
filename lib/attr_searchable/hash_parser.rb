
class AttrSearchable::HashParser
  attr_reader :query_object

  def initialize(query_object)
    @query_object = query_object
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
          AttrSearchable::QueryObject.new(query_object.model).parse(value).ast
        else
          parse_attribute key, value
      end
    end

    res.inject :and
  end

  private

  def parse_attribute(key, value)
    collection = AttrSearchableGrammar::Attributes::Collection.new(query_object.model, key.to_s)

    if value.is_a?(Hash)
      raise(AttrSearchable::ParseError, "Unknown operator #{value.keys.first}") unless [:matches, :eq, :not_eq, :gt, :gteq, :lt, :lteq].include?(value.keys.first)

      collection.send value.keys.first, value.values.first.to_s
    else
      collection.send :matches, value.to_s
    end
  end
end

