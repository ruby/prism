# typed: strict

# We keep this shim in here because our client libraries might not have
# ruby_parser in their bundle.
class Sexp < ::Array
  Elem = type_member { { fixed: T.untyped }}
end

class Prism::Translation::RubyParser::Compiler < Prism::Compiler
  Result = type_member { { fixed: Sexp } }
end
