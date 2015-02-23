# SearchCop

[![Build Status](https://secure.travis-ci.org/mrkamel/search_cop.png?branch=master)](http://travis-ci.org/mrkamel/search_cop)
[![Code Climate](https://codeclimate.com/github/mrkamel/search_cop.png)](https://codeclimate.com/github/mrkamel/search_cop)
[![Dependency Status](https://gemnasium.com/mrkamel/search_cop.png?travis)](https://gemnasium.com/mrkamel/search_cop)
[![Gem Version](https://badge.fury.io/rb/search_cop.svg)](http://badge.fury.io/rb/search_cop)

![search_cop](https://raw.githubusercontent.com/mrkamel/search_cop_logo/master/search_cop.png)

SearchCop extends your ActiveRecord models to support fulltext search
engine like queries via simple query strings and hash-based queries. Assume you
have a `Book` model having various attributes like `title`, `author`, `stock`,
`price`, `available`. Using SearchCop you can perform:

```ruby
Book.search("Joanne Rowling Harry Potter")
Book.search("author: Rowling title:'Harry Potter'")
Book.search("price > 10 AND price < 20 -stock:0 (Potter OR Rowling)")
# ...
```

Thus, you can hand out a search query string to your models and you, your app's
admins and/or users will get powerful query features without the need for
integrating additional third party search servers, since SearchCop can use
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

## AttrSearchable is now SearchCop

As the set of features of AttrSearchable grew and grew, it has been neccessary
to change its DSL and name, as no `attr_searchable` method is present anymore.
The new DSL is cleaner and more concise. Morever, the migration process is
simple. Please take a look into the migration guide
[MIGRATION.md](https://github.com/mrkamel/search_cop/blob/master/MIGRATION.md)

## Installation

For Rails/ActiveRecord 3 (or 4), add this line to your application's Gemfile:

    gem 'search_cop'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install search_cop

## Usage

To enable SearchCop for a model, `include SearchCop` and specify the
attributes you want to expose to search queries within a `search_scope`:

```ruby
class Book < ActiveRecord::Base
  include SearchCop

  search_scope :search do
    attributes :title, :description, :stock, :price, :created_at, :available
    attributes :comment => ["comments.title", "comments.message"]
    attributes :author => "author.name"
    # ...
  end

  has_many :comments
  belongs_to :author
end
```

You can of course as well specify multiple `search_scope` blocks as you like:

```ruby
search_scope :admin_search do
  attributes :title, :description, :stock, :price, :created_at, :available

  # ...
end

search_scope :user_search do
  attributes :title, :description

  # ...
end
```

## How does it work

SearchCop parses the query and maps it to an SQL Query in a database agnostic way.
Thus, SearchCop is not bound to a specific RDBMS.

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
check out the section below on SearchCop's fulltext capabilities to
understand how the resulting queries can be optimized.

As `Book.search(...)` returns an `ActiveRecord::Relation`, you are free to pre-
or post-process the search results in every possible way:

```ruby
Book.where(:available => true).search("Harry Potter").order("books.id desc").paginate(:page => params[:page])
```

## Fulltext index capabilities

By default, i.e. if you don't tell SearchCop about your fulltext indices,
SearchCop will use `LIKE '%...%'` queries. Unfortunately, unless you
create a [trigram index](http://www.postgresql.org/docs/9.1/static/pgtrgm.html)
(postgres only), these queries can not use SQL indices, such that every row
needs to be scanned by your RDBMS when you search for `Book.search("Harry
Potter")` or similar. To avoid the penalty of `LIKE` queries, SearchCop
can exploit the fulltext index capabilities of MySQL and PostgreSQL. To use
already existing fulltext indices, simply tell SearchCop to use them via:

```ruby
class Book < ActiveRecord::Base
  # ...

  search_scope :search do
    attributes :title, :author

    options :title, :type => :fulltext
    options :author, :type => :fulltext
  end

  # ...
end
```

SearchCop will then transparently change its SQL queries for the
attributes having fulltext indices to:

```ruby
Book.search("Harry Potter")
# MySQL: ... WHERE (MATCH(books.title) AGAINST('+Harry' IN BOOLEAN MODE) OR MATCH(books.author) AGAINST('+Harry' IN BOOLEAN MODE)) AND (MATCH(books.title) AGAINST ('+Potter' IN BOOLEAN MODE) OR MATCH(books.author) AGAINST('+Potter' IN BOOLEAN MODE))
# PostgreSQL: ... WHERE (to_tsvector('simple', books.title) @@ to_tsquery('simple', 'Harry') OR to_tsvector('simple', books.author) @@ to_tsquery('simple', 'Harry')) AND (to_tsvector('simple', books.title) @@ to_tsquery('simple', 'Potter') OR to_tsvector('simple', books.author) @@ to_tsquery('simple', 'Potter'))
```

Obviously, these queries won't always return the same results as wildcard
`LIKE` queries, because we search for words instead of sub-strings. However,
fulltext indices will usually of course provide better performance.

Moreover, the query above is not yet perfect. To improve it even more,
SearchCop tries to optimize the queries to make optimal use of fulltext indices
while still allowing to mix them with non-fulltext attributes. To improve
queries even more, you can group attributes and specify a default field to
search in, such that SearchCop must no longer search within all fields:

```ruby
search_scope :search do
  attributes :all => [:author, :title]

  options :all, :type => :fulltext, :default => true

  # Use :default => true to explicitly enable fields as default fields (whitelist approach)
  # Use :default => false to explicitly disable fields as default fields (blacklist approach)
end
```

Now SearchCop can optimize the following, not yet optimal query:

```ruby
Book.search("Rowling OR Tolkien stock > 1")
# MySQL: ... WHERE ((MATCH(books.author) AGAINST('+Rowling' IN BOOLEAN MODE) OR MATCH(books.title) AGAINST('+Rowling' IN BOOLEAN MODE)) OR (MATCH(books.author) AGAINST('+Tolkien' IN BOOLEAN MODE) OR MATCH(books.title) AGAINST('+Tolkien' IN BOOLEAN MODE))) AND books.stock > 1
# PostgreSQL: ... WHERE ((to_tsvector('simple', books.author) @@ to_tsquery('simple', 'Rowling') OR to_tsvector('simple', books.title) @@ to_tsquery('simple', 'Rowling')) OR (to_tsvector('simple', books.author) @@ to_tsquery('simple', 'Tolkien') OR to_tsvector('simple', books.title) @@ to_tsquery('simple', 'Tolkien'))) AND books.stock > 1
```

to the following, more performant query:


```ruby
Book.search("Rowling OR Tolkien stock > 1")
# MySQL: ... WHERE MATCH(books.author, books.title) AGAINST('Rowling Tolkien' IN BOOLEAN MODE) AND books.stock > 1
# PostgreSQL: ... WHERE to_tsvector('simple', books.author || ' ' || books.title) @@ to_tsquery('simple', 'Rowling | Tokien') and books.stock > 1
```

What is happening here? Well, we specified `all` as the name of an attribute
group that consists of `author` and `title`. As we, in addition, specified
`all` to be a fulltext attribute, SearchCop assumes there is a compound
fulltext index present on `author` and `title`, such that the query is
optimized accordingly. Finally, we specified `all` to be the default attribute
to search in, such that SearchCop can ignore other attributes, like e.g.
`stock`, as long as they are not specified within queries directly (like for
`stock > 0`).

Other queries will be optimized in a similar way, such that SearchCop
tries to minimize the fultext constraints within a query, namely `MATCH()
AGAINST()` for MySQL and `to_tsvector() @@ to_tsquery()` for PostgreSQL.

```ruby
Book.search("(Rowling -Potter) OR Tolkien")
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

Moreover, for PostgreSQL you should change the schema format in
`config/application.rb`:

```ruby
config.active_record.schema_format = :sql
```

Regarding compound indices for PostgreSQL, use:

```ruby
ActiveRecord::Base.connection.execute "CREATE INDEX fulltext_index_books_on_title ON books USING GIN(to_tsvector('simple', author || ' ' || title))"
```

To use another PostgreSQL dictionary than `simple`, you have to create the
index accordingly and you need tell SearchCop about it, e.g.:

```ruby
search_scope :search do
  attributes :title

  options :title, :type => :fulltext, :dictionary => "english"
end
```

For more details about PostgreSQL fulltext indices visit
[http://www.postgresql.org/docs/9.3/static/textsearch.html](http://www.postgresql.org/docs/9.3/static/textsearch.html)

## Other indices

In case you expose non-fulltext attributes to search queries (price, stock,
etc.), the respective queries, like `Book.search("stock > 0")`, will profit
from from the usual non-fulltext indices. Thus, you should add a usual index on
every column you expose to search queries plus a fulltext index for every
fulltext attribute.

In case you can't use fulltext indices, because you're e.g. still on MySQL 5.5
while using InnoDB or another RDBMS without fulltext support, you can make your
RDBMS use usual non-fulltext indices for string columns if you don't need the
left wildcard within `LIKE` queries. Simply supply the following option:

```ruby
class User < ActiveRecord::Base
  include SearchCop

  search_scope :search do
    attributes :username

    options :username, :left_wildcard => false
  end

  # ...
```

such that SearchCop will omit the left most wildcard.

```ruby
User.search("admin")
# ... WHERE users.username LIKE 'admin%'
```

## Associations

If you specify searchable attributes from another model, like

```ruby
class Book < ActiveRecord::Base
  # ...

  belongs_to :author

  search_scope :search do
    attributes :author => "author.name"
  end

  # ...
end
```

SearchCop will by default `eager_load` the referenced associations, when
you perform `Book.search(...)`.  If you don't want the automatic `eager_load`
or need to perform special operations, specify a `scope`:

```ruby
class Book < ActiveRecord::Base
  # ...

  search_scope :search do
    # ...

    scope { joins(:author).eager_load(:comments) } # etc.
  end

  # ...
end
```

SearchCop will then skip any association auto loading and will use the scope
instead. You can as well use `scope` together with `aliases` to perform
arbitrarily complex joins and search in the joined models/tables:

```ruby
class Book < ActiveRecord::Base
  # ...

  search_scope :search do
    attributes :similar => ["similar_books.title", "similar_books.description"]

    scope do
      joins "left outer join books similar_books on ..."
    end

    aliases :similar_books => Book # Tell SearchCop how to map SQL aliases to models
  end

  # ...
end
```

Assocations of associations can as well be referenced and used:

```ruby
class Book < ActiveRecord::Base
  # ...

  has_many :comments
  has_many :users, :through => :comments

  search_scope :search do
    attributes :user => "users.username"
  end

  # ...
end
```

## Custom table names and associations

SearchCop tries to infer a model's class name and SQL alias from the
specified attributes to autodetect datatype definitions, etc. This usually
works quite fine. In case you're using custom table names via `self.table_name
= ...` or if a model is associated multiple times, SearchCop however can't
infer the class and SQL alias names, e.g.

```ruby
class Book < ActiveRecord::Base
  # ...

  has_many :users, :through => :comments
  belongs_to :user

  search_scope :search do
    attributes :user => ["user.username", "users_books.username"]
  end

  # ...
end
```

Here, for queries to work you have to use `users_books.username`, because
ActiveRecord assigns a different SQL alias for users within its SQL queries,
because the user model is associated multiple times. However, as SearchCop
now can't infer the `User` model from `users_books`, you have to add:

```ruby
class Book < ActiveRecord::Base
  # ...

  search_scope :search do
    # ...

    aliases :users_books => :users
  end

  # ...
end
```

to tell SearchCop about the custom SQL alias and mapping. In addition, you can
always do the joins yourself via a `scope {}` block plus `aliases` and use your
own custom sql aliases to become independent of names auto-assigned by
ActiveRecord.

## Supported operators

Query string queries support `AND/and`, `OR/or`, `:`, `=`, `!=`, `<`, `<=`,
`>`, `>=`, `NOT/not/-`, `()`, `"..."` and `'...'`. Default operators are `AND`
and `matches`, `OR` has precedence over `AND`. `NOT` can only be used as infix
operator regarding a single attribute.

Hash based queries support `:and => [...]` and `:or => [...]`, which take an array
of `:not => {...}`, `:matches => {...}`, `:eq => {...}`, `:not_eq => {...}`,
`:lt => {...}`, `:lteq => {...}`, `:gt => {...}`, `:gteq => {...}` and `:query => "..."`
arguments. Moreover, `:query => "..."` makes it possible to create sub-queries.
The other rules for query string queries apply to hash based queries as well.

## Mapping

When searching in boolean, datetime, timestamp, etc. fields, SearchCop
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

For datetime and timestamp fields, SearchCop expands certain values to
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
SearchCop to optimize the individual queries for fulltext indices.

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

When using `Model#search`, SearchCop conveniently prevents certain
exceptions from being raised in case the query string passed to it is invalid
(parse errors, incompatible datatype errors, etc). Instead, `Model#search`
returns an empty relation. However, if you need to debug certain cases, use
`Model#unsafe_search`, which will raise them.

```ruby
Book.unsafe_search("stock: None") # => raise SearchCop::IncompatibleDatatype
```

## Reflection

SearchCop provides reflective methods, namely `#attributes`,
`#default_attributes`, `#options` and `#aliases`. You can use these methods to
e.g. provide an individual search help widget for your models, that lists the
attributes to search in as well as the default ones, etc.

```ruby
class Product < ActiveRecord::Base
  include SearchCop

  search_scope :search do
    attributes :title, :description

    options :title, :default => true
  end
end

Product.search_reflection(:search).attributes
# {"title" => ["products.title"], "description" => ["products.description"]}

Product.search_reflection(:search).default_attributes
# {"title" => ["products.title"]}

# ...
```

## Semantic Versioning

Starting with version 1.0.0, SearchCop uses Semantic Versioning:
[SemVer](http://semver.org/)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

