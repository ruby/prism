ArrayNode(
  [StringNode(nil, STRING_CONTENT("a"), nil, "a"),
   InterpolatedStringNode(
     nil,
     [StringNode(nil, STRING_CONTENT("b"), nil, "b"),
      StringInterpolatedNode(
        EMBEXPR_BEGIN("\#{"),
        StatementsNode(
          [CallNode(nil, nil, IDENTIFIER("c"), nil, nil, nil, nil, "c")]
        ),
        EMBEXPR_END("}")
      ),
      StringNode(nil, STRING_CONTENT("d"), nil, "d")],
     nil
   ),
   StringNode(nil, STRING_CONTENT("e"), nil, "e")],
  PERCENT_UPPER_W("%W["),
  STRING_END("]")
)
