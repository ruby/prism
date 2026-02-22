# typed: true

module Prism
  class DesugarAndWriteNode
    include DSL

    sig { returns(T.any(ClassVariableAndWriteNode, ConstantAndWriteNode, GlobalVariableAndWriteNode, InstanceVariableAndWriteNode, LocalVariableAndWriteNode)) }
    attr_reader :node

    sig { returns(Source) }
    attr_reader :default_source

    sig { returns(Symbol) }
    attr_reader :read_class

    sig { returns(Symbol) }
    attr_reader :write_class

    sig { returns(T::Hash[Symbol, T.untyped]) }
    attr_reader :arguments

    sig { params(node: T.any(ClassVariableAndWriteNode, ConstantAndWriteNode, GlobalVariableAndWriteNode, InstanceVariableAndWriteNode, LocalVariableAndWriteNode), default_source: Source, read_class: Symbol, write_class: Symbol, arguments: T.untyped).void }
    def initialize(node, default_source, read_class, write_class, **arguments); end

    # Desugar `x &&= y` to `x && x = y`
    sig { returns(Node) }
    def compile; end
  end

  class DesugarOrWriteDefinedNode
    include DSL

    sig { returns(T.any(ClassVariableOrWriteNode, ConstantOrWriteNode, GlobalVariableOrWriteNode)) }
    attr_reader :node

    sig { returns(Source) }
    attr_reader :default_source

    sig { returns(Symbol) }
    attr_reader :read_class

    sig { returns(Symbol) }
    attr_reader :write_class

    sig { returns(T::Hash[Symbol, T.untyped]) }
    attr_reader :arguments

    sig { params(node: T.any(ClassVariableOrWriteNode, ConstantOrWriteNode, GlobalVariableOrWriteNode), default_source: Source, read_class: Symbol, write_class: Symbol, arguments: T.untyped).void }
    def initialize(node, default_source, read_class, write_class, **arguments); end

    # Desugar `x ||= y` to `defined?(x) ? x : x = y`
    sig { returns(Node) }
    def compile; end
  end

  class DesugarOperatorWriteNode
    include DSL

    sig { returns(T.any(ClassVariableOperatorWriteNode, ConstantOperatorWriteNode, GlobalVariableOperatorWriteNode, InstanceVariableOperatorWriteNode, LocalVariableOperatorWriteNode)) }
    attr_reader :node

    sig { returns(Source) }
    attr_reader :default_source

    sig { returns(Symbol) }
    attr_reader :read_class

    sig { returns(Symbol) }
    attr_reader :write_class

    sig { returns(T::Hash[Symbol, T.untyped]) }
    attr_reader :arguments

    sig { params(node: T.any(ClassVariableOperatorWriteNode, ConstantOperatorWriteNode, GlobalVariableOperatorWriteNode, InstanceVariableOperatorWriteNode, LocalVariableOperatorWriteNode), default_source: Source, read_class: Symbol, write_class: Symbol, arguments: T.untyped).void }
    def initialize(node, default_source, read_class, write_class, **arguments); end

    # Desugar `x += y` to `x = x + y`
    sig { returns(Node) }
    def compile; end
  end

  class DesugarOrWriteNode
    include DSL

    sig { returns(T.any(InstanceVariableOrWriteNode, LocalVariableOrWriteNode)) }
    attr_reader :node

    sig { returns(Source) }
    attr_reader :default_source

    sig { returns(Symbol) }
    attr_reader :read_class

    sig { returns(Symbol) }
    attr_reader :write_class

    sig { returns(T::Hash[Symbol, T.untyped]) }
    attr_reader :arguments

    sig { params(node: T.any(InstanceVariableOrWriteNode, LocalVariableOrWriteNode), default_source: Source, read_class: Symbol, write_class: Symbol, arguments: T.untyped).void }
    def initialize(node, default_source, read_class, write_class, **arguments); end

    # Desugar `x ||= y` to `x || x = y`
    sig { returns(Node) }
    def compile; end
  end

  class ClassVariableAndWriteNode
    sig { returns(Node) }
    def desugar; end
  end

  class ClassVariableOrWriteNode
    sig { returns(Node) }
    def desugar; end
  end

  class ClassVariableOperatorWriteNode
    sig { returns(Node) }
    def desugar; end
  end

  class ConstantAndWriteNode
    sig { returns(Node) }
    def desugar; end
  end

  class ConstantOrWriteNode
    sig { returns(Node) }
    def desugar; end
  end

  class ConstantOperatorWriteNode
    sig { returns(Node) }
    def desugar; end
  end

  class GlobalVariableAndWriteNode
    sig { returns(Node) }
    def desugar; end
  end

  class GlobalVariableOrWriteNode
    sig { returns(Node) }
    def desugar; end
  end

  class GlobalVariableOperatorWriteNode
    sig { returns(Node) }
    def desugar; end
  end

  class InstanceVariableAndWriteNode
    sig { returns(Node) }
    def desugar; end
  end

  class InstanceVariableOrWriteNode
    sig { returns(Node) }
    def desugar; end
  end

  class InstanceVariableOperatorWriteNode
    sig { returns(Node) }
    def desugar; end
  end

  class LocalVariableAndWriteNode
    sig { returns(Node) }
    def desugar; end
  end

  class LocalVariableOrWriteNode
    sig { returns(Node) }
    def desugar; end
  end

  class LocalVariableOperatorWriteNode
    sig { returns(Node) }
    def desugar; end
  end

  # DesugarCompiler is a compiler that desugars Ruby code into a more primitive
  # form. This is useful for consumers that want to deal with fewer node types.
  class DesugarCompiler < MutationCompiler
    # `@@foo &&= bar`
    #
    # becomes
    #
    # `@@foo && @@foo = bar`
    sig { params(node: ClassVariableAndWriteNode).returns(Node) }
    def visit_class_variable_and_write_node(node); end

    # `@@foo ||= bar`
    #
    # becomes
    #
    # `defined?(@@foo) ? @@foo : @@foo = bar`
    sig { params(node: ClassVariableOrWriteNode).returns(Node) }
    def visit_class_variable_or_write_node(node); end

    # `@@foo += bar`
    #
    # becomes
    #
    # `@@foo = @@foo + bar`
    sig { params(node: ClassVariableOperatorWriteNode).returns(Node) }
    def visit_class_variable_operator_write_node(node); end

    # `Foo &&= bar`
    #
    # becomes
    #
    # `Foo && Foo = bar`
    sig { params(node: ConstantAndWriteNode).returns(Node) }
    def visit_constant_and_write_node(node); end

    # `Foo ||= bar`
    #
    # becomes
    #
    # `defined?(Foo) ? Foo : Foo = bar`
    sig { params(node: ConstantOrWriteNode).returns(Node) }
    def visit_constant_or_write_node(node); end

    # `Foo += bar`
    #
    # becomes
    #
    # `Foo = Foo + bar`
    sig { params(node: ConstantOperatorWriteNode).returns(Node) }
    def visit_constant_operator_write_node(node); end

    # `$foo &&= bar`
    #
    # becomes
    #
    # `$foo && $foo = bar`
    sig { params(node: GlobalVariableAndWriteNode).returns(Node) }
    def visit_global_variable_and_write_node(node); end

    # `$foo ||= bar`
    #
    # becomes
    #
    # `defined?($foo) ? $foo : $foo = bar`
    sig { params(node: GlobalVariableOrWriteNode).returns(Node) }
    def visit_global_variable_or_write_node(node); end

    # `$foo += bar`
    #
    # becomes
    #
    # `$foo = $foo + bar`
    sig { params(node: GlobalVariableOperatorWriteNode).returns(Node) }
    def visit_global_variable_operator_write_node(node); end

    # `@foo &&= bar`
    #
    # becomes
    #
    # `@foo && @foo = bar`
    sig { params(node: InstanceVariableAndWriteNode).returns(Node) }
    def visit_instance_variable_and_write_node(node); end

    # `@foo ||= bar`
    #
    # becomes
    #
    # `@foo || @foo = bar`
    sig { params(node: InstanceVariableOrWriteNode).returns(Node) }
    def visit_instance_variable_or_write_node(node); end

    # `@foo += bar`
    #
    # becomes
    #
    # `@foo = @foo + bar`
    sig { params(node: InstanceVariableOperatorWriteNode).returns(Node) }
    def visit_instance_variable_operator_write_node(node); end

    # `foo &&= bar`
    #
    # becomes
    #
    # `foo && foo = bar`
    sig { params(node: LocalVariableAndWriteNode).returns(Node) }
    def visit_local_variable_and_write_node(node); end

    # `foo ||= bar`
    #
    # becomes
    #
    # `foo || foo = bar`
    sig { params(node: LocalVariableOrWriteNode).returns(Node) }
    def visit_local_variable_or_write_node(node); end

    # `foo += bar`
    #
    # becomes
    #
    # `foo = foo + bar`
    sig { params(node: LocalVariableOperatorWriteNode).returns(Node) }
    def visit_local_variable_operator_write_node(node); end
  end
end
