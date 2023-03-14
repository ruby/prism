HeredocNode(
  HEREDOC_START("<<~EOF"),
  [StringNode(nil, STRING_CONTENT("  a\n" + "  "), nil, "a\n"),
   StringInterpolatedNode(
     EMBEXPR_BEGIN("\#{"),
     StatementsNode(
       [CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]
     ),
     EMBEXPR_END("}")
   ),
   StringNode(nil, STRING_CONTENT("\n"), nil, "\n")],
  HEREDOC_END("EOF\n"),
  2
)
