CallNode(
  CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
  DOT("."),
  IDENTIFIER("bar"),
  nil,
  ArgumentsNode(
    [StringNode(
       STRING_BEGIN("%{"),
       STRING_CONTENT("baz"),
       STRING_END("}"),
       "baz"
     )]
  ),
  nil,
  nil,
  "bar"
)
