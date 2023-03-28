ProgramNode(2...9)(
  ScopeNode(0...0)([IDENTIFIER(2...3)("a"), IDENTIFIER(4...5)("b")]),
  StatementsNode(2...9)(
    [MultiWriteNode(2...9)(
       [MultiWriteNode(2...5)(
          [LocalVariableWriteNode(2...3)(IDENTIFIER(2...3)("a"), nil, nil),
           LocalVariableWriteNode(4...5)(IDENTIFIER(4...5)("b"), nil, nil)],
          nil,
          nil,
          (1...2),
          (5...6)
        )],
       EQUAL(7...8)("="),
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
       (0...1),
       (6...7)
     )]
  )
)
