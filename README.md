# AttrSearchable

[![Build Status](https://secure.travis-ci.org/mrkamel/attr_searchable.png?branch=master)](http://travis-ci.org/mrkamel/attr_searchable)
[![Code Climate](https://codeclimate.com/github/mrkamel/attr_searchable.png)](https://codeclimate.com/github/mrkamel/attr_searchable)

AttrSearchable extends your ActiveRecord models to support fulltext search engine like queries
via simple query strings. Assume you have a `Book` model having various attributes like
`title`, `author`, `stock`, `price`. Using AttrSearchable you can perform:

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
you want make searchable:

```ruby
class Book
  include AttrSearchable

  attr_searchable :title, :description, :stock, :price, :created_at
  attr_searchable :comment => ["comments.title", "comments.message"]
  attr_searchable :author => "authors.name"
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
```

## Performance

As `LIKE '%...%'` queries can not use SQL indices, every row will be fetched by
your RDBMS when you search for `Book.search("Harry Potter")` or similar.
Contrary, when you search for `Book.search("title=Potter")` indices can and
will be used. Moreover, other indices (on price, stock, ect) will of course be
used by your RDBMS when you search for `Book.search("stock > 0")`, etc.

Regarding the `LIKE` penalty, we plan to support FULLTEXT index capabilities,
such that Mysql's `MATCH() ... AGAINST()` can be used, etc. However, we are
simply not there yet, as every RDBMS has different FULLTEXT capabilities and
syntaxes - and AttrSearchable will stay RDBMS agnostic.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
