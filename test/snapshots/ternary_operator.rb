TernaryNode(
  CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a"),
  QUESTION_MARK("?"),
  DefinedNode(
    nil,
    CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b"),
    nil,
    (15..23)
  ),
  COLON(":"),
  DefinedNode(
    nil,
    CallNode(nil, nil, IDENTIFIER("c"), nil, nil, nil, nil, "c"),
    nil,
    (28..36)
  )
)
