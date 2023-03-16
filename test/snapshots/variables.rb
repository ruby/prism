ProgramNode(
  Scope(
    [IDENTIFIER("abc"),
     IDENTIFIER("foo"),
     IDENTIFIER("bar"),
     IDENTIFIER("baz")]
  ),
  StatementsNode(
    [ClassVariableReadNode(),
     ClassVariableWriteNode((7..12), IntegerNode(), (13..14)),
     MultiWriteNode(
       [ClassVariableWriteNode((18..23), nil, nil),
        ClassVariableWriteNode((25..30), nil, nil)],
       EQUAL("="),
       IntegerNode(),
       nil,
       nil
     ),
     ClassVariableWriteNode(
       (36..41),
       ArrayNode([IntegerNode(), IntegerNode()], nil, nil),
       (42..43)
     ),
     GlobalVariableWriteNode(
       GLOBAL_VARIABLE("$abc"),
       EQUAL("="),
       IntegerNode()
     ),
     GlobalVariableReadNode(GLOBAL_VARIABLE("$abc")),
     InstanceVariableReadNode(),
     InstanceVariableWriteNode((72..76), IntegerNode(), (77..78)),
     CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a"),
     LocalVariableWriteNode(IDENTIFIER("abc"), EQUAL("="), IntegerNode()),
     MultiWriteNode(
       [GlobalVariableWriteNode(GLOBAL_VARIABLE("$foo"), nil, nil),
        GlobalVariableWriteNode(GLOBAL_VARIABLE("$bar"), nil, nil)],
       EQUAL("="),
       IntegerNode(),
       nil,
       nil
     ),
     GlobalVariableWriteNode(
       GLOBAL_VARIABLE("$foo"),
       EQUAL("="),
       ArrayNode([IntegerNode(), IntegerNode()], nil, nil)
     ),
     MultiWriteNode(
       [InstanceVariableWriteNode((123..127), nil, nil),
        InstanceVariableWriteNode((129..133), nil, nil)],
       EQUAL("="),
       IntegerNode(),
       nil,
       nil
     ),
     InstanceVariableWriteNode(
       (139..143),
       ArrayNode([IntegerNode(), IntegerNode()], nil, nil),
       (144..145)
     ),
     LocalVariableWriteNode(IDENTIFIER("foo"), EQUAL("="), IntegerNode()),
     LocalVariableWriteNode(
       IDENTIFIER("foo"),
       EQUAL("="),
       ArrayNode([IntegerNode(), IntegerNode()], nil, nil)
     ),
     LocalVariableWriteNode(
       IDENTIFIER("foo"),
       EQUAL("="),
       ArrayNode([IntegerNode(), IntegerNode()], nil, nil)
     ),
     MultiWriteNode(
       [LocalVariableWriteNode(IDENTIFIER("foo"), nil, nil),
        SplatNode(USTAR("*"), nil)],
       EQUAL("="),
       ArrayNode([IntegerNode(), IntegerNode()], nil, nil),
       nil,
       nil
     ),
     MultiWriteNode(
       [LocalVariableWriteNode(IDENTIFIER("foo"), nil, nil),
        SplatNode(COMMA(","), nil)],
       EQUAL("="),
       ArrayNode([IntegerNode(), IntegerNode()], nil, nil),
       nil,
       nil
     ),
     MultiWriteNode(
       [LocalVariableWriteNode(IDENTIFIER("foo"), nil, nil),
        SplatNode(
          USTAR("*"),
          LocalVariableWriteNode(IDENTIFIER("bar"), nil, nil)
        )],
       EQUAL("="),
       ArrayNode([IntegerNode(), IntegerNode()], nil, nil),
       nil,
       nil
     ),
     MultiWriteNode(
       [LocalVariableWriteNode(IDENTIFIER("foo"), nil, nil),
        MultiWriteNode(
          [LocalVariableWriteNode(IDENTIFIER("bar"), nil, nil),
           LocalVariableWriteNode(IDENTIFIER("baz"), nil, nil)],
          nil,
          nil,
          (236..237),
          (245..246)
        )],
       EQUAL("="),
       ArrayNode(
         [IntegerNode(),
          ArrayNode(
            [IntegerNode(), IntegerNode()],
            BRACKET_LEFT_ARRAY("["),
            BRACKET_RIGHT("]")
          )],
         nil,
         nil
       ),
       nil,
       nil
     ),
     LocalVariableWriteNode(
       IDENTIFIER("foo"),
       EQUAL("="),
       SplatNode(USTAR("*"), LocalVariableReadNode(IDENTIFIER("bar")))
     ),
     ConstantPathWriteNode(
       ConstantReadNode(),
       EQUAL("="),
       ArrayNode([IntegerNode(), IntegerNode()], nil, nil)
     ),
     ParenthesesNode(
       StatementsNode(
         [CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a"),
          CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b"),
          CallNode(nil, nil, IDENTIFIER("c"), nil, nil, nil, nil, "c")]
       ),
       (284..285),
       (292..293)
     )]
  )
)
