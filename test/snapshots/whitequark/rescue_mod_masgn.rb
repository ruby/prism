ProgramNode(0...29)(
  ScopeNode(0...0)([IDENTIFIER(0...3)("foo"), IDENTIFIER(5...8)("bar")]),
  StatementsNode(0...29)(
    [RescueModifierNode(0...29)(
       MultiWriteNode(0...15)(
         [LocalVariableWriteNode(0...3)(IDENTIFIER(0...3)("foo"), nil, nil),
          LocalVariableWriteNode(5...8)(IDENTIFIER(5...8)("bar"), nil, nil)],
         EQUAL(9...10)("="),
         CallNode(11...15)(
           nil,
           nil,
           IDENTIFIER(11...15)("meth"),
           nil,
           nil,
           nil,
           nil,
           "meth"
         ),
         nil,
         nil
       ),
       KEYWORD_RESCUE_MODIFIER(16...22)("rescue"),
       ArrayNode(23...29)(
         [IntegerNode(24...25)(), IntegerNode(27...28)()],
         BRACKET_LEFT_ARRAY(23...24)("["),
         BRACKET_RIGHT(28...29)("]")
       )
     )]
  )
)
