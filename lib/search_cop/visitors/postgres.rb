
module SearchCop
  module Visitors
    module Postgres
      class FulltextQuery < Visitor
        def visit_SearchCopGrammar_Nodes_MatchesFulltextNot(node)
          text = node.right.gsub(/[\s&|!:'"]+/, " ")

          if text =~ /(?<!\\)\*\z/
            "!'#{text.gsub(/\*\z/, "")}':*"
          else
            "!'#{text}'"
          end
        end

        def visit_SearchCopGrammar_Nodes_MatchesFulltext(node)
          text = node.right.gsub(/[\s&|!:'"]+/, " ")

          if text =~ /(?<!\\)\*\z/
            "'#{text.gsub(/\*\z/, "")}':*"
          else
            "'#{text}'"
          end
        end

        def visit_SearchCopGrammar_Nodes_And_Fulltext(node)
          node.nodes.collect { |child_node| "(#{visit child_node})" }.join(" & ")
        end

        def visit_SearchCopGrammar_Nodes_Or_Fulltext(node)
          node.nodes.collect { |child_node| "(#{visit child_node})" }.join(" | ")
        end
      end

      def visit_SearchCopGrammar_Nodes_Matches(node)
        "(#{visit node.left} IS NOT NULL AND #{visit node.left} ILIKE #{visit node.right})"
      end

      def visit_SearchCopGrammar_Attributes_Collection(node)
        res = node.attributes.collect do |attribute|
          if attribute.options[:coalesce]
            "COALESCE(#{visit attribute}, '')"
          else
            visit attribute
          end
        end

        res.join(" || ' ' || ")
      end

      def visit_SearchCopGrammar_Nodes_FulltextExpression(node)
        dictionary = node.collection.options[:dictionary] || "simple"

        "to_tsvector(#{visit dictionary}, #{visit node.collection}) @@ to_tsquery(#{visit dictionary}, #{visit FulltextQuery.new(connection).visit(node.node)})"
      end
    end
  end
end

