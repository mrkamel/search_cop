
require "treetop"

module AttrSearchableGrammar
  module Attributes
    class Collection
      def initialize(model, key)
        @attributes = model.searchable_attributes[key].collect do |attribute|
          table, column = attribute.split(".")
          klass = table.classify.constantize
          type = ((model.searchable_attribute_options[key] || {})[:type]) || klass.columns_hash[column].type

          Attributes.const_get(type.to_s.classify).new(klass.arel_table.alias(table)[column], klass)
        end
      end

      [:eq, :not_eq, :lt, :lteq, :gt, :gteq, :matches].each do |method|
        define_method method do |value|
          @attributes.collect! { |attribute| attribute.send method, value }.inject(:or)
        end
      end

      def compatible?(value)
        @attributes.all? { |attribute| attribute.compatible? value }
      end
    end

    class Base
      def initialize(attribute, klass)
        @attribute = attribute
        @klass = klass
      end

      def map(value)
        value
      end

      def compatible?(value)
        map value
      rescue AttrSearchable::IncompatibleDatatype
        false
      end

      [:eq, :not_eq, :lt, :lteq, :gt, :gteq, :matches].each do |method|
        define_method method do |value|
          return AttrSearchable::IncompatibleDatatype unless compatible?(value)

          super value
        end
      end

      def method_missing(name, *args, &block)
        @attribute.send name, *args, &block
      end

      def respond_to?(*args)
        @attribute.respond_to? *args
      end
    end

    class String < Base
      def matches_value(value)
        if value.strip =~ /^[^*]+\*$|^\*[^*]+$/
          value.gsub /\*/, "%"
        else
          "%#{value}%"
        end
      end

      def matches(value)
        super matches_value(value)
      end
    end

    class Text < String; end

    class Fulltext < Base
      def matches(value)
        matches_fulltext value
      end
    end

    class WithoutMatches < Base
      def matches(value)
        eq value
      end
    end

    class Float < WithoutMatches
      def compatible?(value)
        return true if value =~ /^[0-9]+(\.[0-9]+)?$/

        false
      end
    end

    class Integer < Float; end
    class Decimal < Float; end

    class Datetime < WithoutMatches
      def parse(value)
        return value .. value unless value.is_a?(::String)

        if value =~ /^[0-9]{4,}$/
          ::Time.new(value).beginning_of_year .. ::Time.new(value).end_of_year
        elsif value =~ /^([0-9]{4,})(\.|-|\/)([0-9]{1,2})$/
          ::Time.new($1, $3).beginning_of_month .. ::Time.new($1, $3).end_of_month
        elsif value =~ /^([0-9]{1,2})(\.|-|\/)([0-9]{4,})$/
          ::Time.new($3, $1).beginning_of_month .. ::Time.new($3, $1).end_of_month
        elsif value !~ /:/ 
          time = ::Time.parse(value)
          time.beginning_of_day .. time.end_of_day
        else
          time = ::Time.parse(value)
          time .. time
        end 
      rescue ArgumentError
        raise AttrSearchable::IncompatibleDatatype
      end 

      def map(value)
        parse(value).first
      end

      def eq(value)
        between parse(value)
      end

      def not_eq(value)
        between(parse(value)).not
      end

      def between(range)
        gteq(range.first).and(lteq(range.last))
      end
    end

    class Timestamp < Datetime; end

    class Date < Datetime
      def parse(value)
        dates = super(value).collect { |time| ::Time.parse(time).to_date }
        dates.first .. dates.last
      end
    end

    class Time < Datetime; end

    class Boolean < WithoutMatches
      def map(value)
        return true if value =~ /^(1|true|yes)$/i
        return false if value =~ /^(0|false|no)$/i

        raise AttrSearchable::IncompatibleDatatype
      end 
    end
  end
end

