
# General

Before:

```ruby
class Book < ActiveRecord::Base
  include AttrSearchable

  attr_searchable :title, :description
  attr_searchable :comment => ["comments.title", "comments.message"]
  attr_searchable :user => ["users.username", "users_books.username"]

  attr_searchable_options :title, :type => :fulltext, :default => true

  attr_searchable_alias :users_books => :user
end
```

After:

```ruby
class Book < ActiveRecord::Base
  include SearchCop

  search_scope :search do
    attributes :title, :description
    attributes :comment => ["comments.title", "comments.message"]
    attributes :user => ["users.username", "users_books.username"]

    options :title, :type => :fulltext, :default => true

    aliases :users_books => :user
  end
end
```ruby

# Reflection

Before:

```
Book.searchable_attributes
Book.default_searchable_attributes
Book.searchable_aliases
```

After:

```
Book.search_reflection(:search).attributes
Book.search_reflection(:search).default_attributes
Book.search_reflection(:search).aliases
```

