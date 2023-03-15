IfNode(
  KEYWORD_IF_MODIFIER("if"),
  CallNode(nil, nil, IDENTIFIER("c"), nil, nil, nil, nil, "c"),
  StatementsNode(
    [IfNode(
       KEYWORD_IF_MODIFIER("if"),
       CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b"),
       StatementsNode(
         [CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")]
       ),
       nil,
       nil
     )]
  ),
  nil,
  nil
)
