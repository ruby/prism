ProgramNode(0...15)(
  ScopeNode(0...0)(
    [IDENTIFIER(0...1)("a"),
     IDENTIFIER(3...4)("b"),
     IDENTIFIER(6...7)("c"),
     IDENTIFIER(10...11)("s")]
  ),
  StatementsNode(0...15)(
    [MultiWriteNode(0...15)(
       [LocalVariableWriteNode(0...1)(IDENTIFIER(0...1)("a"), nil, nil),
        LocalVariableWriteNode(3...4)(IDENTIFIER(3...4)("b"), nil, nil),
        LocalVariableWriteNode(6...7)(IDENTIFIER(6...7)("c"), nil, nil),
        SplatNode(9...11)(
          USTAR(9...10)("*"),
          LocalVariableWriteNode(10...11)(IDENTIFIER(10...11)("s"), nil, nil)
        )],
       EQUAL(12...13)("="),
       CallNode(14...15)(
         nil,
         nil,
         IDENTIFIER(14...15)("f"),
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
