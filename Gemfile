# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "benchmark-ips"
gem "rake"
gem "rake-compiler"
gem "test-unit"

platforms :mri, :mswin, :mingw, :x64_mingw do
  if RUBY_VERSION >= '3.0.0'
    gem "ffi"
  end
  gem "parser"
  gem "ruby_memcheck"
  gem "ruby_parser"
  gem "rdoc"
end

gem "onigmo", platforms: :ruby
