
module AttrSearchable
  module Arel
    module Visitors
      module ToSql
        if ::Arel::VERSION >= "4.0.1"
          def visit_AttrSearchableGrammar_Nodes_And(o, a)
            visit ::Arel::Nodes::Grouping.new(o.to_arel), a
          end

          def visit_AttrSearchableGrammar_Nodes_Or(o, a)
            visit ::Arel::Nodes::Grouping.new(o.to_arel), a
          end
        else
          def visit_AttrSearchableGrammar_Nodes_And(o)
            visit ::Arel::Nodes::Grouping.new(o.to_arel)
          end

          def visit_AttrSearchableGrammar_Nodes_Or(o)
            visit ::Arel::Nodes::Grouping.new(o.to_arel)
          end
        end
      end

      module MySQL
        if ::Arel::VERSION >= "4.0.1"
          def visit_AttrSearchableGrammar_Attributes_Collection(o, a)
            o.attributes.collect { |attribute| visit attribute.attribute, a }.join(", ")
          end

          def visit_AttrSearchableGrammar_Nodes_FulltextExpression(o, a)
            "MATCH(#{visit o.collection, a}) AGAINST(#{visit visit(o.node, a), a} IN BOOLEAN MODE)"
          end

          def visit_AttrSearchableGrammar_Nodes_MatchesFulltextNot(o, a)
            "-\"#{o.right.gsub(/[\s+'"<>()~-]+/, " ")}\""
          end

          def visit_AttrSearchableGrammar_Nodes_MatchesFulltext(o, a)
            "\"#{o.right.gsub(/[\s+'"<>()~-]+/, " ")}\""
          end

          def visit_AttrSearchableGrammar_Nodes_FulltextAnd(o, a)
            o.nodes.collect { |node| node.is_a?(AttrSearchableGrammar::Nodes::MatchesFulltextNot) ? visit(node, a) : "+(#{visit node, a})" }.join(" ")
          end

          def visit_AttrSearchableGrammar_Nodes_FulltextOr(o, a)
            o.nodes.collect { |node| "(#{visit node, a})" }.join(" ")
          end
        else
          def visit_AttrSearchableGrammar_Attributes_Collection(o)
            o.attributes.collect { |attribute| visit attribute.attribute }.join(", ")
          end

          def visit_AttrSearchableGrammar_Nodes_FulltextExpression(o)
            "MATCH(#{visit o.collection}) AGAINST(#{visit visit(o.node)} IN BOOLEAN MODE)"
          end

          def visit_AttrSearchableGrammar_Nodes_MatchesFulltextNot(o)
            "-\"#{o.right.gsub(/[\s+'"<>()~-]+/, " ")}\""
          end

          def visit_AttrSearchableGrammar_Nodes_MatchesFulltext(o)
            "\"#{o.right.gsub(/[\s+'"<>()~-]+/, " ")}\""
          end

          def visit_AttrSearchableGrammar_Nodes_FulltextAnd(o)
            o.nodes.collect { |node| node.is_a?(AttrSearchableGrammar::Nodes::MatchesFulltextNot) ? visit(node) : "+(#{visit node})" }.join(" ")
          end

          def visit_AttrSearchableGrammar_Nodes_FulltextOr(o)
            o.nodes.collect { |node| "(#{visit node})" }.join(" ")
          end
        end
      end

      module PostgreSQL
        if ::Arel::VERSION >= "4.0.1"
          def visit_AttrSearchableGrammar_Attributes_Collection(o, a)
            o.attributes.collect { |attribute| visit attribute.attribute, a }.join(" || ' ' || ")
          end

          def visit_AttrSearchableGrammar_Nodes_FulltextExpression(o, a)
            dictionary = o.collection.options[:dictionary] || "simple"

            "to_tsvector(#{visit dictionary, a}, #{visit o.collection, a}) @@ to_tsquery(#{visit dictionary, a}, #{visit visit(o.node, a), a})"
          end

          def visit_AttrSearchableGrammar_Nodes_MatchesFulltextNot(o, a)
            "!'#{o.right}'"
          end

          def visit_AttrSearchableGrammar_Nodes_MatchesFulltext(o, a)
            "'#{o.right.gsub /[\s&|!:'"]+/, " "}'"
          end

          def visit_AttrSearchableGrammar_Nodes_FulltextAnd(o, a)
            o.nodes.collect { |node| "(#{visit node, a})" }.join(" & ")
          end

          def visit_AttrSearchableGrammar_Nodes_FulltextOr(o, a)
            o.nodes.collect { |node| "(#{visit node, a})" }.join(" | ")
          end
        else
          def visit_AttrSearchableGrammar_Attributes_Collection(o)
            o.attributes.collect { |attribute| visit attribute.attribute }.join(" || ' ' || ")
          end

          def visit_AttrSearchableGrammar_Nodes_FulltextExpression(o)
            dictionary = o.collection.options[:dictionary] || "simple"

            "to_tsvector(#{visit dictionary}, #{visit o.collection}) @@ to_tsquery(#{visit dictionary}, #{visit visit(o.node)})"
          end

          def visit_AttrSearchableGrammar_Nodes_MatchesFulltextNot(o)
            "!'#{o.right}'"
          end

          def visit_AttrSearchableGrammar_Nodes_MatchesFulltext(o)
            "'#{o.right.gsub /[\s&|!:'"]+/, " "}'"
          end

          def visit_AttrSearchableGrammar_Nodes_FulltextAnd(o)
            o.nodes.collect { |node| "(#{visit node})" }.join(" & ")
          end

          def visit_AttrSearchableGrammar_Nodes_FulltextOr(o)
            o.nodes.collect { |node| "(#{visit node})" }.join(" | ")
          end
        end
      end
    end
  end
end

Arel::Visitors::PostgreSQL.send :include, AttrSearchable::Arel::Visitors::PostgreSQL
Arel::Visitors::MySQL.send :include, AttrSearchable::Arel::Visitors::MySQL
Arel::Visitors::ToSql.send :include, AttrSearchable::Arel::Visitors::ToSql

