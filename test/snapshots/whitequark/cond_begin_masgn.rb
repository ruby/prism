ProgramNode(0...25)(
  [:a, :b],
  StatementsNode(0...25)(
    [IfNode(0...25)(
       (0...2),
       ParenthesesNode(3...20)(
         StatementsNode(4...19)(
           [CallNode(4...7)(
              nil,
              nil,
              IDENTIFIER(4...7)("bar"),
              nil,
              nil,
              nil,
              nil,
              "bar"
            ),
            MultiWriteNode(9...19)(
              [LocalVariableWriteNode(9...10)(:a, 0, nil, (9...10), nil),
               LocalVariableWriteNode(12...13)(:b, 0, nil, (12...13), nil)],
              (14...15),
              CallNode(16...19)(
                nil,
                nil,
                IDENTIFIER(16...19)("foo"),
                nil,
                nil,
                nil,
                nil,
                "foo"
              ),
              nil,
              nil
            )]
         ),
         (3...4),
         (19...20)
       ),
       nil,
       nil,
       (22...25)
     )]
  )
)
