CallNode(
  nil,
  nil,
  IDENTIFIER("foo"),
  nil,
  ArgumentsNode(
    [CallNode(
       nil,
       nil,
       IDENTIFIER("bar"),
       nil,
       ArgumentsNode(
         [CallNode(nil, nil, IDENTIFIER("baz"), nil, nil, nil, nil, "baz")]
       ),
       nil,
       nil,
       "bar"
     )]
  ),
  nil,
  BlockNode(nil, nil, (12..14), (15..18)),
  "foo"
)
