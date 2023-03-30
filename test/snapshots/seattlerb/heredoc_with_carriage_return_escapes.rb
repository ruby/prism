ProgramNode(6...21)(
  ScopeNode(0...0)([]),
  StatementsNode(6...21)(
    [InterpolatedStringNode(6...21)(
       HEREDOC_START(0...5)("<<EOS"),
       [StringNode(6...21)(
          nil,
          STRING_CONTENT(6...21)("foo\\rbar\n" + "baz\\r\n"),
          nil,
          "foo\rbar\n" + "baz\r\n"
        )],
       HEREDOC_END(21...25)("EOS\n")
     )]
  )
)
