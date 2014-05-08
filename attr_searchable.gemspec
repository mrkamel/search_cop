# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'attr_searchable/version'

Gem::Specification.new do |spec|
  spec.name          = "attr_searchable"
  spec.version       = AttrSearchable::VERSION
  spec.authors       = ["Benjamin Vetter"]
  spec.email         = ["vetter@flakks.com"]
  spec.description   = %q{Complex search-engine like query support for activerecord}
  spec.summary       = %q{Easily perform complex search-engine like queries on your activerecord models}
  spec.homepage      = "https://github.com/mrkamel/attr_searchable"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "treetop"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "activerecord", ">= 3.0.0"
  spec.add_development_dependency "factory_girl"
end
