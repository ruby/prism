ProgramNode(0...43)(
  ScopeNode(0...0)([IDENTIFIER(0...1)("a")]),
  StatementsNode(0...43)(
    [LocalVariableWriteNode(0...43)(
       (0...1),
       HeredocNode(13...43)(
         HEREDOC_START(4...12)("<<~\"EOF\""),
         [StringNode(13...43)(
            nil,
            STRING_CONTENT(13...43)("        blah blah\n" + "\t blah blah\n"),
            nil,
            "blah blah\n" + " blah blah\n"
          )],
         HEREDOC_END(43...49)("  EOF\n"),
         8
       ),
       (2...3),
       0
     )]
  )
)
