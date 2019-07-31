
class SearchCop::HashParser
  attr_reader :query_info

  def initialize(query_info)
    @query_info = query_info
  end

  def parse(hash)
    default_operator = :and
    if hash.member?(:default_operator)
      raise(SearchCop::UnknownAttribute, "Unknown default operator value #{hash[:default_operator]}") unless [:and, :or].include?(hash[:default_operator])

      default_operator = hash[:default_operator]
      hash.delete(:default_operator)
    end

    res = hash.collect do |key, value|
      case key
        when :and
          value.collect { |val| parse val }.inject(:and)
        when :or
          value.collect { |val| parse val }.inject(:or)
        when :not
          parse(value).not
        when :query
          SearchCop::Parser.parse value, query_info
        else
          parse_attribute key, value
      end
    end

    res.inject default_operator
  end

  private

  def parse_attribute(key, value)
    collection = SearchCopGrammar::Attributes::Collection.new(query_info, key.to_s)

    if value.is_a?(Hash)
      raise(SearchCop::ParseError, "Unknown operator #{value.keys.first}") unless collection.valid_operator?(value.keys.first)

      if generator = collection.generator_for(value.keys.first)
        collection.generator generator, value.values.first
      else
        collection.send value.keys.first, value.values.first.to_s
      end
    else
      collection.send :matches, value.to_s
    end
  end
end

