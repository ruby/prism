ProgramNode(0...9)(
  ScopeNode(0...0)([IDENTIFIER(1...2)("a"), IDENTIFIER(4...5)("b")]),
  StatementsNode(0...9)(
    [MultiWriteNode(0...9)(
       [MultiWriteNode(0...2)(
          [SplatNode(0...2)(
             USTAR(0...1)("*"),
             LocalVariableWriteNode(1...2)(IDENTIFIER(1...2)("a"), nil, nil)
           )],
          nil,
          nil,
          nil,
          nil
        ),
        LocalVariableWriteNode(4...5)(IDENTIFIER(4...5)("b"), nil, nil)],
       EQUAL(6...7)("="),
       CallNode(8...9)(
         nil,
         nil,
         IDENTIFIER(8...9)("c"),
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
