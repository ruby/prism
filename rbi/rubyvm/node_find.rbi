# typed: true

class RubyVM::InstructionSequence
  sig { params(callable: T.any(Method, UnboundMethod, Proc)).returns(T.nilable(RubyVM::InstructionSequence)) }
  def self.of(callable); end

  sig { returns(T::Array[T.untyped]) }
  def to_a; end
end

module RubyVM::AbstractSyntaxTree
  sig { params(location: Thread::Backtrace::Location).returns(Integer) }
  def self.node_id_for_backtrace_location(location); end
end
