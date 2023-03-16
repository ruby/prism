ProgramNode(
  Scope([]),
  StatementsNode(
    [SymbolNode(
       SYMBOL_BEGIN(":'"),
       STRING_CONTENT("abc"),
       STRING_END("'"),
       "abc"
     ),
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
     ),
     InterpolatedSymbolNode(
       SYMBOL_BEGIN(":\""),
       [StringNode(nil, STRING_CONTENT("abc"), nil, "abc"),
        StringInterpolatedNode(
          EMBEXPR_BEGIN("\#{"),
          StatementsNode([IntegerNode()]),
          EMBEXPR_END("}")
        )],
       STRING_END("\"")
     ),
     ArrayNode(
       [SymbolNode(SYMBOL_BEGIN(":"), CONSTANT("Υ"), nil, "Υ"),
        SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("ά"), nil, "ά"),
        SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("ŗ"), nil, "ŗ"),
        SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("ρ"), nil, "ρ")],
       BRACKET_LEFT_ARRAY("["),
       BRACKET_RIGHT("]")
     ),
     SymbolNode(SYMBOL_BEGIN(":"), UMINUS("-@"), nil, "-@"),
     SymbolNode(SYMBOL_BEGIN(":"), MINUS("-"), nil, "-"),
     SymbolNode(SYMBOL_BEGIN(":"), PERCENT("%"), nil, "%"),
     SymbolNode(SYMBOL_BEGIN(":"), PIPE("|"), nil, "|"),
     SymbolNode(SYMBOL_BEGIN(":"), UPLUS("+@"), nil, "+@"),
     SymbolNode(SYMBOL_BEGIN(":"), PLUS("+"), nil, "+"),
     SymbolNode(SYMBOL_BEGIN(":"), SLASH("/"), nil, "/"),
     SymbolNode(SYMBOL_BEGIN(":"), STAR_STAR("**"), nil, "**"),
     SymbolNode(SYMBOL_BEGIN(":"), STAR("*"), nil, "*"),
     SymbolNode(SYMBOL_BEGIN(":"), TILDE("~@"), nil, "~@"),
     ArrayNode(
       [IntegerNode(), FloatNode(), RationalNode(), ImaginaryNode()],
       BRACKET_LEFT_ARRAY("["),
       BRACKET_RIGHT("]")
     ),
     SymbolNode(SYMBOL_BEGIN(":"), TILDE("~"), nil, "~"),
     SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("a"), nil, "a"),
     ArrayNode(
       [SymbolNode(nil, STRING_CONTENT("a"), nil, "a"),
        SymbolNode(nil, STRING_CONTENT("b"), nil, "b"),
        SymbolNode(nil, STRING_CONTENT("c"), nil, "c")],
       PERCENT_LOWER_I("%i["),
       STRING_END("]")
     ),
     ArrayNode(
       [SymbolNode(nil, STRING_CONTENT("a"), nil, "a"),
        SymbolNode(nil, STRING_CONTENT("b\#{1}"), nil, "b\#{1}"),
        SymbolNode(nil, STRING_CONTENT("\#{2}c"), nil, "\#{2}c"),
        SymbolNode(nil, STRING_CONTENT("d\#{3}f"), nil, "d\#{3}f")],
       PERCENT_LOWER_I("%i["),
       STRING_END("]")
     ),
     ArrayNode(
       [SymbolNode(nil, STRING_CONTENT("a"), nil, "a"),
        InterpolatedSymbolNode(
          nil,
          [StringNode(nil, STRING_CONTENT("b"), nil, ""),
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
          [StringNode(nil, STRING_CONTENT("d"), nil, ""),
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
     ),
     SymbolNode(SYMBOL_BEGIN(":"), CLASS_VARIABLE("@@a"), nil, "@@a"),
     SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("👍"), nil, "👍"),
     ArrayNode(
       [SymbolNode(nil, STRING_CONTENT("a\\b"), nil, "a\b")],
       PERCENT_LOWER_I("%i["),
       STRING_END("]")
     ),
     SymbolNode(SYMBOL_BEGIN(":"), GLOBAL_VARIABLE("$a"), nil, "$a"),
     SymbolNode(SYMBOL_BEGIN(":"), INSTANCE_VARIABLE("@a"), nil, "@a"),
     SymbolNode(SYMBOL_BEGIN(":"), KEYWORD_DO("do"), nil, "do"),
     SymbolNode(SYMBOL_BEGIN(":"), AMPERSAND("&"), nil, "&"),
     SymbolNode(SYMBOL_BEGIN(":"), BACKTICK("`"), nil, "`"),
     SymbolNode(SYMBOL_BEGIN(":"), BANG("!@"), nil, "!@"),
     SymbolNode(SYMBOL_BEGIN(":"), BANG_TILDE("!~"), nil, "!~"),
     SymbolNode(SYMBOL_BEGIN(":"), BANG("!"), nil, "!"),
     SymbolNode(SYMBOL_BEGIN(":"), BRACKET_LEFT_RIGHT("[]"), nil, "[]"),
     SymbolNode(
       SYMBOL_BEGIN(":"),
       BRACKET_LEFT_RIGHT_EQUAL("[]="),
       nil,
       "[]="
     ),
     SymbolNode(SYMBOL_BEGIN(":"), CARET("^"), nil, "^"),
     SymbolNode(SYMBOL_BEGIN(":"), EQUAL_EQUAL("=="), nil, "=="),
     SymbolNode(SYMBOL_BEGIN(":"), EQUAL_EQUAL_EQUAL("==="), nil, "==="),
     SymbolNode(SYMBOL_BEGIN(":"), EQUAL_TILDE("=~"), nil, "=~"),
     SymbolNode(SYMBOL_BEGIN(":"), GREATER_EQUAL(">="), nil, ">="),
     SymbolNode(SYMBOL_BEGIN(":"), GREATER_GREATER(">>"), nil, ">>"),
     SymbolNode(SYMBOL_BEGIN(":"), GREATER(">"), nil, ">"),
     SymbolNode(SYMBOL_BEGIN(":"), LESS_EQUAL_GREATER("<=>"), nil, "<=>"),
     SymbolNode(SYMBOL_BEGIN(":"), LESS_EQUAL("<="), nil, "<="),
     SymbolNode(SYMBOL_BEGIN(":"), LESS_LESS("<<"), nil, "<<"),
     SymbolNode(SYMBOL_BEGIN(":"), LESS("<"), nil, "<")]
  )
)
