ProgramNode(0...11)(
  ScopeNode(0...0)([IDENTIFIER(0...1)("a"), IDENTIFIER(6...7)("b")]),
  StatementsNode(0...11)(
    [MultiWriteNode(0...11)(
       [LocalVariableWriteNode(0...1)(IDENTIFIER(0...1)("a"), nil, nil),
        SplatNode(3...4)(USTAR(3...4)("*"), nil),
        LocalVariableWriteNode(6...7)(IDENTIFIER(6...7)("b"), nil, nil)],
       EQUAL(8...9)("="),
       CallNode(10...11)(
         nil,
         nil,
         IDENTIFIER(10...11)("c"),
         nil,
         nil,
         nil,
         nil,
         "c"
       ),
       nil,
       nil
     )]
  )
)
