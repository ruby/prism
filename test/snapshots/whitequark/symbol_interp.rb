ProgramNode(0...15)(
  [],
  StatementsNode(0...15)(
    [InterpolatedSymbolNode(0...15)(
       SYMBOL_BEGIN(0...2)(":\""),
       [StringNode(2...5)(nil, (2...5), nil, "foo"),
        StringInterpolatedNode(5...11)(
          (5...7),
          StatementsNode(7...10)(
            [CallNode(7...10)(
               nil,
               nil,
               IDENTIFIER(7...10)("bar"),
               nil,
               nil,
               nil,
               nil,
               "bar"
             )]
          ),
          (10...11)
        ),
        StringNode(11...14)(nil, (11...14), nil, "baz")],
       STRING_END(14...15)("\"")
     )]
  )
)
