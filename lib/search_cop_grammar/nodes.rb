
require "treetop"

module SearchCopGrammar
  module Nodes
    module Base
      def and(node)
        And.new self, node
      end

      def or(node)
        Or.new self, node
      end

      def not
        Not.new self
      end

      def can_flatten?
        false
      end

      def flatten!
        self
      end

      def can_group?
        false
      end

      def group!
        self
      end

      def fulltext?
        false
      end

      def can_optimize?
        can_flatten? || can_group?
      end

      def optimize!
        flatten!.group! while can_optimize?

        finalize!
      end

      def finalize!
        self
      end

      def nodes
        []
      end
    end

    class Alias
      attr_accessor :name, :klass

      def initialize(name, klass)
        @name = name
        @klass = klass
      end
    end

    class Binary
      include Base

      attr_accessor :left, :right

      def initialize(left, right)
        @left = left
        @right = right
      end
    end

    class Equality < Binary; end
    class NotEqual < Binary; end
    class GreaterThan < Binary; end
    class GreaterThanOrEqual < Binary; end
    class LessThan < Binary; end
    class LessThanOrEqual < Binary; end
    class Matches < Binary; end

    class Not
      include Base

      attr_accessor :object

      def initialize(object)
        @object = object
      end
    end

    class MatchesFulltext < Binary
      include Base

      def not
        MatchesFulltextNot.new left, right
      end

      def fulltext?
        true
      end

      def finalize!
        FulltextExpression.new collection, self
      end

      def collection
        left
      end
    end

    class MatchesFulltextNot < MatchesFulltext; end

    class FulltextExpression
      include Base

      attr_reader :collection, :node

      def initialize(collection, node)
        @collection = collection
        @node = node
      end
    end

    class Collection
      include Base

      attr_reader :nodes

      def initialize(*nodes)
        @nodes = nodes.flatten
      end

      def can_flatten?
        nodes.any?(&:can_flatten?) || nodes.any? { |node| node.is_a?(self.class) || node.nodes.size == 1 }
      end

      def flatten!(&block)
        @nodes = nodes.collect(&:flatten!).collect { |node| node.is_a?(self.class) || node.nodes.size == 1 ? node.nodes : node }.flatten

        self
      end

      def can_group?
        nodes.reject(&:fulltext?).any?(&:can_group?) || nodes.select(&:fulltext?).group_by(&:collection).any? { |_, group| group.size > 1 }
      end

      def group!
        @nodes = nodes.reject(&:fulltext?).collect(&:group!) + nodes.select(&:fulltext?).group_by(&:collection).collect { |collection, group| group.size > 1 ? self.class::Fulltext.new(collection, group) : group.first }

        self
      end

      def finalize!
        @nodes = nodes.collect(&:finalize!)

        self
      end
    end

    class FulltextCollection < Collection
      attr_reader :collection

      def initialize(collection, *nodes)
        @collection = collection

        super *nodes
      end

      def fulltext?
        true
      end

      def finalize!
        FulltextExpression.new collection, self
      end
    end

    class And < Collection
      class Fulltext < FulltextCollection; end
    end

    class Or < Collection
      class Fulltext < FulltextCollection; end
    end
  end
end

