BeginNode(
  KEYWORD_BEGIN("begin"),
  StatementsNode(
    [CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")]
  ),
  RescueNode(
    KEYWORD_RESCUE("rescue"),
    [SplatNode(
       STAR("*"),
       CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")
     )],
    nil,
    nil,
    StatementsNode([]),
    nil
  ),
  nil,
  nil,
  KEYWORD_END("end")
)
