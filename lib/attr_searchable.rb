
require "attr_searchable/version"
require "attr_searchable/arel"
require "attr_searchable/query_info"
require "attr_searchable/query_builder"
require "attr_searchable/grammar_parser"
require "attr_searchable/hash_parser"

module AttrSearchable
  class SpecificationError < StandardError; end
  class UnknownAttribute < SpecificationError; end

  class RuntimeError < StandardError; end
  class UnknownColumn < RuntimeError; end
  class NoSearchableAttributes < RuntimeError; end
  class IncompatibleDatatype < RuntimeError; end
  class ParseError < RuntimeError; end

  module Parser
    def self.parse(query, query_info)
      if query.is_a?(Hash)
        AttrSearchable::HashParser.new(query_info).parse(query)
      else
        AttrSearchable::GrammarParser.new(query_info).parse(query)
      end
    end
  end

  def self.included(base)
    base.class_attribute :searchable_attributes
    base.searchable_attributes = {}

    base.class_attribute :searchable_attribute_options
    base.searchable_attribute_options = {}

    base.class_attribute :searchable_attribute_aliases
    base.searchable_attribute_aliases = {}

    base.extend ClassMethods

    base.attr_searchable_scope :default
  end

  module ClassMethods
    def attr_searchable(*args)
      args.each do |arg|
        attr_searchable_hash arg.is_a?(Hash) ? arg : { arg => arg }
      end
    end

    def attr_searchable_hash(hash)
      hash.each do |key, value|
        self.searchable_attributes[searchable_attribute_scope][key.to_s] = Array(value).collect do |column|
          table, attribute = column.to_s =~ /\./ ? column.to_s.split(".") : [name.tableize, column]

          "#{table}.#{attribute}"
        end
      end
    end

    def attr_searchable_options(key, options = {})
      self.searchable_attribute_options[searchable_attribute_scope][key.to_s] = (searchable_attribute_options[searchable_attribute_scope][key.to_s] || {}).merge(options)
    end

    def attr_searchable_alias(hash)
      hash.each do |key, value|
        self.searchable_attribute_aliases[searchable_attribute_scope][key.to_s] = value.respond_to?(:table_name) ? value.table_name : value.to_s
      end
    end

    def attr_searchable_scope(name)
      @searchable_attribute_scope = name

      self.searchable_attributes[name] = {}
      self.searchable_attribute_options[name] = {}
      self.searchable_attribute_aliases[name] = {}

      return unless block_given?

      yield

      self.class.send(:define_method, name) { |query| search query, name }
      self.class.send(:define_method, "unsafe_#{name}") { |query| unsafe_search query, name }
    ensure
      @searchable_attribute_scope = :default
    end

    def searchable_attribute_scope
      @searchable_attribute_scope || :default
    end

    def default_searchable_attributes(scope)
      keys = searchable_attribute_options[scope].select { |key, value| value[:default] == true }.keys
      keys = searchable_attributes[scope].keys.reject { |key| searchable_attribute_options[scope][key] && searchable_attribute_options[scope][key][:default] == false } if keys.empty?
      keys = keys.to_set

      searchable_attributes[scope].select { |key, value| keys.include? key }
    end

    def search(query, scope = :default)
      unsafe_search query, scope
    rescue AttrSearchable::RuntimeError
      respond_to?(:none) ? none : where("1 = 0")
    end

    def unsafe_search(query, scope = :default)
      return respond_to?(:scoped) ? scoped : all if query.blank?

      query_builder = QueryBuilder.new(self, query, scope)

      scope = respond_to?(:search_scope) ? search_scope : eager_load(query_builder.associations)

      scope.where query_builder.sql
    end
  end
end

