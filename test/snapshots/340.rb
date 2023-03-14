MultiWriteNode(
  [LocalVariableWriteNode(IDENTIFIER("foo"), nil, nil),
   MultiWriteNode(
     [LocalVariableWriteNode(IDENTIFIER("bar"), nil, nil),
      LocalVariableWriteNode(IDENTIFIER("baz"), nil, nil)],
     nil,
     nil,
     (5..6),
     (14..15)
   )],
  EQUAL("="),
  ArrayNode(
    [IntegerNode(),
     ArrayNode(
       [IntegerNode(), IntegerNode()],
       BRACKET_LEFT_ARRAY("["),
       BRACKET_RIGHT("]")
     )],
    nil,
    nil
  ),
  nil,
  nil
)
