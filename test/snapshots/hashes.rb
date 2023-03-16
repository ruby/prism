ProgramNode(
  Scope([]),
  StatementsNode(
    [HashNode(BRACE_LEFT("{"), [], BRACE_RIGHT("}")),
     HashNode(BRACE_LEFT("{"), [], BRACE_RIGHT("}")),
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
     ),
     HashNode(
       BRACE_LEFT("{"),
       [AssocNode(
          CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a"),
          CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b"),
          EQUAL_GREATER("=>")
        ),
        AssocSplatNode(
          CallNode(nil, nil, IDENTIFIER("c"), nil, nil, nil, nil, "c"),
          (39..41)
        )],
       BRACE_RIGHT("}")
     ),
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
        )],
       BRACE_RIGHT("}")
     ),
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
          (95..97)
        ),
        AssocNode(
          SymbolNode(nil, LABEL("f"), LABEL_END(":"), "f"),
          CallNode(nil, nil, IDENTIFIER("g"), nil, nil, nil, nil, "g"),
          nil
        )],
       BRACE_RIGHT("}")
     )]
  )
)
