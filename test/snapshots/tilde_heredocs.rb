ProgramNode(0...387)(
  [],
  StatementsNode(0...387)(
    [InterpolatedStringNode(0...15)(
       (0...6),
       [StringNode(7...11)(nil, STRING_CONTENT(7...11)("  a\n"), nil, "a\n")],
       (11...15)
     ),
     InterpolatedStringNode(16...38)(
       (16...22),
       [StringNode(23...34)(
          nil,
          STRING_CONTENT(23...34)("\ta\n" + "  b\n" + "\t\tc\n"),
          nil,
          "\ta\n" + "b\n" + "\t\tc\n"
        )],
       (34...38)
     ),
     InterpolatedStringNode(39...59)(
       (39...45),
       [StringNode(46...48)(nil, STRING_CONTENT(46...48)("  "), nil, ""),
        StringInterpolatedNode(48...52)(
          (48...50),
          StatementsNode(50...51)([IntegerNode(50...51)()]),
          (51...52)
        ),
        StringNode(52...55)(
          nil,
          STRING_CONTENT(52...55)(" a\n"),
          nil,
          " a\n"
        )],
       (55...59)
     ),
     InterpolatedStringNode(60...80)(
       (60...66),
       [StringNode(67...71)(nil, STRING_CONTENT(67...71)("  a "), nil, "a "),
        StringInterpolatedNode(71...75)(
          (71...73),
          StatementsNode(73...74)([IntegerNode(73...74)()]),
          (74...75)
        ),
        StringNode(75...76)(nil, STRING_CONTENT(75...76)("\n"), nil, "\n")],
       (76...80)
     ),
     InterpolatedStringNode(81...102)(
       (81...87),
       [StringNode(88...93)(
          nil,
          STRING_CONTENT(88...93)("  a\n" + " "),
          nil,
          " a\n"
        ),
        StringInterpolatedNode(93...97)(
          (93...95),
          StatementsNode(95...96)([IntegerNode(95...96)()]),
          (96...97)
        ),
        StringNode(97...98)(nil, STRING_CONTENT(97...98)("\n"), nil, "\n")],
       (98...102)
     ),
     InterpolatedStringNode(103...125)(
       (103...109),
       [StringNode(110...116)(
          nil,
          STRING_CONTENT(110...116)("  a\n" + "  "),
          nil,
          "a\n"
        ),
        StringInterpolatedNode(116...120)(
          (116...118),
          StatementsNode(118...119)([IntegerNode(118...119)()]),
          (119...120)
        ),
        StringNode(120...121)(
          nil,
          STRING_CONTENT(120...121)("\n"),
          nil,
          "\n"
        )],
       (121...125)
     ),
     InterpolatedStringNode(126...145)(
       (126...132),
       [StringNode(133...141)(
          nil,
          STRING_CONTENT(133...141)("  a\n" + "  b\n"),
          nil,
          "a\n" + "b\n"
        )],
       (141...145)
     ),
     InterpolatedStringNode(146...166)(
       (146...152),
       [StringNode(153...162)(
          nil,
          STRING_CONTENT(153...162)("  a\n" + "   b\n"),
          nil,
          "a\n" + " b\n"
        )],
       (162...166)
     ),
     InterpolatedStringNode(167...187)(
       (167...173),
       [StringNode(174...183)(
          nil,
          STRING_CONTENT(174...183)("\t\t\ta\n" + "\t\tb\n"),
          nil,
          "\ta\n" + "b\n"
        )],
       (183...187)
     ),
     InterpolatedStringNode(188...210)(
       (188...196),
       [StringNode(197...206)(
          nil,
          STRING_CONTENT(197...206)("  a \#{1}\n"),
          nil,
          "a \#{1}\n"
        )],
       (206...210)
     ),
     InterpolatedStringNode(211...229)(
       (211...217),
       [StringNode(218...225)(
          nil,
          STRING_CONTENT(218...225)("\ta\n" + "\t b\n"),
          nil,
          "a\n" + " b\n"
        )],
       (225...229)
     ),
     InterpolatedStringNode(230...248)(
       (230...236),
       [StringNode(237...244)(
          nil,
          STRING_CONTENT(237...244)("\t a\n" + "\tb\n"),
          nil,
          " a\n" + "b\n"
        )],
       (244...248)
     ),
     InterpolatedStringNode(249...275)(
       (249...255),
       [StringNode(256...271)(
          nil,
          STRING_CONTENT(256...271)("  \ta\n" + "        b\n"),
          nil,
          "a\n" + "b\n"
        )],
       (271...275)
     ),
     InterpolatedStringNode(276...296)(
       (276...282),
       [StringNode(283...292)(
          nil,
          STRING_CONTENT(283...292)("  a\n" + "\n" + "  b\n"),
          nil,
          "a\n" + "\n" + "b\n"
        )],
       (292...296)
     ),
     InterpolatedStringNode(297...317)(
       (297...303),
       [StringNode(304...313)(
          nil,
          STRING_CONTENT(304...313)("  a\n" + "\n" + "  b\n"),
          nil,
          "a\n" + "\n" + "b\n"
        )],
       (313...317)
     ),
     InterpolatedStringNode(318...340)(
       (318...324),
       [StringNode(325...336)(
          nil,
          STRING_CONTENT(325...336)("  a\n" + "\n" + "\n" + "\n" + "  b\n"),
          nil,
          "a\n" + "\n" + "\n" + "\n" + "b\n"
        )],
       (336...340)
     ),
     InterpolatedStringNode(341...365)(
       (341...347),
       [StringNode(348...351)(
          nil,
          STRING_CONTENT(348...351)("\n" + "  "),
          nil,
          "\n"
        ),
        StringInterpolatedNode(351...355)(
          (351...353),
          StatementsNode(353...354)([IntegerNode(353...354)()]),
          (354...355)
        ),
        StringNode(355...357)(
          nil,
          STRING_CONTENT(355...357)("a\n"),
          nil,
          "a\n"
        )],
       (357...365)
     ),
     InterpolatedStringNode(366...387)(
       (366...372),
       [StringNode(373...375)(nil, STRING_CONTENT(373...375)("  "), nil, ""),
        StringInterpolatedNode(375...379)(
          (375...377),
          StatementsNode(377...378)([IntegerNode(377...378)()]),
          (378...379)
        ),
        StringNode(379...383)(
          nil,
          STRING_CONTENT(379...383)("\n" + "\tb\n"),
          nil,
          "\n" + "\tb\n"
        )],
       (383...387)
     )]
  )
)
