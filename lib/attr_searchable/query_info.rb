
module AttrSearchable
  class QueryInfo
    attr_accessor :model, :references

    def initialize(model)
      self.model = model
      self.references = []
    end
  end
end

