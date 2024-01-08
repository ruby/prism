# frozen_string_literal: true

target :lib do
  signature "sig"

  # Tell Steep about stdlib require's
  library "ripper" # RipperCompat
  library "delegate"  # LexCompat
  library "cgi"  # DotVisitor

  check "lib"

  # TODO: Type-checking these files is still WIP
  ignore "lib/prism/debug.rb"
  ignore "lib/prism/desugar_compiler.rb"
  ignore "lib/prism/lex_compat.rb"
  ignore "lib/prism/serialize.rb"
  ignore "lib/prism/ffi.rb"
end
