HashNode(
  BRACE_LEFT("{"),
  [AssocNode(
     CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a"),
     CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b"),
     EQUAL_GREATER("=>")
   ),
   AssocNode(
     CallNode(nil, nil, IDENTIFIER("c"), nil, nil, nil, nil, "c"),
     CallNode(nil, nil, IDENTIFIER("d"), nil, nil, nil, nil, "d"),
     EQUAL_GREATER("=>")
   )],
  BRACE_RIGHT("}")
)
