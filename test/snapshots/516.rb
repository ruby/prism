HeredocNode(
  HEREDOC_START("<<~EOF"),
  [StringNode(nil, STRING_CONTENT("  a "), nil, "a "),
   StringInterpolatedNode(
     EMBEXPR_BEGIN("\#{"),
     StatementsNode([IntegerNode()]),
     EMBEXPR_END("}")
   ),
   StringNode(nil, STRING_CONTENT("\n"), nil, "\n")],
  HEREDOC_END("EOF\n"),
  2
)
