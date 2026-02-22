# typed: true

module Prism
  # This visitor walks through the tree and copies each node as it is being
  # visited. This is useful for consumers that want to mutate the tree, as you
  # can change subtrees in place without effecting the rest of the tree.
  class MutationCompiler < Compiler
    sig { params(arg0: AliasGlobalVariableNode).returns(T.nilable(Node)) }
    def visit_alias_global_variable_node(arg0); end

    sig { params(arg0: AliasMethodNode).returns(T.nilable(Node)) }
    def visit_alias_method_node(arg0); end

    sig { params(arg0: AlternationPatternNode).returns(T.nilable(Node)) }
    def visit_alternation_pattern_node(arg0); end

    sig { params(arg0: AndNode).returns(T.nilable(Node)) }
    def visit_and_node(arg0); end

    sig { params(arg0: ArgumentsNode).returns(T.nilable(Node)) }
    def visit_arguments_node(arg0); end

    sig { params(arg0: ArrayNode).returns(T.nilable(Node)) }
    def visit_array_node(arg0); end

    sig { params(arg0: ArrayPatternNode).returns(T.nilable(Node)) }
    def visit_array_pattern_node(arg0); end

    sig { params(arg0: AssocNode).returns(T.nilable(Node)) }
    def visit_assoc_node(arg0); end

    sig { params(arg0: AssocSplatNode).returns(T.nilable(Node)) }
    def visit_assoc_splat_node(arg0); end

    sig { params(arg0: BackReferenceReadNode).returns(T.nilable(Node)) }
    def visit_back_reference_read_node(arg0); end

    sig { params(arg0: BeginNode).returns(T.nilable(Node)) }
    def visit_begin_node(arg0); end

    sig { params(arg0: BlockArgumentNode).returns(T.nilable(Node)) }
    def visit_block_argument_node(arg0); end

    sig { params(arg0: BlockLocalVariableNode).returns(T.nilable(Node)) }
    def visit_block_local_variable_node(arg0); end

    sig { params(arg0: BlockNode).returns(T.nilable(Node)) }
    def visit_block_node(arg0); end

    sig { params(arg0: BlockParameterNode).returns(T.nilable(Node)) }
    def visit_block_parameter_node(arg0); end

    sig { params(arg0: BlockParametersNode).returns(T.nilable(Node)) }
    def visit_block_parameters_node(arg0); end

    sig { params(arg0: BreakNode).returns(T.nilable(Node)) }
    def visit_break_node(arg0); end

    sig { params(arg0: CallAndWriteNode).returns(T.nilable(Node)) }
    def visit_call_and_write_node(arg0); end

    sig { params(arg0: CallNode).returns(T.nilable(Node)) }
    def visit_call_node(arg0); end

    sig { params(arg0: CallOperatorWriteNode).returns(T.nilable(Node)) }
    def visit_call_operator_write_node(arg0); end

    sig { params(arg0: CallOrWriteNode).returns(T.nilable(Node)) }
    def visit_call_or_write_node(arg0); end

    sig { params(arg0: CallTargetNode).returns(T.nilable(Node)) }
    def visit_call_target_node(arg0); end

    sig { params(arg0: CapturePatternNode).returns(T.nilable(Node)) }
    def visit_capture_pattern_node(arg0); end

    sig { params(arg0: CaseMatchNode).returns(T.nilable(Node)) }
    def visit_case_match_node(arg0); end

    sig { params(arg0: CaseNode).returns(T.nilable(Node)) }
    def visit_case_node(arg0); end

    sig { params(arg0: ClassNode).returns(T.nilable(Node)) }
    def visit_class_node(arg0); end

    sig { params(arg0: ClassVariableAndWriteNode).returns(T.nilable(Node)) }
    def visit_class_variable_and_write_node(arg0); end

    sig { params(arg0: ClassVariableOperatorWriteNode).returns(T.nilable(Node)) }
    def visit_class_variable_operator_write_node(arg0); end

    sig { params(arg0: ClassVariableOrWriteNode).returns(T.nilable(Node)) }
    def visit_class_variable_or_write_node(arg0); end

    sig { params(arg0: ClassVariableReadNode).returns(T.nilable(Node)) }
    def visit_class_variable_read_node(arg0); end

    sig { params(arg0: ClassVariableTargetNode).returns(T.nilable(Node)) }
    def visit_class_variable_target_node(arg0); end

    sig { params(arg0: ClassVariableWriteNode).returns(T.nilable(Node)) }
    def visit_class_variable_write_node(arg0); end

    sig { params(arg0: ConstantAndWriteNode).returns(T.nilable(Node)) }
    def visit_constant_and_write_node(arg0); end

    sig { params(arg0: ConstantOperatorWriteNode).returns(T.nilable(Node)) }
    def visit_constant_operator_write_node(arg0); end

    sig { params(arg0: ConstantOrWriteNode).returns(T.nilable(Node)) }
    def visit_constant_or_write_node(arg0); end

    sig { params(arg0: ConstantPathAndWriteNode).returns(T.nilable(Node)) }
    def visit_constant_path_and_write_node(arg0); end

    sig { params(arg0: ConstantPathNode).returns(T.nilable(Node)) }
    def visit_constant_path_node(arg0); end

    sig { params(arg0: ConstantPathOperatorWriteNode).returns(T.nilable(Node)) }
    def visit_constant_path_operator_write_node(arg0); end

    sig { params(arg0: ConstantPathOrWriteNode).returns(T.nilable(Node)) }
    def visit_constant_path_or_write_node(arg0); end

    sig { params(arg0: ConstantPathTargetNode).returns(T.nilable(Node)) }
    def visit_constant_path_target_node(arg0); end

    sig { params(arg0: ConstantPathWriteNode).returns(T.nilable(Node)) }
    def visit_constant_path_write_node(arg0); end

    sig { params(arg0: ConstantReadNode).returns(T.nilable(Node)) }
    def visit_constant_read_node(arg0); end

    sig { params(arg0: ConstantTargetNode).returns(T.nilable(Node)) }
    def visit_constant_target_node(arg0); end

    sig { params(arg0: ConstantWriteNode).returns(T.nilable(Node)) }
    def visit_constant_write_node(arg0); end

    sig { params(arg0: DefNode).returns(T.nilable(Node)) }
    def visit_def_node(arg0); end

    sig { params(arg0: DefinedNode).returns(T.nilable(Node)) }
    def visit_defined_node(arg0); end

    sig { params(arg0: ElseNode).returns(T.nilable(Node)) }
    def visit_else_node(arg0); end

    sig { params(arg0: EmbeddedStatementsNode).returns(T.nilable(Node)) }
    def visit_embedded_statements_node(arg0); end

    sig { params(arg0: EmbeddedVariableNode).returns(T.nilable(Node)) }
    def visit_embedded_variable_node(arg0); end

    sig { params(arg0: EnsureNode).returns(T.nilable(Node)) }
    def visit_ensure_node(arg0); end

    sig { params(arg0: FalseNode).returns(T.nilable(Node)) }
    def visit_false_node(arg0); end

    sig { params(arg0: FindPatternNode).returns(T.nilable(Node)) }
    def visit_find_pattern_node(arg0); end

    sig { params(arg0: FlipFlopNode).returns(T.nilable(Node)) }
    def visit_flip_flop_node(arg0); end

    sig { params(arg0: FloatNode).returns(T.nilable(Node)) }
    def visit_float_node(arg0); end

    sig { params(arg0: ForNode).returns(T.nilable(Node)) }
    def visit_for_node(arg0); end

    sig { params(arg0: ForwardingArgumentsNode).returns(T.nilable(Node)) }
    def visit_forwarding_arguments_node(arg0); end

    sig { params(arg0: ForwardingParameterNode).returns(T.nilable(Node)) }
    def visit_forwarding_parameter_node(arg0); end

    sig { params(arg0: ForwardingSuperNode).returns(T.nilable(Node)) }
    def visit_forwarding_super_node(arg0); end

    sig { params(arg0: GlobalVariableAndWriteNode).returns(T.nilable(Node)) }
    def visit_global_variable_and_write_node(arg0); end

    sig { params(arg0: GlobalVariableOperatorWriteNode).returns(T.nilable(Node)) }
    def visit_global_variable_operator_write_node(arg0); end

    sig { params(arg0: GlobalVariableOrWriteNode).returns(T.nilable(Node)) }
    def visit_global_variable_or_write_node(arg0); end

    sig { params(arg0: GlobalVariableReadNode).returns(T.nilable(Node)) }
    def visit_global_variable_read_node(arg0); end

    sig { params(arg0: GlobalVariableTargetNode).returns(T.nilable(Node)) }
    def visit_global_variable_target_node(arg0); end

    sig { params(arg0: GlobalVariableWriteNode).returns(T.nilable(Node)) }
    def visit_global_variable_write_node(arg0); end

    sig { params(arg0: HashNode).returns(T.nilable(Node)) }
    def visit_hash_node(arg0); end

    sig { params(arg0: HashPatternNode).returns(T.nilable(Node)) }
    def visit_hash_pattern_node(arg0); end

    sig { params(arg0: IfNode).returns(T.nilable(Node)) }
    def visit_if_node(arg0); end

    sig { params(arg0: ImaginaryNode).returns(T.nilable(Node)) }
    def visit_imaginary_node(arg0); end

    sig { params(arg0: ImplicitNode).returns(T.nilable(Node)) }
    def visit_implicit_node(arg0); end

    sig { params(arg0: ImplicitRestNode).returns(T.nilable(Node)) }
    def visit_implicit_rest_node(arg0); end

    sig { params(arg0: InNode).returns(T.nilable(Node)) }
    def visit_in_node(arg0); end

    sig { params(arg0: IndexAndWriteNode).returns(T.nilable(Node)) }
    def visit_index_and_write_node(arg0); end

    sig { params(arg0: IndexOperatorWriteNode).returns(T.nilable(Node)) }
    def visit_index_operator_write_node(arg0); end

    sig { params(arg0: IndexOrWriteNode).returns(T.nilable(Node)) }
    def visit_index_or_write_node(arg0); end

    sig { params(arg0: IndexTargetNode).returns(T.nilable(Node)) }
    def visit_index_target_node(arg0); end

    sig { params(arg0: InstanceVariableAndWriteNode).returns(T.nilable(Node)) }
    def visit_instance_variable_and_write_node(arg0); end

    sig { params(arg0: InstanceVariableOperatorWriteNode).returns(T.nilable(Node)) }
    def visit_instance_variable_operator_write_node(arg0); end

    sig { params(arg0: InstanceVariableOrWriteNode).returns(T.nilable(Node)) }
    def visit_instance_variable_or_write_node(arg0); end

    sig { params(arg0: InstanceVariableReadNode).returns(T.nilable(Node)) }
    def visit_instance_variable_read_node(arg0); end

    sig { params(arg0: InstanceVariableTargetNode).returns(T.nilable(Node)) }
    def visit_instance_variable_target_node(arg0); end

    sig { params(arg0: InstanceVariableWriteNode).returns(T.nilable(Node)) }
    def visit_instance_variable_write_node(arg0); end

    sig { params(arg0: IntegerNode).returns(T.nilable(Node)) }
    def visit_integer_node(arg0); end

    sig { params(arg0: InterpolatedMatchLastLineNode).returns(T.nilable(Node)) }
    def visit_interpolated_match_last_line_node(arg0); end

    sig { params(arg0: InterpolatedRegularExpressionNode).returns(T.nilable(Node)) }
    def visit_interpolated_regular_expression_node(arg0); end

    sig { params(arg0: InterpolatedStringNode).returns(T.nilable(Node)) }
    def visit_interpolated_string_node(arg0); end

    sig { params(arg0: InterpolatedSymbolNode).returns(T.nilable(Node)) }
    def visit_interpolated_symbol_node(arg0); end

    sig { params(arg0: InterpolatedXStringNode).returns(T.nilable(Node)) }
    def visit_interpolated_x_string_node(arg0); end

    sig { params(arg0: ItLocalVariableReadNode).returns(T.nilable(Node)) }
    def visit_it_local_variable_read_node(arg0); end

    sig { params(arg0: ItParametersNode).returns(T.nilable(Node)) }
    def visit_it_parameters_node(arg0); end

    sig { params(arg0: KeywordHashNode).returns(T.nilable(Node)) }
    def visit_keyword_hash_node(arg0); end

    sig { params(arg0: KeywordRestParameterNode).returns(T.nilable(Node)) }
    def visit_keyword_rest_parameter_node(arg0); end

    sig { params(arg0: LambdaNode).returns(T.nilable(Node)) }
    def visit_lambda_node(arg0); end

    sig { params(arg0: LocalVariableAndWriteNode).returns(T.nilable(Node)) }
    def visit_local_variable_and_write_node(arg0); end

    sig { params(arg0: LocalVariableOperatorWriteNode).returns(T.nilable(Node)) }
    def visit_local_variable_operator_write_node(arg0); end

    sig { params(arg0: LocalVariableOrWriteNode).returns(T.nilable(Node)) }
    def visit_local_variable_or_write_node(arg0); end

    sig { params(arg0: LocalVariableReadNode).returns(T.nilable(Node)) }
    def visit_local_variable_read_node(arg0); end

    sig { params(arg0: LocalVariableTargetNode).returns(T.nilable(Node)) }
    def visit_local_variable_target_node(arg0); end

    sig { params(arg0: LocalVariableWriteNode).returns(T.nilable(Node)) }
    def visit_local_variable_write_node(arg0); end

    sig { params(arg0: MatchLastLineNode).returns(T.nilable(Node)) }
    def visit_match_last_line_node(arg0); end

    sig { params(arg0: MatchPredicateNode).returns(T.nilable(Node)) }
    def visit_match_predicate_node(arg0); end

    sig { params(arg0: MatchRequiredNode).returns(T.nilable(Node)) }
    def visit_match_required_node(arg0); end

    sig { params(arg0: MatchWriteNode).returns(T.nilable(Node)) }
    def visit_match_write_node(arg0); end

    sig { params(arg0: MissingNode).returns(T.nilable(Node)) }
    def visit_missing_node(arg0); end

    sig { params(arg0: ModuleNode).returns(T.nilable(Node)) }
    def visit_module_node(arg0); end

    sig { params(arg0: MultiTargetNode).returns(T.nilable(Node)) }
    def visit_multi_target_node(arg0); end

    sig { params(arg0: MultiWriteNode).returns(T.nilable(Node)) }
    def visit_multi_write_node(arg0); end

    sig { params(arg0: NextNode).returns(T.nilable(Node)) }
    def visit_next_node(arg0); end

    sig { params(arg0: NilNode).returns(T.nilable(Node)) }
    def visit_nil_node(arg0); end

    sig { params(arg0: NoBlockParameterNode).returns(T.nilable(Node)) }
    def visit_no_block_parameter_node(arg0); end

    sig { params(arg0: NoKeywordsParameterNode).returns(T.nilable(Node)) }
    def visit_no_keywords_parameter_node(arg0); end

    sig { params(arg0: NumberedParametersNode).returns(T.nilable(Node)) }
    def visit_numbered_parameters_node(arg0); end

    sig { params(arg0: NumberedReferenceReadNode).returns(T.nilable(Node)) }
    def visit_numbered_reference_read_node(arg0); end

    sig { params(arg0: OptionalKeywordParameterNode).returns(T.nilable(Node)) }
    def visit_optional_keyword_parameter_node(arg0); end

    sig { params(arg0: OptionalParameterNode).returns(T.nilable(Node)) }
    def visit_optional_parameter_node(arg0); end

    sig { params(arg0: OrNode).returns(T.nilable(Node)) }
    def visit_or_node(arg0); end

    sig { params(arg0: ParametersNode).returns(T.nilable(Node)) }
    def visit_parameters_node(arg0); end

    sig { params(arg0: ParenthesesNode).returns(T.nilable(Node)) }
    def visit_parentheses_node(arg0); end

    sig { params(arg0: PinnedExpressionNode).returns(T.nilable(Node)) }
    def visit_pinned_expression_node(arg0); end

    sig { params(arg0: PinnedVariableNode).returns(T.nilable(Node)) }
    def visit_pinned_variable_node(arg0); end

    sig { params(arg0: PostExecutionNode).returns(T.nilable(Node)) }
    def visit_post_execution_node(arg0); end

    sig { params(arg0: PreExecutionNode).returns(T.nilable(Node)) }
    def visit_pre_execution_node(arg0); end

    sig { params(arg0: ProgramNode).returns(T.nilable(Node)) }
    def visit_program_node(arg0); end

    sig { params(arg0: RangeNode).returns(T.nilable(Node)) }
    def visit_range_node(arg0); end

    sig { params(arg0: RationalNode).returns(T.nilable(Node)) }
    def visit_rational_node(arg0); end

    sig { params(arg0: RedoNode).returns(T.nilable(Node)) }
    def visit_redo_node(arg0); end

    sig { params(arg0: RegularExpressionNode).returns(T.nilable(Node)) }
    def visit_regular_expression_node(arg0); end

    sig { params(arg0: RequiredKeywordParameterNode).returns(T.nilable(Node)) }
    def visit_required_keyword_parameter_node(arg0); end

    sig { params(arg0: RequiredParameterNode).returns(T.nilable(Node)) }
    def visit_required_parameter_node(arg0); end

    sig { params(arg0: RescueModifierNode).returns(T.nilable(Node)) }
    def visit_rescue_modifier_node(arg0); end

    sig { params(arg0: RescueNode).returns(T.nilable(Node)) }
    def visit_rescue_node(arg0); end

    sig { params(arg0: RestParameterNode).returns(T.nilable(Node)) }
    def visit_rest_parameter_node(arg0); end

    sig { params(arg0: RetryNode).returns(T.nilable(Node)) }
    def visit_retry_node(arg0); end

    sig { params(arg0: ReturnNode).returns(T.nilable(Node)) }
    def visit_return_node(arg0); end

    sig { params(arg0: SelfNode).returns(T.nilable(Node)) }
    def visit_self_node(arg0); end

    sig { params(arg0: ShareableConstantNode).returns(T.nilable(Node)) }
    def visit_shareable_constant_node(arg0); end

    sig { params(arg0: SingletonClassNode).returns(T.nilable(Node)) }
    def visit_singleton_class_node(arg0); end

    sig { params(arg0: SourceEncodingNode).returns(T.nilable(Node)) }
    def visit_source_encoding_node(arg0); end

    sig { params(arg0: SourceFileNode).returns(T.nilable(Node)) }
    def visit_source_file_node(arg0); end

    sig { params(arg0: SourceLineNode).returns(T.nilable(Node)) }
    def visit_source_line_node(arg0); end

    sig { params(arg0: SplatNode).returns(T.nilable(Node)) }
    def visit_splat_node(arg0); end

    sig { params(arg0: StatementsNode).returns(T.nilable(Node)) }
    def visit_statements_node(arg0); end

    sig { params(arg0: StringNode).returns(T.nilable(Node)) }
    def visit_string_node(arg0); end

    sig { params(arg0: SuperNode).returns(T.nilable(Node)) }
    def visit_super_node(arg0); end

    sig { params(arg0: SymbolNode).returns(T.nilable(Node)) }
    def visit_symbol_node(arg0); end

    sig { params(arg0: TrueNode).returns(T.nilable(Node)) }
    def visit_true_node(arg0); end

    sig { params(arg0: UndefNode).returns(T.nilable(Node)) }
    def visit_undef_node(arg0); end

    sig { params(arg0: UnlessNode).returns(T.nilable(Node)) }
    def visit_unless_node(arg0); end

    sig { params(arg0: UntilNode).returns(T.nilable(Node)) }
    def visit_until_node(arg0); end

    sig { params(arg0: WhenNode).returns(T.nilable(Node)) }
    def visit_when_node(arg0); end

    sig { params(arg0: WhileNode).returns(T.nilable(Node)) }
    def visit_while_node(arg0); end

    sig { params(arg0: XStringNode).returns(T.nilable(Node)) }
    def visit_x_string_node(arg0); end

    sig { params(arg0: YieldNode).returns(T.nilable(Node)) }
    def visit_yield_node(arg0); end
  end
end
