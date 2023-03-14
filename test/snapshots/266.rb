ForNode(
  MultiWriteNode(
    [LocalVariableWriteNode(IDENTIFIER("i"), nil, nil),
     LocalVariableWriteNode(IDENTIFIER("j"), nil, nil)],
    nil,
    nil,
    nil,
    nil
  ),
  RangeNode(IntegerNode(), IntegerNode(), (12..14)),
  StatementsNode([LocalVariableReadNode(IDENTIFIER("i"))]),
  (0..3),
  (8..10),
  nil,
  (19..22)
)
