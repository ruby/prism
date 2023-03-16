ProgramNode(
  Scope([]),
  StatementsNode(
    [AliasNode(
       SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("foo"), nil, "foo"),
       SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("bar"), nil, "bar"),
       (0..5)
     ),
     AliasNode(
       SymbolNode(
         SYMBOL_BEGIN("%s["),
         STRING_CONTENT("abc"),
         STRING_END("]"),
         "abc"
       ),
       SymbolNode(
         SYMBOL_BEGIN("%s["),
         STRING_CONTENT("def"),
         STRING_END("]"),
         "def"
       ),
       (17..22)
     ),
     AliasNode(
       SymbolNode(
         SYMBOL_BEGIN(":'"),
         STRING_CONTENT("abc"),
         STRING_END("'"),
         "abc"
       ),
       SymbolNode(
         SYMBOL_BEGIN(":'"),
         STRING_CONTENT("def"),
         STRING_END("'"),
         "def"
       ),
       (40..45)
     ),
     AliasNode(
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
       SymbolNode(
         SYMBOL_BEGIN(":'"),
         STRING_CONTENT("def"),
         STRING_END("'"),
         "def"
       ),
       (61..66)
     ),
     AliasNode(
       GlobalVariableReadNode(GLOBAL_VARIABLE("$a")),
       GlobalVariableReadNode(BACK_REFERENCE("$'")),
       (86..91)
     ),
     AliasNode(
       SymbolNode(nil, IDENTIFIER("foo"), nil, "foo"),
       SymbolNode(nil, IDENTIFIER("bar"), nil, "bar"),
       (99..104)
     ),
     AliasNode(
       GlobalVariableReadNode(GLOBAL_VARIABLE("$foo")),
       GlobalVariableReadNode(GLOBAL_VARIABLE("$bar")),
       (114..119)
     ),
     AliasNode(
       SymbolNode(nil, IDENTIFIER("foo"), nil, "foo"),
       SymbolNode(nil, KEYWORD_IF("if"), nil, "if"),
       (131..136)
     ),
     AliasNode(
       SymbolNode(nil, IDENTIFIER("foo"), nil, "foo"),
       SymbolNode(nil, LESS_EQUAL_GREATER("<=>"), nil, "<=>"),
       (145..150)
     ),
     AliasNode(
       SymbolNode(SYMBOL_BEGIN(":"), EQUAL_EQUAL("=="), nil, "=="),
       SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("eql?"), nil, "eql?"),
       (160..165)
     )]
  )
)
