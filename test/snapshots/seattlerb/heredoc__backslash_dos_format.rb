ProgramNode(0...35)(
  ScopeNode(0...0)([IDENTIFIER(0...3)("str")]),
  StatementsNode(0...35)(
    [LocalVariableWriteNode(0...35)(
       (0...3),
       InterpolatedStringNode(6...35)(
         HEREDOC_START(6...12)("<<-XXX"),
         [StringNode(14...30)(
            nil,
            STRING_CONTENT(14...30)("before\\\r\n" + "after\r\n"),
            nil,
            "before\u0000\u0000after\r\n"
          )],
         HEREDOC_END(30...35)("XXX\r\n")
       ),
       (4...5),
       0
     )]
  )
)
