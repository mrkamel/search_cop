require "search_cop/version"
require "search_cop/search_scope"
require "search_cop/query_info"
require "search_cop/query_builder"
require "search_cop/grammar_parser"
require "search_cop/hash_parser"
require "search_cop/visitors"

module SearchCop
  class Error < StandardError; end

  class SpecificationError < Error; end
  class UnknownAttribute < SpecificationError; end
  class UnknownDefaultOperator < SpecificationError; end

  class RuntimeError < Error; end
  class UnknownColumn < RuntimeError; end
  class NoSearchableAttributes < RuntimeError; end
  class IncompatibleDatatype < RuntimeError; end
  class ParseError < RuntimeError; end

  module Parser
    def self.parse(query, query_info, query_options = {})
      if query.is_a?(Hash)
        SearchCop::HashParser.new(query_info).parse(query)
      else
        SearchCop::GrammarParser.new(query_info).parse(query, query_options)
      end
    end
  end

  def self.included(base)
    base.extend ClassMethods

    base.class_attribute :search_scopes
    base.search_scopes = {}
  end

  module ClassMethods
    def search_scope(name, &block)
      self.search_scopes = search_scopes.dup

      search_scopes[name] = SearchScope.new(name, self)
      search_scopes[name].instance_exec(&block)

      send(:define_singleton_method, name) { |query, query_options = {}| search_cop query, name, query_options }
      send(:define_singleton_method, "unsafe_#{name}") { |query, query_options = {}| unsafe_search_cop query, name, query_options }
    end

    def search_reflection(scope_name)
      search_scopes[scope_name].reflection
    end

    def search_cop(query, scope_name, query_options)
      unsafe_search_cop query, scope_name, query_options
    rescue SearchCop::RuntimeError
      respond_to?(:none) ? none : where("1 = 0")
    end

    def unsafe_search_cop(query, scope_name, query_options)
      return respond_to?(:scoped) ? scoped : all if query.blank?

      query_builder = QueryBuilder.new(self, query, search_scopes[scope_name], query_options)

      scope = instance_exec(&search_scopes[scope_name].reflection.scope) if search_scopes[scope_name].reflection.scope
      scope ||= eager_load(query_builder.associations) if query_builder.associations.any?

      (scope || self).where(query_builder.sql)
    end
  end

  module Helpers
    def self.sanitize_default_operator(hash, delete_hash_option = false)
      default_operator = :and
      if hash.member?(:default_operator)
        unless [:and, :or].include?(hash[:default_operator])
          raise(SearchCop::UnknownDefaultOperator, "Unknown default operator value #{hash[:default_operator]}")
        end

        default_operator = hash[:default_operator]
      end

      hash.delete(:default_operator) if delete_hash_option

      default_operator
    end
  end
end
