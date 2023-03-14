HeredocNode(
  HEREDOC_START("<<~EOF"),
  [StringNode(nil, STRING_CONTENT("\t a\n" + "\tb\n"), nil, " a\n" + "b\n")],
  HEREDOC_END("EOF\n"),
  8
)
