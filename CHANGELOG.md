
# Changelog

Version 1.2.0:

* Added support for disabling the right wildcard
* Fixed escaping of wildcard chars (_, %, \)

Version 1.1.0:

* Adds customizable default operator to concatenate conditions (#49)
* Make the postgis adapter use the postgres extensions

Version 1.0.9:

* Use [:blank:] instead of \s for space (#46)
* Updated SearchCop::Visitors::Visitor to check the connection's adapter_name when extending. (#47)
* Fix for negative numeric values
* allow searching for relative dates, like hours, days, weeks, months or years ago

Version 1.0.8:

* No longer add search scope methods globally #34

Version 1.0.7:

* Bugfix regarding NOT queries in fulltext mode #32
* Safely handle NULL values for match queries
* Added coalesce option

Version 1.0.6:

* Fixes a bug regarding date overflows in PostgreSQL

Version 1.0.5:

* Fixes a bug regarding quotation

Version 1.0.4:

* Fix for Rails 4.2 regression regarding reflection access

Version 1.0.3:

* Supporting Rails 4.2
* Dropped Arel dependencies

Version 1.0.2:

* Avoid eager loading when no associations referenced
* Prefer objects over class names
* Readme extended

Version 1.0.1:

* Inheritance fix

Version 1.0.0:

* Project name changed to SearchCop
* Scope support added
* Multiple DSL changes

Version 0.0.5:

* Supporting :default => false
* Datetime/Date greater operator fix
* Use reflection to find associated models
* Providing reflection

Version 0.0.4:

* Fixed date attributes
* Fail softly for mixed datatype attributes
* Support custom table, class and alias names via attr_searchable_alias

Version 0.0.3:

* belongs_to association fixes

Version 0.0.2:

* Arel abstraction layer added
* count() queries resulting in "Cannot visit AttrSearchableGrammar::Nodes..." fixed
* Better error messages
* Model#unsafe_search added

