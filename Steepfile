# frozen_string_literal: true

target :lib do
  signature "sig"

  library "cgi" # in lib/prism/dot_visitor.rb (Prism::DotVisitor)

  check "lib"

  # TODO: Type-checking these files is still WIP
  ignore "lib/prism/desugar_compiler.rb"
  ignore "lib/prism/lex_compat.rb"
  ignore "lib/prism/serialize.rb"
  ignore "lib/prism/ffi.rb"
  ignore "lib/prism/translation"

  ignore "lib/prism/polyfill/append_as_bytes.rb"
  ignore "lib/prism/polyfill/byteindex.rb"
  ignore "lib/prism/polyfill/scan_byte.rb"
  ignore "lib/prism/polyfill/unpack1.rb"
end
