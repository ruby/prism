ProgramNode(2...35)(
  ScopeNode(0...0)([]),
  StatementsNode(2...35)(
    [HashNode(2...8)(
       BRACE_LEFT(0...1)("{"),
       [AssocNode(2...8)(
          IntegerNode(2...3)((2...3), 10),
          IntegerNode(7...8)((7...8), 10),
          EQUAL_GREATER(4...6)("=>")
        )],
       BRACE_RIGHT(9...10)("}")
     ),
     HashNode(14...35)(
       BRACE_LEFT(12...13)("{"),
       [AssocNode(14...20)(
          IntegerNode(14...15)((14...15), 10),
          IntegerNode(19...20)((19...20), 10),
          EQUAL_GREATER(16...18)("=>")
        ),
        AssocNode(22...35)(
          SymbolNode(22...26)(
            SYMBOL_BEGIN(22...23)(":"),
            IDENTIFIER(23...26)("foo"),
            nil,
            "foo"
          ),
          StringNode(30...35)(
            STRING_BEGIN(30...31)("\""),
            STRING_CONTENT(31...34)("bar"),
            STRING_END(34...35)("\""),
            "bar"
          ),
          EQUAL_GREATER(27...29)("=>")
        )],
       BRACE_RIGHT(36...37)("}")
     )]
  )
)
