
module SearchCop
  module Visitors
    module Mysql
      def visit_SearchCopGrammar_Attributes_Collection(node)
        node.attributes.collect { |attribute| visit attribute }.join(", ")
      end 

      def visit_SearchCopGrammar_Nodes_FulltextExpression(node)
        "MATCH(#{visit node.collection}) AGAINST(#{visit visit(node.node)} IN BOOLEAN MODE)"
      end 

      def visit_SearchCopGrammar_Nodes_MatchesFulltextNot(node)
        node.right.split(/[\s+'"<>()~-]+/).collect { |word| "-#{word}" }.join(" ")
      end 

      def visit_SearchCopGrammar_Nodes_MatchesFulltext(node)
        words = node.right.split(/[\s+'"<>()~-]+/)

        words.size > 1 ? "\"#{words.join " "}\"" : words.first
      end 

      def visit_SearchCopGrammar_Nodes_And_Fulltext(node)
        res = node.nodes.collect do |node|
          if node.is_a?(SearchCopGrammar::Nodes::MatchesFulltextNot)
            visit node
          else
            node.nodes.size > 1 ? "+(#{visit node})" : "+#{visit node}"
          end 
        end 

        res.join " " 
      end 

      def visit_SearchCopGrammar_Nodes_Or_Fulltext(node)
        node.nodes.collect { |node| "(#{visit node})" }.join(" ")
      end 
    end
  end
end

