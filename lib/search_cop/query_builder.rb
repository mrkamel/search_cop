
module SearchCop
  class QueryBuilder
    attr_accessor :query_info, :scope, :sql

    def initialize(model, query, scope, query_options)
      self.scope = scope
      self.query_info = QueryInfo.new(model, scope)

      arel = SearchCop::Parser.parse(query, query_info, query_options).optimize!

      self.sql = SearchCop::Visitors::Visitor.new(model.connection).visit(arel)
    end

    def associations
      all_associations - [query_info.model.name.tableize.to_sym]
    end

    private

    def all_associations
      scope.reflection.attributes.values.flatten.collect { |column| association_for column.split(".").first }.uniq
    end

    def association_for(column)
      alias_value = scope.reflection.aliases[column]

      association = alias_value.respond_to?(:table_name) ? alias_value.table_name : alias_value
      association ||= column

      association.to_sym
    end
  end
end

