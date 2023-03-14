CallNode(
  CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a"),
  DOT("."),
  IDENTIFIER("b"),
  PARENTHESIS_LEFT("("),
  ArgumentsNode(
    [CallNode(nil, nil, IDENTIFIER("c"), nil, nil, nil, nil, "c"),
     CallNode(nil, nil, IDENTIFIER("d"), nil, nil, nil, nil, "d")]
  ),
  PARENTHESIS_RIGHT(")"),
  nil,
  "b"
)
