# frozen_string_literal: true

require_relative "lib/yarp/version"

Gem::Specification.new do |spec|
  spec.name = "yarp"
  spec.version = YARP::VERSION
  spec.authors = ["Kevin Newton"]
  spec.email = ["kddnewton@gmail.com"]

  spec.summary = "Yet Another Ruby Parser"
  spec.homepage = "https://github.com/ruby-syntax-tree/yarp"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions    = ["ext/yarp/extconf.rb"]

  spec.add_development_dependency "bundler", "~> 2"
  spec.add_development_dependency "minitest", "~> 5"
  spec.add_development_dependency "rake", "~> 13"
  spec.add_development_dependency "rake-compiler", "~> 1"
  spec.add_development_dependency "test-unit", "~> 3"
end
