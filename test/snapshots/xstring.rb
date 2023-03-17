ProgramNode(
  Scope([]),
  StatementsNode(
    [XStringNode(
       PERCENT_LOWER_X("%x["),
       STRING_CONTENT("foo"),
       STRING_END("]"),
       "foo"
     ),
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
     ),
     XStringNode(
       BACKTICK("`"),
       STRING_CONTENT("f\\oo"),
       STRING_END("`"),
       "foo"
     ),
     XStringNode(BACKTICK("`"), STRING_CONTENT("foo"), STRING_END("`"), "foo")]
  )
)
