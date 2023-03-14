MultiWriteNode(
  [CallNode(
     CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
     DOT("."),
     IDENTIFIER("foo"),
     nil,
     nil,
     nil,
     nil,
     "foo="
   ),
   CallNode(
     CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar"),
     DOT("."),
     IDENTIFIER("bar"),
     nil,
     nil,
     nil,
     nil,
     "bar="
   )],
  EQUAL("="),
  ArrayNode([IntegerNode(), IntegerNode()], nil, nil),
  nil,
  nil
)
