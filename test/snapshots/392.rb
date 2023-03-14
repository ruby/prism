HashNode(
  BRACE_LEFT("{"),
  [AssocNode(
     SymbolNode(nil, LABEL("foo"), LABEL_END(":"), "foo"),
     RangeNode(
       nil,
       CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar"),
       (7..10)
     ),
     nil
   )],
  BRACE_RIGHT("}")
)
