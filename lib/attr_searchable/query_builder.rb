
module AttrSearchable
  class QueryBuilder
    attr_accessor :query_info, :sql

    def initialize(model, query)
      self.query_info = QueryInfo.new(model)

      arel = AttrSearchable::Parser.parse(query, query_info).optimize!

      self.sql = model.connection.visitor.accept(arel)
    end

    def associations
      all_associations - [query_info.model.name.tableize.to_sym]
    end

    private

    def all_associations
      query_info.model.searchable_attributes[:default].values.flatten.uniq.collect { |column| column.split(".").first }.collect { |column| query_info.model.searchable_attribute_aliases[:default][column] || column.to_sym }
    end
  end
end

