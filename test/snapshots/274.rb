CallNode(
  HeredocNode(
    HEREDOC_START("<<-FIRST"),
    [StringNode(nil, STRING_CONTENT("  a\n"), nil, "  a\n")],
    HEREDOC_END("FIRST\n"),
    0
  ),
  nil,
  PLUS("+"),
  nil,
  ArgumentsNode(
    [HeredocNode(
       HEREDOC_START("<<-SECOND"),
       [StringNode(nil, STRING_CONTENT("  b\n"), nil, "  b\n")],
       HEREDOC_END("SECOND\n"),
       0
     )]
  ),
  nil,
  nil,
  "+"
)
