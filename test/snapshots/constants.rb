ProgramNode(
  Scope([]),
  StatementsNode(
    [ConstantPathNode(
       ConstantReadNode(),
       COLON_COLON("::"),
       ConstantReadNode()
     ),
     ConstantPathNode(
       ConstantPathNode(
         ConstantReadNode(),
         COLON_COLON("::"),
         ConstantReadNode()
       ),
       COLON_COLON("::"),
       ConstantReadNode()
     ),
     ConstantPathNode(
       CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a"),
       COLON_COLON("::"),
       ConstantReadNode()
     ),
     ConstantPathWriteNode(
       ConstantPathNode(
         ConstantReadNode(),
         COLON_COLON("::"),
         ConstantReadNode()
       ),
       EQUAL("="),
       IntegerNode()
     ),
     ConstantPathWriteNode(ConstantReadNode(), EQUAL("="), IntegerNode()),
     ConstantReadNode(),
     CallNode(
       nil,
       nil,
       CONSTANT("Foo"),
       nil,
       ArgumentsNode([IntegerNode()]),
       nil,
       nil,
       "Foo"
     ),
     CallNode(
       ConstantPathNode(nil, UCOLON_COLON("::"), ConstantReadNode()),
       COLON_COLON("::"),
       IDENTIFIER("foo"),
       nil,
       nil,
       nil,
       nil,
       "foo"
     ),
     ConstantPathWriteNode(
       ConstantPathNode(nil, UCOLON_COLON("::"), ConstantReadNode()),
       EQUAL("="),
       IntegerNode()
     ),
     ConstantPathWriteNode(
       ConstantPathNode(
         ConstantPathNode(nil, UCOLON_COLON("::"), ConstantReadNode()),
         COLON_COLON("::"),
         ConstantReadNode()
       ),
       EQUAL("="),
       IntegerNode()
     ),
     ConstantPathNode(
       ConstantPathNode(nil, UCOLON_COLON("::"), ConstantReadNode()),
       COLON_COLON("::"),
       ConstantReadNode()
     ),
     ConstantPathNode(nil, UCOLON_COLON("::"), ConstantReadNode())]
  )
)
