ProgramNode(0...139)(
  [:c, :d, :b, :a],
  StatementsNode(0...139)(
    [MultiWriteNode(0...7)(
       [SplatNode(0...1)((0...1), nil)],
       (2...3),
       CallNode(4...7)(
         nil,
         nil,
         IDENTIFIER(4...7)("bar"),
         nil,
         nil,
         nil,
         nil,
         "bar"
       ),
       nil,
       nil
     ),
     MultiWriteNode(9...22)(
       [MultiWriteNode(9...10)(
          [SplatNode(9...10)((9...10), nil)],
          nil,
          nil,
          nil,
          nil
        ),
        LocalVariableWriteNode(12...13)(:c, 0, nil, (12...13), nil),
        LocalVariableWriteNode(15...16)(:d, 0, nil, (15...16), nil)],
       (17...18),
       CallNode(19...22)(
         nil,
         nil,
         IDENTIFIER(19...22)("bar"),
         nil,
         nil,
         nil,
         nil,
         "bar"
       ),
       nil,
       nil
     ),
     MultiWriteNode(24...32)(
       [SplatNode(24...26)(
          (24...25),
          LocalVariableWriteNode(25...26)(:b, 0, nil, (25...26), nil)
        )],
       (27...28),
       CallNode(29...32)(
         nil,
         nil,
         IDENTIFIER(29...32)("bar"),
         nil,
         nil,
         nil,
         nil,
         "bar"
       ),
       nil,
       nil
     ),
     MultiWriteNode(34...45)(
       [MultiWriteNode(34...36)(
          [SplatNode(34...36)(
             (34...35),
             LocalVariableWriteNode(35...36)(:b, 0, nil, (35...36), nil)
           )],
          nil,
          nil,
          nil,
          nil
        ),
        LocalVariableWriteNode(38...39)(:c, 0, nil, (38...39), nil)],
       (40...41),
       CallNode(42...45)(
         nil,
         nil,
         IDENTIFIER(42...45)("bar"),
         nil,
         nil,
         nil,
         nil,
         "bar"
       ),
       nil,
       nil
     ),
     MultiWriteNode(47...65)(
       [InstanceVariableWriteNode(47...51)((47...51), nil, nil),
        ClassVariableWriteNode(53...58)((53...58), nil, nil)],
       (59...60),
       SplatNode(61...65)(
         (61...62),
         CallNode(62...65)(
           nil,
           nil,
           IDENTIFIER(62...65)("foo"),
           nil,
           nil,
           nil,
           nil,
           "foo"
         )
       ),
       nil,
       nil
     ),
     MultiWriteNode(67...77)(
       [LocalVariableWriteNode(67...68)(:a, 0, nil, (67...68), nil),
        SplatNode(70...71)((70...71), nil)],
       (72...73),
       CallNode(74...77)(
         nil,
         nil,
         IDENTIFIER(74...77)("bar"),
         nil,
         nil,
         nil,
         nil,
         "bar"
       ),
       nil,
       nil
     ),
     MultiWriteNode(79...92)(
       [LocalVariableWriteNode(79...80)(:a, 0, nil, (79...80), nil),
        SplatNode(82...83)((82...83), nil),
        LocalVariableWriteNode(85...86)(:c, 0, nil, (85...86), nil)],
       (87...88),
       CallNode(89...92)(
         nil,
         nil,
         IDENTIFIER(89...92)("bar"),
         nil,
         nil,
         nil,
         nil,
         "bar"
       ),
       nil,
       nil
     ),
     MultiWriteNode(94...105)(
       [LocalVariableWriteNode(94...95)(:a, 0, nil, (94...95), nil),
        SplatNode(97...99)(
          (97...98),
          LocalVariableWriteNode(98...99)(:b, 0, nil, (98...99), nil)
        )],
       (100...101),
       CallNode(102...105)(
         nil,
         nil,
         IDENTIFIER(102...105)("bar"),
         nil,
         nil,
         nil,
         nil,
         "bar"
       ),
       nil,
       nil
     ),
     MultiWriteNode(107...121)(
       [LocalVariableWriteNode(107...108)(:a, 0, nil, (107...108), nil),
        SplatNode(110...112)(
          (110...111),
          LocalVariableWriteNode(111...112)(:b, 0, nil, (111...112), nil)
        ),
        LocalVariableWriteNode(114...115)(:c, 0, nil, (114...115), nil)],
       (116...117),
       CallNode(118...121)(
         nil,
         nil,
         IDENTIFIER(118...121)("bar"),
         nil,
         nil,
         nil,
         nil,
         "bar"
       ),
       nil,
       nil
     ),
     MultiWriteNode(123...139)(
       [LocalVariableWriteNode(123...124)(:a, 0, nil, (123...124), nil),
        LocalVariableWriteNode(126...127)(:b, 0, nil, (126...127), nil)],
       (128...129),
       ArrayNode(0...139)(
         [SplatNode(130...134)(
            (130...131),
            CallNode(131...134)(
              nil,
              nil,
              IDENTIFIER(131...134)("foo"),
              nil,
              nil,
              nil,
              nil,
              "foo"
            )
          ),
          CallNode(136...139)(
            nil,
            nil,
            IDENTIFIER(136...139)("bar"),
            nil,
            nil,
            nil,
            nil,
            "bar"
          )],
         nil,
         nil
       ),
       nil,
       nil
     )]
  )
)
