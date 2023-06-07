ProgramNode(0...262)(
  [],
  StatementsNode(0...262)(
    [LambdaNode(0...19)(
       [:a, :b, :c, :d],
       (0...2),
       BlockParametersNode(3...15)(
         ParametersNode(4...5)(
           [RequiredParameterNode(4...5)(:a)],
           [],
           [],
           nil,
           [],
           nil,
           nil
         ),
         [IDENTIFIER(7...8)("b"),
          IDENTIFIER(10...11)("c"),
          IDENTIFIER(13...14)("d")],
         (3...4),
         (14...15)
       ),
       StatementsNode(18...19)([LocalVariableReadNode(18...19)(:b, 0)])
     ),
     LambdaNode(23...39)(
       [],
       (23...25),
       nil,
       BeginNode(0...39)(
         nil,
         nil,
         nil,
         nil,
         EnsureNode(29...39)((29...35), nil, (36...39)),
         (36...39)
       )
     ),
     LambdaNode(41...69)(
       [],
       (41...43),
       nil,
       BeginNode(0...69)(
         nil,
         nil,
         RescueNode(47...53)((47...53), [], nil, nil, nil, nil),
         ElseNode(54...65)((54...58), nil, (59...65)),
         EnsureNode(59...69)((59...65), nil, (66...69)),
         (66...69)
       )
     ),
     LambdaNode(71...79)(
       [],
       (71...73),
       nil,
       StatementsNode(76...79)(
         [CallNode(76...79)(
            nil,
            nil,
            IDENTIFIER(76...79)("foo"),
            nil,
            nil,
            nil,
            nil,
            "foo"
          )]
       )
     ),
     LambdaNode(83...93)(
       [],
       (83...85),
       nil,
       StatementsNode(90...93)(
         [CallNode(90...93)(
            nil,
            nil,
            IDENTIFIER(90...93)("foo"),
            nil,
            nil,
            nil,
            nil,
            "foo"
          )]
       )
     ),
     LambdaNode(100...127)(
       [:a, :b, :c, :d, :e],
       (100...102),
       BlockParametersNode(103...123)(
         ParametersNode(103...123)(
           [RequiredParameterNode(103...104)(:a)],
           [OptionalParameterNode(106...111)(
              :b,
              (106...107),
              (108...109),
              IntegerNode(110...111)()
            )],
           [],
           nil,
           [KeywordParameterNode(113...115)((113...115), nil),
            KeywordParameterNode(117...119)((117...119), nil)],
           nil,
           BlockParameterNode(121...123)((122...123), (121...122))
         ),
         [],
         nil,
         nil
       ),
       StatementsNode(126...127)([LocalVariableReadNode(126...127)(:a, 0)])
     ),
     LambdaNode(131...169)(
       [:a, :b, :c, :d, :e, :f, :g],
       (131...133),
       BlockParametersNode(134...165)(
         ParametersNode(135...164)(
           [RequiredParameterNode(135...136)(:a)],
           [OptionalParameterNode(138...143)(
              :b,
              (138...139),
              (140...141),
              IntegerNode(142...143)()
            )],
           [],
           RestParameterNode(145...147)((145...146), (146...147)),
           [KeywordParameterNode(149...151)((149...151), nil),
            KeywordParameterNode(153...155)((153...155), nil)],
           KeywordRestParameterNode(157...160)((157...159), (159...160)),
           BlockParameterNode(162...164)((163...164), (162...163))
         ),
         [],
         (134...135),
         (164...165)
       ),
       StatementsNode(168...169)([LocalVariableReadNode(168...169)(:a, 0)])
     ),
     LambdaNode(173...214)(
       [:a, :b, :c, :d, :e, :f, :g],
       (173...175),
       BlockParametersNode(176...207)(
         ParametersNode(177...206)(
           [RequiredParameterNode(177...178)(:a)],
           [OptionalParameterNode(180...185)(
              :b,
              (180...181),
              (182...183),
              IntegerNode(184...185)()
            )],
           [],
           RestParameterNode(187...189)((187...188), (188...189)),
           [KeywordParameterNode(191...193)((191...193), nil),
            KeywordParameterNode(195...197)((195...197), nil)],
           KeywordRestParameterNode(199...202)((199...201), (201...202)),
           BlockParameterNode(204...206)((205...206), (204...205))
         ),
         [],
         (176...177),
         (206...207)
       ),
       StatementsNode(213...214)([LocalVariableReadNode(213...214)(:a, 0)])
     ),
     LambdaNode(220...241)(
       [:a],
       (220...222),
       BlockParametersNode(223...226)(
         ParametersNode(224...225)(
           [RequiredParameterNode(224...225)(:a)],
           [],
           [],
           nil,
           [],
           nil,
           nil
         ),
         [],
         (223...224),
         (225...226)
       ),
       StatementsNode(229...241)(
         [LambdaNode(229...241)(
            [:b],
            (229...231),
            BlockParametersNode(232...233)(
              ParametersNode(232...233)(
                [RequiredParameterNode(232...233)(:b)],
                [],
                [],
                nil,
                [],
                nil,
                nil
              ),
              [],
              nil,
              nil
            ),
            StatementsNode(236...241)(
              [CallNode(236...241)(
                 LocalVariableReadNode(236...237)(:a, 1),
                 nil,
                 STAR(238...239)("*"),
                 nil,
                 ArgumentsNode(240...241)(
                   [LocalVariableReadNode(240...241)(:b, 0)]
                 ),
                 nil,
                 nil,
                 "*"
               )]
            )
          )]
       )
     ),
     LambdaNode(247...262)(
       [:a, :b, :c],
       (247...249),
       BlockParametersNode(250...262)(
         ParametersNode(251...261)(
           [RequiredDestructuredParameterNode(251...257)(
              [RequiredParameterNode(252...253)(:a),
               RequiredParameterNode(255...256)(:b)],
              (251...252),
              (256...257)
            )],
           [],
           [],
           RestParameterNode(259...261)((259...260), (260...261)),
           [],
           nil,
           nil
         ),
         [],
         (250...251),
         (261...262)
       ),
       nil
     )]
  )
)
