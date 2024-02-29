# typed: strict

# We keep these shims in here because our client libraries might not have
# ast/parser in their bundle.
module AST; end
class AST::Node; end
module Parser; end
module Parser::AST; end
class Parser::AST::Node < AST::Node; end

class Prism::Translation::Parser::Compiler < Prism::Compiler
  Result = type_member { { fixed: Parser::AST::Node } }
end
