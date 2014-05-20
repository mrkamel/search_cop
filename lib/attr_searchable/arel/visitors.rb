
module AttrSearchable
  module Arel
    module Visitors
      module MySQL
        if ::Arel::VERSION >= "4.0.1"
          def visit_AttrSearchableGrammar_Attributes_Collection(o, a)
            o.attributes.collect { |attribute| visit attribute.attribute, a }.join(", ")
          end

          def visit_AttrSearchableGrammar_Nodes_MatchesFulltext(o, a)
            "MATCH(#{visit o.left, a}) AGAINST(#{visit o.right.split(/[\s+'"<>()~-]+/).collect { |word| "+#{word}" }.join(" "), a} IN BOOLEAN MODE)"
          end
        else
          def visit_AttrSearchableGrammar_Attributes_Collection(o)
            o.attributes.collect { |attribute| visit attribute.attribute }.join(", ")
          end

          def visit_AttrSearchableGrammar_Nodes_MatchesFulltext(o)
            "MATCH(#{visit o.left}) AGAINST(#{visit o.right.split(/[\s+'"<>()~-]+/).collect { |word| "+#{word}" }.join(" ")} IN BOOLEAN MODE)"
          end
        end
      end

      module PostgreSQL
        if ::Arel::VERSION >= "4.0.1"
          def visit_AttrSearchableGrammar_Attributes_Collection(o, a)
            o.attributes.collect { |attribute| visit attribute.attribute, a }.join(" || ' ' || ")
          end

          def visit_AttrSearchableGrammar_Nodes_MatchesFulltext(o, a)
            "to_tsvector('simple', #{visit o.left, a}) @@ to_tsquery('simple', #{visit o.right.split(/[\s&|!:'"]+/).join(" & "), a})"
          end
        else
          def visit_AttrSearchableGrammar_Attributes_Collection(o)
            o.attributes.collect { |attribute| visit attribute.attribute }.join(" || ' ' || ")
          end

          def visit_AttrSearchableGrammar_Nodes_MatchesFulltext(o)
            "to_tsvector('simple', #{visit o.left}) @@ to_tsquery('simple', #{visit o.right.split(/[\s&|!:'"]+/).join(" & ")})"
          end
        end
      end
    end
  end
end

Arel::Visitors::PostgreSQL.send :include, AttrSearchable::Arel::Visitors::PostgreSQL
Arel::Visitors::MySQL.send :include, AttrSearchable::Arel::Visitors::MySQL

