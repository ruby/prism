BeginNode(
  KEYWORD_BEGIN("begin"),
  StatementsNode(
    [CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")]
  ),
  RescueNode(
    KEYWORD_RESCUE("rescue"),
    [],
    nil,
    nil,
    StatementsNode(
      [CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]
    ),
    nil
  ),
  ElseNode(
    KEYWORD_ELSE("else"),
    StatementsNode(
      [CallNode(nil, nil, IDENTIFIER("c"), nil, nil, nil, nil, "c")]
    ),
    SEMICOLON(";")
  ),
  EnsureNode(
    KEYWORD_ENSURE("ensure"),
    StatementsNode(
      [CallNode(nil, nil, IDENTIFIER("d"), nil, nil, nil, nil, "d")]
    ),
    KEYWORD_END("end")
  ),
  KEYWORD_END("end")
)
