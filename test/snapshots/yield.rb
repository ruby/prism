ProgramNode(
  Scope([]),
  StatementsNode(
    [YieldNode(KEYWORD_YIELD("yield"), nil, nil, nil),
     YieldNode(
       KEYWORD_YIELD("yield"),
       PARENTHESIS_LEFT("("),
       nil,
       PARENTHESIS_RIGHT(")")
     ),
     YieldNode(
       KEYWORD_YIELD("yield"),
       PARENTHESIS_LEFT("("),
       ArgumentsNode([IntegerNode()]),
       PARENTHESIS_RIGHT(")")
     ),
     YieldNode(
       KEYWORD_YIELD("yield"),
       PARENTHESIS_LEFT("("),
       ArgumentsNode([IntegerNode(), IntegerNode(), IntegerNode()]),
       PARENTHESIS_RIGHT(")")
     )]
  )
)
