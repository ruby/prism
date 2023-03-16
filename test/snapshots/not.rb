ProgramNode(
  Scope([]),
  StatementsNode(
    [AndNode(
       CallNode(
         CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
         nil,
         KEYWORD_NOT("not"),
         nil,
         nil,
         nil,
         nil,
         "!"
       ),
       CallNode(
         CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar"),
         nil,
         KEYWORD_NOT("not"),
         nil,
         nil,
         nil,
         nil,
         "!"
       ),
       KEYWORD_AND("and")
     ),
     CallNode(
       AndNode(
         CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
         CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar"),
         KEYWORD_AND("and")
       ),
       nil,
       KEYWORD_NOT("not"),
       PARENTHESIS_LEFT("("),
       nil,
       PARENTHESIS_RIGHT(")"),
       nil,
       "!"
     ),
     CallNode(
       CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
       nil,
       KEYWORD_NOT("not"),
       nil,
       nil,
       nil,
       nil,
       "!"
     )]
  )
)
