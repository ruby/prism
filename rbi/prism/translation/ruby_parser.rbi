# typed: strict

class Prism::Translation::RubyParser::Compiler < Prism::Compiler
  Result = type_member { { fixed: Sexp } }
end
