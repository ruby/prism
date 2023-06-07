ProgramNode(0...10)(
  [:a, :b],
  StatementsNode(0...10)(
    [MultiWriteNode(0...8)(
       [LocalVariableWriteNode(0...1)(:a, 0, nil, (0...1), nil),
        LocalVariableWriteNode(3...4)(:b, 0, nil, (3...4), nil)],
       (5...6),
       CallNode(7...8)(
         nil,
         nil,
         IDENTIFIER(7...8)("c"),
         nil,
         nil,
         nil,
         nil,
         "c"
       ),
       nil,
       nil
     ),
     CallNode(9...10)(
       nil,
       nil,
       IDENTIFIER(9...10)("d"),
       nil,
       nil,
       nil,
       nil,
       "d"
     )]
  )
)
