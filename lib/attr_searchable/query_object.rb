
module AttrSearchable
  class QueryObject
    attr_accessor :model, :ast

    def initialize(model)
      self.model = model
    end

    def parse(query)
      self.ast = query.is_a?(Hash) ? AttrSearchable::HashParser.new(self).parse(query) : AttrSearchable::GrammarParser.new(self.model).parse(query)

      self
    end

    def to_sql
      ast.optimize!.to_sql model
    end
  end
end

