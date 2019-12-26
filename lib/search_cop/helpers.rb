module SearchCop
  module Helpers
    def self.sanitize_default_operator(query_options)
      return "and" unless query_options.key?(:default_operator)

      default_operator = query_options[:default_operator].to_s.downcase

      unless ["and", "or"].include?(default_operator)
        raise(SearchCop::UnknownDefaultOperator, "Unknown default operator value #{default_operator}")
      end

      default_operator
    end
  end
end
