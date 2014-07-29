
# AttrSearchable to SearchCop

As the set of features of AttrSearchable grew and grew, it has been neccessary
to change its DSL and name, as no `attr_searchable` method is present anymore.
The new DSL is cleaner and more concise. Morever, the migration process is
simple.

AttrSearchable:

```ruby
class Book < ActiveRecord::Base
  include AttrSearchable

  scope :search_scope, lambda { eager_load :comments, :users, :user }

  attr_searchable :title, :description
  attr_searchable :comment => ["comments.title", "comments.message"]
  attr_searchable :user => ["users.username", "users_books.username"]

  attr_searchable_options :title, :type => :fulltext, :default => true

  attr_searchable_alias :users_books => :user
end
```

SearchCop:

```ruby
class Book < ActiveRecord::Base
  include SearchCop

  search_scope :search do
    attributes :title, :description
    attributes :comment => ["comments.title", "comments.message"]
    attributes :user => ["users.username", "users_books.username"]

    options :title, :type => :fulltext, :default => true

    aliases :users_books => :user

    scope { eager_load :comments, :users, :user }
  end
end
```

# Reflection

AttrSearchable:

```ruby
Book.searchable_attributes
Book.searchable_attribute_options
Book.default_searchable_attributes
Book.searchable_aliases
```

SearchCop:

```ruby
Book.search_reflection(:search).attributes
Book.search_reflection(:search).options
Book.search_reflection(:search).default_attributes
Book.search_reflection(:search).aliases
```

