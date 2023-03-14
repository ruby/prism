InterpolatedXStringNode(
  BACKTICK("`"),
  [StringNode(nil, STRING_CONTENT("foo "), nil, "foo "),
   StringInterpolatedNode(
     EMBEXPR_BEGIN("\#{"),
     StatementsNode(
       [CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar")]
     ),
     EMBEXPR_END("}")
   ),
   StringNode(nil, STRING_CONTENT(" baz"), nil, " baz")],
  STRING_END("`")
)
