ProgramNode(1...0)(
  ScopeNode(0...0)(
    [IDENTIFIER(1...4)("foo"),
     IDENTIFIER(6...9)("bar"),
     IDENTIFIER(46...49)("baz")]
  ),
  StatementsNode(1...0)(
    [MultiWriteNode(1...0)(
       [LocalVariableWriteNode(1...4)((1...4), nil, nil, 0),
        LocalVariableWriteNode(6...9)((6...9), nil, nil, 0)],
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
       [LocalVariableWriteNode(19...22)((19...22), nil, nil, 1),
        LocalVariableWriteNode(24...27)((24...27), nil, nil, 1)],
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
       [LocalVariableWriteNode(36...39)((36...39), nil, nil, 1),
        LocalVariableWriteNode(41...44)((41...44), nil, nil, 1),
        LocalVariableWriteNode(46...49)((46...49), nil, nil, 0)],
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
