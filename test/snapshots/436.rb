CallNode(
  CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
  nil,
  BRACKET_LEFT_RIGHT_EQUAL("["),
  BRACKET_LEFT("["),
  ArgumentsNode(
    [CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar"),
     CallNode(nil, nil, IDENTIFIER("baz"), nil, nil, nil, nil, "baz")]
  ),
  BRACKET_RIGHT("]"),
  nil,
  "[]="
)
