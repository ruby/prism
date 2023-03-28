ProgramNode(0...18)(
  ScopeNode(0...0)([IDENTIFIER(0...1)("a"), IDENTIFIER(3...4)("b")]),
  StatementsNode(0...18)(
    [RescueModifierNode(0...18)(
       MultiWriteNode(0...8)(
         [LocalVariableWriteNode(0...1)((0...1), nil, nil),
          LocalVariableWriteNode(3...4)((3...4), nil, nil)],
         EQUAL(5...6)("="),
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
         nil,
         nil
       ),
       KEYWORD_RESCUE_MODIFIER(9...15)("rescue"),
       IntegerNode(16...18)()
     )]
  )
)
