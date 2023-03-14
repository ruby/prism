InterpolatedSymbolNode(
  SYMBOL_BEGIN(":\""),
  [StringInterpolatedNode(
     EMBEXPR_BEGIN("\#{"),
     StatementsNode(
       [CallNode(nil, nil, IDENTIFIER("var"), nil, nil, nil, nil, "var")]
     ),
     EMBEXPR_END("}")
   )],
  STRING_END("\"")
)
