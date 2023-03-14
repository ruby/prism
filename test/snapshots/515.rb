HeredocNode(
  HEREDOC_START("<<~EOF"),
  [StringNode(nil, STRING_CONTENT("  "), nil, ""),
   StringInterpolatedNode(
     EMBEXPR_BEGIN("\#{"),
     StatementsNode([IntegerNode()]),
     EMBEXPR_END("}")
   ),
   StringNode(nil, STRING_CONTENT(" a\n"), nil, " a\n")],
  HEREDOC_END("EOF\n"),
  2
)
