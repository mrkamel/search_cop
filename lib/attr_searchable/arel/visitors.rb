
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

          def visit_AttrSearchableGrammar_Nodes_Equality(o, a)
            visit ::Arel::Nodes::Equality.new(o.left, o.right), a
          end

          def visit_AttrSearchableGrammar_Nodes_NotEqual(o, a)
            visit ::Arel::Nodes::NotEqual.new(o.left, o.right), a
          end

          def visit_AttrSearchableGrammar_Nodes_LessThan(o, a)
            visit ::Arel::Nodes::LessThan.new(o.left, o.right), a
          end

          def visit_AttrSearchableGrammar_Nodes_LessThanOrEqual(o, a)
            visit ::Arel::Nodes::LessThanOrEqual.new(o.left, o.right), a
          end

          def visit_AttrSearchableGrammar_Nodes_GreaterThan(o, a)
            visit ::Arel::Nodes::GreaterThan.new(o.left, o.right), a
          end

          def visit_AttrSearchableGrammar_Nodes_GreaterThanOrEqual(o, a)
            visit ::Arel::Nodes::GreaterThanOrEqual.new(o.left, o.right), a
          end

          def visit_AttrSearchableGrammar_Nodes_Not(o, a)
            visit ::Arel::Nodes::Not.new(o.object), a
          end

          def visit_AttrSearchableGrammar_Nodes_Matches(o, a)
            visit ::Arel::Nodes::Matches.new(o.left, o.right), a
          end
        else
          def visit_AttrSearchableGrammar_Nodes_And(o)
            visit ::Arel::Nodes::Grouping.new(o.to_arel)
          end

          def visit_AttrSearchableGrammar_Nodes_Or(o)
            visit ::Arel::Nodes::Grouping.new(o.to_arel)
          end

          def visit_AttrSearchableGrammar_Nodes_Equality(o)
            visit ::Arel::Nodes::Equality.new(o.left, o.right)
          end

          def visit_AttrSearchableGrammar_Nodes_NotEqual(o)
            visit ::Arel::Nodes::NotEqual.new(o.left, o.right)
          end

          def visit_AttrSearchableGrammar_Nodes_LessThan(o)
            visit ::Arel::Nodes::LessThan.new(o.left, o.right)
          end

          def visit_AttrSearchableGrammar_Nodes_LessThanOrEqual(o)
            visit ::Arel::Nodes::LessThanOrEqual.new(o.left, o.right)
          end

          def visit_AttrSearchableGrammar_Nodes_GreaterThan(o)
            visit ::Arel::Nodes::GreaterThan.new(o.left, o.right)
          end

          def visit_AttrSearchableGrammar_Nodes_GreaterThanOrEqual(o)
            visit ::Arel::Nodes::GreaterThanOrEqual.new(o.left, o.right)
          end

          def visit_AttrSearchableGrammar_Nodes_Not(o)
            visit ::Arel::Nodes::Not.new(o.object)
          end

          def visit_AttrSearchableGrammar_Nodes_Matches(o)
            visit ::Arel::Nodes::Matches.new(o.left, o.right)
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
            o.right.split(/[\s+'"<>()~-]+/).collect { |word| "-#{word}" }.join(" ")
          end

          def visit_AttrSearchableGrammar_Nodes_MatchesFulltext(o, a)
            words = o.right.split(/[\s+'"<>()~-]+/)

            words.size > 1 ? "\"#{words.join " "}\"" : words.first
          end

          def visit_AttrSearchableGrammar_Nodes_And_Fulltext(o, a)
            res = o.nodes.collect do |node|
              if node.is_a?(AttrSearchableGrammar::Nodes::MatchesFulltextNot)
                visit node, a
              else
                node.nodes.size > 1 ? "+(#{visit node, a})" : "+#{visit node, a}"
              end
            end

            res.join " "
          end

          def visit_AttrSearchableGrammar_Nodes_Or_Fulltext(o, a)
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
            o.right.split(/[\s+'"<>()~-]+/).collect { |word| "-#{word}" }.join(" ")
          end

          def visit_AttrSearchableGrammar_Nodes_MatchesFulltext(o)
            words = o.right.split(/[\s+'"<>()~-]+/)

            words.size > 1 ? "\"#{words.join " "}\"" : words.first
          end

          def visit_AttrSearchableGrammar_Nodes_And_Fulltext(o)
            res = o.nodes.collect do |node|
              if node.is_a?(AttrSearchableGrammar::Nodes::MatchesFulltextNot)
                visit node
              else
                node.nodes.size > 1 ? "+(#{visit node})" : "+#{visit node}"
              end
            end

            res.join " "
          end

          def visit_AttrSearchableGrammar_Nodes_Or_Fulltext(o)
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

          def visit_AttrSearchableGrammar_Nodes_And_Fulltext(o, a)
            o.nodes.collect { |node| "(#{visit node, a})" }.join(" & ")
          end

          def visit_AttrSearchableGrammar_Nodes_Or_Fulltext(o, a)
            o.nodes.collect { |node| "(#{visit node, a})" }.join(" | ")
          end
        else
          def visit_AttrSearchableGrammar_Attributes_Collection(o)
            o.attributes.collect { |attribute| visit attribute.attribute }.join(" || ' ' || ")
          end

          def visit_AttrSearchableGrammar_Nodes_FulltextExpression(o)
            dictionary = o.collection.options[:dictionary] || "simple"

            "to_tsvector(#{visit dictionary.to_sym}, #{visit o.collection}) @@ to_tsquery(#{visit dictionary.to_sym}, #{visit visit(o.node)})" # to_sym fixes a 3.2 + postgres bug
          end

          def visit_AttrSearchableGrammar_Nodes_MatchesFulltextNot(o)
            "!'#{o.right}'"
          end

          def visit_AttrSearchableGrammar_Nodes_MatchesFulltext(o)
            "'#{o.right.gsub /[\s&|!:'"]+/, " "}'"
          end

          def visit_AttrSearchableGrammar_Nodes_And_Fulltext(o)
            o.nodes.collect { |node| "(#{visit node})" }.join(" & ")
          end

          def visit_AttrSearchableGrammar_Nodes_Or_Fulltext(o)
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

