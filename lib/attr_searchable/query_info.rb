
module AttrSearchable
  class QueryInfo
    attr_accessor :model

    def initialize(model)
      self.model = model
    end
  end
end

