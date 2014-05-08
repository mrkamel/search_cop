source 'https://rubygems.org'

# Specify your gem's dependencies in attr_searchable.gemspec
gemspec

gem 'activerecord-jdbc-adapter', :platforms => :jruby

platforms :ruby do
  gem 'sqlite3'
  gem 'mysql2'
  gem 'pg'
end

platforms :rbx do
  gem 'racc'
  gem 'rubysl', '~> 2.0'
  gem 'psych'
end

