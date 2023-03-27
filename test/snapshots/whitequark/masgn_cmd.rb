ProgramNode(0...12)(
  ScopeNode(0...0)([IDENTIFIER(0...3)("foo"), IDENTIFIER(5...8)("bar")]),
  StatementsNode(0...12)(
    [MultiWriteNode(0...12)(
       [LocalVariableWriteNode(0...3)(IDENTIFIER(0...3)("foo"), nil, nil),
        LocalVariableWriteNode(5...8)(IDENTIFIER(5...8)("bar"), nil, nil)],
       EQUAL(9...10)("="),
       CallNode(11...12)(
         nil,
         nil,
         IDENTIFIER(11...12)("m"),
         nil,
         ArgumentsNode(13...16)(
           [LocalVariableReadNode(13...16)(IDENTIFIER(13...16)("foo"))]
         ),
         nil,
         nil,
         "m"
       ),
       nil,
       nil
     )]
  )
)
