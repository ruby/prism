CallNode(
  nil,
  nil,
  IDENTIFIER("foo"),
  PARENTHESIS_LEFT("("),
  ArgumentsNode(
    [SplatNode(
       STAR("*"),
       CallNode(nil, nil, IDENTIFIER("rest"), nil, nil, nil, nil, "rest")
     )]
  ),
  PARENTHESIS_RIGHT(")"),
  nil,
  "foo"
)
