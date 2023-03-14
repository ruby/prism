IfNode(
  KEYWORD_IF("if"),
  CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
  StatementsNode(
    [CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar")]
  ),
  nil,
  KEYWORD_END("end")
)
