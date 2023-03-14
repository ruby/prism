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
          SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("h"), nil, "h"),
          ArrayNode(
            [SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("x"), nil, "x"),
             SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("y"), nil, "y")],
            BRACKET_LEFT_ARRAY("["),
            BRACKET_RIGHT("]")
          ),
          EQUAL_GREATER("=>")
        ),
        AssocNode(
          SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("a"), nil, "a"),
          SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("b"), nil, "b"),
          EQUAL_GREATER("=>")
        )],
       nil
     ),
     BlockArgumentNode(
       SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("bar"), nil, "bar"),
       (34..35)
     )]
  ),
  PARENTHESIS_RIGHT(")"),
  nil,
  "foo"
)
