ProgramNode(0...293)(
  ScopeNode(0...0)(
    [IDENTIFIER(85...88)("abc"),
     IDENTIFIER(152...155)("foo"),
     IDENTIFIER(219...222)("bar"),
     IDENTIFIER(242...245)("baz")]
  ),
  StatementsNode(0...293)(
    [ClassVariableReadNode(0...5)(),
     ClassVariableWriteNode(7...16)(
       (7...12),
       IntegerNode(15...16)((15...16), 10),
       (13...14)
     ),
     MultiWriteNode(18...34)(
       [ClassVariableWriteNode(18...23)((18...23), nil, nil),
        ClassVariableWriteNode(25...30)((25...30), nil, nil)],
       EQUAL(31...32)("="),
       IntegerNode(33...34)((33...34), 10),
       nil,
       nil
     ),
     ClassVariableWriteNode(36...0)(
       (36...41),
       ArrayNode(0...0)(
         [IntegerNode(44...45)((44...45), 10),
          IntegerNode(47...48)((47...48), 10)],
         nil,
         nil
       ),
       (42...43)
     ),
     GlobalVariableWriteNode(50...58)(
       GLOBAL_VARIABLE(50...54)("$abc"),
       EQUAL(55...56)("="),
       IntegerNode(57...58)((57...58), 10)
     ),
     GlobalVariableReadNode(60...64)(GLOBAL_VARIABLE(60...64)("$abc")),
     InstanceVariableReadNode(66...70)(),
     InstanceVariableWriteNode(72...80)(
       (72...76),
       IntegerNode(79...80)((79...80), 10),
       (77...78)
     ),
     CallNode(82...83)(
       nil,
       nil,
       IDENTIFIER(82...83)("a"),
       nil,
       nil,
       nil,
       nil,
       "a"
     ),
     LocalVariableWriteNode(85...92)(
       (85...88),
       IntegerNode(91...92)((91...92), 10),
       (89...90),
       0
     ),
     MultiWriteNode(94...108)(
       [GlobalVariableWriteNode(94...98)(
          GLOBAL_VARIABLE(94...98)("$foo"),
          nil,
          nil
        ),
        GlobalVariableWriteNode(100...104)(
          GLOBAL_VARIABLE(100...104)("$bar"),
          nil,
          nil
        )],
       EQUAL(105...106)("="),
       IntegerNode(107...108)((107...108), 10),
       nil,
       nil
     ),
     GlobalVariableWriteNode(110...0)(
       GLOBAL_VARIABLE(110...114)("$foo"),
       EQUAL(115...116)("="),
       ArrayNode(0...0)(
         [IntegerNode(117...118)((117...118), 10),
          IntegerNode(120...121)((120...121), 10)],
         nil,
         nil
       )
     ),
     MultiWriteNode(123...137)(
       [InstanceVariableWriteNode(123...127)((123...127), nil, nil),
        InstanceVariableWriteNode(129...133)((129...133), nil, nil)],
       EQUAL(134...135)("="),
       IntegerNode(136...137)((136...137), 10),
       nil,
       nil
     ),
     InstanceVariableWriteNode(139...0)(
       (139...143),
       ArrayNode(0...0)(
         [IntegerNode(146...147)((146...147), 10),
          IntegerNode(149...150)((149...150), 10)],
         nil,
         nil
       ),
       (144...145)
     ),
     LocalVariableWriteNode(152...159)(
       (152...155),
       IntegerNode(158...159)((158...159), 10),
       (156...157),
       0
     ),
     LocalVariableWriteNode(161...0)(
       (161...164),
       ArrayNode(0...0)(
         [IntegerNode(167...168)((167...168), 10),
          IntegerNode(170...171)((170...171), 10)],
         nil,
         nil
       ),
       (165...166),
       0
     ),
     LocalVariableWriteNode(173...0)(
       (173...176),
       ArrayNode(0...0)(
         [IntegerNode(179...180)((179...180), 10),
          IntegerNode(182...183)((182...183), 10)],
         nil,
         nil
       ),
       (177...178),
       0
     ),
     MultiWriteNode(185...0)(
       [LocalVariableWriteNode(185...188)((185...188), nil, nil, 0),
        SplatNode(190...191)(USTAR(190...191)("*"), nil)],
       EQUAL(192...193)("="),
       ArrayNode(0...0)(
         [IntegerNode(194...195)((194...195), 10),
          IntegerNode(197...198)((197...198), 10)],
         nil,
         nil
       ),
       nil,
       nil
     ),
     MultiWriteNode(200...0)(
       [LocalVariableWriteNode(200...203)((200...203), nil, nil, 0),
        SplatNode(203...204)(COMMA(203...204)(","), nil)],
       EQUAL(205...206)("="),
       ArrayNode(0...0)(
         [IntegerNode(207...208)((207...208), 10),
          IntegerNode(210...211)((210...211), 10)],
         nil,
         nil
       ),
       nil,
       nil
     ),
     MultiWriteNode(213...0)(
       [LocalVariableWriteNode(213...216)((213...216), nil, nil, 0),
        SplatNode(218...222)(
          USTAR(218...219)("*"),
          LocalVariableWriteNode(219...222)((219...222), nil, nil, 0)
        )],
       EQUAL(223...224)("="),
       ArrayNode(0...0)(
         [IntegerNode(225...226)((225...226), 10),
          IntegerNode(228...229)((228...229), 10)],
         nil,
         nil
       ),
       nil,
       nil
     ),
     MultiWriteNode(231...0)(
       [LocalVariableWriteNode(231...234)((231...234), nil, nil, 0),
        MultiWriteNode(237...246)(
          [LocalVariableWriteNode(237...240)((237...240), nil, nil, 0),
           LocalVariableWriteNode(242...245)((242...245), nil, nil, 0)],
          nil,
          nil,
          (236...237),
          (245...246)
        )],
       EQUAL(247...248)("="),
       ArrayNode(0...0)(
         [IntegerNode(249...250)((249...250), 10),
          ArrayNode(252...258)(
            [IntegerNode(253...254)((253...254), 10),
             IntegerNode(256...257)((256...257), 10)],
            BRACKET_LEFT_ARRAY(252...253)("["),
            BRACKET_RIGHT(257...258)("]")
          )],
         nil,
         nil
       ),
       nil,
       nil
     ),
     LocalVariableWriteNode(260...270)(
       (260...263),
       SplatNode(266...270)(
         USTAR(266...267)("*"),
         LocalVariableReadNode(267...270)(0)
       ),
       (264...265),
       0
     ),
     ConstantPathWriteNode(272...0)(
       ConstantReadNode(272...275)(),
       EQUAL(276...277)("="),
       ArrayNode(0...0)(
         [IntegerNode(278...279)((278...279), 10),
          IntegerNode(281...282)((281...282), 10)],
         nil,
         nil
       )
     ),
     ParenthesesNode(284...293)(
       StatementsNode(285...292)(
         [CallNode(285...286)(
            nil,
            nil,
            IDENTIFIER(285...286)("a"),
            nil,
            nil,
            nil,
            nil,
            "a"
          ),
          CallNode(288...289)(
            nil,
            nil,
            IDENTIFIER(288...289)("b"),
            nil,
            nil,
            nil,
            nil,
            "b"
          ),
          CallNode(291...292)(
            nil,
            nil,
            IDENTIFIER(291...292)("c"),
            nil,
            nil,
            nil,
            nil,
            "c"
          )]
       ),
       (284...285),
       (292...293)
     )]
  )
)
