# typed: true

module Prism
  # This represents a node in the tree. It is the parent class of all of the
  # various node types.
  class Node
    abstract!

    # A pointer to the source that this node was created from.
    sig { returns(Source) }
    attr_reader :source

    # A unique identifier for this node. This is used in a very specific
    # use case where you want to keep around a reference to a node without
    # having to keep around the syntax tree in memory. This unique identifier
    # will be consistent across multiple parses of the same source code.
    sig { returns(Integer) }
    attr_reader :node_id

    # Save this node using a saved source so that it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save(repository); end

    # A Location instance that represents the location of this node in the
    # source.
    sig { returns(Location) }
    def location; end

    # Save the location using a saved source so that it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_location(repository); end

    # Delegates to [`start_line`](rdoc-ref:Location#start_line) of the associated location object.
    sig { returns(Integer) }
    def start_line; end

    # Delegates to [`end_line`](rdoc-ref:Location#end_line) of the associated location object.
    sig { returns(Integer) }
    def end_line; end

    # Delegates to [`start_offset`](rdoc-ref:Location#start_offset) of the associated location object.
    sig { returns(Integer) }
    def start_offset; end

    # Delegates to [`end_offset`](rdoc-ref:Location#end_offset) of the associated location object.
    sig { returns(Integer) }
    def end_offset; end

    # Delegates to [`start_character_offset`](rdoc-ref:Location#start_character_offset)
    # of the associated location object.
    sig { returns(Integer) }
    def start_character_offset; end

    # Delegates to [`end_character_offset`](rdoc-ref:Location#end_character_offset)
    # of the associated location object.
    sig { returns(Integer) }
    def end_character_offset; end

    # Delegates to [`cached_start_code_units_offset`](rdoc-ref:Location#cached_start_code_units_offset)
    # of the associated location object.
    sig { params(cache: ::T.untyped).returns(Integer) }
    def cached_start_code_units_offset(cache); end

    # Delegates to [`cached_end_code_units_offset`](rdoc-ref:Location#cached_end_code_units_offset)
    # of the associated location object.
    sig { params(cache: ::T.untyped).returns(Integer) }
    def cached_end_code_units_offset(cache); end

    # Delegates to [`start_column`](rdoc-ref:Location#start_column) of the associated location object.
    sig { returns(Integer) }
    def start_column; end

    # Delegates to [`end_column`](rdoc-ref:Location#end_column) of the associated location object.
    sig { returns(Integer) }
    def end_column; end

    # Delegates to [`start_character_column`](rdoc-ref:Location#start_character_column)
    # of the associated location object.
    sig { returns(Integer) }
    def start_character_column; end

    # Delegates to [`end_character_column`](rdoc-ref:Location#end_character_column)
    # of the associated location object.
    sig { returns(Integer) }
    def end_character_column; end

    # Delegates to [`cached_start_code_units_column`](rdoc-ref:Location#cached_start_code_units_column)
    # of the associated location object.
    sig { params(cache: ::T.untyped).returns(Integer) }
    def cached_start_code_units_column(cache); end

    # Delegates to [`cached_end_code_units_column`](rdoc-ref:Location#cached_end_code_units_column)
    # of the associated location object.
    sig { params(cache: ::T.untyped).returns(Integer) }
    def cached_end_code_units_column(cache); end

    # The comments attached to this node, ordered by start offset. Comments are
    # only attached when the source is parsed with the attach_comments option.
    sig { returns(T::Array[Comment]) }
    def comments; end

    # Returns all of the lines of the source code associated with this node.
    sig { returns(T::Array[String]) }
    def source_lines; end

    # An alias for source_lines, used to mimic the API from
    # RubyVM::AbstractSyntaxTree to make it easier to migrate.
    sig { returns(T::Array[String]) }
    def script_lines; end

    # Slice the location of the node from the source.
    sig { returns(String) }
    def slice; end

    # Slice the location of the node from the source, starting at the beginning
    # of the line that the location starts on, ending at the end of the line
    # that the location ends on.
    sig { returns(String) }
    def slice_lines; end

    # An bitset of flags for this node. There are certain flags that are common
    # for all nodes, and then some nodes have specific flags.
    sig { returns(Integer) }
    attr_reader :flags

    # Returns true if the node has the newline flag set.
    sig { returns(T::Boolean) }
    def newline?; end

    # Returns true if the node has the static literal flag set.
    sig { returns(T::Boolean) }
    def static_literal?; end

    # Similar to inspect, but respects the current level of indentation given by
    # the pretty print object.
    sig { params(q: PP).void }
    def pretty_print(q); end

    # Convert this node into a graphviz dot graph string.
    sig { returns(String) }
    def to_dot; end

    # Returns a list of nodes that are descendants of this node that contain the
    # given line and column. This is useful for locating a node that is selected
    # based on the line and column of the source code.
    #
    # Important to note is that the column given to this method should be in
    # bytes, as opposed to characters or code units.
    sig { params(line: Integer, column: Integer).returns(T::Array[Node]) }
    def tunnel(line, column); end

    # Returns the first node that matches the given block when visited in a
    # breadth-first search. This is useful for finding a node that matches a
    # particular condition.
    #
    #     node.breadth_first_search { |node| node.node_id == node_id }
    sig { params(blk: ::T.proc.params(arg0: Node).returns(T::Boolean)).returns(::T.nilable(Node)) }
    def breadth_first_search(&blk); end

    sig { params(blk: ::T.proc.params(arg0: Node).returns(T::Boolean)).returns(::T.nilable(Node)) }
    def find(&blk); end

    # Returns all of the nodes that match the given block when visited in a
    # breadth-first search. This is useful for finding all nodes that match a
    # particular condition.
    #
    #     node.breadth_first_search_all { |node| node.is_a?(Prism::CallNode) }
    sig { params(blk: ::T.proc.params(arg0: Node).returns(T::Boolean)).returns(T::Array[Node]) }
    def breadth_first_search_all(&blk); end

    sig { params(blk: ::T.proc.params(arg0: Node).returns(T::Boolean)).returns(T::Array[Node]) }
    def find_all(&blk); end

    # Returns a list of the fields that exist for this node class. Fields
    # describe the structure of the node. This kind of reflection is useful for
    # things like recursively visiting each node _and_ field in the tree.
    sig { returns(T::Array[Reflection::Field]) }
    def self.fields; end

    # Accepts a visitor and calls back into the specialized visit function.
    sig { abstract.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # Returns an array of child nodes, including `nil`s in the place of optional
    # nodes that were not present.
    sig { abstract.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    sig { abstract.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    # With a block given, yields each child node. Without a block, returns
    # an enumerator that contains each child node. Excludes any `nil`s in
    # the place of optional nodes that were not present.
    sig { abstract.returns(T::Enumerator[Node]) }
    sig { abstract.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # Returns an array of child nodes, excluding any `nil`s in the place of
    # optional nodes that were not present.
    sig { abstract.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Returns a string representation of the node.
    sig { abstract.returns(String) }
    def inspect; end

    # Sometimes you want to check an instance of a node against a list of
    # classes to see what kind of behavior to perform. Usually this is done by
    # calling `[cls1, cls2].include?(node.class)` or putting the node into a
    # case statement and doing `case node; when cls1; when cls2; end`. Both of
    # these approaches are relatively slow because of the constant lookups,
    # method calls, and/or array allocations.
    #
    # Instead, you can call #type, which will return to you a symbol that you
    # can use for comparison. This is faster than the other approaches because
    # it uses a single integer comparison, but also because if you're on CRuby
    # you can take advantage of the fact that case statements with all symbol
    # keys will use a jump table.
    sig { abstract.returns(Symbol) }
    def type; end

    # Similar to #type, this method returns a symbol that you can use for
    # splitting on the type of the node without having to do a long === chain.
    # Note that like #type, it will still be slower than using == for a single
    # class, but should be faster in a case statement or an array comparison.
    sig { abstract.returns(Symbol) }
    def self.type; end
  end

  # Represents the use of the `alias` keyword to alias a global variable.
  #
  # ```rb
  # alias $foo $bar
  # ^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#YWxpYXMgJGZvbyAkYmFyCg)
  class AliasGlobalVariableNode < Node
    # Initialize a new AliasGlobalVariableNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, new_name: ::T.any(GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode), old_name: ::T.any(GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode), keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, new_name, old_name, keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, new_name: ::T.any(GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode), old_name: ::T.any(GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode), keyword_loc: Location).returns(AliasGlobalVariableNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), new_name: T.unsafe(nil), old_name: T.unsafe(nil), keyword_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Represents the new name of the global variable that can be used after aliasing.
    #
    # ```rb
    # alias $foo $bar
    #       ^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YWxpYXMgJGZvbyAkYmFyCg)
    sig { returns(::T.any(GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode)) }
    def new_name; end

    # Represents the old name of the global variable that can be used before aliasing.
    #
    # ```rb
    # alias $foo $bar
    #            ^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YWxpYXMgJGZvbyAkYmFyCg)
    sig { returns(::T.any(GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode)) }
    def old_name; end

    # The Location of the `alias` keyword.
    #
    # ```rb
    # alias $foo $bar
    # ^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YWxpYXMgJGZvbyAkYmFyCg)
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `alias` keyword to alias a method.
  #
  # ```rb
  # alias foo bar
  # ^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#YWxpYXMgZm9vIGJhcgo)
  class AliasMethodNode < Node
    # Initialize a new AliasMethodNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, new_name: ::T.any(SymbolNode, InterpolatedSymbolNode), old_name: ::T.any(SymbolNode, InterpolatedSymbolNode), keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, new_name, old_name, keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, new_name: ::T.any(SymbolNode, InterpolatedSymbolNode), old_name: ::T.any(SymbolNode, InterpolatedSymbolNode), keyword_loc: Location).returns(AliasMethodNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), new_name: T.unsafe(nil), old_name: T.unsafe(nil), keyword_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Represents the new name of the method that will be aliased.
    #
    # ```rb
    # alias foo bar
    #       ^^^
    #
    # alias :foo :bar
    #       ^^^^
    #
    # alias :"#{foo}" :"#{bar}"
    #       ^^^^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YWxpYXMgZm9vIGJhcgoKYWxpYXMgOmZvbyA6YmFyCgphbGlhcyA6IiN7Zm9vfSIgOiIje2Jhcn0iCg)
    sig { returns(::T.any(SymbolNode, InterpolatedSymbolNode)) }
    def new_name; end

    # Represents the old name of the method that will be aliased.
    #
    # ```rb
    # alias foo bar
    #           ^^^
    #
    # alias :foo :bar
    #            ^^^^
    #
    # alias :"#{foo}" :"#{bar}"
    #                 ^^^^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YWxpYXMgZm9vIGJhcgoKYWxpYXMgOmZvbyA6YmFyCgphbGlhcyA6IiN7Zm9vfSIgOiIje2Jhcn0iCg)
    sig { returns(::T.any(SymbolNode, InterpolatedSymbolNode)) }
    def old_name; end

    # Represents the Location of the `alias` keyword.
    #
    # ```rb
    # alias foo bar
    # ^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YWxpYXMgZm9vIGJhcgo)
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an alternation pattern in pattern matching.
  #
  # ```rb
  # foo => bar | baz
  #        ^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0-IGJhciB8IGJhego)
  class AlternationPatternNode < Node
    # Initialize a new AlternationPatternNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, left: Node, right: Node, operator_loc: Location).void }
    def initialize(source, node_id, location, flags, left, right, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, left: Node, right: Node, operator_loc: Location).returns(AlternationPatternNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), left: T.unsafe(nil), right: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Represents the left side of the expression.
    #
    # ```rb
    # foo => bar | baz
    #        ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0-IGJhciB8IGJhego)
    sig { returns(Node) }
    def left; end

    # Represents the right side of the expression.
    #
    # ```rb
    # foo => bar | baz
    #              ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0-IGJhciB8IGJhego)
    sig { returns(Node) }
    def right; end

    # Represents the alternation operator Location.
    #
    # ```rb
    # foo => bar | baz
    #            ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0-IGJhciB8IGJhego)
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `&&` operator or the `and` keyword.
  #
  # ```rb
  # left and right
  # ^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#bGVmdCBhbmQgcmlnaHQK)
  class AndNode < Node
    # Initialize a new AndNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, left: Node, right: Node, operator_loc: Location).void }
    def initialize(source, node_id, location, flags, left, right, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, left: Node, right: Node, operator_loc: Location).returns(AndNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), left: T.unsafe(nil), right: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Represents the left side of the expression. It can be any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # left and right
    # ^^^^
    #
    # 1 && 2
    # ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#bGVmdCBhbmQgcmlnaHQKCjEgJiYgMgo)
    sig { returns(Node) }
    def left; end

    # Represents the right side of the expression.
    #
    # ```rb
    # left && right
    #         ^^^^^
    #
    # 1 and 2
    #       ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#bGVmdCAmJiByaWdodAoKMSBhbmQgMgo)
    sig { returns(Node) }
    def right; end

    # The Location of the `and` keyword or the `&&` operator.
    #
    # ```rb
    # left and right
    #      ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#bGVmdCBhbmQgcmlnaHQK)
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a set of arguments to a method or a keyword.
  #
  # ```rb
  # return foo, bar, baz
  #        ^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#cmV0dXJuIGZvbywgYmFyLCBiYXoK)
  class ArgumentsNode < Node
    # Initialize a new ArgumentsNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, arguments: T::Array[Node]).void }
    def initialize(source, node_id, location, flags, arguments); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, arguments: T::Array[Node]).returns(ArgumentsNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), arguments: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # if the arguments contain forwarding
    sig { returns(T::Boolean) }
    def contains_forwarding?; end

    # if the arguments contain keywords
    sig { returns(T::Boolean) }
    def contains_keywords?; end

    # if the arguments contain a keyword splat
    sig { returns(T::Boolean) }
    def contains_keyword_splat?; end

    # if the arguments contain a splat
    sig { returns(T::Boolean) }
    def contains_splat?; end

    # if the arguments contain multiple splats
    sig { returns(T::Boolean) }
    def contains_multiple_splats?; end

    # The list of arguments, if present. These can be any [non-void expressions](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # foo(bar, baz)
    #     ^^^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vKGJhciwgYmF6KQo)
    sig { returns(T::Array[Node]) }
    def arguments; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an array literal. This can be a regular array using brackets or a special array using % like %w or %i.
  #
  # ```rb
  # [1, 2, 3]
  # ^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#WzEsIDIsIDNdCg)
  class ArrayNode < Node
    # Initialize a new ArrayNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, elements: T::Array[Node], opening_loc: ::T.nilable(Location), closing_loc: ::T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, elements, opening_loc, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, elements: T::Array[Node], opening_loc: ::T.nilable(Location), closing_loc: ::T.nilable(Location)).returns(ArrayNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), elements: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # if array contains splat nodes
    sig { returns(T::Boolean) }
    def contains_splat?; end

    # Represent the list of zero or more [non-void expressions](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression) within the array.
    sig { returns(T::Array[Node]) }
    def elements; end

    # Represents the optional source Location for the opening token.
    #
    # ```rb
    # [1,2,3]                 # "["
    # %w[foo bar baz]         # "%w["
    # %I(apple orange banana) # "%I("
    # foo = 1, 2, 3           # nil
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#WzEsMiwzXSAgICAgICAgICAgICAgICAgIyAiWyIKJXdbZm9vIGJhciBiYXpdICAgICAgICAgIyAiJXdbIgolSShhcHBsZSBvcmFuZ2UgYmFuYW5hKSAjICIlSSgiCmZvbyA9IDEsIDIsIDMgICAgICAgICAgICMgbmlsCg)
    sig { returns(::T.nilable(Location)) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_opening_loc(repository); end

    # Represents the optional source Location for the closing token.
    #
    # ```rb
    # [1,2,3]                 # "]"
    # %w[foo bar baz]         # "]"
    # %I(apple orange banana) # ")"
    # foo = 1, 2, 3           # nil
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#WzEsMiwzXSAgICAgICAgICAgICAgICAgIyAiXSIKJXdbZm9vIGJhciBiYXpdICAgICAgICAgIyAiXSIKJUkoYXBwbGUgb3JhbmdlIGJhbmFuYSkgIyAiKSIKZm9vID0gMSwgMiwgMyAgICAgICAgICAgIyBuaWwK)
    sig { returns(::T.nilable(Location)) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(::T.nilable(String)) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(::T.nilable(String)) }
    def closing; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an array pattern in pattern matching.
  #
  # ```rb
  # foo in 1, 2
  #        ^^^^
  #
  # foo in [1, 2]
  #        ^^^^^^
  #
  # foo in *bar
  #        ^^^^
  #
  # foo in Bar[]
  #        ^^^^^
  #
  # foo in Bar[1, 2, 3]
  #        ^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIGluIDEsIDIKCmZvbyBpbiBbMSwgMl0KCmZvbyBpbiAqYmFyCgpmb28gaW4gQmFyW10KCmZvbyBpbiBCYXJbMSwgMiwgM10K)
  class ArrayPatternNode < Node
    # Initialize a new ArrayPatternNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, constant: ::T.nilable(::T.any(ConstantPathNode, ConstantReadNode)), requireds: T::Array[Node], rest: ::T.nilable(::T.any(ImplicitRestNode, SplatNode)), posts: T::Array[Node], opening_loc: ::T.nilable(Location), closing_loc: ::T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, constant, requireds, rest, posts, opening_loc, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, constant: ::T.nilable(::T.any(ConstantPathNode, ConstantReadNode)), requireds: T::Array[Node], rest: ::T.nilable(::T.any(ImplicitRestNode, SplatNode)), posts: T::Array[Node], opening_loc: ::T.nilable(Location), closing_loc: ::T.nilable(Location)).returns(ArrayPatternNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), constant: T.unsafe(nil), requireds: T.unsafe(nil), rest: T.unsafe(nil), posts: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Represents the optional constant preceding the Array
    #
    # ```rb
    # foo in Bar[]
    #        ^^^
    #
    # foo in Bar[1, 2, 3]
    #        ^^^
    #
    # foo in Bar::Baz[1, 2, 3]
    #        ^^^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIGluIEJhcltdCgpmb28gaW4gQmFyWzEsIDIsIDNdCgpmb28gaW4gQmFyOjpCYXpbMSwgMiwgM10K)
    sig { returns(::T.nilable(::T.any(ConstantPathNode, ConstantReadNode))) }
    def constant; end

    # Represents the required elements of the array pattern.
    #
    # ```rb
    # foo in [1, 2]
    #         ^  ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIGluIFsxLCAyXQo)
    sig { returns(T::Array[Node]) }
    def requireds; end

    # Represents the rest element of the array pattern.
    #
    # ```rb
    # foo in *bar
    #        ^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIGluICpiYXIK)
    sig { returns(::T.nilable(::T.any(ImplicitRestNode, SplatNode))) }
    def rest; end

    # Represents the elements after the rest element of the array pattern.
    #
    # ```rb
    # foo in *bar, baz
    #              ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIGluICpiYXIsIGJhego)
    sig { returns(T::Array[Node]) }
    def posts; end

    # Represents the opening Location of the array pattern.
    #
    # ```rb
    # foo in [1, 2]
    #        ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIGluIFsxLCAyXQo)
    sig { returns(::T.nilable(Location)) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_opening_loc(repository); end

    # Represents the closing Location of the array pattern.
    #
    # ```rb
    # foo in [1, 2]
    #             ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIGluIFsxLCAyXQo)
    sig { returns(::T.nilable(Location)) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(::T.nilable(String)) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(::T.nilable(String)) }
    def closing; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a hash key/value pair.
  #
  # ```rb
  # { a => b }
  #   ^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#eyBhID0-IGIgfQo)
  class AssocNode < Node
    # Initialize a new AssocNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, key: Node, value: Node, operator_loc: ::T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, key, value, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, key: Node, value: Node, operator_loc: ::T.nilable(Location)).returns(AssocNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), key: T.unsafe(nil), value: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The key of the association. This can be any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # { a: b }
    #   ^
    #
    # { foo => bar }
    #   ^^^
    #
    # { def a; end => 1 }
    #   ^^^^^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#eyBhOiBiIH0KCnsgZm9vID0-IGJhciB9Cgp7IGRlZiBhOyBlbmQgPT4gMSB9Cg)
    sig { returns(Node) }
    def key; end

    # The value of the association, if present. This can be any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # { foo => bar }
    #          ^^^
    #
    # { x: 1 }
    #      ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#eyBmb28gPT4gYmFyIH0KCnsgeDogMSB9Cg)
    sig { returns(Node) }
    def value; end

    # The Location of the `=>` operator, if present.
    #
    # ```rb
    # { foo => bar }
    #       ^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#eyBmb28gPT4gYmFyIH0K)
    sig { returns(::T.nilable(Location)) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(::T.nilable(String)) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a splat in a hash literal.
  #
  # ```rb
  # { **foo }
  #   ^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#eyAqKmZvbyB9Cg)
  class AssocSplatNode < Node
    # Initialize a new AssocSplatNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, value: ::T.nilable(Node), operator_loc: Location).void }
    def initialize(source, node_id, location, flags, value, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, value: ::T.nilable(Node), operator_loc: Location).returns(AssocSplatNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), value: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The value to be splatted, if present. Will be missing when keyword rest argument forwarding is used.
    #
    # ```rb
    # { **foo }
    #     ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#eyAqKmZvbyB9Cg)
    sig { returns(::T.nilable(Node)) }
    def value; end

    # The Location of the `**` operator.
    #
    # ```rb
    # { **x }
    #   ^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#eyAqKnggfQo)
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents reading a reference to a field in the previous match.
  #
  # ```rb
  # $'
  # ^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#JCcK)
  class BackReferenceReadNode < Node
    # Initialize a new BackReferenceReadNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).void }
    def initialize(source, node_id, location, flags, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(BackReferenceReadNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The name of the back-reference variable, including the leading `$`.
    #
    # ```rb
    # $& # name `:$&`
    #
    # $+ # name `:$+`
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#JCYgIyBuYW1lIGA6JCZgCgokKyAjIG5hbWUgYDokK2AK)
    sig { returns(Symbol) }
    def name; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a begin statement.
  #
  # ```rb
  # begin
  #   foo
  # end
  # ^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#YmVnaW4KICBmb28KZW5kCg)
  class BeginNode < Node
    # Initialize a new BeginNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, begin_keyword_loc: ::T.nilable(Location), statements: ::T.nilable(StatementsNode), rescue_clause: ::T.nilable(RescueNode), else_clause: ::T.nilable(ElseNode), ensure_clause: ::T.nilable(EnsureNode), end_keyword_loc: ::T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, begin_keyword_loc, statements, rescue_clause, else_clause, ensure_clause, end_keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, begin_keyword_loc: ::T.nilable(Location), statements: ::T.nilable(StatementsNode), rescue_clause: ::T.nilable(RescueNode), else_clause: ::T.nilable(ElseNode), ensure_clause: ::T.nilable(EnsureNode), end_keyword_loc: ::T.nilable(Location)).returns(BeginNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), begin_keyword_loc: T.unsafe(nil), statements: T.unsafe(nil), rescue_clause: T.unsafe(nil), else_clause: T.unsafe(nil), ensure_clause: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Represents the Location of the `begin` keyword.
    #
    # ```rb
    # begin x end
    # ^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YmVnaW4geCBlbmQK)
    sig { returns(::T.nilable(Location)) }
    def begin_keyword_loc; end

    # Save the begin_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_begin_keyword_loc(repository); end

    # Represents the statements within the begin block.
    #
    # ```rb
    # begin x end
    #       ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YmVnaW4geCBlbmQK)
    sig { returns(::T.nilable(StatementsNode)) }
    def statements; end

    # Represents the rescue clause within the begin block.
    #
    # ```rb
    # begin x; rescue y; end
    #          ^^^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YmVnaW4geDsgcmVzY3VlIHk7IGVuZAo)
    sig { returns(::T.nilable(RescueNode)) }
    def rescue_clause; end

    # Represents the else clause within the begin block.
    #
    # ```rb
    # begin x; rescue y; else z; end
    #                    ^^^^^^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YmVnaW4geDsgcmVzY3VlIHk7IGVsc2UgejsgZW5kCg)
    sig { returns(::T.nilable(ElseNode)) }
    def else_clause; end

    # Represents the ensure clause within the begin block.
    #
    # ```rb
    # begin x; ensure y; end
    #          ^^^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YmVnaW4geDsgZW5zdXJlIHk7IGVuZAo)
    sig { returns(::T.nilable(EnsureNode)) }
    def ensure_clause; end

    # Represents the Location of the `end` keyword.
    #
    # ```rb
    # begin x end
    #         ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YmVnaW4geCBlbmQK)
    sig { returns(::T.nilable(Location)) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_end_keyword_loc(repository); end

    # Slice the location of begin_keyword_loc from the source.
    sig { returns(::T.nilable(String)) }
    def begin_keyword; end

    # Slice the location of end_keyword_loc from the source.
    sig { returns(::T.nilable(String)) }
    def end_keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a block argument using `&`.
  #
  # ```rb
  # bar(&args)
  #     ^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#YmFyKCZhcmdzKQo)
  class BlockArgumentNode < Node
    # Initialize a new BlockArgumentNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, expression: ::T.nilable(Node), operator_loc: Location).void }
    def initialize(source, node_id, location, flags, expression, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, expression: ::T.nilable(Node), operator_loc: Location).returns(BlockArgumentNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), expression: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The expression that is being passed as a block argument. This can be any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # foo(&args)
    #      ^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vKCZhcmdzKQo)
    sig { returns(::T.nilable(Node)) }
    def expression; end

    # Represents the Location of the `&` operator.
    #
    # ```rb
    # foo(&args)
    #     ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vKCZhcmdzKQo)
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a block local variable.
  #
  # ```rb
  # a { |; b| }
  #        ^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#YSB7IHw7IGJ8IH0K)
  class BlockLocalVariableNode < Node
    # Initialize a new BlockLocalVariableNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).void }
    def initialize(source, node_id, location, flags, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(BlockLocalVariableNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # a parameter name that has been repeated in the method signature
    sig { returns(T::Boolean) }
    def repeated_parameter?; end

    # The name of the block local variable.
    #
    # ```rb
    # a { |; b| } # name `:b`
    #        ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YSB7IHw7IGJ8IH0gIyBuYW1lIGA6YmAK)
    sig { returns(Symbol) }
    def name; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a block of ruby code.
  #
  # ```rb
  # [1, 2, 3].each { |i| puts x }
  #                ^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#WzEsIDIsIDNdLmVhY2ggeyB8aXwgcHV0cyB4IH0K)
  class BlockNode < Node
    # Initialize a new BlockNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], parameters: ::T.nilable(::T.any(BlockParametersNode, NumberedParametersNode, ItParametersNode)), body: ::T.nilable(::T.any(StatementsNode, BeginNode)), opening_loc: Location, closing_loc: Location).void }
    def initialize(source, node_id, location, flags, locals, parameters, body, opening_loc, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], parameters: ::T.nilable(::T.any(BlockParametersNode, NumberedParametersNode, ItParametersNode)), body: ::T.nilable(::T.any(StatementsNode, BeginNode)), opening_loc: Location, closing_loc: Location).returns(BlockNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), locals: T.unsafe(nil), parameters: T.unsafe(nil), body: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The local variables declared in the block.
    #
    # ```rb
    # [1, 2, 3].each { |i| puts x } # locals: [:i]
    #                   ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#WzEsIDIsIDNdLmVhY2ggeyB8aXwgcHV0cyB4IH0gIyBsb2NhbHM6IFs6aV0K)
    sig { returns(T::Array[Symbol]) }
    def locals; end

    # The parameters of the block.
    #
    # ```rb
    # [1, 2, 3].each { |i| puts x }
    #                  ^^^
    # [1, 2, 3].each { puts _1 }
    #                ^^^^^^^^^^^
    # [1, 2, 3].each { puts it }
    #                ^^^^^^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#WzEsIDIsIDNdLmVhY2ggeyB8aXwgcHV0cyB4IH0KClsxLCAyLCAzXS5lYWNoIHsgcHV0cyBfMSB9CgpbMSwgMiwgM10uZWFjaCB7IHB1dHMgaXQgfQo)
    sig { returns(::T.nilable(::T.any(BlockParametersNode, NumberedParametersNode, ItParametersNode))) }
    def parameters; end

    # The body of the block.
    #
    # ```rb
    # [1, 2, 3].each { |i| puts x }
    #                      ^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#WzEsIDIsIDNdLmVhY2ggeyB8aXwgcHV0cyB4IH0K)
    sig { returns(::T.nilable(::T.any(StatementsNode, BeginNode))) }
    def body; end

    # Represents the Location of the opening `{` or `do`.
    #
    # ```rb
    # [1, 2, 3].each { |i| puts x }
    #                ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#WzEsIDIsIDNdLmVhY2ggeyB8aXwgcHV0cyB4IH0K)
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Represents the Location of the closing `}` or `end`.
    #
    # ```rb
    # [1, 2, 3].each { |i| puts x }
    #                             ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#WzEsIDIsIDNdLmVhY2ggeyB8aXwgcHV0cyB4IH0K)
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a block parameter of a method, block, or lambda definition.
  #
  # ```rb
  # def a(&b)
  #       ^^
  # end
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#ZGVmIGEoJmIpCgplbmQK)
  class BlockParameterNode < Node
    # Initialize a new BlockParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: ::T.nilable(Symbol), name_loc: ::T.nilable(Location), operator_loc: Location).void }
    def initialize(source, node_id, location, flags, name, name_loc, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: ::T.nilable(Symbol), name_loc: ::T.nilable(Location), operator_loc: Location).returns(BlockParameterNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # a parameter name that has been repeated in the method signature
    sig { returns(T::Boolean) }
    def repeated_parameter?; end

    # The name of the block parameter.
    #
    # ```rb
    # def a(&b) # name `:b`
    #        ^
    # end
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#ZGVmIGEoJmIpICMgbmFtZSBgOmJgCgplbmQK)
    sig { returns(::T.nilable(Symbol)) }
    def name; end

    # Represents the Location of the block parameter name.
    #
    # ```rb
    # def a(&b)
    #        ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#ZGVmIGEoJmIpCg)
    sig { returns(::T.nilable(Location)) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_name_loc(repository); end

    # Represents the Location of the `&` operator.
    #
    # ```rb
    # def a(&b)
    #       ^
    # end
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#ZGVmIGEoJmIpCgplbmQK)
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a block's parameters declaration.
  #
  # ```rb
  # -> (a, b = 1; local) { }
  #    ^^^^^^^^^^^^^^^^^
  #
  # foo do |a, b = 1; local|
  #        ^^^^^^^^^^^^^^^^^
  # end
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#LT4gKGEsIGIgPSAxOyBsb2NhbCkgeyB9Cgpmb28gZG8gfGEsIGIgPSAxOyBsb2NhbHwKCmVuZAo)
  class BlockParametersNode < Node
    # Initialize a new BlockParametersNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, parameters: ::T.nilable(ParametersNode), locals: T::Array[BlockLocalVariableNode], opening_loc: ::T.nilable(Location), closing_loc: ::T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, parameters, locals, opening_loc, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, parameters: ::T.nilable(ParametersNode), locals: T::Array[BlockLocalVariableNode], opening_loc: ::T.nilable(Location), closing_loc: ::T.nilable(Location)).returns(BlockParametersNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), parameters: T.unsafe(nil), locals: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Represents the parameters of the block.
    #
    # ```rb
    # -> (a, b = 1; local) { }
    #     ^^^^^^^^
    #
    # foo do |a, b = 1; local|
    #         ^^^^^^^^
    # end
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#LT4gKGEsIGIgPSAxOyBsb2NhbCkgeyB9Cgpmb28gZG8gfGEsIGIgPSAxOyBsb2NhbHwKCmVuZAo)
    sig { returns(::T.nilable(ParametersNode)) }
    def parameters; end

    # Represents the local variables of the block.
    #
    # ```rb
    # -> (a, b = 1; local) { }
    #               ^^^^^
    #
    # foo do |a, b = 1; local|
    #                   ^^^^^
    # end
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#LT4gKGEsIGIgPSAxOyBsb2NhbCkgeyB9Cgpmb28gZG8gfGEsIGIgPSAxOyBsb2NhbHwKCmVuZAo)
    sig { returns(T::Array[BlockLocalVariableNode]) }
    def locals; end

    # Represents the opening Location of the block parameters.
    #
    # ```rb
    # -> (a, b = 1; local) { }
    #    ^
    #
    # foo do |a, b = 1; local|
    #        ^
    # end
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#LT4gKGEsIGIgPSAxOyBsb2NhbCkgeyB9Cgpmb28gZG8gfGEsIGIgPSAxOyBsb2NhbHwKCmVuZAo)
    sig { returns(::T.nilable(Location)) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_opening_loc(repository); end

    # Represents the closing Location of the block parameters.
    #
    # ```rb
    # -> (a, b = 1; local) { }
    #                    ^
    #
    # foo do |a, b = 1; local|
    #                        ^
    # end
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#LT4gKGEsIGIgPSAxOyBsb2NhbCkgeyB9Cgpmb28gZG8gfGEsIGIgPSAxOyBsb2NhbHwKCmVuZAo)
    sig { returns(::T.nilable(Location)) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(::T.nilable(String)) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(::T.nilable(String)) }
    def closing; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `break` keyword.
  #
  # ```rb
  # break foo
  # ^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#YnJlYWsgZm9vCg)
  class BreakNode < Node
    # Initialize a new BreakNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, arguments: ::T.nilable(ArgumentsNode), keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, arguments, keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, arguments: ::T.nilable(ArgumentsNode), keyword_loc: Location).returns(BreakNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), arguments: T.unsafe(nil), keyword_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The arguments to the break statement, if present. These can be any [non-void expressions](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # break foo
    #       ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YnJlYWsgZm9vCg)
    sig { returns(::T.nilable(ArgumentsNode)) }
    def arguments; end

    # The Location of the `break` keyword.
    #
    # ```rb
    # break foo
    # ^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YnJlYWsgZm9vCg)
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `&&=` operator on a call.
  #
  # ```rb
  # foo.bar &&= value
  # ^^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciAmJj0gdmFsdWUK)
  class CallAndWriteNode < Node
    # Initialize a new CallAndWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: ::T.nilable(Node), call_operator_loc: ::T.nilable(Location), message_loc: ::T.nilable(Location), read_name: Symbol, write_name: Symbol, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, receiver, call_operator_loc, message_loc, read_name, write_name, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, receiver: ::T.nilable(Node), call_operator_loc: ::T.nilable(Location), message_loc: ::T.nilable(Location), read_name: Symbol, write_name: Symbol, operator_loc: Location, value: Node).returns(CallAndWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), call_operator_loc: T.unsafe(nil), message_loc: T.unsafe(nil), read_name: T.unsafe(nil), write_name: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # &. operator
    sig { returns(T::Boolean) }
    def safe_navigation?; end

    # a call that could have been a local variable
    sig { returns(T::Boolean) }
    def variable_call?; end

    # a call that is an attribute write, so the value being written should be returned
    sig { returns(T::Boolean) }
    def attribute_write?; end

    # a call that ignores method visibility
    sig { returns(T::Boolean) }
    def ignore_visibility?; end

    # The object that the method is being called on. This can be either `nil` or any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # foo.bar &&= value
    # ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciAmJj0gdmFsdWUK)
    sig { returns(::T.nilable(Node)) }
    def receiver; end

    # Represents the Location of the call operator.
    #
    # ```rb
    # foo.bar &&= value
    #    ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciAmJj0gdmFsdWUK)
    sig { returns(::T.nilable(Location)) }
    def call_operator_loc; end

    # Save the call_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_call_operator_loc(repository); end

    # Represents the Location of the message.
    #
    # ```rb
    # foo.bar &&= value
    #     ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciAmJj0gdmFsdWUK)
    sig { returns(::T.nilable(Location)) }
    def message_loc; end

    # Save the message_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_message_loc(repository); end

    # Represents the name of the method being called.
    #
    # ```rb
    # foo.bar &&= value # read_name `:bar`
    #     ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciAmJj0gdmFsdWUgIyByZWFkX25hbWUgYDpiYXJgCg)
    sig { returns(Symbol) }
    def read_name; end

    # Represents the name of the method being written to.
    #
    # ```rb
    # foo.bar &&= value # write_name `:bar=`
    #     ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciAmJj0gdmFsdWUgIyB3cml0ZV9uYW1lIGA6YmFyPWAK)
    sig { returns(Symbol) }
    def write_name; end

    # Represents the Location of the operator.
    #
    # ```rb
    # foo.bar &&= value
    #         ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciAmJj0gdmFsdWUK)
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Represents the value being assigned.
    #
    # ```rb
    # foo.bar &&= value
    #             ^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciAmJj0gdmFsdWUK)
    sig { returns(Node) }
    def value; end

    # Slice the location of call_operator_loc from the source.
    sig { returns(::T.nilable(String)) }
    def call_operator; end

    # Slice the location of message_loc from the source.
    sig { returns(::T.nilable(String)) }
    def message; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a method call, in all of the various forms that can take.
  #
  # ```rb
  # foo
  # ^^^
  #
  # foo()
  # ^^^^^
  #
  # +foo
  # ^^^^
  #
  # foo + bar
  # ^^^^^^^^^
  #
  # foo.bar
  # ^^^^^^^
  #
  # foo&.bar
  # ^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vCgpmb28oKQoKK2ZvbwoKZm9vICsgYmFyCgpmb28uYmFyCgpmb28mLmJhcgo)
  class CallNode < Node
    # Initialize a new CallNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: ::T.nilable(Node), call_operator_loc: ::T.nilable(Location), name: Symbol, message_loc: ::T.nilable(Location), opening_loc: ::T.nilable(Location), arguments: ::T.nilable(ArgumentsNode), closing_loc: ::T.nilable(Location), equal_loc: ::T.nilable(Location), block: ::T.nilable(::T.any(BlockNode, BlockArgumentNode))).void }
    def initialize(source, node_id, location, flags, receiver, call_operator_loc, name, message_loc, opening_loc, arguments, closing_loc, equal_loc, block); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, receiver: ::T.nilable(Node), call_operator_loc: ::T.nilable(Location), name: Symbol, message_loc: ::T.nilable(Location), opening_loc: ::T.nilable(Location), arguments: ::T.nilable(ArgumentsNode), closing_loc: ::T.nilable(Location), equal_loc: ::T.nilable(Location), block: ::T.nilable(::T.any(BlockNode, BlockArgumentNode))).returns(CallNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), call_operator_loc: T.unsafe(nil), name: T.unsafe(nil), message_loc: T.unsafe(nil), opening_loc: T.unsafe(nil), arguments: T.unsafe(nil), closing_loc: T.unsafe(nil), equal_loc: T.unsafe(nil), block: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # &. operator
    sig { returns(T::Boolean) }
    def safe_navigation?; end

    # a call that could have been a local variable
    sig { returns(T::Boolean) }
    def variable_call?; end

    # a call that is an attribute write, so the value being written should be returned
    sig { returns(T::Boolean) }
    def attribute_write?; end

    # a call that ignores method visibility
    sig { returns(T::Boolean) }
    def ignore_visibility?; end

    # The object that the method is being called on. This can be either `nil` or any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # foo.bar
    # ^^^
    #
    # +foo
    #  ^^^
    #
    # foo + bar
    # ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhcgoKK2ZvbwoKZm9vICsgYmFyCg)
    sig { returns(::T.nilable(Node)) }
    def receiver; end

    # Represents the Location of the call operator.
    #
    # ```rb
    # foo.bar
    #    ^
    #
    # foo&.bar
    #    ^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhcgoKZm9vJi5iYXIK)
    sig { returns(::T.nilable(Location)) }
    def call_operator_loc; end

    # Save the call_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_call_operator_loc(repository); end

    # Represents the name of the method being called.
    #
    # ```rb
    # foo.bar # name `:foo`
    # ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciAjIG5hbWUgYDpmb29gCg)
    sig { returns(Symbol) }
    def name; end

    # Represents the Location of the message.
    #
    # ```rb
    # foo.bar
    #     ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhcgo)
    sig { returns(::T.nilable(Location)) }
    def message_loc; end

    # Save the message_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_message_loc(repository); end

    # Represents the Location of the left parenthesis.
    #
    # ```rb
    # foo(bar)
    #    ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vKGJhcikK)
    sig { returns(::T.nilable(Location)) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_opening_loc(repository); end

    # Represents the arguments to the method call. These can be any [non-void expressions](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # foo(bar)
    #     ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vKGJhcikK)
    sig { returns(::T.nilable(ArgumentsNode)) }
    def arguments; end

    # Represents the Location of the right parenthesis.
    #
    # ```rb
    # foo(bar)
    #        ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vKGJhcikK)
    sig { returns(::T.nilable(Location)) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_closing_loc(repository); end

    # Represents the Location of the equal sign, in the case that this is an attribute write.
    #
    # ```rb
    # foo.bar = value
    #         ^
    #
    # foo[bar] = value
    #          ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciA9IHZhbHVlCgpmb29bYmFyXSA9IHZhbHVlCg)
    sig { returns(::T.nilable(Location)) }
    def equal_loc; end

    # Save the equal_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_equal_loc(repository); end

    # Represents the block that is being passed to the method.
    #
    # ```rb
    # foo { |a| a }
    #     ^^^^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIHsgfGF8IGEgfQo)
    sig { returns(::T.nilable(::T.any(BlockNode, BlockArgumentNode))) }
    def block; end

    # Slice the location of call_operator_loc from the source.
    sig { returns(::T.nilable(String)) }
    def call_operator; end

    # Slice the location of message_loc from the source.
    sig { returns(::T.nilable(String)) }
    def message; end

    # Slice the location of opening_loc from the source.
    sig { returns(::T.nilable(String)) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(::T.nilable(String)) }
    def closing; end

    # Slice the location of equal_loc from the source.
    sig { returns(::T.nilable(String)) }
    def equal; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of an assignment operator on a call.
  #
  # ```rb
  # foo.bar += baz
  # ^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciArPSBiYXoK)
  class CallOperatorWriteNode < Node
    # Initialize a new CallOperatorWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: ::T.nilable(Node), call_operator_loc: ::T.nilable(Location), message_loc: ::T.nilable(Location), read_name: Symbol, write_name: Symbol, binary_operator: Symbol, binary_operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, receiver, call_operator_loc, message_loc, read_name, write_name, binary_operator, binary_operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, receiver: ::T.nilable(Node), call_operator_loc: ::T.nilable(Location), message_loc: ::T.nilable(Location), read_name: Symbol, write_name: Symbol, binary_operator: Symbol, binary_operator_loc: Location, value: Node).returns(CallOperatorWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), call_operator_loc: T.unsafe(nil), message_loc: T.unsafe(nil), read_name: T.unsafe(nil), write_name: T.unsafe(nil), binary_operator: T.unsafe(nil), binary_operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # &. operator
    sig { returns(T::Boolean) }
    def safe_navigation?; end

    # a call that could have been a local variable
    sig { returns(T::Boolean) }
    def variable_call?; end

    # a call that is an attribute write, so the value being written should be returned
    sig { returns(T::Boolean) }
    def attribute_write?; end

    # a call that ignores method visibility
    sig { returns(T::Boolean) }
    def ignore_visibility?; end

    # The object that the method is being called on. This can be either `nil` or any [non-void expressions](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # foo.bar += value
    # ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciArPSB2YWx1ZQo)
    sig { returns(::T.nilable(Node)) }
    def receiver; end

    # Represents the Location of the call operator.
    #
    # ```rb
    # foo.bar += value
    #    ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciArPSB2YWx1ZQo)
    sig { returns(::T.nilable(Location)) }
    def call_operator_loc; end

    # Save the call_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_call_operator_loc(repository); end

    # Represents the Location of the message.
    #
    # ```rb
    # foo.bar += value
    #     ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciArPSB2YWx1ZQo)
    sig { returns(::T.nilable(Location)) }
    def message_loc; end

    # Save the message_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_message_loc(repository); end

    # Represents the name of the method being called.
    #
    # ```rb
    # foo.bar += value # read_name `:bar`
    #     ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciArPSB2YWx1ZSAjIHJlYWRfbmFtZSBgOmJhcmAK)
    sig { returns(Symbol) }
    def read_name; end

    # Represents the name of the method being written to.
    #
    # ```rb
    # foo.bar += value # write_name `:bar=`
    #     ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciArPSB2YWx1ZSAjIHdyaXRlX25hbWUgYDpiYXI9YAo)
    sig { returns(Symbol) }
    def write_name; end

    # Represents the binary operator being used.
    #
    # ```rb
    # foo.bar += value # binary_operator `:+`
    #         ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciArPSB2YWx1ZSAjIGJpbmFyeV9vcGVyYXRvciBgOitgCg)
    sig { returns(Symbol) }
    def binary_operator; end

    # Represents the Location of the binary operator.
    #
    # ```rb
    # foo.bar += value
    #         ^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciArPSB2YWx1ZQo)
    sig { returns(Location) }
    def binary_operator_loc; end

    # Save the binary_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_binary_operator_loc(repository); end

    # Represents the value being assigned.
    #
    # ```rb
    # foo.bar += value
    #            ^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciArPSB2YWx1ZQo)
    sig { returns(Node) }
    def value; end

    # Slice the location of call_operator_loc from the source.
    sig { returns(::T.nilable(String)) }
    def call_operator; end

    # Slice the location of message_loc from the source.
    sig { returns(::T.nilable(String)) }
    def message; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `||=` operator on a call.
  #
  # ```rb
  # foo.bar ||= value
  # ^^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciB8fD0gdmFsdWUK)
  class CallOrWriteNode < Node
    # Initialize a new CallOrWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: ::T.nilable(Node), call_operator_loc: ::T.nilable(Location), message_loc: ::T.nilable(Location), read_name: Symbol, write_name: Symbol, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, receiver, call_operator_loc, message_loc, read_name, write_name, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, receiver: ::T.nilable(Node), call_operator_loc: ::T.nilable(Location), message_loc: ::T.nilable(Location), read_name: Symbol, write_name: Symbol, operator_loc: Location, value: Node).returns(CallOrWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), call_operator_loc: T.unsafe(nil), message_loc: T.unsafe(nil), read_name: T.unsafe(nil), write_name: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # &. operator
    sig { returns(T::Boolean) }
    def safe_navigation?; end

    # a call that could have been a local variable
    sig { returns(T::Boolean) }
    def variable_call?; end

    # a call that is an attribute write, so the value being written should be returned
    sig { returns(T::Boolean) }
    def attribute_write?; end

    # a call that ignores method visibility
    sig { returns(T::Boolean) }
    def ignore_visibility?; end

    # The object that the method is being called on. This can be either `nil` or any [non-void expressions](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # foo.bar ||= value
    # ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciB8fD0gdmFsdWUK)
    sig { returns(::T.nilable(Node)) }
    def receiver; end

    # Represents the Location of the call operator.
    #
    # ```rb
    # foo.bar ||= value
    #    ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciB8fD0gdmFsdWUK)
    sig { returns(::T.nilable(Location)) }
    def call_operator_loc; end

    # Save the call_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_call_operator_loc(repository); end

    # Represents the Location of the message.
    #
    # ```rb
    # foo.bar ||= value
    #     ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciB8fD0gdmFsdWUK)
    sig { returns(::T.nilable(Location)) }
    def message_loc; end

    # Save the message_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_message_loc(repository); end

    # Represents the name of the method being called.
    #
    # ```rb
    # foo.bar ||= value # read_name `:bar`
    #     ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciB8fD0gdmFsdWUgIyByZWFkX25hbWUgYDpiYXJgCg)
    sig { returns(Symbol) }
    def read_name; end

    # Represents the name of the method being written to.
    #
    # ```rb
    # foo.bar ||= value # write_name `:bar=`
    #     ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciB8fD0gdmFsdWUgIyB3cml0ZV9uYW1lIGA6YmFyPWAK)
    sig { returns(Symbol) }
    def write_name; end

    # Represents the Location of the operator.
    #
    # ```rb
    # foo.bar ||= value
    #         ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciB8fD0gdmFsdWUK)
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Represents the value being assigned.
    #
    # ```rb
    # foo.bar ||= value
    #             ^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciB8fD0gdmFsdWUK)
    sig { returns(Node) }
    def value; end

    # Slice the location of call_operator_loc from the source.
    sig { returns(::T.nilable(String)) }
    def call_operator; end

    # Slice the location of message_loc from the source.
    sig { returns(::T.nilable(String)) }
    def message; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents assigning to a method call.
  #
  # ```rb
  # foo.bar, = 1
  # ^^^^^^^
  #
  # begin
  # rescue => foo.bar
  #           ^^^^^^^
  # end
  #
  # for foo.bar in baz do end
  #     ^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciwgPSAxCgpiZWdpbgpyZXNjdWUgPT4gZm9vLmJhcgoKZW5kCgpmb3IgZm9vLmJhciBpbiBiYXogZG8gZW5kCg)
  class CallTargetNode < Node
    # Initialize a new CallTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: Node, call_operator_loc: Location, name: Symbol, message_loc: Location).void }
    def initialize(source, node_id, location, flags, receiver, call_operator_loc, name, message_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, receiver: Node, call_operator_loc: Location, name: Symbol, message_loc: Location).returns(CallTargetNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), call_operator_loc: T.unsafe(nil), name: T.unsafe(nil), message_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # &. operator
    sig { returns(T::Boolean) }
    def safe_navigation?; end

    # a call that could have been a local variable
    sig { returns(T::Boolean) }
    def variable_call?; end

    # a call that is an attribute write, so the value being written should be returned
    sig { returns(T::Boolean) }
    def attribute_write?; end

    # a call that ignores method visibility
    sig { returns(T::Boolean) }
    def ignore_visibility?; end

    # The object that the method is being called on. This can be any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # foo.bar = 1
    # ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciA9IDEK)
    sig { returns(Node) }
    def receiver; end

    # Represents the Location of the call operator.
    #
    # ```rb
    # foo.bar = 1
    #    ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciA9IDEK)
    sig { returns(Location) }
    def call_operator_loc; end

    # Save the call_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_call_operator_loc(repository); end

    # Represents the name of the method being called.
    #
    # ```rb
    # foo.bar = 1 # name `:foo`
    # ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciA9IDEgIyBuYW1lIGA6Zm9vYAo)
    sig { returns(Symbol) }
    def name; end

    # Represents the Location of the message.
    #
    # ```rb
    # foo.bar = 1
    #     ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhciA9IDEK)
    sig { returns(Location) }
    def message_loc; end

    # Save the message_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_message_loc(repository); end

    # Slice the location of call_operator_loc from the source.
    sig { returns(String) }
    def call_operator; end

    # Slice the location of message_loc from the source.
    sig { returns(String) }
    def message; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents assigning to a local variable in pattern matching.
  #
  # ```rb
  # foo => [bar => baz]
  #         ^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0-IFtiYXIgPT4gYmF6XQo)
  class CapturePatternNode < Node
    # Initialize a new CapturePatternNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, value: Node, target: LocalVariableTargetNode, operator_loc: Location).void }
    def initialize(source, node_id, location, flags, value, target, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, value: Node, target: LocalVariableTargetNode, operator_loc: Location).returns(CapturePatternNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), value: T.unsafe(nil), target: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Represents the value to capture.
    #
    # ```rb
    # foo => bar
    #        ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0-IGJhcgo)
    sig { returns(Node) }
    def value; end

    # Represents the target of the capture.
    #
    # ```rb
    # foo => bar
    # ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0-IGJhcgo)
    sig { returns(LocalVariableTargetNode) }
    def target; end

    # Represents the Location of the `=>` operator.
    #
    # ```rb
    # foo => bar
    #     ^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0-IGJhcgo)
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of a case statement for pattern matching.
  #
  # ```rb
  # case true
  # in false
  # end
  # ^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Y2FzZSB0cnVlCmluIGZhbHNlCmVuZAo)
  class CaseMatchNode < Node
    # Initialize a new CaseMatchNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, predicate: ::T.nilable(Node), conditions: T::Array[InNode], else_clause: ::T.nilable(ElseNode), case_keyword_loc: Location, end_keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, predicate, conditions, else_clause, case_keyword_loc, end_keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, predicate: ::T.nilable(Node), conditions: T::Array[InNode], else_clause: ::T.nilable(ElseNode), case_keyword_loc: Location, end_keyword_loc: Location).returns(CaseMatchNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), predicate: T.unsafe(nil), conditions: T.unsafe(nil), else_clause: T.unsafe(nil), case_keyword_loc: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Represents the predicate of the case match. This can be either `nil` or any [non-void expressions](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # case true; in false; end
    #      ^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Y2FzZSB0cnVlOyBpbiBmYWxzZTsgZW5kCg)
    sig { returns(::T.nilable(Node)) }
    def predicate; end

    # Represents the conditions of the case match.
    #
    # ```rb
    # case true; in false; end
    #            ^^^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Y2FzZSB0cnVlOyBpbiBmYWxzZTsgZW5kCg)
    sig { returns(T::Array[InNode]) }
    def conditions; end

    # Represents the else clause of the case match.
    #
    # ```rb
    # case true; in false; else; end
    #                      ^^^^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Y2FzZSB0cnVlOyBpbiBmYWxzZTsgZWxzZTsgZW5kCg)
    sig { returns(::T.nilable(ElseNode)) }
    def else_clause; end

    # Represents the Location of the `case` keyword.
    #
    # ```rb
    # case true; in false; end
    # ^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Y2FzZSB0cnVlOyBpbiBmYWxzZTsgZW5kCg)
    sig { returns(Location) }
    def case_keyword_loc; end

    # Save the case_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_case_keyword_loc(repository); end

    # Represents the Location of the `end` keyword.
    #
    # ```rb
    # case true; in false; end
    #                      ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Y2FzZSB0cnVlOyBpbiBmYWxzZTsgZW5kCg)
    sig { returns(Location) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_end_keyword_loc(repository); end

    # Slice the location of case_keyword_loc from the source.
    sig { returns(String) }
    def case_keyword; end

    # Slice the location of end_keyword_loc from the source.
    sig { returns(String) }
    def end_keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of a case statement.
  #
  # ```rb
  # case true
  # when false
  # end
  # ^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Y2FzZSB0cnVlCndoZW4gZmFsc2UKZW5kCg)
  class CaseNode < Node
    # Initialize a new CaseNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, predicate: ::T.nilable(Node), conditions: T::Array[WhenNode], else_clause: ::T.nilable(ElseNode), case_keyword_loc: Location, end_keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, predicate, conditions, else_clause, case_keyword_loc, end_keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, predicate: ::T.nilable(Node), conditions: T::Array[WhenNode], else_clause: ::T.nilable(ElseNode), case_keyword_loc: Location, end_keyword_loc: Location).returns(CaseNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), predicate: T.unsafe(nil), conditions: T.unsafe(nil), else_clause: T.unsafe(nil), case_keyword_loc: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Represents the predicate of the case statement. This can be either `nil` or any [non-void expressions](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # case true; when false; end
    #      ^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Y2FzZSB0cnVlOyB3aGVuIGZhbHNlOyBlbmQK)
    sig { returns(::T.nilable(Node)) }
    def predicate; end

    # Represents the conditions of the case statement.
    #
    # ```rb
    # case true; when false; end
    #            ^^^^^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Y2FzZSB0cnVlOyB3aGVuIGZhbHNlOyBlbmQK)
    sig { returns(T::Array[WhenNode]) }
    def conditions; end

    # Represents the else clause of the case statement.
    #
    # ```rb
    # case true; when false; else; end
    #                        ^^^^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Y2FzZSB0cnVlOyB3aGVuIGZhbHNlOyBlbHNlOyBlbmQK)
    sig { returns(::T.nilable(ElseNode)) }
    def else_clause; end

    # Represents the Location of the `case` keyword.
    #
    # ```rb
    # case true; when false; end
    # ^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Y2FzZSB0cnVlOyB3aGVuIGZhbHNlOyBlbmQK)
    sig { returns(Location) }
    def case_keyword_loc; end

    # Save the case_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_case_keyword_loc(repository); end

    # Represents the Location of the `end` keyword.
    #
    # ```rb
    # case true; when false; end
    #                        ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Y2FzZSB0cnVlOyB3aGVuIGZhbHNlOyBlbmQK)
    sig { returns(Location) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_end_keyword_loc(repository); end

    # Slice the location of case_keyword_loc from the source.
    sig { returns(String) }
    def case_keyword; end

    # Slice the location of end_keyword_loc from the source.
    sig { returns(String) }
    def end_keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a class declaration involving the `class` keyword.
  #
  # ```rb
  # class Foo end
  # ^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Y2xhc3MgRm9vIGVuZAo)
  class ClassNode < Node
    # Initialize a new ClassNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], class_keyword_loc: Location, constant_path: ::T.any(ConstantReadNode, ConstantPathNode), inheritance_operator_loc: ::T.nilable(Location), superclass: ::T.nilable(Node), body: ::T.nilable(::T.any(StatementsNode, BeginNode)), end_keyword_loc: Location, name: Symbol).void }
    def initialize(source, node_id, location, flags, locals, class_keyword_loc, constant_path, inheritance_operator_loc, superclass, body, end_keyword_loc, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], class_keyword_loc: Location, constant_path: ::T.any(ConstantReadNode, ConstantPathNode), inheritance_operator_loc: ::T.nilable(Location), superclass: ::T.nilable(Node), body: ::T.nilable(::T.any(StatementsNode, BeginNode)), end_keyword_loc: Location, name: Symbol).returns(ClassNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), locals: T.unsafe(nil), class_keyword_loc: T.unsafe(nil), constant_path: T.unsafe(nil), inheritance_operator_loc: T.unsafe(nil), superclass: T.unsafe(nil), body: T.unsafe(nil), end_keyword_loc: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `locals` attribute.
    sig { returns(T::Array[Symbol]) }
    def locals; end

    # Represents the Location of the `class` keyword.
    #
    # ```rb
    # class Foo end
    # ^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Y2xhc3MgRm9vIGVuZAo)
    sig { returns(Location) }
    def class_keyword_loc; end

    # Save the class_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_class_keyword_loc(repository); end

    # Returns the `constant_path` attribute.
    sig { returns(::T.any(ConstantReadNode, ConstantPathNode)) }
    def constant_path; end

    # Represents the Location of the `<` operator.
    #
    # ```rb
    # class Foo < Bar
    #           ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Y2xhc3MgRm9vIDwgQmFyCg)
    sig { returns(::T.nilable(Location)) }
    def inheritance_operator_loc; end

    # Save the inheritance_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_inheritance_operator_loc(repository); end

    # Represents the superclass of the class.
    #
    # ```rb
    # class Foo < Bar
    #             ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Y2xhc3MgRm9vIDwgQmFyCg)
    sig { returns(::T.nilable(Node)) }
    def superclass; end

    # Represents the body of the class.
    #
    # ```rb
    # class Foo; bar; end
    #            ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Y2xhc3MgRm9vOyBiYXI7IGVuZAo)
    sig { returns(::T.nilable(::T.any(StatementsNode, BeginNode))) }
    def body; end

    # Represents the Location of the `end` keyword.
    #
    # ```rb
    # class Foo end
    #           ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Y2xhc3MgRm9vIGVuZAo)
    sig { returns(Location) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_end_keyword_loc(repository); end

    # The name of the class.
    #
    # ```rb
    # class Foo end # name `:Foo`
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Y2xhc3MgRm9vIGVuZCAjIG5hbWUgYDpGb29gCg)
    sig { returns(Symbol) }
    def name; end

    # Slice the location of class_keyword_loc from the source.
    sig { returns(String) }
    def class_keyword; end

    # Slice the location of inheritance_operator_loc from the source.
    sig { returns(::T.nilable(String)) }
    def inheritance_operator; end

    # Slice the location of end_keyword_loc from the source.
    sig { returns(String) }
    def end_keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `&&=` operator for assignment to a class variable.
  #
  # ```rb
  # @@target &&= value
  # ^^^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#QEB0YXJnZXQgJiY9IHZhbHVlCg)
  class ClassVariableAndWriteNode < Node
    # Initialize a new ClassVariableAndWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, name, name_loc, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(ClassVariableAndWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The name of the class variable, which is a `@@` followed by an [identifier](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#identifiers).
    #
    # ```rb
    # @@target &&= value # name `:@@target`
    # ^^^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#QEB0YXJnZXQgJiY9IHZhbHVlICMgbmFtZSBgOkBAdGFyZ2V0YAo)
    sig { returns(Symbol) }
    def name; end

    # Represents the Location of the variable name.
    #
    # ```rb
    # @@target &&= value
    # ^^^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#QEB0YXJnZXQgJiY9IHZhbHVlCg)
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Represents the Location of the `&&=` operator.
    #
    # ```rb
    # @@target &&= value
    #          ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#QEB0YXJnZXQgJiY9IHZhbHVlCg)
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Represents the value being assigned. This can be any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # @@target &&= value
    #              ^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#QEB0YXJnZXQgJiY9IHZhbHVlCg)
    sig { returns(Node) }
    def value; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents assigning to a class variable using an operator that isn't `=`.
  #
  # ```rb
  # @@target += value
  # ^^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#QEB0YXJnZXQgKz0gdmFsdWUK)
  class ClassVariableOperatorWriteNode < Node
    # Initialize a new ClassVariableOperatorWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, binary_operator_loc: Location, value: Node, binary_operator: Symbol).void }
    def initialize(source, node_id, location, flags, name, name_loc, binary_operator_loc, value, binary_operator); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, binary_operator_loc: Location, value: Node, binary_operator: Symbol).returns(ClassVariableOperatorWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), binary_operator_loc: T.unsafe(nil), value: T.unsafe(nil), binary_operator: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `name` attribute.
    sig { returns(Symbol) }
    def name; end

    # Returns the Location represented by `name_loc`.
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `binary_operator_loc`.
    sig { returns(Location) }
    def binary_operator_loc; end

    # Save the binary_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_binary_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Returns the `binary_operator` attribute.
    sig { returns(Symbol) }
    def binary_operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `||=` operator for assignment to a class variable.
  #
  # ```rb
  # @@target ||= value
  # ^^^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#QEB0YXJnZXQgfHw9IHZhbHVlCg)
  class ClassVariableOrWriteNode < Node
    # Initialize a new ClassVariableOrWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, name, name_loc, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(ClassVariableOrWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `name` attribute.
    sig { returns(Symbol) }
    def name; end

    # Returns the Location represented by `name_loc`.
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents referencing a class variable.
  #
  # ```rb
  # @@foo
  # ^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#QEBmb28K)
  class ClassVariableReadNode < Node
    # Initialize a new ClassVariableReadNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).void }
    def initialize(source, node_id, location, flags, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(ClassVariableReadNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The name of the class variable, which is a `@@` followed by an [identifier](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#identifiers).
    #
    # ```rb
    # @@abc   # name `:@@abc`
    #
    # @@_test # name `:@@_test`
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#QEBhYmMgICAjIG5hbWUgYDpAQGFiY2AKCkBAX3Rlc3QgIyBuYW1lIGA6QEBfdGVzdGAK)
    sig { returns(Symbol) }
    def name; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing to a class variable in a context that doesn't have an explicit value.
  #
  # ```rb
  # @@foo, @@bar = baz
  # ^^^^^  ^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#QEBmb28sIEBAYmFyID0gYmF6Cg)
  class ClassVariableTargetNode < Node
    # Initialize a new ClassVariableTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).void }
    def initialize(source, node_id, location, flags, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(ClassVariableTargetNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `name` attribute.
    sig { returns(Symbol) }
    def name; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing to a class variable.
  #
  # ```rb
  # @@foo = 1
  # ^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#QEBmb28gPSAxCg)
  class ClassVariableWriteNode < Node
    # Initialize a new ClassVariableWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, value: Node, operator_loc: Location).void }
    def initialize(source, node_id, location, flags, name, name_loc, value, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, value: Node, operator_loc: Location).returns(ClassVariableWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), value: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The name of the class variable, which is a `@@` followed by an [identifier](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#identifiers).
    #
    # ```rb
    # @@abc = 123     # name `@@abc`
    #
    # @@_test = :test # name `@@_test`
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#QEBhYmMgPSAxMjMgICAgICMgbmFtZSBgQEBhYmNgCgpAQF90ZXN0ID0gOnRlc3QgIyBuYW1lIGBAQF90ZXN0YAo)
    sig { returns(Symbol) }
    def name; end

    # The Location of the variable name.
    #
    # ```rb
    # @@foo = :bar
    # ^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#QEBmb28gPSA6YmFyCg)
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # The value to write to the class variable. This can be any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # @@foo = :bar
    #         ^^^^
    #
    # @@_xyz = 123
    #          ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#QEBmb28gPSA6YmFyCgpAQF94eXogPSAxMjMK)
    sig { returns(Node) }
    def value; end

    # The Location of the `=` operator.
    #
    # ```rb
    # @@foo = :bar
    #       ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#QEBmb28gPSA6YmFyCg)
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `&&=` operator for assignment to a constant.
  #
  # ```rb
  # Target &&= value
  # ^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#VGFyZ2V0ICYmPSB2YWx1ZQo)
  class ConstantAndWriteNode < Node
    # Initialize a new ConstantAndWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, name, name_loc, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(ConstantAndWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `name` attribute.
    sig { returns(Symbol) }
    def name; end

    # Returns the Location represented by `name_loc`.
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents assigning to a constant using an operator that isn't `=`.
  #
  # ```rb
  # Target += value
  # ^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#VGFyZ2V0ICs9IHZhbHVlCg)
  class ConstantOperatorWriteNode < Node
    # Initialize a new ConstantOperatorWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, binary_operator_loc: Location, value: Node, binary_operator: Symbol).void }
    def initialize(source, node_id, location, flags, name, name_loc, binary_operator_loc, value, binary_operator); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, binary_operator_loc: Location, value: Node, binary_operator: Symbol).returns(ConstantOperatorWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), binary_operator_loc: T.unsafe(nil), value: T.unsafe(nil), binary_operator: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `name` attribute.
    sig { returns(Symbol) }
    def name; end

    # Returns the Location represented by `name_loc`.
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `binary_operator_loc`.
    sig { returns(Location) }
    def binary_operator_loc; end

    # Save the binary_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_binary_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Returns the `binary_operator` attribute.
    sig { returns(Symbol) }
    def binary_operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `||=` operator for assignment to a constant.
  #
  # ```rb
  # Target ||= value
  # ^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#VGFyZ2V0IHx8PSB2YWx1ZQo)
  class ConstantOrWriteNode < Node
    # Initialize a new ConstantOrWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, name, name_loc, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(ConstantOrWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `name` attribute.
    sig { returns(Symbol) }
    def name; end

    # Returns the Location represented by `name_loc`.
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `&&=` operator for assignment to a constant path.
  #
  # ```rb
  # Parent::Child &&= value
  # ^^^^^^^^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#UGFyZW50OjpDaGlsZCAmJj0gdmFsdWUK)
  class ConstantPathAndWriteNode < Node
    # Initialize a new ConstantPathAndWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, target: ConstantPathNode, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, target, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, target: ConstantPathNode, operator_loc: Location, value: Node).returns(ConstantPathAndWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), target: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `target` attribute.
    sig { returns(ConstantPathNode) }
    def target; end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents accessing a constant through a path of `::` operators.
  #
  # ```rb
  # Foo::Bar
  # ^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Rm9vOjpCYXIK)
  class ConstantPathNode < Node
    # Initialize a new ConstantPathNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, parent: ::T.nilable(Node), name: ::T.nilable(Symbol), delimiter_loc: Location, name_loc: Location).void }
    def initialize(source, node_id, location, flags, parent, name, delimiter_loc, name_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, parent: ::T.nilable(Node), name: ::T.nilable(Symbol), delimiter_loc: Location, name_loc: Location).returns(ConstantPathNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), parent: T.unsafe(nil), name: T.unsafe(nil), delimiter_loc: T.unsafe(nil), name_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The left-hand node of the path, if present. It can be `nil` or any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression). It will be `nil` when the constant lookup is at the root of the module tree.
    #
    # ```rb
    # Foo::Bar
    # ^^^
    #
    # self::Test
    # ^^^^
    #
    # a.b::C
    # ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Rm9vOjpCYXIKCnNlbGY6OlRlc3QKCmEuYjo6Qwo)
    sig { returns(::T.nilable(Node)) }
    def parent; end

    # The name of the constant being accessed. This could be `nil` in the event of a syntax error.
    sig { returns(::T.nilable(Symbol)) }
    def name; end

    # The Location of the `::` delimiter.
    #
    # ```rb
    # ^^
    #
    # One::Two
    #    ^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#OjpGb28KCk9uZTo6VHdvCg)
    sig { returns(Location) }
    def delimiter_loc; end

    # Save the delimiter_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_delimiter_loc(repository); end

    # The Location of the name of the constant.
    #
    # ```rb
    #   ^^^
    #
    # One::Two
    #      ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#OjpGb28KCk9uZTo6VHdvCg)
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Slice the location of delimiter_loc from the source.
    sig { returns(String) }
    def delimiter; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents assigning to a constant path using an operator that isn't `=`.
  #
  # ```rb
  # Parent::Child += value
  # ^^^^^^^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#UGFyZW50OjpDaGlsZCArPSB2YWx1ZQo)
  class ConstantPathOperatorWriteNode < Node
    # Initialize a new ConstantPathOperatorWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, target: ConstantPathNode, binary_operator_loc: Location, value: Node, binary_operator: Symbol).void }
    def initialize(source, node_id, location, flags, target, binary_operator_loc, value, binary_operator); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, target: ConstantPathNode, binary_operator_loc: Location, value: Node, binary_operator: Symbol).returns(ConstantPathOperatorWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), target: T.unsafe(nil), binary_operator_loc: T.unsafe(nil), value: T.unsafe(nil), binary_operator: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `target` attribute.
    sig { returns(ConstantPathNode) }
    def target; end

    # Returns the Location represented by `binary_operator_loc`.
    sig { returns(Location) }
    def binary_operator_loc; end

    # Save the binary_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_binary_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Returns the `binary_operator` attribute.
    sig { returns(Symbol) }
    def binary_operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `||=` operator for assignment to a constant path.
  #
  # ```rb
  # Parent::Child ||= value
  # ^^^^^^^^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#UGFyZW50OjpDaGlsZCB8fD0gdmFsdWUK)
  class ConstantPathOrWriteNode < Node
    # Initialize a new ConstantPathOrWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, target: ConstantPathNode, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, target, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, target: ConstantPathNode, operator_loc: Location, value: Node).returns(ConstantPathOrWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), target: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `target` attribute.
    sig { returns(ConstantPathNode) }
    def target; end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing to a constant path in a context that doesn't have an explicit value.
  #
  # ```rb
  # Foo::Foo, Bar::Bar = baz
  # ^^^^^^^^  ^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Rm9vOjpGb28sIEJhcjo6QmFyID0gYmF6Cg)
  class ConstantPathTargetNode < Node
    # Initialize a new ConstantPathTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, parent: ::T.nilable(Node), name: ::T.nilable(Symbol), delimiter_loc: Location, name_loc: Location).void }
    def initialize(source, node_id, location, flags, parent, name, delimiter_loc, name_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, parent: ::T.nilable(Node), name: ::T.nilable(Symbol), delimiter_loc: Location, name_loc: Location).returns(ConstantPathTargetNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), parent: T.unsafe(nil), name: T.unsafe(nil), delimiter_loc: T.unsafe(nil), name_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `parent` attribute.
    sig { returns(::T.nilable(Node)) }
    def parent; end

    # Returns the `name` attribute.
    sig { returns(::T.nilable(Symbol)) }
    def name; end

    # Returns the Location represented by `delimiter_loc`.
    sig { returns(Location) }
    def delimiter_loc; end

    # Save the delimiter_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_delimiter_loc(repository); end

    # Returns the Location represented by `name_loc`.
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Slice the location of delimiter_loc from the source.
    sig { returns(String) }
    def delimiter; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing to a constant path.
  #
  # ```rb
  # ^^^^^^^^^
  #
  # Foo::Bar = 1
  # ^^^^^^^^^^^^
  # ^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#OjpGb28gPSAxCgpGb286OkJhciA9IDEKCjo6Rm9vOjpCYXIgPSAxCg)
  class ConstantPathWriteNode < Node
    # Initialize a new ConstantPathWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, target: ConstantPathNode, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, target, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, target: ConstantPathNode, operator_loc: Location, value: Node).returns(ConstantPathWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), target: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # A node representing the constant path being written to.
    #
    # ```rb
    # Foo::Bar = 1
    # ^^^^^^^^
    # ^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Rm9vOjpCYXIgPSAxCgo6OkZvbyA9IDphYmMK)
    sig { returns(ConstantPathNode) }
    def target; end

    # The Location of the `=` operator.
    #
    # ```rb
    #       ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#OjpBQkMgPSAxMjMK)
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # The value to write to the constant path. It can be any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # FOO::BAR = :abc
    #            ^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Rk9POjpCQVIgPSA6YWJjCg)
    sig { returns(Node) }
    def value; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents referencing a constant.
  #
  # ```rb
  # Foo
  # ^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Rm9vCg)
  class ConstantReadNode < Node
    # Initialize a new ConstantReadNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).void }
    def initialize(source, node_id, location, flags, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(ConstantReadNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The name of the [constant](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#constants).
    #
    # ```rb
    # X              # name `:X`
    #
    # SOME_CONSTANT  # name `:SOME_CONSTANT`
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#WCAgICAgICAgICAgICAgIyBuYW1lIGA6WGAKClNPTUVfQ09OU1RBTlQgICMgbmFtZSBgOlNPTUVfQ09OU1RBTlRgCg)
    sig { returns(Symbol) }
    def name; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing to a constant in a context that doesn't have an explicit value.
  #
  # ```rb
  # Foo, Bar = baz
  # ^^^  ^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Rm9vLCBCYXIgPSBiYXoK)
  class ConstantTargetNode < Node
    # Initialize a new ConstantTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).void }
    def initialize(source, node_id, location, flags, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(ConstantTargetNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `name` attribute.
    sig { returns(Symbol) }
    def name; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing to a constant.
  #
  # ```rb
  # Foo = 1
  # ^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Rm9vID0gMQo)
  class ConstantWriteNode < Node
    # Initialize a new ConstantWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, value: Node, operator_loc: Location).void }
    def initialize(source, node_id, location, flags, name, name_loc, value, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, value: Node, operator_loc: Location).returns(ConstantWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), value: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The name of the [constant](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#constants).
    #
    # ```rb
    # Foo = :bar # name `:Foo`
    #
    # XYZ = 1    # name `:XYZ`
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Rm9vID0gOmJhciAjIG5hbWUgYDpGb29gCgpYWVogPSAxICAgICMgbmFtZSBgOlhZWmAK)
    sig { returns(Symbol) }
    def name; end

    # The Location of the constant name.
    #
    # ```rb
    # FOO = 1
    # ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Rk9PID0gMQo)
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # The value to write to the constant. It can be any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # FOO = :bar
    #       ^^^^
    #
    # MyClass = Class.new
    #           ^^^^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Rk9PID0gOmJhcgoKTXlDbGFzcyA9IENsYXNzLm5ldwo)
    sig { returns(Node) }
    def value; end

    # The Location of the `=` operator.
    #
    # ```rb
    # FOO = :bar
    #     ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Rk9PID0gOmJhcgo)
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a method definition.
  #
  # ```rb
  # def method
  # end
  # ^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#ZGVmIG1ldGhvZAplbmQK)
  class DefNode < Node
    # Initialize a new DefNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, receiver: ::T.nilable(Node), parameters: ::T.nilable(ParametersNode), body: ::T.nilable(::T.any(StatementsNode, BeginNode)), locals: T::Array[Symbol], def_keyword_loc: Location, operator_loc: ::T.nilable(Location), lparen_loc: ::T.nilable(Location), rparen_loc: ::T.nilable(Location), equal_loc: ::T.nilable(Location), end_keyword_loc: ::T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, name, name_loc, receiver, parameters, body, locals, def_keyword_loc, operator_loc, lparen_loc, rparen_loc, equal_loc, end_keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, receiver: ::T.nilable(Node), parameters: ::T.nilable(ParametersNode), body: ::T.nilable(::T.any(StatementsNode, BeginNode)), locals: T::Array[Symbol], def_keyword_loc: Location, operator_loc: ::T.nilable(Location), lparen_loc: ::T.nilable(Location), rparen_loc: ::T.nilable(Location), equal_loc: ::T.nilable(Location), end_keyword_loc: ::T.nilable(Location)).returns(DefNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), receiver: T.unsafe(nil), parameters: T.unsafe(nil), body: T.unsafe(nil), locals: T.unsafe(nil), def_keyword_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), lparen_loc: T.unsafe(nil), rparen_loc: T.unsafe(nil), equal_loc: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `name` attribute.
    sig { returns(Symbol) }
    def name; end

    # Returns the Location represented by `name_loc`.
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the `receiver` attribute.
    sig { returns(::T.nilable(Node)) }
    def receiver; end

    # Returns the `parameters` attribute.
    sig { returns(::T.nilable(ParametersNode)) }
    def parameters; end

    # Returns the `body` attribute.
    sig { returns(::T.nilable(::T.any(StatementsNode, BeginNode))) }
    def body; end

    # Returns the `locals` attribute.
    sig { returns(T::Array[Symbol]) }
    def locals; end

    # Returns the Location represented by `def_keyword_loc`.
    sig { returns(Location) }
    def def_keyword_loc; end

    # Save the def_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_def_keyword_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(::T.nilable(Location)) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_operator_loc(repository); end

    # Returns the Location represented by `lparen_loc`.
    sig { returns(::T.nilable(Location)) }
    def lparen_loc; end

    # Save the lparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_lparen_loc(repository); end

    # Returns the Location represented by `rparen_loc`.
    sig { returns(::T.nilable(Location)) }
    def rparen_loc; end

    # Save the rparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_rparen_loc(repository); end

    # Returns the Location represented by `equal_loc`.
    sig { returns(::T.nilable(Location)) }
    def equal_loc; end

    # Save the equal_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_equal_loc(repository); end

    # Returns the Location represented by `end_keyword_loc`.
    sig { returns(::T.nilable(Location)) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_end_keyword_loc(repository); end

    # Slice the location of def_keyword_loc from the source.
    sig { returns(String) }
    def def_keyword; end

    # Slice the location of operator_loc from the source.
    sig { returns(::T.nilable(String)) }
    def operator; end

    # Slice the location of lparen_loc from the source.
    sig { returns(::T.nilable(String)) }
    def lparen; end

    # Slice the location of rparen_loc from the source.
    sig { returns(::T.nilable(String)) }
    def rparen; end

    # Slice the location of equal_loc from the source.
    sig { returns(::T.nilable(String)) }
    def equal; end

    # Slice the location of end_keyword_loc from the source.
    sig { returns(::T.nilable(String)) }
    def end_keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `defined?` keyword.
  #
  # ```rb
  # defined?(a)
  # ^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#ZGVmaW5lZD8oYSkK)
  class DefinedNode < Node
    # Initialize a new DefinedNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, lparen_loc: ::T.nilable(Location), value: Node, rparen_loc: ::T.nilable(Location), keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, lparen_loc, value, rparen_loc, keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, lparen_loc: ::T.nilable(Location), value: Node, rparen_loc: ::T.nilable(Location), keyword_loc: Location).returns(DefinedNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), lparen_loc: T.unsafe(nil), value: T.unsafe(nil), rparen_loc: T.unsafe(nil), keyword_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the Location represented by `lparen_loc`.
    sig { returns(::T.nilable(Location)) }
    def lparen_loc; end

    # Save the lparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_lparen_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Returns the Location represented by `rparen_loc`.
    sig { returns(::T.nilable(Location)) }
    def rparen_loc; end

    # Save the rparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_rparen_loc(repository); end

    # Returns the Location represented by `keyword_loc`.
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Slice the location of lparen_loc from the source.
    sig { returns(::T.nilable(String)) }
    def lparen; end

    # Slice the location of rparen_loc from the source.
    sig { returns(::T.nilable(String)) }
    def rparen; end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an `else` clause in a `case`, `if`, or `unless` statement.
  #
  # ```rb
  # if a then b else c end
  #             ^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#aWYgYSB0aGVuIGIgZWxzZSBjIGVuZAo)
  class ElseNode < Node
    # Initialize a new ElseNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, else_keyword_loc: Location, statements: ::T.nilable(StatementsNode), end_keyword_loc: ::T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, else_keyword_loc, statements, end_keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, else_keyword_loc: Location, statements: ::T.nilable(StatementsNode), end_keyword_loc: ::T.nilable(Location)).returns(ElseNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), else_keyword_loc: T.unsafe(nil), statements: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the Location represented by `else_keyword_loc`.
    sig { returns(Location) }
    def else_keyword_loc; end

    # Save the else_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_else_keyword_loc(repository); end

    # Returns the `statements` attribute.
    sig { returns(::T.nilable(StatementsNode)) }
    def statements; end

    # Returns the Location represented by `end_keyword_loc`.
    sig { returns(::T.nilable(Location)) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_end_keyword_loc(repository); end

    # Slice the location of else_keyword_loc from the source.
    sig { returns(String) }
    def else_keyword; end

    # Slice the location of end_keyword_loc from the source.
    sig { returns(::T.nilable(String)) }
    def end_keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an interpolated set of statements.
  #
  # ```rb
  # "foo #{bar}"
  #      ^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#ImZvbyAje2Jhcn0iCg)
  class EmbeddedStatementsNode < Node
    # Initialize a new EmbeddedStatementsNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: Location, statements: ::T.nilable(StatementsNode), closing_loc: Location).void }
    def initialize(source, node_id, location, flags, opening_loc, statements, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, opening_loc: Location, statements: ::T.nilable(StatementsNode), closing_loc: Location).returns(EmbeddedStatementsNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), statements: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the Location represented by `opening_loc`.
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the `statements` attribute.
    sig { returns(::T.nilable(StatementsNode)) }
    def statements; end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an interpolated variable.
  #
  # ```rb
  # "foo #@bar"
  #      ^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#ImZvbyAjQGJhciIK)
  class EmbeddedVariableNode < Node
    # Initialize a new EmbeddedVariableNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, operator_loc: Location, variable: ::T.any(InstanceVariableReadNode, ClassVariableReadNode, GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode)).void }
    def initialize(source, node_id, location, flags, operator_loc, variable); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, operator_loc: Location, variable: ::T.any(InstanceVariableReadNode, ClassVariableReadNode, GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode)).returns(EmbeddedVariableNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), operator_loc: T.unsafe(nil), variable: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `variable` attribute.
    sig { returns(::T.any(InstanceVariableReadNode, ClassVariableReadNode, GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode)) }
    def variable; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an `ensure` clause in a `begin` statement.
  #
  # ```rb
  # begin
  #   foo
  # ensure
  # ^^^^^^
  #   bar
  # end
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#YmVnaW4KICBmb28KZW5zdXJlCgogIGJhcgplbmQK)
  class EnsureNode < Node
    # Initialize a new EnsureNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, ensure_keyword_loc: Location, statements: ::T.nilable(StatementsNode), end_keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, ensure_keyword_loc, statements, end_keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, ensure_keyword_loc: Location, statements: ::T.nilable(StatementsNode), end_keyword_loc: Location).returns(EnsureNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), ensure_keyword_loc: T.unsafe(nil), statements: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the Location represented by `ensure_keyword_loc`.
    sig { returns(Location) }
    def ensure_keyword_loc; end

    # Save the ensure_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_ensure_keyword_loc(repository); end

    # Returns the `statements` attribute.
    sig { returns(::T.nilable(StatementsNode)) }
    def statements; end

    # Returns the Location represented by `end_keyword_loc`.
    sig { returns(Location) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_end_keyword_loc(repository); end

    # Slice the location of ensure_keyword_loc from the source.
    sig { returns(String) }
    def ensure_keyword; end

    # Slice the location of end_keyword_loc from the source.
    sig { returns(String) }
    def end_keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a node that is either missing or unexpected and results in a syntax error.
  class ErrorRecoveryNode < Node
    # Initialize a new ErrorRecoveryNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, unexpected: ::T.nilable(Node)).void }
    def initialize(source, node_id, location, flags, unexpected); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, unexpected: ::T.nilable(Node)).returns(ErrorRecoveryNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), unexpected: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The unexpected node that was found in the tree, if there was one.
    sig { returns(::T.nilable(Node)) }
    def unexpected; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the literal `false` keyword.
  #
  # ```rb
  # false
  # ^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#ZmFsc2UK)
  class FalseNode < Node
    # Initialize a new FalseNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(FalseNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a find pattern in pattern matching.
  #
  # ```rb
  # foo in *bar, baz, *qux
  #        ^^^^^^^^^^^^^^^
  #
  # foo in [*bar, baz, *qux]
  #        ^^^^^^^^^^^^^^^^^
  #
  # foo in Foo(*bar, baz, *qux)
  #        ^^^^^^^^^^^^^^^^^^^^
  #
  # foo => *bar, baz, *qux
  #        ^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIGluICpiYXIsIGJheiwgKnF1eAoKZm9vIGluIFsqYmFyLCBiYXosICpxdXhdCgpmb28gaW4gRm9vKCpiYXIsIGJheiwgKnF1eCkKCmZvbyA9PiAqYmFyLCBiYXosICpxdXgK)
  class FindPatternNode < Node
    # Initialize a new FindPatternNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, constant: ::T.nilable(::T.any(ConstantPathNode, ConstantReadNode)), left: SplatNode, requireds: T::Array[Node], right: SplatNode, opening_loc: ::T.nilable(Location), closing_loc: ::T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, constant, left, requireds, right, opening_loc, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, constant: ::T.nilable(::T.any(ConstantPathNode, ConstantReadNode)), left: SplatNode, requireds: T::Array[Node], right: SplatNode, opening_loc: ::T.nilable(Location), closing_loc: ::T.nilable(Location)).returns(FindPatternNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), constant: T.unsafe(nil), left: T.unsafe(nil), requireds: T.unsafe(nil), right: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Represents the optional constant preceding the pattern
    #
    # ```rb
    # foo in Foo(*bar, baz, *qux)
    #        ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIGluIEZvbygqYmFyLCBiYXosICpxdXgpCg)
    sig { returns(::T.nilable(::T.any(ConstantPathNode, ConstantReadNode))) }
    def constant; end

    # Represents the first wildcard node in the pattern.
    #
    # ```rb
    # foo in *bar, baz, *qux
    #        ^^^^
    #
    # foo in Foo(*bar, baz, *qux)
    #            ^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIGluICpiYXIsIGJheiwgKnF1eAoKZm9vIGluIEZvbygqYmFyLCBiYXosICpxdXgpCg)
    sig { returns(SplatNode) }
    def left; end

    # Represents the nodes in between the wildcards.
    #
    # ```rb
    # foo in *bar, baz, *qux
    #              ^^^
    #
    # foo in Foo(*bar, baz, 1, *qux)
    #                  ^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIGluICpiYXIsIGJheiwgKnF1eAoKZm9vIGluIEZvbygqYmFyLCBiYXosIDEsICpxdXgpCg)
    sig { returns(T::Array[Node]) }
    def requireds; end

    # Represents the second wildcard node in the pattern.
    #
    # ```rb
    # foo in *bar, baz, *qux
    #                   ^^^^
    #
    # foo in Foo(*bar, baz, *qux)
    #                       ^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIGluICpiYXIsIGJheiwgKnF1eAoKZm9vIGluIEZvbygqYmFyLCBiYXosICpxdXgpCg)
    sig { returns(SplatNode) }
    def right; end

    # The Location of the opening brace.
    #
    # ```rb
    # foo in [*bar, baz, *qux]
    #        ^
    #
    # foo in Foo(*bar, baz, *qux)
    #           ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIGluIFsqYmFyLCBiYXosICpxdXhdCgpmb28gaW4gRm9vKCpiYXIsIGJheiwgKnF1eCkK)
    sig { returns(::T.nilable(Location)) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_opening_loc(repository); end

    # The Location of the closing brace.
    #
    # ```rb
    # foo in [*bar, baz, *qux]
    #                        ^
    #
    # foo in Foo(*bar, baz, *qux)
    #                           ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIGluIFsqYmFyLCBiYXosICpxdXhdCgpmb28gaW4gRm9vKCpiYXIsIGJheiwgKnF1eCkK)
    sig { returns(::T.nilable(Location)) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(::T.nilable(String)) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(::T.nilable(String)) }
    def closing; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `..` or `...` operators to create flip flops.
  #
  # ```rb
  # baz if foo .. bar
  #        ^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#YmF6IGlmIGZvbyAuLiBiYXIK)
  class FlipFlopNode < Node
    # Initialize a new FlipFlopNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, left: ::T.nilable(Node), right: ::T.nilable(Node), operator_loc: Location).void }
    def initialize(source, node_id, location, flags, left, right, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, left: ::T.nilable(Node), right: ::T.nilable(Node), operator_loc: Location).returns(FlipFlopNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), left: T.unsafe(nil), right: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # ... operator
    sig { returns(T::Boolean) }
    def exclude_end?; end

    # Returns the `left` attribute.
    sig { returns(::T.nilable(Node)) }
    def left; end

    # Returns the `right` attribute.
    sig { returns(::T.nilable(Node)) }
    def right; end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a floating point number literal.
  #
  # ```rb
  # 1.0
  # ^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#MS4wCg)
  class FloatNode < Node
    # Initialize a new FloatNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, value: Float).void }
    def initialize(source, node_id, location, flags, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, value: Float).returns(FloatNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The value of the floating point number as a Float.
    sig { returns(Float) }
    def value; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `for` keyword.
  #
  # ```rb
  # for i in a end
  # ^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9yIGkgaW4gYSBlbmQK)
  class ForNode < Node
    # Initialize a new ForNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, index: ::T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode), collection: Node, statements: ::T.nilable(StatementsNode), for_keyword_loc: Location, in_keyword_loc: Location, do_keyword_loc: ::T.nilable(Location), end_keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, index, collection, statements, for_keyword_loc, in_keyword_loc, do_keyword_loc, end_keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, index: ::T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode), collection: Node, statements: ::T.nilable(StatementsNode), for_keyword_loc: Location, in_keyword_loc: Location, do_keyword_loc: ::T.nilable(Location), end_keyword_loc: Location).returns(ForNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), index: T.unsafe(nil), collection: T.unsafe(nil), statements: T.unsafe(nil), for_keyword_loc: T.unsafe(nil), in_keyword_loc: T.unsafe(nil), do_keyword_loc: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The index expression for `for` loops.
    #
    # ```rb
    # for i in a end
    #     ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9yIGkgaW4gYSBlbmQK)
    sig { returns(::T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode)) }
    def index; end

    # The collection to iterate over.
    #
    # ```rb
    # for i in a end
    #          ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9yIGkgaW4gYSBlbmQK)
    sig { returns(Node) }
    def collection; end

    # Represents the body of statements to execute for each iteration of the loop.
    #
    # ```rb
    # for i in a
    #   foo(i)
    #   ^^^^^^
    # end
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9yIGkgaW4gYQogIGZvbyhpKQoKZW5kCg)
    sig { returns(::T.nilable(StatementsNode)) }
    def statements; end

    # The Location of the `for` keyword.
    #
    # ```rb
    # for i in a end
    # ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9yIGkgaW4gYSBlbmQK)
    sig { returns(Location) }
    def for_keyword_loc; end

    # Save the for_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_for_keyword_loc(repository); end

    # The Location of the `in` keyword.
    #
    # ```rb
    # for i in a end
    #       ^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9yIGkgaW4gYSBlbmQK)
    sig { returns(Location) }
    def in_keyword_loc; end

    # Save the in_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_in_keyword_loc(repository); end

    # The Location of the `do` keyword, if present.
    #
    # ```rb
    # for i in a do end
    #            ^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9yIGkgaW4gYSBkbyBlbmQK)
    sig { returns(::T.nilable(Location)) }
    def do_keyword_loc; end

    # Save the do_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_do_keyword_loc(repository); end

    # The Location of the `end` keyword.
    #
    # ```rb
    # for i in a end
    #            ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9yIGkgaW4gYSBlbmQK)
    sig { returns(Location) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_end_keyword_loc(repository); end

    # Slice the location of for_keyword_loc from the source.
    sig { returns(String) }
    def for_keyword; end

    # Slice the location of in_keyword_loc from the source.
    sig { returns(String) }
    def in_keyword; end

    # Slice the location of do_keyword_loc from the source.
    sig { returns(::T.nilable(String)) }
    def do_keyword; end

    # Slice the location of end_keyword_loc from the source.
    sig { returns(String) }
    def end_keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents forwarding all arguments to this method to another method.
  #
  # ```rb
  # def foo(...)
  #   bar(...)
  #       ^^^
  # end
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#ZGVmIGZvbyguLi4pCiAgYmFyKC4uLikKCmVuZAo)
  class ForwardingArgumentsNode < Node
    # Initialize a new ForwardingArgumentsNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(ForwardingArgumentsNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the forwarding parameter in a method, block, or lambda declaration.
  #
  # ```rb
  # def foo(...)
  #         ^^^
  # end
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#ZGVmIGZvbyguLi4pCgplbmQK)
  class ForwardingParameterNode < Node
    # Initialize a new ForwardingParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(ForwardingParameterNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `super` keyword without parentheses or arguments, but which might have a block.
  #
  # ```rb
  # super
  # ^^^^^
  #
  # super { 123 }
  # ^^^^^^^^^^^^^
  #
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#c3VwZXIKCnN1cGVyIHsgMTIzIH0K)
  # If it has any other arguments, it would be a `SuperNode` instead.
  class ForwardingSuperNode < Node
    # Initialize a new ForwardingSuperNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, block: ::T.nilable(BlockNode)).void }
    def initialize(source, node_id, location, flags, keyword_loc, block); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, block: ::T.nilable(BlockNode)).returns(ForwardingSuperNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), keyword_loc: T.unsafe(nil), block: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # super
    # ^^^^^
    #
    # super { 123 }
    # ^^^^^
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # All other arguments are forwarded as normal, except the original block is replaced with the new block.
    sig { returns(::T.nilable(BlockNode)) }
    def block; end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `&&=` operator for assignment to a global variable.
  #
  # ```rb
  # $target &&= value
  # ^^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#JHRhcmdldCAmJj0gdmFsdWUK)
  class GlobalVariableAndWriteNode < Node
    # Initialize a new GlobalVariableAndWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, name, name_loc, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(GlobalVariableAndWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `name` attribute.
    sig { returns(Symbol) }
    def name; end

    # Returns the Location represented by `name_loc`.
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents assigning to a global variable using an operator that isn't `=`.
  #
  # ```rb
  # $target += value
  # ^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#JHRhcmdldCArPSB2YWx1ZQo)
  class GlobalVariableOperatorWriteNode < Node
    # Initialize a new GlobalVariableOperatorWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, binary_operator_loc: Location, value: Node, binary_operator: Symbol).void }
    def initialize(source, node_id, location, flags, name, name_loc, binary_operator_loc, value, binary_operator); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, binary_operator_loc: Location, value: Node, binary_operator: Symbol).returns(GlobalVariableOperatorWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), binary_operator_loc: T.unsafe(nil), value: T.unsafe(nil), binary_operator: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `name` attribute.
    sig { returns(Symbol) }
    def name; end

    # Returns the Location represented by `name_loc`.
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `binary_operator_loc`.
    sig { returns(Location) }
    def binary_operator_loc; end

    # Save the binary_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_binary_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Returns the `binary_operator` attribute.
    sig { returns(Symbol) }
    def binary_operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `||=` operator for assignment to a global variable.
  #
  # ```rb
  # $target ||= value
  # ^^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#JHRhcmdldCB8fD0gdmFsdWUK)
  class GlobalVariableOrWriteNode < Node
    # Initialize a new GlobalVariableOrWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, name, name_loc, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(GlobalVariableOrWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `name` attribute.
    sig { returns(Symbol) }
    def name; end

    # Returns the Location represented by `name_loc`.
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents referencing a global variable.
  #
  # ```rb
  # $foo
  # ^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#JGZvbwo)
  class GlobalVariableReadNode < Node
    # Initialize a new GlobalVariableReadNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).void }
    def initialize(source, node_id, location, flags, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(GlobalVariableReadNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The name of the global variable, which is a `$` followed by an [identifier](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#identifier). Alternatively, it can be one of the special global variables designated by a symbol.
    #
    # ```rb
    # $foo   # name `:$foo`
    #
    # $_Test # name `:$_Test`
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#JGZvbyAgICMgbmFtZSBgOiRmb29gCgokX1Rlc3QgIyBuYW1lIGA6JF9UZXN0YAo)
    sig { returns(Symbol) }
    def name; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing to a global variable in a context that doesn't have an explicit value.
  #
  # ```rb
  # $foo, $bar = baz
  # ^^^^  ^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#JGZvbywgJGJhciA9IGJhego)
  class GlobalVariableTargetNode < Node
    # Initialize a new GlobalVariableTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).void }
    def initialize(source, node_id, location, flags, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(GlobalVariableTargetNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `name` attribute.
    sig { returns(Symbol) }
    def name; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing to a global variable.
  #
  # ```rb
  # $foo = 1
  # ^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#JGZvbyA9IDEK)
  class GlobalVariableWriteNode < Node
    # Initialize a new GlobalVariableWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, value: Node, operator_loc: Location).void }
    def initialize(source, node_id, location, flags, name, name_loc, value, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, value: Node, operator_loc: Location).returns(GlobalVariableWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), value: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The name of the global variable, which is a `$` followed by an [identifier](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#identifier). Alternatively, it can be one of the special global variables designated by a symbol.
    #
    # ```rb
    # $foo = :bar  # name `:$foo`
    #
    # $_Test = 123 # name `:$_Test`
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#JGZvbyA9IDpiYXIgICMgbmFtZSBgOiRmb29gCgokX1Rlc3QgPSAxMjMgIyBuYW1lIGA6JF9UZXN0YAo)
    sig { returns(Symbol) }
    def name; end

    # The Location of the global variable's name.
    #
    # ```rb
    # $foo = :bar
    # ^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#JGZvbyA9IDpiYXIK)
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # The value to write to the global variable. It can be any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # $foo = :bar
    #        ^^^^
    #
    # $-xyz = 123
    #         ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#JGZvbyA9IDpiYXIKCiQteHl6ID0gMTIzCg)
    sig { returns(Node) }
    def value; end

    # The Location of the `=` operator.
    #
    # ```rb
    # $foo = :bar
    #      ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#JGZvbyA9IDpiYXIK)
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a hash literal.
  #
  # ```rb
  # { a => b }
  # ^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#eyBhID0-IGIgfQo)
  class HashNode < Node
    # Initialize a new HashNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: Location, elements: T::Array[::T.any(AssocNode, AssocSplatNode)], closing_loc: Location).void }
    def initialize(source, node_id, location, flags, opening_loc, elements, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, opening_loc: Location, elements: T::Array[::T.any(AssocNode, AssocSplatNode)], closing_loc: Location).returns(HashNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), elements: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The Location of the opening brace.
    #
    # ```rb
    # { a => b }
    # ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#eyBhID0-IGIgfQo)
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # The elements of the hash. These can be either `AssocNode`s or `AssocSplatNode`s.
    #
    # ```rb
    # { a: b }
    #   ^^^^
    #
    # { **foo }
    #   ^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#eyBhOiBiIH0KCnsgKipmb28gfQo)
    sig { returns(T::Array[::T.any(AssocNode, AssocSplatNode)]) }
    def elements; end

    # The Location of the closing brace.
    #
    # ```rb
    # { a => b }
    #          ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#eyBhID0-IGIgfQo)
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a hash pattern in pattern matching.
  #
  # ```rb
  # foo => { a: 1, b: 2 }
  #        ^^^^^^^^^^^^^^
  #
  # foo => { a: 1, b: 2, **c }
  #        ^^^^^^^^^^^^^^^^^^^
  #
  # foo => Bar[a: 1, b: 2]
  #        ^^^^^^^^^^^^^^^
  #
  # foo in { a: 1, b: 2 }
  #        ^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0-IHsgYTogMSwgYjogMiB9Cgpmb28gPT4geyBhOiAxLCBiOiAyLCAqKmMgfQoKZm9vID0-IEJhclthOiAxLCBiOiAyXQoKZm9vIGluIHsgYTogMSwgYjogMiB9Cg)
  class HashPatternNode < Node
    # Initialize a new HashPatternNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, constant: ::T.nilable(::T.any(ConstantPathNode, ConstantReadNode)), elements: T::Array[AssocNode], rest: ::T.nilable(::T.any(AssocSplatNode, NoKeywordsParameterNode)), opening_loc: ::T.nilable(Location), closing_loc: ::T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, constant, elements, rest, opening_loc, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, constant: ::T.nilable(::T.any(ConstantPathNode, ConstantReadNode)), elements: T::Array[AssocNode], rest: ::T.nilable(::T.any(AssocSplatNode, NoKeywordsParameterNode)), opening_loc: ::T.nilable(Location), closing_loc: ::T.nilable(Location)).returns(HashPatternNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), constant: T.unsafe(nil), elements: T.unsafe(nil), rest: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Represents the optional constant preceding the Hash.
    #
    # ```rb
    # foo => Bar[a: 1, b: 2]
    #      ^^^
    #
    # foo => Bar::Baz[a: 1, b: 2]
    #      ^^^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0-IEJhclthOiAxLCBiOiAyXQoKZm9vID0-IEJhcjo6QmF6W2E6IDEsIGI6IDJdCg)
    sig { returns(::T.nilable(::T.any(ConstantPathNode, ConstantReadNode))) }
    def constant; end

    # Represents the explicit named hash keys and values.
    #
    # ```rb
    # foo => { a: 1, b:, ** }
    #          ^^^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0-IHsgYTogMSwgYjosICoqIH0K)
    sig { returns(T::Array[AssocNode]) }
    def elements; end

    # Represents the rest of the Hash keys and values. This can be named, unnamed, or explicitly forbidden via `**nil`, this last one results in a `NoKeywordsParameterNode`.
    #
    # ```rb
    # foo => { a: 1, b:, **c }
    #                    ^^^
    #
    # foo => { a: 1, b:, ** }
    #                    ^^
    #
    # foo => { a: 1, b:, **nil }
    #                    ^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0-IHsgYTogMSwgYjosICoqYyB9Cgpmb28gPT4geyBhOiAxLCBiOiwgKiogfQoKZm9vID0-IHsgYTogMSwgYjosICoqbmlsIH0K)
    sig { returns(::T.nilable(::T.any(AssocSplatNode, NoKeywordsParameterNode))) }
    def rest; end

    # The Location of the opening brace.
    #
    # ```rb
    # foo => { a: 1 }
    #        ^
    #
    # foo => Bar[a: 1]
    #           ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0-IHsgYTogMSB9Cgpmb28gPT4gQmFyW2E6IDFdCg)
    sig { returns(::T.nilable(Location)) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_opening_loc(repository); end

    # The Location of the closing brace.
    #
    # ```rb
    # foo => { a: 1 }
    #               ^
    #
    # foo => Bar[a: 1]
    #                ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0-IHsgYTogMSB9Cgpmb28gPT4gQmFyW2E6IDFdCg)
    sig { returns(::T.nilable(Location)) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(::T.nilable(String)) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(::T.nilable(String)) }
    def closing; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `if` keyword, either in the block form or the modifier form, or a ternary expression.
  #
  # ```rb
  # bar if foo
  # ^^^^^^^^^^
  #
  # if foo then bar end
  # ^^^^^^^^^^^^^^^^^^^
  #
  # foo ? bar : baz
  # ^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#YmFyIGlmIGZvbwoKaWYgZm9vIHRoZW4gYmFyIGVuZAoKZm9vID8gYmFyIDogYmF6Cg)
  class IfNode < Node
    # Initialize a new IfNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, if_keyword_loc: ::T.nilable(Location), predicate: Node, then_keyword_loc: ::T.nilable(Location), statements: ::T.nilable(StatementsNode), subsequent: ::T.nilable(::T.any(ElseNode, IfNode)), end_keyword_loc: ::T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, if_keyword_loc, predicate, then_keyword_loc, statements, subsequent, end_keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, if_keyword_loc: ::T.nilable(Location), predicate: Node, then_keyword_loc: ::T.nilable(Location), statements: ::T.nilable(StatementsNode), subsequent: ::T.nilable(::T.any(ElseNode, IfNode)), end_keyword_loc: ::T.nilable(Location)).returns(IfNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), if_keyword_loc: T.unsafe(nil), predicate: T.unsafe(nil), then_keyword_loc: T.unsafe(nil), statements: T.unsafe(nil), subsequent: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The Location of the `if` keyword if present.
    #
    # ```rb
    # bar if foo
    #     ^^
    #
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YmFyIGlmIGZvbwo)
    # The `if_keyword_loc` field will be `nil` when the `IfNode` represents a ternary expression.
    sig { returns(::T.nilable(Location)) }
    def if_keyword_loc; end

    # Save the if_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_if_keyword_loc(repository); end

    # The node for the condition the `IfNode` is testing.
    #
    # ```rb
    # if foo
    #    ^^^
    #   bar
    # end
    #
    # bar if foo
    #        ^^^
    #
    # foo ? bar : baz
    # ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#aWYgZm9vCgogIGJhcgplbmQKCmJhciBpZiBmb28KCmZvbyA_IGJhciA6IGJhego)
    sig { returns(Node) }
    def predicate; end

    # The Location of the `then` keyword (if present) or the `?` in a ternary expression, `nil` otherwise.
    #
    # ```rb
    # if foo then bar end
    #        ^^^^
    #
    # a ? b : c
    #   ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#aWYgZm9vIHRoZW4gYmFyIGVuZAoKYSA_IGIgOiBjCg)
    sig { returns(::T.nilable(Location)) }
    def then_keyword_loc; end

    # Save the then_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_then_keyword_loc(repository); end

    # Represents the body of statements that will be executed when the predicate is evaluated as truthy. Will be `nil` when no body is provided.
    #
    # ```rb
    # if foo
    #   bar
    #   ^^^
    #   baz
    #   ^^^
    # end
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#aWYgZm9vCiAgYmFyCgogIGJhegoKZW5kCg)
    sig { returns(::T.nilable(StatementsNode)) }
    def statements; end

    # Represents an `ElseNode` or an `IfNode` when there is an `else` or an `elsif` in the `if` statement.
    #
    # ```rb
    # if foo
    #   bar
    # elsif baz
    # ^^^^^^^^^
    #   qux
    #   ^^^
    # end
    # ^^^
    #
    # if foo then bar else baz end
    #                 ^^^^^^^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#aWYgZm9vCiAgYmFyCmVsc2lmIGJhegoKICBxdXgKCmVuZAoKaWYgZm9vIHRoZW4gYmFyIGVsc2UgYmF6IGVuZAo)
    sig { returns(::T.nilable(::T.any(ElseNode, IfNode))) }
    def subsequent; end

    # The Location of the `end` keyword if present, `nil` otherwise.
    #
    # ```rb
    # if foo
    #   bar
    # end
    # ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#aWYgZm9vCiAgYmFyCmVuZAo)
    sig { returns(::T.nilable(Location)) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_end_keyword_loc(repository); end

    # Slice the location of if_keyword_loc from the source.
    sig { returns(::T.nilable(String)) }
    def if_keyword; end

    # Slice the location of then_keyword_loc from the source.
    sig { returns(::T.nilable(String)) }
    def then_keyword; end

    # Slice the location of end_keyword_loc from the source.
    sig { returns(::T.nilable(String)) }
    def end_keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an imaginary number literal.
  #
  # ```rb
  # 1.0i
  # ^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#MS4waQo)
  class ImaginaryNode < Node
    # Initialize a new ImaginaryNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, numeric: ::T.any(FloatNode, IntegerNode, RationalNode)).void }
    def initialize(source, node_id, location, flags, numeric); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, numeric: ::T.any(FloatNode, IntegerNode, RationalNode)).returns(ImaginaryNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), numeric: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `numeric` attribute.
    sig { returns(::T.any(FloatNode, IntegerNode, RationalNode)) }
    def numeric; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a node that is implicitly being added to the tree but doesn't correspond directly to a node in the source.
  #
  # ```rb
  # { foo: }
  #   ^^^^
  #
  # { Foo: }
  #   ^^^^
  #
  # foo in { bar: }
  #          ^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#eyBmb286IH0KCnsgRm9vOiB9Cgpmb28gaW4geyBiYXI6IH0K)
  class ImplicitNode < Node
    # Initialize a new ImplicitNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, value: ::T.any(LocalVariableReadNode, CallNode, ConstantReadNode, LocalVariableTargetNode)).void }
    def initialize(source, node_id, location, flags, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, value: ::T.any(LocalVariableReadNode, CallNode, ConstantReadNode, LocalVariableTargetNode)).returns(ImplicitNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `value` attribute.
    sig { returns(::T.any(LocalVariableReadNode, CallNode, ConstantReadNode, LocalVariableTargetNode)) }
    def value; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents using a trailing comma to indicate an implicit rest parameter.
  #
  # ```rb
  # foo { |bar,| }
  #           ^
  #
  # foo in [bar,]
  #            ^
  #
  # for foo, in bar do end
  #        ^
  #
  # foo, = bar
  #    ^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIHsgfGJhcix8IH0KCmZvbyBpbiBbYmFyLF0KCmZvciBmb28sIGluIGJhciBkbyBlbmQKCmZvbywgPSBiYXIK)
  class ImplicitRestNode < Node
    # Initialize a new ImplicitRestNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(ImplicitRestNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `in` keyword in a case statement.
  #
  # ```rb
  # case a; in b then c end
  #         ^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Y2FzZSBhOyBpbiBiIHRoZW4gYyBlbmQK)
  class InNode < Node
    # Initialize a new InNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, pattern: Node, statements: ::T.nilable(StatementsNode), in_keyword_loc: Location, then_keyword_loc: ::T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, pattern, statements, in_keyword_loc, then_keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, pattern: Node, statements: ::T.nilable(StatementsNode), in_keyword_loc: Location, then_keyword_loc: ::T.nilable(Location)).returns(InNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), pattern: T.unsafe(nil), statements: T.unsafe(nil), in_keyword_loc: T.unsafe(nil), then_keyword_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `pattern` attribute.
    sig { returns(Node) }
    def pattern; end

    # Returns the `statements` attribute.
    sig { returns(::T.nilable(StatementsNode)) }
    def statements; end

    # Returns the Location represented by `in_keyword_loc`.
    sig { returns(Location) }
    def in_keyword_loc; end

    # Save the in_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_in_keyword_loc(repository); end

    # Returns the Location represented by `then_keyword_loc`.
    sig { returns(::T.nilable(Location)) }
    def then_keyword_loc; end

    # Save the then_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_then_keyword_loc(repository); end

    # Slice the location of in_keyword_loc from the source.
    sig { returns(String) }
    def in_keyword; end

    # Slice the location of then_keyword_loc from the source.
    sig { returns(::T.nilable(String)) }
    def then_keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `&&=` operator on a call to the `[]` method.
  #
  # ```rb
  # foo.bar[baz] &&= value
  # ^^^^^^^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhcltiYXpdICYmPSB2YWx1ZQo)
  class IndexAndWriteNode < Node
    # Initialize a new IndexAndWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: ::T.nilable(Node), call_operator_loc: ::T.nilable(Location), opening_loc: Location, arguments: ::T.nilable(ArgumentsNode), closing_loc: Location, block: ::T.nilable(BlockArgumentNode), operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, receiver, call_operator_loc, opening_loc, arguments, closing_loc, block, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, receiver: ::T.nilable(Node), call_operator_loc: ::T.nilable(Location), opening_loc: Location, arguments: ::T.nilable(ArgumentsNode), closing_loc: Location, block: ::T.nilable(BlockArgumentNode), operator_loc: Location, value: Node).returns(IndexAndWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), call_operator_loc: T.unsafe(nil), opening_loc: T.unsafe(nil), arguments: T.unsafe(nil), closing_loc: T.unsafe(nil), block: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # &. operator
    sig { returns(T::Boolean) }
    def safe_navigation?; end

    # a call that could have been a local variable
    sig { returns(T::Boolean) }
    def variable_call?; end

    # a call that is an attribute write, so the value being written should be returned
    sig { returns(T::Boolean) }
    def attribute_write?; end

    # a call that ignores method visibility
    sig { returns(T::Boolean) }
    def ignore_visibility?; end

    # Returns the `receiver` attribute.
    sig { returns(::T.nilable(Node)) }
    def receiver; end

    # Returns the Location represented by `call_operator_loc`.
    sig { returns(::T.nilable(Location)) }
    def call_operator_loc; end

    # Save the call_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_call_operator_loc(repository); end

    # Returns the Location represented by `opening_loc`.
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the `arguments` attribute.
    sig { returns(::T.nilable(ArgumentsNode)) }
    def arguments; end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Returns the `block` attribute.
    sig { returns(::T.nilable(BlockArgumentNode)) }
    def block; end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of call_operator_loc from the source.
    sig { returns(::T.nilable(String)) }
    def call_operator; end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of an assignment operator on a call to `[]`.
  #
  # ```rb
  # foo.bar[baz] += value
  # ^^^^^^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhcltiYXpdICs9IHZhbHVlCg)
  class IndexOperatorWriteNode < Node
    # Initialize a new IndexOperatorWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: ::T.nilable(Node), call_operator_loc: ::T.nilable(Location), opening_loc: Location, arguments: ::T.nilable(ArgumentsNode), closing_loc: Location, block: ::T.nilable(BlockArgumentNode), binary_operator: Symbol, binary_operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, receiver, call_operator_loc, opening_loc, arguments, closing_loc, block, binary_operator, binary_operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, receiver: ::T.nilable(Node), call_operator_loc: ::T.nilable(Location), opening_loc: Location, arguments: ::T.nilable(ArgumentsNode), closing_loc: Location, block: ::T.nilable(BlockArgumentNode), binary_operator: Symbol, binary_operator_loc: Location, value: Node).returns(IndexOperatorWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), call_operator_loc: T.unsafe(nil), opening_loc: T.unsafe(nil), arguments: T.unsafe(nil), closing_loc: T.unsafe(nil), block: T.unsafe(nil), binary_operator: T.unsafe(nil), binary_operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # &. operator
    sig { returns(T::Boolean) }
    def safe_navigation?; end

    # a call that could have been a local variable
    sig { returns(T::Boolean) }
    def variable_call?; end

    # a call that is an attribute write, so the value being written should be returned
    sig { returns(T::Boolean) }
    def attribute_write?; end

    # a call that ignores method visibility
    sig { returns(T::Boolean) }
    def ignore_visibility?; end

    # Returns the `receiver` attribute.
    sig { returns(::T.nilable(Node)) }
    def receiver; end

    # Returns the Location represented by `call_operator_loc`.
    sig { returns(::T.nilable(Location)) }
    def call_operator_loc; end

    # Save the call_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_call_operator_loc(repository); end

    # Returns the Location represented by `opening_loc`.
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the `arguments` attribute.
    sig { returns(::T.nilable(ArgumentsNode)) }
    def arguments; end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Returns the `block` attribute.
    sig { returns(::T.nilable(BlockArgumentNode)) }
    def block; end

    # Returns the `binary_operator` attribute.
    sig { returns(Symbol) }
    def binary_operator; end

    # Returns the Location represented by `binary_operator_loc`.
    sig { returns(Location) }
    def binary_operator_loc; end

    # Save the binary_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_binary_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of call_operator_loc from the source.
    sig { returns(::T.nilable(String)) }
    def call_operator; end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `||=` operator on a call to `[]`.
  #
  # ```rb
  # foo.bar[baz] ||= value
  # ^^^^^^^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLmJhcltiYXpdIHx8PSB2YWx1ZQo)
  class IndexOrWriteNode < Node
    # Initialize a new IndexOrWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: ::T.nilable(Node), call_operator_loc: ::T.nilable(Location), opening_loc: Location, arguments: ::T.nilable(ArgumentsNode), closing_loc: Location, block: ::T.nilable(BlockArgumentNode), operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, receiver, call_operator_loc, opening_loc, arguments, closing_loc, block, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, receiver: ::T.nilable(Node), call_operator_loc: ::T.nilable(Location), opening_loc: Location, arguments: ::T.nilable(ArgumentsNode), closing_loc: Location, block: ::T.nilable(BlockArgumentNode), operator_loc: Location, value: Node).returns(IndexOrWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), call_operator_loc: T.unsafe(nil), opening_loc: T.unsafe(nil), arguments: T.unsafe(nil), closing_loc: T.unsafe(nil), block: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # &. operator
    sig { returns(T::Boolean) }
    def safe_navigation?; end

    # a call that could have been a local variable
    sig { returns(T::Boolean) }
    def variable_call?; end

    # a call that is an attribute write, so the value being written should be returned
    sig { returns(T::Boolean) }
    def attribute_write?; end

    # a call that ignores method visibility
    sig { returns(T::Boolean) }
    def ignore_visibility?; end

    # Returns the `receiver` attribute.
    sig { returns(::T.nilable(Node)) }
    def receiver; end

    # Returns the Location represented by `call_operator_loc`.
    sig { returns(::T.nilable(Location)) }
    def call_operator_loc; end

    # Save the call_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_call_operator_loc(repository); end

    # Returns the Location represented by `opening_loc`.
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the `arguments` attribute.
    sig { returns(::T.nilable(ArgumentsNode)) }
    def arguments; end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Returns the `block` attribute.
    sig { returns(::T.nilable(BlockArgumentNode)) }
    def block; end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of call_operator_loc from the source.
    sig { returns(::T.nilable(String)) }
    def call_operator; end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents assigning to an index.
  #
  # ```rb
  # foo[bar], = 1
  # ^^^^^^^^
  #
  # begin
  # rescue => foo[bar]
  #           ^^^^^^^^
  # end
  #
  # for foo[bar] in baz do end
  #     ^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vW2Jhcl0sID0gMQoKYmVnaW4KcmVzY3VlID0-IGZvb1tiYXJdCgplbmQKCmZvciBmb29bYmFyXSBpbiBiYXogZG8gZW5kCg)
  class IndexTargetNode < Node
    # Initialize a new IndexTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: Node, opening_loc: Location, arguments: ::T.nilable(ArgumentsNode), closing_loc: Location, block: ::T.nilable(BlockArgumentNode)).void }
    def initialize(source, node_id, location, flags, receiver, opening_loc, arguments, closing_loc, block); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, receiver: Node, opening_loc: Location, arguments: ::T.nilable(ArgumentsNode), closing_loc: Location, block: ::T.nilable(BlockArgumentNode)).returns(IndexTargetNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), opening_loc: T.unsafe(nil), arguments: T.unsafe(nil), closing_loc: T.unsafe(nil), block: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # &. operator
    sig { returns(T::Boolean) }
    def safe_navigation?; end

    # a call that could have been a local variable
    sig { returns(T::Boolean) }
    def variable_call?; end

    # a call that is an attribute write, so the value being written should be returned
    sig { returns(T::Boolean) }
    def attribute_write?; end

    # a call that ignores method visibility
    sig { returns(T::Boolean) }
    def ignore_visibility?; end

    # Returns the `receiver` attribute.
    sig { returns(Node) }
    def receiver; end

    # Returns the Location represented by `opening_loc`.
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the `arguments` attribute.
    sig { returns(::T.nilable(ArgumentsNode)) }
    def arguments; end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Returns the `block` attribute.
    sig { returns(::T.nilable(BlockArgumentNode)) }
    def block; end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `&&=` operator for assignment to an instance variable.
  #
  # ```rb
  # @target &&= value
  # ^^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#QHRhcmdldCAmJj0gdmFsdWUK)
  class InstanceVariableAndWriteNode < Node
    # Initialize a new InstanceVariableAndWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, name, name_loc, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(InstanceVariableAndWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `name` attribute.
    sig { returns(Symbol) }
    def name; end

    # Returns the Location represented by `name_loc`.
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents assigning to an instance variable using an operator that isn't `=`.
  #
  # ```rb
  # @target += value
  # ^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#QHRhcmdldCArPSB2YWx1ZQo)
  class InstanceVariableOperatorWriteNode < Node
    # Initialize a new InstanceVariableOperatorWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, binary_operator_loc: Location, value: Node, binary_operator: Symbol).void }
    def initialize(source, node_id, location, flags, name, name_loc, binary_operator_loc, value, binary_operator); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, binary_operator_loc: Location, value: Node, binary_operator: Symbol).returns(InstanceVariableOperatorWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), binary_operator_loc: T.unsafe(nil), value: T.unsafe(nil), binary_operator: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `name` attribute.
    sig { returns(Symbol) }
    def name; end

    # Returns the Location represented by `name_loc`.
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `binary_operator_loc`.
    sig { returns(Location) }
    def binary_operator_loc; end

    # Save the binary_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_binary_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Returns the `binary_operator` attribute.
    sig { returns(Symbol) }
    def binary_operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `||=` operator for assignment to an instance variable.
  #
  # ```rb
  # @target ||= value
  # ^^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#QHRhcmdldCB8fD0gdmFsdWUK)
  class InstanceVariableOrWriteNode < Node
    # Initialize a new InstanceVariableOrWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, name, name_loc, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(InstanceVariableOrWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `name` attribute.
    sig { returns(Symbol) }
    def name; end

    # Returns the Location represented by `name_loc`.
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents referencing an instance variable.
  #
  # ```rb
  # @foo
  # ^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#QGZvbwo)
  class InstanceVariableReadNode < Node
    # Initialize a new InstanceVariableReadNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).void }
    def initialize(source, node_id, location, flags, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(InstanceVariableReadNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The name of the instance variable, which is a `@` followed by an [identifier](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#identifiers).
    #
    # ```rb
    # @x     # name `:@x`
    #
    # @_test # name `:@_test`
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#QHggICAgICMgbmFtZSBgOkB4YAoKQF90ZXN0ICMgbmFtZSBgOkBfdGVzdGAK)
    sig { returns(Symbol) }
    def name; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing to an instance variable in a context that doesn't have an explicit value.
  #
  # ```rb
  # @foo, @bar = baz
  # ^^^^  ^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#QGZvbywgQGJhciA9IGJhego)
  class InstanceVariableTargetNode < Node
    # Initialize a new InstanceVariableTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).void }
    def initialize(source, node_id, location, flags, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(InstanceVariableTargetNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `name` attribute.
    sig { returns(Symbol) }
    def name; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing to an instance variable.
  #
  # ```rb
  # @foo = 1
  # ^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#QGZvbyA9IDEK)
  class InstanceVariableWriteNode < Node
    # Initialize a new InstanceVariableWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, value: Node, operator_loc: Location).void }
    def initialize(source, node_id, location, flags, name, name_loc, value, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, value: Node, operator_loc: Location).returns(InstanceVariableWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), value: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The name of the instance variable, which is a `@` followed by an [identifier](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#identifiers).
    #
    # ```rb
    # @x = :y       # name `:@x`
    #
    # @_foo = "bar" # name `@_foo`
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#QHggPSA6eSAgICAgICAjIG5hbWUgYDpAeGAKCkBfZm9vID0gImJhciIgIyBuYW1lIGBAX2Zvb2AK)
    sig { returns(Symbol) }
    def name; end

    # The Location of the variable name.
    #
    # ```rb
    # @_x = 1
    # ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#QF94ID0gMQo)
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # The value to write to the instance variable. It can be any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # @foo = :bar
    #        ^^^^
    #
    # @_x = 1234
    #       ^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#QGZvbyA9IDpiYXIKCkBfeCA9IDEyMzQK)
    sig { returns(Node) }
    def value; end

    # The Location of the `=` operator.
    #
    # ```rb
    # @x = y
    #    ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#QHggPSB5Cg)
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an integer number literal.
  #
  # ```rb
  # 1
  # ^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#MQo)
  class IntegerNode < Node
    # Initialize a new IntegerNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, value: Integer).void }
    def initialize(source, node_id, location, flags, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, value: Integer).returns(IntegerNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # 0b prefix
    sig { returns(T::Boolean) }
    def binary?; end

    # 0d or no prefix
    sig { returns(T::Boolean) }
    def decimal?; end

    # 0o or 0 prefix
    sig { returns(T::Boolean) }
    def octal?; end

    # 0x prefix
    sig { returns(T::Boolean) }
    def hexadecimal?; end

    # The value of the integer literal as a number.
    sig { returns(Integer) }
    def value; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a regular expression literal that contains interpolation that is being used in the predicate of a conditional to implicitly match against the last line read by an IO object.
  #
  # ```rb
  # if /foo #{bar} baz/ then end
  #    ^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#aWYgL2ZvbyAje2Jhcn0gYmF6LyB0aGVuIGVuZAo)
  class InterpolatedMatchLastLineNode < Node
    # Initialize a new InterpolatedMatchLastLineNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: Location, parts: T::Array[::T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)], closing_loc: Location).void }
    def initialize(source, node_id, location, flags, opening_loc, parts, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, opening_loc: Location, parts: T::Array[::T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)], closing_loc: Location).returns(InterpolatedMatchLastLineNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), parts: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # i - ignores the case of characters when matching
    sig { returns(T::Boolean) }
    def ignore_case?; end

    # x - ignores whitespace and allows comments in regular expressions
    sig { returns(T::Boolean) }
    def extended?; end

    # m - allows $ to match the end of lines within strings
    sig { returns(T::Boolean) }
    def multi_line?; end

    # o - only interpolates values into the regular expression once
    sig { returns(T::Boolean) }
    def once?; end

    # e - forces the EUC-JP encoding
    sig { returns(T::Boolean) }
    def euc_jp?; end

    # n - forces the ASCII-8BIT encoding
    sig { returns(T::Boolean) }
    def ascii_8bit?; end

    # s - forces the Windows-31J encoding
    sig { returns(T::Boolean) }
    def windows_31j?; end

    # u - forces the UTF-8 encoding
    sig { returns(T::Boolean) }
    def utf_8?; end

    # internal bytes forced the encoding to UTF-8
    sig { returns(T::Boolean) }
    def forced_utf8_encoding?; end

    # internal bytes forced the encoding to binary
    sig { returns(T::Boolean) }
    def forced_binary_encoding?; end

    # internal bytes forced the encoding to US-ASCII
    sig { returns(T::Boolean) }
    def forced_us_ascii_encoding?; end

    # Returns the Location represented by `opening_loc`.
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the `parts` attribute.
    sig { returns(T::Array[::T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)]) }
    def parts; end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a regular expression literal that contains interpolation.
  #
  # ```rb
  # /foo #{bar} baz/
  # ^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#L2ZvbyAje2Jhcn0gYmF6Lwo)
  class InterpolatedRegularExpressionNode < Node
    # Initialize a new InterpolatedRegularExpressionNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: Location, parts: T::Array[::T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)], closing_loc: Location).void }
    def initialize(source, node_id, location, flags, opening_loc, parts, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, opening_loc: Location, parts: T::Array[::T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)], closing_loc: Location).returns(InterpolatedRegularExpressionNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), parts: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # i - ignores the case of characters when matching
    sig { returns(T::Boolean) }
    def ignore_case?; end

    # x - ignores whitespace and allows comments in regular expressions
    sig { returns(T::Boolean) }
    def extended?; end

    # m - allows $ to match the end of lines within strings
    sig { returns(T::Boolean) }
    def multi_line?; end

    # o - only interpolates values into the regular expression once
    sig { returns(T::Boolean) }
    def once?; end

    # e - forces the EUC-JP encoding
    sig { returns(T::Boolean) }
    def euc_jp?; end

    # n - forces the ASCII-8BIT encoding
    sig { returns(T::Boolean) }
    def ascii_8bit?; end

    # s - forces the Windows-31J encoding
    sig { returns(T::Boolean) }
    def windows_31j?; end

    # u - forces the UTF-8 encoding
    sig { returns(T::Boolean) }
    def utf_8?; end

    # internal bytes forced the encoding to UTF-8
    sig { returns(T::Boolean) }
    def forced_utf8_encoding?; end

    # internal bytes forced the encoding to binary
    sig { returns(T::Boolean) }
    def forced_binary_encoding?; end

    # internal bytes forced the encoding to US-ASCII
    sig { returns(T::Boolean) }
    def forced_us_ascii_encoding?; end

    # Returns the Location represented by `opening_loc`.
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the `parts` attribute.
    sig { returns(T::Array[::T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)]) }
    def parts; end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a string literal that contains interpolation.
  #
  # ```rb
  # "foo #{bar} baz"
  # ^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#ImZvbyAje2Jhcn0gYmF6Igo)
  class InterpolatedStringNode < Node
    # Initialize a new InterpolatedStringNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: ::T.nilable(Location), parts: T::Array[::T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode, InterpolatedStringNode)], closing_loc: ::T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, opening_loc, parts, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, opening_loc: ::T.nilable(Location), parts: T::Array[::T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode, InterpolatedStringNode)], closing_loc: ::T.nilable(Location)).returns(InterpolatedStringNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), parts: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # frozen by virtue of a `frozen_string_literal: true` comment or `--enable-frozen-string-literal`; only for adjacent string literals like `'a' 'b'`
    sig { returns(T::Boolean) }
    def frozen?; end

    # mutable by virtue of a `frozen_string_literal: false` comment or `--disable-frozen-string-literal`; only for adjacent string literals like `'a' 'b'`
    sig { returns(T::Boolean) }
    def mutable?; end

    # Returns the Location represented by `opening_loc`.
    sig { returns(::T.nilable(Location)) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_opening_loc(repository); end

    # Returns the `parts` attribute.
    sig { returns(T::Array[::T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode, InterpolatedStringNode)]) }
    def parts; end

    # Returns the Location represented by `closing_loc`.
    sig { returns(::T.nilable(Location)) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(::T.nilable(String)) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(::T.nilable(String)) }
    def closing; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a symbol literal that contains interpolation.
  #
  # ```rb
  # ^^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#OiJmb28gI3tiYXJ9IGJheiIK)
  class InterpolatedSymbolNode < Node
    # Initialize a new InterpolatedSymbolNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: ::T.nilable(Location), parts: T::Array[::T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)], closing_loc: ::T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, opening_loc, parts, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, opening_loc: ::T.nilable(Location), parts: T::Array[::T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)], closing_loc: ::T.nilable(Location)).returns(InterpolatedSymbolNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), parts: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the Location represented by `opening_loc`.
    sig { returns(::T.nilable(Location)) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_opening_loc(repository); end

    # Returns the `parts` attribute.
    sig { returns(T::Array[::T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)]) }
    def parts; end

    # Returns the Location represented by `closing_loc`.
    sig { returns(::T.nilable(Location)) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(::T.nilable(String)) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(::T.nilable(String)) }
    def closing; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an xstring literal that contains interpolation.
  #
  # ```rb
  # `foo #{bar} baz`
  # ^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#YGZvbyAje2Jhcn0gYmF6YAo)
  class InterpolatedXStringNode < Node
    # Initialize a new InterpolatedXStringNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: Location, parts: T::Array[::T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)], closing_loc: Location).void }
    def initialize(source, node_id, location, flags, opening_loc, parts, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, opening_loc: Location, parts: T::Array[::T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)], closing_loc: Location).returns(InterpolatedXStringNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), parts: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the Location represented by `opening_loc`.
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the `parts` attribute.
    sig { returns(T::Array[::T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)]) }
    def parts; end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents reading from the implicit `it` local variable.
  #
  # ```rb
  # -> { it }
  #      ^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#LT4geyBpdCB9Cg)
  class ItLocalVariableReadNode < Node
    # Initialize a new ItLocalVariableReadNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(ItLocalVariableReadNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an implicit set of parameters through the use of the `it` keyword within a block or lambda.
  #
  # ```rb
  # -> { it + it }
  # ^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#LT4geyBpdCArIGl0IH0K)
  class ItParametersNode < Node
    # Initialize a new ItParametersNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(ItParametersNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a hash literal without opening and closing braces.
  #
  # ```rb
  # foo(a: b)
  #     ^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vKGE6IGIpCg)
  class KeywordHashNode < Node
    # Initialize a new KeywordHashNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, elements: T::Array[::T.any(AssocNode, AssocSplatNode)]).void }
    def initialize(source, node_id, location, flags, elements); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, elements: T::Array[::T.any(AssocNode, AssocSplatNode)]).returns(KeywordHashNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), elements: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # a keyword hash which only has `AssocNode` elements all with symbol keys, which means the elements can be treated as keyword arguments
    sig { returns(T::Boolean) }
    def symbol_keys?; end

    # Returns the `elements` attribute.
    sig { returns(T::Array[::T.any(AssocNode, AssocSplatNode)]) }
    def elements; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a keyword rest parameter to a method, block, or lambda definition.
  #
  # ```rb
  # def a(**b)
  #       ^^^
  # end
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#ZGVmIGEoKipiKQoKZW5kCg)
  class KeywordRestParameterNode < Node
    # Initialize a new KeywordRestParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: ::T.nilable(Symbol), name_loc: ::T.nilable(Location), operator_loc: Location).void }
    def initialize(source, node_id, location, flags, name, name_loc, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: ::T.nilable(Symbol), name_loc: ::T.nilable(Location), operator_loc: Location).returns(KeywordRestParameterNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # a parameter name that has been repeated in the method signature
    sig { returns(T::Boolean) }
    def repeated_parameter?; end

    # Returns the `name` attribute.
    sig { returns(::T.nilable(Symbol)) }
    def name; end

    # Returns the Location represented by `name_loc`.
    sig { returns(::T.nilable(Location)) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_name_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents using a lambda literal (not the lambda method call).
  #
  # ```rb
  # ->(value) { value * 2 }
  # ^^^^^^^^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#LT4odmFsdWUpIHsgdmFsdWUgKiAyIH0K)
  class LambdaNode < Node
    # Initialize a new LambdaNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], operator_loc: Location, opening_loc: Location, closing_loc: Location, parameters: ::T.nilable(::T.any(BlockParametersNode, NumberedParametersNode, ItParametersNode)), body: ::T.nilable(::T.any(StatementsNode, BeginNode))).void }
    def initialize(source, node_id, location, flags, locals, operator_loc, opening_loc, closing_loc, parameters, body); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], operator_loc: Location, opening_loc: Location, closing_loc: Location, parameters: ::T.nilable(::T.any(BlockParametersNode, NumberedParametersNode, ItParametersNode)), body: ::T.nilable(::T.any(StatementsNode, BeginNode))).returns(LambdaNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), locals: T.unsafe(nil), operator_loc: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil), parameters: T.unsafe(nil), body: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `locals` attribute.
    sig { returns(T::Array[Symbol]) }
    def locals; end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the Location represented by `opening_loc`.
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Returns the `parameters` attribute.
    sig { returns(::T.nilable(::T.any(BlockParametersNode, NumberedParametersNode, ItParametersNode))) }
    def parameters; end

    # Returns the `body` attribute.
    sig { returns(::T.nilable(::T.any(StatementsNode, BeginNode))) }
    def body; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `&&=` operator for assignment to a local variable.
  #
  # ```rb
  # target &&= value
  # ^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#dGFyZ2V0ICYmPSB2YWx1ZQo)
  class LocalVariableAndWriteNode < Node
    # Initialize a new LocalVariableAndWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name_loc: Location, operator_loc: Location, value: Node, name: Symbol, depth: Integer).void }
    def initialize(source, node_id, location, flags, name_loc, operator_loc, value, name, depth); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name_loc: Location, operator_loc: Location, value: Node, name: Symbol, depth: Integer).returns(LocalVariableAndWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil), name: T.unsafe(nil), depth: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the Location represented by `name_loc`.
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Returns the `name` attribute.
    sig { returns(Symbol) }
    def name; end

    # Returns the `depth` attribute.
    sig { returns(Integer) }
    def depth; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents assigning to a local variable using an operator that isn't `=`.
  #
  # ```rb
  # target += value
  # ^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#dGFyZ2V0ICs9IHZhbHVlCg)
  class LocalVariableOperatorWriteNode < Node
    # Initialize a new LocalVariableOperatorWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name_loc: Location, binary_operator_loc: Location, value: Node, name: Symbol, binary_operator: Symbol, depth: Integer).void }
    def initialize(source, node_id, location, flags, name_loc, binary_operator_loc, value, name, binary_operator, depth); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name_loc: Location, binary_operator_loc: Location, value: Node, name: Symbol, binary_operator: Symbol, depth: Integer).returns(LocalVariableOperatorWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name_loc: T.unsafe(nil), binary_operator_loc: T.unsafe(nil), value: T.unsafe(nil), name: T.unsafe(nil), binary_operator: T.unsafe(nil), depth: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the Location represented by `name_loc`.
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `binary_operator_loc`.
    sig { returns(Location) }
    def binary_operator_loc; end

    # Save the binary_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_binary_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Returns the `name` attribute.
    sig { returns(Symbol) }
    def name; end

    # Returns the `binary_operator` attribute.
    sig { returns(Symbol) }
    def binary_operator; end

    # Returns the `depth` attribute.
    sig { returns(Integer) }
    def depth; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `||=` operator for assignment to a local variable.
  #
  # ```rb
  # target ||= value
  # ^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#dGFyZ2V0IHx8PSB2YWx1ZQo)
  class LocalVariableOrWriteNode < Node
    # Initialize a new LocalVariableOrWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name_loc: Location, operator_loc: Location, value: Node, name: Symbol, depth: Integer).void }
    def initialize(source, node_id, location, flags, name_loc, operator_loc, value, name, depth); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name_loc: Location, operator_loc: Location, value: Node, name: Symbol, depth: Integer).returns(LocalVariableOrWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil), name: T.unsafe(nil), depth: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the Location represented by `name_loc`.
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Returns the `name` attribute.
    sig { returns(Symbol) }
    def name; end

    # Returns the `depth` attribute.
    sig { returns(Integer) }
    def depth; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents reading a local variable. Note that this requires that a local variable of the same name has already been written to in the same scope, otherwise it is parsed as a method call.
  #
  # ```rb
  # foo
  # ^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vCg)
  class LocalVariableReadNode < Node
    # Initialize a new LocalVariableReadNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, depth: Integer).void }
    def initialize(source, node_id, location, flags, name, depth); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, depth: Integer).returns(LocalVariableReadNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), depth: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The name of the local variable, which is an [identifier](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#identifiers).
    #
    # ```rb
    # x      # name `:x`
    #
    # _Test  # name `:_Test`
    #
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#eCAgICAgICMgbmFtZSBgOnhgCgpfVGVzdCAgIyBuYW1lIGA6X1Rlc3RgCg)
    # Note that this can also be an underscore followed by a number for the default block parameters.
    #
    # ```rb
    # _1     # name `:_1`
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#XzEgICAgICMgbmFtZSBgOl8xYAo)
    sig { returns(Symbol) }
    def name; end

    # The number of visible scopes that should be searched to find the origin of this local variable.
    #
    # ```rb
    # foo = 1; foo # depth 0
    #
    # bar = 2; tap { bar } # depth 1
    #
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0gMTsgZm9vICMgZGVwdGggMAoKYmFyID0gMjsgdGFwIHsgYmFyIH0gIyBkZXB0aCAxCg)
    # The specific rules for calculating the depth may differ from individual Ruby implementations, as they are not specified by the language. For more information, see [the Prism documentation](https://github.com/ruby/prism/blob/main/docs/local_variable_depth.md).
    sig { returns(Integer) }
    def depth; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing to a local variable in a context that doesn't have an explicit value.
  #
  # ```rb
  # foo, bar = baz
  # ^^^  ^^^
  #
  # foo => baz
  #        ^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vLCBiYXIgPSBiYXoKCmZvbyA9PiBiYXoK)
  class LocalVariableTargetNode < Node
    # Initialize a new LocalVariableTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, depth: Integer).void }
    def initialize(source, node_id, location, flags, name, depth); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, depth: Integer).returns(LocalVariableTargetNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), depth: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `name` attribute.
    sig { returns(Symbol) }
    def name; end

    # Returns the `depth` attribute.
    sig { returns(Integer) }
    def depth; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing to a local variable.
  #
  # ```rb
  # foo = 1
  # ^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0gMQo)
  class LocalVariableWriteNode < Node
    # Initialize a new LocalVariableWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, depth: Integer, name_loc: Location, value: Node, operator_loc: Location).void }
    def initialize(source, node_id, location, flags, name, depth, name_loc, value, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, depth: Integer, name_loc: Location, value: Node, operator_loc: Location).returns(LocalVariableWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), depth: T.unsafe(nil), name_loc: T.unsafe(nil), value: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The name of the local variable, which is an [identifier](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#identifiers).
    #
    # ```rb
    # foo = :bar # name `:foo`
    #
    # abc = 123  # name `:abc`
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0gOmJhciAjIG5hbWUgYDpmb29gCgphYmMgPSAxMjMgICMgbmFtZSBgOmFiY2AK)
    sig { returns(Symbol) }
    def name; end

    # The number of semantic scopes we have to traverse to find the declaration of this variable.
    #
    # ```rb
    # foo = 1         # depth 0
    #
    # tap { foo = 1 } # depth 1
    #
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0gMSAgICAgICAgICMgZGVwdGggMAoKdGFwIHsgZm9vID0gMSB9ICMgZGVwdGggMQo)
    # The specific rules for calculating the depth may differ from individual Ruby implementations, as they are not specified by the language. For more information, see [the Prism documentation](https://github.com/ruby/prism/blob/main/docs/local_variable_depth.md).
    sig { returns(Integer) }
    def depth; end

    # The Location of the variable name.
    #
    # ```rb
    # foo = :bar
    # ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0gOmJhcgo)
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # The value to write to the local variable. It can be any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # foo = :bar
    #       ^^^^
    #
    # abc = 1234
    #       ^^^^
    #
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0gOmJhcgoKYWJjID0gMTIzNAo)
    # Note that since the name of a local variable is known before the value is parsed, it is valid for a local variable to appear within the value of its own write.
    #
    # ```rb
    # foo = foo
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0gZm9vCg)
    sig { returns(Node) }
    def value; end

    # The Location of the `=` operator.
    #
    # ```rb
    # x = :y
    #   ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#eCA9IDp5Cg)
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a regular expression literal used in the predicate of a conditional to implicitly match against the last line read by an IO object.
  #
  # ```rb
  # if /foo/i then end
  #    ^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#aWYgL2Zvby9pIHRoZW4gZW5kCg)
  class MatchLastLineNode < Node
    # Initialize a new MatchLastLineNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: Location, content_loc: Location, closing_loc: Location, unescaped: String).void }
    def initialize(source, node_id, location, flags, opening_loc, content_loc, closing_loc, unescaped); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, opening_loc: Location, content_loc: Location, closing_loc: Location, unescaped: String).returns(MatchLastLineNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), content_loc: T.unsafe(nil), closing_loc: T.unsafe(nil), unescaped: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # i - ignores the case of characters when matching
    sig { returns(T::Boolean) }
    def ignore_case?; end

    # x - ignores whitespace and allows comments in regular expressions
    sig { returns(T::Boolean) }
    def extended?; end

    # m - allows $ to match the end of lines within strings
    sig { returns(T::Boolean) }
    def multi_line?; end

    # o - only interpolates values into the regular expression once
    sig { returns(T::Boolean) }
    def once?; end

    # e - forces the EUC-JP encoding
    sig { returns(T::Boolean) }
    def euc_jp?; end

    # n - forces the ASCII-8BIT encoding
    sig { returns(T::Boolean) }
    def ascii_8bit?; end

    # s - forces the Windows-31J encoding
    sig { returns(T::Boolean) }
    def windows_31j?; end

    # u - forces the UTF-8 encoding
    sig { returns(T::Boolean) }
    def utf_8?; end

    # internal bytes forced the encoding to UTF-8
    sig { returns(T::Boolean) }
    def forced_utf8_encoding?; end

    # internal bytes forced the encoding to binary
    sig { returns(T::Boolean) }
    def forced_binary_encoding?; end

    # internal bytes forced the encoding to US-ASCII
    sig { returns(T::Boolean) }
    def forced_us_ascii_encoding?; end

    # Returns the Location represented by `opening_loc`.
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the Location represented by `content_loc`.
    sig { returns(Location) }
    def content_loc; end

    # Save the content_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_content_loc(repository); end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Returns the `unescaped` attribute.
    sig { returns(String) }
    def unescaped; end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of content_loc from the source.
    sig { returns(String) }
    def content; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the modifier `in` operator.
  #
  # ```rb
  # foo in bar
  # ^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIGluIGJhcgo)
  class MatchPredicateNode < Node
    # Initialize a new MatchPredicateNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, value: Node, pattern: Node, keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, value, pattern, keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, value: Node, pattern: Node, keyword_loc: Location).returns(MatchPredicateNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), value: T.unsafe(nil), pattern: T.unsafe(nil), keyword_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Returns the `pattern` attribute.
    sig { returns(Node) }
    def pattern; end

    # Returns the Location represented by `keyword_loc`.
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `=>` operator.
  #
  # ```rb
  # foo => bar
  # ^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0-IGJhcgo)
  class MatchRequiredNode < Node
    # Initialize a new MatchRequiredNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, value: Node, pattern: Node, operator_loc: Location).void }
    def initialize(source, node_id, location, flags, value, pattern, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, value: Node, pattern: Node, operator_loc: Location).returns(MatchRequiredNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), value: T.unsafe(nil), pattern: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Represents the left-hand side of the operator.
    #
    # ```rb
    # foo => bar
    # ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0-IGJhcgo)
    sig { returns(Node) }
    def value; end

    # Represents the right-hand side of the operator. The type of the node depends on the expression.
    #
    # Anything that looks like a local variable name (including `_`) will result in a `LocalVariableTargetNode`.
    #
    # ```rb
    # foo => a # This is equivalent to writing `a = foo`
    #        ^
    #
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0-IGEgIyBUaGlzIGlzIGVxdWl2YWxlbnQgdG8gd3JpdGluZyBgYSA9IGZvb2AK)
    # Using an explicit `Array` or combining expressions with `,` will result in a `ArrayPatternNode`. This can be preceded by a constant.
    #
    # ```rb
    # foo => [a]
    #        ^^^
    #
    # foo => a, b
    #        ^^^^
    #
    # foo => Bar[a, b]
    #        ^^^^^^^^^
    #
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0-IFthXQoKZm9vID0-IGEsIGIKCmZvbyA9PiBCYXJbYSwgYl0K)
    # If the array pattern contains at least two wildcard matches, a `FindPatternNode` is created instead.
    #
    # ```rb
    # foo => *, 1, *a
    #        ^^^^^
    #
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0-ICosIDEsICphCg)
    # Using an explicit `Hash` or a constant with square brackets and hash keys in the square brackets will result in a `HashPatternNode`.
    #
    # ```rb
    # foo => { a: 1, b: }
    #
    # foo => Bar[a: 1, b:]
    #
    # foo => Bar[**]
    #
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0-IHsgYTogMSwgYjogfQoKZm9vID0-IEJhclthOiAxLCBiOl0KCmZvbyA9PiBCYXJbKipdCg)
    # To use any variable that needs run time evaluation, pinning is required. This results in a `PinnedVariableNode`
    #
    # ```rb
    # foo => ^a
    #        ^^
    #
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0-IF5hCg)
    # Similar, any expression can be used with pinning. This results in a `PinnedExpressionNode`.
    #
    # ```rb
    # foo => ^(a + 1)
    #
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0-IF4oYSArIDEpCg)
    # Anything else will result in the regular node for that expression, for example a `ConstantReadNode`.
    #
    # ```rb
    # foo => CONST
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0-IENPTlNUCg)
    sig { returns(Node) }
    def pattern; end

    # The Location of the operator.
    #
    # ```rb
    # foo => bar
    #     ^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vID0-IGJhcgo)
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing local variables using a regular expression match with named capture groups.
  #
  # ```rb
  # /(?<foo>bar)/ =~ baz
  # ^^^^^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Lyg_PGZvbz5iYXIpLyA9fiBiYXoK)
  class MatchWriteNode < Node
    # Initialize a new MatchWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, call: CallNode, targets: T::Array[LocalVariableTargetNode]).void }
    def initialize(source, node_id, location, flags, call, targets); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, call: CallNode, targets: T::Array[LocalVariableTargetNode]).returns(MatchWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), call: T.unsafe(nil), targets: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `call` attribute.
    sig { returns(CallNode) }
    def call; end

    # Returns the `targets` attribute.
    sig { returns(T::Array[LocalVariableTargetNode]) }
    def targets; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a module declaration involving the `module` keyword.
  #
  # ```rb
  # module Foo end
  # ^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#bW9kdWxlIEZvbyBlbmQK)
  class ModuleNode < Node
    # Initialize a new ModuleNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], module_keyword_loc: Location, constant_path: ::T.any(ConstantReadNode, ConstantPathNode), body: ::T.nilable(::T.any(StatementsNode, BeginNode)), end_keyword_loc: Location, name: Symbol).void }
    def initialize(source, node_id, location, flags, locals, module_keyword_loc, constant_path, body, end_keyword_loc, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], module_keyword_loc: Location, constant_path: ::T.any(ConstantReadNode, ConstantPathNode), body: ::T.nilable(::T.any(StatementsNode, BeginNode)), end_keyword_loc: Location, name: Symbol).returns(ModuleNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), locals: T.unsafe(nil), module_keyword_loc: T.unsafe(nil), constant_path: T.unsafe(nil), body: T.unsafe(nil), end_keyword_loc: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `locals` attribute.
    sig { returns(T::Array[Symbol]) }
    def locals; end

    # Returns the Location represented by `module_keyword_loc`.
    sig { returns(Location) }
    def module_keyword_loc; end

    # Save the module_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_module_keyword_loc(repository); end

    # Returns the `constant_path` attribute.
    sig { returns(::T.any(ConstantReadNode, ConstantPathNode)) }
    def constant_path; end

    # Returns the `body` attribute.
    sig { returns(::T.nilable(::T.any(StatementsNode, BeginNode))) }
    def body; end

    # Returns the Location represented by `end_keyword_loc`.
    sig { returns(Location) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_end_keyword_loc(repository); end

    # Returns the `name` attribute.
    sig { returns(Symbol) }
    def name; end

    # Slice the location of module_keyword_loc from the source.
    sig { returns(String) }
    def module_keyword; end

    # Slice the location of end_keyword_loc from the source.
    sig { returns(String) }
    def end_keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a multi-target expression.
  #
  # ```rb
  # a, (b, c) = 1, 2, 3
  #    ^^^^^^
  #
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#YSwgKGIsIGMpID0gMSwgMiwgMwo)
  # This can be a part of `MultiWriteNode` as above, or the target of a `for` loop
  #
  # ```rb
  # for a, b in [[1, 2], [3, 4]]
  #     ^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9yIGEsIGIgaW4gW1sxLCAyXSwgWzMsIDRdXQo)
  class MultiTargetNode < Node
    # Initialize a new MultiTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, lefts: T::Array[::T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, RequiredParameterNode)], rest: ::T.nilable(::T.any(ImplicitRestNode, SplatNode)), rights: T::Array[::T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, RequiredParameterNode)], lparen_loc: ::T.nilable(Location), rparen_loc: ::T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, lefts, rest, rights, lparen_loc, rparen_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, lefts: T::Array[::T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, RequiredParameterNode)], rest: ::T.nilable(::T.any(ImplicitRestNode, SplatNode)), rights: T::Array[::T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, RequiredParameterNode)], lparen_loc: ::T.nilable(Location), rparen_loc: ::T.nilable(Location)).returns(MultiTargetNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), lefts: T.unsafe(nil), rest: T.unsafe(nil), rights: T.unsafe(nil), lparen_loc: T.unsafe(nil), rparen_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Represents the targets expressions before a splat node.
    #
    # ```rb
    # a, (b, c, *) = 1, 2, 3, 4, 5
    #     ^^^^
    #
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YSwgKGIsIGMsICopID0gMSwgMiwgMywgNCwgNQo)
    # The splat node can be absent, in that case all target expressions are in the left field.
    #
    # ```rb
    # a, (b, c) = 1, 2, 3, 4, 5
    #     ^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YSwgKGIsIGMpID0gMSwgMiwgMywgNCwgNQo)
    sig { returns(T::Array[::T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, RequiredParameterNode)]) }
    def lefts; end

    # Represents a splat node in the target expression.
    #
    # ```rb
    # a, (b, *c) = 1, 2, 3, 4
    #        ^^
    #
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YSwgKGIsICpjKSA9IDEsIDIsIDMsIDQK)
    # The variable can be empty, this results in a `SplatNode` with a `nil` expression field.
    #
    # ```rb
    # a, (b, *) = 1, 2, 3, 4
    #        ^
    #
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YSwgKGIsICopID0gMSwgMiwgMywgNAo)
    # If the `*` is omitted, this field will contain an `ImplicitRestNode`
    #
    # ```rb
    # a, (b,) = 1, 2, 3, 4
    #      ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YSwgKGIsKSA9IDEsIDIsIDMsIDQK)
    sig { returns(::T.nilable(::T.any(ImplicitRestNode, SplatNode))) }
    def rest; end

    # Represents the targets expressions after a splat node.
    #
    # ```rb
    # a, (*, b, c) = 1, 2, 3, 4, 5
    #        ^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YSwgKCosIGIsIGMpID0gMSwgMiwgMywgNCwgNQo)
    sig { returns(T::Array[::T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, RequiredParameterNode)]) }
    def rights; end

    # The Location of the opening parenthesis.
    #
    # ```rb
    # a, (b, c) = 1, 2, 3
    #    ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YSwgKGIsIGMpID0gMSwgMiwgMwo)
    sig { returns(::T.nilable(Location)) }
    def lparen_loc; end

    # Save the lparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_lparen_loc(repository); end

    # The Location of the closing parenthesis.
    #
    # ```rb
    # a, (b, c) = 1, 2, 3
    #         ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YSwgKGIsIGMpID0gMSwgMiwgMwo)
    sig { returns(::T.nilable(Location)) }
    def rparen_loc; end

    # Save the rparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_rparen_loc(repository); end

    # Slice the location of lparen_loc from the source.
    sig { returns(::T.nilable(String)) }
    def lparen; end

    # Slice the location of rparen_loc from the source.
    sig { returns(::T.nilable(String)) }
    def rparen; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a write to a multi-target expression.
  #
  # ```rb
  # a, b, c = 1, 2, 3
  # ^^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#YSwgYiwgYyA9IDEsIDIsIDMK)
  class MultiWriteNode < Node
    # Initialize a new MultiWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, lefts: T::Array[::T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode)], rest: ::T.nilable(::T.any(ImplicitRestNode, SplatNode)), rights: T::Array[::T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode)], lparen_loc: ::T.nilable(Location), rparen_loc: ::T.nilable(Location), operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, lefts, rest, rights, lparen_loc, rparen_loc, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, lefts: T::Array[::T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode)], rest: ::T.nilable(::T.any(ImplicitRestNode, SplatNode)), rights: T::Array[::T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode)], lparen_loc: ::T.nilable(Location), rparen_loc: ::T.nilable(Location), operator_loc: Location, value: Node).returns(MultiWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), lefts: T.unsafe(nil), rest: T.unsafe(nil), rights: T.unsafe(nil), lparen_loc: T.unsafe(nil), rparen_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Represents the targets expressions before a splat node.
    #
    # ```rb
    # a, b, * = 1, 2, 3, 4, 5
    # ^^^^
    #
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YSwgYiwgKiA9IDEsIDIsIDMsIDQsIDUK)
    # The splat node can be absent, in that case all target expressions are in the left field.
    #
    # ```rb
    # a, b, c = 1, 2, 3, 4, 5
    # ^^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YSwgYiwgYyA9IDEsIDIsIDMsIDQsIDUK)
    sig { returns(T::Array[::T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode)]) }
    def lefts; end

    # Represents a splat node in the target expression.
    #
    # ```rb
    # a, b, *c = 1, 2, 3, 4
    #       ^^
    #
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YSwgYiwgKmMgPSAxLCAyLCAzLCA0Cg)
    # The variable can be empty, this results in a `SplatNode` with a `nil` expression field.
    #
    # ```rb
    # a, b, * = 1, 2, 3, 4
    #       ^
    #
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YSwgYiwgKiA9IDEsIDIsIDMsIDQK)
    # If the `*` is omitted, this field will contain an `ImplicitRestNode`
    #
    # ```rb
    # a, b, = 1, 2, 3, 4
    #     ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YSwgYiwgPSAxLCAyLCAzLCA0Cg)
    sig { returns(::T.nilable(::T.any(ImplicitRestNode, SplatNode))) }
    def rest; end

    # Represents the targets expressions after a splat node.
    #
    # ```rb
    # a, *, b, c = 1, 2, 3, 4, 5
    #       ^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YSwgKiwgYiwgYyA9IDEsIDIsIDMsIDQsIDUK)
    sig { returns(T::Array[::T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode)]) }
    def rights; end

    # The Location of the opening parenthesis.
    #
    # ```rb
    # (a, b, c) = 1, 2, 3
    # ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#KGEsIGIsIGMpID0gMSwgMiwgMwo)
    sig { returns(::T.nilable(Location)) }
    def lparen_loc; end

    # Save the lparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_lparen_loc(repository); end

    # The Location of the closing parenthesis.
    #
    # ```rb
    # (a, b, c) = 1, 2, 3
    #         ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#KGEsIGIsIGMpID0gMSwgMiwgMwo)
    sig { returns(::T.nilable(Location)) }
    def rparen_loc; end

    # Save the rparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_rparen_loc(repository); end

    # The Location of the operator.
    #
    # ```rb
    # a, b, c = 1, 2, 3
    #         ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YSwgYiwgYyA9IDEsIDIsIDMK)
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # The value to write to the targets. It can be any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # a, b, c = 1, 2, 3
    #           ^^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#YSwgYiwgYyA9IDEsIDIsIDMK)
    sig { returns(Node) }
    def value; end

    # Slice the location of lparen_loc from the source.
    sig { returns(::T.nilable(String)) }
    def lparen; end

    # Slice the location of rparen_loc from the source.
    sig { returns(::T.nilable(String)) }
    def rparen; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `next` keyword.
  #
  # ```rb
  # next 1
  # ^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#bmV4dCAxCg)
  class NextNode < Node
    # Initialize a new NextNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, arguments: ::T.nilable(ArgumentsNode), keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, arguments, keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, arguments: ::T.nilable(ArgumentsNode), keyword_loc: Location).returns(NextNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), arguments: T.unsafe(nil), keyword_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `arguments` attribute.
    sig { returns(::T.nilable(ArgumentsNode)) }
    def arguments; end

    # Returns the Location represented by `keyword_loc`.
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `nil` keyword.
  #
  # ```rb
  # nil
  # ^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#bmlsCg)
  class NilNode < Node
    # Initialize a new NilNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(NilNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of `&nil` inside method arguments.
  #
  # ```rb
  # def a(&nil)
  #       ^^^^
  # end
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#ZGVmIGEoJm5pbCkKCmVuZAo)
  class NoBlockParameterNode < Node
    # Initialize a new NoBlockParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, operator_loc: Location, keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, operator_loc, keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, operator_loc: Location, keyword_loc: Location).returns(NoBlockParameterNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), operator_loc: T.unsafe(nil), keyword_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the Location represented by `keyword_loc`.
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of `**nil` inside method arguments.
  #
  # ```rb
  # def a(**nil)
  #       ^^^^^
  # end
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#ZGVmIGEoKipuaWwpCgplbmQK)
  class NoKeywordsParameterNode < Node
    # Initialize a new NoKeywordsParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, operator_loc: Location, keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, operator_loc, keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, operator_loc: Location, keyword_loc: Location).returns(NoKeywordsParameterNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), operator_loc: T.unsafe(nil), keyword_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the Location represented by `keyword_loc`.
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an implicit set of parameters through the use of numbered parameters within a block or lambda.
  #
  # ```rb
  # -> { _1 + _2 }
  # ^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#LT4geyBfMSArIF8yIH0K)
  class NumberedParametersNode < Node
    # Initialize a new NumberedParametersNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, maximum: Integer).void }
    def initialize(source, node_id, location, flags, maximum); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, maximum: Integer).returns(NumberedParametersNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), maximum: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `maximum` attribute.
    sig { returns(Integer) }
    def maximum; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents reading a numbered reference to a capture in the previous match.
  #
  # ```rb
  # $1
  # ^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#JDEK)
  class NumberedReferenceReadNode < Node
    # Initialize a new NumberedReferenceReadNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, number: Integer).void }
    def initialize(source, node_id, location, flags, number); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, number: Integer).returns(NumberedReferenceReadNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), number: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The (1-indexed, from the left) number of the capture group. Numbered references that are too large result in this value being `0`.
    #
    # ```rb
    # $1          # number `1`
    #
    # $5432       # number `5432`
    #
    # $4294967296 # number `0`
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#JDEgICAgICAgICAgIyBudW1iZXIgYDFgCgokNTQzMiAgICAgICAjIG51bWJlciBgNTQzMmAKCiQ0Mjk0OTY3Mjk2ICMgbnVtYmVyIGAwYAo)
    sig { returns(Integer) }
    def number; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an optional keyword parameter to a method, block, or lambda definition.
  #
  # ```rb
  # def a(b: 1)
  #       ^^^^
  # end
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#ZGVmIGEoYjogMSkKCmVuZAo)
  class OptionalKeywordParameterNode < Node
    # Initialize a new OptionalKeywordParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, name, name_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, value: Node).returns(OptionalKeywordParameterNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # a parameter name that has been repeated in the method signature
    sig { returns(T::Boolean) }
    def repeated_parameter?; end

    # Returns the `name` attribute.
    sig { returns(Symbol) }
    def name; end

    # Returns the Location represented by `name_loc`.
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an optional parameter to a method, block, or lambda definition.
  #
  # ```rb
  # def a(b = 1)
  #       ^^^^^
  # end
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#ZGVmIGEoYiA9IDEpCgplbmQK)
  class OptionalParameterNode < Node
    # Initialize a new OptionalParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, name, name_loc, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(OptionalParameterNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # a parameter name that has been repeated in the method signature
    sig { returns(T::Boolean) }
    def repeated_parameter?; end

    # Returns the `name` attribute.
    sig { returns(Symbol) }
    def name; end

    # Returns the Location represented by `name_loc`.
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `||` operator or the `or` keyword.
  #
  # ```rb
  # left or right
  # ^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#bGVmdCBvciByaWdodAo)
  class OrNode < Node
    # Initialize a new OrNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, left: Node, right: Node, operator_loc: Location).void }
    def initialize(source, node_id, location, flags, left, right, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, left: Node, right: Node, operator_loc: Location).returns(OrNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), left: T.unsafe(nil), right: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Represents the left side of the expression. It can be any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # left or right
    # ^^^^
    #
    # 1 || 2
    # ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#bGVmdCBvciByaWdodAoKMSB8fCAyCg)
    sig { returns(Node) }
    def left; end

    # Represents the right side of the expression.
    #
    # ```rb
    # left || right
    #         ^^^^^
    #
    # 1 or 2
    #      ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#bGVmdCB8fCByaWdodAoKMSBvciAyCg)
    sig { returns(Node) }
    def right; end

    # The Location of the `or` keyword or the `||` operator.
    #
    # ```rb
    # left or right
    #      ^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#bGVmdCBvciByaWdodAo)
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the list of parameters on a method, block, or lambda definition.
  #
  # ```rb
  # def a(b, c, d)
  #       ^^^^^^^
  # end
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#ZGVmIGEoYiwgYywgZCkKCmVuZAo)
  class ParametersNode < Node
    # Initialize a new ParametersNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, requireds: T::Array[::T.any(RequiredParameterNode, MultiTargetNode)], optionals: T::Array[OptionalParameterNode], rest: ::T.nilable(::T.any(RestParameterNode, ImplicitRestNode)), posts: T::Array[::T.any(RequiredParameterNode, MultiTargetNode)], keywords: T::Array[::T.any(RequiredKeywordParameterNode, OptionalKeywordParameterNode)], keyword_rest: ::T.nilable(::T.any(KeywordRestParameterNode, ForwardingParameterNode, NoKeywordsParameterNode)), block: ::T.nilable(::T.any(BlockParameterNode, NoBlockParameterNode))).void }
    def initialize(source, node_id, location, flags, requireds, optionals, rest, posts, keywords, keyword_rest, block); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, requireds: T::Array[::T.any(RequiredParameterNode, MultiTargetNode)], optionals: T::Array[OptionalParameterNode], rest: ::T.nilable(::T.any(RestParameterNode, ImplicitRestNode)), posts: T::Array[::T.any(RequiredParameterNode, MultiTargetNode)], keywords: T::Array[::T.any(RequiredKeywordParameterNode, OptionalKeywordParameterNode)], keyword_rest: ::T.nilable(::T.any(KeywordRestParameterNode, ForwardingParameterNode, NoKeywordsParameterNode)), block: ::T.nilable(::T.any(BlockParameterNode, NoBlockParameterNode))).returns(ParametersNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), requireds: T.unsafe(nil), optionals: T.unsafe(nil), rest: T.unsafe(nil), posts: T.unsafe(nil), keywords: T.unsafe(nil), keyword_rest: T.unsafe(nil), block: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `requireds` attribute.
    sig { returns(T::Array[::T.any(RequiredParameterNode, MultiTargetNode)]) }
    def requireds; end

    # Returns the `optionals` attribute.
    sig { returns(T::Array[OptionalParameterNode]) }
    def optionals; end

    # Returns the `rest` attribute.
    sig { returns(::T.nilable(::T.any(RestParameterNode, ImplicitRestNode))) }
    def rest; end

    # Returns the `posts` attribute.
    sig { returns(T::Array[::T.any(RequiredParameterNode, MultiTargetNode)]) }
    def posts; end

    # Returns the `keywords` attribute.
    sig { returns(T::Array[::T.any(RequiredKeywordParameterNode, OptionalKeywordParameterNode)]) }
    def keywords; end

    # Returns the `keyword_rest` attribute.
    sig { returns(::T.nilable(::T.any(KeywordRestParameterNode, ForwardingParameterNode, NoKeywordsParameterNode))) }
    def keyword_rest; end

    # Returns the `block` attribute.
    sig { returns(::T.nilable(::T.any(BlockParameterNode, NoBlockParameterNode))) }
    def block; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a parenthesized expression
  #
  # ```rb
  # (10 + 34)
  # ^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#KDEwICsgMzQpCg)
  class ParenthesesNode < Node
    # Initialize a new ParenthesesNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, body: ::T.nilable(Node), opening_loc: Location, closing_loc: Location).void }
    def initialize(source, node_id, location, flags, body, opening_loc, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, body: ::T.nilable(Node), opening_loc: Location, closing_loc: Location).returns(ParenthesesNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), body: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # parentheses that contain multiple potentially void statements
    sig { returns(T::Boolean) }
    def multiple_statements?; end

    # Returns the `body` attribute.
    sig { returns(::T.nilable(Node)) }
    def body; end

    # Returns the Location represented by `opening_loc`.
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `^` operator for pinning an expression in a pattern matching expression.
  #
  # ```rb
  # foo in ^(bar)
  #        ^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIGluIF4oYmFyKQo)
  class PinnedExpressionNode < Node
    # Initialize a new PinnedExpressionNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, expression: Node, operator_loc: Location, lparen_loc: Location, rparen_loc: Location).void }
    def initialize(source, node_id, location, flags, expression, operator_loc, lparen_loc, rparen_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, expression: Node, operator_loc: Location, lparen_loc: Location, rparen_loc: Location).returns(PinnedExpressionNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), expression: T.unsafe(nil), operator_loc: T.unsafe(nil), lparen_loc: T.unsafe(nil), rparen_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The expression used in the pinned expression
    #
    # ```rb
    # foo in ^(bar)
    #          ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIGluIF4oYmFyKQo)
    sig { returns(Node) }
    def expression; end

    # The Location of the `^` operator
    #
    # ```rb
    # foo in ^(bar)
    #        ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIGluIF4oYmFyKQo)
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # The Location of the opening parenthesis.
    #
    # ```rb
    # foo in ^(bar)
    #         ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIGluIF4oYmFyKQo)
    sig { returns(Location) }
    def lparen_loc; end

    # Save the lparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_lparen_loc(repository); end

    # The Location of the closing parenthesis.
    #
    # ```rb
    # foo in ^(bar)
    #             ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIGluIF4oYmFyKQo)
    sig { returns(Location) }
    def rparen_loc; end

    # Save the rparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_rparen_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    # Slice the location of lparen_loc from the source.
    sig { returns(String) }
    def lparen; end

    # Slice the location of rparen_loc from the source.
    sig { returns(String) }
    def rparen; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `^` operator for pinning a variable in a pattern matching expression.
  #
  # ```rb
  # foo in ^bar
  #        ^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIGluIF5iYXIK)
  class PinnedVariableNode < Node
    # Initialize a new PinnedVariableNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, variable: ::T.any(LocalVariableReadNode, InstanceVariableReadNode, ClassVariableReadNode, GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode, ItLocalVariableReadNode), operator_loc: Location).void }
    def initialize(source, node_id, location, flags, variable, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, variable: ::T.any(LocalVariableReadNode, InstanceVariableReadNode, ClassVariableReadNode, GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode, ItLocalVariableReadNode), operator_loc: Location).returns(PinnedVariableNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), variable: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The variable used in the pinned expression
    #
    # ```rb
    # foo in ^bar
    #         ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIGluIF5iYXIK)
    sig { returns(::T.any(LocalVariableReadNode, InstanceVariableReadNode, ClassVariableReadNode, GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode, ItLocalVariableReadNode)) }
    def variable; end

    # The Location of the `^` operator
    #
    # ```rb
    # foo in ^bar
    #        ^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIGluIF5iYXIK)
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `END` keyword.
  #
  # ```rb
  # END { foo }
  # ^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#RU5EIHsgZm9vIH0K)
  class PostExecutionNode < Node
    # Initialize a new PostExecutionNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, statements: ::T.nilable(StatementsNode), keyword_loc: Location, opening_loc: Location, closing_loc: Location).void }
    def initialize(source, node_id, location, flags, statements, keyword_loc, opening_loc, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, statements: ::T.nilable(StatementsNode), keyword_loc: Location, opening_loc: Location, closing_loc: Location).returns(PostExecutionNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), statements: T.unsafe(nil), keyword_loc: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `statements` attribute.
    sig { returns(::T.nilable(StatementsNode)) }
    def statements; end

    # Returns the Location represented by `keyword_loc`.
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Returns the Location represented by `opening_loc`.
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `BEGIN` keyword.
  #
  # ```rb
  # BEGIN { foo }
  # ^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#QkVHSU4geyBmb28gfQo)
  class PreExecutionNode < Node
    # Initialize a new PreExecutionNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, statements: ::T.nilable(StatementsNode), keyword_loc: Location, opening_loc: Location, closing_loc: Location).void }
    def initialize(source, node_id, location, flags, statements, keyword_loc, opening_loc, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, statements: ::T.nilable(StatementsNode), keyword_loc: Location, opening_loc: Location, closing_loc: Location).returns(PreExecutionNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), statements: T.unsafe(nil), keyword_loc: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `statements` attribute.
    sig { returns(::T.nilable(StatementsNode)) }
    def statements; end

    # Returns the Location represented by `keyword_loc`.
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Returns the Location represented by `opening_loc`.
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # The top level node of any parse tree.
  class ProgramNode < Node
    # Initialize a new ProgramNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], statements: StatementsNode).void }
    def initialize(source, node_id, location, flags, locals, statements); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], statements: StatementsNode).returns(ProgramNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), locals: T.unsafe(nil), statements: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `locals` attribute.
    sig { returns(T::Array[Symbol]) }
    def locals; end

    # Returns the `statements` attribute.
    sig { returns(StatementsNode) }
    def statements; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `..` or `...` operators.
  #
  # ```rb
  # 1..2
  # ^^^^
  #
  # c if a =~ /left/ ... b =~ /right/
  #      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#MS4uMgoKYyBpZiBhID1-IC9sZWZ0LyAuLi4gYiA9fiAvcmlnaHQvCg)
  class RangeNode < Node
    # Initialize a new RangeNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, left: ::T.nilable(Node), right: ::T.nilable(Node), operator_loc: Location).void }
    def initialize(source, node_id, location, flags, left, right, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, left: ::T.nilable(Node), right: ::T.nilable(Node), operator_loc: Location).returns(RangeNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), left: T.unsafe(nil), right: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # ... operator
    sig { returns(T::Boolean) }
    def exclude_end?; end

    # The left-hand side of the range, if present. It can be either `nil` or any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # 1...
    # ^
    #
    # hello...goodbye
    # ^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#MS4uLgoKaGVsbG8uLi5nb29kYnllCg)
    sig { returns(::T.nilable(Node)) }
    def left; end

    # The right-hand side of the range, if present. It can be either `nil` or any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # ..5
    #   ^
    #
    # 1...foo
    #     ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#Li41CgoxLi4uZm9vCg)
    # If neither right-hand or left-hand side was included, this will be an ErrorRecoveryNode.
    sig { returns(::T.nilable(Node)) }
    def right; end

    # The Location of the `..` or `...` operator.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a rational number literal.
  #
  # ```rb
  # 1.0r
  # ^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#MS4wcgo)
  class RationalNode < Node
    # Initialize a new RationalNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, numerator: Integer, denominator: Integer).void }
    def initialize(source, node_id, location, flags, numerator, denominator); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, numerator: Integer, denominator: Integer).returns(RationalNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), numerator: T.unsafe(nil), denominator: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # 0b prefix
    sig { returns(T::Boolean) }
    def binary?; end

    # 0d or no prefix
    sig { returns(T::Boolean) }
    def decimal?; end

    # 0o or 0 prefix
    sig { returns(T::Boolean) }
    def octal?; end

    # 0x prefix
    sig { returns(T::Boolean) }
    def hexadecimal?; end

    # The numerator of the rational number.
    #
    # ```rb
    # 1.5r # numerator 3
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#MS41ciAjIG51bWVyYXRvciAzCg)
    sig { returns(Integer) }
    def numerator; end

    # The denominator of the rational number.
    #
    # ```rb
    # 1.5r # denominator 2
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#MS41ciAjIGRlbm9taW5hdG9yIDIK)
    sig { returns(Integer) }
    def denominator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `redo` keyword.
  #
  # ```rb
  # redo
  # ^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#cmVkbwo)
  class RedoNode < Node
    # Initialize a new RedoNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(RedoNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a regular expression literal with no interpolation.
  #
  # ```rb
  # /foo/i
  # ^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#L2Zvby9pCg)
  class RegularExpressionNode < Node
    # Initialize a new RegularExpressionNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: Location, content_loc: Location, closing_loc: Location, unescaped: String).void }
    def initialize(source, node_id, location, flags, opening_loc, content_loc, closing_loc, unescaped); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, opening_loc: Location, content_loc: Location, closing_loc: Location, unescaped: String).returns(RegularExpressionNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), content_loc: T.unsafe(nil), closing_loc: T.unsafe(nil), unescaped: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # i - ignores the case of characters when matching
    sig { returns(T::Boolean) }
    def ignore_case?; end

    # x - ignores whitespace and allows comments in regular expressions
    sig { returns(T::Boolean) }
    def extended?; end

    # m - allows $ to match the end of lines within strings
    sig { returns(T::Boolean) }
    def multi_line?; end

    # o - only interpolates values into the regular expression once
    sig { returns(T::Boolean) }
    def once?; end

    # e - forces the EUC-JP encoding
    sig { returns(T::Boolean) }
    def euc_jp?; end

    # n - forces the ASCII-8BIT encoding
    sig { returns(T::Boolean) }
    def ascii_8bit?; end

    # s - forces the Windows-31J encoding
    sig { returns(T::Boolean) }
    def windows_31j?; end

    # u - forces the UTF-8 encoding
    sig { returns(T::Boolean) }
    def utf_8?; end

    # internal bytes forced the encoding to UTF-8
    sig { returns(T::Boolean) }
    def forced_utf8_encoding?; end

    # internal bytes forced the encoding to binary
    sig { returns(T::Boolean) }
    def forced_binary_encoding?; end

    # internal bytes forced the encoding to US-ASCII
    sig { returns(T::Boolean) }
    def forced_us_ascii_encoding?; end

    # Returns the Location represented by `opening_loc`.
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the Location represented by `content_loc`.
    sig { returns(Location) }
    def content_loc; end

    # Save the content_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_content_loc(repository); end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Returns the `unescaped` attribute.
    sig { returns(String) }
    def unescaped; end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of content_loc from the source.
    sig { returns(String) }
    def content; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a required keyword parameter to a method, block, or lambda definition.
  #
  # ```rb
  # def a(b: )
  #       ^^
  # end
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#ZGVmIGEoYjogKQoKZW5kCg)
  class RequiredKeywordParameterNode < Node
    # Initialize a new RequiredKeywordParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location).void }
    def initialize(source, node_id, location, flags, name, name_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location).returns(RequiredKeywordParameterNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # a parameter name that has been repeated in the method signature
    sig { returns(T::Boolean) }
    def repeated_parameter?; end

    # Returns the `name` attribute.
    sig { returns(Symbol) }
    def name; end

    # Returns the Location represented by `name_loc`.
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a required parameter to a method, block, or lambda definition.
  #
  # ```rb
  # def a(b)
  #       ^
  # end
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#ZGVmIGEoYikKCmVuZAo)
  class RequiredParameterNode < Node
    # Initialize a new RequiredParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).void }
    def initialize(source, node_id, location, flags, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(RequiredParameterNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # a parameter name that has been repeated in the method signature
    sig { returns(T::Boolean) }
    def repeated_parameter?; end

    # Returns the `name` attribute.
    sig { returns(Symbol) }
    def name; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an expression modified with a rescue.
  #
  # ```rb
  # foo rescue nil
  # ^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vIHJlc2N1ZSBuaWwK)
  class RescueModifierNode < Node
    # Initialize a new RescueModifierNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, expression: Node, keyword_loc: Location, rescue_expression: Node).void }
    def initialize(source, node_id, location, flags, expression, keyword_loc, rescue_expression); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, expression: Node, keyword_loc: Location, rescue_expression: Node).returns(RescueModifierNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), expression: T.unsafe(nil), keyword_loc: T.unsafe(nil), rescue_expression: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `expression` attribute.
    sig { returns(Node) }
    def expression; end

    # Returns the Location represented by `keyword_loc`.
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Returns the `rescue_expression` attribute.
    sig { returns(Node) }
    def rescue_expression; end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a rescue statement.
  #
  # ```rb
  # begin
  # rescue Foo, *splat, Bar => ex
  #   foo
  # ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  # end
  #
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#YmVnaW4KcmVzY3VlIEZvbywgKnNwbGF0LCBCYXIgPT4gZXgKICBmb28KCmVuZAo)
  # `Foo, *splat, Bar` are in the `exceptions` field. `ex` is in the `reference` field.
  class RescueNode < Node
    # Initialize a new RescueNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, exceptions: T::Array[Node], operator_loc: ::T.nilable(Location), reference: ::T.nilable(::T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode)), then_keyword_loc: ::T.nilable(Location), statements: ::T.nilable(StatementsNode), subsequent: ::T.nilable(RescueNode)).void }
    def initialize(source, node_id, location, flags, keyword_loc, exceptions, operator_loc, reference, then_keyword_loc, statements, subsequent); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, exceptions: T::Array[Node], operator_loc: ::T.nilable(Location), reference: ::T.nilable(::T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode)), then_keyword_loc: ::T.nilable(Location), statements: ::T.nilable(StatementsNode), subsequent: ::T.nilable(RescueNode)).returns(RescueNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), keyword_loc: T.unsafe(nil), exceptions: T.unsafe(nil), operator_loc: T.unsafe(nil), reference: T.unsafe(nil), then_keyword_loc: T.unsafe(nil), statements: T.unsafe(nil), subsequent: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the Location represented by `keyword_loc`.
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Returns the `exceptions` attribute.
    sig { returns(T::Array[Node]) }
    def exceptions; end

    # Returns the Location represented by `operator_loc`.
    sig { returns(::T.nilable(Location)) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_operator_loc(repository); end

    # Returns the `reference` attribute.
    sig { returns(::T.nilable(::T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode))) }
    def reference; end

    # Returns the Location represented by `then_keyword_loc`.
    sig { returns(::T.nilable(Location)) }
    def then_keyword_loc; end

    # Save the then_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_then_keyword_loc(repository); end

    # Returns the `statements` attribute.
    sig { returns(::T.nilable(StatementsNode)) }
    def statements; end

    # Returns the `subsequent` attribute.
    sig { returns(::T.nilable(RescueNode)) }
    def subsequent; end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    # Slice the location of operator_loc from the source.
    sig { returns(::T.nilable(String)) }
    def operator; end

    # Slice the location of then_keyword_loc from the source.
    sig { returns(::T.nilable(String)) }
    def then_keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a rest parameter to a method, block, or lambda definition.
  #
  # ```rb
  # def a(*b)
  #       ^^
  # end
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#ZGVmIGEoKmIpCgplbmQK)
  class RestParameterNode < Node
    # Initialize a new RestParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: ::T.nilable(Symbol), name_loc: ::T.nilable(Location), operator_loc: Location).void }
    def initialize(source, node_id, location, flags, name, name_loc, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: ::T.nilable(Symbol), name_loc: ::T.nilable(Location), operator_loc: Location).returns(RestParameterNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # a parameter name that has been repeated in the method signature
    sig { returns(T::Boolean) }
    def repeated_parameter?; end

    # Returns the `name` attribute.
    sig { returns(::T.nilable(Symbol)) }
    def name; end

    # Returns the Location represented by `name_loc`.
    sig { returns(::T.nilable(Location)) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_name_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `retry` keyword.
  #
  # ```rb
  # retry
  # ^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#cmV0cnkK)
  class RetryNode < Node
    # Initialize a new RetryNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(RetryNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `return` keyword.
  #
  # ```rb
  # return 1
  # ^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#cmV0dXJuIDEK)
  class ReturnNode < Node
    # Initialize a new ReturnNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, arguments: ::T.nilable(ArgumentsNode)).void }
    def initialize(source, node_id, location, flags, keyword_loc, arguments); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, arguments: ::T.nilable(ArgumentsNode)).returns(ReturnNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), keyword_loc: T.unsafe(nil), arguments: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the Location represented by `keyword_loc`.
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Returns the `arguments` attribute.
    sig { returns(::T.nilable(ArgumentsNode)) }
    def arguments; end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the `self` keyword.
  #
  # ```rb
  # self
  # ^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#c2VsZgo)
  class SelfNode < Node
    # Initialize a new SelfNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(SelfNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # This node wraps a constant write to indicate that when the value is written, it should have its shareability state modified.
  #
  # ```rb
  # # shareable_constant_value: literal
  # C = { a: 1 }
  # ^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#IyBzaGFyZWFibGVfY29uc3RhbnRfdmFsdWU6IGxpdGVyYWwKQyA9IHsgYTogMSB9Cg)
  class ShareableConstantNode < Node
    # Initialize a new ShareableConstantNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, write: ::T.any(ConstantWriteNode, ConstantAndWriteNode, ConstantOrWriteNode, ConstantOperatorWriteNode, ConstantPathWriteNode, ConstantPathAndWriteNode, ConstantPathOrWriteNode, ConstantPathOperatorWriteNode)).void }
    def initialize(source, node_id, location, flags, write); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, write: ::T.any(ConstantWriteNode, ConstantAndWriteNode, ConstantOrWriteNode, ConstantOperatorWriteNode, ConstantPathWriteNode, ConstantPathAndWriteNode, ConstantPathOrWriteNode, ConstantPathOperatorWriteNode)).returns(ShareableConstantNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), write: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # constant writes that should be modified with shareable constant value literal
    sig { returns(T::Boolean) }
    def literal?; end

    # constant writes that should be modified with shareable constant value experimental everything
    sig { returns(T::Boolean) }
    def experimental_everything?; end

    # constant writes that should be modified with shareable constant value experimental copy
    sig { returns(T::Boolean) }
    def experimental_copy?; end

    # The constant write that should be modified with the shareability state.
    sig { returns(::T.any(ConstantWriteNode, ConstantAndWriteNode, ConstantOrWriteNode, ConstantOperatorWriteNode, ConstantPathWriteNode, ConstantPathAndWriteNode, ConstantPathOrWriteNode, ConstantPathOperatorWriteNode)) }
    def write; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a singleton class declaration involving the `class` keyword.
  #
  # ```rb
  # class << self end
  # ^^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Y2xhc3MgPDwgc2VsZiBlbmQK)
  class SingletonClassNode < Node
    # Initialize a new SingletonClassNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], class_keyword_loc: Location, operator_loc: Location, expression: Node, body: ::T.nilable(::T.any(StatementsNode, BeginNode)), end_keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, locals, class_keyword_loc, operator_loc, expression, body, end_keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], class_keyword_loc: Location, operator_loc: Location, expression: Node, body: ::T.nilable(::T.any(StatementsNode, BeginNode)), end_keyword_loc: Location).returns(SingletonClassNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), locals: T.unsafe(nil), class_keyword_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), expression: T.unsafe(nil), body: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `locals` attribute.
    sig { returns(T::Array[Symbol]) }
    def locals; end

    # Returns the Location represented by `class_keyword_loc`.
    sig { returns(Location) }
    def class_keyword_loc; end

    # Save the class_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_class_keyword_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `expression` attribute.
    sig { returns(Node) }
    def expression; end

    # Returns the `body` attribute.
    sig { returns(::T.nilable(::T.any(StatementsNode, BeginNode))) }
    def body; end

    # Returns the Location represented by `end_keyword_loc`.
    sig { returns(Location) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_end_keyword_loc(repository); end

    # Slice the location of class_keyword_loc from the source.
    sig { returns(String) }
    def class_keyword; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    # Slice the location of end_keyword_loc from the source.
    sig { returns(String) }
    def end_keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `__ENCODING__` keyword.
  #
  # ```rb
  # __ENCODING__
  # ^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#X19FTkNPRElOR19fCg)
  class SourceEncodingNode < Node
    # Initialize a new SourceEncodingNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(SourceEncodingNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `__FILE__` keyword.
  #
  # ```rb
  # __FILE__
  # ^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#X19GSUxFX18K)
  class SourceFileNode < Node
    # Initialize a new SourceFileNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, filepath: String).void }
    def initialize(source, node_id, location, flags, filepath); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, filepath: String).returns(SourceFileNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), filepath: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # internal bytes forced the encoding to UTF-8
    sig { returns(T::Boolean) }
    def forced_utf8_encoding?; end

    # internal bytes forced the encoding to binary
    sig { returns(T::Boolean) }
    def forced_binary_encoding?; end

    # frozen by virtue of a `frozen_string_literal: true` comment or `--enable-frozen-string-literal`
    sig { returns(T::Boolean) }
    def frozen?; end

    # mutable by virtue of a `frozen_string_literal: false` comment or `--disable-frozen-string-literal`
    sig { returns(T::Boolean) }
    def mutable?; end

    # Represents the file path being parsed. This corresponds directly to the `filepath` option given to the various `Prism.parse*` APIs.
    sig { returns(String) }
    def filepath; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `__LINE__` keyword.
  #
  # ```rb
  # __LINE__
  # ^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#X19MSU5FX18K)
  class SourceLineNode < Node
    # Initialize a new SourceLineNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(SourceLineNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the splat operator.
  #
  # ```rb
  # [*a]
  #  ^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#WyphXQo)
  class SplatNode < Node
    # Initialize a new SplatNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, operator_loc: Location, expression: ::T.nilable(Node)).void }
    def initialize(source, node_id, location, flags, operator_loc, expression); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, operator_loc: Location, expression: ::T.nilable(Node)).returns(SplatNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), operator_loc: T.unsafe(nil), expression: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `expression` attribute.
    sig { returns(::T.nilable(Node)) }
    def expression; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a set of statements contained within some scope.
  #
  # ```rb
  # foo; bar; baz
  # ^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Zm9vOyBiYXI7IGJhego)
  class StatementsNode < Node
    # Initialize a new StatementsNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, body: T::Array[Node]).void }
    def initialize(source, node_id, location, flags, body); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, body: T::Array[Node]).returns(StatementsNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), body: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `body` attribute.
    sig { returns(T::Array[Node]) }
    def body; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a string literal, a string contained within a `%w` list, or plain string content within an interpolated string.
  #
  # ```rb
  # "foo"
  # ^^^^^
  #
  # %w[foo]
  #    ^^^
  #
  # "foo #{bar} baz"
  #  ^^^^      ^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#ImZvbyIKCiV3W2Zvb10KCiJmb28gI3tiYXJ9IGJheiIK)
  class StringNode < Node
    # Initialize a new StringNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: ::T.nilable(Location), content_loc: Location, closing_loc: ::T.nilable(Location), unescaped: String).void }
    def initialize(source, node_id, location, flags, opening_loc, content_loc, closing_loc, unescaped); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, opening_loc: ::T.nilable(Location), content_loc: Location, closing_loc: ::T.nilable(Location), unescaped: String).returns(StringNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), content_loc: T.unsafe(nil), closing_loc: T.unsafe(nil), unescaped: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # internal bytes forced the encoding to UTF-8
    sig { returns(T::Boolean) }
    def forced_utf8_encoding?; end

    # internal bytes forced the encoding to binary
    sig { returns(T::Boolean) }
    def forced_binary_encoding?; end

    # frozen by virtue of a `frozen_string_literal: true` comment or `--enable-frozen-string-literal`
    sig { returns(T::Boolean) }
    def frozen?; end

    # mutable by virtue of a `frozen_string_literal: false` comment or `--disable-frozen-string-literal`
    sig { returns(T::Boolean) }
    def mutable?; end

    # Returns the Location represented by `opening_loc`.
    sig { returns(::T.nilable(Location)) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_opening_loc(repository); end

    # Returns the Location represented by `content_loc`.
    sig { returns(Location) }
    def content_loc; end

    # Save the content_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_content_loc(repository); end

    # Returns the Location represented by `closing_loc`.
    sig { returns(::T.nilable(Location)) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_closing_loc(repository); end

    # Returns the `unescaped` attribute.
    sig { returns(String) }
    def unescaped; end

    # Slice the location of opening_loc from the source.
    sig { returns(::T.nilable(String)) }
    def opening; end

    # Slice the location of content_loc from the source.
    sig { returns(String) }
    def content; end

    # Slice the location of closing_loc from the source.
    sig { returns(::T.nilable(String)) }
    def closing; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `super` keyword with parentheses or arguments.
  #
  # ```rb
  # super()
  # ^^^^^^^
  #
  # super foo, bar
  # ^^^^^^^^^^^^^^
  #
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#c3VwZXIoKQoKc3VwZXIgZm9vLCBiYXIK)
  # If no arguments are provided (except for a block), it would be a `ForwardingSuperNode` instead.
  class SuperNode < Node
    # Initialize a new SuperNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, lparen_loc: ::T.nilable(Location), arguments: ::T.nilable(ArgumentsNode), rparen_loc: ::T.nilable(Location), block: ::T.nilable(::T.any(BlockNode, BlockArgumentNode))).void }
    def initialize(source, node_id, location, flags, keyword_loc, lparen_loc, arguments, rparen_loc, block); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, lparen_loc: ::T.nilable(Location), arguments: ::T.nilable(ArgumentsNode), rparen_loc: ::T.nilable(Location), block: ::T.nilable(::T.any(BlockNode, BlockArgumentNode))).returns(SuperNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), keyword_loc: T.unsafe(nil), lparen_loc: T.unsafe(nil), arguments: T.unsafe(nil), rparen_loc: T.unsafe(nil), block: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the Location represented by `keyword_loc`.
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Returns the Location represented by `lparen_loc`.
    sig { returns(::T.nilable(Location)) }
    def lparen_loc; end

    # Save the lparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_lparen_loc(repository); end

    # Can be only `nil` when there are empty parentheses, like `super()`.
    sig { returns(::T.nilable(ArgumentsNode)) }
    def arguments; end

    # Returns the Location represented by `rparen_loc`.
    sig { returns(::T.nilable(Location)) }
    def rparen_loc; end

    # Save the rparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_rparen_loc(repository); end

    # Returns the `block` attribute.
    sig { returns(::T.nilable(::T.any(BlockNode, BlockArgumentNode))) }
    def block; end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    # Slice the location of lparen_loc from the source.
    sig { returns(::T.nilable(String)) }
    def lparen; end

    # Slice the location of rparen_loc from the source.
    sig { returns(::T.nilable(String)) }
    def rparen; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a symbol literal or a symbol contained within a `%i` list.
  #
  # ```rb
  # ^^^^
  #
  # %i[foo]
  #    ^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#OmZvbwoKJWlbZm9vXQo)
  class SymbolNode < Node
    # Initialize a new SymbolNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: ::T.nilable(Location), content_loc: Location, closing_loc: ::T.nilable(Location), unescaped: String).void }
    def initialize(source, node_id, location, flags, opening_loc, content_loc, closing_loc, unescaped); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, opening_loc: ::T.nilable(Location), content_loc: Location, closing_loc: ::T.nilable(Location), unescaped: String).returns(SymbolNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), content_loc: T.unsafe(nil), closing_loc: T.unsafe(nil), unescaped: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # internal bytes forced the encoding to UTF-8
    sig { returns(T::Boolean) }
    def forced_utf8_encoding?; end

    # internal bytes forced the encoding to binary
    sig { returns(T::Boolean) }
    def forced_binary_encoding?; end

    # internal bytes forced the encoding to US-ASCII
    sig { returns(T::Boolean) }
    def forced_us_ascii_encoding?; end

    # Returns the Location represented by `opening_loc`.
    sig { returns(::T.nilable(Location)) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_opening_loc(repository); end

    # Returns the Location represented by `content_loc`.
    sig { returns(Location) }
    def content_loc; end

    # Save the content_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_content_loc(repository); end

    # Returns the Location represented by `closing_loc`.
    sig { returns(::T.nilable(Location)) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_closing_loc(repository); end

    # Returns the `unescaped` attribute.
    sig { returns(String) }
    def unescaped; end

    # Slice the location of opening_loc from the source.
    sig { returns(::T.nilable(String)) }
    def opening; end

    # Slice the location of content_loc from the source.
    sig { returns(String) }
    def content; end

    # Slice the location of closing_loc from the source.
    sig { returns(::T.nilable(String)) }
    def closing; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the literal `true` keyword.
  #
  # ```rb
  # true
  # ^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#dHJ1ZQo)
  class TrueNode < Node
    # Initialize a new TrueNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(TrueNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `undef` keyword.
  #
  # ```rb
  # undef :foo, :bar, :baz
  # ^^^^^^^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#dW5kZWYgOmZvbywgOmJhciwgOmJhego)
  class UndefNode < Node
    # Initialize a new UndefNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, names: T::Array[::T.any(SymbolNode, InterpolatedSymbolNode)], keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, names, keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, names: T::Array[::T.any(SymbolNode, InterpolatedSymbolNode)], keyword_loc: Location).returns(UndefNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), names: T.unsafe(nil), keyword_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the `names` attribute.
    sig { returns(T::Array[::T.any(SymbolNode, InterpolatedSymbolNode)]) }
    def names; end

    # Returns the Location represented by `keyword_loc`.
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `unless` keyword, either in the block form or the modifier form.
  #
  # ```rb
  # bar unless foo
  # ^^^^^^^^^^^^^^
  #
  # unless foo then bar end
  # ^^^^^^^^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#YmFyIHVubGVzcyBmb28KCnVubGVzcyBmb28gdGhlbiBiYXIgZW5kCg)
  class UnlessNode < Node
    # Initialize a new UnlessNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, unless_keyword_loc: Location, predicate: Node, then_keyword_loc: ::T.nilable(Location), statements: ::T.nilable(StatementsNode), else_clause: ::T.nilable(ElseNode), end_keyword_loc: ::T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, unless_keyword_loc, predicate, then_keyword_loc, statements, else_clause, end_keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, unless_keyword_loc: Location, predicate: Node, then_keyword_loc: ::T.nilable(Location), statements: ::T.nilable(StatementsNode), else_clause: ::T.nilable(ElseNode), end_keyword_loc: ::T.nilable(Location)).returns(UnlessNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), unless_keyword_loc: T.unsafe(nil), predicate: T.unsafe(nil), then_keyword_loc: T.unsafe(nil), statements: T.unsafe(nil), else_clause: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # The Location of the `unless` keyword.
    #
    # ```rb
    # unless cond then bar end
    # ^^^^^^
    #
    # bar unless cond
    #     ^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#dW5sZXNzIGNvbmQgdGhlbiBiYXIgZW5kCgpiYXIgdW5sZXNzIGNvbmQK)
    sig { returns(Location) }
    def unless_keyword_loc; end

    # Save the unless_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_unless_keyword_loc(repository); end

    # The condition to be evaluated for the unless expression. It can be any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    # ```rb
    # unless cond then bar end
    #        ^^^^
    #
    # bar unless cond
    #            ^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#dW5sZXNzIGNvbmQgdGhlbiBiYXIgZW5kCgpiYXIgdW5sZXNzIGNvbmQK)
    sig { returns(Node) }
    def predicate; end

    # The Location of the `then` keyword, if present.
    #
    # ```rb
    # unless cond then bar end
    #             ^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#dW5sZXNzIGNvbmQgdGhlbiBiYXIgZW5kCg)
    sig { returns(::T.nilable(Location)) }
    def then_keyword_loc; end

    # Save the then_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_then_keyword_loc(repository); end

    # The body of statements that will executed if the unless condition is
    # falsey. Will be `nil` if no body is provided.
    #
    # ```rb
    # unless cond then bar end
    #                  ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#dW5sZXNzIGNvbmQgdGhlbiBiYXIgZW5kCg)
    sig { returns(::T.nilable(StatementsNode)) }
    def statements; end

    # The else clause of the unless expression, if present.
    #
    # ```rb
    # unless cond then bar else baz end
    #                      ^^^^^^^^^^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#dW5sZXNzIGNvbmQgdGhlbiBiYXIgZWxzZSBiYXogZW5kCg)
    sig { returns(::T.nilable(ElseNode)) }
    def else_clause; end

    # The Location of the `end` keyword, if present.
    #
    # ```rb
    # unless cond then bar end
    #                      ^^^
    # ```
    #
    # [Explore code sample](https://ruby.github.io/prism/playground.html#dW5sZXNzIGNvbmQgdGhlbiBiYXIgZW5kCg)
    sig { returns(::T.nilable(Location)) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_end_keyword_loc(repository); end

    # Slice the location of unless_keyword_loc from the source.
    sig { returns(String) }
    def unless_keyword; end

    # Slice the location of then_keyword_loc from the source.
    sig { returns(::T.nilable(String)) }
    def then_keyword; end

    # Slice the location of end_keyword_loc from the source.
    sig { returns(::T.nilable(String)) }
    def end_keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `until` keyword, either in the block form or the modifier form.
  #
  # ```rb
  # bar until foo
  # ^^^^^^^^^^^^^
  #
  # until foo do bar end
  # ^^^^^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#YmFyIHVudGlsIGZvbwoKdW50aWwgZm9vIGRvIGJhciBlbmQK)
  class UntilNode < Node
    # Initialize a new UntilNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, until_keyword_loc: Location, do_keyword_loc: ::T.nilable(Location), end_keyword_loc: ::T.nilable(Location), predicate: Node, statements: ::T.nilable(StatementsNode)).void }
    def initialize(source, node_id, location, flags, until_keyword_loc, do_keyword_loc, end_keyword_loc, predicate, statements); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, until_keyword_loc: Location, do_keyword_loc: ::T.nilable(Location), end_keyword_loc: ::T.nilable(Location), predicate: Node, statements: ::T.nilable(StatementsNode)).returns(UntilNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), until_keyword_loc: T.unsafe(nil), do_keyword_loc: T.unsafe(nil), end_keyword_loc: T.unsafe(nil), predicate: T.unsafe(nil), statements: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # a loop after a begin statement, so the body is executed first before the condition
    sig { returns(T::Boolean) }
    def begin_modifier?; end

    # Returns the Location represented by `until_keyword_loc`.
    sig { returns(Location) }
    def until_keyword_loc; end

    # Save the until_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_until_keyword_loc(repository); end

    # Returns the Location represented by `do_keyword_loc`.
    sig { returns(::T.nilable(Location)) }
    def do_keyword_loc; end

    # Save the do_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_do_keyword_loc(repository); end

    # Returns the Location represented by `end_keyword_loc`.
    sig { returns(::T.nilable(Location)) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_end_keyword_loc(repository); end

    # Returns the `predicate` attribute.
    sig { returns(Node) }
    def predicate; end

    # Returns the `statements` attribute.
    sig { returns(::T.nilable(StatementsNode)) }
    def statements; end

    # Slice the location of until_keyword_loc from the source.
    sig { returns(String) }
    def until_keyword; end

    # Slice the location of do_keyword_loc from the source.
    sig { returns(::T.nilable(String)) }
    def do_keyword; end

    # Slice the location of end_keyword_loc from the source.
    sig { returns(::T.nilable(String)) }
    def end_keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `when` keyword within a case statement.
  #
  # ```rb
  # case true
  # when true
  # ^^^^^^^^^
  # end
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#Y2FzZSB0cnVlCndoZW4gdHJ1ZQoKZW5kCg)
  class WhenNode < Node
    # Initialize a new WhenNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, when_keyword_loc: Location, conditions: T::Array[Node], then_keyword_loc: ::T.nilable(Location), statements: ::T.nilable(StatementsNode)).void }
    def initialize(source, node_id, location, flags, when_keyword_loc, conditions, then_keyword_loc, statements); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, when_keyword_loc: Location, conditions: T::Array[Node], then_keyword_loc: ::T.nilable(Location), statements: ::T.nilable(StatementsNode)).returns(WhenNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), when_keyword_loc: T.unsafe(nil), conditions: T.unsafe(nil), then_keyword_loc: T.unsafe(nil), statements: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the Location represented by `when_keyword_loc`.
    sig { returns(Location) }
    def when_keyword_loc; end

    # Save the when_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_when_keyword_loc(repository); end

    # Returns the `conditions` attribute.
    sig { returns(T::Array[Node]) }
    def conditions; end

    # Returns the Location represented by `then_keyword_loc`.
    sig { returns(::T.nilable(Location)) }
    def then_keyword_loc; end

    # Save the then_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_then_keyword_loc(repository); end

    # Returns the `statements` attribute.
    sig { returns(::T.nilable(StatementsNode)) }
    def statements; end

    # Slice the location of when_keyword_loc from the source.
    sig { returns(String) }
    def when_keyword; end

    # Slice the location of then_keyword_loc from the source.
    sig { returns(::T.nilable(String)) }
    def then_keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `while` keyword, either in the block form or the modifier form.
  #
  # ```rb
  # bar while foo
  # ^^^^^^^^^^^^^
  #
  # while foo do bar end
  # ^^^^^^^^^^^^^^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#YmFyIHdoaWxlIGZvbwoKd2hpbGUgZm9vIGRvIGJhciBlbmQK)
  class WhileNode < Node
    # Initialize a new WhileNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, while_keyword_loc: Location, do_keyword_loc: ::T.nilable(Location), end_keyword_loc: ::T.nilable(Location), predicate: Node, statements: ::T.nilable(StatementsNode)).void }
    def initialize(source, node_id, location, flags, while_keyword_loc, do_keyword_loc, end_keyword_loc, predicate, statements); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, while_keyword_loc: Location, do_keyword_loc: ::T.nilable(Location), end_keyword_loc: ::T.nilable(Location), predicate: Node, statements: ::T.nilable(StatementsNode)).returns(WhileNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), while_keyword_loc: T.unsafe(nil), do_keyword_loc: T.unsafe(nil), end_keyword_loc: T.unsafe(nil), predicate: T.unsafe(nil), statements: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # a loop after a begin statement, so the body is executed first before the condition
    sig { returns(T::Boolean) }
    def begin_modifier?; end

    # Returns the Location represented by `while_keyword_loc`.
    sig { returns(Location) }
    def while_keyword_loc; end

    # Save the while_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_while_keyword_loc(repository); end

    # Returns the Location represented by `do_keyword_loc`.
    sig { returns(::T.nilable(Location)) }
    def do_keyword_loc; end

    # Save the do_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_do_keyword_loc(repository); end

    # Returns the Location represented by `end_keyword_loc`.
    sig { returns(::T.nilable(Location)) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_end_keyword_loc(repository); end

    # Returns the `predicate` attribute.
    sig { returns(Node) }
    def predicate; end

    # Returns the `statements` attribute.
    sig { returns(::T.nilable(StatementsNode)) }
    def statements; end

    # Slice the location of while_keyword_loc from the source.
    sig { returns(String) }
    def while_keyword; end

    # Slice the location of do_keyword_loc from the source.
    sig { returns(::T.nilable(String)) }
    def do_keyword; end

    # Slice the location of end_keyword_loc from the source.
    sig { returns(::T.nilable(String)) }
    def end_keyword; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an xstring literal with no interpolation.
  #
  # ```rb
  # `foo`
  # ^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#YGZvb2AK)
  class XStringNode < Node
    # Initialize a new XStringNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: Location, content_loc: Location, closing_loc: Location, unescaped: String).void }
    def initialize(source, node_id, location, flags, opening_loc, content_loc, closing_loc, unescaped); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, opening_loc: Location, content_loc: Location, closing_loc: Location, unescaped: String).returns(XStringNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), content_loc: T.unsafe(nil), closing_loc: T.unsafe(nil), unescaped: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # internal bytes forced the encoding to UTF-8
    sig { returns(T::Boolean) }
    def forced_utf8_encoding?; end

    # internal bytes forced the encoding to binary
    sig { returns(T::Boolean) }
    def forced_binary_encoding?; end

    # Returns the Location represented by `opening_loc`.
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the Location represented by `content_loc`.
    sig { returns(Location) }
    def content_loc; end

    # Save the content_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_content_loc(repository); end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Returns the `unescaped` attribute.
    sig { returns(String) }
    def unescaped; end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of content_loc from the source.
    sig { returns(String) }
    def content; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `yield` keyword.
  #
  # ```rb
  # yield 1
  # ^^^^^^^
  # ```
  #
  # [Explore code sample](https://ruby.github.io/prism/playground.html#eWllbGQgMQo)
  class YieldNode < Node
    # Initialize a new YieldNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, lparen_loc: ::T.nilable(Location), arguments: ::T.nilable(ArgumentsNode), rparen_loc: ::T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, keyword_loc, lparen_loc, arguments, rparen_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(::T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: ::T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, lparen_loc: ::T.nilable(Location), arguments: ::T.nilable(ArgumentsNode), rparen_loc: ::T.nilable(Location)).returns(YieldNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), keyword_loc: T.unsafe(nil), lparen_loc: T.unsafe(nil), arguments: T.unsafe(nil), rparen_loc: T.unsafe(nil)); end

    sig { override.returns(T::Array[::T.nilable(Node)]) }
    def deconstruct; end

    sig { params(keys: ::T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, ::T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # Returns the Location represented by `keyword_loc`.
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Returns the Location represented by `lparen_loc`.
    sig { returns(::T.nilable(Location)) }
    def lparen_loc; end

    # Save the lparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_lparen_loc(repository); end

    # Returns the `arguments` attribute.
    sig { returns(::T.nilable(ArgumentsNode)) }
    def arguments; end

    # Returns the Location represented by `rparen_loc`.
    sig { returns(::T.nilable(Location)) }
    def rparen_loc; end

    # Save the rparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: ::T.untyped).returns(::T.nilable(Relocation::Entry)) }
    def save_rparen_loc(repository); end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    # Slice the location of lparen_loc from the source.
    sig { returns(::T.nilable(String)) }
    def lparen; end

    # Slice the location of rparen_loc from the source.
    sig { returns(::T.nilable(String)) }
    def rparen; end

    sig { params(other: ::T.untyped).returns(::T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Flags for arguments nodes.
  module ArgumentsNodeFlags
    # if the arguments contain forwarding
    CONTAINS_FORWARDING = T.let(nil, ::T.untyped)

    # if the arguments contain keywords
    CONTAINS_KEYWORDS = T.let(nil, ::T.untyped)

    # if the arguments contain a keyword splat
    CONTAINS_KEYWORD_SPLAT = T.let(nil, ::T.untyped)

    # if the arguments contain a splat
    CONTAINS_SPLAT = T.let(nil, ::T.untyped)

    # if the arguments contain multiple splats
    CONTAINS_MULTIPLE_SPLATS = T.let(nil, ::T.untyped)
  end

  # Flags for array nodes.
  module ArrayNodeFlags
    # if array contains splat nodes
    CONTAINS_SPLAT = T.let(nil, ::T.untyped)
  end

  # Flags for call nodes.
  module CallNodeFlags
    # &. operator
    SAFE_NAVIGATION = T.let(nil, ::T.untyped)

    # a call that could have been a local variable
    VARIABLE_CALL = T.let(nil, ::T.untyped)

    # a call that is an attribute write, so the value being written should be returned
    ATTRIBUTE_WRITE = T.let(nil, ::T.untyped)

    # a call that ignores method visibility
    IGNORE_VISIBILITY = T.let(nil, ::T.untyped)
  end

  # Flags for nodes that have unescaped content.
  module EncodingFlags
    # internal bytes forced the encoding to UTF-8
    FORCED_UTF8_ENCODING = T.let(nil, ::T.untyped)

    # internal bytes forced the encoding to binary
    FORCED_BINARY_ENCODING = T.let(nil, ::T.untyped)
  end

  # Flags for integer nodes that correspond to the base of the integer.
  module IntegerBaseFlags
    # 0b prefix
    BINARY = T.let(nil, ::T.untyped)

    # 0d or no prefix
    DECIMAL = T.let(nil, ::T.untyped)

    # 0o or 0 prefix
    OCTAL = T.let(nil, ::T.untyped)

    # 0x prefix
    HEXADECIMAL = T.let(nil, ::T.untyped)
  end

  # Flags for interpolated string nodes that indicated mutability if they are also marked as literals.
  module InterpolatedStringNodeFlags
    # frozen by virtue of a `frozen_string_literal: true` comment or `--enable-frozen-string-literal`; only for adjacent string literals like `'a' 'b'`
    FROZEN = T.let(nil, ::T.untyped)

    # mutable by virtue of a `frozen_string_literal: false` comment or `--disable-frozen-string-literal`; only for adjacent string literals like `'a' 'b'`
    MUTABLE = T.let(nil, ::T.untyped)
  end

  # Flags for keyword hash nodes.
  module KeywordHashNodeFlags
    # a keyword hash which only has `AssocNode` elements all with symbol keys, which means the elements can be treated as keyword arguments
    SYMBOL_KEYS = T.let(nil, ::T.untyped)
  end

  # Flags for while and until loop nodes.
  module LoopFlags
    # a loop after a begin statement, so the body is executed first before the condition
    BEGIN_MODIFIER = T.let(nil, ::T.untyped)
  end

  # Flags for parameter nodes.
  module ParameterFlags
    # a parameter name that has been repeated in the method signature
    REPEATED_PARAMETER = T.let(nil, ::T.untyped)
  end

  # Flags for parentheses nodes.
  module ParenthesesNodeFlags
    # parentheses that contain multiple potentially void statements
    MULTIPLE_STATEMENTS = T.let(nil, ::T.untyped)
  end

  # Flags for range and flip-flop nodes.
  module RangeFlags
    # ... operator
    EXCLUDE_END = T.let(nil, ::T.untyped)
  end

  # Flags for regular expression and match last line nodes.
  module RegularExpressionFlags
    # i - ignores the case of characters when matching
    IGNORE_CASE = T.let(nil, ::T.untyped)

    # x - ignores whitespace and allows comments in regular expressions
    EXTENDED = T.let(nil, ::T.untyped)

    # m - allows $ to match the end of lines within strings
    MULTI_LINE = T.let(nil, ::T.untyped)

    # o - only interpolates values into the regular expression once
    ONCE = T.let(nil, ::T.untyped)

    # e - forces the EUC-JP encoding
    EUC_JP = T.let(nil, ::T.untyped)

    # n - forces the ASCII-8BIT encoding
    ASCII_8BIT = T.let(nil, ::T.untyped)

    # s - forces the Windows-31J encoding
    WINDOWS_31J = T.let(nil, ::T.untyped)

    # u - forces the UTF-8 encoding
    UTF_8 = T.let(nil, ::T.untyped)

    # internal bytes forced the encoding to UTF-8
    FORCED_UTF8_ENCODING = T.let(nil, ::T.untyped)

    # internal bytes forced the encoding to binary
    FORCED_BINARY_ENCODING = T.let(nil, ::T.untyped)

    # internal bytes forced the encoding to US-ASCII
    FORCED_US_ASCII_ENCODING = T.let(nil, ::T.untyped)
  end

  # Flags for shareable constant nodes.
  module ShareableConstantNodeFlags
    # constant writes that should be modified with shareable constant value literal
    LITERAL = T.let(nil, ::T.untyped)

    # constant writes that should be modified with shareable constant value experimental everything
    EXPERIMENTAL_EVERYTHING = T.let(nil, ::T.untyped)

    # constant writes that should be modified with shareable constant value experimental copy
    EXPERIMENTAL_COPY = T.let(nil, ::T.untyped)
  end

  # Flags for string nodes.
  module StringFlags
    # internal bytes forced the encoding to UTF-8
    FORCED_UTF8_ENCODING = T.let(nil, ::T.untyped)

    # internal bytes forced the encoding to binary
    FORCED_BINARY_ENCODING = T.let(nil, ::T.untyped)

    # frozen by virtue of a `frozen_string_literal: true` comment or `--enable-frozen-string-literal`
    FROZEN = T.let(nil, ::T.untyped)

    # mutable by virtue of a `frozen_string_literal: false` comment or `--disable-frozen-string-literal`
    MUTABLE = T.let(nil, ::T.untyped)
  end

  # Flags for symbol nodes.
  module SymbolFlags
    # internal bytes forced the encoding to UTF-8
    FORCED_UTF8_ENCODING = T.let(nil, ::T.untyped)

    # internal bytes forced the encoding to binary
    FORCED_BINARY_ENCODING = T.let(nil, ::T.untyped)

    # internal bytes forced the encoding to US-ASCII
    FORCED_US_ASCII_ENCODING = T.let(nil, ::T.untyped)
  end

  # The flags that are common to all nodes.
  module NodeFlags
    # A flag to indicate that the node is a candidate to emit a :line event
    # through tracepoint when compiled.
    NEWLINE = T.let(nil, Integer)

    # A flag to indicate that the value that the node represents is a value that
    # can be determined at parse-time.
    STATIC_LITERAL = T.let(nil, Integer)
  end
end
