ProgramNode(
  Scope([]),
  StatementsNode(
    [HeredocNode(
       HEREDOC_START("<<-EOF"),
       [StringNode(nil, STRING_CONTENT("  a\n"), nil, "  a\n")],
       HEREDOC_END("EOF\n"),
       0
     ),
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
     ),
     InterpolatedXStringNode(
       HEREDOC_START("<<-`EOF`"),
       [StringNode(nil, STRING_CONTENT("  a\n"), nil, "  a\n"),
        StringInterpolatedNode(
          EMBEXPR_BEGIN("\#{"),
          StatementsNode(
            [CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]
          ),
          EMBEXPR_END("}")
        ),
        StringNode(nil, STRING_CONTENT("\n"), nil, "\n")],
       HEREDOC_END("EOF\n")
     ),
     HeredocNode(
       HEREDOC_START("<<-EOF"),
       [StringNode(nil, STRING_CONTENT("  a\n"), nil, "  a\n")],
       HEREDOC_END("EOF\n"),
       0
     ),
     HeredocNode(
       HEREDOC_START("<<-EOF"),
       [StringNode(
          nil,
          STRING_CONTENT("  a\n" + "  b\n"),
          nil,
          "  a\n" + "  b\n"
        )],
       HEREDOC_END("  EOF\n"),
       0
     ),
     HeredocNode(
       HEREDOC_START("<<-\"EOF\""),
       [StringNode(nil, STRING_CONTENT("  a\n"), nil, "  a\n"),
        StringInterpolatedNode(
          EMBEXPR_BEGIN("\#{"),
          StatementsNode(
            [CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]
          ),
          EMBEXPR_END("}")
        ),
        StringNode(nil, STRING_CONTENT("\n"), nil, "\n")],
       HEREDOC_END("EOF\n"),
       0
     ),
     HeredocNode(
       HEREDOC_START("<<-EOF"),
       [StringNode(nil, STRING_CONTENT("  a\n"), nil, "  a\n"),
        StringInterpolatedNode(
          EMBEXPR_BEGIN("\#{"),
          StatementsNode(
            [CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]
          ),
          EMBEXPR_END("}")
        ),
        StringNode(nil, STRING_CONTENT("\n"), nil, "\n")],
       HEREDOC_END("EOF\n"),
       0
     ),
     StringNode(
       STRING_BEGIN("%#"),
       STRING_CONTENT("abc"),
       STRING_END("#"),
       "abc"
     ),
     HeredocNode(
       HEREDOC_START("<<-EOF"),
       [StringNode(
          nil,
          STRING_CONTENT("  a\n" + "  b\n"),
          nil,
          "  a\n" + "  b\n"
        )],
       HEREDOC_END("EOF\n"),
       0
     ),
     HeredocNode(
       HEREDOC_START("<<-'EOF'"),
       [StringNode(nil, STRING_CONTENT("  a \#{1}\n"), nil, "  a \#{1}\n")],
       HEREDOC_END("EOF\n"),
       0
     )]
  )
)
