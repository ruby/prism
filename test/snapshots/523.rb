HeredocNode(
  HEREDOC_START("<<~EOF"),
  [StringNode(nil, STRING_CONTENT("\ta\n" + "\t b\n"), nil, "a\n" + " b\n")],
  HEREDOC_END("EOF\n"),
  8
)
