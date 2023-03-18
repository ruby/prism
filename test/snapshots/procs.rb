ProgramNode(
  Scope([]),
  StatementsNode(
    [LambdaNode(
       Scope(
         [IDENTIFIER("a"), IDENTIFIER("b"), IDENTIFIER("c"), IDENTIFIER("d")]
       ),
       PARENTHESIS_LEFT("("),
       BlockParametersNode(
         ParametersNode(
           [RequiredParameterNode(IDENTIFIER("a"))],
           [],
           nil,
           [],
           nil,
           nil
         ),
         [IDENTIFIER("b"), IDENTIFIER("c"), IDENTIFIER("d")]
       ),
       PARENTHESIS_RIGHT(")"),
       StatementsNode([LocalVariableReadNode(IDENTIFIER("b"), 0)])
     ),
     LambdaNode(
       Scope([]),
       nil,
       BlockParametersNode(ParametersNode([], [], nil, [], nil, nil), []),
       nil,
       BeginNode(
         nil,
         StatementsNode([]),
         nil,
         nil,
         EnsureNode(
           KEYWORD_ENSURE("ensure"),
           StatementsNode([]),
           KEYWORD_END("end")
         ),
         KEYWORD_END("end")
       )
     ),
     LambdaNode(
       Scope([]),
       nil,
       BlockParametersNode(ParametersNode([], [], nil, [], nil, nil), []),
       nil,
       BeginNode(
         nil,
         StatementsNode([]),
         RescueNode(
           KEYWORD_RESCUE("rescue"),
           [],
           nil,
           nil,
           StatementsNode([]),
           nil
         ),
         ElseNode(
           KEYWORD_ELSE("else"),
           StatementsNode([]),
           KEYWORD_ELSE("else")
         ),
         EnsureNode(
           KEYWORD_ENSURE("ensure"),
           StatementsNode([]),
           KEYWORD_END("end")
         ),
         KEYWORD_END("end")
       )
     ),
     LambdaNode(
       Scope([]),
       nil,
       BlockParametersNode(ParametersNode([], [], nil, [], nil, nil), []),
       nil,
       StatementsNode(
         [CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo")]
       )
     ),
     LambdaNode(
       Scope([]),
       nil,
       BlockParametersNode(ParametersNode([], [], nil, [], nil, nil), []),
       nil,
       StatementsNode(
         [CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo")]
       )
     ),
     LambdaNode(
       Scope(
         [IDENTIFIER("a"),
          IDENTIFIER("b"),
          LABEL("c"),
          LABEL("d"),
          IDENTIFIER("e")]
       ),
       nil,
       BlockParametersNode(
         ParametersNode(
           [RequiredParameterNode(IDENTIFIER("a"))],
           [OptionalParameterNode(IDENTIFIER("b"), EQUAL("="), IntegerNode())],
           nil,
           [KeywordParameterNode(LABEL("c:"), nil),
            KeywordParameterNode(LABEL("d:"), nil)],
           nil,
           BlockParameterNode(IDENTIFIER("e"), (121..122))
         ),
         []
       ),
       nil,
       StatementsNode([LocalVariableReadNode(IDENTIFIER("a"), 0)])
     ),
     LambdaNode(
       Scope(
         [IDENTIFIER("a"),
          IDENTIFIER("b"),
          IDENTIFIER("c"),
          LABEL("d"),
          LABEL("e"),
          IDENTIFIER("f"),
          IDENTIFIER("g")]
       ),
       PARENTHESIS_LEFT("("),
       BlockParametersNode(
         ParametersNode(
           [RequiredParameterNode(IDENTIFIER("a"))],
           [OptionalParameterNode(IDENTIFIER("b"), EQUAL("="), IntegerNode())],
           RestParameterNode(USTAR("*"), IDENTIFIER("c")),
           [KeywordParameterNode(LABEL("d:"), nil),
            KeywordParameterNode(LABEL("e:"), nil)],
           KeywordRestParameterNode(STAR_STAR("**"), IDENTIFIER("f")),
           BlockParameterNode(IDENTIFIER("g"), (162..163))
         ),
         []
       ),
       PARENTHESIS_RIGHT(")"),
       StatementsNode([LocalVariableReadNode(IDENTIFIER("a"), 0)])
     ),
     LambdaNode(
       Scope(
         [IDENTIFIER("a"),
          IDENTIFIER("b"),
          IDENTIFIER("c"),
          LABEL("d"),
          LABEL("e"),
          IDENTIFIER("f"),
          IDENTIFIER("g")]
       ),
       PARENTHESIS_LEFT("("),
       BlockParametersNode(
         ParametersNode(
           [RequiredParameterNode(IDENTIFIER("a"))],
           [OptionalParameterNode(IDENTIFIER("b"), EQUAL("="), IntegerNode())],
           RestParameterNode(USTAR("*"), IDENTIFIER("c")),
           [KeywordParameterNode(LABEL("d:"), nil),
            KeywordParameterNode(LABEL("e:"), nil)],
           KeywordRestParameterNode(STAR_STAR("**"), IDENTIFIER("f")),
           BlockParameterNode(IDENTIFIER("g"), (204..205))
         ),
         []
       ),
       PARENTHESIS_RIGHT(")"),
       StatementsNode([LocalVariableReadNode(IDENTIFIER("a"), 0)])
     ),
     LambdaNode(
       Scope([IDENTIFIER("a")]),
       PARENTHESIS_LEFT("("),
       BlockParametersNode(
         ParametersNode(
           [RequiredParameterNode(IDENTIFIER("a"))],
           [],
           nil,
           [],
           nil,
           nil
         ),
         []
       ),
       PARENTHESIS_RIGHT(")"),
       StatementsNode(
         [LambdaNode(
            Scope([IDENTIFIER("b")]),
            nil,
            BlockParametersNode(
              ParametersNode(
                [RequiredParameterNode(IDENTIFIER("b"))],
                [],
                nil,
                [],
                nil,
                nil
              ),
              []
            ),
            nil,
            StatementsNode(
              [CallNode(
                 LocalVariableReadNode(IDENTIFIER("a"), 1),
                 nil,
                 STAR("*"),
                 nil,
                 ArgumentsNode([LocalVariableReadNode(IDENTIFIER("b"), 0)]),
                 nil,
                 nil,
                 "*"
               )]
            )
          )]
       )
     )]
  )
)
