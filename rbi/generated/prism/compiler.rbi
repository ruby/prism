# typed: true

module Prism
  # A compiler is a visitor that returns the value of each node as it visits.
  # This is as opposed to a visitor which will only walk the tree. This can be
  # useful when you are trying to compile a tree into a different format.
  #
  # For example, to build a representation of the tree as s-expressions, you
  # could write:
  #
  #     class SExpressions < Prism::Compiler
  #       def visit_arguments_node(node) = [:arguments, super]
  #       def visit_call_node(node) = [:call, super]
  #       def visit_integer_node(node) = [:integer]
  #       def visit_program_node(node) = [:program, super]
  #     end
  #
  #     Prism.parse("1 + 2").value.accept(SExpressions.new)
  #     # => [:program, [[[:call, [[:integer], [:arguments, [[:integer]]]]]]]]
  class Compiler < Visitor
    # Visit an individual node.
    sig { params(arg0: T.nilable(Node)).returns(T.untyped) }
    def visit(arg0); end

    # Visit a list of nodes.
    sig { params(arg0: T::Array[T.nilable(Node)]).returns(T.untyped) }
    def visit_all(arg0); end

    # Visit the child nodes of the given node.
    sig { params(arg0: Node).returns(T::Array[T.untyped]) }
    def visit_child_nodes(arg0); end

    sig { params(arg0: AliasGlobalVariableNode).returns(T::Array[T.untyped]) }
    def visit_alias_global_variable_node(arg0); end

    sig { params(arg0: AliasMethodNode).returns(T::Array[T.untyped]) }
    def visit_alias_method_node(arg0); end

    sig { params(arg0: AlternationPatternNode).returns(T::Array[T.untyped]) }
    def visit_alternation_pattern_node(arg0); end

    sig { params(arg0: AndNode).returns(T::Array[T.untyped]) }
    def visit_and_node(arg0); end

    sig { params(arg0: ArgumentsNode).returns(T::Array[T.untyped]) }
    def visit_arguments_node(arg0); end

    sig { params(arg0: ArrayNode).returns(T::Array[T.untyped]) }
    def visit_array_node(arg0); end

    sig { params(arg0: ArrayPatternNode).returns(T::Array[T.untyped]) }
    def visit_array_pattern_node(arg0); end

    sig { params(arg0: AssocNode).returns(T::Array[T.untyped]) }
    def visit_assoc_node(arg0); end

    sig { params(arg0: AssocSplatNode).returns(T::Array[T.untyped]) }
    def visit_assoc_splat_node(arg0); end

    sig { params(arg0: BackReferenceReadNode).returns(T::Array[T.untyped]) }
    def visit_back_reference_read_node(arg0); end

    sig { params(arg0: BeginNode).returns(T::Array[T.untyped]) }
    def visit_begin_node(arg0); end

    sig { params(arg0: BlockArgumentNode).returns(T::Array[T.untyped]) }
    def visit_block_argument_node(arg0); end

    sig { params(arg0: BlockLocalVariableNode).returns(T::Array[T.untyped]) }
    def visit_block_local_variable_node(arg0); end

    sig { params(arg0: BlockNode).returns(T::Array[T.untyped]) }
    def visit_block_node(arg0); end

    sig { params(arg0: BlockParameterNode).returns(T::Array[T.untyped]) }
    def visit_block_parameter_node(arg0); end

    sig { params(arg0: BlockParametersNode).returns(T::Array[T.untyped]) }
    def visit_block_parameters_node(arg0); end

    sig { params(arg0: BreakNode).returns(T::Array[T.untyped]) }
    def visit_break_node(arg0); end

    sig { params(arg0: CallAndWriteNode).returns(T::Array[T.untyped]) }
    def visit_call_and_write_node(arg0); end

    sig { params(arg0: CallNode).returns(T::Array[T.untyped]) }
    def visit_call_node(arg0); end

    sig { params(arg0: CallOperatorWriteNode).returns(T::Array[T.untyped]) }
    def visit_call_operator_write_node(arg0); end

    sig { params(arg0: CallOrWriteNode).returns(T::Array[T.untyped]) }
    def visit_call_or_write_node(arg0); end

    sig { params(arg0: CallTargetNode).returns(T::Array[T.untyped]) }
    def visit_call_target_node(arg0); end

    sig { params(arg0: CapturePatternNode).returns(T::Array[T.untyped]) }
    def visit_capture_pattern_node(arg0); end

    sig { params(arg0: CaseMatchNode).returns(T::Array[T.untyped]) }
    def visit_case_match_node(arg0); end

    sig { params(arg0: CaseNode).returns(T::Array[T.untyped]) }
    def visit_case_node(arg0); end

    sig { params(arg0: ClassNode).returns(T::Array[T.untyped]) }
    def visit_class_node(arg0); end

    sig { params(arg0: ClassVariableAndWriteNode).returns(T::Array[T.untyped]) }
    def visit_class_variable_and_write_node(arg0); end

    sig { params(arg0: ClassVariableOperatorWriteNode).returns(T::Array[T.untyped]) }
    def visit_class_variable_operator_write_node(arg0); end

    sig { params(arg0: ClassVariableOrWriteNode).returns(T::Array[T.untyped]) }
    def visit_class_variable_or_write_node(arg0); end

    sig { params(arg0: ClassVariableReadNode).returns(T::Array[T.untyped]) }
    def visit_class_variable_read_node(arg0); end

    sig { params(arg0: ClassVariableTargetNode).returns(T::Array[T.untyped]) }
    def visit_class_variable_target_node(arg0); end

    sig { params(arg0: ClassVariableWriteNode).returns(T::Array[T.untyped]) }
    def visit_class_variable_write_node(arg0); end

    sig { params(arg0: ConstantAndWriteNode).returns(T::Array[T.untyped]) }
    def visit_constant_and_write_node(arg0); end

    sig { params(arg0: ConstantOperatorWriteNode).returns(T::Array[T.untyped]) }
    def visit_constant_operator_write_node(arg0); end

    sig { params(arg0: ConstantOrWriteNode).returns(T::Array[T.untyped]) }
    def visit_constant_or_write_node(arg0); end

    sig { params(arg0: ConstantPathAndWriteNode).returns(T::Array[T.untyped]) }
    def visit_constant_path_and_write_node(arg0); end

    sig { params(arg0: ConstantPathNode).returns(T::Array[T.untyped]) }
    def visit_constant_path_node(arg0); end

    sig { params(arg0: ConstantPathOperatorWriteNode).returns(T::Array[T.untyped]) }
    def visit_constant_path_operator_write_node(arg0); end

    sig { params(arg0: ConstantPathOrWriteNode).returns(T::Array[T.untyped]) }
    def visit_constant_path_or_write_node(arg0); end

    sig { params(arg0: ConstantPathTargetNode).returns(T::Array[T.untyped]) }
    def visit_constant_path_target_node(arg0); end

    sig { params(arg0: ConstantPathWriteNode).returns(T::Array[T.untyped]) }
    def visit_constant_path_write_node(arg0); end

    sig { params(arg0: ConstantReadNode).returns(T::Array[T.untyped]) }
    def visit_constant_read_node(arg0); end

    sig { params(arg0: ConstantTargetNode).returns(T::Array[T.untyped]) }
    def visit_constant_target_node(arg0); end

    sig { params(arg0: ConstantWriteNode).returns(T::Array[T.untyped]) }
    def visit_constant_write_node(arg0); end

    sig { params(arg0: DefNode).returns(T::Array[T.untyped]) }
    def visit_def_node(arg0); end

    sig { params(arg0: DefinedNode).returns(T::Array[T.untyped]) }
    def visit_defined_node(arg0); end

    sig { params(arg0: ElseNode).returns(T::Array[T.untyped]) }
    def visit_else_node(arg0); end

    sig { params(arg0: EmbeddedStatementsNode).returns(T::Array[T.untyped]) }
    def visit_embedded_statements_node(arg0); end

    sig { params(arg0: EmbeddedVariableNode).returns(T::Array[T.untyped]) }
    def visit_embedded_variable_node(arg0); end

    sig { params(arg0: EnsureNode).returns(T::Array[T.untyped]) }
    def visit_ensure_node(arg0); end

    sig { params(arg0: FalseNode).returns(T::Array[T.untyped]) }
    def visit_false_node(arg0); end

    sig { params(arg0: FindPatternNode).returns(T::Array[T.untyped]) }
    def visit_find_pattern_node(arg0); end

    sig { params(arg0: FlipFlopNode).returns(T::Array[T.untyped]) }
    def visit_flip_flop_node(arg0); end

    sig { params(arg0: FloatNode).returns(T::Array[T.untyped]) }
    def visit_float_node(arg0); end

    sig { params(arg0: ForNode).returns(T::Array[T.untyped]) }
    def visit_for_node(arg0); end

    sig { params(arg0: ForwardingArgumentsNode).returns(T::Array[T.untyped]) }
    def visit_forwarding_arguments_node(arg0); end

    sig { params(arg0: ForwardingParameterNode).returns(T::Array[T.untyped]) }
    def visit_forwarding_parameter_node(arg0); end

    sig { params(arg0: ForwardingSuperNode).returns(T::Array[T.untyped]) }
    def visit_forwarding_super_node(arg0); end

    sig { params(arg0: GlobalVariableAndWriteNode).returns(T::Array[T.untyped]) }
    def visit_global_variable_and_write_node(arg0); end

    sig { params(arg0: GlobalVariableOperatorWriteNode).returns(T::Array[T.untyped]) }
    def visit_global_variable_operator_write_node(arg0); end

    sig { params(arg0: GlobalVariableOrWriteNode).returns(T::Array[T.untyped]) }
    def visit_global_variable_or_write_node(arg0); end

    sig { params(arg0: GlobalVariableReadNode).returns(T::Array[T.untyped]) }
    def visit_global_variable_read_node(arg0); end

    sig { params(arg0: GlobalVariableTargetNode).returns(T::Array[T.untyped]) }
    def visit_global_variable_target_node(arg0); end

    sig { params(arg0: GlobalVariableWriteNode).returns(T::Array[T.untyped]) }
    def visit_global_variable_write_node(arg0); end

    sig { params(arg0: HashNode).returns(T::Array[T.untyped]) }
    def visit_hash_node(arg0); end

    sig { params(arg0: HashPatternNode).returns(T::Array[T.untyped]) }
    def visit_hash_pattern_node(arg0); end

    sig { params(arg0: IfNode).returns(T::Array[T.untyped]) }
    def visit_if_node(arg0); end

    sig { params(arg0: ImaginaryNode).returns(T::Array[T.untyped]) }
    def visit_imaginary_node(arg0); end

    sig { params(arg0: ImplicitNode).returns(T::Array[T.untyped]) }
    def visit_implicit_node(arg0); end

    sig { params(arg0: ImplicitRestNode).returns(T::Array[T.untyped]) }
    def visit_implicit_rest_node(arg0); end

    sig { params(arg0: InNode).returns(T::Array[T.untyped]) }
    def visit_in_node(arg0); end

    sig { params(arg0: IndexAndWriteNode).returns(T::Array[T.untyped]) }
    def visit_index_and_write_node(arg0); end

    sig { params(arg0: IndexOperatorWriteNode).returns(T::Array[T.untyped]) }
    def visit_index_operator_write_node(arg0); end

    sig { params(arg0: IndexOrWriteNode).returns(T::Array[T.untyped]) }
    def visit_index_or_write_node(arg0); end

    sig { params(arg0: IndexTargetNode).returns(T::Array[T.untyped]) }
    def visit_index_target_node(arg0); end

    sig { params(arg0: InstanceVariableAndWriteNode).returns(T::Array[T.untyped]) }
    def visit_instance_variable_and_write_node(arg0); end

    sig { params(arg0: InstanceVariableOperatorWriteNode).returns(T::Array[T.untyped]) }
    def visit_instance_variable_operator_write_node(arg0); end

    sig { params(arg0: InstanceVariableOrWriteNode).returns(T::Array[T.untyped]) }
    def visit_instance_variable_or_write_node(arg0); end

    sig { params(arg0: InstanceVariableReadNode).returns(T::Array[T.untyped]) }
    def visit_instance_variable_read_node(arg0); end

    sig { params(arg0: InstanceVariableTargetNode).returns(T::Array[T.untyped]) }
    def visit_instance_variable_target_node(arg0); end

    sig { params(arg0: InstanceVariableWriteNode).returns(T::Array[T.untyped]) }
    def visit_instance_variable_write_node(arg0); end

    sig { params(arg0: IntegerNode).returns(T::Array[T.untyped]) }
    def visit_integer_node(arg0); end

    sig { params(arg0: InterpolatedMatchLastLineNode).returns(T::Array[T.untyped]) }
    def visit_interpolated_match_last_line_node(arg0); end

    sig { params(arg0: InterpolatedRegularExpressionNode).returns(T::Array[T.untyped]) }
    def visit_interpolated_regular_expression_node(arg0); end

    sig { params(arg0: InterpolatedStringNode).returns(T::Array[T.untyped]) }
    def visit_interpolated_string_node(arg0); end

    sig { params(arg0: InterpolatedSymbolNode).returns(T::Array[T.untyped]) }
    def visit_interpolated_symbol_node(arg0); end

    sig { params(arg0: InterpolatedXStringNode).returns(T::Array[T.untyped]) }
    def visit_interpolated_x_string_node(arg0); end

    sig { params(arg0: ItLocalVariableReadNode).returns(T::Array[T.untyped]) }
    def visit_it_local_variable_read_node(arg0); end

    sig { params(arg0: ItParametersNode).returns(T::Array[T.untyped]) }
    def visit_it_parameters_node(arg0); end

    sig { params(arg0: KeywordHashNode).returns(T::Array[T.untyped]) }
    def visit_keyword_hash_node(arg0); end

    sig { params(arg0: KeywordRestParameterNode).returns(T::Array[T.untyped]) }
    def visit_keyword_rest_parameter_node(arg0); end

    sig { params(arg0: LambdaNode).returns(T::Array[T.untyped]) }
    def visit_lambda_node(arg0); end

    sig { params(arg0: LocalVariableAndWriteNode).returns(T::Array[T.untyped]) }
    def visit_local_variable_and_write_node(arg0); end

    sig { params(arg0: LocalVariableOperatorWriteNode).returns(T::Array[T.untyped]) }
    def visit_local_variable_operator_write_node(arg0); end

    sig { params(arg0: LocalVariableOrWriteNode).returns(T::Array[T.untyped]) }
    def visit_local_variable_or_write_node(arg0); end

    sig { params(arg0: LocalVariableReadNode).returns(T::Array[T.untyped]) }
    def visit_local_variable_read_node(arg0); end

    sig { params(arg0: LocalVariableTargetNode).returns(T::Array[T.untyped]) }
    def visit_local_variable_target_node(arg0); end

    sig { params(arg0: LocalVariableWriteNode).returns(T::Array[T.untyped]) }
    def visit_local_variable_write_node(arg0); end

    sig { params(arg0: MatchLastLineNode).returns(T::Array[T.untyped]) }
    def visit_match_last_line_node(arg0); end

    sig { params(arg0: MatchPredicateNode).returns(T::Array[T.untyped]) }
    def visit_match_predicate_node(arg0); end

    sig { params(arg0: MatchRequiredNode).returns(T::Array[T.untyped]) }
    def visit_match_required_node(arg0); end

    sig { params(arg0: MatchWriteNode).returns(T::Array[T.untyped]) }
    def visit_match_write_node(arg0); end

    sig { params(arg0: MissingNode).returns(T::Array[T.untyped]) }
    def visit_missing_node(arg0); end

    sig { params(arg0: ModuleNode).returns(T::Array[T.untyped]) }
    def visit_module_node(arg0); end

    sig { params(arg0: MultiTargetNode).returns(T::Array[T.untyped]) }
    def visit_multi_target_node(arg0); end

    sig { params(arg0: MultiWriteNode).returns(T::Array[T.untyped]) }
    def visit_multi_write_node(arg0); end

    sig { params(arg0: NextNode).returns(T::Array[T.untyped]) }
    def visit_next_node(arg0); end

    sig { params(arg0: NilNode).returns(T::Array[T.untyped]) }
    def visit_nil_node(arg0); end

    sig { params(arg0: NoBlockParameterNode).returns(T::Array[T.untyped]) }
    def visit_no_block_parameter_node(arg0); end

    sig { params(arg0: NoKeywordsParameterNode).returns(T::Array[T.untyped]) }
    def visit_no_keywords_parameter_node(arg0); end

    sig { params(arg0: NumberedParametersNode).returns(T::Array[T.untyped]) }
    def visit_numbered_parameters_node(arg0); end

    sig { params(arg0: NumberedReferenceReadNode).returns(T::Array[T.untyped]) }
    def visit_numbered_reference_read_node(arg0); end

    sig { params(arg0: OptionalKeywordParameterNode).returns(T::Array[T.untyped]) }
    def visit_optional_keyword_parameter_node(arg0); end

    sig { params(arg0: OptionalParameterNode).returns(T::Array[T.untyped]) }
    def visit_optional_parameter_node(arg0); end

    sig { params(arg0: OrNode).returns(T::Array[T.untyped]) }
    def visit_or_node(arg0); end

    sig { params(arg0: ParametersNode).returns(T::Array[T.untyped]) }
    def visit_parameters_node(arg0); end

    sig { params(arg0: ParenthesesNode).returns(T::Array[T.untyped]) }
    def visit_parentheses_node(arg0); end

    sig { params(arg0: PinnedExpressionNode).returns(T::Array[T.untyped]) }
    def visit_pinned_expression_node(arg0); end

    sig { params(arg0: PinnedVariableNode).returns(T::Array[T.untyped]) }
    def visit_pinned_variable_node(arg0); end

    sig { params(arg0: PostExecutionNode).returns(T::Array[T.untyped]) }
    def visit_post_execution_node(arg0); end

    sig { params(arg0: PreExecutionNode).returns(T::Array[T.untyped]) }
    def visit_pre_execution_node(arg0); end

    sig { params(arg0: ProgramNode).returns(T::Array[T.untyped]) }
    def visit_program_node(arg0); end

    sig { params(arg0: RangeNode).returns(T::Array[T.untyped]) }
    def visit_range_node(arg0); end

    sig { params(arg0: RationalNode).returns(T::Array[T.untyped]) }
    def visit_rational_node(arg0); end

    sig { params(arg0: RedoNode).returns(T::Array[T.untyped]) }
    def visit_redo_node(arg0); end

    sig { params(arg0: RegularExpressionNode).returns(T::Array[T.untyped]) }
    def visit_regular_expression_node(arg0); end

    sig { params(arg0: RequiredKeywordParameterNode).returns(T::Array[T.untyped]) }
    def visit_required_keyword_parameter_node(arg0); end

    sig { params(arg0: RequiredParameterNode).returns(T::Array[T.untyped]) }
    def visit_required_parameter_node(arg0); end

    sig { params(arg0: RescueModifierNode).returns(T::Array[T.untyped]) }
    def visit_rescue_modifier_node(arg0); end

    sig { params(arg0: RescueNode).returns(T::Array[T.untyped]) }
    def visit_rescue_node(arg0); end

    sig { params(arg0: RestParameterNode).returns(T::Array[T.untyped]) }
    def visit_rest_parameter_node(arg0); end

    sig { params(arg0: RetryNode).returns(T::Array[T.untyped]) }
    def visit_retry_node(arg0); end

    sig { params(arg0: ReturnNode).returns(T::Array[T.untyped]) }
    def visit_return_node(arg0); end

    sig { params(arg0: SelfNode).returns(T::Array[T.untyped]) }
    def visit_self_node(arg0); end

    sig { params(arg0: ShareableConstantNode).returns(T::Array[T.untyped]) }
    def visit_shareable_constant_node(arg0); end

    sig { params(arg0: SingletonClassNode).returns(T::Array[T.untyped]) }
    def visit_singleton_class_node(arg0); end

    sig { params(arg0: SourceEncodingNode).returns(T::Array[T.untyped]) }
    def visit_source_encoding_node(arg0); end

    sig { params(arg0: SourceFileNode).returns(T::Array[T.untyped]) }
    def visit_source_file_node(arg0); end

    sig { params(arg0: SourceLineNode).returns(T::Array[T.untyped]) }
    def visit_source_line_node(arg0); end

    sig { params(arg0: SplatNode).returns(T::Array[T.untyped]) }
    def visit_splat_node(arg0); end

    sig { params(arg0: StatementsNode).returns(T::Array[T.untyped]) }
    def visit_statements_node(arg0); end

    sig { params(arg0: StringNode).returns(T::Array[T.untyped]) }
    def visit_string_node(arg0); end

    sig { params(arg0: SuperNode).returns(T::Array[T.untyped]) }
    def visit_super_node(arg0); end

    sig { params(arg0: SymbolNode).returns(T::Array[T.untyped]) }
    def visit_symbol_node(arg0); end

    sig { params(arg0: TrueNode).returns(T::Array[T.untyped]) }
    def visit_true_node(arg0); end

    sig { params(arg0: UndefNode).returns(T::Array[T.untyped]) }
    def visit_undef_node(arg0); end

    sig { params(arg0: UnlessNode).returns(T::Array[T.untyped]) }
    def visit_unless_node(arg0); end

    sig { params(arg0: UntilNode).returns(T::Array[T.untyped]) }
    def visit_until_node(arg0); end

    sig { params(arg0: WhenNode).returns(T::Array[T.untyped]) }
    def visit_when_node(arg0); end

    sig { params(arg0: WhileNode).returns(T::Array[T.untyped]) }
    def visit_while_node(arg0); end

    sig { params(arg0: XStringNode).returns(T::Array[T.untyped]) }
    def visit_x_string_node(arg0); end

    sig { params(arg0: YieldNode).returns(T::Array[T.untyped]) }
    def visit_yield_node(arg0); end
  end
end
