LambdaNode(
  Scope([IDENTIFIER("a"), IDENTIFIER("b"), IDENTIFIER("c"), IDENTIFIER("d")]),
  PARENTHESIS_LEFT("("),
  BlockParametersNode(
    ParametersNode(
      [RequiredParameterNode(IDENTIFIER("a"))],
      [],
      nil,
      [],
      nil,
      nil
    ),
    [IDENTIFIER("b"), IDENTIFIER("c"), IDENTIFIER("d")]
  ),
  PARENTHESIS_RIGHT(")"),
  StatementsNode([LocalVariableReadNode(IDENTIFIER("b"))])
)
