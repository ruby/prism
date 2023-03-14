DefNode(
  IDENTIFIER("hi"),
  nil,
  ParametersNode([], [], nil, [], nil, nil),
  StatementsNode(
    [IfNode(
       KEYWORD_IF("if"),
       TrueNode(),
       StatementsNode(
         [ReturnNode(
            KEYWORD_RETURN("return"),
            ArgumentsNode(
              [SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("hi"), nil, "hi")]
            )
          )]
       ),
       nil,
       nil
     ),
     SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("bye"), nil, "bye")]
  ),
  Scope([]),
  (0..3),
  nil,
  nil,
  nil,
  nil,
  (31..34)
)
