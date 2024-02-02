require File.expand_path("test_helper", __dir__)

class VisitorTest < SearchCop::TestCase
  def test_and
    node = SearchCopGrammar::Attributes::Integer.new(Product, "products", "stock", nil).gt(0).and(SearchCopGrammar::Attributes::Integer.new(Product, "products", "stock", nil).lt(2))

    assert_equal "(#{quote_table_name "products"}.#{quote_column_name "stock"} > 0 AND #{quote_table_name "products"}.#{quote_column_name "stock"} < 2)", SearchCop::Visitors::Visitor.new(ActiveRecord::Base.connection).visit(node)
  end

  def test_or
    node = SearchCopGrammar::Attributes::Integer.new(Product, "products", "stock", nil).gt(0).or(SearchCopGrammar::Attributes::Integer.new(Product, "products", "stock", nil).lt(2))

    assert_equal "(#{quote_table_name "products"}.#{quote_column_name "stock"} > 0 OR #{quote_table_name "products"}.#{quote_column_name "stock"} < 2)", SearchCop::Visitors::Visitor.new(ActiveRecord::Base.connection).visit(node)
  end

  def test_greater_than
    node = SearchCopGrammar::Attributes::Integer.new(Product, "products", "stock", nil).gt(1)

    assert_equal "#{quote_table_name "products"}.#{quote_column_name "stock"} > 1", SearchCop::Visitors::Visitor.new(ActiveRecord::Base.connection).visit(node)
  end

  def test_greater_than_or_equal
    node = SearchCopGrammar::Attributes::Integer.new(Product, "products", "stock", nil).gteq(1)

    assert_equal "#{quote_table_name "products"}.#{quote_column_name "stock"} >= 1", SearchCop::Visitors::Visitor.new(ActiveRecord::Base.connection).visit(node)
  end

  def test_less_than
    node = SearchCopGrammar::Attributes::Integer.new(Product, "products", "stock", nil).lt(1)

    assert_equal "#{quote_table_name "products"}.#{quote_column_name "stock"} < 1", SearchCop::Visitors::Visitor.new(ActiveRecord::Base.connection).visit(node)
  end

  def test_less_than_or_equal
    node = SearchCopGrammar::Attributes::Integer.new(Product, "products", "stock", nil).lteq(1)

    assert_equal "#{quote_table_name "products"}.#{quote_column_name "stock"} <= 1", SearchCop::Visitors::Visitor.new(ActiveRecord::Base.connection).visit(node)
  end

  def test_equality
    node = SearchCopGrammar::Attributes::Integer.new(Product, "products", "stock", nil).eq(1)

    assert_equal "#{quote_table_name "products"}.#{quote_column_name "stock"} = 1", SearchCop::Visitors::Visitor.new(ActiveRecord::Base.connection).visit(node)
  end

  def test_not_equal
    node = SearchCopGrammar::Attributes::Integer.new(Product, "products", "stock", nil).not_eq(1)

    assert_equal "#{quote_table_name "products"}.#{quote_column_name "stock"} != 1", SearchCop::Visitors::Visitor.new(ActiveRecord::Base.connection).visit(node)
  end

  def test_matches
    node = SearchCopGrammar::Attributes::String.new(Product, "products", "notice", nil).matches("Notice")

    assert_equal("(#{quote_table_name "products"}.#{quote_column_name "notice"} IS NOT NULL AND #{quote_table_name "products"}.#{quote_column_name "notice"} LIKE #{quote "%Notice%"} ESCAPE #{quote "\\"})", SearchCop::Visitors::Visitor.new(ActiveRecord::Base.connection).visit(node)) if ENV["DATABASE"] != "postgres"
    assert_equal("(#{quote_table_name "products"}.#{quote_column_name "notice"} IS NOT NULL AND #{quote_table_name "products"}.#{quote_column_name "notice"} ILIKE #{quote "%Notice%"} ESCAPE #{quote "\\"})", SearchCop::Visitors::Visitor.new(ActiveRecord::Base.connection).visit(node)) if ENV["DATABASE"] == "postgres"
  end

  def test_not
    node = SearchCopGrammar::Attributes::Integer.new(Product, "products", "stock", nil).eq(1).not

    assert_equal "NOT (#{quote_table_name "products"}.#{quote_column_name "stock"} = 1)", SearchCop::Visitors::Visitor.new(ActiveRecord::Base.connection).visit(node)
  end

  def test_attribute
    # Already tested
  end

  def test_quote
    assert_equal quote("Test"), SearchCop::Visitors::Visitor.new(ActiveRecord::Base.connection).visit("Test")
  end

  def test_fulltext
    node = SearchCopGrammar::Attributes::Collection.new(SearchCop::QueryInfo.new(Product, Product.search_scopes[:search]), "title").matches("Query").optimize!

    assert_equal("MATCH(`products`.`title`) AGAINST('Query' IN BOOLEAN MODE)", SearchCop::Visitors::Visitor.new(ActiveRecord::Base.connection).visit(node)) if ENV["DATABASE"] == "mysql"
    assert_equal("to_tsvector('english', COALESCE(\"products\".\"title\", '')) @@ to_tsquery('english', '''Query''')", SearchCop::Visitors::Visitor.new(ActiveRecord::Base.connection).visit(node)) if ENV["DATABASE"] == "postgres"
  end

  def test_fulltext_and
    query1 = SearchCopGrammar::Attributes::Collection.new(SearchCop::QueryInfo.new(Product, Product.search_scopes[:search]), "title").matches("Query1")
    query2 = SearchCopGrammar::Attributes::Collection.new(SearchCop::QueryInfo.new(Product, Product.search_scopes[:search]), "title").matches("Query2")

    node = query1.and(query2).optimize!

    assert_equal("(MATCH(`products`.`title`) AGAINST('+Query1 +Query2' IN BOOLEAN MODE))", SearchCop::Visitors::Visitor.new(ActiveRecord::Base.connection).visit(node)) if ENV["DATABASE"] == "mysql"
    assert_equal("(to_tsvector('english', COALESCE(\"products\".\"title\", '')) @@ to_tsquery('english', '(''Query1'') & (''Query2'')'))", SearchCop::Visitors::Visitor.new(ActiveRecord::Base.connection).visit(node)) if ENV["DATABASE"] == "postgres"
  end

  def test_fulltext_or
    query1 = SearchCopGrammar::Attributes::Collection.new(SearchCop::QueryInfo.new(Product, Product.search_scopes[:search]), "title").matches("Query1")
    query2 = SearchCopGrammar::Attributes::Collection.new(SearchCop::QueryInfo.new(Product, Product.search_scopes[:search]), "title").matches("Query2")

    node = query1.or(query2).optimize!

    assert_equal("(MATCH(`products`.`title`) AGAINST('(Query1) (Query2)' IN BOOLEAN MODE))", SearchCop::Visitors::Visitor.new(ActiveRecord::Base.connection).visit(node)) if ENV["DATABASE"] == "mysql"
    assert_equal("(to_tsvector('english', COALESCE(\"products\".\"title\", '')) @@ to_tsquery('english', '(''Query1'') | (''Query2'')'))", SearchCop::Visitors::Visitor.new(ActiveRecord::Base.connection).visit(node)) if ENV["DATABASE"] == "postgres"
  end

  def test_generator
    generator = lambda do |column_name, value|
      "#{column_name} = #{quote value}"
    end
    node = SearchCopGrammar::Attributes::Collection.new(SearchCop::QueryInfo.new(Product, Product.search_scopes[:search]), "title").generator(generator, "value").optimize!

    assert_equal "#{quote_table_name "products"}.#{quote_column_name "title"} = 'value'", SearchCop::Visitors::Visitor.new(ActiveRecord::Base.connection).visit(node)
  end
end
