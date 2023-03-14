HashNode(
  BRACE_LEFT("{"),
  [AssocNode(
     CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a"),
     CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b"),
     EQUAL_GREATER("=>")
   ),
   AssocSplatNode(
     CallNode(nil, nil, IDENTIFIER("c"), nil, nil, nil, nil, "c"),
     (10..12)
   )],
  BRACE_RIGHT("}")
)
