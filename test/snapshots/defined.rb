ProgramNode(
  Scope([IDENTIFIER("x")]),
  StatementsNode(
    [AndNode(
       DefinedNode(nil, IntegerNode(), nil, (0..8)),
       DefinedNode(nil, IntegerNode(), nil, (15..23)),
       KEYWORD_AND("and")
     ),
     DefinedNode(
       PARENTHESIS_LEFT("("),
       OperatorAssignmentNode(
         LocalVariableWriteNode(IDENTIFIER("x"), nil, nil, 0),
         PERCENT_EQUAL("%="),
         IntegerNode()
       ),
       PARENTHESIS_RIGHT(")"),
       (27..35)
     ),
     DefinedNode(
       PARENTHESIS_LEFT("("),
       AndNode(
         CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
         CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar"),
         KEYWORD_AND("and")
       ),
       PARENTHESIS_RIGHT(")"),
       (45..53)
     ),
     DefinedNode(nil, IntegerNode(), nil, (68..76))]
  )
)
