ProgramNode(0...309)(
  Scope(0...0)([]),
  StatementsNode(0...309)(
    [WhileNode(0...13)(
       KEYWORD_WHILE(0...5)("while"),
       TrueNode(6...10)(),
       StatementsNode(12...13)([IntegerNode(12...13)()])
     ),
     WhileNode(22...21)(
       KEYWORD_WHILE_MODIFIER(22...27)("while"),
       TrueNode(28...32)(),
       StatementsNode(20...21)([IntegerNode(20...21)()])
     ),
     WhileNode(40...39)(
       KEYWORD_WHILE_MODIFIER(40...45)("while"),
       TrueNode(46...50)(),
       StatementsNode(34...39)([BreakNode(34...39)(nil, (34...39))])
     ),
     WhileNode(57...56)(
       KEYWORD_WHILE_MODIFIER(57...62)("while"),
       TrueNode(63...67)(),
       StatementsNode(52...56)([NextNode(52...56)(nil, (52...56))])
     ),
     WhileNode(76...75)(
       KEYWORD_WHILE_MODIFIER(76...81)("while"),
       TrueNode(82...86)(),
       StatementsNode(69...75)(
         [ReturnNode(69...75)(KEYWORD_RETURN(69...75)("return"), nil)]
       )
     ),
     WhileNode(99...91)(
       KEYWORD_WHILE_MODIFIER(99...104)("while"),
       CallNode(105...109)(
         nil,
         nil,
         IDENTIFIER(105...109)("bar?"),
         nil,
         nil,
         nil,
         nil,
         "bar?"
       ),
       StatementsNode(88...91)(
         [CallNode(88...91)(
            nil,
            nil,
            IDENTIFIER(88...91)("foo"),
            nil,
            ArgumentsNode(92...98)(
              [SymbolNode(92...94)(
                 SYMBOL_BEGIN(92...93)(":"),
                 IDENTIFIER(93...94)("a"),
                 nil,
                 "a"
               ),
               SymbolNode(96...98)(
                 SYMBOL_BEGIN(96...97)(":"),
                 IDENTIFIER(97...98)("b"),
                 nil,
                 "b"
               )]
            ),
            nil,
            nil,
            "foo"
          )]
       )
     ),
     WhileNode(111...156)(
       KEYWORD_WHILE(111...116)("while"),
       DefNode(117...149)(
         IDENTIFIER(126...129)("foo"),
         SelfNode(121...125)(),
         ParametersNode(130...144)(
           [],
           [OptionalParameterNode(130...144)(
              IDENTIFIER(130...131)("a"),
              EQUAL(132...133)("="),
              CallNode(134...144)(
                nil,
                nil,
                IDENTIFIER(134...137)("tap"),
                nil,
                nil,
                nil,
                BlockNode(138...144)(
                  Scope(138...140)([]),
                  nil,
                  nil,
                  (138...140),
                  (141...144)
                ),
                "tap"
              )
            )],
           nil,
           [],
           nil,
           nil
         ),
         StatementsNode(0...0)([]),
         Scope(117...120)([IDENTIFIER(130...131)("a")]),
         (117...120),
         (125...126),
         nil,
         nil,
         nil,
         (146...149)
       ),
       StatementsNode(151...156)([BreakNode(151...156)(nil, (151...156))])
     ),
     WhileNode(163...205)(
       KEYWORD_WHILE(163...168)("while"),
       ClassNode(169...198)(
         Scope(169...174)([IDENTIFIER(179...180)("a")]),
         KEYWORD_CLASS(169...174)("class"),
         ConstantReadNode(175...178)(),
         nil,
         nil,
         StatementsNode(179...193)(
           [LocalVariableWriteNode(179...193)(
              IDENTIFIER(179...180)("a"),
              EQUAL(181...182)("="),
              CallNode(183...193)(
                nil,
                nil,
                IDENTIFIER(183...186)("tap"),
                nil,
                nil,
                nil,
                BlockNode(187...193)(
                  Scope(187...189)([]),
                  nil,
                  nil,
                  (187...189),
                  (190...193)
                ),
                "tap"
              )
            )]
         ),
         KEYWORD_END(195...198)("end")
       ),
       StatementsNode(200...205)([BreakNode(200...205)(nil, (200...205))])
     ),
     WhileNode(212...255)(
       KEYWORD_WHILE(212...217)("while"),
       SingletonClassNode(218...248)(
         Scope(218...223)([]),
         KEYWORD_CLASS(218...223)("class"),
         LESS_LESS(224...226)("<<"),
         SelfNode(227...231)(),
         StatementsNode(233...243)(
           [CallNode(233...243)(
              nil,
              nil,
              IDENTIFIER(233...236)("tap"),
              nil,
              nil,
              nil,
              BlockNode(237...243)(
                Scope(237...239)([]),
                nil,
                nil,
                (237...239),
                (240...243)
              ),
              "tap"
            )]
         ),
         KEYWORD_END(245...248)("end")
       ),
       StatementsNode(250...255)([BreakNode(250...255)(nil, (250...255))])
     ),
     WhileNode(262...309)(
       KEYWORD_WHILE(262...267)("while"),
       SingletonClassNode(268...302)(
         Scope(268...273)([IDENTIFIER(283...284)("a")]),
         KEYWORD_CLASS(268...273)("class"),
         LESS_LESS(274...276)("<<"),
         SelfNode(277...281)(),
         StatementsNode(283...297)(
           [LocalVariableWriteNode(283...297)(
              IDENTIFIER(283...284)("a"),
              EQUAL(285...286)("="),
              CallNode(287...297)(
                nil,
                nil,
                IDENTIFIER(287...290)("tap"),
                nil,
                nil,
                nil,
                BlockNode(291...297)(
                  Scope(291...293)([]),
                  nil,
                  nil,
                  (291...293),
                  (294...297)
                ),
                "tap"
              )
            )]
         ),
         KEYWORD_END(299...302)("end")
       ),
       StatementsNode(304...309)([BreakNode(304...309)(nil, (304...309))])
     )]
  )
)
