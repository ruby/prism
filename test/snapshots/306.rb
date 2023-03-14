CallNode(
  nil,
  nil,
  IDENTIFIER("foo"),
  nil,
  nil,
  nil,
  BlockNode(
    BlockParametersNode(
      ParametersNode(
        [RequiredParameterNode(IDENTIFIER("x"))],
        [OptionalParameterNode(IDENTIFIER("y"), EQUAL("="), IntegerNode())],
        nil,
        [KeywordParameterNode(LABEL("z:"), nil)],
        nil,
        nil
      ),
      []
    ),
    StatementsNode([LocalVariableReadNode(IDENTIFIER("x"))]),
    (4..5),
    (23..24)
  ),
  "foo"
)
