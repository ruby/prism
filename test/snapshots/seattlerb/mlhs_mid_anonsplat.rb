ProgramNode(0...23)(
  [:a, :b, :c, :x, :y, :z],
  StatementsNode(0...23)(
    [MultiWriteNode(0...23)(
       [LocalVariableWriteNode(0...1)(:a, 0, nil, (0...1), nil),
        LocalVariableWriteNode(3...4)(:b, 0, nil, (3...4), nil),
        LocalVariableWriteNode(6...7)(:c, 0, nil, (6...7), nil),
        SplatNode(9...10)((9...10), nil),
        LocalVariableWriteNode(12...13)(:x, 0, nil, (12...13), nil),
        LocalVariableWriteNode(15...16)(:y, 0, nil, (15...16), nil),
        LocalVariableWriteNode(18...19)(:z, 0, nil, (18...19), nil)],
       (20...21),
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
