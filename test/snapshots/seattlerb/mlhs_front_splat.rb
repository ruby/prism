ProgramNode(0...15)(
  ScopeNode(0...0)(
    [IDENTIFIER(1...2)("s"),
     IDENTIFIER(4...5)("x"),
     IDENTIFIER(7...8)("y"),
     IDENTIFIER(10...11)("z")]
  ),
  StatementsNode(0...15)(
    [MultiWriteNode(0...15)(
       [MultiWriteNode(0...2)(
          [SplatNode(0...2)(
             USTAR(0...1)("*"),
             LocalVariableWriteNode(1...2)(IDENTIFIER(1...2)("s"), nil, nil)
           )],
          nil,
          nil,
          nil,
          nil
        ),
        LocalVariableWriteNode(4...5)(IDENTIFIER(4...5)("x"), nil, nil),
        LocalVariableWriteNode(7...8)(IDENTIFIER(7...8)("y"), nil, nil),
        LocalVariableWriteNode(10...11)(IDENTIFIER(10...11)("z"), nil, nil)],
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
