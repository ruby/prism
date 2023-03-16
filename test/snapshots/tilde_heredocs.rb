ProgramNode(
  Scope([]),
  StatementsNode(
    [HeredocNode(
       HEREDOC_START("<<~EOF"),
       [StringNode(nil, STRING_CONTENT("  a\n"), nil, "a\n")],
       HEREDOC_END("EOF\n"),
       2
     ),
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
     ),
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
     ),
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
     ),
     HeredocNode(
       HEREDOC_START("<<~EOF"),
       [StringNode(nil, STRING_CONTENT("  a\n" + " "), nil, " a\n"),
        StringInterpolatedNode(
          EMBEXPR_BEGIN("\#{"),
          StatementsNode(
            [CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]
          ),
          EMBEXPR_END("}")
        ),
        StringNode(nil, STRING_CONTENT("\n"), nil, "\n")],
       HEREDOC_END("EOF\n"),
       1
     ),
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
     ),
     HeredocNode(
       HEREDOC_START("<<~EOF"),
       [StringNode(
          nil,
          STRING_CONTENT("  a\n" + "  b\n"),
          nil,
          "a\n" + "b\n"
        )],
       HEREDOC_END("EOF\n"),
       2
     ),
     ArrayNode([], BRACKET_LEFT_ARRAY("["), BRACKET_RIGHT("]")),
     HeredocNode(
       HEREDOC_START("<<~EOF"),
       [StringNode(
          nil,
          STRING_CONTENT("  a\n" + "   b\n"),
          nil,
          "a\n" + " b\n"
        )],
       HEREDOC_END("EOF\n"),
       2
     ),
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
     ),
     HeredocNode(
       HEREDOC_START("<<~'EOF'"),
       [StringNode(nil, STRING_CONTENT("  a \#{1}\n"), nil, "a \#{1}\n")],
       HEREDOC_END("EOF\n"),
       2
     ),
     HeredocNode(
       HEREDOC_START("<<~EOF"),
       [StringNode(
          nil,
          STRING_CONTENT("\ta\n" + "\t b\n"),
          nil,
          "a\n" + " b\n"
        )],
       HEREDOC_END("EOF\n"),
       8
     ),
     HeredocNode(
       HEREDOC_START("<<~EOF"),
       [StringNode(
          nil,
          STRING_CONTENT("\t a\n" + "\tb\n"),
          nil,
          " a\n" + "b\n"
        )],
       HEREDOC_END("EOF\n"),
       8
     )]
  )
)
