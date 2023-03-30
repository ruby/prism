ProgramNode(9...23)(
  ScopeNode(0...0)([]),
  StatementsNode(9...23)(
    [InterpolatedStringNode(9...23)(
       HEREDOC_START(0...8)("<<~'FOO'"),
       [StringNode(9...23)(
          nil,
          STRING_CONTENT(9...23)("  baz\\\\\n" + "  qux\n"),
          nil,
          "baz\\\n" + "qux\n"
        )],
       HEREDOC_END(23...27)("FOO\n")
     )]
  )
)
