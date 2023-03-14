DefNode(
  IDENTIFIER("a"),
  nil,
  ParametersNode([], [], nil, [], ForwardingParameterNode(), nil),
  StatementsNode(
    [CallNode(
       nil,
       nil,
       IDENTIFIER("b"),
       PARENTHESIS_LEFT("("),
       ArgumentsNode(
         [IntegerNode(), IntegerNode(), ForwardingArgumentsNode()]
       ),
       PARENTHESIS_RIGHT(")"),
       nil,
       "b"
     )]
  ),
  Scope([UDOT_DOT_DOT("...")]),
  (0..3),
  nil,
  (5..6),
  (9..10),
  nil,
  (26..29)
)
