ProgramNode(
  Scope([]),
  StatementsNode(
    [UntilNode(
       KEYWORD_UNTIL("until"),
       TrueNode(),
       StatementsNode([IntegerNode()])
     ),
     UntilNode(
       KEYWORD_UNTIL_MODIFIER("until"),
       TrueNode(),
       StatementsNode([IntegerNode()])
     ),
     UntilNode(
       KEYWORD_UNTIL_MODIFIER("until"),
       TrueNode(),
       StatementsNode([BreakNode(nil, (34..39))])
     ),
     UntilNode(
       KEYWORD_UNTIL_MODIFIER("until"),
       TrueNode(),
       StatementsNode([NextNode(nil, (52..56))])
     ),
     UntilNode(
       KEYWORD_UNTIL_MODIFIER("until"),
       TrueNode(),
       StatementsNode([ReturnNode(KEYWORD_RETURN("return"), nil)])
     ),
     UntilNode(
       KEYWORD_UNTIL_MODIFIER("until"),
       CallNode(nil, nil, IDENTIFIER("bar?"), nil, nil, nil, nil, "bar?"),
       StatementsNode(
         [CallNode(
            nil,
            nil,
            IDENTIFIER("foo"),
            nil,
            ArgumentsNode(
              [SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("a"), nil, "a"),
               SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("b"), nil, "b")]
            ),
            nil,
            nil,
            "foo"
          )]
       )
     )]
  )
)
