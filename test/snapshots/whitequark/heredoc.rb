ProgramNode(0...66)(
  [],
  StatementsNode(0...66)(
    [InterpolatedStringNode(0...22)(
       (0...8),
       [StringNode(9...17)(
          nil,
          STRING_CONTENT(9...17)("foo\n" + "bar\n"),
          nil,
          "foo\n" + "bar\n"
        )],
       (17...22)
     ),
     InterpolatedStringNode(23...43)(
       (23...29),
       [StringNode(30...38)(
          nil,
          STRING_CONTENT(30...38)("foo\n" + "bar\n"),
          nil,
          "foo\n" + "bar\n"
        )],
       (38...43)
     ),
     InterpolatedXStringNode(44...66)(
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
