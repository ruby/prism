ProgramNode(0...53)(
  ScopeNode(0...0)([IDENTIFIER(22...23)("a")]),
  StatementsNode(0...53)(
    [OperatorAssignmentNode(0...11)(
       ClassVariableWriteNode(0...5)((0...5), nil, nil),
       PIPE_EQUAL(6...8)("|="),
       IntegerNode(9...11)((9...11), 10)
     ),
     OperatorAssignmentNode(13...20)(
       InstanceVariableWriteNode(13...15)((13...15), nil, nil),
       PIPE_EQUAL(16...18)("|="),
       IntegerNode(19...20)((19...20), 10)
     ),
     OperatorAssignmentNode(22...28)(
       LocalVariableWriteNode(22...23)((22...23), nil, nil, 0),
       PLUS_EQUAL(24...26)("+="),
       IntegerNode(27...28)((27...28), 10)
     ),
     DefNode(30...53)(
       IDENTIFIER(34...35)("a"),
       nil,
       nil,
       StatementsNode(37...48)(
         [OperatorAssignmentNode(37...48)(
            ClassVariableWriteNode(37...42)((37...42), nil, nil),
            PIPE_EQUAL(43...45)("|="),
            IntegerNode(46...48)((46...48), 10)
          )]
       ),
       ScopeNode(30...33)([]),
       (30...33),
       nil,
       nil,
       nil,
       nil,
       (50...53)
     )]
  )
)
