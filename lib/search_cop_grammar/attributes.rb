
require "treetop"

module SearchCopGrammar
  module Attributes
    class Collection
      attr_reader :query_info, :key

      def initialize(query_info, key)
        raise(SearchCop::UnknownColumn, "Unknown column #{key}") unless query_info.scope.reflection.attributes[key]

        @query_info = query_info
        @key = key
      end

      def eql?(other)
        self == other
      end

      def ==(other)
        other.is_a?(self.class) && [query_info.model, key] == [query_info.model, other.key]
      end

      def hash
        [query_info.model, key].hash
      end

      [:eq, :not_eq, :lt, :lteq, :gt, :gteq].each do |method|
         define_method method do |value|
           attributes.collect! { |attribute| attribute.send method, value }.inject(:or)
         end
      end

      def matches(value)
        if fulltext?
          SearchCopGrammar::Nodes::MatchesFulltext.new self, value.to_s
        else
          attributes.collect! { |attribute| attribute.matches value }.inject(:or)
        end
      end

      def fulltext?
        (query_info.scope.reflection.options[key] || {})[:type] == :fulltext
      end

      def compatible?(value)
        attributes.all? { |attribute| attribute.compatible? value }
      end

      def options
        query_info.scope.reflection.options[key]
      end

      def attributes
        @attributes ||= query_info.scope.reflection.attributes[key].collect { |attribute_definition| attribute_for attribute_definition }
      end

      def klass_for_association(name)
        reflections = query_info.model.reflections

        return reflections[name].klass if reflections[name]
        return reflections[name.to_sym].klass if reflections[name.to_sym]

        nil
      end

      def klass_for(name)
        mapped_name = query_info.scope.reflection.aliases[name]
        mapped_name ||= name

        klass_for_association(mapped_name) || mapped_name.classify.constantize
      end

      def alias_for(name)
        (query_info.scope.reflection.aliases[name] && name) || klass_for(name).table_name
      end

      def attribute_for(attribute_definition)
        query_info.references.push attribute_definition

        table, column = attribute_definition.split(".")
        klass = klass_for(table)

        raise(SearchCop::UnknownAttribute, "Unknown attribute #{attribute_definition}") unless klass.columns_hash[column]

        Attributes.const_get(klass.columns_hash[column].type.to_s.classify).new(klass, alias_for(table), column, options)
      end
    end

    class Base
      attr_reader :attribute, :table_alias, :column_name, :options

      def initialize(klass, table_alias, column_name, options = {})
        @attribute = klass.arel_table.alias(table_alias)[column_name]
        @klass = klass
        @table_alias = table_alias
        @column_name = column_name
        @options = (options || {})
      end

      def map(value)
        value
      end

      def compatible?(value)
        map value

        true
      rescue SearchCop::IncompatibleDatatype
        false
      end

      def fulltext?
        false
      end

      { :eq => "Equality", :not_eq => "NotEqual", :lt => "LessThan", :lteq => "LessThanOrEqual", :gt => "GreaterThan", :gteq => "GreaterThanOrEqual", :matches => "Matches" }.each do |method, class_name|
        define_method method do |value|
          raise(SearchCop::IncompatibleDatatype, "Incompatible datatype for #{value}") unless compatible?(value)

          SearchCopGrammar::Nodes.const_get(class_name).new(self, map(value))
        end
      end

      def method_missing(name, *args, &block)
        @attribute.send(name, *args, &block)
      end

      def respond_to?(*args)
        super(*args) || @attribute.respond_to?(*args)
      end
    end

    class String < Base
      def matches_value(value)
        return value.gsub(/\*/, "%") if (options[:left_wildcard] != false && value.strip =~ /^[^*]+\*$|^\*[^*]+$/) || value.strip =~ /^[^*]+\*$/

        options[:left_wildcard] != false ? "%#{value}%" : "#{value}%"
      end

      def matches(value)
        super matches_value(value)
      end
    end

    class Text < String; end

    class WithoutMatches < Base
      def matches(value)
        eq value
      end
    end

    class Float < WithoutMatches
      def compatible?(value)
        return true if value.to_s =~ /^[0-9]+(\.[0-9]+)?$/

        false
      end

      def map(value)
        value.to_f
      end
    end

    class Integer < Float
      def map(value)
        value.to_i
      end
    end

    class Decimal < Float; end

    class Datetime < WithoutMatches
      def parse(value)
        return value .. value unless value.is_a?(::String)

        if value =~ /^[0-9]{4,}$/
          ::Time.new(value).beginning_of_year .. ::Time.new(value).end_of_year
        elsif value =~ /^([0-9]{4,})(\.|-|\/)([0-9]{1,2})$/
          ::Time.new($1, $3, 15).beginning_of_month .. ::Time.new($1, $3, 15).end_of_month
        elsif value =~ /^([0-9]{1,2})(\.|-|\/)([0-9]{4,})$/
          ::Time.new($3, $1, 15).beginning_of_month .. ::Time.new($3, $1, 15).end_of_month
        elsif value !~ /:/
          time = ::Time.parse(value)
          time.beginning_of_day .. time.end_of_day
        else
          time = ::Time.parse(value)
          time .. time
        end
      rescue ArgumentError
        raise SearchCop::IncompatibleDatatype, "Incompatible datatype for #{value}"
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

      def gt(value)
        super parse(value).last
      end

      def between(range)
        gteq(range.first).and(lteq(range.last))
      end
    end

    class Timestamp < Datetime; end

    class Date < Datetime
      def parse(value)
        return value .. value unless value.is_a?(::String)

        if value =~ /^[0-9]{4,}$/
          ::Date.new(value.to_i).beginning_of_year .. ::Date.new(value.to_i).end_of_year
        elsif value =~ /^([0-9]{4,})(\.|-|\/)([0-9]{1,2})$/
          ::Date.new($1.to_i, $3.to_i, 15).beginning_of_month .. ::Date.new($1.to_i, $3.to_i, 15).end_of_month
        elsif value =~ /^([0-9]{1,2})(\.|-|\/)([0-9]{4,})$/
          ::Date.new($3.to_i, $1.to_i, 15).beginning_of_month .. ::Date.new($3.to_i, $1.to_i, 15).end_of_month
        else
          date = ::Date.parse(value)
          date .. date
        end
      rescue ArgumentError
        raise SearchCop::IncompatibleDatatype, "Incompatible datatype for #{value}"
      end
    end

    class Time < Datetime; end

    class Boolean < WithoutMatches
      def map(value)
        return true if value.to_s =~ /^(1|true|yes)$/i
        return false if value.to_s =~ /^(0|false|no)$/i

        raise SearchCop::IncompatibleDatatype, "Incompatible datatype for #{value}"
      end
    end
  end
end

