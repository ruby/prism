# typed: true

module Prism
  # This visitor provides the ability to call Node#to_dot, which converts a
  # subtree into a graphviz dot graph.
  class DotVisitor < Visitor
    class Field
      sig { returns(String) }
      attr_reader :name

      sig { returns(T.nilable(String)) }
      attr_reader :value

      sig { returns(T::Boolean) }
      attr_reader :port

      sig { params(name: String, value: T.nilable(String), port: T::Boolean).void }
      def initialize(name, value, port); end

      sig { returns(String) }
      def to_dot; end
    end

    class Table
      sig { returns(String) }
      attr_reader :name

      sig { returns(T::Array[Field]) }
      attr_reader :fields

      sig { params(name: String).void }
      def initialize(name); end

      sig { params(name: String, value: T.nilable(String), port: T::Boolean).void }
      def field(name, value = T.unsafe(nil), port: T.unsafe(nil)); end

      sig { returns(String) }
      def to_dot; end
    end

    class Digraph
      sig { returns(T::Array[String]) }
      attr_reader :nodes

      sig { returns(T::Array[String]) }
      attr_reader :waypoints

      sig { returns(T::Array[String]) }
      attr_reader :edges

      sig { void }
      def initialize; end

      sig { params(value: String).void }
      def node(value); end

      sig { params(value: String).void }
      def waypoint(value); end

      sig { params(value: String).void }
      def edge(value); end

      sig { returns(String) }
      def to_dot; end
    end

    # The digraph that is being built.
    sig { returns(Digraph) }
    attr_reader :digraph

    # Initialize a new dot visitor.
    sig { void }
    def initialize; end

    # Convert this visitor into a graphviz dot graph string.
    sig { returns(String) }
    def to_dot; end

    sig { params(arg0: AliasGlobalVariableNode).void }
    def visit_alias_global_variable_node(arg0); end

    sig { params(arg0: AliasMethodNode).void }
    def visit_alias_method_node(arg0); end

    sig { params(arg0: AlternationPatternNode).void }
    def visit_alternation_pattern_node(arg0); end

    sig { params(arg0: AndNode).void }
    def visit_and_node(arg0); end

    sig { params(arg0: ArgumentsNode).void }
    def visit_arguments_node(arg0); end

    sig { params(arg0: ArrayNode).void }
    def visit_array_node(arg0); end

    sig { params(arg0: ArrayPatternNode).void }
    def visit_array_pattern_node(arg0); end

    sig { params(arg0: AssocNode).void }
    def visit_assoc_node(arg0); end

    sig { params(arg0: AssocSplatNode).void }
    def visit_assoc_splat_node(arg0); end

    sig { params(arg0: BackReferenceReadNode).void }
    def visit_back_reference_read_node(arg0); end

    sig { params(arg0: BeginNode).void }
    def visit_begin_node(arg0); end

    sig { params(arg0: BlockArgumentNode).void }
    def visit_block_argument_node(arg0); end

    sig { params(arg0: BlockLocalVariableNode).void }
    def visit_block_local_variable_node(arg0); end

    sig { params(arg0: BlockNode).void }
    def visit_block_node(arg0); end

    sig { params(arg0: BlockParameterNode).void }
    def visit_block_parameter_node(arg0); end

    sig { params(arg0: BlockParametersNode).void }
    def visit_block_parameters_node(arg0); end

    sig { params(arg0: BreakNode).void }
    def visit_break_node(arg0); end

    sig { params(arg0: CallAndWriteNode).void }
    def visit_call_and_write_node(arg0); end

    sig { params(arg0: CallNode).void }
    def visit_call_node(arg0); end

    sig { params(arg0: CallOperatorWriteNode).void }
    def visit_call_operator_write_node(arg0); end

    sig { params(arg0: CallOrWriteNode).void }
    def visit_call_or_write_node(arg0); end

    sig { params(arg0: CallTargetNode).void }
    def visit_call_target_node(arg0); end

    sig { params(arg0: CapturePatternNode).void }
    def visit_capture_pattern_node(arg0); end

    sig { params(arg0: CaseMatchNode).void }
    def visit_case_match_node(arg0); end

    sig { params(arg0: CaseNode).void }
    def visit_case_node(arg0); end

    sig { params(arg0: ClassNode).void }
    def visit_class_node(arg0); end

    sig { params(arg0: ClassVariableAndWriteNode).void }
    def visit_class_variable_and_write_node(arg0); end

    sig { params(arg0: ClassVariableOperatorWriteNode).void }
    def visit_class_variable_operator_write_node(arg0); end

    sig { params(arg0: ClassVariableOrWriteNode).void }
    def visit_class_variable_or_write_node(arg0); end

    sig { params(arg0: ClassVariableReadNode).void }
    def visit_class_variable_read_node(arg0); end

    sig { params(arg0: ClassVariableTargetNode).void }
    def visit_class_variable_target_node(arg0); end

    sig { params(arg0: ClassVariableWriteNode).void }
    def visit_class_variable_write_node(arg0); end

    sig { params(arg0: ConstantAndWriteNode).void }
    def visit_constant_and_write_node(arg0); end

    sig { params(arg0: ConstantOperatorWriteNode).void }
    def visit_constant_operator_write_node(arg0); end

    sig { params(arg0: ConstantOrWriteNode).void }
    def visit_constant_or_write_node(arg0); end

    sig { params(arg0: ConstantPathAndWriteNode).void }
    def visit_constant_path_and_write_node(arg0); end

    sig { params(arg0: ConstantPathNode).void }
    def visit_constant_path_node(arg0); end

    sig { params(arg0: ConstantPathOperatorWriteNode).void }
    def visit_constant_path_operator_write_node(arg0); end

    sig { params(arg0: ConstantPathOrWriteNode).void }
    def visit_constant_path_or_write_node(arg0); end

    sig { params(arg0: ConstantPathTargetNode).void }
    def visit_constant_path_target_node(arg0); end

    sig { params(arg0: ConstantPathWriteNode).void }
    def visit_constant_path_write_node(arg0); end

    sig { params(arg0: ConstantReadNode).void }
    def visit_constant_read_node(arg0); end

    sig { params(arg0: ConstantTargetNode).void }
    def visit_constant_target_node(arg0); end

    sig { params(arg0: ConstantWriteNode).void }
    def visit_constant_write_node(arg0); end

    sig { params(arg0: DefNode).void }
    def visit_def_node(arg0); end

    sig { params(arg0: DefinedNode).void }
    def visit_defined_node(arg0); end

    sig { params(arg0: ElseNode).void }
    def visit_else_node(arg0); end

    sig { params(arg0: EmbeddedStatementsNode).void }
    def visit_embedded_statements_node(arg0); end

    sig { params(arg0: EmbeddedVariableNode).void }
    def visit_embedded_variable_node(arg0); end

    sig { params(arg0: EnsureNode).void }
    def visit_ensure_node(arg0); end

    sig { params(arg0: FalseNode).void }
    def visit_false_node(arg0); end

    sig { params(arg0: FindPatternNode).void }
    def visit_find_pattern_node(arg0); end

    sig { params(arg0: FlipFlopNode).void }
    def visit_flip_flop_node(arg0); end

    sig { params(arg0: FloatNode).void }
    def visit_float_node(arg0); end

    sig { params(arg0: ForNode).void }
    def visit_for_node(arg0); end

    sig { params(arg0: ForwardingArgumentsNode).void }
    def visit_forwarding_arguments_node(arg0); end

    sig { params(arg0: ForwardingParameterNode).void }
    def visit_forwarding_parameter_node(arg0); end

    sig { params(arg0: ForwardingSuperNode).void }
    def visit_forwarding_super_node(arg0); end

    sig { params(arg0: GlobalVariableAndWriteNode).void }
    def visit_global_variable_and_write_node(arg0); end

    sig { params(arg0: GlobalVariableOperatorWriteNode).void }
    def visit_global_variable_operator_write_node(arg0); end

    sig { params(arg0: GlobalVariableOrWriteNode).void }
    def visit_global_variable_or_write_node(arg0); end

    sig { params(arg0: GlobalVariableReadNode).void }
    def visit_global_variable_read_node(arg0); end

    sig { params(arg0: GlobalVariableTargetNode).void }
    def visit_global_variable_target_node(arg0); end

    sig { params(arg0: GlobalVariableWriteNode).void }
    def visit_global_variable_write_node(arg0); end

    sig { params(arg0: HashNode).void }
    def visit_hash_node(arg0); end

    sig { params(arg0: HashPatternNode).void }
    def visit_hash_pattern_node(arg0); end

    sig { params(arg0: IfNode).void }
    def visit_if_node(arg0); end

    sig { params(arg0: ImaginaryNode).void }
    def visit_imaginary_node(arg0); end

    sig { params(arg0: ImplicitNode).void }
    def visit_implicit_node(arg0); end

    sig { params(arg0: ImplicitRestNode).void }
    def visit_implicit_rest_node(arg0); end

    sig { params(arg0: InNode).void }
    def visit_in_node(arg0); end

    sig { params(arg0: IndexAndWriteNode).void }
    def visit_index_and_write_node(arg0); end

    sig { params(arg0: IndexOperatorWriteNode).void }
    def visit_index_operator_write_node(arg0); end

    sig { params(arg0: IndexOrWriteNode).void }
    def visit_index_or_write_node(arg0); end

    sig { params(arg0: IndexTargetNode).void }
    def visit_index_target_node(arg0); end

    sig { params(arg0: InstanceVariableAndWriteNode).void }
    def visit_instance_variable_and_write_node(arg0); end

    sig { params(arg0: InstanceVariableOperatorWriteNode).void }
    def visit_instance_variable_operator_write_node(arg0); end

    sig { params(arg0: InstanceVariableOrWriteNode).void }
    def visit_instance_variable_or_write_node(arg0); end

    sig { params(arg0: InstanceVariableReadNode).void }
    def visit_instance_variable_read_node(arg0); end

    sig { params(arg0: InstanceVariableTargetNode).void }
    def visit_instance_variable_target_node(arg0); end

    sig { params(arg0: InstanceVariableWriteNode).void }
    def visit_instance_variable_write_node(arg0); end

    sig { params(arg0: IntegerNode).void }
    def visit_integer_node(arg0); end

    sig { params(arg0: InterpolatedMatchLastLineNode).void }
    def visit_interpolated_match_last_line_node(arg0); end

    sig { params(arg0: InterpolatedRegularExpressionNode).void }
    def visit_interpolated_regular_expression_node(arg0); end

    sig { params(arg0: InterpolatedStringNode).void }
    def visit_interpolated_string_node(arg0); end

    sig { params(arg0: InterpolatedSymbolNode).void }
    def visit_interpolated_symbol_node(arg0); end

    sig { params(arg0: InterpolatedXStringNode).void }
    def visit_interpolated_x_string_node(arg0); end

    sig { params(arg0: ItLocalVariableReadNode).void }
    def visit_it_local_variable_read_node(arg0); end

    sig { params(arg0: ItParametersNode).void }
    def visit_it_parameters_node(arg0); end

    sig { params(arg0: KeywordHashNode).void }
    def visit_keyword_hash_node(arg0); end

    sig { params(arg0: KeywordRestParameterNode).void }
    def visit_keyword_rest_parameter_node(arg0); end

    sig { params(arg0: LambdaNode).void }
    def visit_lambda_node(arg0); end

    sig { params(arg0: LocalVariableAndWriteNode).void }
    def visit_local_variable_and_write_node(arg0); end

    sig { params(arg0: LocalVariableOperatorWriteNode).void }
    def visit_local_variable_operator_write_node(arg0); end

    sig { params(arg0: LocalVariableOrWriteNode).void }
    def visit_local_variable_or_write_node(arg0); end

    sig { params(arg0: LocalVariableReadNode).void }
    def visit_local_variable_read_node(arg0); end

    sig { params(arg0: LocalVariableTargetNode).void }
    def visit_local_variable_target_node(arg0); end

    sig { params(arg0: LocalVariableWriteNode).void }
    def visit_local_variable_write_node(arg0); end

    sig { params(arg0: MatchLastLineNode).void }
    def visit_match_last_line_node(arg0); end

    sig { params(arg0: MatchPredicateNode).void }
    def visit_match_predicate_node(arg0); end

    sig { params(arg0: MatchRequiredNode).void }
    def visit_match_required_node(arg0); end

    sig { params(arg0: MatchWriteNode).void }
    def visit_match_write_node(arg0); end

    sig { params(arg0: MissingNode).void }
    def visit_missing_node(arg0); end

    sig { params(arg0: ModuleNode).void }
    def visit_module_node(arg0); end

    sig { params(arg0: MultiTargetNode).void }
    def visit_multi_target_node(arg0); end

    sig { params(arg0: MultiWriteNode).void }
    def visit_multi_write_node(arg0); end

    sig { params(arg0: NextNode).void }
    def visit_next_node(arg0); end

    sig { params(arg0: NilNode).void }
    def visit_nil_node(arg0); end

    sig { params(arg0: NoBlockParameterNode).void }
    def visit_no_block_parameter_node(arg0); end

    sig { params(arg0: NoKeywordsParameterNode).void }
    def visit_no_keywords_parameter_node(arg0); end

    sig { params(arg0: NumberedParametersNode).void }
    def visit_numbered_parameters_node(arg0); end

    sig { params(arg0: NumberedReferenceReadNode).void }
    def visit_numbered_reference_read_node(arg0); end

    sig { params(arg0: OptionalKeywordParameterNode).void }
    def visit_optional_keyword_parameter_node(arg0); end

    sig { params(arg0: OptionalParameterNode).void }
    def visit_optional_parameter_node(arg0); end

    sig { params(arg0: OrNode).void }
    def visit_or_node(arg0); end

    sig { params(arg0: ParametersNode).void }
    def visit_parameters_node(arg0); end

    sig { params(arg0: ParenthesesNode).void }
    def visit_parentheses_node(arg0); end

    sig { params(arg0: PinnedExpressionNode).void }
    def visit_pinned_expression_node(arg0); end

    sig { params(arg0: PinnedVariableNode).void }
    def visit_pinned_variable_node(arg0); end

    sig { params(arg0: PostExecutionNode).void }
    def visit_post_execution_node(arg0); end

    sig { params(arg0: PreExecutionNode).void }
    def visit_pre_execution_node(arg0); end

    sig { params(arg0: ProgramNode).void }
    def visit_program_node(arg0); end

    sig { params(arg0: RangeNode).void }
    def visit_range_node(arg0); end

    sig { params(arg0: RationalNode).void }
    def visit_rational_node(arg0); end

    sig { params(arg0: RedoNode).void }
    def visit_redo_node(arg0); end

    sig { params(arg0: RegularExpressionNode).void }
    def visit_regular_expression_node(arg0); end

    sig { params(arg0: RequiredKeywordParameterNode).void }
    def visit_required_keyword_parameter_node(arg0); end

    sig { params(arg0: RequiredParameterNode).void }
    def visit_required_parameter_node(arg0); end

    sig { params(arg0: RescueModifierNode).void }
    def visit_rescue_modifier_node(arg0); end

    sig { params(arg0: RescueNode).void }
    def visit_rescue_node(arg0); end

    sig { params(arg0: RestParameterNode).void }
    def visit_rest_parameter_node(arg0); end

    sig { params(arg0: RetryNode).void }
    def visit_retry_node(arg0); end

    sig { params(arg0: ReturnNode).void }
    def visit_return_node(arg0); end

    sig { params(arg0: SelfNode).void }
    def visit_self_node(arg0); end

    sig { params(arg0: ShareableConstantNode).void }
    def visit_shareable_constant_node(arg0); end

    sig { params(arg0: SingletonClassNode).void }
    def visit_singleton_class_node(arg0); end

    sig { params(arg0: SourceEncodingNode).void }
    def visit_source_encoding_node(arg0); end

    sig { params(arg0: SourceFileNode).void }
    def visit_source_file_node(arg0); end

    sig { params(arg0: SourceLineNode).void }
    def visit_source_line_node(arg0); end

    sig { params(arg0: SplatNode).void }
    def visit_splat_node(arg0); end

    sig { params(arg0: StatementsNode).void }
    def visit_statements_node(arg0); end

    sig { params(arg0: StringNode).void }
    def visit_string_node(arg0); end

    sig { params(arg0: SuperNode).void }
    def visit_super_node(arg0); end

    sig { params(arg0: SymbolNode).void }
    def visit_symbol_node(arg0); end

    sig { params(arg0: TrueNode).void }
    def visit_true_node(arg0); end

    sig { params(arg0: UndefNode).void }
    def visit_undef_node(arg0); end

    sig { params(arg0: UnlessNode).void }
    def visit_unless_node(arg0); end

    sig { params(arg0: UntilNode).void }
    def visit_until_node(arg0); end

    sig { params(arg0: WhenNode).void }
    def visit_when_node(arg0); end

    sig { params(arg0: WhileNode).void }
    def visit_while_node(arg0); end

    sig { params(arg0: XStringNode).void }
    def visit_x_string_node(arg0); end

    sig { params(arg0: YieldNode).void }
    def visit_yield_node(arg0); end

    # Generate a unique node ID for a node throughout the digraph.
    sig { params(arg0: Node).returns(String) }
    private def node_id(arg0); end

    # Inspect a location to display the start and end line and columns in bytes.
    sig { params(arg0: Location).returns(String) }
    private def location_inspect(arg0); end

    # Inspect a node that has arguments_node_flags flags to display the flags as a
    # comma-separated list.
    sig { params(node: ArgumentsNode).returns(String) }
    private def arguments_node_flags_inspect(node); end

    # Inspect a node that has array_node_flags flags to display the flags as a
    # comma-separated list.
    sig { params(node: ArrayNode).returns(String) }
    private def array_node_flags_inspect(node); end

    # Inspect a node that has call_node_flags flags to display the flags as a
    # comma-separated list.
    sig { params(node: T.any(CallAndWriteNode, CallNode, CallOperatorWriteNode, CallOrWriteNode, CallTargetNode, IndexAndWriteNode, IndexOperatorWriteNode, IndexOrWriteNode, IndexTargetNode)).returns(String) }
    private def call_node_flags_inspect(node); end

    # Inspect a node that has encoding_flags flags to display the flags as a
    # comma-separated list.
    sig { params(node: XStringNode).returns(String) }
    private def encoding_flags_inspect(node); end

    # Inspect a node that has integer_base_flags flags to display the flags as a
    # comma-separated list.
    sig { params(node: T.any(IntegerNode, RationalNode)).returns(String) }
    private def integer_base_flags_inspect(node); end

    # Inspect a node that has interpolated_string_node_flags flags to display the flags as a
    # comma-separated list.
    sig { params(node: InterpolatedStringNode).returns(String) }
    private def interpolated_string_node_flags_inspect(node); end

    # Inspect a node that has keyword_hash_node_flags flags to display the flags as a
    # comma-separated list.
    sig { params(node: KeywordHashNode).returns(String) }
    private def keyword_hash_node_flags_inspect(node); end

    # Inspect a node that has loop_flags flags to display the flags as a
    # comma-separated list.
    sig { params(node: T.any(UntilNode, WhileNode)).returns(String) }
    private def loop_flags_inspect(node); end

    # Inspect a node that has parameter_flags flags to display the flags as a
    # comma-separated list.
    sig { params(node: T.any(BlockLocalVariableNode, BlockParameterNode, KeywordRestParameterNode, OptionalKeywordParameterNode, OptionalParameterNode, RequiredKeywordParameterNode, RequiredParameterNode, RestParameterNode)).returns(String) }
    private def parameter_flags_inspect(node); end

    # Inspect a node that has parentheses_node_flags flags to display the flags as a
    # comma-separated list.
    sig { params(node: ParenthesesNode).returns(String) }
    private def parentheses_node_flags_inspect(node); end

    # Inspect a node that has range_flags flags to display the flags as a
    # comma-separated list.
    sig { params(node: T.any(FlipFlopNode, RangeNode)).returns(String) }
    private def range_flags_inspect(node); end

    # Inspect a node that has regular_expression_flags flags to display the flags as a
    # comma-separated list.
    sig { params(node: T.any(InterpolatedMatchLastLineNode, InterpolatedRegularExpressionNode, MatchLastLineNode, RegularExpressionNode)).returns(String) }
    private def regular_expression_flags_inspect(node); end

    # Inspect a node that has shareable_constant_node_flags flags to display the flags as a
    # comma-separated list.
    sig { params(node: ShareableConstantNode).returns(String) }
    private def shareable_constant_node_flags_inspect(node); end

    # Inspect a node that has string_flags flags to display the flags as a
    # comma-separated list.
    sig { params(node: T.any(SourceFileNode, StringNode)).returns(String) }
    private def string_flags_inspect(node); end

    # Inspect a node that has symbol_flags flags to display the flags as a
    # comma-separated list.
    sig { params(node: SymbolNode).returns(String) }
    private def symbol_flags_inspect(node); end
  end
end
