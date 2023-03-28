ProgramNode(6...17)(
  ScopeNode(0...0)([]),
  StatementsNode(6...17)(
    [HeredocNode(6...17)(
       HEREDOC_START(0...5)("<<EOS"),
       [StringNode(6...11)(
          nil,
          STRING_CONTENT(6...11)("foo\\r"),
          nil,
          "foo\r"
        ),
        InstanceVariableReadNode(12...16)(),
        StringNode(16...17)(nil, STRING_CONTENT(16...17)("\n"), nil, "\n")],
       HEREDOC_END(17...21)("EOS\n"),
       0
     )]
  )
)
