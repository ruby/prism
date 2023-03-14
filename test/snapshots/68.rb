BeginNode(
  KEYWORD_BEGIN("begin"),
  StatementsNode(
    [CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")]
  ),
  RescueNode(
    KEYWORD_RESCUE("rescue"),
    [ConstantReadNode()],
    EQUAL_GREATER("=>"),
    LocalVariableWriteNode(IDENTIFIER("ex"), nil, nil),
    StatementsNode(
      [CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]
    ),
    RescueNode(
      KEYWORD_RESCUE("rescue"),
      [ConstantReadNode(), ConstantReadNode()],
      EQUAL_GREATER("=>"),
      LocalVariableWriteNode(IDENTIFIER("ex"), nil, nil),
      StatementsNode(
        [CallNode(nil, nil, IDENTIFIER("c"), nil, nil, nil, nil, "c")]
      ),
      nil
    )
  ),
  nil,
  nil,
  KEYWORD_END("end")
)
