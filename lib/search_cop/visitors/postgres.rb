
module SearchCop
  module Visitors
    module Postgres
      class FulltextQuery < Visitor
        def visit_SearchCopGrammar_Nodes_MatchesFulltextNot(node)
          "!'#{node.right.gsub(/[\s&|!:'"]+/, " ")}'"
        end

        def visit_SearchCopGrammar_Nodes_MatchesFulltext(node)
          "'#{node.right.gsub(/[\s&|!:'"]+/, " ")}'"
        end

        def visit_SearchCopGrammar_Nodes_And_Fulltext(node)
          node.nodes.collect { |child_node| "(#{visit child_node})" }.join(" & ")
        end

        def visit_SearchCopGrammar_Nodes_Or_Fulltext(node)
          node.nodes.collect { |child_node| "(#{visit child_node})" }.join(" | ")
        end
      end

      def visit_SearchCopGrammar_Nodes_Matches(node)
        "#{visit node.left} ILIKE #{visit node.right}"
      end

      def visit_SearchCopGrammar_Attributes_Collection(node)
        node.attributes.collect { |attribute| visit attribute }.join(" || ' ' || ")
      end

      def visit_SearchCopGrammar_Nodes_FulltextExpression(node)
        dictionary = node.collection.options[:dictionary] || "simple"

        "to_tsvector(#{visit dictionary}, #{visit node.collection}) @@ to_tsquery(#{visit dictionary}, #{visit FulltextQuery.new(connection).visit(node.node)})"
      end
    end
  end
end

