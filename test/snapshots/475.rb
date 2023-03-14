ArrayNode(
  [SymbolNode(nil, STRING_CONTENT("a"), nil, "a"),
   InterpolatedSymbolNode(
     nil,
     [StringNode(nil, STRING_CONTENT("b"), nil, "b"),
      StringInterpolatedNode(
        EMBEXPR_BEGIN("\#{"),
        StatementsNode([IntegerNode()]),
        EMBEXPR_END("}")
      )],
     nil
   ),
   InterpolatedSymbolNode(
     nil,
     [StringInterpolatedNode(
        EMBEXPR_BEGIN("\#{"),
        StatementsNode([IntegerNode()]),
        EMBEXPR_END("}")
      ),
      StringNode(nil, STRING_CONTENT("c"), nil, "c")],
     nil
   ),
   InterpolatedSymbolNode(
     nil,
     [StringNode(nil, STRING_CONTENT("d"), nil, "d"),
      StringInterpolatedNode(
        EMBEXPR_BEGIN("\#{"),
        StatementsNode([IntegerNode()]),
        EMBEXPR_END("}")
      ),
      StringNode(nil, STRING_CONTENT("f"), nil, "f")],
     nil
   )],
  PERCENT_UPPER_I("%I["),
  STRING_END("]")
)
