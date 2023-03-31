ProgramNode(7...396)(
  ScopeNode(0...0)([]),
  StatementsNode(7...396)(
    [InterpolatedStringNode(7...11)(
       HEREDOC_START(0...6)("<<~EOF"),
       [StringNode(7...11)(nil, STRING_CONTENT(7...11)("  a\n"), nil, "a\n")],
       HEREDOC_END(11...15)("EOF\n")
     ),
     InterpolatedStringNode(23...34)(
       HEREDOC_START(16...22)("<<~EOF"),
       [StringNode(23...34)(
          nil,
          STRING_CONTENT(23...34)("\ta\n" + "  b\n" + "\t\tc\n"),
          nil,
          "\ta\n" + "b\n" + "\t\tc\n"
        )],
       HEREDOC_END(34...38)("EOF\n")
     ),
     InterpolatedStringNode(46...55)(
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
       HEREDOC_END(55...59)("EOF\n")
     ),
     InterpolatedStringNode(67...76)(
       HEREDOC_START(60...66)("<<~EOF"),
       [StringNode(67...71)(nil, STRING_CONTENT(67...71)("  a "), nil, "a "),
        StringInterpolatedNode(71...75)(
          EMBEXPR_BEGIN(71...73)("\#{"),
          StatementsNode(73...74)([IntegerNode(73...74)()]),
          EMBEXPR_END(74...75)("}")
        ),
        StringNode(75...76)(nil, STRING_CONTENT(75...76)("\n"), nil, "\n")],
       HEREDOC_END(76...80)("EOF\n")
     ),
     InterpolatedStringNode(88...98)(
       HEREDOC_START(81...87)("<<~EOF"),
       [StringNode(88...93)(
          nil,
          STRING_CONTENT(88...93)("  a\n" + " "),
          nil,
          " a\n"
        ),
        StringInterpolatedNode(93...97)(
          EMBEXPR_BEGIN(93...95)("\#{"),
          StatementsNode(95...96)([IntegerNode(95...96)()]),
          EMBEXPR_END(96...97)("}")
        ),
        StringNode(97...98)(nil, STRING_CONTENT(97...98)("\n"), nil, "\n")],
       HEREDOC_END(98...102)("EOF\n")
     ),
     InterpolatedStringNode(110...121)(
       HEREDOC_START(103...109)("<<~EOF"),
       [StringNode(110...116)(
          nil,
          STRING_CONTENT(110...116)("  a\n" + "  "),
          nil,
          "a\n"
        ),
        StringInterpolatedNode(116...120)(
          EMBEXPR_BEGIN(116...118)("\#{"),
          StatementsNode(118...119)([IntegerNode(118...119)()]),
          EMBEXPR_END(119...120)("}")
        ),
        StringNode(120...121)(
          nil,
          STRING_CONTENT(120...121)("\n"),
          nil,
          "\n"
        )],
       HEREDOC_END(121...125)("EOF\n")
     ),
     InterpolatedStringNode(133...141)(
       HEREDOC_START(126...132)("<<~EOF"),
       [StringNode(133...141)(
          nil,
          STRING_CONTENT(133...141)("  a\n" + "  b\n"),
          nil,
          "a\n" + "b\n"
        )],
       HEREDOC_END(141...145)("EOF\n")
     ),
     InterpolatedStringNode(153...162)(
       HEREDOC_START(146...152)("<<~EOF"),
       [StringNode(153...162)(
          nil,
          STRING_CONTENT(153...162)("  a\n" + "   b\n"),
          nil,
          "a\n" + " b\n"
        )],
       HEREDOC_END(162...166)("EOF\n")
     ),
     InterpolatedStringNode(174...183)(
       HEREDOC_START(167...173)("<<~EOF"),
       [StringNode(174...183)(
          nil,
          STRING_CONTENT(174...183)("\t\t\ta\n" + "\t\tb\n"),
          nil,
          "\ta\n" + "b\n"
        )],
       HEREDOC_END(183...187)("EOF\n")
     ),
     InterpolatedStringNode(197...206)(
       HEREDOC_START(188...196)("<<~'EOF'"),
       [StringNode(197...206)(
          nil,
          STRING_CONTENT(197...206)("  a \#{1}\n"),
          nil,
          "a \#{1}\n"
        )],
       HEREDOC_END(206...210)("EOF\n")
     ),
     InterpolatedStringNode(218...225)(
       HEREDOC_START(211...217)("<<~EOF"),
       [StringNode(218...225)(
          nil,
          STRING_CONTENT(218...225)("\ta\n" + "\t b\n"),
          nil,
          "a\n" + " b\n"
        )],
       HEREDOC_END(225...229)("EOF\n")
     ),
     InterpolatedStringNode(237...244)(
       HEREDOC_START(230...236)("<<~EOF"),
       [StringNode(237...244)(
          nil,
          STRING_CONTENT(237...244)("\t a\n" + "\tb\n"),
          nil,
          " a\n" + "b\n"
        )],
       HEREDOC_END(244...248)("EOF\n")
     ),
     InterpolatedStringNode(256...271)(
       HEREDOC_START(249...255)("<<~EOF"),
       [StringNode(256...271)(
          nil,
          STRING_CONTENT(256...271)("  \ta\n" + "        b\n"),
          nil,
          "a\n" + "b\n"
        )],
       HEREDOC_END(271...275)("EOF\n")
     ),
     InterpolatedStringNode(283...293)(
       HEREDOC_START(276...282)("<<~EOF"),
       [StringNode(283...293)(
          nil,
          STRING_CONTENT(283...293)("  a\n" + " \n" + "  b\n"),
          nil,
          "a\n" + "\n" + "b\n"
        )],
       HEREDOC_END(293...297)("EOF\n")
     ),
     InterpolatedStringNode(305...318)(
       HEREDOC_START(298...304)("<<~EOF"),
       [StringNode(305...318)(
          nil,
          STRING_CONTENT(305...318)("  a\n" + "    \n" + "  b\n"),
          nil,
          "a\n" + "  \n" + "b\n"
        )],
       HEREDOC_END(318...322)("EOF\n")
     ),
     InterpolatedStringNode(330...349)(
       HEREDOC_START(323...329)("<<~EOF"),
       [StringNode(330...349)(
          nil,
          STRING_CONTENT(330...349)(
            "  a\n" + "    \n" + "\n" + "    \n" + "  b\n"
          ),
          nil,
          "a\n" + "  \n" + "\n" + "  \n" + "b\n"
        )],
       HEREDOC_END(349...353)("EOF\n")
     ),
     InterpolatedStringNode(361...370)(
       HEREDOC_START(354...360)("<<~EOF"),
       [StringNode(361...364)(
          nil,
          STRING_CONTENT(361...364)("\n" + "  "),
          nil,
          "\n"
        ),
        StringInterpolatedNode(364...368)(
          EMBEXPR_BEGIN(364...366)("\#{"),
          StatementsNode(366...367)([IntegerNode(366...367)()]),
          EMBEXPR_END(367...368)("}")
        ),
        StringNode(368...370)(
          nil,
          STRING_CONTENT(368...370)("a\n"),
          nil,
          "a\n"
        )],
       HEREDOC_END(370...378)("    EOF\n")
     ),
     InterpolatedStringNode(386...396)(
       HEREDOC_START(379...385)("<<~EOT"),
       [StringNode(386...388)(nil, STRING_CONTENT(386...388)("  "), nil, ""),
        StringInterpolatedNode(388...392)(
          EMBEXPR_BEGIN(388...390)("\#{"),
          StatementsNode(390...391)([IntegerNode(390...391)()]),
          EMBEXPR_END(391...392)("}")
        ),
        StringNode(392...396)(
          nil,
          STRING_CONTENT(392...396)("\n" + "\tb\n"),
          nil,
          "\n" + "\tb\n"
        )],
       HEREDOC_END(396...400)("EOT\n")
     )]
  )
)
