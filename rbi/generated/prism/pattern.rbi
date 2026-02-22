# typed: true

module Prism
  # A pattern is an object that wraps a Ruby pattern matching expression. The
  # expression would normally be passed to an `in` clause within a `case`
  # expression or a rightward assignment expression. For example, in the
  # following snippet:
  #
  #     case node
  #     in ConstantPathNode[ConstantReadNode[name: :Prism], ConstantReadNode[name: :Pattern]]
  #     end
  #
  # the pattern is the <tt>ConstantPathNode[...]</tt> expression.
  #
  # The pattern gets compiled into an object that responds to #call by running
  # the #compile method. This method itself will run back through Prism to
  # parse the expression into a tree, then walk the tree to generate the
  # necessary callable objects. For example, if you wanted to compile the
  # expression above into a callable, you would:
  #
  #     callable = Prism::Pattern.new("ConstantPathNode[ConstantReadNode[name: :Prism], ConstantReadNode[name: :Pattern]]").compile
  #     callable.call(node)
  #
  # The callable object returned by #compile is guaranteed to respond to #call
  # with a single argument, which is the node to match against. It also is
  # guaranteed to respond to #===, which means it itself can be used in a `case`
  # expression, as in:
  #
  #     case node
  #     when callable
  #     end
  #
  # If the query given to the initializer cannot be compiled into a valid
  # matcher (either because of a syntax error or because it is using syntax we
  # do not yet support) then a Prism::Pattern::CompilationError will be
  # raised.
  class Pattern
    # Raised when the query given to a pattern is either invalid Ruby syntax or
    # is using syntax that we don't yet support.
    class CompilationError < StandardError
      # Create a new CompilationError with the given representation of the node
      # that caused the error.
      sig { params(repr: String).void }
      def initialize(repr); end
    end

    # The query that this pattern was initialized with.
    sig { returns(String) }
    attr_reader :query

    # Create a new pattern with the given query. The query should be a string
    # containing a Ruby pattern matching expression.
    sig { params(query: String).void }
    def initialize(query); end

    # Compile the query into a callable object that can be used to match against
    # nodes.
    sig { returns(Proc) }
    def compile; end

    # Scan the given node and all of its children for nodes that match the
    # pattern. If a block is given, it will be called with each node that
    # matches the pattern. If no block is given, an enumerator will be returned
    # that will yield each node that matches the pattern.
    sig { params(root: Node).returns(T::Enumerator[Node]) }
    sig { params(root: Node, blk: T.proc.params(arg0: Node).void).void }
    def scan(root, &blk); end

    # Shortcut for combining two procs into one that returns true if both return
    # true.
    sig { params(left: Proc, right: Proc).returns(Proc) }
    private def combine_and(left, right); end

    # Shortcut for combining two procs into one that returns true if either
    # returns true.
    sig { params(left: Proc, right: Proc).returns(Proc) }
    private def combine_or(left, right); end

    # Raise an error because the given node is not supported. Note purposefully
    # not typing this method since it is a no return method that Steep does not
    # understand.
    sig { params(node: Node).returns(T.noreturn) }
    private def compile_error(node); end

    # in [foo, bar, baz]
    sig { params(node: ArrayPatternNode).returns(Proc) }
    private def compile_array_pattern_node(node); end

    # in foo | bar
    sig { params(node: AlternationPatternNode).returns(Proc) }
    private def compile_alternation_pattern_node(node); end

    # in Prism::ConstantReadNode
    sig { params(node: ConstantPathNode).returns(Proc) }
    private def compile_constant_path_node(node); end

    # in ConstantReadNode
    # in String
    sig { params(node: ConstantReadNode).returns(Proc) }
    private def compile_constant_read_node(node); end

    # Compile a name associated with a constant.
    sig { params(node: T.any(ConstantPathNode, ConstantReadNode), name: Symbol).returns(Proc) }
    private def compile_constant_name(node, name); end

    # in InstanceVariableReadNode[name: Symbol]
    # in { name: Symbol }
    sig { params(node: HashPatternNode).returns(Proc) }
    private def compile_hash_pattern_node(node); end

    # in nil
    sig { params(node: NilNode).returns(Proc) }
    private def compile_nil_node(node); end

    # in /foo/
    sig { params(node: RegularExpressionNode).returns(Proc) }
    private def compile_regular_expression_node(node); end

    # in ""
    # in "foo"
    sig { params(node: StringNode).returns(Proc) }
    private def compile_string_node(node); end

    # in :+
    # in :foo
    sig { params(node: SymbolNode).returns(Proc) }
    private def compile_symbol_node(node); end

    # Compile any kind of node. Dispatch out to the individual compilation
    # methods based on the type of node.
    sig { params(node: Node).returns(Proc) }
    private def compile_node(node); end
  end
end
