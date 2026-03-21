# typed: true

module Prism
  # Finds the Prism AST node corresponding to a given Method, UnboundMethod,
  # Proc, or Thread::Backtrace::Location. On CRuby, uses node_id from the
  # instruction sequence for an exact match. On other implementations, falls
  # back to best-effort matching by source location line number.
  #
  # This module is autoloaded so that programs that don't use Prism.find don't
  # pay for its definition.
  module NodeFind
    # Find the node for the given callable or backtrace location.
    sig { params(callable: ::T.any(Method, UnboundMethod, Proc, Thread::Backtrace::Location), rubyvm: T::Boolean).returns(::T.nilable(Node)) }
    def self.find(callable, rubyvm); end

    # Base class that handles parsing a file.
    class Find
      # Parse the given file path, returning a ParseResult or nil.
      sig { params(file: ::T.nilable(String)).returns(::T.nilable(ParseResult)) }
      private def parse_file(file); end
    end

    # Finds the AST node for a Method, UnboundMethod, or Proc using the node_id
    # from the instruction sequence.
    class RubyVMCallableFind < Find
      # Find the node for the given callable using the ISeq node_id.
      sig { params(callable: ::T.any(Method, UnboundMethod, Proc)).returns(::T.nilable(Node)) }
      def find(callable); end
    end

    # Finds the AST node for a Thread::Backtrace::Location using the node_id
    # from the backtrace location.
    class RubyVMBacktraceLocationFind < Find
      # Find the node for the given backtrace location using node_id.
      sig { params(location: Thread::Backtrace::Location).returns(::T.nilable(Node)) }
      def find(location); end
    end

    # Finds the AST node for a Method or UnboundMethod using best-effort line
    # matching. Used on non-CRuby implementations.
    class LineMethodFind < Find
      # Find the node for the given method by matching on name and line.
      sig { params(callable: ::T.any(Method, UnboundMethod)).returns(::T.nilable(Node)) }
      def find(callable); end
    end

    # Finds the AST node for a lambda using best-effort line matching. Used
    # on non-CRuby implementations.
    class LineLambdaFind < Find
      # Find the node for the given lambda by matching on line.
      sig { params(callable: Proc).returns(::T.nilable(Node)) }
      def find(callable); end
    end

    # Finds the AST node for a non-lambda Proc using best-effort line
    # matching. Used on non-CRuby implementations.
    class LineProcFind < Find
      # Find the node for the given proc by matching on line.
      sig { params(callable: Proc).returns(::T.nilable(Node)) }
      def find(callable); end
    end

    # Finds the AST node for a Thread::Backtrace::Location using best-effort
    # line matching. Used on non-CRuby implementations.
    class LineBacktraceLocationFind < Find
      # Find the node for the given backtrace location by matching on line.
      sig { params(location: Thread::Backtrace::Location).returns(::T.nilable(Node)) }
      def find(location); end
    end
  end
end
