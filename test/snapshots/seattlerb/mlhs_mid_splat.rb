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
       [LocalVariableWriteNode(0...1)(IDENTIFIER(0...1)("a"), nil, nil),
        LocalVariableWriteNode(3...4)(IDENTIFIER(3...4)("b"), nil, nil),
        LocalVariableWriteNode(6...7)(IDENTIFIER(6...7)("c"), nil, nil),
        SplatNode(9...11)(
          USTAR(9...10)("*"),
          LocalVariableWriteNode(10...11)(IDENTIFIER(10...11)("s"), nil, nil)
        ),
        LocalVariableWriteNode(13...14)(IDENTIFIER(13...14)("x"), nil, nil),
        LocalVariableWriteNode(16...17)(IDENTIFIER(16...17)("y"), nil, nil),
        LocalVariableWriteNode(19...20)(IDENTIFIER(19...20)("z"), nil, nil)],
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
