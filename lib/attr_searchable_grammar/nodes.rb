
require "treetop"

module AttrSearchableGrammar
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

      def can_reduce?
        false
      end

      def reduce!
        self
      end

      def can_group?
        false
      end

      def group!
        self
      end

      def can_optimize?
        can_flatten? || can_reduce? || can_group?
      end

      def optimize!
        flatten!.reduce!.group! while can_optimize?

        self
      end

      def finalize!
        fulltext? ? FulltextExpression.new(collection, self) : self
      end

      def fulltext?
        false
      end
    end

    ["Equality", "NotEqual", "GreaterThan", "LessThan", "GreaterThanOrEqual", "LessThanOrEqual", "Matches", "Not"].each do |name|
      const_set name, Class.new(Arel::Nodes.const_get(name))
      const_get(name).send :include, Base
    end

    class MatchesFulltext < Arel::Nodes::Binary
      include Base

      def not
        MatchesFulltextNot.new left, right
      end

      def fulltext?
        true
      end

      def collection
        left
      end
    end

    class MatchesFulltextNot < MatchesFulltext; end

    class FulltextExpression < Arel::Nodes::Node
      include Base

      attr_reader :collection, :node

      def initialize(collection, node)
        @collection = collection
        @node = node
      end
    end

    class Collection < Arel::Nodes::Node
      include Base

      attr_reader :nodes

      def initialize(*nodes)
        @nodes = nodes.flatten
      end

      def can_flatten?
        @nodes.any?(&:can_flatten?) || @nodes.any? { |node| node.is_a? self.class }
      end

      def flatten!
        @nodes = @nodes.collect(&:flatten!).collect { |node| node.is_a?(self.class) ? node.nodes : node }.flatten

        self
      end

      def can_reduce?
        @nodes.any?(&:can_reduce?) || @nodes.any? { |node| node.respond_to?(:nodes) && node.nodes.size == 1 }
      end
        
      def reduce!
        @nodes = @nodes.collect(&:reduce!).collect { |node| node.respond_to?(:nodes) && node.nodes.size == 1 ? node.nodes : node }.flatten

        self
      end

      def can_group?
        standard_nodes.any?(&:can_group?) || fulltext_groups.any? { |_, group| group.size > 1 }
      end

      def group!
        @nodes = standard_nodes.collect(&:group!) + fulltext_groups.collect do |collection, group|
          if group.size > 1
            fulltext_collection_type.new collection, *group.collect { |node| node.is_a?(fulltext_collection_type) ? node.nodes : node }
          else
            group.first
          end
        end

        self
      end

      def finalize!
        @nodes = @nodes.collect { |node| node.fulltext? ? FulltextExpression.new(node.collection, node) : node.finalize! }

        self
      end

      def fulltext_groups
        @nodes.select(&:fulltext?).group_by(&:collection)
      end

      def standard_nodes
        @nodes.reject(&:fulltext?)
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
    end

    class FulltextAnd < FulltextCollection; end

    class And < Collection
      def fulltext_collection_type
        FulltextAnd
      end

      def to_arel
        @nodes.inject { |res, cur| Arel::Nodes::And.new [res, cur] }
      end
    end

    class FulltextOr < FulltextCollection; end

    class Or < Collection
      def fulltext_collection_type
        FulltextOr
      end

      def to_arel
        @nodes.inject { |res, cur| Arel::Nodes::Or.new res, cur }
      end
    end
  end
end

