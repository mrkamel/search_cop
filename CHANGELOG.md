
# Changelog

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

