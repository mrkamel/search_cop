# AttrSearchable

[![Build Status](https://secure.travis-ci.org/mrkamel/attr_searchable.png?branch=master)](http://travis-ci.org/mrkamel/attr_searchable)
[![Code Climate](https://codeclimate.com/github/mrkamel/attr_searchable.png)](https://codeclimate.com/github/mrkamel/attr_searchable)
[![Dependency Status](https://gemnasium.com/mrkamel/attr_searchable.png?travis)](https://gemnasium.com/mrkamel/attr_searchable)

AttrSearchable extends your ActiveRecord models to support fulltext search engine like queries
via simple query strings. Assume you have a `Book` model having various attributes like
`title`, `author`, `stock`, `price`, `available`. Using AttrSearchable you can perform:

```ruby
Book.search("Joanne Rowling Harry Potter")
Book.search("author: Rowling title:'Harry Potter'")
Book.search("price > 10 AND price < 20 -stock:0 (Potter OR Rowling)")
# ...
```

Thus, you can hand out a search query string to your models, such that your
app's admins and/or users will get powerful query features without the need for
building complex forms, because all you need is a simple text field:

```ruby
class BooksController < ApplicationController
  def index
    @books = Book.search(params[:q])...
  end
end
```

AttrSearchable can even use fulltext index capabilities of your favorite RDBMS
(currently MySQL and PostgreSQL fulltext indices are supported) in a database
agnostic way.

## Installation

Add this line to your application's Gemfile:

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
Book.where(:availabble => true).search("Harry Potter").order("books.id desc").paginate(:page => params[:page])
```

## Associations

If you specify searchable attributes from another model, like

```ruby
class Book < ActiveRecord::Base
  # ...

  attr_searchable :author => "author.name"

  # ...
end
```

AttrSearchable will by default `eager_load` these associations, when you
perform `Book.search(...)`. If you don't want that or need to perform special
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

## Fulltext index capabilities

By default, AttrSearchable will use `LIKE '%...%'` queries. Unfortunately,
unless you create a [trigram index](http://www.postgresql.org/docs/9.1/static/pgtrgm.html) (postgres only),
theses queries can not use SQL indices, such that every row needs to be scanned
by your RDBMS when you search for `Book.search("Harry Potter")` or similar.
Contrary, when you search for `Book.search("title=Potter")` indices can and
will be used. Moreover, other indices (on price, stock, etc) will of course be
used by your RDBMS when you search for `Book.search("stock > 0")`, etc.

Regarding the `LIKE` penalty, the easiest way to make them use indices is
to remove the left wildcard. AttrSearchble supports this via:

```ruby
class Book < ActiveRecord::Base
  # ...

  attr_searchable_options, :title, :left_wildcard => false

  # ...
end
```

However, this is often not desirable. Therefore, AttrSearchable can exploit the
fulltext index capabilities of MySQL and PostgreSQL. To use already existing
fulltext indices, simply tell AttrSearchable to use them via:

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
# MySQL: ... WHERE MATCH(books.title) AGAINST('+Harry +Potter' IN BOOLEAN MODE) OR MATCH(books.author) AGAINST('+Harry +Potter' IN BOOLEAN MODE)
# PostgreSQL: ... WHERE to_tsvector('simple', books.title) @@ to_tsquery('simple', 'Harry & Potter') OR to_tsvector('simple', books.author) @@ to_tsquery('simple', 'Harry & Potter')
```

Obviously, theses queries won't always return the same results as wildcard
`LIKE` queries, because we search for words instead of substrings. However,
fulltext indices will provide better performance for most cases.

Moreover, the query above is not yet perfect. To improve it even more,
AttrSearchable tries to optimize the queries to make optimal use of fulltext
indices while still allowing to mix them with non-fulltext attributes. To
improve queries, the first thing you want to do is to specify a default field
to search in:

```ruby
attr_searchable :all => [:author, :title]
attr_searchable_options :all, :type => :fulltext, :default => true
```

Now AttrSearchable can optimize the following query:

```ruby
BookSearch("Rowling OR Tolkien stock > 1")
# MySQL: ... WHERE (MATCH(books.author) AGAINST('+Rowling' IN BOOLEAN MODE) OR MATCH(books.title) AGAINST('+Tolkien' IN BOOLEAN MODE)) AND books.stock > 1
# PostgreSQL: ... WHERE (to_tsvector('simple', books.author) @@ to_tsquery('simple', 'Rowling') OR to_tsvector('simple', books.title) @@ to_tsquery('simple', 'Tolkien')) AND books.stock > 1
```

to the following, more performant query:

```ruby
BookSearch("Rowling OR Tolkien stock > 1")
# MySQL: ... WHERE MATCH(books.author, books.title) AGAINST('Rowling Tolkien' IN BOOLEAN MODE) AND books.stock > 1
# PostgreSQL: ... WHERE to_tsvector('simple', books.author || ' ' || books.title) @@ to_tsquery('simple', 'Rowling | Tokien') and books.stock > 1
```

Other queries will be optimized in a similar way, such that AttrSearchable
tries to minimize the fultext constraints within a query, namely `MATCH()
AGAINST()` for MySQL and `to_tsvector() @@ to_tsquery()` for PostgreSQL. To
create a fulltext index on `books.title` in MySQL, simply use:

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

## Security

Exposing complex SQL query capabilities should always be done with caution.
Besides its fulltext extensions, AttrSearchable does not generate or manipulate
any SQL itself. Instead, it uses Arel. Using Arel does not by definition mean
that you're safe against SQL injection, but Arel sanitizes strings, converts
between datatypes, quotes table and column names, etc before sending the query
to your RDBMS. Moreover, you are of course very welcome to review the code,
send pull requests for additional features and database fulltext support, open
issues, etc.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
