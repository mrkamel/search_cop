
require "attr_searchable_grammar"
require "treetop"

Treetop.load File.expand_path("../../attr_searchable_grammar.treetop", __FILE__)

module AttrSearchable
  class GrammarParser
    attr_reader :query_info

    def initialize(query_info)
      @query_info = query_info
    end

    def parse(string)
      node = AttrSearchableGrammarParser.new.parse(string) || raise(ParseError)
      node.model = query_info.model
      node.evaluate
    end
  end
end

