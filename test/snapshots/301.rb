DefNode(
  IDENTIFIER("a"),
  nil,
  ParametersNode([], [], RestParameterNode(STAR("*"), nil), [], nil, nil),
  StatementsNode(
    [CallNode(
       nil,
       nil,
       IDENTIFIER("b"),
       PARENTHESIS_LEFT("("),
       ArgumentsNode([SplatNode(STAR("*"), nil)]),
       PARENTHESIS_RIGHT(")"),
       nil,
       "b"
     )]
  ),
  Scope([STAR("*")]),
  (0..3),
  nil,
  (5..6),
  (7..8),
  nil,
  (16..19)
)
