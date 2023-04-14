ProgramNode(0...1)(
  ScopeNode(0...0)([]),
  StatementsNode(0...1)(
    [CallNode(0...1)(
       nil,
       nil,
       IDENTIFIER(0...1)("p"),
       nil,
       ArgumentsNode(2...30)(
         [StringNode(2...30)(
            STRING_BEGIN(2...3)("\""),
            STRING_CONTENT(3...29)(
              "123\n" + "456\n" + "789\\nabc\n" + "def\\nghi\n"
            ),
            STRING_END(29...30)("\""),
            "123\n" + "456\n" + "789\n" + "abc\n" + "def\n" + "ghi\n"
          )]
       ),
       nil,
       nil,
       "p"
     )]
  )
)
