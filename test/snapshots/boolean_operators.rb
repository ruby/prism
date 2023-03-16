ProgramNode(
  Scope([IDENTIFIER("a")]),
  StatementsNode(
    [OperatorAndAssignmentNode(
       LocalVariableWriteNode(IDENTIFIER("a"), nil, nil),
       CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b"),
       (2..5)
     ),
     OperatorAssignmentNode(
       LocalVariableWriteNode(IDENTIFIER("a"), nil, nil),
       PLUS_EQUAL("+="),
       CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")
     ),
     OperatorOrAssignmentNode(
       LocalVariableWriteNode(IDENTIFIER("a"), nil, nil),
       CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b"),
       (19..22)
     )]
  )
)
