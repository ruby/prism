ProgramNode(0...27)(
  [],
  StatementsNode(0...27)(
    [UndefNode(0...27)(
       [SymbolNode(6...9)(nil, IDENTIFIER(6...9)("foo"), nil, "foo"),
        SymbolNode(11...15)(
          SYMBOL_BEGIN(11...12)(":"),
          IDENTIFIER(12...15)("bar"),
          nil,
          "bar"
        ),
        InterpolatedSymbolNode(17...27)(
          SYMBOL_BEGIN(17...19)(":\""),
          [StringNode(19...22)(nil, (19...22), nil, "foo"),
           StringInterpolatedNode(22...26)(
             (22...24),
             StatementsNode(24...25)([IntegerNode(24...25)()]),
             (25...26)
           )],
          STRING_END(26...27)("\"")
        )],
       (0...5)
     )]
  )
)
