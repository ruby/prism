ProgramNode(0...12)(
  [:foo],
  StatementsNode(0...12)(
    [OperatorAssignmentNode(0...12)(
       LocalVariableWriteNode(0...3)(:foo, 0, nil, (0...3), nil),
       PLUS_EQUAL(4...6)("+="),
       CallNode(7...12)(
         nil,
         nil,
         IDENTIFIER(7...8)("m"),
         nil,
         ArgumentsNode(9...12)([LocalVariableReadNode(9...12)(:foo, 0)]),
         nil,
         nil,
         "m"
       )
     )]
  )
)
