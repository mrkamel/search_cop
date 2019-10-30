module SearchCop
  class QueryInfo
    attr_accessor :model, :scope, :references

    def initialize(model, scope)
      self.model = model
      self.scope = scope
      self.references = []
    end
  end
end
