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

Thus, you can hand out a search query string to your models:

```ruby
class BooksController < ApplicationController
  def index
    @books = Book.search(params[:q])...
  end
end
```

## Installation

Add this line to your application's Gemfile:

    gem 'attr_searchable'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install attr_searchable

## Usage

To enable AttrSearchable for a model, `include AttrSearchable` and specify the attributes
you want to expose to search queries:

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

## Performance

As `LIKE '%...%'` queries can not use SQL indices, every row needs to be
scanned by your RDBMS when you search for `Book.search("Harry Potter")` or
similar. Contrary, when you search for `Book.search("title=Potter")` indices
can and will be used. Moreover, other indices (on price, stock, etc) will of
course be used by your RDBMS when you search for `Book.search("stock > 0")`,
etc.

Regarding the `LIKE` penalty, we plan to support FULLTEXT index capabilities,
such that `MATCH() ... AGAINST()` of MySQL can be used in the future. However,
we are simply not there yet, as every RDBMS has different FULLTEXT capabilities
and syntaxes - and AttrSearchable will stay RDBMS agnostic.

## Security

Exposing complex SQL query capabilities should always be done with caution.
Otherwise you get vulnerable to SQL injection. AttrSearchable does not generate
any SQL itself. Instead, it uses Arel. Using Arel does not by definition mean
that you're safe, but Arel sanitizes strings, converts between datatypes,
quotes table and column names, etc before sending the query to your RDBMS.
Moreover, you are of course always very welcome to review the code and report
any found issues.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
