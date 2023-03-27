ProgramNode(1...0)(
  ScopeNode(0...0)(
    [IDENTIFIER(1...4)("foo"),
     IDENTIFIER(6...9)("bar"),
     IDENTIFIER(46...49)("baz")]
  ),
  StatementsNode(1...0)(
    [MultiWriteNode(1...0)(
       [LocalVariableWriteNode(1...4)(IDENTIFIER(1...4)("foo"), nil, nil),
        LocalVariableWriteNode(6...9)(IDENTIFIER(6...9)("bar"), nil, nil)],
       EQUAL(11...12)("="),
       ArrayNode(0...0)(
         [IntegerNode(13...14)(), IntegerNode(16...17)()],
         nil,
         nil
       ),
       (0...1),
       (9...10)
     ),
     MultiWriteNode(19...0)(
       [LocalVariableWriteNode(19...22)(IDENTIFIER(19...22)("foo"), nil, nil),
        LocalVariableWriteNode(24...27)(IDENTIFIER(24...27)("bar"), nil, nil)],
       EQUAL(28...29)("="),
       ArrayNode(0...0)(
         [IntegerNode(30...31)(), IntegerNode(33...34)()],
         nil,
         nil
       ),
       nil,
       nil
     ),
     MultiWriteNode(36...0)(
       [LocalVariableWriteNode(36...39)(IDENTIFIER(36...39)("foo"), nil, nil),
        LocalVariableWriteNode(41...44)(IDENTIFIER(41...44)("bar"), nil, nil),
        LocalVariableWriteNode(46...49)(IDENTIFIER(46...49)("baz"), nil, nil)],
       EQUAL(50...51)("="),
       ArrayNode(0...0)(
         [IntegerNode(52...53)(), IntegerNode(55...56)()],
         nil,
         nil
       ),
       nil,
       nil
     )]
  )
)
