ProgramNode(7...22)(
  ScopeNode(0...0)([]),
  StatementsNode(7...22)(
    [HeredocNode(7...22)(
       HEREDOC_START(0...5)("<<EOS"),
       [StringNode(7...22)(
          nil,
          STRING_CONTENT(7...22)("foo\rbar\r\r\n" + "baz\r\n"),
          nil,
          "foo\rbar\r\r\n" + "baz\r\n"
        )],
       HEREDOC_END(22...27)("EOS\r\n"),
       0
     )]
  )
)
