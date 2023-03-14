LambdaNode(
  Scope(
    [IDENTIFIER("a"),
     IDENTIFIER("b"),
     IDENTIFIER("c"),
     LABEL("d"),
     LABEL("e"),
     IDENTIFIER("f"),
     IDENTIFIER("g")]
  ),
  PARENTHESIS_LEFT("("),
  BlockParametersNode(
    ParametersNode(
      [RequiredParameterNode(IDENTIFIER("a"))],
      [OptionalParameterNode(IDENTIFIER("b"), EQUAL("="), IntegerNode())],
      RestParameterNode(STAR("*"), IDENTIFIER("c")),
      [KeywordParameterNode(LABEL("d:"), nil),
       KeywordParameterNode(LABEL("e:"), nil)],
      KeywordRestParameterNode(STAR_STAR("**"), IDENTIFIER("f")),
      BlockParameterNode(IDENTIFIER("g"), (31..32))
    ),
    []
  ),
  PARENTHESIS_RIGHT(")"),
  StatementsNode([LocalVariableReadNode(IDENTIFIER("a"))])
)
