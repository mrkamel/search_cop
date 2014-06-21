
require "attr_searchable/version"
require "attr_searchable/arel"
require "attr_searchable_grammar"
require "attr_searchable/hash_parser"
require "treetop"

Treetop.load File.expand_path("../attr_searchable_grammar.treetop", __FILE__)

module AttrSearchable
  class SpecificationError < StandardError; end
  class UnknownAttribute < SpecificationError; end

  class RuntimeError < StandardError; end
  class UnknownColumn < RuntimeError; end
  class NoSearchableAttributes < RuntimeError; end
  class IncompatibleDatatype < RuntimeError; end
  class ParseError < RuntimeError; end

  module Parser
    def self.parse(arg, model)
      arg.is_a?(Hash) ? parse_hash(arg, model) : parse_string(arg, model)
    end

    def self.parse_hash(hash, model)
      AttrSearchable::HashParser.new(model).parse(hash) || raise(ParseError)
    end

    def self.parse_string(string, model)
      node = AttrSearchableGrammarParser.new.parse(string) || raise(ParseError)
      node.model = model
      node.evaluate
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

    def search(*args)
      unsafe_search *args
    rescue AttrSearchable::RuntimeError
      respond_to?(:none) ? none : where("1 = 0")
    end

    def unsafe_search(arg)
      return respond_to?(:scoped) ? scoped : all if arg.blank?

      scope = respond_to?(:search_scope) ? search_scope : nil
      scope ||= eager_load(searchable_attributes.values.flatten.uniq.collect { |column| column.split(".").first.to_sym } - [name.tableize.to_sym])

      scope.where AttrSearchable::Parser.parse(arg, self).optimize!.to_sql(self)
    end
  end
end

