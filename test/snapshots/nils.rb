ProgramNode(
  Scope([]),
  StatementsNode(
    [NilNode(),
     ParenthesesNode(nil, (5..6), (6..7)),
     ParenthesesNode(nil, (9..10), (15..16)),
     PostExecutionNode(
       StatementsNode([IntegerNode()]),
       (18..21),
       (22..23),
       (26..27)
     ),
     PreExecutionNode(
       StatementsNode([IntegerNode()]),
       (29..34),
       (35..36),
       (39..40)
     )]
  )
)
