lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "search_cop/version"

Gem::Specification.new do |spec|
  spec.name          = "search_cop"
  spec.version       = SearchCop::VERSION
  spec.authors       = ["Benjamin Vetter"]
  spec.email         = ["vetter@flakks.com"]
  spec.description   = "Search engine like fulltext query support for ActiveRecord"
  spec.summary       = "Easily perform complex search engine like fulltext queries on your ActiveRecord models"
  spec.homepage      = "https://github.com/mrkamel/search_cop"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mrkamel/search_cop"
  spec.metadata["changelog_uri"] = "https://github.com/mrkamel/search_cop/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "treetop"

  spec.add_development_dependency "activerecord", ">= 3.0.0"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "factory_bot"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rubocop"
end
