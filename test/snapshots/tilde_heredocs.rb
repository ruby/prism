ProgramNode(7...248)(
  Scope(0...0)([]),
  StatementsNode(7...248)(
    [HeredocNode(7...11)(
       HEREDOC_START(0...6)("<<~EOF"),
       [StringNode(7...11)(nil, STRING_CONTENT(7...11)("  a\n"), nil, "a\n")],
       HEREDOC_END(11...15)("EOF\n"),
       2
     ),
     HeredocNode(23...34)(
       HEREDOC_START(16...22)("<<~EOF"),
       [StringNode(23...34)(
          nil,
          STRING_CONTENT(23...34)("\ta\n" + "  b\n" + "\t\tc\n"),
          nil,
          "\ta\n" + "b\n" + "\t\tc\n"
        )],
       HEREDOC_END(34...38)("EOF\n"),
       2
     ),
     HeredocNode(46...55)(
       HEREDOC_START(39...45)("<<~EOF"),
       [StringNode(46...48)(nil, STRING_CONTENT(46...48)("  "), nil, ""),
        StringInterpolatedNode(48...52)(
          EMBEXPR_BEGIN(48...50)("\#{"),
          StatementsNode(50...51)([IntegerNode(50...51)()]),
          EMBEXPR_END(51...52)("}")
        ),
        StringNode(52...55)(
          nil,
          STRING_CONTENT(52...55)(" a\n"),
          nil,
          " a\n"
        )],
       HEREDOC_END(55...59)("EOF\n"),
       2
     ),
     HeredocNode(67...76)(
       HEREDOC_START(60...66)("<<~EOF"),
       [StringNode(67...71)(nil, STRING_CONTENT(67...71)("  a "), nil, "a "),
        StringInterpolatedNode(71...75)(
          EMBEXPR_BEGIN(71...73)("\#{"),
          StatementsNode(73...74)([IntegerNode(73...74)()]),
          EMBEXPR_END(74...75)("}")
        ),
        StringNode(75...76)(nil, STRING_CONTENT(75...76)("\n"), nil, "\n")],
       HEREDOC_END(76...80)("EOF\n"),
       2
     ),
     HeredocNode(88...98)(
       HEREDOC_START(81...87)("<<~EOF"),
       [StringNode(88...93)(
          nil,
          STRING_CONTENT(88...93)("  a\n" + " "),
          nil,
          " a\n"
        ),
        StringInterpolatedNode(93...97)(
          EMBEXPR_BEGIN(93...95)("\#{"),
          StatementsNode(95...96)(
            [CallNode(95...96)(
               nil,
               nil,
               IDENTIFIER(95...96)("b"),
               nil,
               nil,
               nil,
               nil,
               "b"
             )]
          ),
          EMBEXPR_END(96...97)("}")
        ),
        StringNode(97...98)(nil, STRING_CONTENT(97...98)("\n"), nil, "\n")],
       HEREDOC_END(98...102)("EOF\n"),
       1
     ),
     HeredocNode(110...121)(
       HEREDOC_START(103...109)("<<~EOF"),
       [StringNode(110...116)(
          nil,
          STRING_CONTENT(110...116)("  a\n" + "  "),
          nil,
          "a\n"
        ),
        StringInterpolatedNode(116...120)(
          EMBEXPR_BEGIN(116...118)("\#{"),
          StatementsNode(118...119)(
            [CallNode(118...119)(
               nil,
               nil,
               IDENTIFIER(118...119)("b"),
               nil,
               nil,
               nil,
               nil,
               "b"
             )]
          ),
          EMBEXPR_END(119...120)("}")
        ),
        StringNode(120...121)(
          nil,
          STRING_CONTENT(120...121)("\n"),
          nil,
          "\n"
        )],
       HEREDOC_END(121...125)("EOF\n"),
       2
     ),
     HeredocNode(133...141)(
       HEREDOC_START(126...132)("<<~EOF"),
       [StringNode(133...141)(
          nil,
          STRING_CONTENT(133...141)("  a\n" + "  b\n"),
          nil,
          "a\n" + "b\n"
        )],
       HEREDOC_END(141...145)("EOF\n"),
       2
     ),
     ArrayNode(146...148)(
       [],
       BRACKET_LEFT_ARRAY(146...147)("["),
       BRACKET_RIGHT(147...148)("]")
     ),
     HeredocNode(157...166)(
       HEREDOC_START(150...156)("<<~EOF"),
       [StringNode(157...166)(
          nil,
          STRING_CONTENT(157...166)("  a\n" + "   b\n"),
          nil,
          "a\n" + " b\n"
        )],
       HEREDOC_END(166...170)("EOF\n"),
       2
     ),
     HeredocNode(178...187)(
       HEREDOC_START(171...177)("<<~EOF"),
       [StringNode(178...187)(
          nil,
          STRING_CONTENT(178...187)("\t\t\ta\n" + "\t\tb\n"),
          nil,
          "\ta\n" + "b\n"
        )],
       HEREDOC_END(187...191)("EOF\n"),
       16
     ),
     HeredocNode(201...210)(
       HEREDOC_START(192...200)("<<~'EOF'"),
       [StringNode(201...210)(
          nil,
          STRING_CONTENT(201...210)("  a \#{1}\n"),
          nil,
          "a \#{1}\n"
        )],
       HEREDOC_END(210...214)("EOF\n"),
       2
     ),
     HeredocNode(222...229)(
       HEREDOC_START(215...221)("<<~EOF"),
       [StringNode(222...229)(
          nil,
          STRING_CONTENT(222...229)("\ta\n" + "\t b\n"),
          nil,
          "a\n" + " b\n"
        )],
       HEREDOC_END(229...233)("EOF\n"),
       8
     ),
     HeredocNode(241...248)(
       HEREDOC_START(234...240)("<<~EOF"),
       [StringNode(241...248)(
          nil,
          STRING_CONTENT(241...248)("\t a\n" + "\tb\n"),
          nil,
          " a\n" + "b\n"
        )],
       HEREDOC_END(248...252)("EOF\n"),
       8
     )]
  )
)
