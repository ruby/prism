CallNode(
  nil,
  nil,
  IDENTIFIER("hi"),
  nil,
  ArgumentsNode(
    [IntegerNode(),
     HashNode(
       BRACE_LEFT("{"),
       [AssocNode(
          SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("there"), nil, "there"),
          SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("friend"), nil, "friend"),
          EQUAL_GREATER("=>")
        ),
        AssocSplatNode(
          HashNode(BRACE_LEFT("{"), [], BRACE_RIGHT("}")),
          (29..31)
        ),
        AssocNode(
          SymbolNode(nil, LABEL("whatup"), LABEL_END(":"), "whatup"),
          SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("dog"), nil, "dog"),
          nil
        )],
       BRACE_RIGHT("}")
     )]
  ),
  nil,
  nil,
  "hi"
)
