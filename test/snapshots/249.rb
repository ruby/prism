InterpolatedSymbolNode(
  SYMBOL_BEGIN(":\""),
  [StringNode(nil, STRING_CONTENT("abc"), nil, "abc"),
   StringInterpolatedNode(
     EMBEXPR_BEGIN("\#{"),
     StatementsNode([IntegerNode()]),
     EMBEXPR_END("}")
   )],
  STRING_END("\"")
)
