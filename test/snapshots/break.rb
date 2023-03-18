ProgramNode(
  Scope([]),
  StatementsNode(
    [BreakNode(nil, (0..5)),
     BreakNode(
       ArgumentsNode(
         [ParenthesesNode(StatementsNode([IntegerNode()]), (13..14), (15..16)),
          ParenthesesNode(StatementsNode([IntegerNode()]), (18..19), (20..21)),
          ParenthesesNode(StatementsNode([IntegerNode()]), (23..24), (25..26))]
       ),
       (7..12)
     ),
     BreakNode(ArgumentsNode([IntegerNode()]), (28..33)),
     BreakNode(
       ArgumentsNode([IntegerNode(), IntegerNode(), IntegerNode()]),
       (37..42)
     ),
     BreakNode(
       ArgumentsNode([IntegerNode(), IntegerNode(), IntegerNode()]),
       (52..57)
     ),
     BreakNode(
       ArgumentsNode(
         [ArrayNode(
            [IntegerNode(), IntegerNode(), IntegerNode()],
            BRACKET_LEFT_ARRAY("["),
            BRACKET_RIGHT("]")
          )]
       ),
       (67..72)
     ),
     BreakNode(
       ArgumentsNode(
         [ParenthesesNode(
            StatementsNode([IntegerNode(), IntegerNode()]),
            (89..90),
            (99..100)
          )]
       ),
       (84..89)
     ),
     BreakNode(
       ArgumentsNode([ParenthesesNode(nil, (107..108), (108..109))]),
       (102..107)
     ),
     BreakNode(
       ArgumentsNode(
         [ParenthesesNode(
            StatementsNode([IntegerNode()]),
            (116..117),
            (118..119)
          )]
       ),
       (111..116)
     ),
     CallNode(
       CallNode(
         nil,
         nil,
         IDENTIFIER("foo"),
         nil,
         nil,
         nil,
         BlockNode(
           Scope([]),
           nil,
           StatementsNode(
             [BreakNode(ArgumentsNode([IntegerNode()]), (127..132))]
           ),
           (125..126),
           (136..137)
         ),
         "foo"
       ),
       nil,
       EQUAL_EQUAL("=="),
       nil,
       ArgumentsNode([IntegerNode()]),
       nil,
       nil,
       "=="
     ),
     CallNode(
       CallNode(
         nil,
         nil,
         IDENTIFIER("foo"),
         nil,
         nil,
         nil,
         BlockNode(
           Scope([IDENTIFIER("a")]),
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
           StatementsNode([BreakNode(nil, (155..160))]),
           (149..150),
           (161..162)
         ),
         "foo"
       ),
       nil,
       EQUAL_EQUAL("=="),
       nil,
       ArgumentsNode([IntegerNode()]),
       nil,
       nil,
       "=="
     )]
  )
)
