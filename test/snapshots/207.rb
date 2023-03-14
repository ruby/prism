DefNode(
  CONSTANT("C"),
  ParenthesesNode(
    LocalVariableWriteNode(
      IDENTIFIER("a"),
      EQUAL("="),
      CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")
    ),
    (4..5),
    (10..11)
  ),
  ParametersNode([], [], nil, [], nil, nil),
  StatementsNode([]),
  Scope([]),
  (0..3),
  (11..12),
  nil,
  nil,
  nil,
  (14..17)
)
