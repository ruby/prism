# typed: strict

class Prism::Translation::Parser::Compiler < Prism::Compiler
  Result = type_member { { fixed: Parser::AST::Node } }
end
