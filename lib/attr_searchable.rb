
require "attr_searchable/version"
require "attr_searchable/arel"
require "attr_searchable_grammar"
require "treetop"

Treetop.load File.expand_path("../attr_searchable_grammar.treetop", __FILE__)

module AttrSearchable
  class Error < StandardError; end
  class UnknownColumn < Error; end
  class NoSearchableAttributes < Error; end
  class IncompatibleDatatype < Error; end
  class ParseError < Error; end

  module Parser
    def self.parse(str, model)
      node = AttrSearchableGrammarParser.new.parse(str) || raise(ParseError)
      node.model = model
      node
    end
  end

  def self.included(base)
    base.class_attribute :searchable_attributes
    base.searchable_attributes = {}

    base.class_attribute :searchable_attribute_options
    base.searchable_attribute_options = {}

    base.extend ClassMethods
  end

  module ClassMethods
    def attr_searchable(*args)
      args.each do |arg|
        attr_searchable_hash arg.is_a?(Hash) ? arg : { arg => arg }
      end
    end

    def attr_searchable_hash(hash)
      hash.each do |key, value|
        self.searchable_attributes[key.to_s] = Array(value).collect do |column|
          table, attribute = column.to_s =~ /\./ ? column.to_s.split(".") : [name, column]

          "#{table.tableize}.#{attribute}"
        end
      end
    end

    def attr_searchable_options(key, options = {})
      self.searchable_attribute_options[key.to_s] = (self.searchable_attribute_options[key.to_s] || {}).merge(options)
    end

    def search(str)
      return respond_to?(:scoped) ? scoped : all if str.blank?

      scope = respond_to?(:search_scope) ? search_scope : nil
      scope ||= eager_load(searchable_attributes.values.flatten.uniq.collect { |column| column.split(".").first.to_sym } - [name.tableize.to_sym])

      scope.where AttrSearchable::Parser.parse(str, self).to_arel.optimize!
    rescue AttrSearchable::Error
      respond_to?(:none) ? none : where("1 = 0")
    end
  end
end

