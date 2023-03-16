ProgramNode(
  Scope([]),
  StatementsNode(
    [ParenthesesNode(
       StatementsNode([RangeNode(nil, IntegerNode(), (1..4))]),
       (0..1),
       (5..6)
     ),
     ParenthesesNode(
       StatementsNode([RangeNode(nil, IntegerNode(), (9..11))]),
       (8..9),
       (12..13)
     ),
     RangeNode(IntegerNode(), IntegerNode(), (16..19)),
     CallNode(
       CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
       nil,
       BRACKET_LEFT_RIGHT("["),
       BRACKET_LEFT("["),
       ArgumentsNode([RangeNode(nil, IntegerNode(), (26..29))]),
       BRACKET_RIGHT("]"),
       nil,
       "[]"
     ),
     HashNode(
       BRACE_LEFT("{"),
       [AssocNode(
          SymbolNode(nil, LABEL("foo"), LABEL_END(":"), "foo"),
          RangeNode(
            nil,
            CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar"),
            (40..43)
          ),
          nil
        )],
       BRACE_RIGHT("}")
     ),
     ParenthesesNode(
       StatementsNode([RangeNode(IntegerNode(), nil, (52..55))]),
       (50..51),
       (55..56)
     ),
     RangeNode(IntegerNode(), IntegerNode(), (59..61)),
     HashNode(
       BRACE_LEFT("{"),
       [AssocNode(
          SymbolNode(nil, LABEL("foo"), LABEL_END(":"), "foo"),
          RangeNode(
            nil,
            CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar"),
            (71..73)
          ),
          nil
        )],
       BRACE_RIGHT("}")
     ),
     ParenthesesNode(
       StatementsNode([RangeNode(IntegerNode(), nil, (82..84))]),
       (80..81),
       (84..85)
     )]
  )
)
