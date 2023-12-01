# frozen_string_literal: true

require_relative "lib/rubanok/version"

Gem::Specification.new do |spec|
  spec.name = "rubanok"
  spec.version = Rubanok::VERSION
  spec.authors = ["Vladimir Dementyev"]
  spec.email = ["dementiev.vm@gmail.com"]

  spec.summary = "Parameters-based transformation DSL"
  spec.description = "Parameters-based transformation DSL"
  spec.homepage = "https://github.com/palkan/rubanok"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.files = Dir.glob("lib/**/*") + %w[README.md LICENSE.txt CHANGELOG.md] +
    Dir.glob("sig/**/*")

  spec.metadata = {
    "bug_tracker_uri" => "http://github.com/palkan/rubanok/issues",
    "changelog_uri" => "https://github.com/palkan/rubanok/blob/master/CHANGELOG.md",
    "documentation_uri" => "http://github.com/palkan/rubanok",
    "homepage_uri" => "http://github.com/palkan/rubanok",
    "source_code_uri" => "http://github.com/palkan/rubanok"
  }

  spec.require_paths = ["lib"]

  spec.add_development_dependency "actionpack", ">= 6.0"
  spec.add_development_dependency "actionview", ">= 6.0"
  spec.add_development_dependency "bundler", ">= 1.16"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "rspec", ">= 3.0"
  spec.add_development_dependency "rspec-rails"
end
