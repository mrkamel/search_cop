
require "search_cop_grammar"
require "treetop"

Treetop.load File.expand_path("../../search_cop_grammar.treetop", __FILE__)

module SearchCop
  class GrammarParser
    attr_reader :query_info

    def initialize(query_info)
      @query_info = query_info
    end

    def parse(string)
      string = parse_in_operator string
      node = SearchCopGrammarParser.new.parse(string) || raise(ParseError)
      node.query_info = query_info
      node.evaluate
    end

    def parse_in_operator(string)
      in_operator_regex = /(([a-zA-Z_]*) in \(([a-zA-Z0-9_|, ]*)\))/
      string.scan(in_operator_regex).each do |in_exp, param, list|
        subquery = list.split(",").map(&:strip).map do |value|
          "#{param} = #{value}"
        end.join(" or ")

        string = string.sub(in_exp, "(#{subquery})")
      end

      string
    end
  end
end

