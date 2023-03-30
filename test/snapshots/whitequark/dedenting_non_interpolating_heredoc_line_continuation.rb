ProgramNode(9...22)(
  ScopeNode(0...0)([]),
  StatementsNode(9...22)(
    [InterpolatedStringNode(9...22)(
       HEREDOC_START(0...8)("<<~'FOO'"),
       [StringNode(9...22)(
          nil,
          STRING_CONTENT(9...22)("  baz\\\n" + "  qux\n"),
          nil,
          "baz\n" + "qux\n"
        )],
       HEREDOC_END(22...26)("FOO\n")
     )]
  )
)
