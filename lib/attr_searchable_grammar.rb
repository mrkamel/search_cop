
require "attr_searchable_grammar/attributes"
require "attr_searchable_grammar/nodes"

module AttrSearchableGrammar
  class BaseNode < Treetop::Runtime::SyntaxNode
    attr_writer :model

    def model
      @model || parent.model
    end

    def to_arel
      elements.collect(&:to_arel).inject(:and)
    end

    def elements
      super.select { |element| element.class != Treetop::Runtime::SyntaxNode }
    end

    def arel_collection_for(key)
      raise AttrSearchable::UnknownColumn, "Unknown key: #{key}" if model.searchable_attributes[key].nil?

      Attributes::Collection.new model, key
    end
  end

  class OperatorNode < Treetop::Runtime::SyntaxNode
    def to_arel
      text_value
    end
  end

  class ComplexExpression < BaseNode; end

  class ParenthesesExpression < BaseNode
    #def to_arel
    #  model.arel_table.grouping(elements[0].to_arel)
    #end
  end

  class ComparativeExpression < BaseNode
    def to_arel
      elements[0].arel_collection.send elements[1].to_arel_method, elements[2].text_value
    end
  end

  class IncludesOperator < OperatorNode
    def to_arel_method
      :matches
    end
  end

  class EqualOperator < OperatorNode
    def to_arel_method
      :eq
    end
  end

  class UnequalOperator < OperatorNode
    def to_arel_method
      :not_eq
    end
  end

  class GreaterEqualOperator < OperatorNode
    def to_arel_method
      :gteq
    end
  end

  class GreaterOperator < OperatorNode
    def to_arel_method
      :gt
    end
  end

  class LessEqualOperator < OperatorNode
    def to_arel_method
      :lteq
    end
  end

  class LessOperator < OperatorNode
    def to_arel_method
      :lt
    end
  end

  class AnywhereExpression < BaseNode
    def to_arel
      keys = model.searchable_attribute_options.select { |key, value| value[:default] == true }.keys
      keys = model.searchable_attributes.keys if keys.empty?

      queries = keys.collect { |key| arel_collection_for key }.select { |attribute| attribute.compatible? text_value }.collect { |attribute| attribute.matches text_value }

      raise AttrSearchable::NoSearchableAttributes unless model.searchable_attributes

      queries.flatten.inject(:or)
    end
  end

  class AndExpression < BaseNode
    def to_arel
      [elements.first.to_arel, elements.last.to_arel].inject(:and)
    end
  end

  class OrExpression < BaseNode
    def to_arel
      [elements.first.to_arel, elements.last.to_arel].inject(:or)
    end
  end

  class NotExpression < BaseNode
    def to_arel
      elements.first.to_arel.not
    end
  end

  class Column < BaseNode
    def arel_collection
      arel_collection_for text_value
    end
  end

  class SingleQuotedValue < BaseNode
    def text_value
      super.gsub /^'|'$/, ""
    end
  end

  class DoubleQuotedValue < BaseNode
    def text_value
      super.gsub /^"|"$/, ""
    end
  end

  class Value < BaseNode; end
end

