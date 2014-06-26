# AttrSearchable

[![Build Status](https://secure.travis-ci.org/mrkamel/attr_searchable.png?branch=master)](http://travis-ci.org/mrkamel/attr_searchable)
[![Code Climate](https://codeclimate.com/github/mrkamel/attr_searchable.png)](https://codeclimate.com/github/mrkamel/attr_searchable)
[![Dependency Status](https://gemnasium.com/mrkamel/attr_searchable.png?travis)](https://gemnasium.com/mrkamel/attr_searchable)
[![Gem Version](https://badge.fury.io/rb/attr_searchable.svg)](http://badge.fury.io/rb/attr_searchable)

AttrSearchable extends your ActiveRecord models to support fulltext search
engine like queries via simple query strings and hash-based queries. Assume you
have a `Book` model having various attributes like `title`, `author`, `stock`,
`price`, `available`. Using AttrSearchable you can perform:

```ruby
Book.search("Joanne Rowling Harry Potter")
Book.search("author: Rowling title:'Harry Potter'")
Book.search("price > 10 AND price < 20 -stock:0 (Potter OR Rowling)")
# ...
```

Thus, you can hand out a search query string to your models and you, your app's
admins and/or users will get powerful query features without the need for
integrating additional third party search servers, since AttrSearchable can use
fulltext index capabilities of your RDBMS in a database agnostic way (currently
MySQL and PostgreSQL fulltext indices are supported) and optimizes the queries
to make optimal use of them. Read more below.

Complex hash-based queries are supported as well:

```ruby
Book.search(:author => "Rowling", :title => "Harry Potter")
Book.search(:or => [{:author => "Rowling"}, {:author => "Tolkien"}])
Book.search(:and => [{:price => {:gt => 10}}, {:not => {:stock => 0}}, :or => [{:title => "Potter"}, {:author => "Rowling"}]])
Book.search(:or => [{:query => "Rowling -Potter"}, {:query => "Tolkien -Rings"}])
# ...
```

## Installation

For Rails/ActiveRecord 3 (or 4), add this line to your application's Gemfile:

    gem 'attr_searchable'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install attr_searchable

## Usage

To enable AttrSearchable for a model, `include AttrSearchable` and specify the
attributes you want to expose to search queries:

```ruby
class Book < ActiveRecord::Base
  include AttrSearchable

  attr_searchable :title, :description, :stock, :price, :created_at, :available
  attr_searchable :comment => ["comments.title", "comments.message"]
  attr_searchable :author => "author.name"
  # ...

  has_many :comments
  belongs_to :author
end
```

## How does it work

AttrSearchable parses the query and maps it to an SQL Query using Arel.
Thus, AttrSearchable is not bound to a specific RDBMS.

```ruby
Book.search("stock > 0")
# ... WHERE books.stock > 0

Book.search("price > 10 stock > 0")
# ... WHERE books.price > 10 AND books.stock > 0

Book.search("Harry Potter")
# ... WHERE (books.title LIKE '%Harry%' OR books.description LIKE '%Harry%' OR ...) AND (books.title LIKE '%Potter%' OR books.description LIKE '%Potter%' ...)

Book.search("available:yes OR created_at:2014")
# ... WHERE books.available = 1 OR (books.created_at >= '2014-01-01 00:00:00' and books.created_at <= '2014-12-31 00:00:00')
```

Of course, these `LIKE '%...%'` queries won't achieve optimal performance, but
check out the section below on AttrSearchable's fulltext capabilities to
understand how the resulting queries can be optimized.

As `Book.search(...)` returns an `ActiveRecord::Relation`, you are free to pre-
or post-process the search results in every possible way:

```ruby
Book.where(:available => true).search("Harry Potter").order("books.id desc").paginate(:page => params[:page])
```

## Fulltext index capabilities

By default, i.e. if you don't tell AttrSearchable about your fulltext indices,
AttrSearchable will use `LIKE '%...%'` queries. Unfortunately, unless you
create a [trigram index](http://www.postgresql.org/docs/9.1/static/pgtrgm.html)
(postgres only), theses queries can not use SQL indices, such that every row
needs to be scanned by your RDBMS when you search for `Book.search("Harry
Potter")` or similar. Therefore, AttrSearchable can exploit the fulltext index
capabilities of MySQL and PostgreSQL. To use already existing fulltext indices,
simply tell AttrSearchable to use them via:

```ruby
class Book < ActiveRecord::Base
  # ...

  attr_searchable_options :title, :type => :fulltext
  attr_searchable_options :author, :type => :fulltext

  # ...
end
```

AttrSearchable will then transparently change its SQL queries for the
attributes having fulltext indices to:

```ruby
Book.search("Harry Potter")
# MySQL: ... WHERE (MATCH(books.title) AGAINST('+Harry' IN BOOLEAN MODE) OR MATCH(books.author) AGAINST('+Harry' IN BOOLEAN MODE)) AND (MATCH(books.title) AGAINST ('+Potter' IN BOOLEAN MODE) OR MATCH(books.author) AGAINST('+Potter' IN BOOLEAN MODE))
# PostgreSQL: ... WHERE (to_tsvector('simple', books.title) @@ to_tsquery('simple', 'Harry') OR to_tsvector('simple', books.author) @@ to_tsquery('simple', 'Harry')) AND (to_tsvector('simple', books.title) @@ to_tsquery('simple', 'Potter') OR to_tsvector('simple', books.author) @@ to_tsquery('simple', 'Potter'))
```

Obviously, theses queries won't always return the same results as wildcard
`LIKE` queries, because we search for words instead of sub-strings. However,
fulltext indices will usually of course provide better performance.

Moreover, the query above is not yet perfect. To improve it even more,
AttrSearchable tries to optimize the queries to make optimal use of fulltext
indices while still allowing to mix them with non-fulltext attributes. To
improve queries, the first thing you want to do is to specify a default field
to search in, such that AttrSearchable must no longer search within all fields:

```ruby
attr_searchable :all => [:author, :title]
attr_searchable_options :all, :type => :fulltext, :default => true
```

Now AttrSearchable can optimize the following, not yet optimal query:

```ruby
BookSearch("Rowling OR Tolkien stock > 1")
# MySQL: ... WHERE ((MATCH(books.author) AGAINST('+Rowling' IN BOOLEAN MODE) OR MATCH(books.title) AGAINST('+Rowling' IN BOOLEAN MODE)) OR (MATCH(books.author) AGAINST('+Tolkien' IN BOOLEAN MODE) OR MATCH(books.title) AGAINST('+Tolkien' IN BOOLEAN MODE))) AND books.stock > 1
# PostgreSQL: ... WHERE ((to_tsvector('simple', books.author) @@ to_tsquery('simple', 'Rowling') OR to_tsvector('simple', books.title) @@ to_tsquery('simple', 'Rowling')) OR (to_tsvector('simple', books.author) @@ to_tsquery('simple', 'Tolkien') OR to_tsvector('simple', books.title) @@ to_tsquery('simple', 'Tolkien'))) AND books.stock > 1
```

to the following, more performant query:

```ruby
BookSearch("Rowling OR Tolkien stock > 1")
# MySQL: ... WHERE MATCH(books.author, books.title) AGAINST('Rowling Tolkien' IN BOOLEAN MODE) AND books.stock > 1
# PostgreSQL: ... WHERE to_tsvector('simple', books.author || ' ' || books.title) @@ to_tsquery('simple', 'Rowling | Tokien') and books.stock > 1
```

Other queries will be optimized in a similar way, such that AttrSearchable
tries to minimize the fultext constraints within a query, namely `MATCH()
AGAINST()` for MySQL and `to_tsvector() @@ to_tsquery()` for PostgreSQL.

```ruby
BookSearch("(Rowling -Potter) OR Tolkien")
# MySQL: ... WHERE MATCH(books.author, books.title) AGAINST('(+Rowling -Potter) Tolkien' IN BOOLEAN MODE)
# PostgreSQL: ... WHERE to_tsvector('simple', books.author || ' ' || books.title) @@ to_tsquery('simple', '(Rowling & !Potter) | Tolkien')
```

To create a fulltext index on `books.title` in MySQL, simply use:

```ruby
add_index :books, :title, :type => :fulltext
```

Regarding compound indices, which will e.g. be used for the default field `all`
we already specified above, use:

```ruby
add_index :books, [:author, :title], :type => :fulltext
```

Please note that MySQL supports fulltext indices for MyISAM and, as of MySQL
version 5.6+, for InnoDB as well. For more details about MySQL fulltext indices
visit
[http://dev.mysql.com/doc/refman/5.6/en/fulltext-search.html](http://dev.mysql.com/doc/refman/5.6/en/fulltext-search.html)

Regarding PostgreSQL there are more ways to create a fulltext index. However,
one of the easiest ways is:

```ruby
ActiveRecord::Base.connection.execute "CREATE INDEX fulltext_index_books_on_title ON books USING GIN(to_tsvector('simple', title))"
```

Regarding compound indices for PostgreSQL, use:

```ruby
ActiveRecord::Base.connection.execute "CREATE INDEX fulltext_index_books_on_title ON books USING GIN(to_tsvector('simple', author || ' ' || title))"
```

To use another PostgreSQL dictionary than `simple`, you have to create the
index accordingly and you need tell AttrSearchable about it, e.g.:

```ruby
attr_searchable_options :title, :dictionary => "english"
```

For more details about PostgreSQL fulltext indices visit
[http://www.postgresql.org/docs/9.3/static/textsearch.html](http://www.postgresql.org/docs/9.3/static/textsearch.html)

## Other indices

In case you expose non-fulltext attributes to search queries (price, stock,
etc.), the respective queries, like `Book.search("stock > 0")`, will profit
from from the usual non-fulltext indices. Thus, you should add a usual index on
every column you expose to search queries plus a fulltext index for every
fulltext attribute.

## Associations

If you specify searchable attributes from another model, like

```ruby
class Book < ActiveRecord::Base
  # ...

  belongs_to :author

  attr_searchable :author => "author.name"

  # ...
end
```

AttrSearchable will by default `eager_load` the referenced associations, when
you perform `Book.search(...)`. Assocations of associations can thus as well be
referenced and used:

```ruby
class Book < ActiveRecord::Base
  # ...

  has_many :comments
  has_many :users, :through => :comments

  attr_searchable :user => "users.username"

  # ...
end
```

If you don't want the automatic `eager_load` or need to perform special
operations, define a `search_scope` within your model:

```ruby
class Book < ActiveRecord::Base
  # ...

  scope :search_scope, lambda { joins(:author).eager_load(:comments) } # etc.

  # ...
end
```

AttrSearchable will then skip any association auto loading and will use
the `search_scope` instead.

## Supported operators

Query string queries support `AND/and`, `OR/or`, `:`, `=`, `!=`, `<`, `<=`,
`>`, `>=`, `NOT/not/-`, `()`, `"..."` and `'...'`. Default operators are `AND`
and `matches`, `OR` has precedence over `AND`. `NOT` can only be used as infix
operator regarding a single attribute.

Hash based queries support `:and => [...]` and `:or => [...]`, which take an array
of `:not => {...}`, `:matches => {...}`, `:eq => {...}`, `:not_eq => {...}`,
`:lt => {...}`, `:lteq => {...}`, `gt => {...}`, `:gteq => {...}` and `:query => "..."`
arguments. Moreover, `:query => "..."` makes it possible to create sub-queries.
The other rules for query string queries apply to hash based queries as well.

## Mapping

When searching in boolean, datetime, timestamp, etc. fields, AttrSearchable
performs some mapping. The following queries are equivalent:

```ruby
Book.search("available:true")
Book.search("available:1")
Book.search("available:yes")
```

as well as

```ruby
Book.search("available:false")
Book.search("available:0")
Book.search("available:no")
```

For datetime and timestamp fields, AttrSearchable expands certain values to
ranges:

```ruby
Book.search("created_at:2014")
# ... WHERE created_at >= '2014-01-01 00:00:00' AND created_at <= '2014-12-31 23:59:59'

Book.search("created_at:2014-06")
# ... WHERE created_at >= '2014-06-01 00:00:00' AND created_at <= '2014-06-30 23:59:59'

Book.search("created_at:2014-06-15")
# ... WHERE created_at >= '2014-06-15 00:00:00' AND created_at <= '2014-06-15 23:59:59'
```

## Chaining

Chaining of searches is possible. However, chaining does currently not allow
AttrSearchable to optimize the individual queries for fulltext indices.

```ruby
Book.search("Harry").search("Potter")
```

will generate

```ruby
# MySQL: ... WHERE MATCH(...) AGAINST('+Harry' IN BOOLEAN MODE) AND MATCH(...) AGAINST('+Potter' IN BOOLEAN MODE)
# PostgreSQL: ... WHERE to_tsvector(...) @@ to_tsquery('simple', 'Harry') AND to_tsvector(...) @@ to_tsquery('simple', 'Potter')
```

instead of

```ruby
# MySQL: ... WHERE MATCH(...) AGAINST('+Harry +Potter' IN BOOLEAN MODE)
# PostgreSQL: ... WHERE to_tsvector(...) @@ to_tsquery('simple', 'Harry & Potter')
```

Thus, if you use fulltext indices, you better avoid chaining.

## Debugging

When using `Model#search`, AttrSearchable conveniently prevents certain
exceptions from being raised in case the query string passed to it is invalid
(parse errors, incompatible datatype errors, etc). Instead, `Model#search`
returns an empty relation. However, if you need to debug certain cases, use
`Model#unsafe_search`, which will raise them.

```ruby
Book.unsafe_search("stock: None") # => raise AttrSearchable::IncompatibleDatatype
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Changelog

Version 0.0.3:

* belongs_to association fixes

Version 0.0.2:

* Arel abstraction layer added
* count() queries resulting in "Cannot visit AttrSearchableGrammar::Nodes..." fixed
* Better error messages
* Model#unsafe_search added

