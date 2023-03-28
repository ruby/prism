ProgramNode(0...37)(
  ScopeNode(0...0)([IDENTIFIER(0...1)("a")]),
  StatementsNode(0...37)(
    [LocalVariableWriteNode(0...37)(
       (0...1),
       HeredocNode(13...37)(
         HEREDOC_START(4...12)("<<~\"EOF\""),
         [StringNode(13...37)(
            nil,
            STRING_CONTENT(13...37)("  blah blah\n" + " \tblah blah\n"),
            nil,
            "blah blah\n" + "\tblah blah\n"
          )],
         HEREDOC_END(37...43)("  EOF\n"),
         2
       ),
       (2...3)
     )]
  )
)
