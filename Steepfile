# frozen_string_literal: true

target :lib do
  check "lib"
  signature "sig"

  library "cgi"
  library "pp"

  # Ignored because it requires other libraries.
  ignore "lib/prism/translation"

  # Ignored because they are only for older Rubies.
  ignore "lib/prism/polyfill"

  # Ignored because we do not want to overlap with the C extension.
  ignore "lib/prism/ffi.rb"
end
