ProgramNode(0...23)(
  ScopeNode(0...0)(
    [IDENTIFIER(0...1)("a"),
     IDENTIFIER(3...4)("b"),
     IDENTIFIER(6...7)("c"),
     IDENTIFIER(12...13)("x"),
     IDENTIFIER(15...16)("y"),
     IDENTIFIER(18...19)("z")]
  ),
  StatementsNode(0...23)(
    [MultiWriteNode(0...23)(
       [LocalVariableWriteNode(0...1)(IDENTIFIER(0...1)("a"), nil, nil),
        LocalVariableWriteNode(3...4)(IDENTIFIER(3...4)("b"), nil, nil),
        LocalVariableWriteNode(6...7)(IDENTIFIER(6...7)("c"), nil, nil),
        SplatNode(9...10)(USTAR(9...10)("*"), nil),
        LocalVariableWriteNode(12...13)(IDENTIFIER(12...13)("x"), nil, nil),
        LocalVariableWriteNode(15...16)(IDENTIFIER(15...16)("y"), nil, nil),
        LocalVariableWriteNode(18...19)(IDENTIFIER(18...19)("z"), nil, nil)],
       EQUAL(20...21)("="),
       CallNode(22...23)(
         nil,
         nil,
         IDENTIFIER(22...23)("f"),
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
