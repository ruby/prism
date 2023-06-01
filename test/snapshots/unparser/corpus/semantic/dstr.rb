ProgramNode(0...608)(
  [],
  StatementsNode(0...608)(
    [InterpolatedStringNode(0...10)((0...5), [], (6...10)),
     InterpolatedStringNode(11...23)((11...18), [], (19...23)),
     InterpolatedStringNode(24...35)((24...30), [], (31...35)),
     InterpolatedStringNode(36...49)((36...44), [], (45...49)),
     InterpolatedStringNode(50...64)(
       (50...55),
       [StringNode(56...60)(
          nil,
          STRING_CONTENT(56...60)("  a\n"),
          nil,
          "  a\n"
        )],
       (60...64)
     ),
     InterpolatedStringNode(65...81)(
       (65...72),
       [StringNode(73...77)(
          nil,
          STRING_CONTENT(73...77)("  a\n"),
          nil,
          "  a\n"
        )],
       (77...81)
     ),
     InterpolatedStringNode(82...102)(
       (82...87),
       [StringNode(88...94)(
          nil,
          STRING_CONTENT(88...94)("  a\n" + "  "),
          nil,
          "  a\n" + "  "
        ),
        StringInterpolatedNode(94...97)((94...96), nil, (96...97)),
        StringNode(97...98)(nil, STRING_CONTENT(97...98)("\n"), nil, "\n")],
       (98...102)
     ),
     InterpolatedStringNode(103...124)(
       (103...109),
       [StringNode(110...116)(
          nil,
          STRING_CONTENT(110...116)("  a\n" + "  "),
          nil,
          "a\n"
        ),
        StringInterpolatedNode(116...119)((116...118), nil, (118...119)),
        StringNode(119...120)(
          nil,
          STRING_CONTENT(119...120)("\n"),
          nil,
          "\n"
        )],
       (120...124)
     ),
     InterpolatedStringNode(125...150)(
       (125...131),
       [StringNode(132...138)(
          nil,
          STRING_CONTENT(132...138)("  a\n" + "  "),
          nil,
          "a\n"
        ),
        StringInterpolatedNode(138...141)((138...140), nil, (140...141)),
        StringNode(141...146)(
          nil,
          STRING_CONTENT(141...146)("\n" + "  b\n"),
          nil,
          "\n" + "b\n"
        )],
       (146...150)
     ),
     InterpolatedStringNode(151...172)(
       (151...157),
       [StringNode(158...168)(
          nil,
          STRING_CONTENT(158...168)("  a\n" + "    b\n"),
          nil,
          "a\n" + "  b\n"
        )],
       (168...172)
     ),
     InterpolatedStringNode(173...190)(
       (173...180),
       [StringNode(181...186)(
          nil,
          STRING_CONTENT(181...186)("a\n" + "\n" + "b\n"),
          nil,
          "a\n" + "\n" + "b\n"
        )],
       (186...190)
     ),
     InterpolatedStringNode(191...210)(
       (191...198),
       [StringNode(199...206)(
          nil,
          STRING_CONTENT(199...206)(" a\n" + "\n" + " b\n"),
          nil,
          " a\n" + "\n" + " b\n"
        )],
       (206...210)
     ),
     InterpolatedStringNode(211...229)(
       (211...218),
       [StringNode(219...225)(
          nil,
          STRING_CONTENT(219...225)(" a\\nb\n"),
          nil,
          " a\\nb\n"
        )],
       (225...229)
     ),
     InterpolatedStringNode(230...251)(
       (230...235),
       [StringInterpolatedNode(236...239)((236...238), nil, (238...239)),
        StringNode(239...242)(
          nil,
          STRING_CONTENT(239...242)("a\n" + " "),
          nil,
          "a\n" + " "
        ),
        StringInterpolatedNode(242...245)((242...244), nil, (244...245)),
        StringNode(245...247)(
          nil,
          STRING_CONTENT(245...247)("a\n"),
          nil,
          "a\n"
        )],
       (247...251)
     ),
     InterpolatedStringNode(252...275)(
       (252...257),
       [StringNode(258...260)(nil, STRING_CONTENT(258...260)("  "), nil, "  "),
        StringInterpolatedNode(260...263)((260...262), nil, (262...263)),
        StringNode(263...271)(
          nil,
          STRING_CONTENT(263...271)("\n" + "  \\\#{}\n"),
          nil,
          "\n" + "  \#{}\n"
        )],
       (271...275)
     ),
     InterpolatedStringNode(276...296)(
       (276...281),
       [StringNode(282...284)(nil, STRING_CONTENT(282...284)(" a"), nil, " a"),
        StringInterpolatedNode(284...287)((284...286), nil, (286...287)),
        StringNode(287...292)(
          nil,
          STRING_CONTENT(287...292)("b\n" + " c\n"),
          nil,
          "b\n" + " c\n"
        )],
       (292...296)
     ),
     InterpolatedStringNode(297...314)(
       (297...303),
       [StringNode(304...306)(nil, STRING_CONTENT(304...306)("  "), nil, ""),
        StringInterpolatedNode(306...309)((306...308), nil, (308...309)),
        StringNode(309...310)(
          nil,
          STRING_CONTENT(309...310)("\n"),
          nil,
          "\n"
        )],
       (310...314)
     ),
     IfNode(315...349)(
       (315...317),
       TrueNode(318...322)(),
       StatementsNode(325...346)(
         [InterpolatedStringNode(325...346)(
            (325...331),
            [StringNode(332...336)(
               nil,
               STRING_CONTENT(332...336)("    "),
               nil,
               ""
             ),
             StringInterpolatedNode(336...339)((336...338), nil, (338...339)),
             StringNode(339...340)(
               nil,
               STRING_CONTENT(339...340)("\n"),
               nil,
               "\n"
             )],
            (340...346)
          )]
       ),
       nil,
       (346...349)
     ),
     IfNode(351...386)(
       (351...353),
       TrueNode(354...358)(),
       StatementsNode(361...383)(
         [InterpolatedStringNode(361...383)(
            (361...367),
            [StringNode(368...373)(
               nil,
               STRING_CONTENT(368...373)("    b"),
               nil,
               "b"
             ),
             StringInterpolatedNode(373...376)((373...375), nil, (375...376)),
             StringNode(376...377)(
               nil,
               STRING_CONTENT(376...377)("\n"),
               nil,
               "\n"
             )],
            (377...383)
          )]
       ),
       nil,
       (383...386)
     ),
     IfNode(388...423)(
       (388...390),
       TrueNode(391...395)(),
       StatementsNode(398...420)(
         [InterpolatedStringNode(398...420)(
            (398...404),
            [StringNode(405...409)(
               nil,
               STRING_CONTENT(405...409)("    "),
               nil,
               ""
             ),
             StringInterpolatedNode(409...412)((409...411), nil, (411...412)),
             StringNode(412...414)(
               nil,
               STRING_CONTENT(412...414)("a\n"),
               nil,
               "a\n"
             )],
            (414...420)
          )]
       ),
       nil,
       (420...423)
     ),
     IfNode(425...464)(
       (425...427),
       TrueNode(428...432)(),
       StatementsNode(435...461)(
         [InterpolatedStringNode(435...461)(
            (435...443),
            [StringNode(444...455)(
               nil,
               STRING_CONTENT(444...455)("   a\n" + "\n" + "   b\n"),
               nil,
               "   a\n" + "\n" + "   b\n"
             )],
            (455...461)
          )]
       ),
       nil,
       (461...464)
     ),
     InterpolatedStringNode(466...472)(
       (466...467),
       [StringInterpolatedNode(467...470)((467...469), nil, (469...470)),
        StringNode(470...471)(nil, STRING_CONTENT(470...471)("a"), nil, "a")],
       (471...472)
     ),
     InterpolatedStringNode(474...486)(
       (474...476),
       [StringNode(476...479)(
          nil,
          STRING_CONTENT(476...479)("\\n\""),
          nil,
          "\n" + "\""
        ),
        StringInterpolatedNode(479...482)((479...481), nil, (481...482)),
        StringNode(482...485)(
          nil,
          STRING_CONTENT(482...485)("\"\\n"),
          nil,
          "\"\n"
        )],
       (485...486)
     ),
     InterpolatedStringNode(488...502)(
       (488...491),
       [StringNode(491...495)(
          nil,
          STRING_CONTENT(491...495)("-\\n\""),
          nil,
          "-\n" + "\""
        ),
        StringInterpolatedNode(495...498)((495...497), nil, (497...498)),
        StringNode(498...501)(
          nil,
          STRING_CONTENT(498...501)("\"\\n"),
          nil,
          "\"\n"
        )],
       (501...502)
     ),
     InterpolatedStringNode(504...513)(
       (504...505),
       [StringNode(505...507)(
          nil,
          STRING_CONTENT(505...507)("a\n"),
          nil,
          "a\n"
        ),
        StringInterpolatedNode(507...510)((507...509), nil, (509...510)),
        StringNode(510...512)(
          nil,
          STRING_CONTENT(510...512)("\n" + "b"),
          nil,
          "\n" + "b"
        )],
       (512...513)
     ),
     InterpolatedStringNode(515...525)(
       (515...516),
       [StringNode(516...519)(
          nil,
          STRING_CONTENT(516...519)("a\\n"),
          nil,
          "a\n"
        ),
        StringInterpolatedNode(519...522)((519...521), nil, (521...522)),
        StringNode(522...524)(
          nil,
          STRING_CONTENT(522...524)("\n" + "b"),
          nil,
          "\n" + "b"
        )],
       (524...525)
     ),
     InterpolatedStringNode(527...537)(
       (527...528),
       [StringNode(528...530)(
          nil,
          STRING_CONTENT(528...530)("a\n"),
          nil,
          "a\n"
        ),
        StringInterpolatedNode(530...533)((530...532), nil, (532...533)),
        StringNode(533...536)(
          nil,
          STRING_CONTENT(533...536)("\\nb"),
          nil,
          "\n" + "b"
        )],
       (536...537)
     ),
     StringConcatNode(539...550)(
       StringNode(539...542)(
         STRING_BEGIN(539...540)("'"),
         STRING_CONTENT(540...541)("a"),
         STRING_END(541...542)("'"),
         "a"
       ),
       InterpolatedStringNode(545...550)(
         (545...546),
         [StringInterpolatedNode(546...549)((546...548), nil, (548...549))],
         (549...550)
       )
     ),
     StringConcatNode(552...560)(
       StringNode(552...554)(
         STRING_BEGIN(552...553)("\""),
         STRING_CONTENT(553...553)(""),
         STRING_END(553...554)("\""),
         ""
       ),
       StringConcatNode(555...560)(
         StringNode(555...557)(
           STRING_BEGIN(555...556)("\""),
           STRING_CONTENT(556...556)(""),
           STRING_END(556...557)("\""),
           ""
         ),
         StringNode(558...560)(
           STRING_BEGIN(558...559)("\""),
           STRING_CONTENT(559...559)(""),
           STRING_END(559...560)("\""),
           ""
         )
       )
     ),
     StringConcatNode(562...574)(
       InterpolatedStringNode(562...570)(
         (562...563),
         [StringNode(563...564)(nil, STRING_CONTENT(563...564)("a"), nil, "a"),
          StringInterpolatedNode(564...569)(
            (564...566),
            StatementsNode(566...568)([InstanceVariableReadNode(566...568)()]),
            (568...569)
          )],
         (569...570)
       ),
       StringNode(571...574)(
         STRING_BEGIN(571...572)("\""),
         STRING_CONTENT(572...573)("b"),
         STRING_END(573...574)("\""),
         "b"
       )
     ),
     StringConcatNode(575...585)(
       InterpolatedStringNode(575...581)(
         (575...576),
         [StringNode(576...577)(nil, STRING_CONTENT(576...577)("a"), nil, "a"),
          InstanceVariableReadNode(578...580)()],
         (580...581)
       ),
       StringNode(582...585)(
         STRING_BEGIN(582...583)("\""),
         STRING_CONTENT(583...584)("b"),
         STRING_END(584...585)("\""),
         "b"
       )
     ),
     StringConcatNode(586...596)(
       InterpolatedStringNode(586...592)(
         (586...587),
         [StringNode(587...588)(nil, STRING_CONTENT(587...588)("a"), nil, "a"),
          GlobalVariableReadNode(589...591)(GLOBAL_VARIABLE(589...591)("$a"))],
         (591...592)
       ),
       StringNode(593...596)(
         STRING_BEGIN(593...594)("\""),
         STRING_CONTENT(594...595)("b"),
         STRING_END(595...596)("\""),
         "b"
       )
     ),
     StringConcatNode(597...608)(
       InterpolatedStringNode(597...604)(
         (597...598),
         [StringNode(598...599)(nil, STRING_CONTENT(598...599)("a"), nil, "a"),
          ClassVariableReadNode(600...603)()],
         (603...604)
       ),
       StringNode(605...608)(
         STRING_BEGIN(605...606)("\""),
         STRING_CONTENT(606...607)("b"),
         STRING_END(607...608)("\""),
         "b"
       )
     )]
  )
)
