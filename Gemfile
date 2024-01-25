# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "rake"
gem "rake-compiler"
gem "test-unit"

# Some gems we don't want to install on JRuby or TruffleRuby.
platforms = %i[mri mswin mingw x64_mingw]

gem "ffi", platform: platforms
group :memcheck do
  gem "ruby_memcheck", platform: platforms
end

gem "rbs", platform: platforms
gem "parser", platform: platforms
gem "ruby_parser", platform: platforms
