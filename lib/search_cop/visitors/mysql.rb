
module SearchCop
  module Visitors
    module Mysql
      class FulltextQuery < Visitor
        def visit_SearchCopGrammar_Nodes_MatchesFulltextNot(node)
          node.right.split(/[\s+'"<>()~-]+/).collect { |word| "-#{word}" }.join(" ")
        end

        def visit_SearchCopGrammar_Nodes_MatchesFulltext(node)
          words = node.right.split(/[\s+'"<>()~-]+/)

          words.size > 1 ? "\"#{words.join " "}\"" : words.first
        end

        def visit_SearchCopGrammar_Nodes_And_Fulltext(node)
          res = node.nodes.collect do |child_node|
            if child_node.is_a?(SearchCopGrammar::Nodes::MatchesFulltextNot)
              visit child_node
            else
              child_node.nodes.size > 1 ? "+(#{visit child_node})" : "+#{visit child_node}"
            end
          end

          res.join " "
        end

        def visit_SearchCopGrammar_Nodes_Or_Fulltext(node)
          node.nodes.collect { |child_node| "(#{visit child_node})" }.join(" ")
        end
      end

      def visit_SearchCopGrammar_Attributes_Collection(node)
        node.attributes.collect { |attribute| visit attribute }.join(", ")
      end

      def visit_SearchCopGrammar_Nodes_FulltextExpression(node)
        "MATCH(#{visit node.collection}) AGAINST(#{visit FulltextQuery.new(connection).visit(node.node)} IN BOOLEAN MODE)"
      end
    end
  end
end

