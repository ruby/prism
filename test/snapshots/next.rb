ProgramNode(
  Scope([]),
  StatementsNode(
    [NextNode(nil, (0..4)),
     NextNode(
       ArgumentsNode(
         [ParenthesesNode(StatementsNode([IntegerNode()]), (11..12), (13..14)),
          ParenthesesNode(StatementsNode([IntegerNode()]), (16..17), (18..19)),
          ParenthesesNode(StatementsNode([IntegerNode()]), (21..22), (23..24))]
       ),
       (6..10)
     ),
     NextNode(ArgumentsNode([IntegerNode()]), (26..30)),
     NextNode(
       ArgumentsNode([IntegerNode(), IntegerNode(), IntegerNode()]),
       (34..38)
     ),
     NextNode(
       ArgumentsNode([IntegerNode(), IntegerNode(), IntegerNode()]),
       (48..52)
     ),
     NextNode(
       ArgumentsNode(
         [ArrayNode(
            [IntegerNode(), IntegerNode(), IntegerNode()],
            BRACKET_LEFT_ARRAY("["),
            BRACKET_RIGHT("]")
          )]
       ),
       (62..66)
     ),
     NextNode(
       ArgumentsNode(
         [ParenthesesNode(
            StatementsNode([IntegerNode(), IntegerNode()]),
            (82..83),
            (92..93)
          )]
       ),
       (78..82)
     ),
     NextNode(nil, (95..99)),
     IntegerNode(),
     NextNode(
       ArgumentsNode([ParenthesesNode(nil, (107..108), (108..109))]),
       (103..107)
     ),
     NextNode(
       ArgumentsNode(
         [ParenthesesNode(
            StatementsNode([IntegerNode()]),
            (115..116),
            (117..118)
          )]
       ),
       (111..115)
     )]
  )
)
