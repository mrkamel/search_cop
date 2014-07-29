# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'search_cop/version'

Gem::Specification.new do |spec|
  spec.name          = "search_cop"
  spec.version       = SearchCop::VERSION
  spec.authors       = ["Benjamin Vetter"]
  spec.email         = ["vetter@flakks.com"]
  spec.description   = %q{Search engine like fulltext query support for ActiveRecord}
  spec.summary       = %q{Easily perform complex search engine like fulltext queries on your ActiveRecord models}
  spec.homepage      = "https://github.com/mrkamel/search_cop"
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
  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "minitest"
end
