ProgramNode(0...218)(
  ScopeNode(0...0)([IDENTIFIER(152...153)("f")]),
  StatementsNode(0...218)(
    [CallNode(0...1)(
       nil,
       nil,
       IDENTIFIER(0...1)("p"),
       nil,
       ArgumentsNode(2...9)(
         [RegularExpressionNode(2...9)(
            REGEXP_BEGIN(2...5)("%r{"),
            STRING_CONTENT(5...8)("\\/$"),
            REGEXP_END(8...9)("}"),
            "/$"
          )]
       ),
       nil,
       nil,
       "p"
     ),
     CallNode(10...11)(
       nil,
       nil,
       IDENTIFIER(10...11)("p"),
       nil,
       ArgumentsNode(12...41)(
         [RegularExpressionNode(12...41)(
            REGEXP_BEGIN(12...15)("%r~"),
            STRING_CONTENT(15...39)("<!include:([\\/\\w\\.\\-]+)>"),
            REGEXP_END(39...41)("~m"),
            "<!include:([/w.-]+)>"
          )]
       ),
       nil,
       nil,
       "p"
     ),
     CallNode(43...44)(
       nil,
       nil,
       IDENTIFIER(43...44)("p"),
       nil,
       ArgumentsNode(45...61)(
         [CallNode(45...61)(
            ArrayNode(45...47)(
              [],
              BRACKET_LEFT_ARRAY(45...46)("["),
              BRACKET_RIGHT(46...47)("]")
            ),
            DOT(47...48)("."),
            IDENTIFIER(48...52)("push"),
            nil,
            ArgumentsNode(53...61)(
              [SplatNode(53...61)(
                 USTAR(53...54)("*"),
                 ArrayNode(54...61)(
                   [IntegerNode(55...56)(),
                    IntegerNode(57...58)(),
                    IntegerNode(59...60)()],
                   BRACKET_LEFT_ARRAY(54...55)("["),
                   BRACKET_RIGHT(60...61)("]")
                 )
               )]
            ),
            nil,
            nil,
            "push"
          )]
       ),
       nil,
       nil,
       "p"
     ),
     CallNode(62...63)(
       nil,
       nil,
       IDENTIFIER(62...63)("p"),
       nil,
       ArgumentsNode(64...68)(
         [RegularExpressionNode(64...68)(
            REGEXP_BEGIN(64...65)("/"),
            STRING_CONTENT(65...67)("\\n"),
            REGEXP_END(67...68)("/"),
            "\n"
          )]
       ),
       nil,
       nil,
       "p"
     ),
     GlobalVariableWriteNode(70...74)(
       GLOBAL_VARIABLE(70...72)("$a"),
       EQUAL(72...73)("="),
       IntegerNode(73...74)()
     ),
     InstanceVariableWriteNode(75...79)(
       (75...77),
       IntegerNode(78...79)(),
       (77...78)
     ),
     ClassVariableWriteNode(80...85)(
       (80...83),
       IntegerNode(84...85)(),
       (83...84)
     ),
     CallNode(86...120)(
       nil,
       nil,
       IDENTIFIER(86...87)("p"),
       PARENTHESIS_LEFT(87...88)("("),
       ArgumentsNode(88...119)(
         [RegularExpressionNode(88...119)(
            REGEXP_BEGIN(88...89)("/"),
            STRING_CONTENT(89...118)("\\\#$a \\\#@b \\\#@@c \\\#{$a+@b+@@c}"),
            REGEXP_END(118...119)("/"),
            "\#$a \#@b \#@@c \#{$a+@b+@@c}"
          )]
       ),
       PARENTHESIS_RIGHT(119...120)(")"),
       nil,
       "p"
     ),
     ClassNode(123...151)(
       ScopeNode(123...128)([]),
       KEYWORD_CLASS(123...128)("class"),
       ConstantReadNode(129...132)(),
       nil,
       nil,
       StatementsNode(133...137)(
         [CallNode(133...137)(
            nil,
            nil,
            IDENTIFIER(133...137)("attr"),
            nil,
            ArgumentsNode(138...147)(
              [SymbolNode(138...142)(
                 SYMBOL_BEGIN(138...139)(":"),
                 IDENTIFIER(139...142)("foo"),
                 nil,
                 "foo"
               ),
               TrueNode(143...147)()]
            ),
            nil,
            nil,
            "attr"
          )]
       ),
       KEYWORD_END(148...151)("end")
     ),
     LocalVariableWriteNode(152...161)(
       (152...153),
       CallNode(154...161)(
         ConstantReadNode(154...157)(),
         DOT(157...158)("."),
         IDENTIFIER(158...161)("new"),
         nil,
         nil,
         nil,
         nil,
         "new"
       ),
       (153...154),
       0
     ),
     CallNode(162...163)(
       nil,
       nil,
       IDENTIFIER(162...163)("p"),
       nil,
       ArgumentsNode(164...169)(
         [CallNode(164...169)(
            LocalVariableReadNode(164...165)(0),
            DOT(165...166)("."),
            IDENTIFIER(166...169)("foo"),
            nil,
            nil,
            nil,
            nil,
            "foo"
          )]
       ),
       nil,
       nil,
       "p"
     ),
     CallNode(170...171)(
       nil,
       nil,
       IDENTIFIER(170...171)("p"),
       nil,
       ArgumentsNode(172...177)(
         [CallNode(172...177)(
            LocalVariableReadNode(172...173)(0),
            DOT(173...174)("."),
            IDENTIFIER(174...177)("foo"),
            nil,
            ArgumentsNode(178...179)([IntegerNode(178...179)()]),
            nil,
            nil,
            "foo="
          )]
       ),
       nil,
       nil,
       "p"
     ),
     CallNode(180...181)(
       nil,
       nil,
       IDENTIFIER(180...181)("p"),
       nil,
       ArgumentsNode(182...187)(
         [CallNode(182...187)(
            LocalVariableReadNode(182...183)(0),
            DOT(183...184)("."),
            IDENTIFIER(184...187)("foo"),
            nil,
            ArgumentsNode(189...191)([IntegerNode(189...191)()]),
            nil,
            nil,
            "foo="
          )]
       ),
       nil,
       nil,
       "p"
     ),
     CallNode(192...193)(
       nil,
       nil,
       IDENTIFIER(192...193)("p"),
       nil,
       ArgumentsNode(194...199)(
         [CallNode(194...199)(
            LocalVariableReadNode(194...195)(0),
            DOT(195...196)("."),
            IDENTIFIER(196...199)("foo"),
            nil,
            ArgumentsNode(201...203)([IntegerNode(201...203)()]),
            nil,
            nil,
            "foo="
          )]
       ),
       nil,
       nil,
       "p"
     ),
     CallNode(204...205)(
       nil,
       nil,
       IDENTIFIER(204...205)("p"),
       nil,
       ArgumentsNode(206...211)(
         [CallNode(206...211)(
            LocalVariableReadNode(206...207)(0),
            DOT(207...208)("."),
            IDENTIFIER(208...211)("foo"),
            nil,
            ArgumentsNode(214...216)([IntegerNode(214...216)()]),
            nil,
            nil,
            "foo="
          )]
       ),
       nil,
       nil,
       "p"
     ),
     CallNode(217...218)(
       nil,
       nil,
       IDENTIFIER(217...218)("p"),
       nil,
       ArgumentsNode(219...224)(
         [CallNode(219...224)(
            LocalVariableReadNode(219...220)(0),
            DOT(220...221)("."),
            IDENTIFIER(221...224)("foo"),
            nil,
            nil,
            nil,
            nil,
            "foo"
          )]
       ),
       nil,
       nil,
       "p"
     )]
  )
)
