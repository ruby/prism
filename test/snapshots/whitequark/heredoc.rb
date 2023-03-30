ProgramNode(9...61)(
  ScopeNode(0...0)([]),
  StatementsNode(9...61)(
    [InterpolatedStringNode(9...17)(
       HEREDOC_START(0...8)("<<'HERE'"),
       [StringNode(9...17)(
          nil,
          STRING_CONTENT(9...17)("foo\n" + "bar\n"),
          nil,
          "foo\n" + "bar\n"
        )],
       HEREDOC_END(17...22)("HERE\n")
     ),
     InterpolatedStringNode(30...38)(
       HEREDOC_START(23...29)("<<HERE"),
       [StringNode(30...38)(
          nil,
          STRING_CONTENT(30...38)("foo\n" + "bar\n"),
          nil,
          "foo\n" + "bar\n"
        )],
       HEREDOC_END(38...43)("HERE\n")
     ),
     InterpolatedXStringNode(53...61)(
       HEREDOC_START(44...52)("<<`HERE`"),
       [StringNode(53...61)(
          nil,
          STRING_CONTENT(53...61)("foo\n" + "bar\n"),
          nil,
          "foo\n" + "bar\n"
        )],
       HEREDOC_END(61...66)("HERE\n")
     )]
  )
)
