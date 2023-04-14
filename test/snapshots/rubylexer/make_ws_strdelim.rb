ProgramNode(0...446)(
  ScopeNode(0...0)([]),
  StatementsNode(0...446)(
    [CallNode(0...4)(
       nil,
       nil,
       IDENTIFIER(0...4)("puts"),
       nil,
       ArgumentsNode(5...16)(
         [StringNode(5...16)(
            STRING_BEGIN(5...6)("\""),
            STRING_CONTENT(6...15)("%\\sfoo\\s "),
            STRING_END(15...16)("\""),
            "% foo  "
          )]
       ),
       nil,
       nil,
       "puts"
     ),
     CallNode(18...22)(
       nil,
       nil,
       IDENTIFIER(18...22)("puts"),
       nil,
       ArgumentsNode(23...34)(
         [StringNode(23...34)(
            STRING_BEGIN(23...24)("\""),
            STRING_CONTENT(24...33)("%\\tfoo\\t "),
            STRING_END(33...34)("\""),
            "%\tfoo\t "
          )]
       ),
       nil,
       nil,
       "puts"
     ),
     CallNode(35...39)(
       nil,
       nil,
       IDENTIFIER(35...39)("puts"),
       nil,
       ArgumentsNode(40...51)(
         [StringNode(40...51)(
            STRING_BEGIN(40...41)("\""),
            STRING_CONTENT(41...50)("%\\vfoo\\v "),
            STRING_END(50...51)("\""),
            "%\vfoo\v "
          )]
       ),
       nil,
       nil,
       "puts"
     ),
     CallNode(52...56)(
       nil,
       nil,
       IDENTIFIER(52...56)("puts"),
       nil,
       ArgumentsNode(57...68)(
         [StringNode(57...68)(
            STRING_BEGIN(57...58)("\""),
            STRING_CONTENT(58...67)("%\\rfoo\\r "),
            STRING_END(67...68)("\""),
            "%\rfoo\r "
          )]
       ),
       nil,
       nil,
       "puts"
     ),
     CallNode(69...73)(
       nil,
       nil,
       IDENTIFIER(69...73)("puts"),
       nil,
       ArgumentsNode(74...85)(
         [StringNode(74...85)(
            STRING_BEGIN(74...75)("\""),
            STRING_CONTENT(75...84)("%\\nfoo\\n "),
            STRING_END(84...85)("\""),
            "%\n" + "foo\n" + " "
          )]
       ),
       nil,
       nil,
       "puts"
     ),
     CallNode(86...90)(
       nil,
       nil,
       IDENTIFIER(86...90)("puts"),
       nil,
       ArgumentsNode(91...102)(
         [StringNode(91...102)(
            STRING_BEGIN(91...92)("\""),
            STRING_CONTENT(92...101)("%\\0foo\\0 "),
            STRING_END(101...102)("\""),
            "%\u0000foo\u0000 "
          )]
       ),
       nil,
       nil,
       "puts"
     ),
     CallNode(104...108)(
       nil,
       nil,
       IDENTIFIER(104...108)("puts"),
       nil,
       ArgumentsNode(109...124)(
         [StringNode(109...124)(
            STRING_BEGIN(109...110)("\""),
            STRING_CONTENT(110...123)("%\\r\\nfoo\\r\\n "),
            STRING_END(123...124)("\""),
            "%\r\n" + "foo\r\n" + " "
          )]
       ),
       nil,
       nil,
       "puts"
     ),
     CallNode(224...228)(
       nil,
       nil,
       IDENTIFIER(224...228)("puts"),
       nil,
       ArgumentsNode(229...244)(
         [StringNode(229...244)(
            STRING_BEGIN(229...230)("\""),
            STRING_CONTENT(230...243)("%\\n\\rfoo\\n\\r "),
            STRING_END(243...244)("\""),
            "%\n" + "\rfoo\n" + "\r "
          )]
       ),
       nil,
       nil,
       "puts"
     ),
     CallNode(246...250)(
       nil,
       nil,
       IDENTIFIER(246...250)("puts"),
       nil,
       ArgumentsNode(251...264)(
         [StringNode(251...264)(
            STRING_BEGIN(251...252)("\""),
            STRING_CONTENT(252...263)("%\\n\\rfoo\\n "),
            STRING_END(263...264)("\""),
            "%\n" + "\rfoo\n" + " "
          )]
       ),
       nil,
       nil,
       "puts"
     ),
     CallNode(382...386)(
       nil,
       nil,
       IDENTIFIER(382...386)("puts"),
       nil,
       ArgumentsNode(387...400)(
         [StringNode(387...400)(
            STRING_BEGIN(387...388)("\""),
            STRING_CONTENT(388...399)("%\\r\\nfoo\\n "),
            STRING_END(399...400)("\""),
            "%\r\n" + "foo\n" + " "
          )]
       ),
       nil,
       nil,
       "puts"
     ),
     CallNode(402...406)(
       nil,
       nil,
       IDENTIFIER(402...406)("puts"),
       nil,
       ArgumentsNode(407...418)(
         [StringNode(407...418)(
            STRING_BEGIN(407...408)("\""),
            STRING_CONTENT(408...417)("%\\rfoo\\r "),
            STRING_END(417...418)("\""),
            "%\rfoo\r "
          )]
       ),
       nil,
       nil,
       "puts"
     ),
     CallNode(421...425)(
       nil,
       nil,
       IDENTIFIER(421...425)("puts"),
       nil,
       ArgumentsNode(426...437)(
         [StringNode(426...437)(
            STRING_BEGIN(426...427)("\""),
            STRING_CONTENT(427...436)("%\\nfoo\\n "),
            STRING_END(436...437)("\""),
            "%\n" + "foo\n" + " "
          )]
       ),
       nil,
       nil,
       "puts"
     ),
     CallNode(442...446)(
       nil,
       nil,
       IDENTIFIER(442...446)("puts"),
       nil,
       ArgumentsNode(447...460)(
         [StringNode(447...460)(
            STRING_BEGIN(447...448)("\""),
            STRING_CONTENT(448...459)("%\\nfoo\\r\\n "),
            STRING_END(459...460)("\""),
            "%\n" + "foo\r\n" + " "
          )]
       ),
       nil,
       nil,
       "puts"
     )]
  )
)
