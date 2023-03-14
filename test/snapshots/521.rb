HeredocNode(
  HEREDOC_START("<<~EOF"),
  [StringNode(
     nil,
     STRING_CONTENT("\t\t\ta\n" + "\t\tb\n"),
     nil,
     "\ta\n" + "b\n"
   )],
  HEREDOC_END("EOF\n"),
  16
)
