HashNode(
  BRACE_LEFT("{"),
  [AssocNode(
     SymbolNode(nil, LABEL("a"), LABEL_END(":"), "a"),
     CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b"),
     nil
   ),
   AssocNode(
     SymbolNode(nil, LABEL("c"), LABEL_END(":"), "c"),
     CallNode(nil, nil, IDENTIFIER("d"), nil, nil, nil, nil, "d"),
     nil
   ),
   AssocSplatNode(
     CallNode(nil, nil, IDENTIFIER("e"), nil, nil, nil, nil, "e"),
     (14..16)
   ),
   AssocNode(
     SymbolNode(nil, LABEL("f"), LABEL_END(":"), "f"),
     CallNode(nil, nil, IDENTIFIER("g"), nil, nil, nil, nil, "g"),
     nil
   )],
  BRACE_RIGHT("}")
)
