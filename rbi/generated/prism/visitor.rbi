# typed: true

module Prism
  # A class that knows how to walk down the tree. None of the individual visit
  # methods are implemented on this visitor, so it forces the consumer to
  # implement each one that they need. For a default implementation that
  # continues walking the tree, see the Visitor class.
  class BasicVisitor
    # Calls `accept` on the given node if it is not `nil`, which in turn should
    # call back into this visitor by calling the appropriate `visit_*` method.
    sig { params(node: T.nilable(Node)).void }
    def visit(node); end

    # Visits each node in `nodes` by calling `accept` on each one.
    sig { params(nodes: T::Array[T.nilable(Node)]).void }
    def visit_all(nodes); end

    # Visits the child nodes of `node` by calling `accept` on each one.
    sig { params(node: Node).void }
    def visit_child_nodes(node); end
  end

  # A visitor is a class that provides a default implementation for every accept
  # method defined on the nodes. This means it can walk a tree without the
  # caller needing to define any special handling. This allows you to handle a
  # subset of the tree, while still walking the whole tree.
  #
  # For example, to find all of the method calls that call the `foo` method, you
  # could write:
  #
  #     class FooCalls < Prism::Visitor
  #       def visit_call_node(node)
  #         if node.name == :foo
  #           # Do something with the node
  #         end
  #
  #         # Call super so that the visitor continues walking the tree
  #         super
  #       end
  #     end
  class Visitor < BasicVisitor
    # Visit a AliasGlobalVariableNode node
    sig { params(node: AliasGlobalVariableNode).void }
    def visit_alias_global_variable_node(node); end

    # Visit a AliasMethodNode node
    sig { params(node: AliasMethodNode).void }
    def visit_alias_method_node(node); end

    # Visit a AlternationPatternNode node
    sig { params(node: AlternationPatternNode).void }
    def visit_alternation_pattern_node(node); end

    # Visit a AndNode node
    sig { params(node: AndNode).void }
    def visit_and_node(node); end

    # Visit a ArgumentsNode node
    sig { params(node: ArgumentsNode).void }
    def visit_arguments_node(node); end

    # Visit a ArrayNode node
    sig { params(node: ArrayNode).void }
    def visit_array_node(node); end

    # Visit a ArrayPatternNode node
    sig { params(node: ArrayPatternNode).void }
    def visit_array_pattern_node(node); end

    # Visit a AssocNode node
    sig { params(node: AssocNode).void }
    def visit_assoc_node(node); end

    # Visit a AssocSplatNode node
    sig { params(node: AssocSplatNode).void }
    def visit_assoc_splat_node(node); end

    # Visit a BackReferenceReadNode node
    sig { params(node: BackReferenceReadNode).void }
    def visit_back_reference_read_node(node); end

    # Visit a BeginNode node
    sig { params(node: BeginNode).void }
    def visit_begin_node(node); end

    # Visit a BlockArgumentNode node
    sig { params(node: BlockArgumentNode).void }
    def visit_block_argument_node(node); end

    # Visit a BlockLocalVariableNode node
    sig { params(node: BlockLocalVariableNode).void }
    def visit_block_local_variable_node(node); end

    # Visit a BlockNode node
    sig { params(node: BlockNode).void }
    def visit_block_node(node); end

    # Visit a BlockParameterNode node
    sig { params(node: BlockParameterNode).void }
    def visit_block_parameter_node(node); end

    # Visit a BlockParametersNode node
    sig { params(node: BlockParametersNode).void }
    def visit_block_parameters_node(node); end

    # Visit a BreakNode node
    sig { params(node: BreakNode).void }
    def visit_break_node(node); end

    # Visit a CallAndWriteNode node
    sig { params(node: CallAndWriteNode).void }
    def visit_call_and_write_node(node); end

    # Visit a CallNode node
    sig { params(node: CallNode).void }
    def visit_call_node(node); end

    # Visit a CallOperatorWriteNode node
    sig { params(node: CallOperatorWriteNode).void }
    def visit_call_operator_write_node(node); end

    # Visit a CallOrWriteNode node
    sig { params(node: CallOrWriteNode).void }
    def visit_call_or_write_node(node); end

    # Visit a CallTargetNode node
    sig { params(node: CallTargetNode).void }
    def visit_call_target_node(node); end

    # Visit a CapturePatternNode node
    sig { params(node: CapturePatternNode).void }
    def visit_capture_pattern_node(node); end

    # Visit a CaseMatchNode node
    sig { params(node: CaseMatchNode).void }
    def visit_case_match_node(node); end

    # Visit a CaseNode node
    sig { params(node: CaseNode).void }
    def visit_case_node(node); end

    # Visit a ClassNode node
    sig { params(node: ClassNode).void }
    def visit_class_node(node); end

    # Visit a ClassVariableAndWriteNode node
    sig { params(node: ClassVariableAndWriteNode).void }
    def visit_class_variable_and_write_node(node); end

    # Visit a ClassVariableOperatorWriteNode node
    sig { params(node: ClassVariableOperatorWriteNode).void }
    def visit_class_variable_operator_write_node(node); end

    # Visit a ClassVariableOrWriteNode node
    sig { params(node: ClassVariableOrWriteNode).void }
    def visit_class_variable_or_write_node(node); end

    # Visit a ClassVariableReadNode node
    sig { params(node: ClassVariableReadNode).void }
    def visit_class_variable_read_node(node); end

    # Visit a ClassVariableTargetNode node
    sig { params(node: ClassVariableTargetNode).void }
    def visit_class_variable_target_node(node); end

    # Visit a ClassVariableWriteNode node
    sig { params(node: ClassVariableWriteNode).void }
    def visit_class_variable_write_node(node); end

    # Visit a ConstantAndWriteNode node
    sig { params(node: ConstantAndWriteNode).void }
    def visit_constant_and_write_node(node); end

    # Visit a ConstantOperatorWriteNode node
    sig { params(node: ConstantOperatorWriteNode).void }
    def visit_constant_operator_write_node(node); end

    # Visit a ConstantOrWriteNode node
    sig { params(node: ConstantOrWriteNode).void }
    def visit_constant_or_write_node(node); end

    # Visit a ConstantPathAndWriteNode node
    sig { params(node: ConstantPathAndWriteNode).void }
    def visit_constant_path_and_write_node(node); end

    # Visit a ConstantPathNode node
    sig { params(node: ConstantPathNode).void }
    def visit_constant_path_node(node); end

    # Visit a ConstantPathOperatorWriteNode node
    sig { params(node: ConstantPathOperatorWriteNode).void }
    def visit_constant_path_operator_write_node(node); end

    # Visit a ConstantPathOrWriteNode node
    sig { params(node: ConstantPathOrWriteNode).void }
    def visit_constant_path_or_write_node(node); end

    # Visit a ConstantPathTargetNode node
    sig { params(node: ConstantPathTargetNode).void }
    def visit_constant_path_target_node(node); end

    # Visit a ConstantPathWriteNode node
    sig { params(node: ConstantPathWriteNode).void }
    def visit_constant_path_write_node(node); end

    # Visit a ConstantReadNode node
    sig { params(node: ConstantReadNode).void }
    def visit_constant_read_node(node); end

    # Visit a ConstantTargetNode node
    sig { params(node: ConstantTargetNode).void }
    def visit_constant_target_node(node); end

    # Visit a ConstantWriteNode node
    sig { params(node: ConstantWriteNode).void }
    def visit_constant_write_node(node); end

    # Visit a DefNode node
    sig { params(node: DefNode).void }
    def visit_def_node(node); end

    # Visit a DefinedNode node
    sig { params(node: DefinedNode).void }
    def visit_defined_node(node); end

    # Visit a ElseNode node
    sig { params(node: ElseNode).void }
    def visit_else_node(node); end

    # Visit a EmbeddedStatementsNode node
    sig { params(node: EmbeddedStatementsNode).void }
    def visit_embedded_statements_node(node); end

    # Visit a EmbeddedVariableNode node
    sig { params(node: EmbeddedVariableNode).void }
    def visit_embedded_variable_node(node); end

    # Visit a EnsureNode node
    sig { params(node: EnsureNode).void }
    def visit_ensure_node(node); end

    # Visit a FalseNode node
    sig { params(node: FalseNode).void }
    def visit_false_node(node); end

    # Visit a FindPatternNode node
    sig { params(node: FindPatternNode).void }
    def visit_find_pattern_node(node); end

    # Visit a FlipFlopNode node
    sig { params(node: FlipFlopNode).void }
    def visit_flip_flop_node(node); end

    # Visit a FloatNode node
    sig { params(node: FloatNode).void }
    def visit_float_node(node); end

    # Visit a ForNode node
    sig { params(node: ForNode).void }
    def visit_for_node(node); end

    # Visit a ForwardingArgumentsNode node
    sig { params(node: ForwardingArgumentsNode).void }
    def visit_forwarding_arguments_node(node); end

    # Visit a ForwardingParameterNode node
    sig { params(node: ForwardingParameterNode).void }
    def visit_forwarding_parameter_node(node); end

    # Visit a ForwardingSuperNode node
    sig { params(node: ForwardingSuperNode).void }
    def visit_forwarding_super_node(node); end

    # Visit a GlobalVariableAndWriteNode node
    sig { params(node: GlobalVariableAndWriteNode).void }
    def visit_global_variable_and_write_node(node); end

    # Visit a GlobalVariableOperatorWriteNode node
    sig { params(node: GlobalVariableOperatorWriteNode).void }
    def visit_global_variable_operator_write_node(node); end

    # Visit a GlobalVariableOrWriteNode node
    sig { params(node: GlobalVariableOrWriteNode).void }
    def visit_global_variable_or_write_node(node); end

    # Visit a GlobalVariableReadNode node
    sig { params(node: GlobalVariableReadNode).void }
    def visit_global_variable_read_node(node); end

    # Visit a GlobalVariableTargetNode node
    sig { params(node: GlobalVariableTargetNode).void }
    def visit_global_variable_target_node(node); end

    # Visit a GlobalVariableWriteNode node
    sig { params(node: GlobalVariableWriteNode).void }
    def visit_global_variable_write_node(node); end

    # Visit a HashNode node
    sig { params(node: HashNode).void }
    def visit_hash_node(node); end

    # Visit a HashPatternNode node
    sig { params(node: HashPatternNode).void }
    def visit_hash_pattern_node(node); end

    # Visit a IfNode node
    sig { params(node: IfNode).void }
    def visit_if_node(node); end

    # Visit a ImaginaryNode node
    sig { params(node: ImaginaryNode).void }
    def visit_imaginary_node(node); end

    # Visit a ImplicitNode node
    sig { params(node: ImplicitNode).void }
    def visit_implicit_node(node); end

    # Visit a ImplicitRestNode node
    sig { params(node: ImplicitRestNode).void }
    def visit_implicit_rest_node(node); end

    # Visit a InNode node
    sig { params(node: InNode).void }
    def visit_in_node(node); end

    # Visit a IndexAndWriteNode node
    sig { params(node: IndexAndWriteNode).void }
    def visit_index_and_write_node(node); end

    # Visit a IndexOperatorWriteNode node
    sig { params(node: IndexOperatorWriteNode).void }
    def visit_index_operator_write_node(node); end

    # Visit a IndexOrWriteNode node
    sig { params(node: IndexOrWriteNode).void }
    def visit_index_or_write_node(node); end

    # Visit a IndexTargetNode node
    sig { params(node: IndexTargetNode).void }
    def visit_index_target_node(node); end

    # Visit a InstanceVariableAndWriteNode node
    sig { params(node: InstanceVariableAndWriteNode).void }
    def visit_instance_variable_and_write_node(node); end

    # Visit a InstanceVariableOperatorWriteNode node
    sig { params(node: InstanceVariableOperatorWriteNode).void }
    def visit_instance_variable_operator_write_node(node); end

    # Visit a InstanceVariableOrWriteNode node
    sig { params(node: InstanceVariableOrWriteNode).void }
    def visit_instance_variable_or_write_node(node); end

    # Visit a InstanceVariableReadNode node
    sig { params(node: InstanceVariableReadNode).void }
    def visit_instance_variable_read_node(node); end

    # Visit a InstanceVariableTargetNode node
    sig { params(node: InstanceVariableTargetNode).void }
    def visit_instance_variable_target_node(node); end

    # Visit a InstanceVariableWriteNode node
    sig { params(node: InstanceVariableWriteNode).void }
    def visit_instance_variable_write_node(node); end

    # Visit a IntegerNode node
    sig { params(node: IntegerNode).void }
    def visit_integer_node(node); end

    # Visit a InterpolatedMatchLastLineNode node
    sig { params(node: InterpolatedMatchLastLineNode).void }
    def visit_interpolated_match_last_line_node(node); end

    # Visit a InterpolatedRegularExpressionNode node
    sig { params(node: InterpolatedRegularExpressionNode).void }
    def visit_interpolated_regular_expression_node(node); end

    # Visit a InterpolatedStringNode node
    sig { params(node: InterpolatedStringNode).void }
    def visit_interpolated_string_node(node); end

    # Visit a InterpolatedSymbolNode node
    sig { params(node: InterpolatedSymbolNode).void }
    def visit_interpolated_symbol_node(node); end

    # Visit a InterpolatedXStringNode node
    sig { params(node: InterpolatedXStringNode).void }
    def visit_interpolated_x_string_node(node); end

    # Visit a ItLocalVariableReadNode node
    sig { params(node: ItLocalVariableReadNode).void }
    def visit_it_local_variable_read_node(node); end

    # Visit a ItParametersNode node
    sig { params(node: ItParametersNode).void }
    def visit_it_parameters_node(node); end

    # Visit a KeywordHashNode node
    sig { params(node: KeywordHashNode).void }
    def visit_keyword_hash_node(node); end

    # Visit a KeywordRestParameterNode node
    sig { params(node: KeywordRestParameterNode).void }
    def visit_keyword_rest_parameter_node(node); end

    # Visit a LambdaNode node
    sig { params(node: LambdaNode).void }
    def visit_lambda_node(node); end

    # Visit a LocalVariableAndWriteNode node
    sig { params(node: LocalVariableAndWriteNode).void }
    def visit_local_variable_and_write_node(node); end

    # Visit a LocalVariableOperatorWriteNode node
    sig { params(node: LocalVariableOperatorWriteNode).void }
    def visit_local_variable_operator_write_node(node); end

    # Visit a LocalVariableOrWriteNode node
    sig { params(node: LocalVariableOrWriteNode).void }
    def visit_local_variable_or_write_node(node); end

    # Visit a LocalVariableReadNode node
    sig { params(node: LocalVariableReadNode).void }
    def visit_local_variable_read_node(node); end

    # Visit a LocalVariableTargetNode node
    sig { params(node: LocalVariableTargetNode).void }
    def visit_local_variable_target_node(node); end

    # Visit a LocalVariableWriteNode node
    sig { params(node: LocalVariableWriteNode).void }
    def visit_local_variable_write_node(node); end

    # Visit a MatchLastLineNode node
    sig { params(node: MatchLastLineNode).void }
    def visit_match_last_line_node(node); end

    # Visit a MatchPredicateNode node
    sig { params(node: MatchPredicateNode).void }
    def visit_match_predicate_node(node); end

    # Visit a MatchRequiredNode node
    sig { params(node: MatchRequiredNode).void }
    def visit_match_required_node(node); end

    # Visit a MatchWriteNode node
    sig { params(node: MatchWriteNode).void }
    def visit_match_write_node(node); end

    # Visit a MissingNode node
    sig { params(node: MissingNode).void }
    def visit_missing_node(node); end

    # Visit a ModuleNode node
    sig { params(node: ModuleNode).void }
    def visit_module_node(node); end

    # Visit a MultiTargetNode node
    sig { params(node: MultiTargetNode).void }
    def visit_multi_target_node(node); end

    # Visit a MultiWriteNode node
    sig { params(node: MultiWriteNode).void }
    def visit_multi_write_node(node); end

    # Visit a NextNode node
    sig { params(node: NextNode).void }
    def visit_next_node(node); end

    # Visit a NilNode node
    sig { params(node: NilNode).void }
    def visit_nil_node(node); end

    # Visit a NoBlockParameterNode node
    sig { params(node: NoBlockParameterNode).void }
    def visit_no_block_parameter_node(node); end

    # Visit a NoKeywordsParameterNode node
    sig { params(node: NoKeywordsParameterNode).void }
    def visit_no_keywords_parameter_node(node); end

    # Visit a NumberedParametersNode node
    sig { params(node: NumberedParametersNode).void }
    def visit_numbered_parameters_node(node); end

    # Visit a NumberedReferenceReadNode node
    sig { params(node: NumberedReferenceReadNode).void }
    def visit_numbered_reference_read_node(node); end

    # Visit a OptionalKeywordParameterNode node
    sig { params(node: OptionalKeywordParameterNode).void }
    def visit_optional_keyword_parameter_node(node); end

    # Visit a OptionalParameterNode node
    sig { params(node: OptionalParameterNode).void }
    def visit_optional_parameter_node(node); end

    # Visit a OrNode node
    sig { params(node: OrNode).void }
    def visit_or_node(node); end

    # Visit a ParametersNode node
    sig { params(node: ParametersNode).void }
    def visit_parameters_node(node); end

    # Visit a ParenthesesNode node
    sig { params(node: ParenthesesNode).void }
    def visit_parentheses_node(node); end

    # Visit a PinnedExpressionNode node
    sig { params(node: PinnedExpressionNode).void }
    def visit_pinned_expression_node(node); end

    # Visit a PinnedVariableNode node
    sig { params(node: PinnedVariableNode).void }
    def visit_pinned_variable_node(node); end

    # Visit a PostExecutionNode node
    sig { params(node: PostExecutionNode).void }
    def visit_post_execution_node(node); end

    # Visit a PreExecutionNode node
    sig { params(node: PreExecutionNode).void }
    def visit_pre_execution_node(node); end

    # Visit a ProgramNode node
    sig { params(node: ProgramNode).void }
    def visit_program_node(node); end

    # Visit a RangeNode node
    sig { params(node: RangeNode).void }
    def visit_range_node(node); end

    # Visit a RationalNode node
    sig { params(node: RationalNode).void }
    def visit_rational_node(node); end

    # Visit a RedoNode node
    sig { params(node: RedoNode).void }
    def visit_redo_node(node); end

    # Visit a RegularExpressionNode node
    sig { params(node: RegularExpressionNode).void }
    def visit_regular_expression_node(node); end

    # Visit a RequiredKeywordParameterNode node
    sig { params(node: RequiredKeywordParameterNode).void }
    def visit_required_keyword_parameter_node(node); end

    # Visit a RequiredParameterNode node
    sig { params(node: RequiredParameterNode).void }
    def visit_required_parameter_node(node); end

    # Visit a RescueModifierNode node
    sig { params(node: RescueModifierNode).void }
    def visit_rescue_modifier_node(node); end

    # Visit a RescueNode node
    sig { params(node: RescueNode).void }
    def visit_rescue_node(node); end

    # Visit a RestParameterNode node
    sig { params(node: RestParameterNode).void }
    def visit_rest_parameter_node(node); end

    # Visit a RetryNode node
    sig { params(node: RetryNode).void }
    def visit_retry_node(node); end

    # Visit a ReturnNode node
    sig { params(node: ReturnNode).void }
    def visit_return_node(node); end

    # Visit a SelfNode node
    sig { params(node: SelfNode).void }
    def visit_self_node(node); end

    # Visit a ShareableConstantNode node
    sig { params(node: ShareableConstantNode).void }
    def visit_shareable_constant_node(node); end

    # Visit a SingletonClassNode node
    sig { params(node: SingletonClassNode).void }
    def visit_singleton_class_node(node); end

    # Visit a SourceEncodingNode node
    sig { params(node: SourceEncodingNode).void }
    def visit_source_encoding_node(node); end

    # Visit a SourceFileNode node
    sig { params(node: SourceFileNode).void }
    def visit_source_file_node(node); end

    # Visit a SourceLineNode node
    sig { params(node: SourceLineNode).void }
    def visit_source_line_node(node); end

    # Visit a SplatNode node
    sig { params(node: SplatNode).void }
    def visit_splat_node(node); end

    # Visit a StatementsNode node
    sig { params(node: StatementsNode).void }
    def visit_statements_node(node); end

    # Visit a StringNode node
    sig { params(node: StringNode).void }
    def visit_string_node(node); end

    # Visit a SuperNode node
    sig { params(node: SuperNode).void }
    def visit_super_node(node); end

    # Visit a SymbolNode node
    sig { params(node: SymbolNode).void }
    def visit_symbol_node(node); end

    # Visit a TrueNode node
    sig { params(node: TrueNode).void }
    def visit_true_node(node); end

    # Visit a UndefNode node
    sig { params(node: UndefNode).void }
    def visit_undef_node(node); end

    # Visit a UnlessNode node
    sig { params(node: UnlessNode).void }
    def visit_unless_node(node); end

    # Visit a UntilNode node
    sig { params(node: UntilNode).void }
    def visit_until_node(node); end

    # Visit a WhenNode node
    sig { params(node: WhenNode).void }
    def visit_when_node(node); end

    # Visit a WhileNode node
    sig { params(node: WhileNode).void }
    def visit_while_node(node); end

    # Visit a XStringNode node
    sig { params(node: XStringNode).void }
    def visit_x_string_node(node); end

    # Visit a YieldNode node
    sig { params(node: YieldNode).void }
    def visit_yield_node(node); end
  end
end
