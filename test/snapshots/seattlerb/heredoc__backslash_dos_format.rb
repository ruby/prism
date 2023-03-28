ProgramNode(0...30)(
  ScopeNode(0...0)([IDENTIFIER(0...3)("str")]),
  StatementsNode(0...30)(
    [LocalVariableWriteNode(0...30)(
       IDENTIFIER(0...3)("str"),
       EQUAL(4...5)("="),
       HeredocNode(14...30)(
         HEREDOC_START(6...12)("<<-XXX"),
         [StringNode(14...30)(
            nil,
            STRING_CONTENT(14...30)("before\\\r\n" + "after\r\n"),
            nil,
            "before\r\n" + "after\r\n"
          )],
         HEREDOC_END(30...35)("XXX\r\n"),
         0
       )
     )]
  )
)
