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
gem "rdoc"

platforms :mri, :windows do
  gem "ffi"
  gem "irb"

  group :memcheck, optional: true do
    gem "ruby_memcheck"
  end
end

gem "onigmo", platforms: :ruby

gem "lrama"
