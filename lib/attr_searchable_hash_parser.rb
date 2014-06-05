
class AttrSearchableHashParser
  def initialize(model)
    @model = model
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
        else
          parse_attribute key, value
      end
    end

    res.inject :and
  end

  private

  def parse_attribute(key, value)
    collection = AttrSearchableGrammar::Attributes::Collection.new(@model, key.to_s)

    if value.is_a?(Hash)
      raise AttrSearchable::ParseError unless collection.respond_to?(value.keys.first)

      collection.send value.keys.first, value.values.first
    else
      collection.send :matches, value
    end
  end
end

