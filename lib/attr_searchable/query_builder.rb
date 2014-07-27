
module AttrSearchable
  class QueryBuilder
    attr_accessor :query_info, :sql

    def initialize(model, query, scope)
      self.query_info = QueryInfo.new(model, scope)

      arel = AttrSearchable::Parser.parse(query, query_info).optimize!

      self.sql = model.connection.visitor.accept(arel)
    end

    def associations
      all_associations - [query_info.model.name.tableize.to_sym]
    end

    private

    def all_associations
      query_info.model.searchable_attributes[query_info.scope].values.flatten.uniq.collect { |column| column.split(".").first }.collect { |column| query_info.model.searchable_attribute_aliases[query_info.scope][column] || column.to_sym }
    end
  end
end

