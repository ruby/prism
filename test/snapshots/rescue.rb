ProgramNode(
  Scope([]),
  StatementsNode(
    [RescueModifierNode(
       CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
       KEYWORD_RESCUE_MODIFIER("rescue"),
       NilNode()
     ),
     RescueModifierNode(
       CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
       KEYWORD_RESCUE_MODIFIER("rescue"),
       NilNode()
     ),
     RescueModifierNode(
       BreakNode(nil, (32..37)),
       KEYWORD_RESCUE_MODIFIER("rescue"),
       NilNode()
     ),
     RescueModifierNode(
       NextNode(nil, (50..54)),
       KEYWORD_RESCUE_MODIFIER("rescue"),
       NilNode()
     ),
     RescueModifierNode(
       ReturnNode(KEYWORD_RETURN("return"), nil),
       KEYWORD_RESCUE_MODIFIER("rescue"),
       NilNode()
     ),
     RescueModifierNode(
       CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
       KEYWORD_RESCUE_MODIFIER("rescue"),
       OrNode(NilNode(), IntegerNode(), (101..103))
     ),
     RescueModifierNode(
       CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
       KEYWORD_RESCUE_MODIFIER("rescue"),
       TernaryNode(
         NilNode(),
         QUESTION_MARK("?"),
         IntegerNode(),
         COLON(":"),
         IntegerNode()
       )
     ),
     BeginNode(
       KEYWORD_BEGIN("begin"),
       StatementsNode(
         [CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")]
       ),
       RescueNode(
         KEYWORD_RESCUE("rescue"),
         [SplatNode(
            STAR("*"),
            CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")
          )],
         nil,
         nil,
         StatementsNode([]),
         nil
       ),
       nil,
       nil,
       KEYWORD_END("end")
     )]
  )
)
