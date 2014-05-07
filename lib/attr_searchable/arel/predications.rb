
module Arel::Predications
  def matches_fulltext(other)
    Arel::Nodes::MatchesFulltext.new self, other
  end
end

