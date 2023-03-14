CallNode(
  nil,
  nil,
  IDENTIFIER("a"),
  PARENTHESIS_LEFT("("),
  ArgumentsNode(
    [SplatNode(
       STAR("*"),
       CallNode(nil, nil, IDENTIFIER("args"), nil, nil, nil, nil, "args")
     )]
  ),
  PARENTHESIS_RIGHT(")"),
  nil,
  "a"
)
