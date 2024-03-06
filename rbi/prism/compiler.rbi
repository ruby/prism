# typed: strict

class Prism::Compiler
  Result = type_member

  sig { params(node: T.nilable(Prism::Node)).returns(T.nilable(Result)) }
  def visit(node); end

  sig { params(nodes: T::Array[T.nilable(Prism::Node)]).returns(T::Array[T.nilable(Result)]) }
  def visit_all(nodes); end

  sig { params(node: Prism::Node).returns(T::Array[T.nilable(Result)]) }
  def visit_child_nodes(node); end
end
