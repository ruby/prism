CaseNode(
  SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("hi"), nil, "hi"),
  [WhenNode(
     KEYWORD_WHEN("when"),
     [SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("hi"), nil, "hi")],
     nil
   )],
  ElseNode(
    KEYWORD_ELSE("else"),
    StatementsNode([SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("b"), nil, "b")]),
    KEYWORD_END("end")
  ),
  (0..4),
  (26..29)
)
