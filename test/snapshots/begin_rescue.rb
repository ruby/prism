ProgramNode(
  Scope([IDENTIFIER("ex")]),
  StatementsNode(
    [BeginNode(
       KEYWORD_BEGIN("begin"),
       StatementsNode(
         [CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")]
       ),
       RescueNode(
         KEYWORD_RESCUE("rescue"),
         [],
         nil,
         nil,
         StatementsNode(
           [CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]
         ),
         nil
       ),
       ElseNode(
         KEYWORD_ELSE("else"),
         StatementsNode(
           [CallNode(nil, nil, IDENTIFIER("c"), nil, nil, nil, nil, "c")]
         ),
         SEMICOLON(";")
       ),
       nil,
       KEYWORD_END("end")
     ),
     BeginNode(
       KEYWORD_BEGIN("begin"),
       StatementsNode(
         [CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")]
       ),
       RescueNode(
         KEYWORD_RESCUE("rescue"),
         [],
         nil,
         nil,
         StatementsNode(
           [CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]
         ),
         nil
       ),
       ElseNode(
         KEYWORD_ELSE("else"),
         StatementsNode(
           [CallNode(nil, nil, IDENTIFIER("c"), nil, nil, nil, nil, "c")]
         ),
         SEMICOLON(";")
       ),
       EnsureNode(
         KEYWORD_ENSURE("ensure"),
         StatementsNode(
           [CallNode(nil, nil, IDENTIFIER("d"), nil, nil, nil, nil, "d")]
         ),
         KEYWORD_END("end")
       ),
       KEYWORD_END("end")
     ),
     BeginNode(
       KEYWORD_BEGIN("begin"),
       StatementsNode(
         [CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")]
       ),
       nil,
       nil,
       nil,
       KEYWORD_END("end")
     ),
     BeginNode(
       KEYWORD_BEGIN("begin"),
       StatementsNode(
         [CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")]
       ),
       nil,
       nil,
       nil,
       KEYWORD_END("end")
     ),
     BeginNode(
       KEYWORD_BEGIN("begin"),
       StatementsNode(
         [CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")]
       ),
       nil,
       nil,
       nil,
       KEYWORD_END("end")
     ),
     BeginNode(
       KEYWORD_BEGIN("begin"),
       StatementsNode(
         [CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")]
       ),
       nil,
       nil,
       nil,
       KEYWORD_END("end")
     ),
     BeginNode(
       KEYWORD_BEGIN("begin"),
       StatementsNode(
         [CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")]
       ),
       RescueNode(
         KEYWORD_RESCUE("rescue"),
         [],
         nil,
         nil,
         StatementsNode(
           [CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]
         ),
         RescueNode(
           KEYWORD_RESCUE("rescue"),
           [],
           nil,
           nil,
           StatementsNode(
             [CallNode(nil, nil, IDENTIFIER("c"), nil, nil, nil, nil, "c")]
           ),
           RescueNode(
             KEYWORD_RESCUE("rescue"),
             [],
             nil,
             nil,
             StatementsNode(
               [CallNode(nil, nil, IDENTIFIER("d"), nil, nil, nil, nil, "d")]
             ),
             nil
           )
         )
       ),
       nil,
       nil,
       KEYWORD_END("end")
     ),
     BeginNode(
       KEYWORD_BEGIN("begin"),
       StatementsNode(
         [CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")]
       ),
       RescueNode(
         KEYWORD_RESCUE("rescue"),
         [ConstantReadNode()],
         EQUAL_GREATER("=>"),
         LocalVariableWriteNode(IDENTIFIER("ex"), nil, nil, 0),
         StatementsNode(
           [CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]
         ),
         RescueNode(
           KEYWORD_RESCUE("rescue"),
           [ConstantReadNode(), ConstantReadNode()],
           EQUAL_GREATER("=>"),
           LocalVariableWriteNode(IDENTIFIER("ex"), nil, nil, 0),
           StatementsNode(
             [CallNode(nil, nil, IDENTIFIER("c"), nil, nil, nil, nil, "c")]
           ),
           nil
         )
       ),
       nil,
       nil,
       KEYWORD_END("end")
     ),
     BeginNode(
       KEYWORD_BEGIN("begin"),
       StatementsNode(
         [CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")]
       ),
       RescueNode(
         KEYWORD_RESCUE("rescue"),
         [ConstantReadNode()],
         EQUAL_GREATER("=>"),
         LocalVariableWriteNode(IDENTIFIER("ex"), nil, nil, 0),
         StatementsNode(
           [CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]
         ),
         nil
       ),
       nil,
       EnsureNode(
         KEYWORD_ENSURE("ensure"),
         StatementsNode(
           [CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]
         ),
         KEYWORD_END("end")
       ),
       KEYWORD_END("end")
     ),
     StringNode(
       STRING_BEGIN("%!"),
       STRING_CONTENT("abc"),
       STRING_END("!"),
       "abc"
     ),
     BeginNode(
       KEYWORD_BEGIN("begin"),
       StatementsNode(
         [CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")]
       ),
       RescueNode(
         KEYWORD_RESCUE("rescue"),
         [],
         nil,
         nil,
         StatementsNode(
           [CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]
         ),
         nil
       ),
       nil,
       nil,
       KEYWORD_END("end")
     ),
     BeginNode(
       KEYWORD_BEGIN("begin"),
       StatementsNode(
         [CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")]
       ),
       RescueNode(
         KEYWORD_RESCUE("rescue"),
         [],
         nil,
         nil,
         StatementsNode(
           [CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]
         ),
         nil
       ),
       nil,
       nil,
       KEYWORD_END("end")
     ),
     BeginNode(
       KEYWORD_BEGIN("begin"),
       StatementsNode(
         [CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")]
       ),
       RescueNode(
         KEYWORD_RESCUE("rescue"),
         [],
         nil,
         nil,
         StatementsNode(
           [CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]
         ),
         nil
       ),
       nil,
       nil,
       KEYWORD_END("end")
     ),
     BeginNode(
       KEYWORD_BEGIN("begin"),
       StatementsNode(
         [CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")]
       ),
       RescueNode(
         KEYWORD_RESCUE("rescue"),
         [ConstantReadNode()],
         nil,
         nil,
         StatementsNode(
           [CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]
         ),
         nil
       ),
       nil,
       nil,
       KEYWORD_END("end")
     ),
     BeginNode(
       KEYWORD_BEGIN("begin"),
       StatementsNode(
         [CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")]
       ),
       RescueNode(
         KEYWORD_RESCUE("rescue"),
         [ConstantReadNode(), ConstantReadNode()],
         nil,
         nil,
         StatementsNode(
           [CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]
         ),
         nil
       ),
       nil,
       nil,
       KEYWORD_END("end")
     ),
     BeginNode(
       KEYWORD_BEGIN("begin"),
       StatementsNode(
         [CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")]
       ),
       RescueNode(
         KEYWORD_RESCUE("rescue"),
         [ConstantReadNode(), ConstantReadNode()],
         EQUAL_GREATER("=>"),
         LocalVariableWriteNode(IDENTIFIER("ex"), nil, nil, 0),
         StatementsNode(
           [CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]
         ),
         nil
       ),
       nil,
       nil,
       KEYWORD_END("end")
     ),
     BeginNode(
       KEYWORD_BEGIN("begin"),
       StatementsNode(
         [CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")]
       ),
       RescueNode(
         KEYWORD_RESCUE("rescue"),
         [ConstantReadNode()],
         EQUAL_GREATER("=>"),
         LocalVariableWriteNode(IDENTIFIER("ex"), nil, nil, 0),
         StatementsNode(
           [CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]
         ),
         nil
       ),
       nil,
       nil,
       KEYWORD_END("end")
     )]
  )
)
