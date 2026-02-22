# typed: true

module Prism
  # This visitor is responsible for composing the strings that get returned by
  # the various #inspect methods defined on each of the nodes.
  class InspectVisitor < Visitor
    # Most of the time, we can simply pass down the indent to the next node.
    # However, when we are inside a list we want some extra special formatting
    # when we hit an element in that list. In this case, we have a special
    # command that replaces the subsequent indent with the given value.
    class Replace
      sig { returns(String) }
      attr_reader :value

      sig { params(value: String).void }
      def initialize(value); end
    end

    # The current prefix string.
    sig { returns(String) }
    attr_reader :indent

    # The list of commands that we need to execute in order to compose the
    # final string.
    sig { returns(T::Array[[T.any(String, Node, Replace), String]]) }
    attr_reader :commands

    sig { params(indent: String).void }
    def initialize(indent = T.unsafe(nil)); end

    # Compose an inspect string for the given node.
    sig { params(node: Node).returns(String) }
    def self.compose(node); end

    # Compose the final string.
    sig { returns(String) }
    def compose; end

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

    # Compose a header for the given node.
    sig { params(name: String, node: Node).returns(String) }
    private def inspect_node(name, node); end

    # Compose a string representing the given inner location field.
    sig { params(location: T.nilable(Location)).returns(String) }
    private def inspect_location(location); end
  end
end
