ProgramNode(0...278)(
  ScopeNode(0...0)([]),
  StatementsNode(0...278)(
    [DefNode(0...14)(
       IDENTIFIER(4...7)("foo"),
       nil,
       nil,
       StatementsNode(10...14)(
         [CallNode(10...14)(
            nil,
            nil,
            IDENTIFIER(10...14)("puts"),
            nil,
            ArgumentsNode(15...22)(
              [StringNode(15...22)(
                 STRING_BEGIN(15...16)("\""),
                 STRING_CONTENT(16...21)("Hello"),
                 STRING_END(21...22)("\""),
                 "Hello"
               )]
            ),
            nil,
            nil,
            "puts"
          )]
       ),
       ScopeNode(0...3)([]),
       (0...3),
       nil,
       nil,
       nil,
       (8...9),
       nil
     ),
     DefNode(24...40)(
       IDENTIFIER(28...31)("foo"),
       nil,
       nil,
       StatementsNode(36...40)(
         [CallNode(36...40)(
            nil,
            nil,
            IDENTIFIER(36...40)("puts"),
            nil,
            ArgumentsNode(41...48)(
              [StringNode(41...48)(
                 STRING_BEGIN(41...42)("\""),
                 STRING_CONTENT(42...47)("Hello"),
                 STRING_END(47...48)("\""),
                 "Hello"
               )]
            ),
            nil,
            nil,
            "puts"
          )]
       ),
       ScopeNode(24...27)([]),
       (24...27),
       nil,
       (31...32),
       (32...33),
       (34...35),
       nil
     ),
     DefNode(50...67)(
       IDENTIFIER(54...57)("foo"),
       nil,
       ParametersNode(58...59)(
         [RequiredParameterNode(58...59)()],
         [],
         nil,
         [],
         nil,
         nil
       ),
       StatementsNode(63...67)(
         [CallNode(63...67)(
            nil,
            nil,
            IDENTIFIER(63...67)("puts"),
            nil,
            ArgumentsNode(68...69)([LocalVariableReadNode(68...69)(1)]),
            nil,
            nil,
            "puts"
          )]
       ),
       ScopeNode(50...53)([IDENTIFIER(58...59)("x")]),
       (50...53),
       nil,
       (57...58),
       (59...60),
       (61...62),
       nil
     ),
     DefNode(71...89)(
       IDENTIFIER(79...82)("foo"),
       CallNode(75...78)(
         nil,
         nil,
         IDENTIFIER(75...78)("obj"),
         nil,
         nil,
         nil,
         nil,
         "obj"
       ),
       nil,
       StatementsNode(85...89)(
         [CallNode(85...89)(
            nil,
            nil,
            IDENTIFIER(85...89)("puts"),
            nil,
            ArgumentsNode(90...97)(
              [StringNode(90...97)(
                 STRING_BEGIN(90...91)("\""),
                 STRING_CONTENT(91...96)("Hello"),
                 STRING_END(96...97)("\""),
                 "Hello"
               )]
            ),
            nil,
            nil,
            "puts"
          )]
       ),
       ScopeNode(71...74)([]),
       (71...74),
       (78...79),
       nil,
       nil,
       (83...84),
       nil
     ),
     DefNode(99...119)(
       IDENTIFIER(107...110)("foo"),
       CallNode(103...106)(
         nil,
         nil,
         IDENTIFIER(103...106)("obj"),
         nil,
         nil,
         nil,
         nil,
         "obj"
       ),
       nil,
       StatementsNode(115...119)(
         [CallNode(115...119)(
            nil,
            nil,
            IDENTIFIER(115...119)("puts"),
            nil,
            ArgumentsNode(120...127)(
              [StringNode(120...127)(
                 STRING_BEGIN(120...121)("\""),
                 STRING_CONTENT(121...126)("Hello"),
                 STRING_END(126...127)("\""),
                 "Hello"
               )]
            ),
            nil,
            nil,
            "puts"
          )]
       ),
       ScopeNode(99...102)([]),
       (99...102),
       (106...107),
       (110...111),
       (111...112),
       (113...114),
       nil
     ),
     DefNode(129...150)(
       IDENTIFIER(137...140)("foo"),
       CallNode(133...136)(
         nil,
         nil,
         IDENTIFIER(133...136)("obj"),
         nil,
         nil,
         nil,
         nil,
         "obj"
       ),
       ParametersNode(141...142)(
         [RequiredParameterNode(141...142)()],
         [],
         nil,
         [],
         nil,
         nil
       ),
       StatementsNode(146...150)(
         [CallNode(146...150)(
            nil,
            nil,
            IDENTIFIER(146...150)("puts"),
            nil,
            ArgumentsNode(151...152)([LocalVariableReadNode(151...152)(1)]),
            nil,
            nil,
            "puts"
          )]
       ),
       ScopeNode(129...132)([IDENTIFIER(141...142)("x")]),
       (129...132),
       (136...137),
       (140...141),
       (142...143),
       (144...145),
       nil
     ),
     DefNode(154...214)(
       IDENTIFIER(158...165)("rescued"),
       nil,
       ParametersNode(166...167)(
         [RequiredParameterNode(166...167)()],
         [],
         nil,
         [],
         nil,
         nil
       ),
       StatementsNode(171...214)(
         [RescueModifierNode(171...214)(
            CallNode(171...176)(
              nil,
              nil,
              IDENTIFIER(171...176)("raise"),
              nil,
              ArgumentsNode(177...191)(
                [StringNode(177...191)(
                   STRING_BEGIN(177...178)("\""),
                   STRING_CONTENT(178...190)("to be caught"),
                   STRING_END(190...191)("\""),
                   "to be caught"
                 )]
              ),
              nil,
              nil,
              "raise"
            ),
            KEYWORD_RESCUE_MODIFIER(192...198)("rescue"),
            InterpolatedStringNode(199...214)(
              STRING_BEGIN(199...200)("\""),
              [StringNode(200...209)(
                 nil,
                 STRING_CONTENT(200...209)("instance "),
                 nil,
                 "instance "
               ),
               StringInterpolatedNode(209...213)(
                 EMBEXPR_BEGIN(209...211)("\#{"),
                 StatementsNode(211...212)(
                   [LocalVariableReadNode(211...212)(1)]
                 ),
                 EMBEXPR_END(212...213)("}")
               )],
              STRING_END(213...214)("\"")
            )
          )]
       ),
       ScopeNode(154...157)([IDENTIFIER(166...167)("x")]),
       (154...157),
       nil,
       (165...166),
       (167...168),
       (169...170),
       nil
     ),
     DefNode(216...278)(
       IDENTIFIER(225...232)("rescued"),
       SelfNode(220...224)(),
       ParametersNode(233...234)(
         [RequiredParameterNode(233...234)()],
         [],
         nil,
         [],
         nil,
         nil
       ),
       StatementsNode(238...278)(
         [RescueModifierNode(238...278)(
            CallNode(238...243)(
              nil,
              nil,
              IDENTIFIER(238...243)("raise"),
              nil,
              ArgumentsNode(244...258)(
                [StringNode(244...258)(
                   STRING_BEGIN(244...245)("\""),
                   STRING_CONTENT(245...257)("to be caught"),
                   STRING_END(257...258)("\""),
                   "to be caught"
                 )]
              ),
              nil,
              nil,
              "raise"
            ),
            KEYWORD_RESCUE_MODIFIER(259...265)("rescue"),
            InterpolatedStringNode(266...278)(
              STRING_BEGIN(266...267)("\""),
              [StringNode(267...273)(
                 nil,
                 STRING_CONTENT(267...273)("class "),
                 nil,
                 "class "
               ),
               StringInterpolatedNode(273...277)(
                 EMBEXPR_BEGIN(273...275)("\#{"),
                 StatementsNode(275...276)(
                   [LocalVariableReadNode(275...276)(1)]
                 ),
                 EMBEXPR_END(276...277)("}")
               )],
              STRING_END(277...278)("\"")
            )
          )]
       ),
       ScopeNode(216...219)([IDENTIFIER(233...234)("x")]),
       (216...219),
       (224...225),
       (232...233),
       (234...235),
       (236...237),
       nil
     )]
  )
)
