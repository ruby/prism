HeredocNode(
  HEREDOC_START("<<~EOF"),
  [StringNode(
     nil,
     STRING_CONTENT("\ta\n" + "  b\n" + "\t\tc\n"),
     nil,
     "\ta\n" + "b\n" + "\t\tc\n"
   )],
  HEREDOC_END("EOF\n"),
  2
)
