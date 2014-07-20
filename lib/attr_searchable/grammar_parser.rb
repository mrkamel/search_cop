
require "attr_searchable_grammar"
require "treetop"

Treetop.load File.expand_path("../../attr_searchable_grammar.treetop", __FILE__)

module AttrSearchable
  class GrammarParser
    attr_reader :model

    def initialize(model)
      @model = model
    end

    def parse(string)
      node = AttrSearchableGrammarParser.new.parse(string) || raise(ParseError)
      node.model = model
      node.evaluate
    end
  end
end

