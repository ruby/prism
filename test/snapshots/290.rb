IfNode(
  KEYWORD_IF("if"),
  AndNode(
    OrNode(
      CallNode(nil, nil, IDENTIFIER("bar?"), nil, nil, nil, nil, "bar?"),
      CallNode(nil, nil, IDENTIFIER("baz"), nil, nil, nil, nil, "baz"),
      (19..21)
    ),
    CallNode(nil, nil, IDENTIFIER("qux"), nil, nil, nil, nil, "qux"),
    KEYWORD_AND("and")
  ),
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
  ),
  nil,
  nil
)
