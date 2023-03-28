ProgramNode(6...67)(
  ScopeNode(0...0)([IDENTIFIER(6...12)("string")]),
  StatementsNode(6...67)(
    [LocalVariableWriteNode(6...48)(
       IDENTIFIER(6...12)("string"),
       EQUAL(13...14)("="),
       HeredocNode(23...48)(
         HEREDOC_START(15...22)("<<-\"^D\""),
         [StringNode(23...48)(
            nil,
            STRING_CONTENT(23...48)("        very long string\n"),
            nil,
            "        very long string\n"
          )],
         HEREDOC_END(48...57)("      ^D\n"),
         0
       )
     ),
     CallNode(63...67)(
       nil,
       nil,
       IDENTIFIER(63...67)("puts"),
       nil,
       ArgumentsNode(68...74)(
         [LocalVariableReadNode(68...74)(IDENTIFIER(68...74)("string"))]
       ),
       nil,
       nil,
       "puts"
     )]
  )
)
