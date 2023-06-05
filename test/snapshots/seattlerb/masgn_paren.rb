ProgramNode(1...12)(
  [:a, :b],
  StatementsNode(1...12)(
    [MultiWriteNode(1...12)(
       [LocalVariableWriteNode(1...2)(:a, 0, nil, (1...2), nil),
        LocalVariableWriteNode(4...5)(:b, 0, nil, (4...5), nil)],
       (7...8),
       CallNode(9...12)(
         CallNode(9...10)(
           nil,
           nil,
           IDENTIFIER(9...10)("c"),
           nil,
           nil,
           nil,
           nil,
           "c"
         ),
         DOT(10...11)("."),
         IDENTIFIER(11...12)("d"),
         nil,
         nil,
         nil,
         nil,
         "d"
       ),
       (0...1),
       (5...6)
     )]
  )
)
