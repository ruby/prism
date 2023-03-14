DefinedNode(
  PARENTHESIS_LEFT("("),
  AndNode(
    CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
    CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar"),
    KEYWORD_AND("and")
  ),
  PARENTHESIS_RIGHT(")"),
  (0..8)
)
