ProgramNode(0...29)(
  [IDENTIFIER(0...3)("foo"), IDENTIFIER(5...8)("bar")],
  StatementsNode(0...29)(
    [MultiWriteNode(0...29)(
       [LocalVariableWriteNode(0...3)((0...3), nil, nil, 0),
        LocalVariableWriteNode(5...8)((5...8), nil, nil, 0)],
       (9...10),
       RescueModifierNode(11...29)(
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
         (16...22),
         ArrayNode(23...29)(
           [IntegerNode(24...25)(), IntegerNode(27...28)()],
           (23...24),
           (28...29)
         )
       ),
       nil,
       nil
     )]
  )
)
