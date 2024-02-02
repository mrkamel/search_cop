module SearchCop
  module Visitors
    module Sqlite
      # rubocop:disable Naming/MethodName

      def visit_SearchCopGrammar_Attributes_Json(attribute)
        "json_extract(#{quote_table_name attribute.table_alias}.#{quote_column_name attribute.column_name}, #{quote "$.#{attribute.field_names.join(".")}"})"
      end

      # rubocop:enable Naming/MethodName
    end
  end
end
