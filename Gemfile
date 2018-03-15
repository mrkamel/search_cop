source 'https://rubygems.org'

# Specify your gem's dependencies in search_cop.gemspec
gemspec

platforms :jruby do
  gem 'activerecord-jdbcmysql-adapter'
  gem 'activerecord-jdbcsqlite3-adapter'
  gem 'activerecord-jdbcpostgresql-adapter'
end

platforms :ruby do
  gem 'sqlite3'
  gem 'mysql2'
  gem 'pg'
end

