CallNode(
  nil,
  nil,
  IDENTIFIER("foo"),
  PARENTHESIS_LEFT("("),
  ArgumentsNode(
    [SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("a"), nil, "a"),
     HashNode(
       nil,
       [AssocNode(
          SymbolNode(nil, LABEL("b"), LABEL_END(":"), "b"),
          SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("c"), nil, "c"),
          nil
        )],
       nil
     )]
  ),
  PARENTHESIS_RIGHT(")"),
  nil,
  "foo"
)
