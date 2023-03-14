CallNode(
  CallNode(
    CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
    nil,
    UPLUS("+"),
    nil,
    nil,
    nil,
    nil,
    "+@"
  ),
  nil,
  STAR_STAR("**"),
  nil,
  ArgumentsNode(
    [CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar")]
  ),
  nil,
  nil,
  "**"
)
