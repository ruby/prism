# typed: strict

class Prism::DesugarCompiler < Prism::MutationCompiler
  Result = type_member { { fixed: Prism::Node } }
end
