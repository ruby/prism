CallNode(
  nil,
  nil,
  IDENTIFIER("foo"),
  nil,
  ArgumentsNode(
    [HashNode(
       nil,
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
       nil
     ),
     BlockArgumentNode(
       SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("block"), nil, "block"),
       (23..24)
     )]
  ),
  nil,
  nil,
  "foo"
)
