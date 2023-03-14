MultiWriteNode(
  [CallNode(
     CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
     nil,
     BRACKET_LEFT_RIGHT_EQUAL("["),
     BRACKET_LEFT("["),
     ArgumentsNode([IntegerNode()]),
     BRACKET_RIGHT("]"),
     nil,
     "[]="
   ),
   CallNode(
     CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar"),
     nil,
     BRACKET_LEFT_RIGHT_EQUAL("["),
     BRACKET_LEFT("["),
     ArgumentsNode([IntegerNode()]),
     BRACKET_RIGHT("]"),
     nil,
     "[]="
   )],
  EQUAL("="),
  ArrayNode([IntegerNode(), IntegerNode()], nil, nil),
  nil,
  nil
)
