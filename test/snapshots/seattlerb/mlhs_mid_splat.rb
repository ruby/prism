ProgramNode(0...24)(
  ScopeNode(0...0)(
    [IDENTIFIER(0...1)("a"),
     IDENTIFIER(3...4)("b"),
     IDENTIFIER(6...7)("c"),
     IDENTIFIER(10...11)("s"),
     IDENTIFIER(13...14)("x"),
     IDENTIFIER(16...17)("y"),
     IDENTIFIER(19...20)("z")]
  ),
  StatementsNode(0...24)(
    [MultiWriteNode(0...24)(
       [LocalVariableWriteNode(0...1)((0...1), nil, nil),
        LocalVariableWriteNode(3...4)((3...4), nil, nil),
        LocalVariableWriteNode(6...7)((6...7), nil, nil),
        SplatNode(9...11)(
          USTAR(9...10)("*"),
          LocalVariableWriteNode(10...11)((10...11), nil, nil)
        ),
        LocalVariableWriteNode(13...14)((13...14), nil, nil),
        LocalVariableWriteNode(16...17)((16...17), nil, nil),
        LocalVariableWriteNode(19...20)((19...20), nil, nil)],
       EQUAL(21...22)("="),
       CallNode(23...24)(
         nil,
         nil,
         IDENTIFIER(23...24)("f"),
         nil,
         nil,
         nil,
         nil,
         "f"
       ),
       nil,
       nil
     )]
  )
)
