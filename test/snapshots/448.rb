LambdaNode(
  Scope(
    [IDENTIFIER("a"), IDENTIFIER("b"), LABEL("c"), LABEL("d"), IDENTIFIER("e")]
  ),
  nil,
  BlockParametersNode(
    ParametersNode(
      [RequiredParameterNode(IDENTIFIER("a"))],
      [OptionalParameterNode(IDENTIFIER("b"), EQUAL("="), IntegerNode())],
      nil,
      [KeywordParameterNode(LABEL("c:"), nil),
       KeywordParameterNode(LABEL("d:"), nil)],
      nil,
      BlockParameterNode(IDENTIFIER("e"), (21..22))
    ),
    []
  ),
  nil,
  StatementsNode([LocalVariableReadNode(IDENTIFIER("a"))])
)
