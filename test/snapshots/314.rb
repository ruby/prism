CallNode(
  nil,
  nil,
  IDENTIFIER("foo"),
  PARENTHESIS_LEFT("("),
  ArgumentsNode(
    [HashNode(
       BRACE_LEFT("{"),
       [AssocNode(
          SymbolNode(nil, LABEL("a"), LABEL_END(":"), "a"),
          TrueNode(),
          nil
        ),
        AssocNode(
          SymbolNode(nil, LABEL("b"), LABEL_END(":"), "b"),
          FalseNode(),
          nil
        )],
       BRACE_RIGHT("}")
     ),
     BlockArgumentNode(
       SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("block"), nil, "block"),
       (28..29)
     )]
  ),
  PARENTHESIS_RIGHT(")"),
  nil,
  "foo"
)
