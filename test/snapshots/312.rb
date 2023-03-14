CallNode(
  nil,
  nil,
  IDENTIFIER("hi"),
  nil,
  ArgumentsNode(
    [HashNode(
       nil,
       [AssocNode(
          SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("there"), nil, "there"),
          SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("friend"), nil, "friend"),
          EQUAL_GREATER("=>")
        ),
        AssocSplatNode(
          HashNode(BRACE_LEFT("{"), [], BRACE_RIGHT("}")),
          (22..24)
        ),
        AssocNode(
          SymbolNode(nil, LABEL("whatup"), LABEL_END(":"), "whatup"),
          SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("dog"), nil, "dog"),
          nil
        )],
       nil
     )]
  ),
  nil,
  nil,
  "hi"
)
