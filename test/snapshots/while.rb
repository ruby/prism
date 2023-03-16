ProgramNode(
  Scope([]),
  StatementsNode(
    [WhileNode(
       KEYWORD_WHILE("while"),
       TrueNode(),
       StatementsNode([IntegerNode()])
     ),
     WhileNode(
       KEYWORD_WHILE_MODIFIER("while"),
       TrueNode(),
       StatementsNode([IntegerNode()])
     ),
     WhileNode(
       KEYWORD_WHILE_MODIFIER("while"),
       TrueNode(),
       StatementsNode([BreakNode(nil, (34..39))])
     ),
     WhileNode(
       KEYWORD_WHILE_MODIFIER("while"),
       TrueNode(),
       StatementsNode([NextNode(nil, (52..56))])
     ),
     WhileNode(
       KEYWORD_WHILE_MODIFIER("while"),
       TrueNode(),
       StatementsNode([ReturnNode(KEYWORD_RETURN("return"), nil)])
     ),
     WhileNode(
       KEYWORD_WHILE_MODIFIER("while"),
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
