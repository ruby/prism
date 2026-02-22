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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save(repository); end

    # A Location instance that represents the location of this node in the
    # source.
    sig { returns(Location) }
    def location; end

    # Save the location using a saved source so that it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
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
    sig { params(cache: T.untyped).returns(Integer) }
    def cached_start_code_units_offset(cache); end

    # Delegates to [`cached_end_code_units_offset`](rdoc-ref:Location#cached_end_code_units_offset)
    # of the associated location object.
    sig { params(cache: T.untyped).returns(Integer) }
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
    sig { params(cache: T.untyped).returns(Integer) }
    def cached_start_code_units_column(cache); end

    # Delegates to [`cached_end_code_units_column`](rdoc-ref:Location#cached_end_code_units_column)
    # of the associated location object.
    sig { params(cache: T.untyped).returns(Integer) }
    def cached_end_code_units_column(cache); end

    # Delegates to [`leading_comments`](rdoc-ref:Location#leading_comments) of the associated location object.
    sig { returns(T::Array[Comment]) }
    def leading_comments; end

    # Delegates to [`trailing_comments`](rdoc-ref:Location#trailing_comments) of the associated location object.
    sig { returns(T::Array[Comment]) }
    def trailing_comments; end

    # Delegates to [`comments`](rdoc-ref:Location#comments) of the associated location object.
    sig { returns(T::Array[Comment]) }
    def comments; end

    # Returns all of the lines of the source code associated with this node.
    sig { returns(T::Array[String]) }
    def source_lines; end

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
    sig { params(blk: T.proc.params(arg0: Node).returns(T::Boolean)).returns(T.nilable(Node)) }
    def breadth_first_search(&blk); end

    # Returns all of the nodes that match the given block when visited in a
    # breadth-first search. This is useful for finding all nodes that match a
    # particular condition.
    #
    #     node.breadth_first_search_all { |node| node.is_a?(Prism::CallNode) }
    sig { params(blk: T.proc.params(arg0: Node).returns(T::Boolean)).returns(T::Array[Node]) }
    def breadth_first_search_all(&blk); end

    # Returns a list of the fields that exist for this node class. Fields
    # describe the structure of the node. This kind of reflection is useful for
    # things like recursively visiting each node _and_ field in the tree.
    sig { returns(T::Array[Reflection::Field]) }
    def self.fields; end

    # Accepts a visitor and calls back into the specialized visit function.
    sig { abstract.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # Returns an array of child nodes, including `nil`s in the place of optional
    # nodes that were not present.
    sig { abstract.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # With a block given, yields each child node. Without a block, returns
    # an enumerator that contains each child node. Excludes any `nil`s in
    # the place of optional nodes that were not present.
    sig { abstract.returns(T::Enumerator[Node]) }
    sig { abstract.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # Returns an array of child nodes, excluding any `nil`s in the place of
    # optional nodes that were not present.
    sig { abstract.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # Returns an array of child nodes and locations that could potentially have
    # comments attached to them.
    sig { abstract.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

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
  #     alias $foo $bar
  #     ^^^^^^^^^^^^^^^
  class AliasGlobalVariableNode < Node
    # Initialize a new AliasGlobalVariableNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, new_name: T.any(GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode), old_name: T.any(GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode, SymbolNode, MissingNode), keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, new_name, old_name, keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, new_name: T.any(GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode), old_name: T.any(GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode, SymbolNode, MissingNode), keyword_loc: Location).returns(AliasGlobalVariableNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), new_name: T.unsafe(nil), old_name: T.unsafe(nil), keyword_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     alias $foo $bar
    #           ^^^^
    sig { returns(T.any(GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode)) }
    def new_name; end

    # Represents the old name of the global variable that can be used before aliasing.
    #
    #     alias $foo $bar
    #                ^^^^
    sig { returns(T.any(GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode, SymbolNode, MissingNode)) }
    def old_name; end

    # The Location of the `alias` keyword.
    #
    #     alias $foo $bar
    #     ^^^^^
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `alias` keyword to alias a method.
  #
  #     alias foo bar
  #     ^^^^^^^^^^^^^
  class AliasMethodNode < Node
    # Initialize a new AliasMethodNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, new_name: T.any(SymbolNode, InterpolatedSymbolNode), old_name: T.any(SymbolNode, InterpolatedSymbolNode, GlobalVariableReadNode, MissingNode), keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, new_name, old_name, keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, new_name: T.any(SymbolNode, InterpolatedSymbolNode), old_name: T.any(SymbolNode, InterpolatedSymbolNode, GlobalVariableReadNode, MissingNode), keyword_loc: Location).returns(AliasMethodNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), new_name: T.unsafe(nil), old_name: T.unsafe(nil), keyword_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     alias foo bar
    #           ^^^
    #
    #     alias :foo :bar
    #           ^^^^
    #
    #     alias :"#{foo}" :"#{bar}"
    #           ^^^^^^^^^
    sig { returns(T.any(SymbolNode, InterpolatedSymbolNode)) }
    def new_name; end

    # Represents the old name of the method that will be aliased.
    #
    #     alias foo bar
    #               ^^^
    #
    #     alias :foo :bar
    #                ^^^^
    #
    #     alias :"#{foo}" :"#{bar}"
    #                     ^^^^^^^^^
    sig { returns(T.any(SymbolNode, InterpolatedSymbolNode, GlobalVariableReadNode, MissingNode)) }
    def old_name; end

    # Represents the Location of the `alias` keyword.
    #
    #     alias foo bar
    #     ^^^^^
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an alternation pattern in pattern matching.
  #
  #     foo => bar | baz
  #            ^^^^^^^^^
  class AlternationPatternNode < Node
    # Initialize a new AlternationPatternNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, left: Node, right: Node, operator_loc: Location).void }
    def initialize(source, node_id, location, flags, left, right, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, left: Node, right: Node, operator_loc: Location).returns(AlternationPatternNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), left: T.unsafe(nil), right: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     foo => bar | baz
    #            ^^^
    sig { returns(Node) }
    def left; end

    # Represents the right side of the expression.
    #
    #     foo => bar | baz
    #                  ^^^
    sig { returns(Node) }
    def right; end

    # Represents the alternation operator Location.
    #
    #     foo => bar | baz
    #                ^
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `&&` operator or the `and` keyword.
  #
  #     left and right
  #     ^^^^^^^^^^^^^^
  class AndNode < Node
    # Initialize a new AndNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, left: Node, right: Node, operator_loc: Location).void }
    def initialize(source, node_id, location, flags, left, right, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, left: Node, right: Node, operator_loc: Location).returns(AndNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), left: T.unsafe(nil), right: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     left and right
    #     ^^^^
    #
    #     1 && 2
    #     ^
    sig { returns(Node) }
    def left; end

    # Represents the right side of the expression.
    #
    #     left && right
    #             ^^^^^
    #
    #     1 and 2
    #           ^
    sig { returns(Node) }
    def right; end

    # The Location of the `and` keyword or the `&&` operator.
    #
    #     left and right
    #          ^^^
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a set of arguments to a method or a keyword.
  #
  #     return foo, bar, baz
  #            ^^^^^^^^^^^^^
  class ArgumentsNode < Node
    # Initialize a new ArgumentsNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, arguments: T::Array[Node]).void }
    def initialize(source, node_id, location, flags, arguments); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, arguments: T::Array[Node]).returns(ArgumentsNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), arguments: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     foo(bar, baz)
    #         ^^^^^^^^
    sig { returns(T::Array[Node]) }
    def arguments; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an array literal. This can be a regular array using brackets or a special array using % like %w or %i.
  #
  #     [1, 2, 3]
  #     ^^^^^^^^^
  class ArrayNode < Node
    # Initialize a new ArrayNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, elements: T::Array[Node], opening_loc: T.nilable(Location), closing_loc: T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, elements, opening_loc, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, elements: T::Array[Node], opening_loc: T.nilable(Location), closing_loc: T.nilable(Location)).returns(ArrayNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), elements: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     [1,2,3]                 # "["
    #     %w[foo bar baz]         # "%w["
    #     %I(apple orange banana) # "%I("
    #     foo = 1, 2, 3           # nil
    sig { returns(T.nilable(Location)) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_opening_loc(repository); end

    # Represents the optional source Location for the closing token.
    #
    #     [1,2,3]                 # "]"
    #     %w[foo bar baz]         # "]"
    #     %I(apple orange banana) # ")"
    #     foo = 1, 2, 3           # nil
    sig { returns(T.nilable(Location)) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(T.nilable(String)) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(T.nilable(String)) }
    def closing; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an array pattern in pattern matching.
  #
  #     foo in 1, 2
  #     ^^^^^^^^^^^
  #
  #     foo in [1, 2]
  #     ^^^^^^^^^^^^^
  #
  #     foo in *bar
  #     ^^^^^^^^^^^
  #
  #     foo in Bar[]
  #     ^^^^^^^^^^^^
  #
  #     foo in Bar[1, 2, 3]
  #     ^^^^^^^^^^^^^^^^^^^
  class ArrayPatternNode < Node
    # Initialize a new ArrayPatternNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, constant: T.nilable(T.any(ConstantPathNode, ConstantReadNode)), requireds: T::Array[Node], rest: T.nilable(Node), posts: T::Array[Node], opening_loc: T.nilable(Location), closing_loc: T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, constant, requireds, rest, posts, opening_loc, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, constant: T.nilable(T.any(ConstantPathNode, ConstantReadNode)), requireds: T::Array[Node], rest: T.nilable(Node), posts: T::Array[Node], opening_loc: T.nilable(Location), closing_loc: T.nilable(Location)).returns(ArrayPatternNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), constant: T.unsafe(nil), requireds: T.unsafe(nil), rest: T.unsafe(nil), posts: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     foo in Bar[]
    #            ^^^
    #
    #     foo in Bar[1, 2, 3]
    #            ^^^
    #
    #     foo in Bar::Baz[1, 2, 3]
    #            ^^^^^^^^
    sig { returns(T.nilable(T.any(ConstantPathNode, ConstantReadNode))) }
    def constant; end

    # Represents the required elements of the array pattern.
    #
    #     foo in [1, 2]
    #             ^  ^
    sig { returns(T::Array[Node]) }
    def requireds; end

    # Represents the rest element of the array pattern.
    #
    #     foo in *bar
    #            ^^^^
    sig { returns(T.nilable(Node)) }
    def rest; end

    # Represents the elements after the rest element of the array pattern.
    #
    #     foo in *bar, baz
    #                  ^^^
    sig { returns(T::Array[Node]) }
    def posts; end

    # Represents the opening Location of the array pattern.
    #
    #     foo in [1, 2]
    #            ^
    sig { returns(T.nilable(Location)) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_opening_loc(repository); end

    # Represents the closing Location of the array pattern.
    #
    #     foo in [1, 2]
    #                 ^
    sig { returns(T.nilable(Location)) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(T.nilable(String)) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(T.nilable(String)) }
    def closing; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a hash key/value pair.
  #
  #     { a => b }
  #       ^^^^^^
  class AssocNode < Node
    # Initialize a new AssocNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, key: Node, value: Node, operator_loc: T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, key, value, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, key: Node, value: Node, operator_loc: T.nilable(Location)).returns(AssocNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), key: T.unsafe(nil), value: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     { a: b }
    #       ^
    #
    #     { foo => bar }
    #       ^^^
    #
    #     { def a; end => 1 }
    #       ^^^^^^^^^^
    sig { returns(Node) }
    def key; end

    # The value of the association, if present. This can be any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    #     { foo => bar }
    #              ^^^
    #
    #     { x: 1 }
    #          ^
    sig { returns(Node) }
    def value; end

    # The Location of the `=>` operator, if present.
    #
    #     { foo => bar }
    #           ^^
    sig { returns(T.nilable(Location)) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(T.nilable(String)) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a splat in a hash literal.
  #
  #     { **foo }
  #       ^^^^^
  class AssocSplatNode < Node
    # Initialize a new AssocSplatNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, value: T.nilable(Node), operator_loc: Location).void }
    def initialize(source, node_id, location, flags, value, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, value: T.nilable(Node), operator_loc: Location).returns(AssocSplatNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), value: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     { **foo }
    #         ^^^
    sig { returns(T.nilable(Node)) }
    def value; end

    # The Location of the `**` operator.
    #
    #     { **x }
    #       ^^
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents reading a reference to a field in the previous match.
  #
  #     $'
  #     ^^
  class BackReferenceReadNode < Node
    # Initialize a new BackReferenceReadNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).void }
    def initialize(source, node_id, location, flags, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(BackReferenceReadNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     $& # name `:$&`
    #
    #     $+ # name `:$+`
    sig { returns(Symbol) }
    def name; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a begin statement.
  #
  #     begin
  #       foo
  #     end
  #     ^^^^^
  class BeginNode < Node
    # Initialize a new BeginNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, begin_keyword_loc: T.nilable(Location), statements: T.nilable(StatementsNode), rescue_clause: T.nilable(RescueNode), else_clause: T.nilable(ElseNode), ensure_clause: T.nilable(EnsureNode), end_keyword_loc: T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, begin_keyword_loc, statements, rescue_clause, else_clause, ensure_clause, end_keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, begin_keyword_loc: T.nilable(Location), statements: T.nilable(StatementsNode), rescue_clause: T.nilable(RescueNode), else_clause: T.nilable(ElseNode), ensure_clause: T.nilable(EnsureNode), end_keyword_loc: T.nilable(Location)).returns(BeginNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), begin_keyword_loc: T.unsafe(nil), statements: T.unsafe(nil), rescue_clause: T.unsafe(nil), else_clause: T.unsafe(nil), ensure_clause: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     begin x end
    #     ^^^^^
    sig { returns(T.nilable(Location)) }
    def begin_keyword_loc; end

    # Save the begin_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_begin_keyword_loc(repository); end

    # Represents the statements within the begin block.
    #
    #     begin x end
    #           ^
    sig { returns(T.nilable(StatementsNode)) }
    def statements; end

    # Represents the rescue clause within the begin block.
    #
    #     begin x; rescue y; end
    #              ^^^^^^^^
    sig { returns(T.nilable(RescueNode)) }
    def rescue_clause; end

    # Represents the else clause within the begin block.
    #
    #     begin x; rescue y; else z; end
    #                        ^^^^^^
    sig { returns(T.nilable(ElseNode)) }
    def else_clause; end

    # Represents the ensure clause within the begin block.
    #
    #     begin x; ensure y; end
    #              ^^^^^^^^
    sig { returns(T.nilable(EnsureNode)) }
    def ensure_clause; end

    # Represents the Location of the `end` keyword.
    #
    #     begin x end
    #             ^^^
    sig { returns(T.nilable(Location)) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_end_keyword_loc(repository); end

    # Slice the location of begin_keyword_loc from the source.
    sig { returns(T.nilable(String)) }
    def begin_keyword; end

    # Slice the location of end_keyword_loc from the source.
    sig { returns(T.nilable(String)) }
    def end_keyword; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a block argument using `&`.
  #
  #     bar(&args)
  #     ^^^^^^^^^^
  class BlockArgumentNode < Node
    # Initialize a new BlockArgumentNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, expression: T.nilable(Node), operator_loc: Location).void }
    def initialize(source, node_id, location, flags, expression, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, expression: T.nilable(Node), operator_loc: Location).returns(BlockArgumentNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), expression: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     foo(&args)
    #         ^^^^^
    sig { returns(T.nilable(Node)) }
    def expression; end

    # Represents the Location of the `&` operator.
    #
    #     foo(&args)
    #         ^
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a block local variable.
  #
  #     a { |; b| }
  #            ^
  class BlockLocalVariableNode < Node
    # Initialize a new BlockLocalVariableNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).void }
    def initialize(source, node_id, location, flags, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(BlockLocalVariableNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     a { |; b| } # name `:b`
    #            ^
    sig { returns(Symbol) }
    def name; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a block of ruby code.
  #
  #     [1, 2, 3].each { |i| puts x }
  #                    ^^^^^^^^^^^^^^
  class BlockNode < Node
    # Initialize a new BlockNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], parameters: T.nilable(T.any(BlockParametersNode, NumberedParametersNode, ItParametersNode)), body: T.nilable(T.any(StatementsNode, BeginNode)), opening_loc: Location, closing_loc: Location).void }
    def initialize(source, node_id, location, flags, locals, parameters, body, opening_loc, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], parameters: T.nilable(T.any(BlockParametersNode, NumberedParametersNode, ItParametersNode)), body: T.nilable(T.any(StatementsNode, BeginNode)), opening_loc: Location, closing_loc: Location).returns(BlockNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), locals: T.unsafe(nil), parameters: T.unsafe(nil), body: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     [1, 2, 3].each { |i| puts x } # locals: [:i]
    #                       ^
    sig { returns(T::Array[Symbol]) }
    def locals; end

    # The parameters of the block.
    #
    #     [1, 2, 3].each { |i| puts x }
    #                      ^^^
    #     [1, 2, 3].each { puts _1 }
    #                    ^^^^^^^^^^^
    #     [1, 2, 3].each { puts it }
    #                    ^^^^^^^^^^^
    sig { returns(T.nilable(T.any(BlockParametersNode, NumberedParametersNode, ItParametersNode))) }
    def parameters; end

    # The body of the block.
    #
    #     [1, 2, 3].each { |i| puts x }
    #                          ^^^^^^
    sig { returns(T.nilable(T.any(StatementsNode, BeginNode))) }
    def body; end

    # Represents the Location of the opening `{` or `do`.
    #
    #     [1, 2, 3].each { |i| puts x }
    #                    ^
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Represents the Location of the closing `}` or `end`.
    #
    #     [1, 2, 3].each { |i| puts x }
    #                                 ^
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a block parameter of a method, block, or lambda definition.
  #
  #     def a(&b)
  #           ^^
  #     end
  class BlockParameterNode < Node
    # Initialize a new BlockParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: T.nilable(Symbol), name_loc: T.nilable(Location), operator_loc: Location).void }
    def initialize(source, node_id, location, flags, name, name_loc, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: T.nilable(Symbol), name_loc: T.nilable(Location), operator_loc: Location).returns(BlockParameterNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     def a(&b) # name `:b`
    #            ^
    #     end
    sig { returns(T.nilable(Symbol)) }
    def name; end

    # Represents the Location of the block parameter name.
    #
    #     def a(&b)
    #            ^
    sig { returns(T.nilable(Location)) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_name_loc(repository); end

    # Represents the Location of the `&` operator.
    #
    #     def a(&b)
    #           ^
    #     end
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a block's parameters declaration.
  #
  #     -> (a, b = 1; local) { }
  #        ^^^^^^^^^^^^^^^^^
  #
  #     foo do |a, b = 1; local|
  #            ^^^^^^^^^^^^^^^^^
  #     end
  class BlockParametersNode < Node
    # Initialize a new BlockParametersNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, parameters: T.nilable(ParametersNode), locals: T::Array[BlockLocalVariableNode], opening_loc: T.nilable(Location), closing_loc: T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, parameters, locals, opening_loc, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, parameters: T.nilable(ParametersNode), locals: T::Array[BlockLocalVariableNode], opening_loc: T.nilable(Location), closing_loc: T.nilable(Location)).returns(BlockParametersNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), parameters: T.unsafe(nil), locals: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     -> (a, b = 1; local) { }
    #         ^^^^^^^^
    #
    #     foo do |a, b = 1; local|
    #             ^^^^^^^^
    #     end
    sig { returns(T.nilable(ParametersNode)) }
    def parameters; end

    # Represents the local variables of the block.
    #
    #     -> (a, b = 1; local) { }
    #                   ^^^^^
    #
    #     foo do |a, b = 1; local|
    #                       ^^^^^
    #     end
    sig { returns(T::Array[BlockLocalVariableNode]) }
    def locals; end

    # Represents the opening Location of the block parameters.
    #
    #     -> (a, b = 1; local) { }
    #        ^
    #
    #     foo do |a, b = 1; local|
    #            ^
    #     end
    sig { returns(T.nilable(Location)) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_opening_loc(repository); end

    # Represents the closing Location of the block parameters.
    #
    #     -> (a, b = 1; local) { }
    #                        ^
    #
    #     foo do |a, b = 1; local|
    #                            ^
    #     end
    sig { returns(T.nilable(Location)) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(T.nilable(String)) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(T.nilable(String)) }
    def closing; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `break` keyword.
  #
  #     break foo
  #     ^^^^^^^^^
  class BreakNode < Node
    # Initialize a new BreakNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, arguments: T.nilable(ArgumentsNode), keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, arguments, keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, arguments: T.nilable(ArgumentsNode), keyword_loc: Location).returns(BreakNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), arguments: T.unsafe(nil), keyword_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     break foo
    #           ^^^
    sig { returns(T.nilable(ArgumentsNode)) }
    def arguments; end

    # The Location of the `break` keyword.
    #
    #     break foo
    #     ^^^^^
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `&&=` operator on a call.
  #
  #     foo.bar &&= value
  #     ^^^^^^^^^^^^^^^^^
  class CallAndWriteNode < Node
    # Initialize a new CallAndWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: T.nilable(Node), call_operator_loc: T.nilable(Location), message_loc: T.nilable(Location), read_name: Symbol, write_name: Symbol, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, receiver, call_operator_loc, message_loc, read_name, write_name, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, receiver: T.nilable(Node), call_operator_loc: T.nilable(Location), message_loc: T.nilable(Location), read_name: Symbol, write_name: Symbol, operator_loc: Location, value: Node).returns(CallAndWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), call_operator_loc: T.unsafe(nil), message_loc: T.unsafe(nil), read_name: T.unsafe(nil), write_name: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     foo.bar &&= value
    #     ^^^
    sig { returns(T.nilable(Node)) }
    def receiver; end

    # Represents the Location of the call operator.
    #
    #     foo.bar &&= value
    #        ^
    sig { returns(T.nilable(Location)) }
    def call_operator_loc; end

    # Save the call_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_call_operator_loc(repository); end

    # Represents the Location of the message.
    #
    #     foo.bar &&= value
    #         ^^^
    sig { returns(T.nilable(Location)) }
    def message_loc; end

    # Save the message_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_message_loc(repository); end

    # Represents the name of the method being called.
    #
    #     foo.bar &&= value # read_name `:bar`
    #         ^^^
    sig { returns(Symbol) }
    def read_name; end

    # Represents the name of the method being written to.
    #
    #     foo.bar &&= value # write_name `:bar=`
    #         ^^^
    sig { returns(Symbol) }
    def write_name; end

    # Represents the Location of the operator.
    #
    #     foo.bar &&= value
    #             ^^^
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Represents the value being assigned.
    #
    #     foo.bar &&= value
    #                 ^^^^^
    sig { returns(Node) }
    def value; end

    # Slice the location of call_operator_loc from the source.
    sig { returns(T.nilable(String)) }
    def call_operator; end

    # Slice the location of message_loc from the source.
    sig { returns(T.nilable(String)) }
    def message; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a method call, in all of the various forms that can take.
  #
  #     foo
  #     ^^^
  #
  #     foo()
  #     ^^^^^
  #
  #     +foo
  #     ^^^^
  #
  #     foo + bar
  #     ^^^^^^^^^
  #
  #     foo.bar
  #     ^^^^^^^
  #
  #     foo&.bar
  #     ^^^^^^^^
  class CallNode < Node
    # Initialize a new CallNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: T.nilable(Node), call_operator_loc: T.nilable(Location), name: Symbol, message_loc: T.nilable(Location), opening_loc: T.nilable(Location), arguments: T.nilable(ArgumentsNode), closing_loc: T.nilable(Location), equal_loc: T.nilable(Location), block: T.nilable(T.any(BlockNode, BlockArgumentNode))).void }
    def initialize(source, node_id, location, flags, receiver, call_operator_loc, name, message_loc, opening_loc, arguments, closing_loc, equal_loc, block); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, receiver: T.nilable(Node), call_operator_loc: T.nilable(Location), name: Symbol, message_loc: T.nilable(Location), opening_loc: T.nilable(Location), arguments: T.nilable(ArgumentsNode), closing_loc: T.nilable(Location), equal_loc: T.nilable(Location), block: T.nilable(T.any(BlockNode, BlockArgumentNode))).returns(CallNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), call_operator_loc: T.unsafe(nil), name: T.unsafe(nil), message_loc: T.unsafe(nil), opening_loc: T.unsafe(nil), arguments: T.unsafe(nil), closing_loc: T.unsafe(nil), equal_loc: T.unsafe(nil), block: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     foo.bar
    #     ^^^
    #
    #     +foo
    #      ^^^
    #
    #     foo + bar
    #     ^^^
    sig { returns(T.nilable(Node)) }
    def receiver; end

    # Represents the Location of the call operator.
    #
    #     foo.bar
    #        ^
    #
    #     foo&.bar
    #        ^^
    sig { returns(T.nilable(Location)) }
    def call_operator_loc; end

    # Save the call_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_call_operator_loc(repository); end

    # Represents the name of the method being called.
    #
    #     foo.bar # name `:foo`
    #     ^^^
    sig { returns(Symbol) }
    def name; end

    # Represents the Location of the message.
    #
    #     foo.bar
    #         ^^^
    sig { returns(T.nilable(Location)) }
    def message_loc; end

    # Save the message_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_message_loc(repository); end

    # Represents the Location of the left parenthesis.
    #
    #     foo(bar)
    #        ^
    sig { returns(T.nilable(Location)) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_opening_loc(repository); end

    # Represents the arguments to the method call. These can be any [non-void expressions](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    #     foo(bar)
    #         ^^^
    sig { returns(T.nilable(ArgumentsNode)) }
    def arguments; end

    # Represents the Location of the right parenthesis.
    #
    #     foo(bar)
    #            ^
    sig { returns(T.nilable(Location)) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_closing_loc(repository); end

    # Represents the Location of the equal sign, in the case that this is an attribute write.
    #
    #     foo.bar = value
    #             ^
    #
    #     foo[bar] = value
    #              ^
    sig { returns(T.nilable(Location)) }
    def equal_loc; end

    # Save the equal_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_equal_loc(repository); end

    # Represents the block that is being passed to the method.
    #
    #     foo { |a| a }
    #         ^^^^^^^^^
    sig { returns(T.nilable(T.any(BlockNode, BlockArgumentNode))) }
    def block; end

    # Slice the location of call_operator_loc from the source.
    sig { returns(T.nilable(String)) }
    def call_operator; end

    # Slice the location of message_loc from the source.
    sig { returns(T.nilable(String)) }
    def message; end

    # Slice the location of opening_loc from the source.
    sig { returns(T.nilable(String)) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(T.nilable(String)) }
    def closing; end

    # Slice the location of equal_loc from the source.
    sig { returns(T.nilable(String)) }
    def equal; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of an assignment operator on a call.
  #
  #     foo.bar += baz
  #     ^^^^^^^^^^^^^^
  class CallOperatorWriteNode < Node
    # Initialize a new CallOperatorWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: T.nilable(Node), call_operator_loc: T.nilable(Location), message_loc: T.nilable(Location), read_name: Symbol, write_name: Symbol, binary_operator: Symbol, binary_operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, receiver, call_operator_loc, message_loc, read_name, write_name, binary_operator, binary_operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, receiver: T.nilable(Node), call_operator_loc: T.nilable(Location), message_loc: T.nilable(Location), read_name: Symbol, write_name: Symbol, binary_operator: Symbol, binary_operator_loc: Location, value: Node).returns(CallOperatorWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), call_operator_loc: T.unsafe(nil), message_loc: T.unsafe(nil), read_name: T.unsafe(nil), write_name: T.unsafe(nil), binary_operator: T.unsafe(nil), binary_operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     foo.bar += value
    #     ^^^
    sig { returns(T.nilable(Node)) }
    def receiver; end

    # Represents the Location of the call operator.
    #
    #     foo.bar += value
    #        ^
    sig { returns(T.nilable(Location)) }
    def call_operator_loc; end

    # Save the call_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_call_operator_loc(repository); end

    # Represents the Location of the message.
    #
    #     foo.bar += value
    #         ^^^
    sig { returns(T.nilable(Location)) }
    def message_loc; end

    # Save the message_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_message_loc(repository); end

    # Represents the name of the method being called.
    #
    #     foo.bar += value # read_name `:bar`
    #         ^^^
    sig { returns(Symbol) }
    def read_name; end

    # Represents the name of the method being written to.
    #
    #     foo.bar += value # write_name `:bar=`
    #         ^^^
    sig { returns(Symbol) }
    def write_name; end

    # Represents the binary operator being used.
    #
    #     foo.bar += value # binary_operator `:+`
    #             ^
    sig { returns(Symbol) }
    def binary_operator; end

    # Represents the Location of the binary operator.
    #
    #     foo.bar += value
    #             ^^
    sig { returns(Location) }
    def binary_operator_loc; end

    # Save the binary_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_binary_operator_loc(repository); end

    # Represents the value being assigned.
    #
    #     foo.bar += value
    #                ^^^^^
    sig { returns(Node) }
    def value; end

    # Slice the location of call_operator_loc from the source.
    sig { returns(T.nilable(String)) }
    def call_operator; end

    # Slice the location of message_loc from the source.
    sig { returns(T.nilable(String)) }
    def message; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `||=` operator on a call.
  #
  #     foo.bar ||= value
  #     ^^^^^^^^^^^^^^^^^
  class CallOrWriteNode < Node
    # Initialize a new CallOrWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: T.nilable(Node), call_operator_loc: T.nilable(Location), message_loc: T.nilable(Location), read_name: Symbol, write_name: Symbol, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, receiver, call_operator_loc, message_loc, read_name, write_name, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, receiver: T.nilable(Node), call_operator_loc: T.nilable(Location), message_loc: T.nilable(Location), read_name: Symbol, write_name: Symbol, operator_loc: Location, value: Node).returns(CallOrWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), call_operator_loc: T.unsafe(nil), message_loc: T.unsafe(nil), read_name: T.unsafe(nil), write_name: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     foo.bar ||= value
    #     ^^^
    sig { returns(T.nilable(Node)) }
    def receiver; end

    # Represents the Location of the call operator.
    #
    #     foo.bar ||= value
    #        ^
    sig { returns(T.nilable(Location)) }
    def call_operator_loc; end

    # Save the call_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_call_operator_loc(repository); end

    # Represents the Location of the message.
    #
    #     foo.bar ||= value
    #         ^^^
    sig { returns(T.nilable(Location)) }
    def message_loc; end

    # Save the message_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_message_loc(repository); end

    # Represents the name of the method being called.
    #
    #     foo.bar ||= value # read_name `:bar`
    #         ^^^
    sig { returns(Symbol) }
    def read_name; end

    # Represents the name of the method being written to.
    #
    #     foo.bar ||= value # write_name `:bar=`
    #         ^^^
    sig { returns(Symbol) }
    def write_name; end

    # Represents the Location of the operator.
    #
    #     foo.bar ||= value
    #             ^^^
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Represents the value being assigned.
    #
    #     foo.bar ||= value
    #                 ^^^^^
    sig { returns(Node) }
    def value; end

    # Slice the location of call_operator_loc from the source.
    sig { returns(T.nilable(String)) }
    def call_operator; end

    # Slice the location of message_loc from the source.
    sig { returns(T.nilable(String)) }
    def message; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents assigning to a method call.
  #
  #     foo.bar, = 1
  #     ^^^^^^^
  #
  #     begin
  #     rescue => foo.bar
  #               ^^^^^^^
  #     end
  #
  #     for foo.bar in baz do end
  #         ^^^^^^^
  class CallTargetNode < Node
    # Initialize a new CallTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: Node, call_operator_loc: Location, name: Symbol, message_loc: Location).void }
    def initialize(source, node_id, location, flags, receiver, call_operator_loc, name, message_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, receiver: Node, call_operator_loc: Location, name: Symbol, message_loc: Location).returns(CallTargetNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), call_operator_loc: T.unsafe(nil), name: T.unsafe(nil), message_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     foo.bar = 1
    #     ^^^
    sig { returns(Node) }
    def receiver; end

    # Represents the Location of the call operator.
    #
    #     foo.bar = 1
    #        ^
    sig { returns(Location) }
    def call_operator_loc; end

    # Save the call_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_call_operator_loc(repository); end

    # Represents the name of the method being called.
    #
    #     foo.bar = 1 # name `:foo`
    #     ^^^
    sig { returns(Symbol) }
    def name; end

    # Represents the Location of the message.
    #
    #     foo.bar = 1
    #         ^^^
    sig { returns(Location) }
    def message_loc; end

    # Save the message_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_message_loc(repository); end

    # Slice the location of call_operator_loc from the source.
    sig { returns(String) }
    def call_operator; end

    # Slice the location of message_loc from the source.
    sig { returns(String) }
    def message; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents assigning to a local variable in pattern matching.
  #
  #     foo => [bar => baz]
  #            ^^^^^^^^^^^^
  class CapturePatternNode < Node
    # Initialize a new CapturePatternNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, value: Node, target: LocalVariableTargetNode, operator_loc: Location).void }
    def initialize(source, node_id, location, flags, value, target, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, value: Node, target: LocalVariableTargetNode, operator_loc: Location).returns(CapturePatternNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), value: T.unsafe(nil), target: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     foo => bar
    #            ^^^
    sig { returns(Node) }
    def value; end

    # Represents the target of the capture.
    #
    #     foo => bar
    #     ^^^
    sig { returns(LocalVariableTargetNode) }
    def target; end

    # Represents the Location of the `=>` operator.
    #
    #     foo => bar
    #         ^^
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of a case statement for pattern matching.
  #
  #     case true
  #     in false
  #     end
  #     ^^^^^^^^^
  class CaseMatchNode < Node
    # Initialize a new CaseMatchNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, predicate: T.nilable(Node), conditions: T::Array[InNode], else_clause: T.nilable(ElseNode), case_keyword_loc: Location, end_keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, predicate, conditions, else_clause, case_keyword_loc, end_keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, predicate: T.nilable(Node), conditions: T::Array[InNode], else_clause: T.nilable(ElseNode), case_keyword_loc: Location, end_keyword_loc: Location).returns(CaseMatchNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), predicate: T.unsafe(nil), conditions: T.unsafe(nil), else_clause: T.unsafe(nil), case_keyword_loc: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     case true; in false; end
    #     ^^^^
    sig { returns(T.nilable(Node)) }
    def predicate; end

    # Represents the conditions of the case match.
    #
    #     case true; in false; end
    #                ^^^^^^^^
    sig { returns(T::Array[InNode]) }
    def conditions; end

    # Represents the else clause of the case match.
    #
    #     case true; in false; else; end
    #                          ^^^^
    sig { returns(T.nilable(ElseNode)) }
    def else_clause; end

    # Represents the Location of the `case` keyword.
    #
    #     case true; in false; end
    #     ^^^^
    sig { returns(Location) }
    def case_keyword_loc; end

    # Save the case_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_case_keyword_loc(repository); end

    # Represents the Location of the `end` keyword.
    #
    #     case true; in false; end
    #                          ^^^
    sig { returns(Location) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_end_keyword_loc(repository); end

    # Slice the location of case_keyword_loc from the source.
    sig { returns(String) }
    def case_keyword; end

    # Slice the location of end_keyword_loc from the source.
    sig { returns(String) }
    def end_keyword; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of a case statement.
  #
  #     case true
  #     when false
  #     end
  #     ^^^^^^^^^^
  class CaseNode < Node
    # Initialize a new CaseNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, predicate: T.nilable(Node), conditions: T::Array[WhenNode], else_clause: T.nilable(ElseNode), case_keyword_loc: Location, end_keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, predicate, conditions, else_clause, case_keyword_loc, end_keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, predicate: T.nilable(Node), conditions: T::Array[WhenNode], else_clause: T.nilable(ElseNode), case_keyword_loc: Location, end_keyword_loc: Location).returns(CaseNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), predicate: T.unsafe(nil), conditions: T.unsafe(nil), else_clause: T.unsafe(nil), case_keyword_loc: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     case true; when false; end
    #          ^^^^
    sig { returns(T.nilable(Node)) }
    def predicate; end

    # Represents the conditions of the case statement.
    #
    #     case true; when false; end
    #                ^^^^^^^^^^
    sig { returns(T::Array[WhenNode]) }
    def conditions; end

    # Represents the else clause of the case statement.
    #
    #     case true; when false; else; end
    #                            ^^^^
    sig { returns(T.nilable(ElseNode)) }
    def else_clause; end

    # Represents the Location of the `case` keyword.
    #
    #     case true; when false; end
    #     ^^^^
    sig { returns(Location) }
    def case_keyword_loc; end

    # Save the case_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_case_keyword_loc(repository); end

    # Represents the Location of the `end` keyword.
    #
    #     case true; when false; end
    #                            ^^^
    sig { returns(Location) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_end_keyword_loc(repository); end

    # Slice the location of case_keyword_loc from the source.
    sig { returns(String) }
    def case_keyword; end

    # Slice the location of end_keyword_loc from the source.
    sig { returns(String) }
    def end_keyword; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a class declaration involving the `class` keyword.
  #
  #     class Foo end
  #     ^^^^^^^^^^^^^
  class ClassNode < Node
    # Initialize a new ClassNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], class_keyword_loc: Location, constant_path: T.any(ConstantReadNode, ConstantPathNode, CallNode), inheritance_operator_loc: T.nilable(Location), superclass: T.nilable(Node), body: T.nilable(T.any(StatementsNode, BeginNode)), end_keyword_loc: Location, name: Symbol).void }
    def initialize(source, node_id, location, flags, locals, class_keyword_loc, constant_path, inheritance_operator_loc, superclass, body, end_keyword_loc, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], class_keyword_loc: Location, constant_path: T.any(ConstantReadNode, ConstantPathNode, CallNode), inheritance_operator_loc: T.nilable(Location), superclass: T.nilable(Node), body: T.nilable(T.any(StatementsNode, BeginNode)), end_keyword_loc: Location, name: Symbol).returns(ClassNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), locals: T.unsafe(nil), class_keyword_loc: T.unsafe(nil), constant_path: T.unsafe(nil), inheritance_operator_loc: T.unsafe(nil), superclass: T.unsafe(nil), body: T.unsafe(nil), end_keyword_loc: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     class Foo end
    #     ^^^^^
    sig { returns(Location) }
    def class_keyword_loc; end

    # Save the class_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_class_keyword_loc(repository); end

    # Returns the `constant_path` attribute.
    sig { returns(T.any(ConstantReadNode, ConstantPathNode, CallNode)) }
    def constant_path; end

    # Represents the Location of the `<` operator.
    #
    #     class Foo < Bar
    #               ^
    sig { returns(T.nilable(Location)) }
    def inheritance_operator_loc; end

    # Save the inheritance_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_inheritance_operator_loc(repository); end

    # Represents the superclass of the class.
    #
    #     class Foo < Bar
    #                 ^^^
    sig { returns(T.nilable(Node)) }
    def superclass; end

    # Represents the body of the class.
    #
    #     class Foo
    #       foo
    #       ^^^
    sig { returns(T.nilable(T.any(StatementsNode, BeginNode))) }
    def body; end

    # Represents the Location of the `end` keyword.
    #
    #     class Foo end
    #               ^^^
    sig { returns(Location) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_end_keyword_loc(repository); end

    # The name of the class.
    #
    #     class Foo end # name `:Foo`
    sig { returns(Symbol) }
    def name; end

    # Slice the location of class_keyword_loc from the source.
    sig { returns(String) }
    def class_keyword; end

    # Slice the location of inheritance_operator_loc from the source.
    sig { returns(T.nilable(String)) }
    def inheritance_operator; end

    # Slice the location of end_keyword_loc from the source.
    sig { returns(String) }
    def end_keyword; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `&&=` operator for assignment to a class variable.
  #
  #     @@target &&= value
  #     ^^^^^^^^^^^^^^^^^^
  class ClassVariableAndWriteNode < Node
    # Initialize a new ClassVariableAndWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, name, name_loc, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(ClassVariableAndWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     @@target &&= value # name `:@@target`
    #     ^^^^^^^^
    sig { returns(Symbol) }
    def name; end

    # Represents the Location of the variable name.
    #
    #     @@target &&= value
    #     ^^^^^^^^
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Represents the Location of the `&&=` operator.
    #
    #     @@target &&= value
    #              ^^^
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Represents the value being assigned. This can be any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    #     @@target &&= value
    #                  ^^^^^
    sig { returns(Node) }
    def value; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents assigning to a class variable using an operator that isn't `=`.
  #
  #     @@target += value
  #     ^^^^^^^^^^^^^^^^^
  class ClassVariableOperatorWriteNode < Node
    # Initialize a new ClassVariableOperatorWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, binary_operator_loc: Location, value: Node, binary_operator: Symbol).void }
    def initialize(source, node_id, location, flags, name, name_loc, binary_operator_loc, value, binary_operator); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, binary_operator_loc: Location, value: Node, binary_operator: Symbol).returns(ClassVariableOperatorWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), binary_operator_loc: T.unsafe(nil), value: T.unsafe(nil), binary_operator: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `binary_operator_loc`.
    sig { returns(Location) }
    def binary_operator_loc; end

    # Save the binary_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_binary_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Returns the `binary_operator` attribute.
    sig { returns(Symbol) }
    def binary_operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `||=` operator for assignment to a class variable.
  #
  #     @@target ||= value
  #     ^^^^^^^^^^^^^^^^^^
  class ClassVariableOrWriteNode < Node
    # Initialize a new ClassVariableOrWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, name, name_loc, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(ClassVariableOrWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents referencing a class variable.
  #
  #     @@foo
  #     ^^^^^
  class ClassVariableReadNode < Node
    # Initialize a new ClassVariableReadNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).void }
    def initialize(source, node_id, location, flags, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(ClassVariableReadNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     @@abc   # name `:@@abc`
    #
    #     @@_test # name `:@@_test`
    sig { returns(Symbol) }
    def name; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing to a class variable in a context that doesn't have an explicit value.
  #
  #     @@foo, @@bar = baz
  #     ^^^^^  ^^^^^
  class ClassVariableTargetNode < Node
    # Initialize a new ClassVariableTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).void }
    def initialize(source, node_id, location, flags, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(ClassVariableTargetNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing to a class variable.
  #
  #     @@foo = 1
  #     ^^^^^^^^^
  class ClassVariableWriteNode < Node
    # Initialize a new ClassVariableWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, value: Node, operator_loc: Location).void }
    def initialize(source, node_id, location, flags, name, name_loc, value, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, value: Node, operator_loc: Location).returns(ClassVariableWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), value: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     @@abc = 123     # name `@@abc`
    #
    #     @@_test = :test # name `@@_test`
    sig { returns(Symbol) }
    def name; end

    # The Location of the variable name.
    #
    #     @@foo = :bar
    #     ^^^^^
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # The value to write to the class variable. This can be any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    #     @@foo = :bar
    #             ^^^^
    #
    #     @@_xyz = 123
    #              ^^^
    sig { returns(Node) }
    def value; end

    # The Location of the `=` operator.
    #
    #     @@foo = :bar
    #           ^
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `&&=` operator for assignment to a constant.
  #
  #     Target &&= value
  #     ^^^^^^^^^^^^^^^^
  class ConstantAndWriteNode < Node
    # Initialize a new ConstantAndWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, name, name_loc, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(ConstantAndWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents assigning to a constant using an operator that isn't `=`.
  #
  #     Target += value
  #     ^^^^^^^^^^^^^^^
  class ConstantOperatorWriteNode < Node
    # Initialize a new ConstantOperatorWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, binary_operator_loc: Location, value: Node, binary_operator: Symbol).void }
    def initialize(source, node_id, location, flags, name, name_loc, binary_operator_loc, value, binary_operator); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, binary_operator_loc: Location, value: Node, binary_operator: Symbol).returns(ConstantOperatorWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), binary_operator_loc: T.unsafe(nil), value: T.unsafe(nil), binary_operator: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `binary_operator_loc`.
    sig { returns(Location) }
    def binary_operator_loc; end

    # Save the binary_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_binary_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Returns the `binary_operator` attribute.
    sig { returns(Symbol) }
    def binary_operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `||=` operator for assignment to a constant.
  #
  #     Target ||= value
  #     ^^^^^^^^^^^^^^^^
  class ConstantOrWriteNode < Node
    # Initialize a new ConstantOrWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, name, name_loc, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(ConstantOrWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `&&=` operator for assignment to a constant path.
  #
  #     Parent::Child &&= value
  #     ^^^^^^^^^^^^^^^^^^^^^^^
  class ConstantPathAndWriteNode < Node
    # Initialize a new ConstantPathAndWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, target: ConstantPathNode, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, target, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, target: ConstantPathNode, operator_loc: Location, value: Node).returns(ConstantPathAndWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), target: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents accessing a constant through a path of `::` operators.
  #
  #     Foo::Bar
  #     ^^^^^^^^
  class ConstantPathNode < Node
    # Initialize a new ConstantPathNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, parent: T.nilable(Node), name: T.nilable(Symbol), delimiter_loc: Location, name_loc: Location).void }
    def initialize(source, node_id, location, flags, parent, name, delimiter_loc, name_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, parent: T.nilable(Node), name: T.nilable(Symbol), delimiter_loc: Location, name_loc: Location).returns(ConstantPathNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), parent: T.unsafe(nil), name: T.unsafe(nil), delimiter_loc: T.unsafe(nil), name_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     Foo::Bar
    #     ^^^
    #
    #     self::Test
    #     ^^^^
    #
    #     a.b::C
    #     ^^^
    sig { returns(T.nilable(Node)) }
    def parent; end

    # The name of the constant being accessed. This could be `nil` in the event of a syntax error.
    sig { returns(T.nilable(Symbol)) }
    def name; end

    # The Location of the `::` delimiter.
    #
    #     ::Foo
    #     ^^
    #
    #     One::Two
    #        ^^
    sig { returns(Location) }
    def delimiter_loc; end

    # Save the delimiter_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_delimiter_loc(repository); end

    # The Location of the name of the constant.
    #
    #     ::Foo
    #       ^^^
    #
    #     One::Two
    #          ^^^
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Slice the location of delimiter_loc from the source.
    sig { returns(String) }
    def delimiter; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents assigning to a constant path using an operator that isn't `=`.
  #
  #     Parent::Child += value
  #     ^^^^^^^^^^^^^^^^^^^^^^
  class ConstantPathOperatorWriteNode < Node
    # Initialize a new ConstantPathOperatorWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, target: ConstantPathNode, binary_operator_loc: Location, value: Node, binary_operator: Symbol).void }
    def initialize(source, node_id, location, flags, target, binary_operator_loc, value, binary_operator); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, target: ConstantPathNode, binary_operator_loc: Location, value: Node, binary_operator: Symbol).returns(ConstantPathOperatorWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), target: T.unsafe(nil), binary_operator_loc: T.unsafe(nil), value: T.unsafe(nil), binary_operator: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_binary_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Returns the `binary_operator` attribute.
    sig { returns(Symbol) }
    def binary_operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `||=` operator for assignment to a constant path.
  #
  #     Parent::Child ||= value
  #     ^^^^^^^^^^^^^^^^^^^^^^^
  class ConstantPathOrWriteNode < Node
    # Initialize a new ConstantPathOrWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, target: ConstantPathNode, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, target, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, target: ConstantPathNode, operator_loc: Location, value: Node).returns(ConstantPathOrWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), target: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing to a constant path in a context that doesn't have an explicit value.
  #
  #     Foo::Foo, Bar::Bar = baz
  #     ^^^^^^^^  ^^^^^^^^
  class ConstantPathTargetNode < Node
    # Initialize a new ConstantPathTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, parent: T.nilable(Node), name: T.nilable(Symbol), delimiter_loc: Location, name_loc: Location).void }
    def initialize(source, node_id, location, flags, parent, name, delimiter_loc, name_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, parent: T.nilable(Node), name: T.nilable(Symbol), delimiter_loc: Location, name_loc: Location).returns(ConstantPathTargetNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), parent: T.unsafe(nil), name: T.unsafe(nil), delimiter_loc: T.unsafe(nil), name_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { returns(T.nilable(Node)) }
    def parent; end

    # Returns the `name` attribute.
    sig { returns(T.nilable(Symbol)) }
    def name; end

    # Returns the Location represented by `delimiter_loc`.
    sig { returns(Location) }
    def delimiter_loc; end

    # Save the delimiter_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_delimiter_loc(repository); end

    # Returns the Location represented by `name_loc`.
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Slice the location of delimiter_loc from the source.
    sig { returns(String) }
    def delimiter; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing to a constant path.
  #
  #     ::Foo = 1
  #     ^^^^^^^^^
  #
  #     Foo::Bar = 1
  #     ^^^^^^^^^^^^
  #
  #     ::Foo::Bar = 1
  #     ^^^^^^^^^^^^^^
  class ConstantPathWriteNode < Node
    # Initialize a new ConstantPathWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, target: ConstantPathNode, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, target, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, target: ConstantPathNode, operator_loc: Location, value: Node).returns(ConstantPathWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), target: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     Foo::Bar = 1
    #     ^^^^^^^^
    #
    #     ::Foo = :abc
    #     ^^^^^
    sig { returns(ConstantPathNode) }
    def target; end

    # The Location of the `=` operator.
    #
    #     ::ABC = 123
    #           ^
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # The value to write to the constant path. It can be any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    #     FOO::BAR = :abc
    #                ^^^^
    sig { returns(Node) }
    def value; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents referencing a constant.
  #
  #     Foo
  #     ^^^
  class ConstantReadNode < Node
    # Initialize a new ConstantReadNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).void }
    def initialize(source, node_id, location, flags, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(ConstantReadNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     X              # name `:X`
    #
    #     SOME_CONSTANT  # name `:SOME_CONSTANT`
    sig { returns(Symbol) }
    def name; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing to a constant in a context that doesn't have an explicit value.
  #
  #     Foo, Bar = baz
  #     ^^^  ^^^
  class ConstantTargetNode < Node
    # Initialize a new ConstantTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).void }
    def initialize(source, node_id, location, flags, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(ConstantTargetNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing to a constant.
  #
  #     Foo = 1
  #     ^^^^^^^
  class ConstantWriteNode < Node
    # Initialize a new ConstantWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, value: Node, operator_loc: Location).void }
    def initialize(source, node_id, location, flags, name, name_loc, value, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, value: Node, operator_loc: Location).returns(ConstantWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), value: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     Foo = :bar # name `:Foo`
    #
    #     XYZ = 1    # name `:XYZ`
    sig { returns(Symbol) }
    def name; end

    # The Location of the constant name.
    #
    #     FOO = 1
    #     ^^^
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # The value to write to the constant. It can be any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    #     FOO = :bar
    #           ^^^^
    #
    #     MyClass = Class.new
    #               ^^^^^^^^^
    sig { returns(Node) }
    def value; end

    # The Location of the `=` operator.
    #
    #     FOO = :bar
    #         ^
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a method definition.
  #
  #     def method
  #     end
  #     ^^^^^^^^^^
  class DefNode < Node
    # Initialize a new DefNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, receiver: T.nilable(Node), parameters: T.nilable(ParametersNode), body: T.nilable(T.any(StatementsNode, BeginNode)), locals: T::Array[Symbol], def_keyword_loc: Location, operator_loc: T.nilable(Location), lparen_loc: T.nilable(Location), rparen_loc: T.nilable(Location), equal_loc: T.nilable(Location), end_keyword_loc: T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, name, name_loc, receiver, parameters, body, locals, def_keyword_loc, operator_loc, lparen_loc, rparen_loc, equal_loc, end_keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, receiver: T.nilable(Node), parameters: T.nilable(ParametersNode), body: T.nilable(T.any(StatementsNode, BeginNode)), locals: T::Array[Symbol], def_keyword_loc: Location, operator_loc: T.nilable(Location), lparen_loc: T.nilable(Location), rparen_loc: T.nilable(Location), equal_loc: T.nilable(Location), end_keyword_loc: T.nilable(Location)).returns(DefNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), receiver: T.unsafe(nil), parameters: T.unsafe(nil), body: T.unsafe(nil), locals: T.unsafe(nil), def_keyword_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), lparen_loc: T.unsafe(nil), rparen_loc: T.unsafe(nil), equal_loc: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the `receiver` attribute.
    sig { returns(T.nilable(Node)) }
    def receiver; end

    # Returns the `parameters` attribute.
    sig { returns(T.nilable(ParametersNode)) }
    def parameters; end

    # Returns the `body` attribute.
    sig { returns(T.nilable(T.any(StatementsNode, BeginNode))) }
    def body; end

    # Returns the `locals` attribute.
    sig { returns(T::Array[Symbol]) }
    def locals; end

    # Returns the Location represented by `def_keyword_loc`.
    sig { returns(Location) }
    def def_keyword_loc; end

    # Save the def_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_def_keyword_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(T.nilable(Location)) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_operator_loc(repository); end

    # Returns the Location represented by `lparen_loc`.
    sig { returns(T.nilable(Location)) }
    def lparen_loc; end

    # Save the lparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_lparen_loc(repository); end

    # Returns the Location represented by `rparen_loc`.
    sig { returns(T.nilable(Location)) }
    def rparen_loc; end

    # Save the rparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_rparen_loc(repository); end

    # Returns the Location represented by `equal_loc`.
    sig { returns(T.nilable(Location)) }
    def equal_loc; end

    # Save the equal_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_equal_loc(repository); end

    # Returns the Location represented by `end_keyword_loc`.
    sig { returns(T.nilable(Location)) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_end_keyword_loc(repository); end

    # Slice the location of def_keyword_loc from the source.
    sig { returns(String) }
    def def_keyword; end

    # Slice the location of operator_loc from the source.
    sig { returns(T.nilable(String)) }
    def operator; end

    # Slice the location of lparen_loc from the source.
    sig { returns(T.nilable(String)) }
    def lparen; end

    # Slice the location of rparen_loc from the source.
    sig { returns(T.nilable(String)) }
    def rparen; end

    # Slice the location of equal_loc from the source.
    sig { returns(T.nilable(String)) }
    def equal; end

    # Slice the location of end_keyword_loc from the source.
    sig { returns(T.nilable(String)) }
    def end_keyword; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `defined?` keyword.
  #
  #     defined?(a)
  #     ^^^^^^^^^^^
  class DefinedNode < Node
    # Initialize a new DefinedNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, lparen_loc: T.nilable(Location), value: Node, rparen_loc: T.nilable(Location), keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, lparen_loc, value, rparen_loc, keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, lparen_loc: T.nilable(Location), value: Node, rparen_loc: T.nilable(Location), keyword_loc: Location).returns(DefinedNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), lparen_loc: T.unsafe(nil), value: T.unsafe(nil), rparen_loc: T.unsafe(nil), keyword_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { returns(T.nilable(Location)) }
    def lparen_loc; end

    # Save the lparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_lparen_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Returns the Location represented by `rparen_loc`.
    sig { returns(T.nilable(Location)) }
    def rparen_loc; end

    # Save the rparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_rparen_loc(repository); end

    # Returns the Location represented by `keyword_loc`.
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Slice the location of lparen_loc from the source.
    sig { returns(T.nilable(String)) }
    def lparen; end

    # Slice the location of rparen_loc from the source.
    sig { returns(T.nilable(String)) }
    def rparen; end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an `else` clause in a `case`, `if`, or `unless` statement.
  #
  #     if a then b else c end
  #                 ^^^^^^^^^^
  class ElseNode < Node
    # Initialize a new ElseNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, else_keyword_loc: Location, statements: T.nilable(StatementsNode), end_keyword_loc: T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, else_keyword_loc, statements, end_keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, else_keyword_loc: Location, statements: T.nilable(StatementsNode), end_keyword_loc: T.nilable(Location)).returns(ElseNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), else_keyword_loc: T.unsafe(nil), statements: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_else_keyword_loc(repository); end

    # Returns the `statements` attribute.
    sig { returns(T.nilable(StatementsNode)) }
    def statements; end

    # Returns the Location represented by `end_keyword_loc`.
    sig { returns(T.nilable(Location)) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_end_keyword_loc(repository); end

    # Slice the location of else_keyword_loc from the source.
    sig { returns(String) }
    def else_keyword; end

    # Slice the location of end_keyword_loc from the source.
    sig { returns(T.nilable(String)) }
    def end_keyword; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an interpolated set of statements.
  #
  #     "foo #{bar}"
  #          ^^^^^^
  class EmbeddedStatementsNode < Node
    # Initialize a new EmbeddedStatementsNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: Location, statements: T.nilable(StatementsNode), closing_loc: Location).void }
    def initialize(source, node_id, location, flags, opening_loc, statements, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, opening_loc: Location, statements: T.nilable(StatementsNode), closing_loc: Location).returns(EmbeddedStatementsNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), statements: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the `statements` attribute.
    sig { returns(T.nilable(StatementsNode)) }
    def statements; end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an interpolated variable.
  #
  #     "foo #@bar"
  #          ^^^^^
  class EmbeddedVariableNode < Node
    # Initialize a new EmbeddedVariableNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, operator_loc: Location, variable: T.any(InstanceVariableReadNode, ClassVariableReadNode, GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode)).void }
    def initialize(source, node_id, location, flags, operator_loc, variable); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, operator_loc: Location, variable: T.any(InstanceVariableReadNode, ClassVariableReadNode, GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode)).returns(EmbeddedVariableNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), operator_loc: T.unsafe(nil), variable: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `variable` attribute.
    sig { returns(T.any(InstanceVariableReadNode, ClassVariableReadNode, GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode)) }
    def variable; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an `ensure` clause in a `begin` statement.
  #
  #     begin
  #       foo
  #     ensure
  #     ^^^^^^
  #       bar
  #     end
  class EnsureNode < Node
    # Initialize a new EnsureNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, ensure_keyword_loc: Location, statements: T.nilable(StatementsNode), end_keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, ensure_keyword_loc, statements, end_keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, ensure_keyword_loc: Location, statements: T.nilable(StatementsNode), end_keyword_loc: Location).returns(EnsureNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), ensure_keyword_loc: T.unsafe(nil), statements: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_ensure_keyword_loc(repository); end

    # Returns the `statements` attribute.
    sig { returns(T.nilable(StatementsNode)) }
    def statements; end

    # Returns the Location represented by `end_keyword_loc`.
    sig { returns(Location) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_end_keyword_loc(repository); end

    # Slice the location of ensure_keyword_loc from the source.
    sig { returns(String) }
    def ensure_keyword; end

    # Slice the location of end_keyword_loc from the source.
    sig { returns(String) }
    def end_keyword; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the literal `false` keyword.
  #
  #     false
  #     ^^^^^
  class FalseNode < Node
    # Initialize a new FalseNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(FalseNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a find pattern in pattern matching.
  #
  #     foo in *bar, baz, *qux
  #            ^^^^^^^^^^^^^^^
  #
  #     foo in [*bar, baz, *qux]
  #            ^^^^^^^^^^^^^^^^^
  #
  #     foo in Foo(*bar, baz, *qux)
  #            ^^^^^^^^^^^^^^^^^^^^
  #
  #     foo => *bar, baz, *qux
  #            ^^^^^^^^^^^^^^^
  class FindPatternNode < Node
    # Initialize a new FindPatternNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, constant: T.nilable(T.any(ConstantPathNode, ConstantReadNode)), left: SplatNode, requireds: T::Array[Node], right: T.any(SplatNode, MissingNode), opening_loc: T.nilable(Location), closing_loc: T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, constant, left, requireds, right, opening_loc, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, constant: T.nilable(T.any(ConstantPathNode, ConstantReadNode)), left: SplatNode, requireds: T::Array[Node], right: T.any(SplatNode, MissingNode), opening_loc: T.nilable(Location), closing_loc: T.nilable(Location)).returns(FindPatternNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), constant: T.unsafe(nil), left: T.unsafe(nil), requireds: T.unsafe(nil), right: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     foo in Foo(*bar, baz, *qux)
    #            ^^^
    sig { returns(T.nilable(T.any(ConstantPathNode, ConstantReadNode))) }
    def constant; end

    # Represents the first wildcard node in the pattern.
    #
    #     foo in *bar, baz, *qux
    #            ^^^^
    #
    #     foo in Foo(*bar, baz, *qux)
    #                ^^^^
    sig { returns(SplatNode) }
    def left; end

    # Represents the nodes in between the wildcards.
    #
    #     foo in *bar, baz, *qux
    #                  ^^^
    #
    #     foo in Foo(*bar, baz, 1, *qux)
    #                      ^^^^^^
    sig { returns(T::Array[Node]) }
    def requireds; end

    # Represents the second wildcard node in the pattern.
    #
    #     foo in *bar, baz, *qux
    #                       ^^^^
    #
    #     foo in Foo(*bar, baz, *qux)
    #                           ^^^^
    sig { returns(T.any(SplatNode, MissingNode)) }
    def right; end

    # The Location of the opening brace.
    #
    #     foo in [*bar, baz, *qux]
    #            ^
    #
    #     foo in Foo(*bar, baz, *qux)
    #               ^
    sig { returns(T.nilable(Location)) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_opening_loc(repository); end

    # The Location of the closing brace.
    #
    #     foo in [*bar, baz, *qux]
    #                            ^
    #
    #     foo in Foo(*bar, baz, *qux)
    #                               ^
    sig { returns(T.nilable(Location)) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(T.nilable(String)) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(T.nilable(String)) }
    def closing; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `..` or `...` operators to create flip flops.
  #
  #     baz if foo .. bar
  #            ^^^^^^^^^^
  class FlipFlopNode < Node
    # Initialize a new FlipFlopNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, left: T.nilable(Node), right: T.nilable(Node), operator_loc: Location).void }
    def initialize(source, node_id, location, flags, left, right, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, left: T.nilable(Node), right: T.nilable(Node), operator_loc: Location).returns(FlipFlopNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), left: T.unsafe(nil), right: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { returns(T.nilable(Node)) }
    def left; end

    # Returns the `right` attribute.
    sig { returns(T.nilable(Node)) }
    def right; end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a floating point number literal.
  #
  #     1.0
  #     ^^^
  class FloatNode < Node
    # Initialize a new FloatNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, value: Float).void }
    def initialize(source, node_id, location, flags, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, value: Float).returns(FloatNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `for` keyword.
  #
  #     for i in a end
  #     ^^^^^^^^^^^^^^
  class ForNode < Node
    # Initialize a new ForNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, index: T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, BackReferenceReadNode, NumberedReferenceReadNode, MissingNode), collection: Node, statements: T.nilable(StatementsNode), for_keyword_loc: Location, in_keyword_loc: Location, do_keyword_loc: T.nilable(Location), end_keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, index, collection, statements, for_keyword_loc, in_keyword_loc, do_keyword_loc, end_keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, index: T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, BackReferenceReadNode, NumberedReferenceReadNode, MissingNode), collection: Node, statements: T.nilable(StatementsNode), for_keyword_loc: Location, in_keyword_loc: Location, do_keyword_loc: T.nilable(Location), end_keyword_loc: Location).returns(ForNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), index: T.unsafe(nil), collection: T.unsafe(nil), statements: T.unsafe(nil), for_keyword_loc: T.unsafe(nil), in_keyword_loc: T.unsafe(nil), do_keyword_loc: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     for i in a end
    #         ^
    sig { returns(T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, BackReferenceReadNode, NumberedReferenceReadNode, MissingNode)) }
    def index; end

    # The collection to iterate over.
    #
    #     for i in a end
    #              ^
    sig { returns(Node) }
    def collection; end

    # Represents the body of statements to execute for each iteration of the loop.
    #
    #     for i in a
    #       foo(i)
    #       ^^^^^^
    #     end
    sig { returns(T.nilable(StatementsNode)) }
    def statements; end

    # The Location of the `for` keyword.
    #
    #     for i in a end
    #     ^^^
    sig { returns(Location) }
    def for_keyword_loc; end

    # Save the for_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_for_keyword_loc(repository); end

    # The Location of the `in` keyword.
    #
    #     for i in a end
    #           ^^
    sig { returns(Location) }
    def in_keyword_loc; end

    # Save the in_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_in_keyword_loc(repository); end

    # The Location of the `do` keyword, if present.
    #
    #     for i in a do end
    #                ^^
    sig { returns(T.nilable(Location)) }
    def do_keyword_loc; end

    # Save the do_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_do_keyword_loc(repository); end

    # The Location of the `end` keyword.
    #
    #     for i in a end
    #                ^^^
    sig { returns(Location) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_end_keyword_loc(repository); end

    # Slice the location of for_keyword_loc from the source.
    sig { returns(String) }
    def for_keyword; end

    # Slice the location of in_keyword_loc from the source.
    sig { returns(String) }
    def in_keyword; end

    # Slice the location of do_keyword_loc from the source.
    sig { returns(T.nilable(String)) }
    def do_keyword; end

    # Slice the location of end_keyword_loc from the source.
    sig { returns(String) }
    def end_keyword; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents forwarding all arguments to this method to another method.
  #
  #     def foo(...)
  #       bar(...)
  #           ^^^
  #     end
  class ForwardingArgumentsNode < Node
    # Initialize a new ForwardingArgumentsNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(ForwardingArgumentsNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the forwarding parameter in a method, block, or lambda declaration.
  #
  #     def foo(...)
  #             ^^^
  #     end
  class ForwardingParameterNode < Node
    # Initialize a new ForwardingParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(ForwardingParameterNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `super` keyword without parentheses or arguments, but which might have a block.
  #
  #     super
  #     ^^^^^
  #
  #     super { 123 }
  #     ^^^^^^^^^^^^^
  #
  # If it has any other arguments, it would be a `SuperNode` instead.
  class ForwardingSuperNode < Node
    # Initialize a new ForwardingSuperNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, block: T.nilable(BlockNode)).void }
    def initialize(source, node_id, location, flags, block); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, block: T.nilable(BlockNode)).returns(ForwardingSuperNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), block: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    # All other arguments are forwarded as normal, except the original block is replaced with the new block.
    sig { returns(T.nilable(BlockNode)) }
    def block; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `&&=` operator for assignment to a global variable.
  #
  #     $target &&= value
  #     ^^^^^^^^^^^^^^^^^
  class GlobalVariableAndWriteNode < Node
    # Initialize a new GlobalVariableAndWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, name, name_loc, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(GlobalVariableAndWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents assigning to a global variable using an operator that isn't `=`.
  #
  #     $target += value
  #     ^^^^^^^^^^^^^^^^
  class GlobalVariableOperatorWriteNode < Node
    # Initialize a new GlobalVariableOperatorWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, binary_operator_loc: Location, value: Node, binary_operator: Symbol).void }
    def initialize(source, node_id, location, flags, name, name_loc, binary_operator_loc, value, binary_operator); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, binary_operator_loc: Location, value: Node, binary_operator: Symbol).returns(GlobalVariableOperatorWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), binary_operator_loc: T.unsafe(nil), value: T.unsafe(nil), binary_operator: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `binary_operator_loc`.
    sig { returns(Location) }
    def binary_operator_loc; end

    # Save the binary_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_binary_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Returns the `binary_operator` attribute.
    sig { returns(Symbol) }
    def binary_operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `||=` operator for assignment to a global variable.
  #
  #     $target ||= value
  #     ^^^^^^^^^^^^^^^^^
  class GlobalVariableOrWriteNode < Node
    # Initialize a new GlobalVariableOrWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, name, name_loc, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(GlobalVariableOrWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents referencing a global variable.
  #
  #     $foo
  #     ^^^^
  class GlobalVariableReadNode < Node
    # Initialize a new GlobalVariableReadNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).void }
    def initialize(source, node_id, location, flags, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(GlobalVariableReadNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     $foo   # name `:$foo`
    #
    #     $_Test # name `:$_Test`
    sig { returns(Symbol) }
    def name; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing to a global variable in a context that doesn't have an explicit value.
  #
  #     $foo, $bar = baz
  #     ^^^^  ^^^^
  class GlobalVariableTargetNode < Node
    # Initialize a new GlobalVariableTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).void }
    def initialize(source, node_id, location, flags, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(GlobalVariableTargetNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing to a global variable.
  #
  #     $foo = 1
  #     ^^^^^^^^
  class GlobalVariableWriteNode < Node
    # Initialize a new GlobalVariableWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, value: Node, operator_loc: Location).void }
    def initialize(source, node_id, location, flags, name, name_loc, value, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, value: Node, operator_loc: Location).returns(GlobalVariableWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), value: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     $foo = :bar  # name `:$foo`
    #
    #     $_Test = 123 # name `:$_Test`
    sig { returns(Symbol) }
    def name; end

    # The Location of the global variable's name.
    #
    #     $foo = :bar
    #     ^^^^
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # The value to write to the global variable. It can be any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    #     $foo = :bar
    #            ^^^^
    #
    #     $-xyz = 123
    #             ^^^
    sig { returns(Node) }
    def value; end

    # The Location of the `=` operator.
    #
    #     $foo = :bar
    #          ^
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a hash literal.
  #
  #     { a => b }
  #     ^^^^^^^^^^
  class HashNode < Node
    # Initialize a new HashNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: Location, elements: T::Array[T.any(AssocNode, AssocSplatNode)], closing_loc: Location).void }
    def initialize(source, node_id, location, flags, opening_loc, elements, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, opening_loc: Location, elements: T::Array[T.any(AssocNode, AssocSplatNode)], closing_loc: Location).returns(HashNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), elements: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     { a => b }
    #     ^
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # The elements of the hash. These can be either `AssocNode`s or `AssocSplatNode`s.
    #
    #     { a: b }
    #       ^^^^
    #
    #     { **foo }
    #       ^^^^^
    sig { returns(T::Array[T.any(AssocNode, AssocSplatNode)]) }
    def elements; end

    # The Location of the closing brace.
    #
    #     { a => b }
    #              ^
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a hash pattern in pattern matching.
  #
  #     foo => { a: 1, b: 2 }
  #            ^^^^^^^^^^^^^^
  #
  #     foo => { a: 1, b: 2, **c }
  #            ^^^^^^^^^^^^^^^^^^^
  #
  #     foo => Bar[a: 1, b: 2]
  #            ^^^^^^^^^^^^^^^
  #
  #     foo in { a: 1, b: 2 }
  #            ^^^^^^^^^^^^^^
  class HashPatternNode < Node
    # Initialize a new HashPatternNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, constant: T.nilable(T.any(ConstantPathNode, ConstantReadNode)), elements: T::Array[AssocNode], rest: T.nilable(T.any(AssocSplatNode, NoKeywordsParameterNode)), opening_loc: T.nilable(Location), closing_loc: T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, constant, elements, rest, opening_loc, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, constant: T.nilable(T.any(ConstantPathNode, ConstantReadNode)), elements: T::Array[AssocNode], rest: T.nilable(T.any(AssocSplatNode, NoKeywordsParameterNode)), opening_loc: T.nilable(Location), closing_loc: T.nilable(Location)).returns(HashPatternNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), constant: T.unsafe(nil), elements: T.unsafe(nil), rest: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     foo => Bar[a: 1, b: 2]
    #          ^^^
    #
    #     foo => Bar::Baz[a: 1, b: 2]
    #          ^^^^^^^^
    sig { returns(T.nilable(T.any(ConstantPathNode, ConstantReadNode))) }
    def constant; end

    # Represents the explicit named hash keys and values.
    #
    #     foo => { a: 1, b:, ** }
    #              ^^^^^^^^
    sig { returns(T::Array[AssocNode]) }
    def elements; end

    # Represents the rest of the Hash keys and values. This can be named, unnamed, or explicitly forbidden via `**nil`, this last one results in a `NoKeywordsParameterNode`.
    #
    #     foo => { a: 1, b:, **c }
    #                        ^^^
    #
    #     foo => { a: 1, b:, ** }
    #                        ^^
    #
    #     foo => { a: 1, b:, **nil }
    #                        ^^^^^
    sig { returns(T.nilable(T.any(AssocSplatNode, NoKeywordsParameterNode))) }
    def rest; end

    # The Location of the opening brace.
    #
    #     foo => { a: 1 }
    #            ^
    #
    #     foo => Bar[a: 1]
    #               ^
    sig { returns(T.nilable(Location)) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_opening_loc(repository); end

    # The Location of the closing brace.
    #
    #     foo => { a: 1 }
    #                   ^
    #
    #     foo => Bar[a: 1]
    #                    ^
    sig { returns(T.nilable(Location)) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(T.nilable(String)) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(T.nilable(String)) }
    def closing; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `if` keyword, either in the block form or the modifier form, or a ternary expression.
  #
  #     bar if foo
  #     ^^^^^^^^^^
  #
  #     if foo then bar end
  #     ^^^^^^^^^^^^^^^^^^^
  #
  #     foo ? bar : baz
  #     ^^^^^^^^^^^^^^^
  class IfNode < Node
    # Initialize a new IfNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, if_keyword_loc: T.nilable(Location), predicate: Node, then_keyword_loc: T.nilable(Location), statements: T.nilable(StatementsNode), subsequent: T.nilable(T.any(ElseNode, IfNode)), end_keyword_loc: T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, if_keyword_loc, predicate, then_keyword_loc, statements, subsequent, end_keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, if_keyword_loc: T.nilable(Location), predicate: Node, then_keyword_loc: T.nilable(Location), statements: T.nilable(StatementsNode), subsequent: T.nilable(T.any(ElseNode, IfNode)), end_keyword_loc: T.nilable(Location)).returns(IfNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), if_keyword_loc: T.unsafe(nil), predicate: T.unsafe(nil), then_keyword_loc: T.unsafe(nil), statements: T.unsafe(nil), subsequent: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     bar if foo
    #         ^^
    #
    # The `if_keyword_loc` field will be `nil` when the `IfNode` represents a ternary expression.
    sig { returns(T.nilable(Location)) }
    def if_keyword_loc; end

    # Save the if_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_if_keyword_loc(repository); end

    # The node for the condition the `IfNode` is testing.
    #
    #     if foo
    #        ^^^
    #       bar
    #     end
    #
    #     bar if foo
    #            ^^^
    #
    #     foo ? bar : baz
    #     ^^^
    sig { returns(Node) }
    def predicate; end

    # The Location of the `then` keyword (if present) or the `?` in a ternary expression, `nil` otherwise.
    #
    #     if foo then bar end
    #            ^^^^
    #
    #     a ? b : c
    #       ^
    sig { returns(T.nilable(Location)) }
    def then_keyword_loc; end

    # Save the then_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_then_keyword_loc(repository); end

    # Represents the body of statements that will be executed when the predicate is evaluated as truthy. Will be `nil` when no body is provided.
    #
    #     if foo
    #       bar
    #       ^^^
    #       baz
    #       ^^^
    #     end
    sig { returns(T.nilable(StatementsNode)) }
    def statements; end

    # Represents an `ElseNode` or an `IfNode` when there is an `else` or an `elsif` in the `if` statement.
    #
    #     if foo
    #       bar
    #     elsif baz
    #     ^^^^^^^^^
    #       qux
    #       ^^^
    #     end
    #     ^^^
    #
    #     if foo then bar else baz end
    #                     ^^^^^^^^^^^^
    sig { returns(T.nilable(T.any(ElseNode, IfNode))) }
    def subsequent; end

    # The Location of the `end` keyword if present, `nil` otherwise.
    #
    #     if foo
    #       bar
    #     end
    #     ^^^
    sig { returns(T.nilable(Location)) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_end_keyword_loc(repository); end

    # Slice the location of if_keyword_loc from the source.
    sig { returns(T.nilable(String)) }
    def if_keyword; end

    # Slice the location of then_keyword_loc from the source.
    sig { returns(T.nilable(String)) }
    def then_keyword; end

    # Slice the location of end_keyword_loc from the source.
    sig { returns(T.nilable(String)) }
    def end_keyword; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an imaginary number literal.
  #
  #     1.0i
  #     ^^^^
  class ImaginaryNode < Node
    # Initialize a new ImaginaryNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, numeric: T.any(FloatNode, IntegerNode, RationalNode)).void }
    def initialize(source, node_id, location, flags, numeric); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, numeric: T.any(FloatNode, IntegerNode, RationalNode)).returns(ImaginaryNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), numeric: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { returns(T.any(FloatNode, IntegerNode, RationalNode)) }
    def numeric; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a node that is implicitly being added to the tree but doesn't correspond directly to a node in the source.
  #
  #     { foo: }
  #       ^^^^
  #
  #     { Foo: }
  #       ^^^^
  #
  #     foo in { bar: }
  #              ^^^^
  class ImplicitNode < Node
    # Initialize a new ImplicitNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, value: T.any(LocalVariableReadNode, CallNode, ConstantReadNode, LocalVariableTargetNode)).void }
    def initialize(source, node_id, location, flags, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, value: T.any(LocalVariableReadNode, CallNode, ConstantReadNode, LocalVariableTargetNode)).returns(ImplicitNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { returns(T.any(LocalVariableReadNode, CallNode, ConstantReadNode, LocalVariableTargetNode)) }
    def value; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents using a trailing comma to indicate an implicit rest parameter.
  #
  #     foo { |bar,| }
  #               ^
  #
  #     foo in [bar,]
  #                ^
  #
  #     for foo, in bar do end
  #            ^
  #
  #     foo, = bar
  #        ^
  class ImplicitRestNode < Node
    # Initialize a new ImplicitRestNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(ImplicitRestNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `in` keyword in a case statement.
  #
  #     case a; in b then c end
  #             ^^^^^^^^^^^
  class InNode < Node
    # Initialize a new InNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, pattern: Node, statements: T.nilable(StatementsNode), in_loc: Location, then_loc: T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, pattern, statements, in_loc, then_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, pattern: Node, statements: T.nilable(StatementsNode), in_loc: Location, then_loc: T.nilable(Location)).returns(InNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), pattern: T.unsafe(nil), statements: T.unsafe(nil), in_loc: T.unsafe(nil), then_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { returns(T.nilable(StatementsNode)) }
    def statements; end

    # Returns the Location represented by `in_loc`.
    sig { returns(Location) }
    def in_loc; end

    # Save the in_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_in_loc(repository); end

    # Returns the Location represented by `then_loc`.
    sig { returns(T.nilable(Location)) }
    def then_loc; end

    # Save the then_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_then_loc(repository); end

    # Slice the location of in_loc from the source.
    sig { returns(String) }
    def in; end

    # Slice the location of then_loc from the source.
    sig { returns(T.nilable(String)) }
    def then; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `&&=` operator on a call to the `[]` method.
  #
  #     foo.bar[baz] &&= value
  #     ^^^^^^^^^^^^^^^^^^^^^^
  class IndexAndWriteNode < Node
    # Initialize a new IndexAndWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: T.nilable(Node), call_operator_loc: T.nilable(Location), opening_loc: Location, arguments: T.nilable(ArgumentsNode), closing_loc: Location, block: T.nilable(BlockArgumentNode), operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, receiver, call_operator_loc, opening_loc, arguments, closing_loc, block, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, receiver: T.nilable(Node), call_operator_loc: T.nilable(Location), opening_loc: Location, arguments: T.nilable(ArgumentsNode), closing_loc: Location, block: T.nilable(BlockArgumentNode), operator_loc: Location, value: Node).returns(IndexAndWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), call_operator_loc: T.unsafe(nil), opening_loc: T.unsafe(nil), arguments: T.unsafe(nil), closing_loc: T.unsafe(nil), block: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { returns(T.nilable(Node)) }
    def receiver; end

    # Returns the Location represented by `call_operator_loc`.
    sig { returns(T.nilable(Location)) }
    def call_operator_loc; end

    # Save the call_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_call_operator_loc(repository); end

    # Returns the Location represented by `opening_loc`.
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the `arguments` attribute.
    sig { returns(T.nilable(ArgumentsNode)) }
    def arguments; end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Returns the `block` attribute.
    sig { returns(T.nilable(BlockArgumentNode)) }
    def block; end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of call_operator_loc from the source.
    sig { returns(T.nilable(String)) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of an assignment operator on a call to `[]`.
  #
  #     foo.bar[baz] += value
  #     ^^^^^^^^^^^^^^^^^^^^^
  class IndexOperatorWriteNode < Node
    # Initialize a new IndexOperatorWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: T.nilable(Node), call_operator_loc: T.nilable(Location), opening_loc: Location, arguments: T.nilable(ArgumentsNode), closing_loc: Location, block: T.nilable(BlockArgumentNode), binary_operator: Symbol, binary_operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, receiver, call_operator_loc, opening_loc, arguments, closing_loc, block, binary_operator, binary_operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, receiver: T.nilable(Node), call_operator_loc: T.nilable(Location), opening_loc: Location, arguments: T.nilable(ArgumentsNode), closing_loc: Location, block: T.nilable(BlockArgumentNode), binary_operator: Symbol, binary_operator_loc: Location, value: Node).returns(IndexOperatorWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), call_operator_loc: T.unsafe(nil), opening_loc: T.unsafe(nil), arguments: T.unsafe(nil), closing_loc: T.unsafe(nil), block: T.unsafe(nil), binary_operator: T.unsafe(nil), binary_operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { returns(T.nilable(Node)) }
    def receiver; end

    # Returns the Location represented by `call_operator_loc`.
    sig { returns(T.nilable(Location)) }
    def call_operator_loc; end

    # Save the call_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_call_operator_loc(repository); end

    # Returns the Location represented by `opening_loc`.
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the `arguments` attribute.
    sig { returns(T.nilable(ArgumentsNode)) }
    def arguments; end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Returns the `block` attribute.
    sig { returns(T.nilable(BlockArgumentNode)) }
    def block; end

    # Returns the `binary_operator` attribute.
    sig { returns(Symbol) }
    def binary_operator; end

    # Returns the Location represented by `binary_operator_loc`.
    sig { returns(Location) }
    def binary_operator_loc; end

    # Save the binary_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_binary_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of call_operator_loc from the source.
    sig { returns(T.nilable(String)) }
    def call_operator; end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `||=` operator on a call to `[]`.
  #
  #     foo.bar[baz] ||= value
  #     ^^^^^^^^^^^^^^^^^^^^^^
  class IndexOrWriteNode < Node
    # Initialize a new IndexOrWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: T.nilable(Node), call_operator_loc: T.nilable(Location), opening_loc: Location, arguments: T.nilable(ArgumentsNode), closing_loc: Location, block: T.nilable(BlockArgumentNode), operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, receiver, call_operator_loc, opening_loc, arguments, closing_loc, block, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, receiver: T.nilable(Node), call_operator_loc: T.nilable(Location), opening_loc: Location, arguments: T.nilable(ArgumentsNode), closing_loc: Location, block: T.nilable(BlockArgumentNode), operator_loc: Location, value: Node).returns(IndexOrWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), call_operator_loc: T.unsafe(nil), opening_loc: T.unsafe(nil), arguments: T.unsafe(nil), closing_loc: T.unsafe(nil), block: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { returns(T.nilable(Node)) }
    def receiver; end

    # Returns the Location represented by `call_operator_loc`.
    sig { returns(T.nilable(Location)) }
    def call_operator_loc; end

    # Save the call_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_call_operator_loc(repository); end

    # Returns the Location represented by `opening_loc`.
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the `arguments` attribute.
    sig { returns(T.nilable(ArgumentsNode)) }
    def arguments; end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Returns the `block` attribute.
    sig { returns(T.nilable(BlockArgumentNode)) }
    def block; end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of call_operator_loc from the source.
    sig { returns(T.nilable(String)) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents assigning to an index.
  #
  #     foo[bar], = 1
  #     ^^^^^^^^
  #
  #     begin
  #     rescue => foo[bar]
  #               ^^^^^^^^
  #     end
  #
  #     for foo[bar] in baz do end
  #         ^^^^^^^^
  class IndexTargetNode < Node
    # Initialize a new IndexTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: Node, opening_loc: Location, arguments: T.nilable(ArgumentsNode), closing_loc: Location, block: T.nilable(BlockArgumentNode)).void }
    def initialize(source, node_id, location, flags, receiver, opening_loc, arguments, closing_loc, block); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, receiver: Node, opening_loc: Location, arguments: T.nilable(ArgumentsNode), closing_loc: Location, block: T.nilable(BlockArgumentNode)).returns(IndexTargetNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), opening_loc: T.unsafe(nil), arguments: T.unsafe(nil), closing_loc: T.unsafe(nil), block: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the `arguments` attribute.
    sig { returns(T.nilable(ArgumentsNode)) }
    def arguments; end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Returns the `block` attribute.
    sig { returns(T.nilable(BlockArgumentNode)) }
    def block; end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `&&=` operator for assignment to an instance variable.
  #
  #     @target &&= value
  #     ^^^^^^^^^^^^^^^^^
  class InstanceVariableAndWriteNode < Node
    # Initialize a new InstanceVariableAndWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, name, name_loc, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(InstanceVariableAndWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents assigning to an instance variable using an operator that isn't `=`.
  #
  #     @target += value
  #     ^^^^^^^^^^^^^^^^
  class InstanceVariableOperatorWriteNode < Node
    # Initialize a new InstanceVariableOperatorWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, binary_operator_loc: Location, value: Node, binary_operator: Symbol).void }
    def initialize(source, node_id, location, flags, name, name_loc, binary_operator_loc, value, binary_operator); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, binary_operator_loc: Location, value: Node, binary_operator: Symbol).returns(InstanceVariableOperatorWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), binary_operator_loc: T.unsafe(nil), value: T.unsafe(nil), binary_operator: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `binary_operator_loc`.
    sig { returns(Location) }
    def binary_operator_loc; end

    # Save the binary_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_binary_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Returns the `binary_operator` attribute.
    sig { returns(Symbol) }
    def binary_operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `||=` operator for assignment to an instance variable.
  #
  #     @target ||= value
  #     ^^^^^^^^^^^^^^^^^
  class InstanceVariableOrWriteNode < Node
    # Initialize a new InstanceVariableOrWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, name, name_loc, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(InstanceVariableOrWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents referencing an instance variable.
  #
  #     @foo
  #     ^^^^
  class InstanceVariableReadNode < Node
    # Initialize a new InstanceVariableReadNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).void }
    def initialize(source, node_id, location, flags, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(InstanceVariableReadNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     @x     # name `:@x`
    #
    #     @_test # name `:@_test`
    sig { returns(Symbol) }
    def name; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing to an instance variable in a context that doesn't have an explicit value.
  #
  #     @foo, @bar = baz
  #     ^^^^  ^^^^
  class InstanceVariableTargetNode < Node
    # Initialize a new InstanceVariableTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).void }
    def initialize(source, node_id, location, flags, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(InstanceVariableTargetNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing to an instance variable.
  #
  #     @foo = 1
  #     ^^^^^^^^
  class InstanceVariableWriteNode < Node
    # Initialize a new InstanceVariableWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, value: Node, operator_loc: Location).void }
    def initialize(source, node_id, location, flags, name, name_loc, value, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, value: Node, operator_loc: Location).returns(InstanceVariableWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), value: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     @x = :y       # name `:@x`
    #
    #     @_foo = "bar" # name `@_foo`
    sig { returns(Symbol) }
    def name; end

    # The Location of the variable name.
    #
    #     @_x = 1
    #     ^^^
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # The value to write to the instance variable. It can be any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    #     @foo = :bar
    #            ^^^^
    #
    #     @_x = 1234
    #           ^^^^
    sig { returns(Node) }
    def value; end

    # The Location of the `=` operator.
    #
    #     @x = y
    #        ^
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an integer number literal.
  #
  #     1
  #     ^
  class IntegerNode < Node
    # Initialize a new IntegerNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, value: Integer).void }
    def initialize(source, node_id, location, flags, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, value: Integer).returns(IntegerNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a regular expression literal that contains interpolation that is being used in the predicate of a conditional to implicitly match against the last line read by an IO object.
  #
  #     if /foo #{bar} baz/ then end
  #        ^^^^^^^^^^^^^^^^
  class InterpolatedMatchLastLineNode < Node
    # Initialize a new InterpolatedMatchLastLineNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: Location, parts: T::Array[T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)], closing_loc: Location).void }
    def initialize(source, node_id, location, flags, opening_loc, parts, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, opening_loc: Location, parts: T::Array[T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)], closing_loc: Location).returns(InterpolatedMatchLastLineNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), parts: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the `parts` attribute.
    sig { returns(T::Array[T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)]) }
    def parts; end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a regular expression literal that contains interpolation.
  #
  #     /foo #{bar} baz/
  #     ^^^^^^^^^^^^^^^^
  class InterpolatedRegularExpressionNode < Node
    # Initialize a new InterpolatedRegularExpressionNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: Location, parts: T::Array[T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)], closing_loc: Location).void }
    def initialize(source, node_id, location, flags, opening_loc, parts, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, opening_loc: Location, parts: T::Array[T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)], closing_loc: Location).returns(InterpolatedRegularExpressionNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), parts: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the `parts` attribute.
    sig { returns(T::Array[T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)]) }
    def parts; end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a string literal that contains interpolation.
  #
  #     "foo #{bar} baz"
  #     ^^^^^^^^^^^^^^^^
  class InterpolatedStringNode < Node
    # Initialize a new InterpolatedStringNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: T.nilable(Location), parts: T::Array[T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode, InterpolatedStringNode, XStringNode, InterpolatedXStringNode, SymbolNode, InterpolatedSymbolNode)], closing_loc: T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, opening_loc, parts, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, opening_loc: T.nilable(Location), parts: T::Array[T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode, InterpolatedStringNode, XStringNode, InterpolatedXStringNode, SymbolNode, InterpolatedSymbolNode)], closing_loc: T.nilable(Location)).returns(InterpolatedStringNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), parts: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { returns(T.nilable(Location)) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_opening_loc(repository); end

    # Returns the `parts` attribute.
    sig { returns(T::Array[T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode, InterpolatedStringNode, XStringNode, InterpolatedXStringNode, SymbolNode, InterpolatedSymbolNode)]) }
    def parts; end

    # Returns the Location represented by `closing_loc`.
    sig { returns(T.nilable(Location)) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(T.nilable(String)) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(T.nilable(String)) }
    def closing; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a symbol literal that contains interpolation.
  #
  #     :"foo #{bar} baz"
  #     ^^^^^^^^^^^^^^^^^
  class InterpolatedSymbolNode < Node
    # Initialize a new InterpolatedSymbolNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: T.nilable(Location), parts: T::Array[T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)], closing_loc: T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, opening_loc, parts, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, opening_loc: T.nilable(Location), parts: T::Array[T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)], closing_loc: T.nilable(Location)).returns(InterpolatedSymbolNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), parts: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { returns(T.nilable(Location)) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_opening_loc(repository); end

    # Returns the `parts` attribute.
    sig { returns(T::Array[T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)]) }
    def parts; end

    # Returns the Location represented by `closing_loc`.
    sig { returns(T.nilable(Location)) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(T.nilable(String)) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(T.nilable(String)) }
    def closing; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an xstring literal that contains interpolation.
  #
  #     `foo #{bar} baz`
  #     ^^^^^^^^^^^^^^^^
  class InterpolatedXStringNode < Node
    # Initialize a new InterpolatedXStringNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: Location, parts: T::Array[T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)], closing_loc: Location).void }
    def initialize(source, node_id, location, flags, opening_loc, parts, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, opening_loc: Location, parts: T::Array[T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)], closing_loc: Location).returns(InterpolatedXStringNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), parts: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the `parts` attribute.
    sig { returns(T::Array[T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)]) }
    def parts; end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents reading from the implicit `it` local variable.
  #
  #     -> { it }
  #          ^^
  class ItLocalVariableReadNode < Node
    # Initialize a new ItLocalVariableReadNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(ItLocalVariableReadNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an implicit set of parameters through the use of the `it` keyword within a block or lambda.
  #
  #     -> { it + it }
  #     ^^^^^^^^^^^^^^
  class ItParametersNode < Node
    # Initialize a new ItParametersNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(ItParametersNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a hash literal without opening and closing braces.
  #
  #     foo(a: b)
  #         ^^^^
  class KeywordHashNode < Node
    # Initialize a new KeywordHashNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, elements: T::Array[T.any(AssocNode, AssocSplatNode)]).void }
    def initialize(source, node_id, location, flags, elements); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, elements: T::Array[T.any(AssocNode, AssocSplatNode)]).returns(KeywordHashNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), elements: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { returns(T::Array[T.any(AssocNode, AssocSplatNode)]) }
    def elements; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a keyword rest parameter to a method, block, or lambda definition.
  #
  #     def a(**b)
  #           ^^^
  #     end
  class KeywordRestParameterNode < Node
    # Initialize a new KeywordRestParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: T.nilable(Symbol), name_loc: T.nilable(Location), operator_loc: Location).void }
    def initialize(source, node_id, location, flags, name, name_loc, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: T.nilable(Symbol), name_loc: T.nilable(Location), operator_loc: Location).returns(KeywordRestParameterNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { returns(T.nilable(Symbol)) }
    def name; end

    # Returns the Location represented by `name_loc`.
    sig { returns(T.nilable(Location)) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_name_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents using a lambda literal (not the lambda method call).
  #
  #     ->(value) { value * 2 }
  #     ^^^^^^^^^^^^^^^^^^^^^^^
  class LambdaNode < Node
    # Initialize a new LambdaNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], operator_loc: Location, opening_loc: Location, closing_loc: Location, parameters: T.nilable(T.any(BlockParametersNode, NumberedParametersNode, ItParametersNode)), body: T.nilable(T.any(StatementsNode, BeginNode))).void }
    def initialize(source, node_id, location, flags, locals, operator_loc, opening_loc, closing_loc, parameters, body); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], operator_loc: Location, opening_loc: Location, closing_loc: Location, parameters: T.nilable(T.any(BlockParametersNode, NumberedParametersNode, ItParametersNode)), body: T.nilable(T.any(StatementsNode, BeginNode))).returns(LambdaNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), locals: T.unsafe(nil), operator_loc: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil), parameters: T.unsafe(nil), body: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the Location represented by `opening_loc`.
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Returns the `parameters` attribute.
    sig { returns(T.nilable(T.any(BlockParametersNode, NumberedParametersNode, ItParametersNode))) }
    def parameters; end

    # Returns the `body` attribute.
    sig { returns(T.nilable(T.any(StatementsNode, BeginNode))) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `&&=` operator for assignment to a local variable.
  #
  #     target &&= value
  #     ^^^^^^^^^^^^^^^^
  class LocalVariableAndWriteNode < Node
    # Initialize a new LocalVariableAndWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name_loc: Location, operator_loc: Location, value: Node, name: Symbol, depth: Integer).void }
    def initialize(source, node_id, location, flags, name_loc, operator_loc, value, name, depth); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name_loc: Location, operator_loc: Location, value: Node, name: Symbol, depth: Integer).returns(LocalVariableAndWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil), name: T.unsafe(nil), depth: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents assigning to a local variable using an operator that isn't `=`.
  #
  #     target += value
  #     ^^^^^^^^^^^^^^^
  class LocalVariableOperatorWriteNode < Node
    # Initialize a new LocalVariableOperatorWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name_loc: Location, binary_operator_loc: Location, value: Node, name: Symbol, binary_operator: Symbol, depth: Integer).void }
    def initialize(source, node_id, location, flags, name_loc, binary_operator_loc, value, name, binary_operator, depth); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name_loc: Location, binary_operator_loc: Location, value: Node, name: Symbol, binary_operator: Symbol, depth: Integer).returns(LocalVariableOperatorWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name_loc: T.unsafe(nil), binary_operator_loc: T.unsafe(nil), value: T.unsafe(nil), name: T.unsafe(nil), binary_operator: T.unsafe(nil), depth: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `binary_operator_loc`.
    sig { returns(Location) }
    def binary_operator_loc; end

    # Save the binary_operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `||=` operator for assignment to a local variable.
  #
  #     target ||= value
  #     ^^^^^^^^^^^^^^^^
  class LocalVariableOrWriteNode < Node
    # Initialize a new LocalVariableOrWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name_loc: Location, operator_loc: Location, value: Node, name: Symbol, depth: Integer).void }
    def initialize(source, node_id, location, flags, name_loc, operator_loc, value, name, depth); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name_loc: Location, operator_loc: Location, value: Node, name: Symbol, depth: Integer).returns(LocalVariableOrWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil), name: T.unsafe(nil), depth: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents reading a local variable. Note that this requires that a local variable of the same name has already been written to in the same scope, otherwise it is parsed as a method call.
  #
  #     foo
  #     ^^^
  class LocalVariableReadNode < Node
    # Initialize a new LocalVariableReadNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, depth: Integer).void }
    def initialize(source, node_id, location, flags, name, depth); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, depth: Integer).returns(LocalVariableReadNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), depth: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     x      # name `:x`
    #
    #     _Test  # name `:_Test`
    #
    # Note that this can also be an underscore followed by a number for the default block parameters.
    #
    #     _1     # name `:_1`
    sig { returns(Symbol) }
    def name; end

    # The number of visible scopes that should be searched to find the origin of this local variable.
    #
    #     foo = 1; foo # depth 0
    #
    #     bar = 2; tap { bar } # depth 1
    #
    # The specific rules for calculating the depth may differ from individual Ruby implementations, as they are not specified by the language. For more information, see [the Prism documentation](https://github.com/ruby/prism/blob/main/docs/local_variable_depth.md).
    sig { returns(Integer) }
    def depth; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing to a local variable in a context that doesn't have an explicit value.
  #
  #     foo, bar = baz
  #     ^^^  ^^^
  #
  #     foo => baz
  #            ^^^
  class LocalVariableTargetNode < Node
    # Initialize a new LocalVariableTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, depth: Integer).void }
    def initialize(source, node_id, location, flags, name, depth); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, depth: Integer).returns(LocalVariableTargetNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), depth: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing to a local variable.
  #
  #     foo = 1
  #     ^^^^^^^
  class LocalVariableWriteNode < Node
    # Initialize a new LocalVariableWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, depth: Integer, name_loc: Location, value: Node, operator_loc: Location).void }
    def initialize(source, node_id, location, flags, name, depth, name_loc, value, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, depth: Integer, name_loc: Location, value: Node, operator_loc: Location).returns(LocalVariableWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), depth: T.unsafe(nil), name_loc: T.unsafe(nil), value: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     foo = :bar # name `:foo`
    #
    #     abc = 123  # name `:abc`
    sig { returns(Symbol) }
    def name; end

    # The number of semantic scopes we have to traverse to find the declaration of this variable.
    #
    #     foo = 1         # depth 0
    #
    #     tap { foo = 1 } # depth 1
    #
    # The specific rules for calculating the depth may differ from individual Ruby implementations, as they are not specified by the language. For more information, see [the Prism documentation](https://github.com/ruby/prism/blob/main/docs/local_variable_depth.md).
    sig { returns(Integer) }
    def depth; end

    # The Location of the variable name.
    #
    #     foo = :bar
    #     ^^^
    sig { returns(Location) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # The value to write to the local variable. It can be any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    #     foo = :bar
    #           ^^^^
    #
    #     abc = 1234
    #           ^^^^
    #
    # Note that since the name of a local variable is known before the value is parsed, it is valid for a local variable to appear within the value of its own write.
    #
    #     foo = foo
    sig { returns(Node) }
    def value; end

    # The Location of the `=` operator.
    #
    #     x = :y
    #       ^
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a regular expression literal used in the predicate of a conditional to implicitly match against the last line read by an IO object.
  #
  #     if /foo/i then end
  #        ^^^^^^
  class MatchLastLineNode < Node
    # Initialize a new MatchLastLineNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: Location, content_loc: Location, closing_loc: Location, unescaped: String).void }
    def initialize(source, node_id, location, flags, opening_loc, content_loc, closing_loc, unescaped); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, opening_loc: Location, content_loc: Location, closing_loc: Location, unescaped: String).returns(MatchLastLineNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), content_loc: T.unsafe(nil), closing_loc: T.unsafe(nil), unescaped: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the Location represented by `content_loc`.
    sig { returns(Location) }
    def content_loc; end

    # Save the content_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_content_loc(repository); end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the modifier `in` operator.
  #
  #     foo in bar
  #     ^^^^^^^^^^
  class MatchPredicateNode < Node
    # Initialize a new MatchPredicateNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, value: Node, pattern: Node, operator_loc: Location).void }
    def initialize(source, node_id, location, flags, value, pattern, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, value: Node, pattern: Node, operator_loc: Location).returns(MatchPredicateNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), value: T.unsafe(nil), pattern: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `=>` operator.
  #
  #     foo => bar
  #     ^^^^^^^^^^
  class MatchRequiredNode < Node
    # Initialize a new MatchRequiredNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, value: Node, pattern: Node, operator_loc: Location).void }
    def initialize(source, node_id, location, flags, value, pattern, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, value: Node, pattern: Node, operator_loc: Location).returns(MatchRequiredNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), value: T.unsafe(nil), pattern: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     foo => bar
    #     ^^^
    sig { returns(Node) }
    def value; end

    # Represents the right-hand side of the operator. The type of the node depends on the expression.
    #
    # Anything that looks like a local variable name (including `_`) will result in a `LocalVariableTargetNode`.
    #
    #     foo => a # This is equivalent to writing `a = foo`
    #            ^
    #
    # Using an explicit `Array` or combining expressions with `,` will result in a `ArrayPatternNode`. This can be preceded by a constant.
    #
    #     foo => [a]
    #            ^^^
    #
    #     foo => a, b
    #            ^^^^
    #
    #     foo => Bar[a, b]
    #            ^^^^^^^^^
    #
    # If the array pattern contains at least two wildcard matches, a `FindPatternNode` is created instead.
    #
    #     foo => *, 1, *a
    #            ^^^^^
    #
    # Using an explicit `Hash` or a constant with square brackets and hash keys in the square brackets will result in a `HashPatternNode`.
    #
    #     foo => { a: 1, b: }
    #
    #     foo => Bar[a: 1, b:]
    #
    #     foo => Bar[**]
    #
    # To use any variable that needs run time evaluation, pinning is required. This results in a `PinnedVariableNode`
    #
    #     foo => ^a
    #            ^^
    #
    # Similar, any expression can be used with pinning. This results in a `PinnedExpressionNode`.
    #
    #     foo => ^(a + 1)
    #
    # Anything else will result in the regular node for that expression, for example a `ConstantReadNode`.
    #
    #     foo => CONST
    sig { returns(Node) }
    def pattern; end

    # The Location of the operator.
    #
    #     foo => bar
    #         ^^
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents writing local variables using a regular expression match with named capture groups.
  #
  #     /(?<foo>bar)/ =~ baz
  #     ^^^^^^^^^^^^^^^^^^^^
  class MatchWriteNode < Node
    # Initialize a new MatchWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, call: CallNode, targets: T::Array[LocalVariableTargetNode]).void }
    def initialize(source, node_id, location, flags, call, targets); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, call: CallNode, targets: T::Array[LocalVariableTargetNode]).returns(MatchWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), call: T.unsafe(nil), targets: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a node that is missing from the source and results in a syntax error.
  class MissingNode < Node
    # Initialize a new MissingNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(MissingNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a module declaration involving the `module` keyword.
  #
  #     module Foo end
  #     ^^^^^^^^^^^^^^
  class ModuleNode < Node
    # Initialize a new ModuleNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], module_keyword_loc: Location, constant_path: T.any(ConstantReadNode, ConstantPathNode, MissingNode), body: T.nilable(T.any(StatementsNode, BeginNode)), end_keyword_loc: Location, name: Symbol).void }
    def initialize(source, node_id, location, flags, locals, module_keyword_loc, constant_path, body, end_keyword_loc, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], module_keyword_loc: Location, constant_path: T.any(ConstantReadNode, ConstantPathNode, MissingNode), body: T.nilable(T.any(StatementsNode, BeginNode)), end_keyword_loc: Location, name: Symbol).returns(ModuleNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), locals: T.unsafe(nil), module_keyword_loc: T.unsafe(nil), constant_path: T.unsafe(nil), body: T.unsafe(nil), end_keyword_loc: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_module_keyword_loc(repository); end

    # Returns the `constant_path` attribute.
    sig { returns(T.any(ConstantReadNode, ConstantPathNode, MissingNode)) }
    def constant_path; end

    # Returns the `body` attribute.
    sig { returns(T.nilable(T.any(StatementsNode, BeginNode))) }
    def body; end

    # Returns the Location represented by `end_keyword_loc`.
    sig { returns(Location) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a multi-target expression.
  #
  #     a, (b, c) = 1, 2, 3
  #        ^^^^^^
  #
  # This can be a part of `MultiWriteNode` as above, or the target of a `for` loop
  #
  #     for a, b in [[1, 2], [3, 4]]
  #         ^^^^
  class MultiTargetNode < Node
    # Initialize a new MultiTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, lefts: T::Array[T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, RequiredParameterNode, BackReferenceReadNode, NumberedReferenceReadNode)], rest: T.nilable(T.any(ImplicitRestNode, SplatNode)), rights: T::Array[T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, RequiredParameterNode, BackReferenceReadNode, NumberedReferenceReadNode)], lparen_loc: T.nilable(Location), rparen_loc: T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, lefts, rest, rights, lparen_loc, rparen_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, lefts: T::Array[T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, RequiredParameterNode, BackReferenceReadNode, NumberedReferenceReadNode)], rest: T.nilable(T.any(ImplicitRestNode, SplatNode)), rights: T::Array[T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, RequiredParameterNode, BackReferenceReadNode, NumberedReferenceReadNode)], lparen_loc: T.nilable(Location), rparen_loc: T.nilable(Location)).returns(MultiTargetNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), lefts: T.unsafe(nil), rest: T.unsafe(nil), rights: T.unsafe(nil), lparen_loc: T.unsafe(nil), rparen_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     a, (b, c, *) = 1, 2, 3, 4, 5
    #         ^^^^
    #
    # The splat node can be absent, in that case all target expressions are in the left field.
    #
    #     a, (b, c) = 1, 2, 3, 4, 5
    #         ^^^^
    sig { returns(T::Array[T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, RequiredParameterNode, BackReferenceReadNode, NumberedReferenceReadNode)]) }
    def lefts; end

    # Represents a splat node in the target expression.
    #
    #     a, (b, *c) = 1, 2, 3, 4
    #            ^^
    #
    # The variable can be empty, this results in a `SplatNode` with a `nil` expression field.
    #
    #     a, (b, *) = 1, 2, 3, 4
    #            ^
    #
    # If the `*` is omitted, this field will contain an `ImplicitRestNode`
    #
    #     a, (b,) = 1, 2, 3, 4
    #          ^
    sig { returns(T.nilable(T.any(ImplicitRestNode, SplatNode))) }
    def rest; end

    # Represents the targets expressions after a splat node.
    #
    #     a, (*, b, c) = 1, 2, 3, 4, 5
    #            ^^^^
    sig { returns(T::Array[T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, RequiredParameterNode, BackReferenceReadNode, NumberedReferenceReadNode)]) }
    def rights; end

    # The Location of the opening parenthesis.
    #
    #     a, (b, c) = 1, 2, 3
    #        ^
    sig { returns(T.nilable(Location)) }
    def lparen_loc; end

    # Save the lparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_lparen_loc(repository); end

    # The Location of the closing parenthesis.
    #
    #     a, (b, c) = 1, 2, 3
    #             ^
    sig { returns(T.nilable(Location)) }
    def rparen_loc; end

    # Save the rparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_rparen_loc(repository); end

    # Slice the location of lparen_loc from the source.
    sig { returns(T.nilable(String)) }
    def lparen; end

    # Slice the location of rparen_loc from the source.
    sig { returns(T.nilable(String)) }
    def rparen; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a write to a multi-target expression.
  #
  #     a, b, c = 1, 2, 3
  #     ^^^^^^^^^^^^^^^^^
  class MultiWriteNode < Node
    # Initialize a new MultiWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, lefts: T::Array[T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, BackReferenceReadNode, NumberedReferenceReadNode)], rest: T.nilable(T.any(ImplicitRestNode, SplatNode)), rights: T::Array[T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, BackReferenceReadNode, NumberedReferenceReadNode)], lparen_loc: T.nilable(Location), rparen_loc: T.nilable(Location), operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, lefts, rest, rights, lparen_loc, rparen_loc, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, lefts: T::Array[T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, BackReferenceReadNode, NumberedReferenceReadNode)], rest: T.nilable(T.any(ImplicitRestNode, SplatNode)), rights: T::Array[T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, BackReferenceReadNode, NumberedReferenceReadNode)], lparen_loc: T.nilable(Location), rparen_loc: T.nilable(Location), operator_loc: Location, value: Node).returns(MultiWriteNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), lefts: T.unsafe(nil), rest: T.unsafe(nil), rights: T.unsafe(nil), lparen_loc: T.unsafe(nil), rparen_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     a, b, * = 1, 2, 3, 4, 5
    #     ^^^^
    #
    # The splat node can be absent, in that case all target expressions are in the left field.
    #
    #     a, b, c = 1, 2, 3, 4, 5
    #     ^^^^^^^
    sig { returns(T::Array[T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, BackReferenceReadNode, NumberedReferenceReadNode)]) }
    def lefts; end

    # Represents a splat node in the target expression.
    #
    #     a, b, *c = 1, 2, 3, 4
    #           ^^
    #
    # The variable can be empty, this results in a `SplatNode` with a `nil` expression field.
    #
    #     a, b, * = 1, 2, 3, 4
    #           ^
    #
    # If the `*` is omitted, this field will contain an `ImplicitRestNode`
    #
    #     a, b, = 1, 2, 3, 4
    #         ^
    sig { returns(T.nilable(T.any(ImplicitRestNode, SplatNode))) }
    def rest; end

    # Represents the targets expressions after a splat node.
    #
    #     a, *, b, c = 1, 2, 3, 4, 5
    #           ^^^^
    sig { returns(T::Array[T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, BackReferenceReadNode, NumberedReferenceReadNode)]) }
    def rights; end

    # The Location of the opening parenthesis.
    #
    #     (a, b, c) = 1, 2, 3
    #     ^
    sig { returns(T.nilable(Location)) }
    def lparen_loc; end

    # Save the lparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_lparen_loc(repository); end

    # The Location of the closing parenthesis.
    #
    #     (a, b, c) = 1, 2, 3
    #             ^
    sig { returns(T.nilable(Location)) }
    def rparen_loc; end

    # Save the rparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_rparen_loc(repository); end

    # The Location of the operator.
    #
    #     a, b, c = 1, 2, 3
    #             ^
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # The value to write to the targets. It can be any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    #     a, b, c = 1, 2, 3
    #               ^^^^^^^
    sig { returns(Node) }
    def value; end

    # Slice the location of lparen_loc from the source.
    sig { returns(T.nilable(String)) }
    def lparen; end

    # Slice the location of rparen_loc from the source.
    sig { returns(T.nilable(String)) }
    def rparen; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `next` keyword.
  #
  #     next 1
  #     ^^^^^^
  class NextNode < Node
    # Initialize a new NextNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, arguments: T.nilable(ArgumentsNode), keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, arguments, keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, arguments: T.nilable(ArgumentsNode), keyword_loc: Location).returns(NextNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), arguments: T.unsafe(nil), keyword_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { returns(T.nilable(ArgumentsNode)) }
    def arguments; end

    # Returns the Location represented by `keyword_loc`.
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `nil` keyword.
  #
  #     nil
  #     ^^^
  class NilNode < Node
    # Initialize a new NilNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(NilNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of `&nil` inside method arguments.
  #
  #     def a(&nil)
  #           ^^^^
  #     end
  class NoBlockParameterNode < Node
    # Initialize a new NoBlockParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, operator_loc: Location, keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, operator_loc, keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, operator_loc: Location, keyword_loc: Location).returns(NoBlockParameterNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), operator_loc: T.unsafe(nil), keyword_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the Location represented by `keyword_loc`.
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of `**nil` inside method arguments.
  #
  #     def a(**nil)
  #           ^^^^^
  #     end
  class NoKeywordsParameterNode < Node
    # Initialize a new NoKeywordsParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, operator_loc: Location, keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, operator_loc, keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, operator_loc: Location, keyword_loc: Location).returns(NoKeywordsParameterNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), operator_loc: T.unsafe(nil), keyword_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the Location represented by `keyword_loc`.
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an implicit set of parameters through the use of numbered parameters within a block or lambda.
  #
  #     -> { _1 + _2 }
  #     ^^^^^^^^^^^^^^
  class NumberedParametersNode < Node
    # Initialize a new NumberedParametersNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, maximum: Integer).void }
    def initialize(source, node_id, location, flags, maximum); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, maximum: Integer).returns(NumberedParametersNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), maximum: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents reading a numbered reference to a capture in the previous match.
  #
  #     $1
  #     ^^
  class NumberedReferenceReadNode < Node
    # Initialize a new NumberedReferenceReadNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, number: Integer).void }
    def initialize(source, node_id, location, flags, number); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, number: Integer).returns(NumberedReferenceReadNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), number: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     $1          # number `1`
    #
    #     $5432       # number `5432`
    #
    #     $4294967296 # number `0`
    sig { returns(Integer) }
    def number; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an optional keyword parameter to a method, block, or lambda definition.
  #
  #     def a(b: 1)
  #           ^^^^
  #     end
  class OptionalKeywordParameterNode < Node
    # Initialize a new OptionalKeywordParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, name, name_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, value: Node).returns(OptionalKeywordParameterNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an optional parameter to a method, block, or lambda definition.
  #
  #     def a(b = 1)
  #           ^^^^^
  #     end
  class OptionalParameterNode < Node
    # Initialize a new OptionalParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).void }
    def initialize(source, node_id, location, flags, name, name_loc, operator_loc, value); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(OptionalParameterNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `value` attribute.
    sig { returns(Node) }
    def value; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `||` operator or the `or` keyword.
  #
  #     left or right
  #     ^^^^^^^^^^^^^
  class OrNode < Node
    # Initialize a new OrNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, left: Node, right: Node, operator_loc: Location).void }
    def initialize(source, node_id, location, flags, left, right, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, left: Node, right: Node, operator_loc: Location).returns(OrNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), left: T.unsafe(nil), right: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     left or right
    #     ^^^^
    #
    #     1 || 2
    #     ^
    sig { returns(Node) }
    def left; end

    # Represents the right side of the expression.
    #
    #     left || right
    #             ^^^^^
    #
    #     1 or 2
    #          ^
    sig { returns(Node) }
    def right; end

    # The Location of the `or` keyword or the `||` operator.
    #
    #     left or right
    #          ^^
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the list of parameters on a method, block, or lambda definition.
  #
  #     def a(b, c, d)
  #           ^^^^^^^
  #     end
  class ParametersNode < Node
    # Initialize a new ParametersNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, requireds: T::Array[T.any(RequiredParameterNode, MultiTargetNode)], optionals: T::Array[OptionalParameterNode], rest: T.nilable(T.any(RestParameterNode, ImplicitRestNode)), posts: T::Array[T.any(RequiredParameterNode, MultiTargetNode, KeywordRestParameterNode, NoKeywordsParameterNode, ForwardingParameterNode, BlockParameterNode, NoBlockParameterNode)], keywords: T::Array[T.any(RequiredKeywordParameterNode, OptionalKeywordParameterNode)], keyword_rest: T.nilable(T.any(KeywordRestParameterNode, ForwardingParameterNode, NoKeywordsParameterNode)), block: T.nilable(T.any(BlockParameterNode, NoBlockParameterNode))).void }
    def initialize(source, node_id, location, flags, requireds, optionals, rest, posts, keywords, keyword_rest, block); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, requireds: T::Array[T.any(RequiredParameterNode, MultiTargetNode)], optionals: T::Array[OptionalParameterNode], rest: T.nilable(T.any(RestParameterNode, ImplicitRestNode)), posts: T::Array[T.any(RequiredParameterNode, MultiTargetNode, KeywordRestParameterNode, NoKeywordsParameterNode, ForwardingParameterNode, BlockParameterNode, NoBlockParameterNode)], keywords: T::Array[T.any(RequiredKeywordParameterNode, OptionalKeywordParameterNode)], keyword_rest: T.nilable(T.any(KeywordRestParameterNode, ForwardingParameterNode, NoKeywordsParameterNode)), block: T.nilable(T.any(BlockParameterNode, NoBlockParameterNode))).returns(ParametersNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), requireds: T.unsafe(nil), optionals: T.unsafe(nil), rest: T.unsafe(nil), posts: T.unsafe(nil), keywords: T.unsafe(nil), keyword_rest: T.unsafe(nil), block: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { returns(T::Array[T.any(RequiredParameterNode, MultiTargetNode)]) }
    def requireds; end

    # Returns the `optionals` attribute.
    sig { returns(T::Array[OptionalParameterNode]) }
    def optionals; end

    # Returns the `rest` attribute.
    sig { returns(T.nilable(T.any(RestParameterNode, ImplicitRestNode))) }
    def rest; end

    # Returns the `posts` attribute.
    sig { returns(T::Array[T.any(RequiredParameterNode, MultiTargetNode, KeywordRestParameterNode, NoKeywordsParameterNode, ForwardingParameterNode, BlockParameterNode, NoBlockParameterNode)]) }
    def posts; end

    # Returns the `keywords` attribute.
    sig { returns(T::Array[T.any(RequiredKeywordParameterNode, OptionalKeywordParameterNode)]) }
    def keywords; end

    # Returns the `keyword_rest` attribute.
    sig { returns(T.nilable(T.any(KeywordRestParameterNode, ForwardingParameterNode, NoKeywordsParameterNode))) }
    def keyword_rest; end

    # Returns the `block` attribute.
    sig { returns(T.nilable(T.any(BlockParameterNode, NoBlockParameterNode))) }
    def block; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a parenthesized expression
  #
  #     (10 + 34)
  #     ^^^^^^^^^
  class ParenthesesNode < Node
    # Initialize a new ParenthesesNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, body: T.nilable(Node), opening_loc: Location, closing_loc: Location).void }
    def initialize(source, node_id, location, flags, body, opening_loc, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, body: T.nilable(Node), opening_loc: Location, closing_loc: Location).returns(ParenthesesNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), body: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { returns(T.nilable(Node)) }
    def body; end

    # Returns the Location represented by `opening_loc`.
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_closing_loc(repository); end

    # Slice the location of opening_loc from the source.
    sig { returns(String) }
    def opening; end

    # Slice the location of closing_loc from the source.
    sig { returns(String) }
    def closing; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `^` operator for pinning an expression in a pattern matching expression.
  #
  #     foo in ^(bar)
  #            ^^^^^^
  class PinnedExpressionNode < Node
    # Initialize a new PinnedExpressionNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, expression: Node, operator_loc: Location, lparen_loc: Location, rparen_loc: Location).void }
    def initialize(source, node_id, location, flags, expression, operator_loc, lparen_loc, rparen_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, expression: Node, operator_loc: Location, lparen_loc: Location, rparen_loc: Location).returns(PinnedExpressionNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), expression: T.unsafe(nil), operator_loc: T.unsafe(nil), lparen_loc: T.unsafe(nil), rparen_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     foo in ^(bar)
    #              ^^^
    sig { returns(Node) }
    def expression; end

    # The Location of the `^` operator
    #
    #     foo in ^(bar)
    #            ^
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # The Location of the opening parenthesis.
    #
    #     foo in ^(bar)
    #             ^
    sig { returns(Location) }
    def lparen_loc; end

    # Save the lparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_lparen_loc(repository); end

    # The Location of the closing parenthesis.
    #
    #     foo in ^(bar)
    #                 ^
    sig { returns(Location) }
    def rparen_loc; end

    # Save the rparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `^` operator for pinning a variable in a pattern matching expression.
  #
  #     foo in ^bar
  #            ^^^^
  class PinnedVariableNode < Node
    # Initialize a new PinnedVariableNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, variable: T.any(LocalVariableReadNode, InstanceVariableReadNode, ClassVariableReadNode, GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode, ItLocalVariableReadNode, MissingNode), operator_loc: Location).void }
    def initialize(source, node_id, location, flags, variable, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, variable: T.any(LocalVariableReadNode, InstanceVariableReadNode, ClassVariableReadNode, GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode, ItLocalVariableReadNode, MissingNode), operator_loc: Location).returns(PinnedVariableNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), variable: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     foo in ^bar
    #             ^^^
    sig { returns(T.any(LocalVariableReadNode, InstanceVariableReadNode, ClassVariableReadNode, GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode, ItLocalVariableReadNode, MissingNode)) }
    def variable; end

    # The Location of the `^` operator
    #
    #     foo in ^bar
    #            ^
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `END` keyword.
  #
  #     END { foo }
  #     ^^^^^^^^^^^
  class PostExecutionNode < Node
    # Initialize a new PostExecutionNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, statements: T.nilable(StatementsNode), keyword_loc: Location, opening_loc: Location, closing_loc: Location).void }
    def initialize(source, node_id, location, flags, statements, keyword_loc, opening_loc, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, statements: T.nilable(StatementsNode), keyword_loc: Location, opening_loc: Location, closing_loc: Location).returns(PostExecutionNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), statements: T.unsafe(nil), keyword_loc: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { returns(T.nilable(StatementsNode)) }
    def statements; end

    # Returns the Location represented by `keyword_loc`.
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Returns the Location represented by `opening_loc`.
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `BEGIN` keyword.
  #
  #     BEGIN { foo }
  #     ^^^^^^^^^^^^^
  class PreExecutionNode < Node
    # Initialize a new PreExecutionNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, statements: T.nilable(StatementsNode), keyword_loc: Location, opening_loc: Location, closing_loc: Location).void }
    def initialize(source, node_id, location, flags, statements, keyword_loc, opening_loc, closing_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, statements: T.nilable(StatementsNode), keyword_loc: Location, opening_loc: Location, closing_loc: Location).returns(PreExecutionNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), statements: T.unsafe(nil), keyword_loc: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { returns(T.nilable(StatementsNode)) }
    def statements; end

    # Returns the Location represented by `keyword_loc`.
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Returns the Location represented by `opening_loc`.
    sig { returns(Location) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # The top level node of any parse tree.
  class ProgramNode < Node
    # Initialize a new ProgramNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], statements: StatementsNode).void }
    def initialize(source, node_id, location, flags, locals, statements); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], statements: StatementsNode).returns(ProgramNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), locals: T.unsafe(nil), statements: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `..` or `...` operators.
  #
  #     1..2
  #     ^^^^
  #
  #     c if a =~ /left/ ... b =~ /right/
  #          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  class RangeNode < Node
    # Initialize a new RangeNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, left: T.nilable(Node), right: T.nilable(Node), operator_loc: Location).void }
    def initialize(source, node_id, location, flags, left, right, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, left: T.nilable(Node), right: T.nilable(Node), operator_loc: Location).returns(RangeNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), left: T.unsafe(nil), right: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     1...
    #     ^
    #
    #     hello...goodbye
    #     ^^^^^
    sig { returns(T.nilable(Node)) }
    def left; end

    # The right-hand side of the range, if present. It can be either `nil` or any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    #     ..5
    #       ^
    #
    #     1...foo
    #         ^^^
    # If neither right-hand or left-hand side was included, this will be a MissingNode.
    sig { returns(T.nilable(Node)) }
    def right; end

    # The Location of the `..` or `...` operator.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a rational number literal.
  #
  #     1.0r
  #     ^^^^
  class RationalNode < Node
    # Initialize a new RationalNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, numerator: Integer, denominator: Integer).void }
    def initialize(source, node_id, location, flags, numerator, denominator); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, numerator: Integer, denominator: Integer).returns(RationalNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), numerator: T.unsafe(nil), denominator: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     1.5r # numerator 3
    sig { returns(Integer) }
    def numerator; end

    # The denominator of the rational number.
    #
    #     1.5r # denominator 2
    sig { returns(Integer) }
    def denominator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `redo` keyword.
  #
  #     redo
  #     ^^^^
  class RedoNode < Node
    # Initialize a new RedoNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(RedoNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a regular expression literal with no interpolation.
  #
  #     /foo/i
  #     ^^^^^^
  class RegularExpressionNode < Node
    # Initialize a new RegularExpressionNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: Location, content_loc: Location, closing_loc: Location, unescaped: String).void }
    def initialize(source, node_id, location, flags, opening_loc, content_loc, closing_loc, unescaped); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, opening_loc: Location, content_loc: Location, closing_loc: Location, unescaped: String).returns(RegularExpressionNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), content_loc: T.unsafe(nil), closing_loc: T.unsafe(nil), unescaped: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the Location represented by `content_loc`.
    sig { returns(Location) }
    def content_loc; end

    # Save the content_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_content_loc(repository); end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a required keyword parameter to a method, block, or lambda definition.
  #
  #     def a(b: )
  #           ^^
  #     end
  class RequiredKeywordParameterNode < Node
    # Initialize a new RequiredKeywordParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location).void }
    def initialize(source, node_id, location, flags, name, name_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location).returns(RequiredKeywordParameterNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_name_loc(repository); end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a required parameter to a method, block, or lambda definition.
  #
  #     def a(b)
  #           ^
  #     end
  class RequiredParameterNode < Node
    # Initialize a new RequiredParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).void }
    def initialize(source, node_id, location, flags, name); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(RequiredParameterNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an expression modified with a rescue.
  #
  #     foo rescue nil
  #     ^^^^^^^^^^^^^^
  class RescueModifierNode < Node
    # Initialize a new RescueModifierNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, expression: Node, keyword_loc: Location, rescue_expression: Node).void }
    def initialize(source, node_id, location, flags, expression, keyword_loc, rescue_expression); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, expression: Node, keyword_loc: Location, rescue_expression: Node).returns(RescueModifierNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), expression: T.unsafe(nil), keyword_loc: T.unsafe(nil), rescue_expression: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Returns the `rescue_expression` attribute.
    sig { returns(Node) }
    def rescue_expression; end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a rescue statement.
  #
  #     begin
  #     rescue Foo, *splat, Bar => ex
  #       foo
  #     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  #     end
  #
  # `Foo, *splat, Bar` are in the `exceptions` field. `ex` is in the `reference` field.
  class RescueNode < Node
    # Initialize a new RescueNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, exceptions: T::Array[Node], operator_loc: T.nilable(Location), reference: T.nilable(T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, BackReferenceReadNode, NumberedReferenceReadNode, MissingNode)), then_keyword_loc: T.nilable(Location), statements: T.nilable(StatementsNode), subsequent: T.nilable(RescueNode)).void }
    def initialize(source, node_id, location, flags, keyword_loc, exceptions, operator_loc, reference, then_keyword_loc, statements, subsequent); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, exceptions: T::Array[Node], operator_loc: T.nilable(Location), reference: T.nilable(T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, BackReferenceReadNode, NumberedReferenceReadNode, MissingNode)), then_keyword_loc: T.nilable(Location), statements: T.nilable(StatementsNode), subsequent: T.nilable(RescueNode)).returns(RescueNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), keyword_loc: T.unsafe(nil), exceptions: T.unsafe(nil), operator_loc: T.unsafe(nil), reference: T.unsafe(nil), then_keyword_loc: T.unsafe(nil), statements: T.unsafe(nil), subsequent: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Returns the `exceptions` attribute.
    sig { returns(T::Array[Node]) }
    def exceptions; end

    # Returns the Location represented by `operator_loc`.
    sig { returns(T.nilable(Location)) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_operator_loc(repository); end

    # Returns the `reference` attribute.
    sig { returns(T.nilable(T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, BackReferenceReadNode, NumberedReferenceReadNode, MissingNode))) }
    def reference; end

    # Returns the Location represented by `then_keyword_loc`.
    sig { returns(T.nilable(Location)) }
    def then_keyword_loc; end

    # Save the then_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_then_keyword_loc(repository); end

    # Returns the `statements` attribute.
    sig { returns(T.nilable(StatementsNode)) }
    def statements; end

    # Returns the `subsequent` attribute.
    sig { returns(T.nilable(RescueNode)) }
    def subsequent; end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    # Slice the location of operator_loc from the source.
    sig { returns(T.nilable(String)) }
    def operator; end

    # Slice the location of then_keyword_loc from the source.
    sig { returns(T.nilable(String)) }
    def then_keyword; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a rest parameter to a method, block, or lambda definition.
  #
  #     def a(*b)
  #           ^^
  #     end
  class RestParameterNode < Node
    # Initialize a new RestParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: T.nilable(Symbol), name_loc: T.nilable(Location), operator_loc: Location).void }
    def initialize(source, node_id, location, flags, name, name_loc, operator_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, name: T.nilable(Symbol), name_loc: T.nilable(Location), operator_loc: Location).returns(RestParameterNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { returns(T.nilable(Symbol)) }
    def name; end

    # Returns the Location represented by `name_loc`.
    sig { returns(T.nilable(Location)) }
    def name_loc; end

    # Save the name_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_name_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `retry` keyword.
  #
  #     retry
  #     ^^^^^
  class RetryNode < Node
    # Initialize a new RetryNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(RetryNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `return` keyword.
  #
  #     return 1
  #     ^^^^^^^^
  class ReturnNode < Node
    # Initialize a new ReturnNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, arguments: T.nilable(ArgumentsNode)).void }
    def initialize(source, node_id, location, flags, keyword_loc, arguments); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, arguments: T.nilable(ArgumentsNode)).returns(ReturnNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), keyword_loc: T.unsafe(nil), arguments: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Returns the `arguments` attribute.
    sig { returns(T.nilable(ArgumentsNode)) }
    def arguments; end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the `self` keyword.
  #
  #     self
  #     ^^^^
  class SelfNode < Node
    # Initialize a new SelfNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(SelfNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # This node wraps a constant write to indicate that when the value is written, it should have its shareability state modified.
  #
  #     # shareable_constant_value: literal
  #     C = { a: 1 }
  #     ^^^^^^^^^^^^
  class ShareableConstantNode < Node
    # Initialize a new ShareableConstantNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, write: T.any(ConstantWriteNode, ConstantAndWriteNode, ConstantOrWriteNode, ConstantOperatorWriteNode, ConstantPathWriteNode, ConstantPathAndWriteNode, ConstantPathOrWriteNode, ConstantPathOperatorWriteNode)).void }
    def initialize(source, node_id, location, flags, write); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, write: T.any(ConstantWriteNode, ConstantAndWriteNode, ConstantOrWriteNode, ConstantOperatorWriteNode, ConstantPathWriteNode, ConstantPathAndWriteNode, ConstantPathOrWriteNode, ConstantPathOperatorWriteNode)).returns(ShareableConstantNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), write: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { returns(T.any(ConstantWriteNode, ConstantAndWriteNode, ConstantOrWriteNode, ConstantOperatorWriteNode, ConstantPathWriteNode, ConstantPathAndWriteNode, ConstantPathOrWriteNode, ConstantPathOperatorWriteNode)) }
    def write; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a singleton class declaration involving the `class` keyword.
  #
  #     class << self end
  #     ^^^^^^^^^^^^^^^^^
  class SingletonClassNode < Node
    # Initialize a new SingletonClassNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], class_keyword_loc: Location, operator_loc: Location, expression: Node, body: T.nilable(T.any(StatementsNode, BeginNode)), end_keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, locals, class_keyword_loc, operator_loc, expression, body, end_keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], class_keyword_loc: Location, operator_loc: Location, expression: Node, body: T.nilable(T.any(StatementsNode, BeginNode)), end_keyword_loc: Location).returns(SingletonClassNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), locals: T.unsafe(nil), class_keyword_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), expression: T.unsafe(nil), body: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_class_keyword_loc(repository); end

    # Returns the Location represented by `operator_loc`.
    sig { returns(Location) }
    def operator_loc; end

    # Save the operator_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `expression` attribute.
    sig { returns(Node) }
    def expression; end

    # Returns the `body` attribute.
    sig { returns(T.nilable(T.any(StatementsNode, BeginNode))) }
    def body; end

    # Returns the Location represented by `end_keyword_loc`.
    sig { returns(Location) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `__ENCODING__` keyword.
  #
  #     __ENCODING__
  #     ^^^^^^^^^^^^
  class SourceEncodingNode < Node
    # Initialize a new SourceEncodingNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(SourceEncodingNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `__FILE__` keyword.
  #
  #     __FILE__
  #     ^^^^^^^^
  class SourceFileNode < Node
    # Initialize a new SourceFileNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, filepath: String).void }
    def initialize(source, node_id, location, flags, filepath); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, filepath: String).returns(SourceFileNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), filepath: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `__LINE__` keyword.
  #
  #     __LINE__
  #     ^^^^^^^^
  class SourceLineNode < Node
    # Initialize a new SourceLineNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(SourceLineNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the splat operator.
  #
  #     [*a]
  #      ^^
  class SplatNode < Node
    # Initialize a new SplatNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, operator_loc: Location, expression: T.nilable(Node)).void }
    def initialize(source, node_id, location, flags, operator_loc, expression); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, operator_loc: Location, expression: T.nilable(Node)).returns(SplatNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), operator_loc: T.unsafe(nil), expression: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_operator_loc(repository); end

    # Returns the `expression` attribute.
    sig { returns(T.nilable(Node)) }
    def expression; end

    # Slice the location of operator_loc from the source.
    sig { returns(String) }
    def operator; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a set of statements contained within some scope.
  #
  #     foo; bar; baz
  #     ^^^^^^^^^^^^^
  class StatementsNode < Node
    # Initialize a new StatementsNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, body: T::Array[Node]).void }
    def initialize(source, node_id, location, flags, body); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, body: T::Array[Node]).returns(StatementsNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), body: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a string literal, a string contained within a `%w` list, or plain string content within an interpolated string.
  #
  #     "foo"
  #     ^^^^^
  #
  #     %w[foo]
  #        ^^^
  #
  #     "foo #{bar} baz"
  #      ^^^^      ^^^^
  class StringNode < Node
    # Initialize a new StringNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: T.nilable(Location), content_loc: Location, closing_loc: T.nilable(Location), unescaped: String).void }
    def initialize(source, node_id, location, flags, opening_loc, content_loc, closing_loc, unescaped); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, opening_loc: T.nilable(Location), content_loc: Location, closing_loc: T.nilable(Location), unescaped: String).returns(StringNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), content_loc: T.unsafe(nil), closing_loc: T.unsafe(nil), unescaped: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { returns(T.nilable(Location)) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_opening_loc(repository); end

    # Returns the Location represented by `content_loc`.
    sig { returns(Location) }
    def content_loc; end

    # Save the content_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_content_loc(repository); end

    # Returns the Location represented by `closing_loc`.
    sig { returns(T.nilable(Location)) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_closing_loc(repository); end

    # Returns the `unescaped` attribute.
    sig { returns(String) }
    def unescaped; end

    # Slice the location of opening_loc from the source.
    sig { returns(T.nilable(String)) }
    def opening; end

    # Slice the location of content_loc from the source.
    sig { returns(String) }
    def content; end

    # Slice the location of closing_loc from the source.
    sig { returns(T.nilable(String)) }
    def closing; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `super` keyword with parentheses or arguments.
  #
  #     super()
  #     ^^^^^^^
  #
  #     super foo, bar
  #     ^^^^^^^^^^^^^^
  #
  # If no arguments are provided (except for a block), it would be a `ForwardingSuperNode` instead.
  class SuperNode < Node
    # Initialize a new SuperNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, lparen_loc: T.nilable(Location), arguments: T.nilable(ArgumentsNode), rparen_loc: T.nilable(Location), block: T.nilable(T.any(BlockNode, BlockArgumentNode))).void }
    def initialize(source, node_id, location, flags, keyword_loc, lparen_loc, arguments, rparen_loc, block); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, lparen_loc: T.nilable(Location), arguments: T.nilable(ArgumentsNode), rparen_loc: T.nilable(Location), block: T.nilable(T.any(BlockNode, BlockArgumentNode))).returns(SuperNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), keyword_loc: T.unsafe(nil), lparen_loc: T.unsafe(nil), arguments: T.unsafe(nil), rparen_loc: T.unsafe(nil), block: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Returns the Location represented by `lparen_loc`.
    sig { returns(T.nilable(Location)) }
    def lparen_loc; end

    # Save the lparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_lparen_loc(repository); end

    # Can be only `nil` when there are empty parentheses, like `super()`.
    sig { returns(T.nilable(ArgumentsNode)) }
    def arguments; end

    # Returns the Location represented by `rparen_loc`.
    sig { returns(T.nilable(Location)) }
    def rparen_loc; end

    # Save the rparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_rparen_loc(repository); end

    # Returns the `block` attribute.
    sig { returns(T.nilable(T.any(BlockNode, BlockArgumentNode))) }
    def block; end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    # Slice the location of lparen_loc from the source.
    sig { returns(T.nilable(String)) }
    def lparen; end

    # Slice the location of rparen_loc from the source.
    sig { returns(T.nilable(String)) }
    def rparen; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents a symbol literal or a symbol contained within a `%i` list.
  #
  #     :foo
  #     ^^^^
  #
  #     %i[foo]
  #        ^^^
  class SymbolNode < Node
    # Initialize a new SymbolNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: T.nilable(Location), value_loc: T.nilable(Location), closing_loc: T.nilable(Location), unescaped: String).void }
    def initialize(source, node_id, location, flags, opening_loc, value_loc, closing_loc, unescaped); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, opening_loc: T.nilable(Location), value_loc: T.nilable(Location), closing_loc: T.nilable(Location), unescaped: String).returns(SymbolNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), value_loc: T.unsafe(nil), closing_loc: T.unsafe(nil), unescaped: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { returns(T.nilable(Location)) }
    def opening_loc; end

    # Save the opening_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_opening_loc(repository); end

    # Returns the Location represented by `value_loc`.
    sig { returns(T.nilable(Location)) }
    def value_loc; end

    # Save the value_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_value_loc(repository); end

    # Returns the Location represented by `closing_loc`.
    sig { returns(T.nilable(Location)) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_closing_loc(repository); end

    # Returns the `unescaped` attribute.
    sig { returns(String) }
    def unescaped; end

    # Slice the location of opening_loc from the source.
    sig { returns(T.nilable(String)) }
    def opening; end

    # Slice the location of value_loc from the source.
    sig { returns(T.nilable(String)) }
    def value; end

    # Slice the location of closing_loc from the source.
    sig { returns(T.nilable(String)) }
    def closing; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the literal `true` keyword.
  #
  #     true
  #     ^^^^
  class TrueNode < Node
    # Initialize a new TrueNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).void }
    def initialize(source, node_id, location, flags); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer).returns(TrueNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
    def deconstruct_keys(keys); end

    # See `Node#type`.
    sig { override.returns(Symbol) }
    def type; end

    # See `Node.type`.
    sig { override.returns(Symbol) }
    def self.type; end

    sig { override.returns(String) }
    def inspect; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `undef` keyword.
  #
  #     undef :foo, :bar, :baz
  #     ^^^^^^^^^^^^^^^^^^^^^^
  class UndefNode < Node
    # Initialize a new UndefNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, names: T::Array[T.any(SymbolNode, InterpolatedSymbolNode)], keyword_loc: Location).void }
    def initialize(source, node_id, location, flags, names, keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, names: T::Array[T.any(SymbolNode, InterpolatedSymbolNode)], keyword_loc: Location).returns(UndefNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), names: T.unsafe(nil), keyword_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { returns(T::Array[T.any(SymbolNode, InterpolatedSymbolNode)]) }
    def names; end

    # Returns the Location represented by `keyword_loc`.
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `unless` keyword, either in the block form or the modifier form.
  #
  #     bar unless foo
  #     ^^^^^^^^^^^^^^
  #
  #     unless foo then bar end
  #     ^^^^^^^^^^^^^^^^^^^^^^^
  class UnlessNode < Node
    # Initialize a new UnlessNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, predicate: Node, then_keyword_loc: T.nilable(Location), statements: T.nilable(StatementsNode), else_clause: T.nilable(ElseNode), end_keyword_loc: T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, keyword_loc, predicate, then_keyword_loc, statements, else_clause, end_keyword_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, predicate: Node, then_keyword_loc: T.nilable(Location), statements: T.nilable(StatementsNode), else_clause: T.nilable(ElseNode), end_keyword_loc: T.nilable(Location)).returns(UnlessNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), keyword_loc: T.unsafe(nil), predicate: T.unsafe(nil), then_keyword_loc: T.unsafe(nil), statements: T.unsafe(nil), else_clause: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    #     unless cond then bar end
    #     ^^^^^^
    #
    #     bar unless cond
    #         ^^^^^^
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # The condition to be evaluated for the unless expression. It can be any [non-void expression](https://github.com/ruby/prism/blob/main/docs/parsing_rules.md#non-void-expression).
    #
    #     unless cond then bar end
    #            ^^^^
    #
    #     bar unless cond
    #                ^^^^
    sig { returns(Node) }
    def predicate; end

    # The Location of the `then` keyword, if present.
    #
    #     unless cond then bar end
    #                 ^^^^
    sig { returns(T.nilable(Location)) }
    def then_keyword_loc; end

    # Save the then_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_then_keyword_loc(repository); end

    # The body of statements that will executed if the unless condition is
    # falsey. Will be `nil` if no body is provided.
    #
    #     unless cond then bar end
    #                      ^^^
    sig { returns(T.nilable(StatementsNode)) }
    def statements; end

    # The else clause of the unless expression, if present.
    #
    #     unless cond then bar else baz end
    #                          ^^^^^^^^
    sig { returns(T.nilable(ElseNode)) }
    def else_clause; end

    # The Location of the `end` keyword, if present.
    #
    #     unless cond then bar end
    #                          ^^^
    sig { returns(T.nilable(Location)) }
    def end_keyword_loc; end

    # Save the end_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_end_keyword_loc(repository); end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    # Slice the location of then_keyword_loc from the source.
    sig { returns(T.nilable(String)) }
    def then_keyword; end

    # Slice the location of end_keyword_loc from the source.
    sig { returns(T.nilable(String)) }
    def end_keyword; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `until` keyword, either in the block form or the modifier form.
  #
  #     bar until foo
  #     ^^^^^^^^^^^^^
  #
  #     until foo do bar end
  #     ^^^^^^^^^^^^^^^^^^^^
  class UntilNode < Node
    # Initialize a new UntilNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, do_keyword_loc: T.nilable(Location), closing_loc: T.nilable(Location), predicate: Node, statements: T.nilable(StatementsNode)).void }
    def initialize(source, node_id, location, flags, keyword_loc, do_keyword_loc, closing_loc, predicate, statements); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, do_keyword_loc: T.nilable(Location), closing_loc: T.nilable(Location), predicate: Node, statements: T.nilable(StatementsNode)).returns(UntilNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), keyword_loc: T.unsafe(nil), do_keyword_loc: T.unsafe(nil), closing_loc: T.unsafe(nil), predicate: T.unsafe(nil), statements: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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

    # Returns the Location represented by `keyword_loc`.
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Returns the Location represented by `do_keyword_loc`.
    sig { returns(T.nilable(Location)) }
    def do_keyword_loc; end

    # Save the do_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_do_keyword_loc(repository); end

    # Returns the Location represented by `closing_loc`.
    sig { returns(T.nilable(Location)) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_closing_loc(repository); end

    # Returns the `predicate` attribute.
    sig { returns(Node) }
    def predicate; end

    # Returns the `statements` attribute.
    sig { returns(T.nilable(StatementsNode)) }
    def statements; end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    # Slice the location of do_keyword_loc from the source.
    sig { returns(T.nilable(String)) }
    def do_keyword; end

    # Slice the location of closing_loc from the source.
    sig { returns(T.nilable(String)) }
    def closing; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `when` keyword within a case statement.
  #
  #     case true
  #     when true
  #     ^^^^^^^^^
  #     end
  class WhenNode < Node
    # Initialize a new WhenNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, conditions: T::Array[Node], then_keyword_loc: T.nilable(Location), statements: T.nilable(StatementsNode)).void }
    def initialize(source, node_id, location, flags, keyword_loc, conditions, then_keyword_loc, statements); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, conditions: T::Array[Node], then_keyword_loc: T.nilable(Location), statements: T.nilable(StatementsNode)).returns(WhenNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), keyword_loc: T.unsafe(nil), conditions: T.unsafe(nil), then_keyword_loc: T.unsafe(nil), statements: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Returns the `conditions` attribute.
    sig { returns(T::Array[Node]) }
    def conditions; end

    # Returns the Location represented by `then_keyword_loc`.
    sig { returns(T.nilable(Location)) }
    def then_keyword_loc; end

    # Save the then_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_then_keyword_loc(repository); end

    # Returns the `statements` attribute.
    sig { returns(T.nilable(StatementsNode)) }
    def statements; end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    # Slice the location of then_keyword_loc from the source.
    sig { returns(T.nilable(String)) }
    def then_keyword; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `while` keyword, either in the block form or the modifier form.
  #
  #     bar while foo
  #     ^^^^^^^^^^^^^
  #
  #     while foo do bar end
  #     ^^^^^^^^^^^^^^^^^^^^
  class WhileNode < Node
    # Initialize a new WhileNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, do_keyword_loc: T.nilable(Location), closing_loc: T.nilable(Location), predicate: Node, statements: T.nilable(StatementsNode)).void }
    def initialize(source, node_id, location, flags, keyword_loc, do_keyword_loc, closing_loc, predicate, statements); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, do_keyword_loc: T.nilable(Location), closing_loc: T.nilable(Location), predicate: Node, statements: T.nilable(StatementsNode)).returns(WhileNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), keyword_loc: T.unsafe(nil), do_keyword_loc: T.unsafe(nil), closing_loc: T.unsafe(nil), predicate: T.unsafe(nil), statements: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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

    # Returns the Location represented by `keyword_loc`.
    sig { returns(Location) }
    def keyword_loc; end

    # Save the keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Returns the Location represented by `do_keyword_loc`.
    sig { returns(T.nilable(Location)) }
    def do_keyword_loc; end

    # Save the do_keyword_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_do_keyword_loc(repository); end

    # Returns the Location represented by `closing_loc`.
    sig { returns(T.nilable(Location)) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_closing_loc(repository); end

    # Returns the `predicate` attribute.
    sig { returns(Node) }
    def predicate; end

    # Returns the `statements` attribute.
    sig { returns(T.nilable(StatementsNode)) }
    def statements; end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    # Slice the location of do_keyword_loc from the source.
    sig { returns(T.nilable(String)) }
    def do_keyword; end

    # Slice the location of closing_loc from the source.
    sig { returns(T.nilable(String)) }
    def closing; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents an xstring literal with no interpolation.
  #
  #     `foo`
  #     ^^^^^
  class XStringNode < Node
    # Initialize a new XStringNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: Location, content_loc: Location, closing_loc: Location, unescaped: String).void }
    def initialize(source, node_id, location, flags, opening_loc, content_loc, closing_loc, unescaped); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, opening_loc: Location, content_loc: Location, closing_loc: Location, unescaped: String).returns(XStringNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), content_loc: T.unsafe(nil), closing_loc: T.unsafe(nil), unescaped: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_opening_loc(repository); end

    # Returns the Location represented by `content_loc`.
    sig { returns(Location) }
    def content_loc; end

    # Save the content_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_content_loc(repository); end

    # Returns the Location represented by `closing_loc`.
    sig { returns(Location) }
    def closing_loc; end

    # Save the closing_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
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

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Represents the use of the `yield` keyword.
  #
  #     yield 1
  #     ^^^^^^^
  class YieldNode < Node
    # Initialize a new YieldNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, lparen_loc: T.nilable(Location), arguments: T.nilable(ArgumentsNode), rparen_loc: T.nilable(Location)).void }
    def initialize(source, node_id, location, flags, keyword_loc, lparen_loc, arguments, rparen_loc); end

    # See Node.accept.
    sig { override.params(visitor: Visitor).returns(T.untyped) }
    def accept(visitor); end

    # See Node.child_nodes.
    sig { override.returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    # See Node.each_child_node.
    sig { override.returns(T::Enumerator[Node]) }
    sig { override.params(blk: T.proc.params(arg0: Node).void).void }
    def each_child_node(&blk); end

    # See Node.compact_child_nodes.
    sig { override.returns(T::Array[Node]) }
    def compact_child_nodes; end

    # See Node.comment_targets.
    sig { override.returns(T::Array[T.any(Node, Location)]) }
    def comment_targets; end

    # Creates a copy of self with the given fields, using self as the template.
    sig { params(node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, lparen_loc: T.nilable(Location), arguments: T.nilable(ArgumentsNode), rparen_loc: T.nilable(Location)).returns(YieldNode) }
    def copy(node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), keyword_loc: T.unsafe(nil), lparen_loc: T.unsafe(nil), arguments: T.unsafe(nil), rparen_loc: T.unsafe(nil)); end

    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
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
    sig { params(repository: T.untyped).returns(Relocation::Entry) }
    def save_keyword_loc(repository); end

    # Returns the Location represented by `lparen_loc`.
    sig { returns(T.nilable(Location)) }
    def lparen_loc; end

    # Save the lparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_lparen_loc(repository); end

    # Returns the `arguments` attribute.
    sig { returns(T.nilable(ArgumentsNode)) }
    def arguments; end

    # Returns the Location represented by `rparen_loc`.
    sig { returns(T.nilable(Location)) }
    def rparen_loc; end

    # Save the rparen_loc location using the given saved source so that
    # it can be retrieved later.
    sig { params(repository: T.untyped).returns(T.nilable(Relocation::Entry)) }
    def save_rparen_loc(repository); end

    # Slice the location of keyword_loc from the source.
    sig { returns(String) }
    def keyword; end

    # Slice the location of lparen_loc from the source.
    sig { returns(T.nilable(String)) }
    def lparen; end

    # Slice the location of rparen_loc from the source.
    sig { returns(T.nilable(String)) }
    def rparen; end

    sig { params(other: T.untyped).returns(T.nilable(T::Boolean)) }
    def ===(other); end
  end

  # Flags for arguments nodes.
  module ArgumentsNodeFlags
    # if the arguments contain forwarding
    CONTAINS_FORWARDING = T.let(nil, T.untyped)

    # if the arguments contain keywords
    CONTAINS_KEYWORDS = T.let(nil, T.untyped)

    # if the arguments contain a keyword splat
    CONTAINS_KEYWORD_SPLAT = T.let(nil, T.untyped)

    # if the arguments contain a splat
    CONTAINS_SPLAT = T.let(nil, T.untyped)

    # if the arguments contain multiple splats
    CONTAINS_MULTIPLE_SPLATS = T.let(nil, T.untyped)
  end

  # Flags for array nodes.
  module ArrayNodeFlags
    # if array contains splat nodes
    CONTAINS_SPLAT = T.let(nil, T.untyped)
  end

  # Flags for call nodes.
  module CallNodeFlags
    # &. operator
    SAFE_NAVIGATION = T.let(nil, T.untyped)

    # a call that could have been a local variable
    VARIABLE_CALL = T.let(nil, T.untyped)

    # a call that is an attribute write, so the value being written should be returned
    ATTRIBUTE_WRITE = T.let(nil, T.untyped)

    # a call that ignores method visibility
    IGNORE_VISIBILITY = T.let(nil, T.untyped)
  end

  # Flags for nodes that have unescaped content.
  module EncodingFlags
    # internal bytes forced the encoding to UTF-8
    FORCED_UTF8_ENCODING = T.let(nil, T.untyped)

    # internal bytes forced the encoding to binary
    FORCED_BINARY_ENCODING = T.let(nil, T.untyped)
  end

  # Flags for integer nodes that correspond to the base of the integer.
  module IntegerBaseFlags
    # 0b prefix
    BINARY = T.let(nil, T.untyped)

    # 0d or no prefix
    DECIMAL = T.let(nil, T.untyped)

    # 0o or 0 prefix
    OCTAL = T.let(nil, T.untyped)

    # 0x prefix
    HEXADECIMAL = T.let(nil, T.untyped)
  end

  # Flags for interpolated string nodes that indicated mutability if they are also marked as literals.
  module InterpolatedStringNodeFlags
    # frozen by virtue of a `frozen_string_literal: true` comment or `--enable-frozen-string-literal`; only for adjacent string literals like `'a' 'b'`
    FROZEN = T.let(nil, T.untyped)

    # mutable by virtue of a `frozen_string_literal: false` comment or `--disable-frozen-string-literal`; only for adjacent string literals like `'a' 'b'`
    MUTABLE = T.let(nil, T.untyped)
  end

  # Flags for keyword hash nodes.
  module KeywordHashNodeFlags
    # a keyword hash which only has `AssocNode` elements all with symbol keys, which means the elements can be treated as keyword arguments
    SYMBOL_KEYS = T.let(nil, T.untyped)
  end

  # Flags for while and until loop nodes.
  module LoopFlags
    # a loop after a begin statement, so the body is executed first before the condition
    BEGIN_MODIFIER = T.let(nil, T.untyped)
  end

  # Flags for parameter nodes.
  module ParameterFlags
    # a parameter name that has been repeated in the method signature
    REPEATED_PARAMETER = T.let(nil, T.untyped)
  end

  # Flags for parentheses nodes.
  module ParenthesesNodeFlags
    # parentheses that contain multiple potentially void statements
    MULTIPLE_STATEMENTS = T.let(nil, T.untyped)
  end

  # Flags for range and flip-flop nodes.
  module RangeFlags
    # ... operator
    EXCLUDE_END = T.let(nil, T.untyped)
  end

  # Flags for regular expression and match last line nodes.
  module RegularExpressionFlags
    # i - ignores the case of characters when matching
    IGNORE_CASE = T.let(nil, T.untyped)

    # x - ignores whitespace and allows comments in regular expressions
    EXTENDED = T.let(nil, T.untyped)

    # m - allows $ to match the end of lines within strings
    MULTI_LINE = T.let(nil, T.untyped)

    # o - only interpolates values into the regular expression once
    ONCE = T.let(nil, T.untyped)

    # e - forces the EUC-JP encoding
    EUC_JP = T.let(nil, T.untyped)

    # n - forces the ASCII-8BIT encoding
    ASCII_8BIT = T.let(nil, T.untyped)

    # s - forces the Windows-31J encoding
    WINDOWS_31J = T.let(nil, T.untyped)

    # u - forces the UTF-8 encoding
    UTF_8 = T.let(nil, T.untyped)

    # internal bytes forced the encoding to UTF-8
    FORCED_UTF8_ENCODING = T.let(nil, T.untyped)

    # internal bytes forced the encoding to binary
    FORCED_BINARY_ENCODING = T.let(nil, T.untyped)

    # internal bytes forced the encoding to US-ASCII
    FORCED_US_ASCII_ENCODING = T.let(nil, T.untyped)
  end

  # Flags for shareable constant nodes.
  module ShareableConstantNodeFlags
    # constant writes that should be modified with shareable constant value literal
    LITERAL = T.let(nil, T.untyped)

    # constant writes that should be modified with shareable constant value experimental everything
    EXPERIMENTAL_EVERYTHING = T.let(nil, T.untyped)

    # constant writes that should be modified with shareable constant value experimental copy
    EXPERIMENTAL_COPY = T.let(nil, T.untyped)
  end

  # Flags for string nodes.
  module StringFlags
    # internal bytes forced the encoding to UTF-8
    FORCED_UTF8_ENCODING = T.let(nil, T.untyped)

    # internal bytes forced the encoding to binary
    FORCED_BINARY_ENCODING = T.let(nil, T.untyped)

    # frozen by virtue of a `frozen_string_literal: true` comment or `--enable-frozen-string-literal`
    FROZEN = T.let(nil, T.untyped)

    # mutable by virtue of a `frozen_string_literal: false` comment or `--disable-frozen-string-literal`
    MUTABLE = T.let(nil, T.untyped)
  end

  # Flags for symbol nodes.
  module SymbolFlags
    # internal bytes forced the encoding to UTF-8
    FORCED_UTF8_ENCODING = T.let(nil, T.untyped)

    # internal bytes forced the encoding to binary
    FORCED_BINARY_ENCODING = T.let(nil, T.untyped)

    # internal bytes forced the encoding to US-ASCII
    FORCED_US_ASCII_ENCODING = T.let(nil, T.untyped)
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
