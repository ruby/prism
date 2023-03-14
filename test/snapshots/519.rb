HeredocNode(
  HEREDOC_START("<<~EOF"),
  [StringNode(nil, STRING_CONTENT("  a\n" + "  b\n"), nil, "a\n" + "b\n")],
  HEREDOC_END("EOF\n"),
  2
)
