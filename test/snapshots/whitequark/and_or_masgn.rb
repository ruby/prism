ProgramNode(0...40)(
  [:a, :b],
  StatementsNode(0...40)(
    [AndNode(0...19)(
       CallNode(0...3)(
         nil,
         nil,
         IDENTIFIER(0...3)("foo"),
         nil,
         nil,
         nil,
         nil,
         "foo"
       ),
       ParenthesesNode(7...19)(
         StatementsNode(8...18)(
           [MultiWriteNode(8...18)(
              [LocalVariableWriteNode(8...9)(:a, 0, nil, (8...9), nil),
               LocalVariableWriteNode(11...12)(:b, 0, nil, (11...12), nil)],
              (13...14),
              CallNode(15...18)(
                nil,
                nil,
                IDENTIFIER(15...18)("bar"),
                nil,
                nil,
                nil,
                nil,
                "bar"
              ),
              nil,
              nil
            )]
         ),
         (7...8),
         (18...19)
       ),
       (4...6)
     ),
     OrNode(21...40)(
       CallNode(21...24)(
         nil,
         nil,
         IDENTIFIER(21...24)("foo"),
         nil,
         nil,
         nil,
         nil,
         "foo"
       ),
       ParenthesesNode(28...40)(
         StatementsNode(29...39)(
           [MultiWriteNode(29...39)(
              [LocalVariableWriteNode(29...30)(:a, 0, nil, (29...30), nil),
               LocalVariableWriteNode(32...33)(:b, 0, nil, (32...33), nil)],
              (34...35),
              CallNode(36...39)(
                nil,
                nil,
                IDENTIFIER(36...39)("bar"),
                nil,
                nil,
                nil,
                nil,
                "bar"
              ),
              nil,
              nil
            )]
         ),
         (28...29),
         (39...40)
       ),
       (25...27)
     )]
  )
)
