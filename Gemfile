# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "rake"
gem "rake-compiler"
gem "test-unit"
gem "ruby_memcheck", platform: %i[mri truffleruby mswin mingw x64_mingw]

if RUBY_ENGINE == 'ruby' and ENV["YARP_FFI_BACKEND"]
  gem "ffi"
end
