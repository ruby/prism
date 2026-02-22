# typed: true

module Prism
  # The DSL module provides a set of methods that can be used to create prism
  # nodes in a more concise manner. For example, instead of writing:
  #
  #     source = Prism::Source.for("[1]")
  #
  #     Prism::ArrayNode.new(
  #       source,
  #       0,
  #       Prism::Location.new(source, 0, 3),
  #       0,
  #       [
  #         Prism::IntegerNode.new(
  #           source,
  #           0,
  #           Prism::Location.new(source, 1, 1),
  #           Prism::IntegerBaseFlags::DECIMAL,
  #           1
  #         )
  #       ],
  #       Prism::Location.new(source, 0, 1),
  #       Prism::Location.new(source, 2, 1)
  #     )
  #
  # you could instead write:
  #
  #     class Builder
  #       include Prism::DSL
  #
  #       attr_reader :default_source
  #
  #       def initialize
  #         @default_source = source("[1]")
  #       end
  #
  #       def build
  #         array_node(
  #           location: location(start_offset: 0, length: 3),
  #           elements: [
  #             integer_node(
  #               location: location(start_offset: 1, length: 1),
  #               flags: integer_base_flag(:decimal),
  #               value: 1
  #             )
  #           ],
  #           opening_loc: location(start_offset: 0, length: 1),
  #           closing_loc: location(start_offset: 2, length: 1)
  #         )
  #       end
  #     end
  #
  # This is mostly helpful in the context of generating trees programmatically.
  module DSL
    # Create a new Source object.
    sig { params(string: String).returns(Source) }
    def source(string); end

    # Create a new Location object.
    sig { params(source: Source, start_offset: Integer, length: Integer).returns(Location) }
    def location(source: T.unsafe(nil), start_offset: T.unsafe(nil), length: T.unsafe(nil)); end

    # Create a new AliasGlobalVariableNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, new_name: T.any(GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode), old_name: T.any(GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode, SymbolNode, MissingNode), keyword_loc: Location).returns(AliasGlobalVariableNode) }
    def alias_global_variable_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), new_name: T.unsafe(nil), old_name: T.unsafe(nil), keyword_loc: T.unsafe(nil)); end

    # Create a new AliasMethodNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, new_name: T.any(SymbolNode, InterpolatedSymbolNode), old_name: T.any(SymbolNode, InterpolatedSymbolNode, GlobalVariableReadNode, MissingNode), keyword_loc: Location).returns(AliasMethodNode) }
    def alias_method_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), new_name: T.unsafe(nil), old_name: T.unsafe(nil), keyword_loc: T.unsafe(nil)); end

    # Create a new AlternationPatternNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, left: Node, right: Node, operator_loc: Location).returns(AlternationPatternNode) }
    def alternation_pattern_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), left: T.unsafe(nil), right: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    # Create a new AndNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, left: Node, right: Node, operator_loc: Location).returns(AndNode) }
    def and_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), left: T.unsafe(nil), right: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    # Create a new ArgumentsNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, arguments: T::Array[Node]).returns(ArgumentsNode) }
    def arguments_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), arguments: T.unsafe(nil)); end

    # Create a new ArrayNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, elements: T::Array[Node], opening_loc: T.nilable(Location), closing_loc: T.nilable(Location)).returns(ArrayNode) }
    def array_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), elements: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    # Create a new ArrayPatternNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, constant: T.nilable(T.any(ConstantPathNode, ConstantReadNode)), requireds: T::Array[Node], rest: T.nilable(Node), posts: T::Array[Node], opening_loc: T.nilable(Location), closing_loc: T.nilable(Location)).returns(ArrayPatternNode) }
    def array_pattern_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), constant: T.unsafe(nil), requireds: T.unsafe(nil), rest: T.unsafe(nil), posts: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    # Create a new AssocNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, key: Node, value: Node, operator_loc: T.nilable(Location)).returns(AssocNode) }
    def assoc_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), key: T.unsafe(nil), value: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    # Create a new AssocSplatNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, value: T.nilable(Node), operator_loc: Location).returns(AssocSplatNode) }
    def assoc_splat_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), value: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    # Create a new BackReferenceReadNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(BackReferenceReadNode) }
    def back_reference_read_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    # Create a new BeginNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, begin_keyword_loc: T.nilable(Location), statements: T.nilable(StatementsNode), rescue_clause: T.nilable(RescueNode), else_clause: T.nilable(ElseNode), ensure_clause: T.nilable(EnsureNode), end_keyword_loc: T.nilable(Location)).returns(BeginNode) }
    def begin_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), begin_keyword_loc: T.unsafe(nil), statements: T.unsafe(nil), rescue_clause: T.unsafe(nil), else_clause: T.unsafe(nil), ensure_clause: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    # Create a new BlockArgumentNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, expression: T.nilable(Node), operator_loc: Location).returns(BlockArgumentNode) }
    def block_argument_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), expression: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    # Create a new BlockLocalVariableNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(BlockLocalVariableNode) }
    def block_local_variable_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    # Create a new BlockNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], parameters: T.nilable(T.any(BlockParametersNode, NumberedParametersNode, ItParametersNode)), body: T.nilable(T.any(StatementsNode, BeginNode)), opening_loc: Location, closing_loc: Location).returns(BlockNode) }
    def block_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), locals: T.unsafe(nil), parameters: T.unsafe(nil), body: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    # Create a new BlockParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: T.nilable(Symbol), name_loc: T.nilable(Location), operator_loc: Location).returns(BlockParameterNode) }
    def block_parameter_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    # Create a new BlockParametersNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, parameters: T.nilable(ParametersNode), locals: T::Array[BlockLocalVariableNode], opening_loc: T.nilable(Location), closing_loc: T.nilable(Location)).returns(BlockParametersNode) }
    def block_parameters_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), parameters: T.unsafe(nil), locals: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    # Create a new BreakNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, arguments: T.nilable(ArgumentsNode), keyword_loc: Location).returns(BreakNode) }
    def break_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), arguments: T.unsafe(nil), keyword_loc: T.unsafe(nil)); end

    # Create a new CallAndWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: T.nilable(Node), call_operator_loc: T.nilable(Location), message_loc: T.nilable(Location), read_name: Symbol, write_name: Symbol, operator_loc: Location, value: Node).returns(CallAndWriteNode) }
    def call_and_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), call_operator_loc: T.unsafe(nil), message_loc: T.unsafe(nil), read_name: T.unsafe(nil), write_name: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    # Create a new CallNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: T.nilable(Node), call_operator_loc: T.nilable(Location), name: Symbol, message_loc: T.nilable(Location), opening_loc: T.nilable(Location), arguments: T.nilable(ArgumentsNode), closing_loc: T.nilable(Location), equal_loc: T.nilable(Location), block: T.nilable(T.any(BlockNode, BlockArgumentNode))).returns(CallNode) }
    def call_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), call_operator_loc: T.unsafe(nil), name: T.unsafe(nil), message_loc: T.unsafe(nil), opening_loc: T.unsafe(nil), arguments: T.unsafe(nil), closing_loc: T.unsafe(nil), equal_loc: T.unsafe(nil), block: T.unsafe(nil)); end

    # Create a new CallOperatorWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: T.nilable(Node), call_operator_loc: T.nilable(Location), message_loc: T.nilable(Location), read_name: Symbol, write_name: Symbol, binary_operator: Symbol, binary_operator_loc: Location, value: Node).returns(CallOperatorWriteNode) }
    def call_operator_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), call_operator_loc: T.unsafe(nil), message_loc: T.unsafe(nil), read_name: T.unsafe(nil), write_name: T.unsafe(nil), binary_operator: T.unsafe(nil), binary_operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    # Create a new CallOrWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: T.nilable(Node), call_operator_loc: T.nilable(Location), message_loc: T.nilable(Location), read_name: Symbol, write_name: Symbol, operator_loc: Location, value: Node).returns(CallOrWriteNode) }
    def call_or_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), call_operator_loc: T.unsafe(nil), message_loc: T.unsafe(nil), read_name: T.unsafe(nil), write_name: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    # Create a new CallTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: Node, call_operator_loc: Location, name: Symbol, message_loc: Location).returns(CallTargetNode) }
    def call_target_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), call_operator_loc: T.unsafe(nil), name: T.unsafe(nil), message_loc: T.unsafe(nil)); end

    # Create a new CapturePatternNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, value: Node, target: LocalVariableTargetNode, operator_loc: Location).returns(CapturePatternNode) }
    def capture_pattern_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), value: T.unsafe(nil), target: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    # Create a new CaseMatchNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, predicate: T.nilable(Node), conditions: T::Array[InNode], else_clause: T.nilable(ElseNode), case_keyword_loc: Location, end_keyword_loc: Location).returns(CaseMatchNode) }
    def case_match_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), predicate: T.unsafe(nil), conditions: T.unsafe(nil), else_clause: T.unsafe(nil), case_keyword_loc: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    # Create a new CaseNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, predicate: T.nilable(Node), conditions: T::Array[WhenNode], else_clause: T.nilable(ElseNode), case_keyword_loc: Location, end_keyword_loc: Location).returns(CaseNode) }
    def case_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), predicate: T.unsafe(nil), conditions: T.unsafe(nil), else_clause: T.unsafe(nil), case_keyword_loc: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    # Create a new ClassNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], class_keyword_loc: Location, constant_path: T.any(ConstantReadNode, ConstantPathNode, CallNode), inheritance_operator_loc: T.nilable(Location), superclass: T.nilable(Node), body: T.nilable(T.any(StatementsNode, BeginNode)), end_keyword_loc: Location, name: Symbol).returns(ClassNode) }
    def class_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), locals: T.unsafe(nil), class_keyword_loc: T.unsafe(nil), constant_path: T.unsafe(nil), inheritance_operator_loc: T.unsafe(nil), superclass: T.unsafe(nil), body: T.unsafe(nil), end_keyword_loc: T.unsafe(nil), name: T.unsafe(nil)); end

    # Create a new ClassVariableAndWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(ClassVariableAndWriteNode) }
    def class_variable_and_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    # Create a new ClassVariableOperatorWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, binary_operator_loc: Location, value: Node, binary_operator: Symbol).returns(ClassVariableOperatorWriteNode) }
    def class_variable_operator_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), binary_operator_loc: T.unsafe(nil), value: T.unsafe(nil), binary_operator: T.unsafe(nil)); end

    # Create a new ClassVariableOrWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(ClassVariableOrWriteNode) }
    def class_variable_or_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    # Create a new ClassVariableReadNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(ClassVariableReadNode) }
    def class_variable_read_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    # Create a new ClassVariableTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(ClassVariableTargetNode) }
    def class_variable_target_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    # Create a new ClassVariableWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, value: Node, operator_loc: Location).returns(ClassVariableWriteNode) }
    def class_variable_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), value: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    # Create a new ConstantAndWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(ConstantAndWriteNode) }
    def constant_and_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    # Create a new ConstantOperatorWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, binary_operator_loc: Location, value: Node, binary_operator: Symbol).returns(ConstantOperatorWriteNode) }
    def constant_operator_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), binary_operator_loc: T.unsafe(nil), value: T.unsafe(nil), binary_operator: T.unsafe(nil)); end

    # Create a new ConstantOrWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(ConstantOrWriteNode) }
    def constant_or_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    # Create a new ConstantPathAndWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, target: ConstantPathNode, operator_loc: Location, value: Node).returns(ConstantPathAndWriteNode) }
    def constant_path_and_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), target: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    # Create a new ConstantPathNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, parent: T.nilable(Node), name: T.nilable(Symbol), delimiter_loc: Location, name_loc: Location).returns(ConstantPathNode) }
    def constant_path_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), parent: T.unsafe(nil), name: T.unsafe(nil), delimiter_loc: T.unsafe(nil), name_loc: T.unsafe(nil)); end

    # Create a new ConstantPathOperatorWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, target: ConstantPathNode, binary_operator_loc: Location, value: Node, binary_operator: Symbol).returns(ConstantPathOperatorWriteNode) }
    def constant_path_operator_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), target: T.unsafe(nil), binary_operator_loc: T.unsafe(nil), value: T.unsafe(nil), binary_operator: T.unsafe(nil)); end

    # Create a new ConstantPathOrWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, target: ConstantPathNode, operator_loc: Location, value: Node).returns(ConstantPathOrWriteNode) }
    def constant_path_or_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), target: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    # Create a new ConstantPathTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, parent: T.nilable(Node), name: T.nilable(Symbol), delimiter_loc: Location, name_loc: Location).returns(ConstantPathTargetNode) }
    def constant_path_target_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), parent: T.unsafe(nil), name: T.unsafe(nil), delimiter_loc: T.unsafe(nil), name_loc: T.unsafe(nil)); end

    # Create a new ConstantPathWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, target: ConstantPathNode, operator_loc: Location, value: Node).returns(ConstantPathWriteNode) }
    def constant_path_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), target: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    # Create a new ConstantReadNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(ConstantReadNode) }
    def constant_read_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    # Create a new ConstantTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(ConstantTargetNode) }
    def constant_target_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    # Create a new ConstantWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, value: Node, operator_loc: Location).returns(ConstantWriteNode) }
    def constant_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), value: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    # Create a new DefNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, receiver: T.nilable(Node), parameters: T.nilable(ParametersNode), body: T.nilable(T.any(StatementsNode, BeginNode)), locals: T::Array[Symbol], def_keyword_loc: Location, operator_loc: T.nilable(Location), lparen_loc: T.nilable(Location), rparen_loc: T.nilable(Location), equal_loc: T.nilable(Location), end_keyword_loc: T.nilable(Location)).returns(DefNode) }
    def def_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), receiver: T.unsafe(nil), parameters: T.unsafe(nil), body: T.unsafe(nil), locals: T.unsafe(nil), def_keyword_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), lparen_loc: T.unsafe(nil), rparen_loc: T.unsafe(nil), equal_loc: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    # Create a new DefinedNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, lparen_loc: T.nilable(Location), value: Node, rparen_loc: T.nilable(Location), keyword_loc: Location).returns(DefinedNode) }
    def defined_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), lparen_loc: T.unsafe(nil), value: T.unsafe(nil), rparen_loc: T.unsafe(nil), keyword_loc: T.unsafe(nil)); end

    # Create a new ElseNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, else_keyword_loc: Location, statements: T.nilable(StatementsNode), end_keyword_loc: T.nilable(Location)).returns(ElseNode) }
    def else_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), else_keyword_loc: T.unsafe(nil), statements: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    # Create a new EmbeddedStatementsNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: Location, statements: T.nilable(StatementsNode), closing_loc: Location).returns(EmbeddedStatementsNode) }
    def embedded_statements_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), statements: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    # Create a new EmbeddedVariableNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, operator_loc: Location, variable: T.any(InstanceVariableReadNode, ClassVariableReadNode, GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode)).returns(EmbeddedVariableNode) }
    def embedded_variable_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), operator_loc: T.unsafe(nil), variable: T.unsafe(nil)); end

    # Create a new EnsureNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, ensure_keyword_loc: Location, statements: T.nilable(StatementsNode), end_keyword_loc: Location).returns(EnsureNode) }
    def ensure_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), ensure_keyword_loc: T.unsafe(nil), statements: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    # Create a new FalseNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).returns(FalseNode) }
    def false_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    # Create a new FindPatternNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, constant: T.nilable(T.any(ConstantPathNode, ConstantReadNode)), left: SplatNode, requireds: T::Array[Node], right: T.any(SplatNode, MissingNode), opening_loc: T.nilable(Location), closing_loc: T.nilable(Location)).returns(FindPatternNode) }
    def find_pattern_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), constant: T.unsafe(nil), left: T.unsafe(nil), requireds: T.unsafe(nil), right: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    # Create a new FlipFlopNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, left: T.nilable(Node), right: T.nilable(Node), operator_loc: Location).returns(FlipFlopNode) }
    def flip_flop_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), left: T.unsafe(nil), right: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    # Create a new FloatNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, value: Float).returns(FloatNode) }
    def float_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), value: T.unsafe(nil)); end

    # Create a new ForNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, index: T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, BackReferenceReadNode, NumberedReferenceReadNode, MissingNode), collection: Node, statements: T.nilable(StatementsNode), for_keyword_loc: Location, in_keyword_loc: Location, do_keyword_loc: T.nilable(Location), end_keyword_loc: Location).returns(ForNode) }
    def for_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), index: T.unsafe(nil), collection: T.unsafe(nil), statements: T.unsafe(nil), for_keyword_loc: T.unsafe(nil), in_keyword_loc: T.unsafe(nil), do_keyword_loc: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    # Create a new ForwardingArgumentsNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).returns(ForwardingArgumentsNode) }
    def forwarding_arguments_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    # Create a new ForwardingParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).returns(ForwardingParameterNode) }
    def forwarding_parameter_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    # Create a new ForwardingSuperNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, block: T.nilable(BlockNode)).returns(ForwardingSuperNode) }
    def forwarding_super_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), block: T.unsafe(nil)); end

    # Create a new GlobalVariableAndWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(GlobalVariableAndWriteNode) }
    def global_variable_and_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    # Create a new GlobalVariableOperatorWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, binary_operator_loc: Location, value: Node, binary_operator: Symbol).returns(GlobalVariableOperatorWriteNode) }
    def global_variable_operator_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), binary_operator_loc: T.unsafe(nil), value: T.unsafe(nil), binary_operator: T.unsafe(nil)); end

    # Create a new GlobalVariableOrWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(GlobalVariableOrWriteNode) }
    def global_variable_or_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    # Create a new GlobalVariableReadNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(GlobalVariableReadNode) }
    def global_variable_read_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    # Create a new GlobalVariableTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(GlobalVariableTargetNode) }
    def global_variable_target_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    # Create a new GlobalVariableWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, value: Node, operator_loc: Location).returns(GlobalVariableWriteNode) }
    def global_variable_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), value: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    # Create a new HashNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: Location, elements: T::Array[T.any(AssocNode, AssocSplatNode)], closing_loc: Location).returns(HashNode) }
    def hash_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), elements: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    # Create a new HashPatternNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, constant: T.nilable(T.any(ConstantPathNode, ConstantReadNode)), elements: T::Array[AssocNode], rest: T.nilable(T.any(AssocSplatNode, NoKeywordsParameterNode)), opening_loc: T.nilable(Location), closing_loc: T.nilable(Location)).returns(HashPatternNode) }
    def hash_pattern_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), constant: T.unsafe(nil), elements: T.unsafe(nil), rest: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    # Create a new IfNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, if_keyword_loc: T.nilable(Location), predicate: Node, then_keyword_loc: T.nilable(Location), statements: T.nilable(StatementsNode), subsequent: T.nilable(T.any(ElseNode, IfNode)), end_keyword_loc: T.nilable(Location)).returns(IfNode) }
    def if_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), if_keyword_loc: T.unsafe(nil), predicate: T.unsafe(nil), then_keyword_loc: T.unsafe(nil), statements: T.unsafe(nil), subsequent: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    # Create a new ImaginaryNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, numeric: T.any(FloatNode, IntegerNode, RationalNode)).returns(ImaginaryNode) }
    def imaginary_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), numeric: T.unsafe(nil)); end

    # Create a new ImplicitNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, value: T.any(LocalVariableReadNode, CallNode, ConstantReadNode, LocalVariableTargetNode)).returns(ImplicitNode) }
    def implicit_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), value: T.unsafe(nil)); end

    # Create a new ImplicitRestNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).returns(ImplicitRestNode) }
    def implicit_rest_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    # Create a new InNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, pattern: Node, statements: T.nilable(StatementsNode), in_loc: Location, then_loc: T.nilable(Location)).returns(InNode) }
    def in_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), pattern: T.unsafe(nil), statements: T.unsafe(nil), in_loc: T.unsafe(nil), then_loc: T.unsafe(nil)); end

    # Create a new IndexAndWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: T.nilable(Node), call_operator_loc: T.nilable(Location), opening_loc: Location, arguments: T.nilable(ArgumentsNode), closing_loc: Location, block: T.nilable(BlockArgumentNode), operator_loc: Location, value: Node).returns(IndexAndWriteNode) }
    def index_and_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), call_operator_loc: T.unsafe(nil), opening_loc: T.unsafe(nil), arguments: T.unsafe(nil), closing_loc: T.unsafe(nil), block: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    # Create a new IndexOperatorWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: T.nilable(Node), call_operator_loc: T.nilable(Location), opening_loc: Location, arguments: T.nilable(ArgumentsNode), closing_loc: Location, block: T.nilable(BlockArgumentNode), binary_operator: Symbol, binary_operator_loc: Location, value: Node).returns(IndexOperatorWriteNode) }
    def index_operator_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), call_operator_loc: T.unsafe(nil), opening_loc: T.unsafe(nil), arguments: T.unsafe(nil), closing_loc: T.unsafe(nil), block: T.unsafe(nil), binary_operator: T.unsafe(nil), binary_operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    # Create a new IndexOrWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: T.nilable(Node), call_operator_loc: T.nilable(Location), opening_loc: Location, arguments: T.nilable(ArgumentsNode), closing_loc: Location, block: T.nilable(BlockArgumentNode), operator_loc: Location, value: Node).returns(IndexOrWriteNode) }
    def index_or_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), call_operator_loc: T.unsafe(nil), opening_loc: T.unsafe(nil), arguments: T.unsafe(nil), closing_loc: T.unsafe(nil), block: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    # Create a new IndexTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, receiver: Node, opening_loc: Location, arguments: T.nilable(ArgumentsNode), closing_loc: Location, block: T.nilable(BlockArgumentNode)).returns(IndexTargetNode) }
    def index_target_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), receiver: T.unsafe(nil), opening_loc: T.unsafe(nil), arguments: T.unsafe(nil), closing_loc: T.unsafe(nil), block: T.unsafe(nil)); end

    # Create a new InstanceVariableAndWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(InstanceVariableAndWriteNode) }
    def instance_variable_and_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    # Create a new InstanceVariableOperatorWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, binary_operator_loc: Location, value: Node, binary_operator: Symbol).returns(InstanceVariableOperatorWriteNode) }
    def instance_variable_operator_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), binary_operator_loc: T.unsafe(nil), value: T.unsafe(nil), binary_operator: T.unsafe(nil)); end

    # Create a new InstanceVariableOrWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(InstanceVariableOrWriteNode) }
    def instance_variable_or_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    # Create a new InstanceVariableReadNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(InstanceVariableReadNode) }
    def instance_variable_read_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    # Create a new InstanceVariableTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(InstanceVariableTargetNode) }
    def instance_variable_target_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    # Create a new InstanceVariableWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, value: Node, operator_loc: Location).returns(InstanceVariableWriteNode) }
    def instance_variable_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), value: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    # Create a new IntegerNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, value: Integer).returns(IntegerNode) }
    def integer_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), value: T.unsafe(nil)); end

    # Create a new InterpolatedMatchLastLineNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: Location, parts: T::Array[T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)], closing_loc: Location).returns(InterpolatedMatchLastLineNode) }
    def interpolated_match_last_line_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), parts: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    # Create a new InterpolatedRegularExpressionNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: Location, parts: T::Array[T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)], closing_loc: Location).returns(InterpolatedRegularExpressionNode) }
    def interpolated_regular_expression_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), parts: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    # Create a new InterpolatedStringNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: T.nilable(Location), parts: T::Array[T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode, InterpolatedStringNode, XStringNode, InterpolatedXStringNode, SymbolNode, InterpolatedSymbolNode)], closing_loc: T.nilable(Location)).returns(InterpolatedStringNode) }
    def interpolated_string_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), parts: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    # Create a new InterpolatedSymbolNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: T.nilable(Location), parts: T::Array[T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)], closing_loc: T.nilable(Location)).returns(InterpolatedSymbolNode) }
    def interpolated_symbol_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), parts: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    # Create a new InterpolatedXStringNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: Location, parts: T::Array[T.any(StringNode, EmbeddedStatementsNode, EmbeddedVariableNode)], closing_loc: Location).returns(InterpolatedXStringNode) }
    def interpolated_x_string_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), parts: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    # Create a new ItLocalVariableReadNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).returns(ItLocalVariableReadNode) }
    def it_local_variable_read_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    # Create a new ItParametersNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).returns(ItParametersNode) }
    def it_parameters_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    # Create a new KeywordHashNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, elements: T::Array[T.any(AssocNode, AssocSplatNode)]).returns(KeywordHashNode) }
    def keyword_hash_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), elements: T.unsafe(nil)); end

    # Create a new KeywordRestParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: T.nilable(Symbol), name_loc: T.nilable(Location), operator_loc: Location).returns(KeywordRestParameterNode) }
    def keyword_rest_parameter_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    # Create a new LambdaNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], operator_loc: Location, opening_loc: Location, closing_loc: Location, parameters: T.nilable(T.any(BlockParametersNode, NumberedParametersNode, ItParametersNode)), body: T.nilable(T.any(StatementsNode, BeginNode))).returns(LambdaNode) }
    def lambda_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), locals: T.unsafe(nil), operator_loc: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil), parameters: T.unsafe(nil), body: T.unsafe(nil)); end

    # Create a new LocalVariableAndWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name_loc: Location, operator_loc: Location, value: Node, name: Symbol, depth: Integer).returns(LocalVariableAndWriteNode) }
    def local_variable_and_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil), name: T.unsafe(nil), depth: T.unsafe(nil)); end

    # Create a new LocalVariableOperatorWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name_loc: Location, binary_operator_loc: Location, value: Node, name: Symbol, binary_operator: Symbol, depth: Integer).returns(LocalVariableOperatorWriteNode) }
    def local_variable_operator_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name_loc: T.unsafe(nil), binary_operator_loc: T.unsafe(nil), value: T.unsafe(nil), name: T.unsafe(nil), binary_operator: T.unsafe(nil), depth: T.unsafe(nil)); end

    # Create a new LocalVariableOrWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name_loc: Location, operator_loc: Location, value: Node, name: Symbol, depth: Integer).returns(LocalVariableOrWriteNode) }
    def local_variable_or_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil), name: T.unsafe(nil), depth: T.unsafe(nil)); end

    # Create a new LocalVariableReadNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, depth: Integer).returns(LocalVariableReadNode) }
    def local_variable_read_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), depth: T.unsafe(nil)); end

    # Create a new LocalVariableTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, depth: Integer).returns(LocalVariableTargetNode) }
    def local_variable_target_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), depth: T.unsafe(nil)); end

    # Create a new LocalVariableWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, depth: Integer, name_loc: Location, value: Node, operator_loc: Location).returns(LocalVariableWriteNode) }
    def local_variable_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), depth: T.unsafe(nil), name_loc: T.unsafe(nil), value: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    # Create a new MatchLastLineNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: Location, content_loc: Location, closing_loc: Location, unescaped: String).returns(MatchLastLineNode) }
    def match_last_line_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), content_loc: T.unsafe(nil), closing_loc: T.unsafe(nil), unescaped: T.unsafe(nil)); end

    # Create a new MatchPredicateNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, value: Node, pattern: Node, operator_loc: Location).returns(MatchPredicateNode) }
    def match_predicate_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), value: T.unsafe(nil), pattern: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    # Create a new MatchRequiredNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, value: Node, pattern: Node, operator_loc: Location).returns(MatchRequiredNode) }
    def match_required_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), value: T.unsafe(nil), pattern: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    # Create a new MatchWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, call: CallNode, targets: T::Array[LocalVariableTargetNode]).returns(MatchWriteNode) }
    def match_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), call: T.unsafe(nil), targets: T.unsafe(nil)); end

    # Create a new MissingNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).returns(MissingNode) }
    def missing_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    # Create a new ModuleNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], module_keyword_loc: Location, constant_path: T.any(ConstantReadNode, ConstantPathNode, MissingNode), body: T.nilable(T.any(StatementsNode, BeginNode)), end_keyword_loc: Location, name: Symbol).returns(ModuleNode) }
    def module_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), locals: T.unsafe(nil), module_keyword_loc: T.unsafe(nil), constant_path: T.unsafe(nil), body: T.unsafe(nil), end_keyword_loc: T.unsafe(nil), name: T.unsafe(nil)); end

    # Create a new MultiTargetNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, lefts: T::Array[T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, RequiredParameterNode, BackReferenceReadNode, NumberedReferenceReadNode)], rest: T.nilable(T.any(ImplicitRestNode, SplatNode)), rights: T::Array[T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, RequiredParameterNode, BackReferenceReadNode, NumberedReferenceReadNode)], lparen_loc: T.nilable(Location), rparen_loc: T.nilable(Location)).returns(MultiTargetNode) }
    def multi_target_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), lefts: T.unsafe(nil), rest: T.unsafe(nil), rights: T.unsafe(nil), lparen_loc: T.unsafe(nil), rparen_loc: T.unsafe(nil)); end

    # Create a new MultiWriteNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, lefts: T::Array[T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, BackReferenceReadNode, NumberedReferenceReadNode)], rest: T.nilable(T.any(ImplicitRestNode, SplatNode)), rights: T::Array[T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, MultiTargetNode, BackReferenceReadNode, NumberedReferenceReadNode)], lparen_loc: T.nilable(Location), rparen_loc: T.nilable(Location), operator_loc: Location, value: Node).returns(MultiWriteNode) }
    def multi_write_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), lefts: T.unsafe(nil), rest: T.unsafe(nil), rights: T.unsafe(nil), lparen_loc: T.unsafe(nil), rparen_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    # Create a new NextNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, arguments: T.nilable(ArgumentsNode), keyword_loc: Location).returns(NextNode) }
    def next_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), arguments: T.unsafe(nil), keyword_loc: T.unsafe(nil)); end

    # Create a new NilNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).returns(NilNode) }
    def nil_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    # Create a new NoBlockParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, operator_loc: Location, keyword_loc: Location).returns(NoBlockParameterNode) }
    def no_block_parameter_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), operator_loc: T.unsafe(nil), keyword_loc: T.unsafe(nil)); end

    # Create a new NoKeywordsParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, operator_loc: Location, keyword_loc: Location).returns(NoKeywordsParameterNode) }
    def no_keywords_parameter_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), operator_loc: T.unsafe(nil), keyword_loc: T.unsafe(nil)); end

    # Create a new NumberedParametersNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, maximum: Integer).returns(NumberedParametersNode) }
    def numbered_parameters_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), maximum: T.unsafe(nil)); end

    # Create a new NumberedReferenceReadNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, number: Integer).returns(NumberedReferenceReadNode) }
    def numbered_reference_read_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), number: T.unsafe(nil)); end

    # Create a new OptionalKeywordParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, value: Node).returns(OptionalKeywordParameterNode) }
    def optional_keyword_parameter_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    # Create a new OptionalParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location, operator_loc: Location, value: Node).returns(OptionalParameterNode) }
    def optional_parameter_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), value: T.unsafe(nil)); end

    # Create a new OrNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, left: Node, right: Node, operator_loc: Location).returns(OrNode) }
    def or_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), left: T.unsafe(nil), right: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    # Create a new ParametersNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, requireds: T::Array[T.any(RequiredParameterNode, MultiTargetNode)], optionals: T::Array[OptionalParameterNode], rest: T.nilable(T.any(RestParameterNode, ImplicitRestNode)), posts: T::Array[T.any(RequiredParameterNode, MultiTargetNode, KeywordRestParameterNode, NoKeywordsParameterNode, ForwardingParameterNode, BlockParameterNode, NoBlockParameterNode)], keywords: T::Array[T.any(RequiredKeywordParameterNode, OptionalKeywordParameterNode)], keyword_rest: T.nilable(T.any(KeywordRestParameterNode, ForwardingParameterNode, NoKeywordsParameterNode)), block: T.nilable(T.any(BlockParameterNode, NoBlockParameterNode))).returns(ParametersNode) }
    def parameters_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), requireds: T.unsafe(nil), optionals: T.unsafe(nil), rest: T.unsafe(nil), posts: T.unsafe(nil), keywords: T.unsafe(nil), keyword_rest: T.unsafe(nil), block: T.unsafe(nil)); end

    # Create a new ParenthesesNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, body: T.nilable(Node), opening_loc: Location, closing_loc: Location).returns(ParenthesesNode) }
    def parentheses_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), body: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    # Create a new PinnedExpressionNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, expression: Node, operator_loc: Location, lparen_loc: Location, rparen_loc: Location).returns(PinnedExpressionNode) }
    def pinned_expression_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), expression: T.unsafe(nil), operator_loc: T.unsafe(nil), lparen_loc: T.unsafe(nil), rparen_loc: T.unsafe(nil)); end

    # Create a new PinnedVariableNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, variable: T.any(LocalVariableReadNode, InstanceVariableReadNode, ClassVariableReadNode, GlobalVariableReadNode, BackReferenceReadNode, NumberedReferenceReadNode, ItLocalVariableReadNode, MissingNode), operator_loc: Location).returns(PinnedVariableNode) }
    def pinned_variable_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), variable: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    # Create a new PostExecutionNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, statements: T.nilable(StatementsNode), keyword_loc: Location, opening_loc: Location, closing_loc: Location).returns(PostExecutionNode) }
    def post_execution_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), statements: T.unsafe(nil), keyword_loc: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    # Create a new PreExecutionNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, statements: T.nilable(StatementsNode), keyword_loc: Location, opening_loc: Location, closing_loc: Location).returns(PreExecutionNode) }
    def pre_execution_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), statements: T.unsafe(nil), keyword_loc: T.unsafe(nil), opening_loc: T.unsafe(nil), closing_loc: T.unsafe(nil)); end

    # Create a new ProgramNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], statements: StatementsNode).returns(ProgramNode) }
    def program_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), locals: T.unsafe(nil), statements: T.unsafe(nil)); end

    # Create a new RangeNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, left: T.nilable(Node), right: T.nilable(Node), operator_loc: Location).returns(RangeNode) }
    def range_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), left: T.unsafe(nil), right: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    # Create a new RationalNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, numerator: Integer, denominator: Integer).returns(RationalNode) }
    def rational_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), numerator: T.unsafe(nil), denominator: T.unsafe(nil)); end

    # Create a new RedoNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).returns(RedoNode) }
    def redo_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    # Create a new RegularExpressionNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: Location, content_loc: Location, closing_loc: Location, unescaped: String).returns(RegularExpressionNode) }
    def regular_expression_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), content_loc: T.unsafe(nil), closing_loc: T.unsafe(nil), unescaped: T.unsafe(nil)); end

    # Create a new RequiredKeywordParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol, name_loc: Location).returns(RequiredKeywordParameterNode) }
    def required_keyword_parameter_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil)); end

    # Create a new RequiredParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: Symbol).returns(RequiredParameterNode) }
    def required_parameter_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil)); end

    # Create a new RescueModifierNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, expression: Node, keyword_loc: Location, rescue_expression: Node).returns(RescueModifierNode) }
    def rescue_modifier_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), expression: T.unsafe(nil), keyword_loc: T.unsafe(nil), rescue_expression: T.unsafe(nil)); end

    # Create a new RescueNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, exceptions: T::Array[Node], operator_loc: T.nilable(Location), reference: T.nilable(T.any(LocalVariableTargetNode, InstanceVariableTargetNode, ClassVariableTargetNode, GlobalVariableTargetNode, ConstantTargetNode, ConstantPathTargetNode, CallTargetNode, IndexTargetNode, BackReferenceReadNode, NumberedReferenceReadNode, MissingNode)), then_keyword_loc: T.nilable(Location), statements: T.nilable(StatementsNode), subsequent: T.nilable(RescueNode)).returns(RescueNode) }
    def rescue_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), keyword_loc: T.unsafe(nil), exceptions: T.unsafe(nil), operator_loc: T.unsafe(nil), reference: T.unsafe(nil), then_keyword_loc: T.unsafe(nil), statements: T.unsafe(nil), subsequent: T.unsafe(nil)); end

    # Create a new RestParameterNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, name: T.nilable(Symbol), name_loc: T.nilable(Location), operator_loc: Location).returns(RestParameterNode) }
    def rest_parameter_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), name: T.unsafe(nil), name_loc: T.unsafe(nil), operator_loc: T.unsafe(nil)); end

    # Create a new RetryNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).returns(RetryNode) }
    def retry_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    # Create a new ReturnNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, arguments: T.nilable(ArgumentsNode)).returns(ReturnNode) }
    def return_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), keyword_loc: T.unsafe(nil), arguments: T.unsafe(nil)); end

    # Create a new SelfNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).returns(SelfNode) }
    def self_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    # Create a new ShareableConstantNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, write: T.any(ConstantWriteNode, ConstantAndWriteNode, ConstantOrWriteNode, ConstantOperatorWriteNode, ConstantPathWriteNode, ConstantPathAndWriteNode, ConstantPathOrWriteNode, ConstantPathOperatorWriteNode)).returns(ShareableConstantNode) }
    def shareable_constant_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), write: T.unsafe(nil)); end

    # Create a new SingletonClassNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, locals: T::Array[Symbol], class_keyword_loc: Location, operator_loc: Location, expression: Node, body: T.nilable(T.any(StatementsNode, BeginNode)), end_keyword_loc: Location).returns(SingletonClassNode) }
    def singleton_class_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), locals: T.unsafe(nil), class_keyword_loc: T.unsafe(nil), operator_loc: T.unsafe(nil), expression: T.unsafe(nil), body: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    # Create a new SourceEncodingNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).returns(SourceEncodingNode) }
    def source_encoding_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    # Create a new SourceFileNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, filepath: String).returns(SourceFileNode) }
    def source_file_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), filepath: T.unsafe(nil)); end

    # Create a new SourceLineNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).returns(SourceLineNode) }
    def source_line_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    # Create a new SplatNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, operator_loc: Location, expression: T.nilable(Node)).returns(SplatNode) }
    def splat_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), operator_loc: T.unsafe(nil), expression: T.unsafe(nil)); end

    # Create a new StatementsNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, body: T::Array[Node]).returns(StatementsNode) }
    def statements_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), body: T.unsafe(nil)); end

    # Create a new StringNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: T.nilable(Location), content_loc: Location, closing_loc: T.nilable(Location), unescaped: String).returns(StringNode) }
    def string_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), content_loc: T.unsafe(nil), closing_loc: T.unsafe(nil), unescaped: T.unsafe(nil)); end

    # Create a new SuperNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, lparen_loc: T.nilable(Location), arguments: T.nilable(ArgumentsNode), rparen_loc: T.nilable(Location), block: T.nilable(T.any(BlockNode, BlockArgumentNode))).returns(SuperNode) }
    def super_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), keyword_loc: T.unsafe(nil), lparen_loc: T.unsafe(nil), arguments: T.unsafe(nil), rparen_loc: T.unsafe(nil), block: T.unsafe(nil)); end

    # Create a new SymbolNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: T.nilable(Location), value_loc: T.nilable(Location), closing_loc: T.nilable(Location), unescaped: String).returns(SymbolNode) }
    def symbol_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), value_loc: T.unsafe(nil), closing_loc: T.unsafe(nil), unescaped: T.unsafe(nil)); end

    # Create a new TrueNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer).returns(TrueNode) }
    def true_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil)); end

    # Create a new UndefNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, names: T::Array[T.any(SymbolNode, InterpolatedSymbolNode)], keyword_loc: Location).returns(UndefNode) }
    def undef_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), names: T.unsafe(nil), keyword_loc: T.unsafe(nil)); end

    # Create a new UnlessNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, predicate: Node, then_keyword_loc: T.nilable(Location), statements: T.nilable(StatementsNode), else_clause: T.nilable(ElseNode), end_keyword_loc: T.nilable(Location)).returns(UnlessNode) }
    def unless_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), keyword_loc: T.unsafe(nil), predicate: T.unsafe(nil), then_keyword_loc: T.unsafe(nil), statements: T.unsafe(nil), else_clause: T.unsafe(nil), end_keyword_loc: T.unsafe(nil)); end

    # Create a new UntilNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, do_keyword_loc: T.nilable(Location), closing_loc: T.nilable(Location), predicate: Node, statements: T.nilable(StatementsNode)).returns(UntilNode) }
    def until_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), keyword_loc: T.unsafe(nil), do_keyword_loc: T.unsafe(nil), closing_loc: T.unsafe(nil), predicate: T.unsafe(nil), statements: T.unsafe(nil)); end

    # Create a new WhenNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, conditions: T::Array[Node], then_keyword_loc: T.nilable(Location), statements: T.nilable(StatementsNode)).returns(WhenNode) }
    def when_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), keyword_loc: T.unsafe(nil), conditions: T.unsafe(nil), then_keyword_loc: T.unsafe(nil), statements: T.unsafe(nil)); end

    # Create a new WhileNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, do_keyword_loc: T.nilable(Location), closing_loc: T.nilable(Location), predicate: Node, statements: T.nilable(StatementsNode)).returns(WhileNode) }
    def while_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), keyword_loc: T.unsafe(nil), do_keyword_loc: T.unsafe(nil), closing_loc: T.unsafe(nil), predicate: T.unsafe(nil), statements: T.unsafe(nil)); end

    # Create a new XStringNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, opening_loc: Location, content_loc: Location, closing_loc: Location, unescaped: String).returns(XStringNode) }
    def x_string_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), opening_loc: T.unsafe(nil), content_loc: T.unsafe(nil), closing_loc: T.unsafe(nil), unescaped: T.unsafe(nil)); end

    # Create a new YieldNode node.
    sig { params(source: Source, node_id: Integer, location: Location, flags: Integer, keyword_loc: Location, lparen_loc: T.nilable(Location), arguments: T.nilable(ArgumentsNode), rparen_loc: T.nilable(Location)).returns(YieldNode) }
    def yield_node(source: T.unsafe(nil), node_id: T.unsafe(nil), location: T.unsafe(nil), flags: T.unsafe(nil), keyword_loc: T.unsafe(nil), lparen_loc: T.unsafe(nil), arguments: T.unsafe(nil), rparen_loc: T.unsafe(nil)); end

    # Retrieve the value of one of the ArgumentsNodeFlags flags.
    sig { params(name: Symbol).returns(Integer) }
    def arguments_node_flag(name); end

    # Retrieve the value of one of the ArrayNodeFlags flags.
    sig { params(name: Symbol).returns(Integer) }
    def array_node_flag(name); end

    # Retrieve the value of one of the CallNodeFlags flags.
    sig { params(name: Symbol).returns(Integer) }
    def call_node_flag(name); end

    # Retrieve the value of one of the EncodingFlags flags.
    sig { params(name: Symbol).returns(Integer) }
    def encoding_flag(name); end

    # Retrieve the value of one of the IntegerBaseFlags flags.
    sig { params(name: Symbol).returns(Integer) }
    def integer_base_flag(name); end

    # Retrieve the value of one of the InterpolatedStringNodeFlags flags.
    sig { params(name: Symbol).returns(Integer) }
    def interpolated_string_node_flag(name); end

    # Retrieve the value of one of the KeywordHashNodeFlags flags.
    sig { params(name: Symbol).returns(Integer) }
    def keyword_hash_node_flag(name); end

    # Retrieve the value of one of the LoopFlags flags.
    sig { params(name: Symbol).returns(Integer) }
    def loop_flag(name); end

    # Retrieve the value of one of the ParameterFlags flags.
    sig { params(name: Symbol).returns(Integer) }
    def parameter_flag(name); end

    # Retrieve the value of one of the ParenthesesNodeFlags flags.
    sig { params(name: Symbol).returns(Integer) }
    def parentheses_node_flag(name); end

    # Retrieve the value of one of the RangeFlags flags.
    sig { params(name: Symbol).returns(Integer) }
    def range_flag(name); end

    # Retrieve the value of one of the RegularExpressionFlags flags.
    sig { params(name: Symbol).returns(Integer) }
    def regular_expression_flag(name); end

    # Retrieve the value of one of the ShareableConstantNodeFlags flags.
    sig { params(name: Symbol).returns(Integer) }
    def shareable_constant_node_flag(name); end

    # Retrieve the value of one of the StringFlags flags.
    sig { params(name: Symbol).returns(Integer) }
    def string_flag(name); end

    # Retrieve the value of one of the SymbolFlags flags.
    sig { params(name: Symbol).returns(Integer) }
    def symbol_flag(name); end

    # The default source object that gets attached to nodes and locations if no
    # source is specified.
    sig { returns(Source) }
    private def default_source; end

    # The default location object that gets attached to nodes if no location is
    # specified, which uses the given source.
    sig { returns(Location) }
    private def default_location; end

    # The default node that gets attached to nodes if no node is specified for a
    # required node field.
    sig { params(source: Source, location: Location).returns(Node) }
    private def default_node(source, location); end
  end
end
