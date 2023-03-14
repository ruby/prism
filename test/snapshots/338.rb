MultiWriteNode(
  [LocalVariableWriteNode(IDENTIFIER("foo"), nil, nil),
   SplatNode(STAR("*"), LocalVariableWriteNode(IDENTIFIER("bar"), nil, nil))],
  EQUAL("="),
  ArrayNode([IntegerNode(), IntegerNode()], nil, nil),
  nil,
  nil
)
