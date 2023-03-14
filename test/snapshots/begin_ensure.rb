BeginNode(
  KEYWORD_BEGIN("begin"),
  StatementsNode(
    [CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")]
  ),
  nil,
  nil,
  EnsureNode(
    KEYWORD_ENSURE("ensure"),
    StatementsNode(
      [CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]
    ),
    KEYWORD_END("end")
  ),
  KEYWORD_END("end")
)
