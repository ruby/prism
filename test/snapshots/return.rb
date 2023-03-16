ProgramNode(
  Scope([]),
  StatementsNode(
    [ReturnNode(KEYWORD_RETURN("return"), nil),
     ReturnNode(
       KEYWORD_RETURN("return"),
       ArgumentsNode(
         [ParenthesesNode(StatementsNode([IntegerNode()]), (15..16), (17..18)),
          ParenthesesNode(StatementsNode([IntegerNode()]), (20..21), (22..23)),
          ParenthesesNode(StatementsNode([IntegerNode()]), (25..26), (27..28))]
       )
     ),
     ReturnNode(
       KEYWORD_RETURN("return"),
       ArgumentsNode([SplatNode(STAR("*"), IntegerNode())])
     ),
     ReturnNode(KEYWORD_RETURN("return"), ArgumentsNode([IntegerNode()])),
     ReturnNode(
       KEYWORD_RETURN("return"),
       ArgumentsNode([IntegerNode(), IntegerNode(), IntegerNode()])
     ),
     ReturnNode(
       KEYWORD_RETURN("return"),
       ArgumentsNode([IntegerNode(), IntegerNode(), IntegerNode()])
     ),
     ReturnNode(
       KEYWORD_RETURN("return"),
       ArgumentsNode(
         [ArrayNode(
            [IntegerNode(), IntegerNode(), IntegerNode()],
            BRACKET_LEFT_ARRAY("["),
            BRACKET_RIGHT("]")
          )]
       )
     ),
     ReturnNode(
       KEYWORD_RETURN("return"),
       ArgumentsNode(
         [ParenthesesNode(
            StatementsNode([IntegerNode(), IntegerNode()]),
            (107..108),
            (117..118)
          )]
       )
     ),
     ReturnNode(
       KEYWORD_RETURN("return"),
       ArgumentsNode([ParenthesesNode(nil, (126..127), (127..128))])
     ),
     ReturnNode(
       KEYWORD_RETURN("return"),
       ArgumentsNode(
         [ParenthesesNode(
            StatementsNode([IntegerNode()]),
            (136..137),
            (138..139)
          )]
       )
     )]
  )
)
