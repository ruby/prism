ProgramNode(0...25)(
  ScopeNode(0...0)([IDENTIFIER(0...1)("a")]),
  StatementsNode(0...25)(
    [LocalVariableWriteNode(0...25)(
       (0...1),
       HeredocNode(13...25)(
         HEREDOC_START(4...12)("<<~\"EOF\""),
         [StringNode(13...25)(
            nil,
            STRING_CONTENT(13...25)("  x\n" + "  y\n" + "  z\n"),
            nil,
            "x\n" + "y\n" + "z\n"
          )],
         HEREDOC_END(25...31)("  EOF\n"),
         2
       ),
       (2...3)
     )]
  )
)
