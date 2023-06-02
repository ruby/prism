ProgramNode(0...18)(
  [IDENTIFIER(0...1)("a"), IDENTIFIER(3...4)("b")],
  StatementsNode(0...18)(
    [MultiWriteNode(0...18)(
       [LocalVariableWriteNode(0...1)((0...1), nil, nil, 0),
        LocalVariableWriteNode(3...4)((3...4), nil, nil, 0)],
       (5...6),
       RescueModifierNode(7...18)(
         CallNode(7...8)(
           nil,
           nil,
           IDENTIFIER(7...8)("f"),
           nil,
           nil,
           nil,
           nil,
           "f"
         ),
         (9...15),
         IntegerNode(16...18)()
       ),
       nil,
       nil
     )]
  )
)
