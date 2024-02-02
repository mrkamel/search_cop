module SearchCop
  module Visitors
    module Postgres
      # rubocop:disable Naming/MethodName

      def visit_SearchCopGrammar_Attributes_Json(attribute)
        elements = ["#{quote_table_name attribute.table_alias}.#{quote_column_name attribute.column_name}", *attribute.field_names.map { |field_name| quote(field_name) }]

        "#{elements[0...-1].join("->")}->>#{elements.last}"
      end

      def visit_SearchCopGrammar_Attributes_Jsonb(attribute)
        elements = ["#{quote_table_name attribute.table_alias}.#{quote_column_name attribute.column_name}", *attribute.field_names.map { |field_name| quote(field_name) }]

        "#{elements[0...-1].join("->")}->>#{elements.last}"
      end

      def visit_SearchCopGrammar_Attributes_Hstore(attribute)
        "#{quote_table_name attribute.table_alias}.#{quote_column_name attribute.column_name}->#{quote attribute.field_names.first}"
      end

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
        "(#{visit node.left} IS NOT NULL AND #{visit node.left} ILIKE #{visit node.right} ESCAPE #{visit "\\"})"
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

      # rubocop:enable Naming/MethodName
    end
  end
end
