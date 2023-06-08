# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "yarp"
  spec.version = "0.4.0"
  spec.authors = ["Shopify"]
  spec.email = ["ruby@shopify.com"]

  spec.summary = "Yet Another Ruby Parser"
  spec.homepage = "https://github.com/ruby/yarp"
  spec.license = "MIT"

  spec.require_paths = ["lib"]
  spec.files = Dir.glob([
    "CODE_OF_CONDUCT.md",
    "config.yml",
    "CONTRIBUTING.md",
    "Gemfile",
    "LICENSE.md",
    "Makefile",
    "Rakefile",
    "yarp.gemspec",
    "bin/**/*",
    "docs/**/*",
    "ext/**/*",
    "include/**/*",
    "lib/**/*.rb",
    "src/**/*"
  ])

  spec.extensions = ["ext/yarp/extconf.rb"]
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
end
