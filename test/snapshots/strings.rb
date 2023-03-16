ProgramNode(
  Scope([]),
  StatementsNode(
    [StringNode(
       STRING_BEGIN("%%"),
       STRING_CONTENT("abc"),
       STRING_END("%"),
       "abc"
     ),
     StringNode(
       STRING_BEGIN("%^"),
       STRING_CONTENT("abc"),
       STRING_END("^"),
       "abc"
     ),
     StringNode(
       STRING_BEGIN("%&"),
       STRING_CONTENT("abc"),
       STRING_END("&"),
       "abc"
     ),
     StringNode(
       STRING_BEGIN("%*"),
       STRING_CONTENT("abc"),
       STRING_END("*"),
       "abc"
     ),
     StringNode(
       STRING_BEGIN("%_"),
       STRING_CONTENT("abc"),
       STRING_END("_"),
       "abc"
     ),
     StringNode(
       STRING_BEGIN("%+"),
       STRING_CONTENT("abc"),
       STRING_END("+"),
       "abc"
     ),
     StringNode(
       STRING_BEGIN("%-"),
       STRING_CONTENT("abc"),
       STRING_END("-"),
       "abc"
     ),
     StringNode(
       STRING_BEGIN("%:"),
       STRING_CONTENT("abc"),
       STRING_END(":"),
       "abc"
     ),
     StringNode(
       STRING_BEGIN("%;"),
       STRING_CONTENT("abc"),
       STRING_END(";"),
       "abc"
     ),
     StringNode(
       STRING_BEGIN("%'"),
       STRING_CONTENT("abc"),
       STRING_END("'"),
       "abc"
     ),
     StringNode(
       STRING_BEGIN("%~"),
       STRING_CONTENT("abc"),
       STRING_END("~"),
       "abc"
     ),
     StringNode(
       STRING_BEGIN("%?"),
       STRING_CONTENT("abc"),
       STRING_END("?"),
       "abc"
     ),
     ArrayNode([], PERCENT_LOWER_W("%w{"), STRING_END("}")),
     StringNode(
       STRING_BEGIN("%/"),
       STRING_CONTENT("abc"),
       STRING_END("/"),
       "abc"
     ),
     StringNode(
       STRING_BEGIN("%`"),
       STRING_CONTENT("abc"),
       STRING_END("`"),
       "abc"
     ),
     InterpolatedStringNode(
       STRING_BEGIN("\""),
       [ClassVariableReadNode()],
       STRING_END("\"")
     ),
     StringNode(
       STRING_BEGIN("%\\"),
       STRING_CONTENT("abc"),
       STRING_END("\\"),
       "abc"
     ),
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
     ),
     StringNode(
       STRING_BEGIN("%["),
       STRING_CONTENT("foo[]"),
       STRING_END("]"),
       "foo[]"
     ),
     CallNode(
       StringNode(
         STRING_BEGIN("\""),
         STRING_CONTENT("foo"),
         STRING_END("\""),
         "foo"
       ),
       nil,
       PLUS("+"),
       nil,
       ArgumentsNode(
         [StringNode(
            STRING_BEGIN("\""),
            STRING_CONTENT("bar"),
            STRING_END("\""),
            "bar"
          )]
       ),
       nil,
       nil,
       "+"
     ),
     StringNode(
       STRING_BEGIN("%q{"),
       STRING_CONTENT("abc"),
       STRING_END("}"),
       "abc"
     ),
     SymbolNode(
       SYMBOL_BEGIN("%s["),
       STRING_CONTENT("abc"),
       STRING_END("]"),
       "abc"
     ),
     StringNode(
       STRING_BEGIN("%{"),
       STRING_CONTENT("abc"),
       STRING_END("}"),
       "abc"
     ),
     StringNode(STRING_BEGIN("'"), STRING_CONTENT(""), STRING_END("'"), ""),
     StringNode(
       STRING_BEGIN("\""),
       STRING_CONTENT("abc"),
       STRING_END("\""),
       "abc"
     ),
     StringNode(
       STRING_BEGIN("\""),
       STRING_CONTENT("\#@---"),
       STRING_END("\""),
       "\#@---"
     ),
     InterpolatedStringNode(
       STRING_BEGIN("\""),
       [StringNode(nil, STRING_CONTENT("aaa "), nil, "aaa "),
        StringInterpolatedNode(
          EMBEXPR_BEGIN("\#{"),
          StatementsNode(
            [CallNode(nil, nil, IDENTIFIER("bbb"), nil, nil, nil, nil, "bbb")]
          ),
          EMBEXPR_END("}")
        ),
        StringNode(nil, STRING_CONTENT(" ccc"), nil, " ccc")],
       STRING_END("\"")
     ),
     StringNode(
       STRING_BEGIN("'"),
       STRING_CONTENT("abc"),
       STRING_END("'"),
       "abc"
     ),
     ArrayNode(
       [StringNode(nil, STRING_CONTENT("a"), nil, "a"),
        StringNode(nil, STRING_CONTENT("b"), nil, "b"),
        StringNode(nil, STRING_CONTENT("c"), nil, "c")],
       PERCENT_LOWER_W("%w["),
       STRING_END("]")
     ),
     ArrayNode(
       [StringNode(nil, STRING_CONTENT("a[]"), nil, "a[]"),
        StringNode(nil, STRING_CONTENT("b[[]]"), nil, "b[[]]"),
        StringNode(nil, STRING_CONTENT("c[]"), nil, "c[]")],
       PERCENT_LOWER_W("%w["),
       STRING_END("]")
     ),
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
     ),
     ArrayNode(
       [StringNode(nil, STRING_CONTENT("a"), nil, "a"),
        StringNode(nil, STRING_CONTENT("b"), nil, "b"),
        StringNode(nil, STRING_CONTENT("c"), nil, "c")],
       PERCENT_UPPER_W("%W["),
       STRING_END("]")
     ),
     ArrayNode(
       [StringNode(nil, STRING_CONTENT("a"), nil, "a"),
        StringNode(nil, STRING_CONTENT("b"), nil, "b"),
        StringNode(nil, STRING_CONTENT("c"), nil, "c")],
       PERCENT_LOWER_W("%w["),
       STRING_END("]")
     ),
     StringNode(
       STRING_BEGIN("'"),
       STRING_CONTENT("\\' foo \\' bar"),
       STRING_END("'"),
       "' foo ' bar"
     ),
     StringNode(
       STRING_BEGIN("'"),
       STRING_CONTENT("\\\\ foo \\\\ bar"),
       STRING_END("'"),
       "\\ foo \\ bar"
     ),
     InterpolatedStringNode(
       STRING_BEGIN("\""),
       [GlobalVariableReadNode(GLOBAL_VARIABLE("$foo"))],
       STRING_END("\"")
     ),
     InterpolatedStringNode(
       STRING_BEGIN("\""),
       [InstanceVariableReadNode()],
       STRING_END("\"")
     ),
     StringNode(
       STRING_BEGIN("\""),
       STRING_CONTENT("\\x7 \\x23 \\x61"),
       STRING_END("\""),
       "\a # a"
     ),
     StringNode(
       STRING_BEGIN("\""),
       STRING_CONTENT("\\7 \\43 \\141"),
       STRING_END("\""),
       "\a # a"
     ),
     StringNode(
       STRING_BEGIN("%["),
       STRING_CONTENT("abc"),
       STRING_END("]"),
       "abc"
     ),
     StringNode(
       STRING_BEGIN("%("),
       STRING_CONTENT("abc"),
       STRING_END(")"),
       "abc"
     ),
     StringNode(
       STRING_BEGIN("%@"),
       STRING_CONTENT("abc"),
       STRING_END("@"),
       "abc"
     ),
     StringNode(
       STRING_BEGIN("%$"),
       STRING_CONTENT("abc"),
       STRING_END("$"),
       "abc"
     ),
     StringNode(STRING_BEGIN("?"), STRING_CONTENT("a"), nil, "a"),
     StringNode(
       STRING_BEGIN("%Q{"),
       STRING_CONTENT("abc"),
       STRING_END("}"),
       "abc"
     )]
  )
)
