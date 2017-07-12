
require "search_cop_grammar"
require "treetop"

Treetop.load File.expand_path("../../search_cop_grammar.treetop", __FILE__)
Treetop.load File.expand_path("../../search_cop_grammar_v2.treetop", __FILE__)

module SearchCop
  class GrammarParser
    attr_reader :query_info

    def initialize(query_info)
      @query_info = query_info
    end

    def parse(string)
      node = parser_class.new.parse(string) || raise(ParseError)
      node.query_info = query_info
      node.evaluate
    end

    private

    def parser_class
      if @query_info.scope.settings[:parser] == :v2
        SearchCopGrammarV2Parser
      else
        SearchCopGrammarParser
      end
    end
  end
end

