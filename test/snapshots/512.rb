TernaryNode(
  CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a"),
  QUESTION_MARK("?"),
  DefinedNode(
    nil,
    CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b"),
    nil,
    (4..12)
  ),
  COLON(":"),
  DefinedNode(
    nil,
    CallNode(nil, nil, IDENTIFIER("c"), nil, nil, nil, nil, "c"),
    nil,
    (17..25)
  )
)
