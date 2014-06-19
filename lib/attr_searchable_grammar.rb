
require "attr_searchable_grammar/attributes"
require "attr_searchable_grammar/nodes"

module AttrSearchableGrammar
  class BaseNode < Treetop::Runtime::SyntaxNode
    attr_writer :model

    def model
      @model || parent.model
    end

    def evaluate
      elements.collect(&:evaluate).inject(:and)
    end

    def elements
      super.select { |element| element.class != Treetop::Runtime::SyntaxNode }
    end

    def collection_for(key)
      raise AttrSearchable::UnknownColumn, "Unknown key: #{key}" if model.searchable_attributes[key].nil?

      Attributes::Collection.new model, key
    end
  end

  class OperatorNode < Treetop::Runtime::SyntaxNode
    def evaluate
      text_value
    end
  end

  class ComplexExpression < BaseNode; end
  class ParenthesesExpression < BaseNode; end

  class ComparativeExpression < BaseNode
    def evaluate
      elements[0].collection.send elements[1].method_name, elements[2].text_value
    end
  end

  class IncludesOperator < OperatorNode
    def method_name
      :matches
    end
  end

  class EqualOperator < OperatorNode
    def method_name
      :eq
    end
  end

  class UnequalOperator < OperatorNode
    def method_name
      :not_eq
    end
  end

  class GreaterEqualOperator < OperatorNode
    def method_name
      :gteq
    end
  end

  class GreaterOperator < OperatorNode
    def method_name
      :gt
    end
  end

  class LessEqualOperator < OperatorNode
    def method_name
      :lteq
    end
  end

  class LessOperator < OperatorNode
    def method_name
      :lt
    end
  end

  class AnywhereExpression < BaseNode
    def evaluate
      keys = model.searchable_attribute_options.select { |key, value| value[:default] == true }.keys
      keys = model.searchable_attributes.keys if keys.empty?

      queries = keys.collect { |key| collection_for key }.select { |attribute| attribute.compatible? text_value }.collect { |attribute| attribute.matches text_value }

      raise AttrSearchable::NoSearchableAttributes unless model.searchable_attributes

      queries.flatten.inject(:or)
    end
  end

  class AndExpression < BaseNode
    def evaluate
      [elements.first.evaluate, elements.last.evaluate].inject(:and)
    end
  end

  class OrExpression < BaseNode
    def evaluate
      [elements.first.evaluate, elements.last.evaluate].inject(:or)
    end
  end

  class NotExpression < BaseNode
    def evaluate
      elements.first.evaluate.not
    end
  end

  class Column < BaseNode
    def collection
      collection_for text_value
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

