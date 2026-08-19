# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "benchmark-ips"
gem "parser"
gem "rake"
gem "rake-compiler"
gem "rake-compiler-dock", "~> 1.12.0"
gem "ruby_parser"
gem "test-unit"

platforms :mri, :windows do
  gem "ffi"
  gem "irb"
  gem "rdoc"
end

platforms :mri do
  group :typecheck do
    gem "rbs", "< 4.1.0" # Until https://github.com/soutaro/steep/issues/2268 is fixed
    gem "rbi"
    gem "rbs-inline"
    gem "sorbet"
    gem "steep", ">= 2.1.0.dev.1"
    gem "tapioca"
  end
end

gem "onigmo", platforms: :ruby

gem "lrama"
