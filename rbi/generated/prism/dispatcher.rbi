# typed: true

module Prism
  # The dispatcher class fires events for nodes that are found while walking an
  # AST to all registered listeners. It's useful for performing different types
  # of analysis on the AST while only having to walk the tree once.
  #
  # To use the dispatcher, you would first instantiate it and register listeners
  # for the events you're interested in:
  #
  #     class OctalListener
  #       def on_integer_node_enter(node)
  #         if node.octal? && !node.slice.start_with?("0o")
  #           warn("Octal integers should be written with the 0o prefix")
  #         end
  #       end
  #     end
  #
  #     listener = OctalListener.new
  #     dispatcher = Prism::Dispatcher.new
  #     dispatcher.register(listener, :on_integer_node_enter)
  #
  # Then, you can walk any number of trees and dispatch events to the listeners:
  #
  #     result = Prism.parse("001 + 002 + 003")
  #     dispatcher.dispatch(result.value)
  #
  # Optionally, you can also use `#dispatch_once` to dispatch enter and leave
  # events for a single node without recursing further down the tree. This can
  # be useful in circumstances where you want to reuse the listeners you already
  # have registers but want to stop walking the tree at a certain point.
  #
  #     integer = result.value.statements.body.first.receiver.receiver
  #     dispatcher.dispatch_once(integer)
  class Dispatcher < Visitor
    # A hash mapping event names to arrays of listeners that should be notified
    # when that event is fired.
    sig { returns(T::Hash[Symbol, T::Array[T.untyped]]) }
    attr_reader :listeners

    # Initialize a new dispatcher.
    sig { void }
    def initialize; end

    # Register a listener for one or more events.
    sig { params(arg0: T.untyped, args: Symbol).void }
    def register(arg0, *args); end

    # Register all public methods of a listener that match the pattern
    # `on_<node_name>_(enter|leave)`.
    sig { params(arg0: T.untyped).void }
    def register_public_methods(arg0); end

    # Register a listener for the given events.
    sig { params(arg0: T.untyped, arg1: T::Array[Symbol]).void }
    def register_events(arg0, arg1); end

    # Dispatches a single event for `node` to all registered listeners.
    sig { params(node: Node).void }
    def dispatch_once(node); end

    sig { params(node: AliasGlobalVariableNode).void }
    def visit_alias_global_variable_node(node); end

    sig { params(node: AliasMethodNode).void }
    def visit_alias_method_node(node); end

    sig { params(node: AlternationPatternNode).void }
    def visit_alternation_pattern_node(node); end

    sig { params(node: AndNode).void }
    def visit_and_node(node); end

    sig { params(node: ArgumentsNode).void }
    def visit_arguments_node(node); end

    sig { params(node: ArrayNode).void }
    def visit_array_node(node); end

    sig { params(node: ArrayPatternNode).void }
    def visit_array_pattern_node(node); end

    sig { params(node: AssocNode).void }
    def visit_assoc_node(node); end

    sig { params(node: AssocSplatNode).void }
    def visit_assoc_splat_node(node); end

    sig { params(node: BackReferenceReadNode).void }
    def visit_back_reference_read_node(node); end

    sig { params(node: BeginNode).void }
    def visit_begin_node(node); end

    sig { params(node: BlockArgumentNode).void }
    def visit_block_argument_node(node); end

    sig { params(node: BlockLocalVariableNode).void }
    def visit_block_local_variable_node(node); end

    sig { params(node: BlockNode).void }
    def visit_block_node(node); end

    sig { params(node: BlockParameterNode).void }
    def visit_block_parameter_node(node); end

    sig { params(node: BlockParametersNode).void }
    def visit_block_parameters_node(node); end

    sig { params(node: BreakNode).void }
    def visit_break_node(node); end

    sig { params(node: CallAndWriteNode).void }
    def visit_call_and_write_node(node); end

    sig { params(node: CallNode).void }
    def visit_call_node(node); end

    sig { params(node: CallOperatorWriteNode).void }
    def visit_call_operator_write_node(node); end

    sig { params(node: CallOrWriteNode).void }
    def visit_call_or_write_node(node); end

    sig { params(node: CallTargetNode).void }
    def visit_call_target_node(node); end

    sig { params(node: CapturePatternNode).void }
    def visit_capture_pattern_node(node); end

    sig { params(node: CaseMatchNode).void }
    def visit_case_match_node(node); end

    sig { params(node: CaseNode).void }
    def visit_case_node(node); end

    sig { params(node: ClassNode).void }
    def visit_class_node(node); end

    sig { params(node: ClassVariableAndWriteNode).void }
    def visit_class_variable_and_write_node(node); end

    sig { params(node: ClassVariableOperatorWriteNode).void }
    def visit_class_variable_operator_write_node(node); end

    sig { params(node: ClassVariableOrWriteNode).void }
    def visit_class_variable_or_write_node(node); end

    sig { params(node: ClassVariableReadNode).void }
    def visit_class_variable_read_node(node); end

    sig { params(node: ClassVariableTargetNode).void }
    def visit_class_variable_target_node(node); end

    sig { params(node: ClassVariableWriteNode).void }
    def visit_class_variable_write_node(node); end

    sig { params(node: ConstantAndWriteNode).void }
    def visit_constant_and_write_node(node); end

    sig { params(node: ConstantOperatorWriteNode).void }
    def visit_constant_operator_write_node(node); end

    sig { params(node: ConstantOrWriteNode).void }
    def visit_constant_or_write_node(node); end

    sig { params(node: ConstantPathAndWriteNode).void }
    def visit_constant_path_and_write_node(node); end

    sig { params(node: ConstantPathNode).void }
    def visit_constant_path_node(node); end

    sig { params(node: ConstantPathOperatorWriteNode).void }
    def visit_constant_path_operator_write_node(node); end

    sig { params(node: ConstantPathOrWriteNode).void }
    def visit_constant_path_or_write_node(node); end

    sig { params(node: ConstantPathTargetNode).void }
    def visit_constant_path_target_node(node); end

    sig { params(node: ConstantPathWriteNode).void }
    def visit_constant_path_write_node(node); end

    sig { params(node: ConstantReadNode).void }
    def visit_constant_read_node(node); end

    sig { params(node: ConstantTargetNode).void }
    def visit_constant_target_node(node); end

    sig { params(node: ConstantWriteNode).void }
    def visit_constant_write_node(node); end

    sig { params(node: DefNode).void }
    def visit_def_node(node); end

    sig { params(node: DefinedNode).void }
    def visit_defined_node(node); end

    sig { params(node: ElseNode).void }
    def visit_else_node(node); end

    sig { params(node: EmbeddedStatementsNode).void }
    def visit_embedded_statements_node(node); end

    sig { params(node: EmbeddedVariableNode).void }
    def visit_embedded_variable_node(node); end

    sig { params(node: EnsureNode).void }
    def visit_ensure_node(node); end

    sig { params(node: FalseNode).void }
    def visit_false_node(node); end

    sig { params(node: FindPatternNode).void }
    def visit_find_pattern_node(node); end

    sig { params(node: FlipFlopNode).void }
    def visit_flip_flop_node(node); end

    sig { params(node: FloatNode).void }
    def visit_float_node(node); end

    sig { params(node: ForNode).void }
    def visit_for_node(node); end

    sig { params(node: ForwardingArgumentsNode).void }
    def visit_forwarding_arguments_node(node); end

    sig { params(node: ForwardingParameterNode).void }
    def visit_forwarding_parameter_node(node); end

    sig { params(node: ForwardingSuperNode).void }
    def visit_forwarding_super_node(node); end

    sig { params(node: GlobalVariableAndWriteNode).void }
    def visit_global_variable_and_write_node(node); end

    sig { params(node: GlobalVariableOperatorWriteNode).void }
    def visit_global_variable_operator_write_node(node); end

    sig { params(node: GlobalVariableOrWriteNode).void }
    def visit_global_variable_or_write_node(node); end

    sig { params(node: GlobalVariableReadNode).void }
    def visit_global_variable_read_node(node); end

    sig { params(node: GlobalVariableTargetNode).void }
    def visit_global_variable_target_node(node); end

    sig { params(node: GlobalVariableWriteNode).void }
    def visit_global_variable_write_node(node); end

    sig { params(node: HashNode).void }
    def visit_hash_node(node); end

    sig { params(node: HashPatternNode).void }
    def visit_hash_pattern_node(node); end

    sig { params(node: IfNode).void }
    def visit_if_node(node); end

    sig { params(node: ImaginaryNode).void }
    def visit_imaginary_node(node); end

    sig { params(node: ImplicitNode).void }
    def visit_implicit_node(node); end

    sig { params(node: ImplicitRestNode).void }
    def visit_implicit_rest_node(node); end

    sig { params(node: InNode).void }
    def visit_in_node(node); end

    sig { params(node: IndexAndWriteNode).void }
    def visit_index_and_write_node(node); end

    sig { params(node: IndexOperatorWriteNode).void }
    def visit_index_operator_write_node(node); end

    sig { params(node: IndexOrWriteNode).void }
    def visit_index_or_write_node(node); end

    sig { params(node: IndexTargetNode).void }
    def visit_index_target_node(node); end

    sig { params(node: InstanceVariableAndWriteNode).void }
    def visit_instance_variable_and_write_node(node); end

    sig { params(node: InstanceVariableOperatorWriteNode).void }
    def visit_instance_variable_operator_write_node(node); end

    sig { params(node: InstanceVariableOrWriteNode).void }
    def visit_instance_variable_or_write_node(node); end

    sig { params(node: InstanceVariableReadNode).void }
    def visit_instance_variable_read_node(node); end

    sig { params(node: InstanceVariableTargetNode).void }
    def visit_instance_variable_target_node(node); end

    sig { params(node: InstanceVariableWriteNode).void }
    def visit_instance_variable_write_node(node); end

    sig { params(node: IntegerNode).void }
    def visit_integer_node(node); end

    sig { params(node: InterpolatedMatchLastLineNode).void }
    def visit_interpolated_match_last_line_node(node); end

    sig { params(node: InterpolatedRegularExpressionNode).void }
    def visit_interpolated_regular_expression_node(node); end

    sig { params(node: InterpolatedStringNode).void }
    def visit_interpolated_string_node(node); end

    sig { params(node: InterpolatedSymbolNode).void }
    def visit_interpolated_symbol_node(node); end

    sig { params(node: InterpolatedXStringNode).void }
    def visit_interpolated_x_string_node(node); end

    sig { params(node: ItLocalVariableReadNode).void }
    def visit_it_local_variable_read_node(node); end

    sig { params(node: ItParametersNode).void }
    def visit_it_parameters_node(node); end

    sig { params(node: KeywordHashNode).void }
    def visit_keyword_hash_node(node); end

    sig { params(node: KeywordRestParameterNode).void }
    def visit_keyword_rest_parameter_node(node); end

    sig { params(node: LambdaNode).void }
    def visit_lambda_node(node); end

    sig { params(node: LocalVariableAndWriteNode).void }
    def visit_local_variable_and_write_node(node); end

    sig { params(node: LocalVariableOperatorWriteNode).void }
    def visit_local_variable_operator_write_node(node); end

    sig { params(node: LocalVariableOrWriteNode).void }
    def visit_local_variable_or_write_node(node); end

    sig { params(node: LocalVariableReadNode).void }
    def visit_local_variable_read_node(node); end

    sig { params(node: LocalVariableTargetNode).void }
    def visit_local_variable_target_node(node); end

    sig { params(node: LocalVariableWriteNode).void }
    def visit_local_variable_write_node(node); end

    sig { params(node: MatchLastLineNode).void }
    def visit_match_last_line_node(node); end

    sig { params(node: MatchPredicateNode).void }
    def visit_match_predicate_node(node); end

    sig { params(node: MatchRequiredNode).void }
    def visit_match_required_node(node); end

    sig { params(node: MatchWriteNode).void }
    def visit_match_write_node(node); end

    sig { params(node: MissingNode).void }
    def visit_missing_node(node); end

    sig { params(node: ModuleNode).void }
    def visit_module_node(node); end

    sig { params(node: MultiTargetNode).void }
    def visit_multi_target_node(node); end

    sig { params(node: MultiWriteNode).void }
    def visit_multi_write_node(node); end

    sig { params(node: NextNode).void }
    def visit_next_node(node); end

    sig { params(node: NilNode).void }
    def visit_nil_node(node); end

    sig { params(node: NoBlockParameterNode).void }
    def visit_no_block_parameter_node(node); end

    sig { params(node: NoKeywordsParameterNode).void }
    def visit_no_keywords_parameter_node(node); end

    sig { params(node: NumberedParametersNode).void }
    def visit_numbered_parameters_node(node); end

    sig { params(node: NumberedReferenceReadNode).void }
    def visit_numbered_reference_read_node(node); end

    sig { params(node: OptionalKeywordParameterNode).void }
    def visit_optional_keyword_parameter_node(node); end

    sig { params(node: OptionalParameterNode).void }
    def visit_optional_parameter_node(node); end

    sig { params(node: OrNode).void }
    def visit_or_node(node); end

    sig { params(node: ParametersNode).void }
    def visit_parameters_node(node); end

    sig { params(node: ParenthesesNode).void }
    def visit_parentheses_node(node); end

    sig { params(node: PinnedExpressionNode).void }
    def visit_pinned_expression_node(node); end

    sig { params(node: PinnedVariableNode).void }
    def visit_pinned_variable_node(node); end

    sig { params(node: PostExecutionNode).void }
    def visit_post_execution_node(node); end

    sig { params(node: PreExecutionNode).void }
    def visit_pre_execution_node(node); end

    sig { params(node: ProgramNode).void }
    def visit_program_node(node); end

    sig { params(node: RangeNode).void }
    def visit_range_node(node); end

    sig { params(node: RationalNode).void }
    def visit_rational_node(node); end

    sig { params(node: RedoNode).void }
    def visit_redo_node(node); end

    sig { params(node: RegularExpressionNode).void }
    def visit_regular_expression_node(node); end

    sig { params(node: RequiredKeywordParameterNode).void }
    def visit_required_keyword_parameter_node(node); end

    sig { params(node: RequiredParameterNode).void }
    def visit_required_parameter_node(node); end

    sig { params(node: RescueModifierNode).void }
    def visit_rescue_modifier_node(node); end

    sig { params(node: RescueNode).void }
    def visit_rescue_node(node); end

    sig { params(node: RestParameterNode).void }
    def visit_rest_parameter_node(node); end

    sig { params(node: RetryNode).void }
    def visit_retry_node(node); end

    sig { params(node: ReturnNode).void }
    def visit_return_node(node); end

    sig { params(node: SelfNode).void }
    def visit_self_node(node); end

    sig { params(node: ShareableConstantNode).void }
    def visit_shareable_constant_node(node); end

    sig { params(node: SingletonClassNode).void }
    def visit_singleton_class_node(node); end

    sig { params(node: SourceEncodingNode).void }
    def visit_source_encoding_node(node); end

    sig { params(node: SourceFileNode).void }
    def visit_source_file_node(node); end

    sig { params(node: SourceLineNode).void }
    def visit_source_line_node(node); end

    sig { params(node: SplatNode).void }
    def visit_splat_node(node); end

    sig { params(node: StatementsNode).void }
    def visit_statements_node(node); end

    sig { params(node: StringNode).void }
    def visit_string_node(node); end

    sig { params(node: SuperNode).void }
    def visit_super_node(node); end

    sig { params(node: SymbolNode).void }
    def visit_symbol_node(node); end

    sig { params(node: TrueNode).void }
    def visit_true_node(node); end

    sig { params(node: UndefNode).void }
    def visit_undef_node(node); end

    sig { params(node: UnlessNode).void }
    def visit_unless_node(node); end

    sig { params(node: UntilNode).void }
    def visit_until_node(node); end

    sig { params(node: WhenNode).void }
    def visit_when_node(node); end

    sig { params(node: WhileNode).void }
    def visit_while_node(node); end

    sig { params(node: XStringNode).void }
    def visit_x_string_node(node); end

    sig { params(node: YieldNode).void }
    def visit_yield_node(node); end

    class DispatchOnce < Visitor
      sig { returns(T::Hash[Symbol, T::Array[T.untyped]]) }
      attr_reader :listeners

      sig { params(listeners: T::Hash[Symbol, T::Array[T.untyped]]).void }
      def initialize(listeners); end

      # Dispatch enter and leave events for AliasGlobalVariableNode nodes.
      sig { params(node: AliasGlobalVariableNode).void }
      def visit_alias_global_variable_node(node); end

      # Dispatch enter and leave events for AliasMethodNode nodes.
      sig { params(node: AliasMethodNode).void }
      def visit_alias_method_node(node); end

      # Dispatch enter and leave events for AlternationPatternNode nodes.
      sig { params(node: AlternationPatternNode).void }
      def visit_alternation_pattern_node(node); end

      # Dispatch enter and leave events for AndNode nodes.
      sig { params(node: AndNode).void }
      def visit_and_node(node); end

      # Dispatch enter and leave events for ArgumentsNode nodes.
      sig { params(node: ArgumentsNode).void }
      def visit_arguments_node(node); end

      # Dispatch enter and leave events for ArrayNode nodes.
      sig { params(node: ArrayNode).void }
      def visit_array_node(node); end

      # Dispatch enter and leave events for ArrayPatternNode nodes.
      sig { params(node: ArrayPatternNode).void }
      def visit_array_pattern_node(node); end

      # Dispatch enter and leave events for AssocNode nodes.
      sig { params(node: AssocNode).void }
      def visit_assoc_node(node); end

      # Dispatch enter and leave events for AssocSplatNode nodes.
      sig { params(node: AssocSplatNode).void }
      def visit_assoc_splat_node(node); end

      # Dispatch enter and leave events for BackReferenceReadNode nodes.
      sig { params(node: BackReferenceReadNode).void }
      def visit_back_reference_read_node(node); end

      # Dispatch enter and leave events for BeginNode nodes.
      sig { params(node: BeginNode).void }
      def visit_begin_node(node); end

      # Dispatch enter and leave events for BlockArgumentNode nodes.
      sig { params(node: BlockArgumentNode).void }
      def visit_block_argument_node(node); end

      # Dispatch enter and leave events for BlockLocalVariableNode nodes.
      sig { params(node: BlockLocalVariableNode).void }
      def visit_block_local_variable_node(node); end

      # Dispatch enter and leave events for BlockNode nodes.
      sig { params(node: BlockNode).void }
      def visit_block_node(node); end

      # Dispatch enter and leave events for BlockParameterNode nodes.
      sig { params(node: BlockParameterNode).void }
      def visit_block_parameter_node(node); end

      # Dispatch enter and leave events for BlockParametersNode nodes.
      sig { params(node: BlockParametersNode).void }
      def visit_block_parameters_node(node); end

      # Dispatch enter and leave events for BreakNode nodes.
      sig { params(node: BreakNode).void }
      def visit_break_node(node); end

      # Dispatch enter and leave events for CallAndWriteNode nodes.
      sig { params(node: CallAndWriteNode).void }
      def visit_call_and_write_node(node); end

      # Dispatch enter and leave events for CallNode nodes.
      sig { params(node: CallNode).void }
      def visit_call_node(node); end

      # Dispatch enter and leave events for CallOperatorWriteNode nodes.
      sig { params(node: CallOperatorWriteNode).void }
      def visit_call_operator_write_node(node); end

      # Dispatch enter and leave events for CallOrWriteNode nodes.
      sig { params(node: CallOrWriteNode).void }
      def visit_call_or_write_node(node); end

      # Dispatch enter and leave events for CallTargetNode nodes.
      sig { params(node: CallTargetNode).void }
      def visit_call_target_node(node); end

      # Dispatch enter and leave events for CapturePatternNode nodes.
      sig { params(node: CapturePatternNode).void }
      def visit_capture_pattern_node(node); end

      # Dispatch enter and leave events for CaseMatchNode nodes.
      sig { params(node: CaseMatchNode).void }
      def visit_case_match_node(node); end

      # Dispatch enter and leave events for CaseNode nodes.
      sig { params(node: CaseNode).void }
      def visit_case_node(node); end

      # Dispatch enter and leave events for ClassNode nodes.
      sig { params(node: ClassNode).void }
      def visit_class_node(node); end

      # Dispatch enter and leave events for ClassVariableAndWriteNode nodes.
      sig { params(node: ClassVariableAndWriteNode).void }
      def visit_class_variable_and_write_node(node); end

      # Dispatch enter and leave events for ClassVariableOperatorWriteNode nodes.
      sig { params(node: ClassVariableOperatorWriteNode).void }
      def visit_class_variable_operator_write_node(node); end

      # Dispatch enter and leave events for ClassVariableOrWriteNode nodes.
      sig { params(node: ClassVariableOrWriteNode).void }
      def visit_class_variable_or_write_node(node); end

      # Dispatch enter and leave events for ClassVariableReadNode nodes.
      sig { params(node: ClassVariableReadNode).void }
      def visit_class_variable_read_node(node); end

      # Dispatch enter and leave events for ClassVariableTargetNode nodes.
      sig { params(node: ClassVariableTargetNode).void }
      def visit_class_variable_target_node(node); end

      # Dispatch enter and leave events for ClassVariableWriteNode nodes.
      sig { params(node: ClassVariableWriteNode).void }
      def visit_class_variable_write_node(node); end

      # Dispatch enter and leave events for ConstantAndWriteNode nodes.
      sig { params(node: ConstantAndWriteNode).void }
      def visit_constant_and_write_node(node); end

      # Dispatch enter and leave events for ConstantOperatorWriteNode nodes.
      sig { params(node: ConstantOperatorWriteNode).void }
      def visit_constant_operator_write_node(node); end

      # Dispatch enter and leave events for ConstantOrWriteNode nodes.
      sig { params(node: ConstantOrWriteNode).void }
      def visit_constant_or_write_node(node); end

      # Dispatch enter and leave events for ConstantPathAndWriteNode nodes.
      sig { params(node: ConstantPathAndWriteNode).void }
      def visit_constant_path_and_write_node(node); end

      # Dispatch enter and leave events for ConstantPathNode nodes.
      sig { params(node: ConstantPathNode).void }
      def visit_constant_path_node(node); end

      # Dispatch enter and leave events for ConstantPathOperatorWriteNode nodes.
      sig { params(node: ConstantPathOperatorWriteNode).void }
      def visit_constant_path_operator_write_node(node); end

      # Dispatch enter and leave events for ConstantPathOrWriteNode nodes.
      sig { params(node: ConstantPathOrWriteNode).void }
      def visit_constant_path_or_write_node(node); end

      # Dispatch enter and leave events for ConstantPathTargetNode nodes.
      sig { params(node: ConstantPathTargetNode).void }
      def visit_constant_path_target_node(node); end

      # Dispatch enter and leave events for ConstantPathWriteNode nodes.
      sig { params(node: ConstantPathWriteNode).void }
      def visit_constant_path_write_node(node); end

      # Dispatch enter and leave events for ConstantReadNode nodes.
      sig { params(node: ConstantReadNode).void }
      def visit_constant_read_node(node); end

      # Dispatch enter and leave events for ConstantTargetNode nodes.
      sig { params(node: ConstantTargetNode).void }
      def visit_constant_target_node(node); end

      # Dispatch enter and leave events for ConstantWriteNode nodes.
      sig { params(node: ConstantWriteNode).void }
      def visit_constant_write_node(node); end

      # Dispatch enter and leave events for DefNode nodes.
      sig { params(node: DefNode).void }
      def visit_def_node(node); end

      # Dispatch enter and leave events for DefinedNode nodes.
      sig { params(node: DefinedNode).void }
      def visit_defined_node(node); end

      # Dispatch enter and leave events for ElseNode nodes.
      sig { params(node: ElseNode).void }
      def visit_else_node(node); end

      # Dispatch enter and leave events for EmbeddedStatementsNode nodes.
      sig { params(node: EmbeddedStatementsNode).void }
      def visit_embedded_statements_node(node); end

      # Dispatch enter and leave events for EmbeddedVariableNode nodes.
      sig { params(node: EmbeddedVariableNode).void }
      def visit_embedded_variable_node(node); end

      # Dispatch enter and leave events for EnsureNode nodes.
      sig { params(node: EnsureNode).void }
      def visit_ensure_node(node); end

      # Dispatch enter and leave events for FalseNode nodes.
      sig { params(node: FalseNode).void }
      def visit_false_node(node); end

      # Dispatch enter and leave events for FindPatternNode nodes.
      sig { params(node: FindPatternNode).void }
      def visit_find_pattern_node(node); end

      # Dispatch enter and leave events for FlipFlopNode nodes.
      sig { params(node: FlipFlopNode).void }
      def visit_flip_flop_node(node); end

      # Dispatch enter and leave events for FloatNode nodes.
      sig { params(node: FloatNode).void }
      def visit_float_node(node); end

      # Dispatch enter and leave events for ForNode nodes.
      sig { params(node: ForNode).void }
      def visit_for_node(node); end

      # Dispatch enter and leave events for ForwardingArgumentsNode nodes.
      sig { params(node: ForwardingArgumentsNode).void }
      def visit_forwarding_arguments_node(node); end

      # Dispatch enter and leave events for ForwardingParameterNode nodes.
      sig { params(node: ForwardingParameterNode).void }
      def visit_forwarding_parameter_node(node); end

      # Dispatch enter and leave events for ForwardingSuperNode nodes.
      sig { params(node: ForwardingSuperNode).void }
      def visit_forwarding_super_node(node); end

      # Dispatch enter and leave events for GlobalVariableAndWriteNode nodes.
      sig { params(node: GlobalVariableAndWriteNode).void }
      def visit_global_variable_and_write_node(node); end

      # Dispatch enter and leave events for GlobalVariableOperatorWriteNode nodes.
      sig { params(node: GlobalVariableOperatorWriteNode).void }
      def visit_global_variable_operator_write_node(node); end

      # Dispatch enter and leave events for GlobalVariableOrWriteNode nodes.
      sig { params(node: GlobalVariableOrWriteNode).void }
      def visit_global_variable_or_write_node(node); end

      # Dispatch enter and leave events for GlobalVariableReadNode nodes.
      sig { params(node: GlobalVariableReadNode).void }
      def visit_global_variable_read_node(node); end

      # Dispatch enter and leave events for GlobalVariableTargetNode nodes.
      sig { params(node: GlobalVariableTargetNode).void }
      def visit_global_variable_target_node(node); end

      # Dispatch enter and leave events for GlobalVariableWriteNode nodes.
      sig { params(node: GlobalVariableWriteNode).void }
      def visit_global_variable_write_node(node); end

      # Dispatch enter and leave events for HashNode nodes.
      sig { params(node: HashNode).void }
      def visit_hash_node(node); end

      # Dispatch enter and leave events for HashPatternNode nodes.
      sig { params(node: HashPatternNode).void }
      def visit_hash_pattern_node(node); end

      # Dispatch enter and leave events for IfNode nodes.
      sig { params(node: IfNode).void }
      def visit_if_node(node); end

      # Dispatch enter and leave events for ImaginaryNode nodes.
      sig { params(node: ImaginaryNode).void }
      def visit_imaginary_node(node); end

      # Dispatch enter and leave events for ImplicitNode nodes.
      sig { params(node: ImplicitNode).void }
      def visit_implicit_node(node); end

      # Dispatch enter and leave events for ImplicitRestNode nodes.
      sig { params(node: ImplicitRestNode).void }
      def visit_implicit_rest_node(node); end

      # Dispatch enter and leave events for InNode nodes.
      sig { params(node: InNode).void }
      def visit_in_node(node); end

      # Dispatch enter and leave events for IndexAndWriteNode nodes.
      sig { params(node: IndexAndWriteNode).void }
      def visit_index_and_write_node(node); end

      # Dispatch enter and leave events for IndexOperatorWriteNode nodes.
      sig { params(node: IndexOperatorWriteNode).void }
      def visit_index_operator_write_node(node); end

      # Dispatch enter and leave events for IndexOrWriteNode nodes.
      sig { params(node: IndexOrWriteNode).void }
      def visit_index_or_write_node(node); end

      # Dispatch enter and leave events for IndexTargetNode nodes.
      sig { params(node: IndexTargetNode).void }
      def visit_index_target_node(node); end

      # Dispatch enter and leave events for InstanceVariableAndWriteNode nodes.
      sig { params(node: InstanceVariableAndWriteNode).void }
      def visit_instance_variable_and_write_node(node); end

      # Dispatch enter and leave events for InstanceVariableOperatorWriteNode nodes.
      sig { params(node: InstanceVariableOperatorWriteNode).void }
      def visit_instance_variable_operator_write_node(node); end

      # Dispatch enter and leave events for InstanceVariableOrWriteNode nodes.
      sig { params(node: InstanceVariableOrWriteNode).void }
      def visit_instance_variable_or_write_node(node); end

      # Dispatch enter and leave events for InstanceVariableReadNode nodes.
      sig { params(node: InstanceVariableReadNode).void }
      def visit_instance_variable_read_node(node); end

      # Dispatch enter and leave events for InstanceVariableTargetNode nodes.
      sig { params(node: InstanceVariableTargetNode).void }
      def visit_instance_variable_target_node(node); end

      # Dispatch enter and leave events for InstanceVariableWriteNode nodes.
      sig { params(node: InstanceVariableWriteNode).void }
      def visit_instance_variable_write_node(node); end

      # Dispatch enter and leave events for IntegerNode nodes.
      sig { params(node: IntegerNode).void }
      def visit_integer_node(node); end

      # Dispatch enter and leave events for InterpolatedMatchLastLineNode nodes.
      sig { params(node: InterpolatedMatchLastLineNode).void }
      def visit_interpolated_match_last_line_node(node); end

      # Dispatch enter and leave events for InterpolatedRegularExpressionNode nodes.
      sig { params(node: InterpolatedRegularExpressionNode).void }
      def visit_interpolated_regular_expression_node(node); end

      # Dispatch enter and leave events for InterpolatedStringNode nodes.
      sig { params(node: InterpolatedStringNode).void }
      def visit_interpolated_string_node(node); end

      # Dispatch enter and leave events for InterpolatedSymbolNode nodes.
      sig { params(node: InterpolatedSymbolNode).void }
      def visit_interpolated_symbol_node(node); end

      # Dispatch enter and leave events for InterpolatedXStringNode nodes.
      sig { params(node: InterpolatedXStringNode).void }
      def visit_interpolated_x_string_node(node); end

      # Dispatch enter and leave events for ItLocalVariableReadNode nodes.
      sig { params(node: ItLocalVariableReadNode).void }
      def visit_it_local_variable_read_node(node); end

      # Dispatch enter and leave events for ItParametersNode nodes.
      sig { params(node: ItParametersNode).void }
      def visit_it_parameters_node(node); end

      # Dispatch enter and leave events for KeywordHashNode nodes.
      sig { params(node: KeywordHashNode).void }
      def visit_keyword_hash_node(node); end

      # Dispatch enter and leave events for KeywordRestParameterNode nodes.
      sig { params(node: KeywordRestParameterNode).void }
      def visit_keyword_rest_parameter_node(node); end

      # Dispatch enter and leave events for LambdaNode nodes.
      sig { params(node: LambdaNode).void }
      def visit_lambda_node(node); end

      # Dispatch enter and leave events for LocalVariableAndWriteNode nodes.
      sig { params(node: LocalVariableAndWriteNode).void }
      def visit_local_variable_and_write_node(node); end

      # Dispatch enter and leave events for LocalVariableOperatorWriteNode nodes.
      sig { params(node: LocalVariableOperatorWriteNode).void }
      def visit_local_variable_operator_write_node(node); end

      # Dispatch enter and leave events for LocalVariableOrWriteNode nodes.
      sig { params(node: LocalVariableOrWriteNode).void }
      def visit_local_variable_or_write_node(node); end

      # Dispatch enter and leave events for LocalVariableReadNode nodes.
      sig { params(node: LocalVariableReadNode).void }
      def visit_local_variable_read_node(node); end

      # Dispatch enter and leave events for LocalVariableTargetNode nodes.
      sig { params(node: LocalVariableTargetNode).void }
      def visit_local_variable_target_node(node); end

      # Dispatch enter and leave events for LocalVariableWriteNode nodes.
      sig { params(node: LocalVariableWriteNode).void }
      def visit_local_variable_write_node(node); end

      # Dispatch enter and leave events for MatchLastLineNode nodes.
      sig { params(node: MatchLastLineNode).void }
      def visit_match_last_line_node(node); end

      # Dispatch enter and leave events for MatchPredicateNode nodes.
      sig { params(node: MatchPredicateNode).void }
      def visit_match_predicate_node(node); end

      # Dispatch enter and leave events for MatchRequiredNode nodes.
      sig { params(node: MatchRequiredNode).void }
      def visit_match_required_node(node); end

      # Dispatch enter and leave events for MatchWriteNode nodes.
      sig { params(node: MatchWriteNode).void }
      def visit_match_write_node(node); end

      # Dispatch enter and leave events for MissingNode nodes.
      sig { params(node: MissingNode).void }
      def visit_missing_node(node); end

      # Dispatch enter and leave events for ModuleNode nodes.
      sig { params(node: ModuleNode).void }
      def visit_module_node(node); end

      # Dispatch enter and leave events for MultiTargetNode nodes.
      sig { params(node: MultiTargetNode).void }
      def visit_multi_target_node(node); end

      # Dispatch enter and leave events for MultiWriteNode nodes.
      sig { params(node: MultiWriteNode).void }
      def visit_multi_write_node(node); end

      # Dispatch enter and leave events for NextNode nodes.
      sig { params(node: NextNode).void }
      def visit_next_node(node); end

      # Dispatch enter and leave events for NilNode nodes.
      sig { params(node: NilNode).void }
      def visit_nil_node(node); end

      # Dispatch enter and leave events for NoBlockParameterNode nodes.
      sig { params(node: NoBlockParameterNode).void }
      def visit_no_block_parameter_node(node); end

      # Dispatch enter and leave events for NoKeywordsParameterNode nodes.
      sig { params(node: NoKeywordsParameterNode).void }
      def visit_no_keywords_parameter_node(node); end

      # Dispatch enter and leave events for NumberedParametersNode nodes.
      sig { params(node: NumberedParametersNode).void }
      def visit_numbered_parameters_node(node); end

      # Dispatch enter and leave events for NumberedReferenceReadNode nodes.
      sig { params(node: NumberedReferenceReadNode).void }
      def visit_numbered_reference_read_node(node); end

      # Dispatch enter and leave events for OptionalKeywordParameterNode nodes.
      sig { params(node: OptionalKeywordParameterNode).void }
      def visit_optional_keyword_parameter_node(node); end

      # Dispatch enter and leave events for OptionalParameterNode nodes.
      sig { params(node: OptionalParameterNode).void }
      def visit_optional_parameter_node(node); end

      # Dispatch enter and leave events for OrNode nodes.
      sig { params(node: OrNode).void }
      def visit_or_node(node); end

      # Dispatch enter and leave events for ParametersNode nodes.
      sig { params(node: ParametersNode).void }
      def visit_parameters_node(node); end

      # Dispatch enter and leave events for ParenthesesNode nodes.
      sig { params(node: ParenthesesNode).void }
      def visit_parentheses_node(node); end

      # Dispatch enter and leave events for PinnedExpressionNode nodes.
      sig { params(node: PinnedExpressionNode).void }
      def visit_pinned_expression_node(node); end

      # Dispatch enter and leave events for PinnedVariableNode nodes.
      sig { params(node: PinnedVariableNode).void }
      def visit_pinned_variable_node(node); end

      # Dispatch enter and leave events for PostExecutionNode nodes.
      sig { params(node: PostExecutionNode).void }
      def visit_post_execution_node(node); end

      # Dispatch enter and leave events for PreExecutionNode nodes.
      sig { params(node: PreExecutionNode).void }
      def visit_pre_execution_node(node); end

      # Dispatch enter and leave events for ProgramNode nodes.
      sig { params(node: ProgramNode).void }
      def visit_program_node(node); end

      # Dispatch enter and leave events for RangeNode nodes.
      sig { params(node: RangeNode).void }
      def visit_range_node(node); end

      # Dispatch enter and leave events for RationalNode nodes.
      sig { params(node: RationalNode).void }
      def visit_rational_node(node); end

      # Dispatch enter and leave events for RedoNode nodes.
      sig { params(node: RedoNode).void }
      def visit_redo_node(node); end

      # Dispatch enter and leave events for RegularExpressionNode nodes.
      sig { params(node: RegularExpressionNode).void }
      def visit_regular_expression_node(node); end

      # Dispatch enter and leave events for RequiredKeywordParameterNode nodes.
      sig { params(node: RequiredKeywordParameterNode).void }
      def visit_required_keyword_parameter_node(node); end

      # Dispatch enter and leave events for RequiredParameterNode nodes.
      sig { params(node: RequiredParameterNode).void }
      def visit_required_parameter_node(node); end

      # Dispatch enter and leave events for RescueModifierNode nodes.
      sig { params(node: RescueModifierNode).void }
      def visit_rescue_modifier_node(node); end

      # Dispatch enter and leave events for RescueNode nodes.
      sig { params(node: RescueNode).void }
      def visit_rescue_node(node); end

      # Dispatch enter and leave events for RestParameterNode nodes.
      sig { params(node: RestParameterNode).void }
      def visit_rest_parameter_node(node); end

      # Dispatch enter and leave events for RetryNode nodes.
      sig { params(node: RetryNode).void }
      def visit_retry_node(node); end

      # Dispatch enter and leave events for ReturnNode nodes.
      sig { params(node: ReturnNode).void }
      def visit_return_node(node); end

      # Dispatch enter and leave events for SelfNode nodes.
      sig { params(node: SelfNode).void }
      def visit_self_node(node); end

      # Dispatch enter and leave events for ShareableConstantNode nodes.
      sig { params(node: ShareableConstantNode).void }
      def visit_shareable_constant_node(node); end

      # Dispatch enter and leave events for SingletonClassNode nodes.
      sig { params(node: SingletonClassNode).void }
      def visit_singleton_class_node(node); end

      # Dispatch enter and leave events for SourceEncodingNode nodes.
      sig { params(node: SourceEncodingNode).void }
      def visit_source_encoding_node(node); end

      # Dispatch enter and leave events for SourceFileNode nodes.
      sig { params(node: SourceFileNode).void }
      def visit_source_file_node(node); end

      # Dispatch enter and leave events for SourceLineNode nodes.
      sig { params(node: SourceLineNode).void }
      def visit_source_line_node(node); end

      # Dispatch enter and leave events for SplatNode nodes.
      sig { params(node: SplatNode).void }
      def visit_splat_node(node); end

      # Dispatch enter and leave events for StatementsNode nodes.
      sig { params(node: StatementsNode).void }
      def visit_statements_node(node); end

      # Dispatch enter and leave events for StringNode nodes.
      sig { params(node: StringNode).void }
      def visit_string_node(node); end

      # Dispatch enter and leave events for SuperNode nodes.
      sig { params(node: SuperNode).void }
      def visit_super_node(node); end

      # Dispatch enter and leave events for SymbolNode nodes.
      sig { params(node: SymbolNode).void }
      def visit_symbol_node(node); end

      # Dispatch enter and leave events for TrueNode nodes.
      sig { params(node: TrueNode).void }
      def visit_true_node(node); end

      # Dispatch enter and leave events for UndefNode nodes.
      sig { params(node: UndefNode).void }
      def visit_undef_node(node); end

      # Dispatch enter and leave events for UnlessNode nodes.
      sig { params(node: UnlessNode).void }
      def visit_unless_node(node); end

      # Dispatch enter and leave events for UntilNode nodes.
      sig { params(node: UntilNode).void }
      def visit_until_node(node); end

      # Dispatch enter and leave events for WhenNode nodes.
      sig { params(node: WhenNode).void }
      def visit_when_node(node); end

      # Dispatch enter and leave events for WhileNode nodes.
      sig { params(node: WhileNode).void }
      def visit_while_node(node); end

      # Dispatch enter and leave events for XStringNode nodes.
      sig { params(node: XStringNode).void }
      def visit_x_string_node(node); end

      # Dispatch enter and leave events for YieldNode nodes.
      sig { params(node: YieldNode).void }
      def visit_yield_node(node); end
    end
  end
end
