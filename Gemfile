# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "benchmark-ips"
gem "rake"
gem "rake-compiler"
gem "test-unit"

platforms :mri, :mswin, :mingw, :x64_mingw do
  gem "ffi"
  gem "parser"
  gem "ruby_memcheck"
  gem "ruby_parser"
  gem "rdoc"
end

gem "onigmo", platforms: :ruby
