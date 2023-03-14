BeginNode(
  KEYWORD_BEGIN("begin"),
  StatementsNode(
    [CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")]
  ),
  RescueNode(
    KEYWORD_RESCUE("rescue"),
    [ConstantReadNode(), ConstantReadNode()],
    nil,
    nil,
    StatementsNode(
      [CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]
    ),
    nil
  ),
  nil,
  nil,
  KEYWORD_END("end")
)
