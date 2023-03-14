InterpolatedStringNode(
  STRING_BEGIN("%{"),
  [StringNode(nil, STRING_CONTENT("aaa "), nil, "aaa "),
   StringInterpolatedNode(
     EMBEXPR_BEGIN("\#{"),
     StatementsNode(
       [CallNode(nil, nil, IDENTIFIER("bbb"), nil, nil, nil, nil, "bbb")]
     ),
     EMBEXPR_END("}")
   ),
   StringNode(nil, STRING_CONTENT(" ccc"), nil, " ccc")],
  STRING_END("}")
)
