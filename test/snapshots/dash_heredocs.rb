ProgramNode(0...223)(
  [],
  StatementsNode(0...223)(
    [InterpolatedStringNode(0...15)(
       (0...6),
       [StringNode(7...11)(
          nil,
          STRING_CONTENT(7...11)("  a\n"),
          nil,
          "  a\n"
        )],
       (11...15)
     ),
     CallNode(16...58)(
       InterpolatedStringNode(16...47)(
         (16...24),
         [StringNode(37...41)(
            nil,
            STRING_CONTENT(37...41)("  a\n"),
            nil,
            "  a\n"
          )],
         (41...47)
       ),
       nil,
       PLUS(25...26)("+"),
       nil,
       ArgumentsNode(27...58)(
         [InterpolatedStringNode(27...58)(
            (27...36),
            [StringNode(47...51)(
               nil,
               STRING_CONTENT(47...51)("  b\n"),
               nil,
               "  b\n"
             )],
            (51...58)
          )]
       ),
       nil,
       nil,
       "+"
     ),
     InterpolatedXStringNode(59...81)(
       (59...67),
       [StringNode(68...72)(
          nil,
          STRING_CONTENT(68...72)("  a\n"),
          nil,
          "  a\n"
        ),
        StringInterpolatedNode(72...76)(
          EMBEXPR_BEGIN(72...74)("\#{"),
          StatementsNode(74...75)(
            [CallNode(74...75)(
               nil,
               nil,
               IDENTIFIER(74...75)("b"),
               nil,
               nil,
               nil,
               nil,
               "b"
             )]
          ),
          EMBEXPR_END(75...76)("}")
        ),
        StringNode(76...77)(nil, STRING_CONTENT(76...77)("\n"), nil, "\n")],
       (77...81)
     ),
     InterpolatedStringNode(82...106)(
       (82...88),
       [StringNode(98...102)(
          nil,
          STRING_CONTENT(98...102)("  a\n"),
          nil,
          "  a\n"
        )],
       (102...106)
     ),
     InterpolatedStringNode(107...128)(
       (107...113),
       [StringNode(114...122)(
          nil,
          STRING_CONTENT(114...122)("  a\n" + "  b\n"),
          nil,
          "  a\n" + "  b\n"
        )],
       (122...128)
     ),
     InterpolatedStringNode(129...151)(
       (129...137),
       [StringNode(138...142)(
          nil,
          STRING_CONTENT(138...142)("  a\n"),
          nil,
          "  a\n"
        ),
        StringInterpolatedNode(142...146)(
          EMBEXPR_BEGIN(142...144)("\#{"),
          StatementsNode(144...145)(
            [CallNode(144...145)(
               nil,
               nil,
               IDENTIFIER(144...145)("b"),
               nil,
               nil,
               nil,
               nil,
               "b"
             )]
          ),
          EMBEXPR_END(145...146)("}")
        ),
        StringNode(146...147)(
          nil,
          STRING_CONTENT(146...147)("\n"),
          nil,
          "\n"
        )],
       (147...151)
     ),
     InterpolatedStringNode(152...172)(
       (152...158),
       [StringNode(159...163)(
          nil,
          STRING_CONTENT(159...163)("  a\n"),
          nil,
          "  a\n"
        ),
        StringInterpolatedNode(163...167)(
          EMBEXPR_BEGIN(163...165)("\#{"),
          StatementsNode(165...166)(
            [CallNode(165...166)(
               nil,
               nil,
               IDENTIFIER(165...166)("b"),
               nil,
               nil,
               nil,
               nil,
               "b"
             )]
          ),
          EMBEXPR_END(166...167)("}")
        ),
        StringNode(167...168)(
          nil,
          STRING_CONTENT(167...168)("\n"),
          nil,
          "\n"
        )],
       (168...172)
     ),
     StringNode(173...179)(
       STRING_BEGIN(173...175)("%#"),
       STRING_CONTENT(175...178)("abc"),
       STRING_END(178...179)("#"),
       "abc"
     ),
     InterpolatedStringNode(181...200)(
       (181...187),
       [StringNode(188...196)(
          nil,
          STRING_CONTENT(188...196)("  a\n" + "  b\n"),
          nil,
          "  a\n" + "  b\n"
        )],
       (196...200)
     ),
     InterpolatedStringNode(201...223)(
       (201...209),
       [StringNode(210...219)(
          nil,
          STRING_CONTENT(210...219)("  a \#{1}\n"),
          nil,
          "  a \#{1}\n"
        )],
       (219...223)
     )]
  )
)
