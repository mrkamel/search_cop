
module AttrSearchable
  module Arel
    module Visitors
      module ToSql
        if ::Arel::VERSION >= "4.0.1"
          def visit_AttrSearchableGrammar_Nodes_And(o, a)
            visit o.to_arel, a
          end

          def visit_AttrSearchableGrammar_Nodes_Or(o, a)
            visit o.to_arel, a
          end

          def visit_AttrSearchableGrammar_Nodes_FulltextAnd(o, a)
            visit AttrSearchableGrammar::Nodes::MatchesFulltext.new(o.nodes.first.left, o.nodes.collect(&:right).join(" ")), a
          end
        else
          def visit_AttrSearchableGrammar_Nodes_And(o)
            visit o.to_arel
          end

          def visit_AttrSearchableGrammar_Nodes_Or(o)
            visit o.to_arel
          end

          def visit_AttrSearchableGrammar_Nodes_FulltextAnd(o)
            visit AttrSearchableGrammar::Nodes::MatchesFulltext.new(o.nodes.first.left, o.nodes.collect(&:right).join(" "))
          end
        end
      end

      module MySQL
        if ::Arel::VERSION >= "4.0.1"
          def visit_AttrSearchableGrammar_Attributes_Collection(o, a)
            o.attributes.collect { |attribute| visit attribute.attribute, a }.join(", ")
          end

          def visit_AttrSearchableGrammar_Nodes_MatchesFulltext(o, a)
            "MATCH(#{visit o.left, a}) AGAINST(#{visit o.right.split(/[\s+'"<>()~-]+/).collect { |word| "+#{word}" }.join(" "), a} IN BOOLEAN MODE)"
          end

          def visit_AttrSearchableGrammar_Nodes_FulltextOr(o, a)
            "MATCH(#{visit o.nodes.first.left, a}) AGAINST(#{visit o.nodes.collect(&:right).join(" ").split(/[\s+'"<>()~-]+/).join(" "), a} IN BOOLEAN MODE)"
          end
        else
          def visit_AttrSearchableGrammar_Attributes_Collection(o)
            o.attributes.collect { |attribute| visit attribute.attribute }.join(", ")
          end

          def visit_AttrSearchableGrammar_Nodes_MatchesFulltext(o)
            "MATCH(#{visit o.left}) AGAINST(#{visit o.right.split(/[\s+'"<>()~-]+/).collect { |word| "+#{word}" }.join(" ")} IN BOOLEAN MODE)"
          end

          def visit_AttrSearchableGrammar_Nodes_FulltextOr(o)
            "MATCH(#{visit o.nodes.first.left}) AGAINST(#{visit o.nodes.collect(&:right).join(" ").split(/[\s+'"<>()~-]+/).join(" ")} IN BOOLEAN MODE)"
          end
        end
      end

      module PostgreSQL
        if ::Arel::VERSION >= "4.0.1"
          def visit_AttrSearchableGrammar_Attributes_Collection(o, a)
            o.attributes.collect { |attribute| visit attribute.attribute, a }.join(" || ' ' || ")
          end

          def visit_AttrSearchableGrammar_Nodes_MatchesFulltext(o, a)
            dictionary = o.left.options[:dictionary] || "simple"

            "to_tsvector(#{visit dictionary, a}, #{visit o.left, a}) @@ to_tsquery(#{visit dictionary, a}, #{visit o.right.split(/[\s&|!:'"]+/).join(" & "), a})"
          end

          def visit_AttrSearchableGrammar_Nodes_FulltextOr(o, a)
            dictionary = o.nodes.first.left.options[:dictionary] || "simple"

            "to_tsvector(#{visit dictionary, a}, #{visit o.nodes.first.left, a}) @@ to_tsquery(#{visit dictionary, a}, #{visit o.nodes.collect(&:right).join(" ").split(/[\s&|!:'"]+/).join(" | "), a})"
          end
        else
          def visit_AttrSearchableGrammar_Attributes_Collection(o)
            o.attributes.collect { |attribute| visit attribute.attribute }.join(" || ' ' || ")
          end

          def visit_AttrSearchableGrammar_Nodes_MatchesFulltext(o)
            dictionary = o.left.options[:dictionary] || "simple"

            "to_tsvector(#{visit dictionary, a}, #{visit o.left}) @@ to_tsquery(#{visit dictionary, a}, #{visit o.right.split(/[\s&|!:'"]+/).join(" & ")})"
          end

          def visit_AttrSearchableGrammar_Nodes_FulltextOr(o)
            dictionary = o.nodes.first.left.options[:dictionary] || "simple"

            "to_tsvector(#{visit dictionary}, #{visit o.nodes.first.left}) @@ to_tsquery(#{visit dictionary}, #{visit o.nodes.collect(&:right).join(" ").split(/[\s&|!:'"]+/).join(" | ")})"
          end
        end
      end
    end
  end
end

Arel::Visitors::PostgreSQL.send :include, AttrSearchable::Arel::Visitors::PostgreSQL
Arel::Visitors::MySQL.send :include, AttrSearchable::Arel::Visitors::MySQL
Arel::Visitors::ToSql.send :include, AttrSearchable::Arel::Visitors::ToSql

