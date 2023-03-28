ProgramNode(0...14)(
  ScopeNode(0...0)(
    [IDENTIFIER(0...1)("a"), IDENTIFIER(3...4)("b"), IDENTIFIER(6...7)("c")]
  ),
  StatementsNode(0...14)(
    [MultiWriteNode(0...14)(
       [LocalVariableWriteNode(0...1)(IDENTIFIER(0...1)("a"), nil, nil),
        LocalVariableWriteNode(3...4)(IDENTIFIER(3...4)("b"), nil, nil),
        LocalVariableWriteNode(6...7)(IDENTIFIER(6...7)("c"), nil, nil),
        SplatNode(9...10)(USTAR(9...10)("*"), nil)],
       EQUAL(11...12)("="),
       CallNode(13...14)(
         nil,
         nil,
         IDENTIFIER(13...14)("f"),
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
