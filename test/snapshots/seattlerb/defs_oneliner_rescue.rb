ProgramNode(0...145)(
  ScopeNode(0...0)([]),
  StatementsNode(0...145)(
    [DefNode(0...49)(
       IDENTIFIER(9...13)("exec"),
       SelfNode(4...8)(),
       ParametersNode(14...17)(
         [RequiredParameterNode(14...17)()],
         [],
         nil,
         [],
         nil,
         nil
       ),
       BeginNode(0...49)(
         nil,
         StatementsNode(21...32)(
           [CallNode(21...32)(
              nil,
              nil,
              IDENTIFIER(21...27)("system"),
              PARENTHESIS_LEFT(27...28)("("),
              ArgumentsNode(28...31)([LocalVariableReadNode(28...31)(1)]),
              PARENTHESIS_RIGHT(31...32)(")"),
              nil,
              "system"
            )]
         ),
         RescueNode(33...45)(
           KEYWORD_RESCUE(33...39)("rescue"),
           [],
           nil,
           nil,
           StatementsNode(42...45)([NilNode(42...45)()]),
           nil
         ),
         nil,
         nil,
         KEYWORD_END(46...49)("end")
       ),
       ScopeNode(0...3)([IDENTIFIER(14...17)("cmd")]),
       (0...3),
       (8...9),
       (13...14),
       (17...18),
       nil,
       (46...49)
     ),
     DefNode(52...99)(
       IDENTIFIER(61...65)("exec"),
       SelfNode(56...60)(),
       ParametersNode(66...69)(
         [RequiredParameterNode(66...69)()],
         [],
         nil,
         [],
         nil,
         nil
       ),
       StatementsNode(73...95)(
         [RescueModifierNode(73...95)(
            CallNode(73...84)(
              nil,
              nil,
              IDENTIFIER(73...79)("system"),
              PARENTHESIS_LEFT(79...80)("("),
              ArgumentsNode(80...83)([LocalVariableReadNode(80...83)(1)]),
              PARENTHESIS_RIGHT(83...84)(")"),
              nil,
              "system"
            ),
            KEYWORD_RESCUE_MODIFIER(85...91)("rescue"),
            NilNode(92...95)()
          )]
       ),
       ScopeNode(52...55)([IDENTIFIER(66...69)("cmd")]),
       (52...55),
       (60...61),
       (65...66),
       (69...70),
       nil,
       (96...99)
     ),
     DefNode(102...145)(
       IDENTIFIER(111...115)("exec"),
       SelfNode(106...110)(),
       ParametersNode(116...119)(
         [RequiredParameterNode(116...119)()],
         [],
         nil,
         [],
         nil,
         nil
       ),
       StatementsNode(123...145)(
         [RescueModifierNode(123...145)(
            CallNode(123...134)(
              nil,
              nil,
              IDENTIFIER(123...129)("system"),
              PARENTHESIS_LEFT(129...130)("("),
              ArgumentsNode(130...133)([LocalVariableReadNode(130...133)(1)]),
              PARENTHESIS_RIGHT(133...134)(")"),
              nil,
              "system"
            ),
            KEYWORD_RESCUE_MODIFIER(135...141)("rescue"),
            NilNode(142...145)()
          )]
       ),
       ScopeNode(102...105)([IDENTIFIER(116...119)("cmd")]),
       (102...105),
       (110...111),
       (115...116),
       (119...120),
       (121...122),
       nil
     )]
  )
)
