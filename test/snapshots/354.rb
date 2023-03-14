AndNode(
  CallNode(
    CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
    nil,
    KEYWORD_NOT("not"),
    nil,
    nil,
    nil,
    nil,
    "!"
  ),
  CallNode(
    CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar"),
    nil,
    KEYWORD_NOT("not"),
    nil,
    nil,
    nil,
    nil,
    "!"
  ),
  KEYWORD_AND("and")
)
