ProgramNode(
  Scope([]),
  StatementsNode(
    [UndefNode([SymbolNode(nil, IDENTIFIER("a"), nil, "a")], (0..5)),
     UndefNode(
       [SymbolNode(nil, IDENTIFIER("a"), nil, "a"),
        SymbolNode(nil, IDENTIFIER("b"), nil, "b")],
       (9..14)
     ),
     UndefNode([SymbolNode(nil, KEYWORD_IF("if"), nil, "if")], (21..26)),
     UndefNode(
       [SymbolNode(nil, LESS_EQUAL_GREATER("<=>"), nil, "<=>")],
       (31..36)
     ),
     UndefNode(
       [SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("a"), nil, "a")],
       (42..47)
     ),
     UndefNode(
       [SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("a"), nil, "a"),
        SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("b"), nil, "b"),
        SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("c"), nil, "c")],
       (52..57)
     ),
     UndefNode(
       [SymbolNode(
          SYMBOL_BEGIN(":'"),
          STRING_CONTENT("abc"),
          STRING_END("'"),
          "abc"
        )],
       (70..75)
     ),
     UndefNode(
       [InterpolatedSymbolNode(
          SYMBOL_BEGIN(":\""),
          [StringNode(nil, STRING_CONTENT("abc"), nil, "abc"),
           StringInterpolatedNode(
             EMBEXPR_BEGIN("\#{"),
             StatementsNode([IntegerNode()]),
             EMBEXPR_END("}")
           )],
          STRING_END("\"")
        )],
       (84..89)
     )]
  )
)
