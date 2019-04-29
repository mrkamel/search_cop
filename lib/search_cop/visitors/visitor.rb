
module SearchCop
  module Visitors
    class Visitor
      attr_accessor :connection

      def initialize(connection)
        @connection = connection

        extend(SearchCop::Visitors::Mysql) if @connection.adapter_name =~ /mysql/i
        extend(SearchCop::Visitors::Postgres) if @connection.adapter_name =~ /postgres/i
      end

      def visit(visit_node = node)
        send "visit_#{visit_node.class.name.gsub(/::/, "_")}", visit_node
      end

      def visit_SearchCopGrammar_Nodes_And(node)
        "(#{node.nodes.collect { |n| visit n }.join(" AND ")})"
      end

      def visit_SearchCopGrammar_Nodes_Or(node)
        "(#{node.nodes.collect { |n| visit n }.join(" OR ")})"
      end

      def visit_SearchCopGrammar_Nodes_GreaterThan(node)
        "#{visit node.left} > #{visit node.right}"
      end

      def visit_SearchCopGrammar_Nodes_GreaterThanOrEqual(node)
        "#{visit node.left} >= #{visit node.right}"
      end

      def visit_SearchCopGrammar_Nodes_LessThan(node)
        "#{visit node.left} < #{visit node.right}"
      end

      def visit_SearchCopGrammar_Nodes_LessThanOrEqual(node)
        "#{visit node.left} <= #{visit node.right}"
      end

      def visit_SearchCopGrammar_Nodes_Equality(node)
        "#{visit node.left} = #{visit node.right}"
      end

      def visit_SearchCopGrammar_Nodes_NotEqual(node)
        "#{visit node.left} != #{visit node.right}"
      end

      def visit_SearchCopGrammar_Nodes_Matches(node)
        "(#{visit node.left} IS NOT NULL AND #{visit node.left} LIKE #{visit node.right})"
      end

      def visit_SearchCopGrammar_Nodes_Not(node)
        "NOT (#{visit node.object})"
      end

      def visit_SearchCopGrammar_Nodes_Generator(node)
        instance_exec visit(node.left), node.right[:value], &node.right[:generator]
      end

      def quote_table_name(name)
        connection.quote_table_name name
      end

      def quote_column_name(name)
        connection.quote_column_name name
      end

      def visit_attribute(attribute)
        "#{quote_table_name attribute.table_alias}.#{quote_column_name attribute.column_name}"
      end

      alias :visit_SearchCopGrammar_Attributes_String :visit_attribute
      alias :visit_SearchCopGrammar_Attributes_Text :visit_attribute
      alias :visit_SearchCopGrammar_Attributes_Float :visit_attribute
      alias :visit_SearchCopGrammar_Attributes_Integer :visit_attribute
      alias :visit_SearchCopGrammar_Attributes_Decimal :visit_attribute
      alias :visit_SearchCopGrammar_Attributes_Datetime :visit_attribute
      alias :visit_SearchCopGrammar_Attributes_Timestamp :visit_attribute
      alias :visit_SearchCopGrammar_Attributes_Date :visit_attribute
      alias :visit_SearchCopGrammar_Attributes_Time :visit_attribute
      alias :visit_SearchCopGrammar_Attributes_Boolean :visit_attribute

      def quote(value)
        connection.quote value
      end

      alias :visit_TrueClass :quote
      alias :visit_FalseClass :quote
      alias :visit_String :quote
      alias :visit_Time :quote
      alias :visit_Date :quote
      alias :visit_Float :quote
      alias :visit_Fixnum :quote
      alias :visit_Symbol :quote
      alias :visit_Integer :quote
    end
  end
end

