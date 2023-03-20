ProgramNode(
  Scope([]),
  StatementsNode(
    [ArrayNode(
       [SplatNode(
          IDENTIFIER("a"),
          CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")
        )],
       BRACKET_LEFT_ARRAY("["),
       BRACKET_RIGHT("]")
     ),
     CallNode(
       CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
       nil,
       BRACKET_LEFT_RIGHT_EQUAL("["),
       BRACKET_LEFT("["),
       ArgumentsNode(
         [CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar"),
          CallNode(nil, nil, IDENTIFIER("baz"), nil, nil, nil, nil, "baz"),
          ArrayNode([IntegerNode(), IntegerNode(), IntegerNode()], nil, nil)]
       ),
       BRACKET_RIGHT("]"),
       nil,
       "[]="
     ),
     ArrayNode(
       [HashNode(
          nil,
          [AssocNode(
             SymbolNode(nil, LABEL("a"), LABEL_END(":"), "a"),
             ArrayNode(
               [SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("b"), nil, "b"),
                SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("c"), nil, "c")],
               BRACKET_LEFT_ARRAY("["),
               BRACKET_RIGHT("]")
             ),
             nil
           )],
          nil
        )],
       BRACKET_LEFT_ARRAY("["),
       BRACKET_RIGHT("]")
     ),
     ArrayNode(
       [SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("a"), nil, "a"),
        SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("b"), nil, "b"),
        SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("c"), nil, "c"),
        IntegerNode(),
        SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("d"), nil, "d")],
       BRACKET_LEFT_ARRAY("["),
       BRACKET_RIGHT("]")
     ),
     ArrayNode(
       [SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("a"), nil, "a"),
        SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("b"), nil, "b"),
        SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("c"), nil, "c"),
        IntegerNode(),
        SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("d"), nil, "d")],
       BRACKET_LEFT_ARRAY("["),
       BRACKET_RIGHT("]")
     ),
     ArrayNode(
       [HashNode(
          nil,
          [AssocNode(
             CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
             CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar"),
             EQUAL_GREATER("=>")
           )],
          nil
        )],
       BRACKET_LEFT_ARRAY("["),
       BRACKET_RIGHT("]")
     ),
     CallNode(
       CallNode(
         CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
         nil,
         BRACKET_LEFT_RIGHT("["),
         BRACKET_LEFT("["),
         ArgumentsNode(
           [CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar")]
         ),
         BRACKET_RIGHT("]"),
         nil,
         "[]"
       ),
       nil,
       BRACKET_LEFT_RIGHT_EQUAL("["),
       BRACKET_LEFT("["),
       ArgumentsNode(
         [CallNode(nil, nil, IDENTIFIER("baz"), nil, nil, nil, nil, "baz"),
          CallNode(nil, nil, IDENTIFIER("qux"), nil, nil, nil, nil, "qux")]
       ),
       BRACKET_RIGHT("]"),
       nil,
       "[]="
     ),
     CallNode(
       CallNode(
         CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
         nil,
         BRACKET_LEFT_RIGHT("["),
         BRACKET_LEFT("["),
         ArgumentsNode(
           [CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar")]
         ),
         BRACKET_RIGHT("]"),
         nil,
         "[]"
       ),
       nil,
       BRACKET_LEFT_RIGHT("["),
       BRACKET_LEFT("["),
       ArgumentsNode(
         [CallNode(nil, nil, IDENTIFIER("baz"), nil, nil, nil, nil, "baz")]
       ),
       BRACKET_RIGHT("]"),
       nil,
       "[]"
     ),
     ArrayNode([], BRACKET_LEFT_ARRAY("["), BRACKET_RIGHT("]")),
     CallNode(
       CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
       nil,
       BRACKET_LEFT_RIGHT("["),
       BRACKET_LEFT("["),
       ArgumentsNode(
         [CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar"),
          CallNode(nil, nil, IDENTIFIER("baz"), nil, nil, nil, nil, "baz")]
       ),
       BRACKET_RIGHT("]"),
       nil,
       "[]"
     ),
     CallNode(
       CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
       nil,
       BRACKET_LEFT_RIGHT_EQUAL("["),
       BRACKET_LEFT("["),
       ArgumentsNode(
         [CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar"),
          CallNode(nil, nil, IDENTIFIER("baz"), nil, nil, nil, nil, "baz"),
          CallNode(nil, nil, IDENTIFIER("qux"), nil, nil, nil, nil, "qux")]
       ),
       BRACKET_RIGHT("]"),
       nil,
       "[]="
     ),
     MultiWriteNode(
       [CallNode(
          CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
          nil,
          BRACKET_LEFT_RIGHT_EQUAL("["),
          BRACKET_LEFT("["),
          ArgumentsNode([IntegerNode()]),
          BRACKET_RIGHT("]"),
          nil,
          "[]="
        ),
        CallNode(
          CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar"),
          nil,
          BRACKET_LEFT_RIGHT_EQUAL("["),
          BRACKET_LEFT("["),
          ArgumentsNode([IntegerNode()]),
          BRACKET_RIGHT("]"),
          nil,
          "[]="
        )],
       EQUAL("="),
       ArrayNode([IntegerNode(), IntegerNode()], nil, nil),
       nil,
       nil
     ),
     CallNode(
       CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
       nil,
       BRACKET_LEFT_RIGHT("["),
       BRACKET_LEFT("["),
       ArgumentsNode(
         [CallNode(
            CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar"),
            nil,
            BRACKET_LEFT_RIGHT_EQUAL("["),
            BRACKET_LEFT("["),
            ArgumentsNode(
              [CallNode(
                 nil,
                 nil,
                 IDENTIFIER("baz"),
                 nil,
                 nil,
                 nil,
                 nil,
                 "baz"
               ),
               CallNode(
                 nil,
                 nil,
                 IDENTIFIER("qux"),
                 nil,
                 nil,
                 nil,
                 nil,
                 "qux"
               )]
            ),
            BRACKET_RIGHT("]"),
            nil,
            "[]="
          )]
       ),
       BRACKET_RIGHT("]"),
       nil,
       "[]"
     ),
     CallNode(
       CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
       nil,
       BRACKET_LEFT_RIGHT("["),
       BRACKET_LEFT("["),
       ArgumentsNode(
         [CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar")]
       ),
       BRACKET_RIGHT("]"),
       nil,
       "[]"
     ),
     CallNode(
       CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
       nil,
       BRACKET_LEFT_RIGHT_EQUAL("["),
       BRACKET_LEFT("["),
       ArgumentsNode(
         [CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar"),
          CallNode(nil, nil, IDENTIFIER("baz"), nil, nil, nil, nil, "baz")]
       ),
       BRACKET_RIGHT("]"),
       nil,
       "[]="
     ),
     ArrayNode(
       [HashNode(
          nil,
          [AssocSplatNode(
             HashNode(BRACE_LEFT("{"), [], BRACE_RIGHT("}")),
             (262..264)
           )],
          nil
        )],
       BRACKET_LEFT_ARRAY("["),
       BRACKET_RIGHT("]")
     ),
     ArrayNode(
       [HashNode(
          nil,
          [AssocSplatNode(
             CallNode(nil, nil, IDENTIFIER("kw"), nil, nil, nil, nil, "kw"),
             (270..272)
           )],
          nil
        )],
       BRACKET_LEFT_ARRAY("["),
       BRACKET_RIGHT("]")
     ),
     ArrayNode(
       [IntegerNode(),
        HashNode(
          nil,
          [AssocSplatNode(
             CallNode(nil, nil, IDENTIFIER("kw"), nil, nil, nil, nil, "kw"),
             (281..283)
           )],
          nil
        )],
       BRACKET_LEFT_ARRAY("["),
       BRACKET_RIGHT("]")
     ),
     ArrayNode(
       [IntegerNode(),
        HashNode(
          nil,
          [AssocSplatNode(
             CallNode(nil, nil, IDENTIFIER("kw"), nil, nil, nil, nil, "kw"),
             (292..294)
           ),
           AssocSplatNode(
             HashNode(BRACE_LEFT("{"), [], BRACE_RIGHT("}")),
             (298..300)
           ),
           AssocSplatNode(
             CallNode(nil, nil, IDENTIFIER("kw"), nil, nil, nil, nil, "kw"),
             (304..306)
           )],
          nil
        )],
       BRACKET_LEFT_ARRAY("["),
       BRACKET_RIGHT("]")
     )]
  )
)
