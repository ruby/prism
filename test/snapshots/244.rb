DefinedNode(
  PARENTHESIS_LEFT("("),
  OperatorAssignmentNode(
    LocalVariableWriteNode(IDENTIFIER("x"), nil, nil),
    PERCENT_EQUAL("%="),
    IntegerNode()
  ),
  PARENTHESIS_RIGHT(")"),
  (0..8)
)
