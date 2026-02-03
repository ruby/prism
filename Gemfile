# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "benchmark-ips"
gem "parser"
gem "rake"
gem "rake-compiler"
gem "ruby_parser"
gem "test-unit"

platforms :mri, :mswin, :mingw, :x64_mingw do
  gem "ffi"
  gem "irb"
  gem "ruby_memcheck"
  gem "rdoc"
end

gem "onigmo", platforms: :ruby
