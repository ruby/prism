ProgramNode(0...24)(
  [:a, :b, :c, :s, :x, :y, :z],
  StatementsNode(0...24)(
    [MultiWriteNode(0...24)(
       [LocalVariableWriteNode(0...1)(:a, 0, nil, (0...1), nil),
        LocalVariableWriteNode(3...4)(:b, 0, nil, (3...4), nil),
        LocalVariableWriteNode(6...7)(:c, 0, nil, (6...7), nil),
        SplatNode(9...11)(
          (9...10),
          LocalVariableWriteNode(10...11)(:s, 0, nil, (10...11), nil)
        ),
        LocalVariableWriteNode(13...14)(:x, 0, nil, (13...14), nil),
        LocalVariableWriteNode(16...17)(:y, 0, nil, (16...17), nil),
        LocalVariableWriteNode(19...20)(:z, 0, nil, (19...20), nil)],
       (21...22),
       CallNode(23...24)(
         nil,
         nil,
         IDENTIFIER(23...24)("f"),
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
