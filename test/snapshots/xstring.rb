ProgramNode(0...40)(
  [],
  StatementsNode(0...40)(
    [XStringNode(0...7)((0...3), (3...6), (6...7), "foo"),
     InterpolatedXStringNode(9...25)(
       (9...10),
       [StringNode(10...14)(nil, (10...14), nil, "foo "),
        StringInterpolatedNode(14...20)(
          (14...16),
          StatementsNode(16...19)(
            [CallNode(16...19)(
               nil,
               nil,
               IDENTIFIER(16...19)("bar"),
               nil,
               nil,
               nil,
               nil,
               "bar"
             )]
          ),
          (19...20)
        ),
        StringNode(20...24)(nil, (20...24), nil, " baz")],
       (24...25)
     ),
     XStringNode(27...33)((27...28), (28...32), (32...33), "foo"),
     XStringNode(35...40)((35...36), (36...39), (39...40), "foo")]
  )
)
