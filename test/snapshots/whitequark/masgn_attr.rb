ProgramNode(0...63)(
  [:foo],
  StatementsNode(0...63)(
    [MultiWriteNode(0...17)(
       [CallNode(0...6)(
          SelfNode(0...4)(),
          DOT(4...5)("."),
          CONSTANT(5...6)("A"),
          nil,
          nil,
          nil,
          nil,
          "A="
        ),
        LocalVariableWriteNode(8...11)(:foo, 0, nil, (8...11), nil)],
       (12...13),
       LocalVariableReadNode(14...17)(:foo, 0),
       nil,
       nil
     ),
     MultiWriteNode(19...43)(
       [CallNode(19...25)(
          SelfNode(19...23)(),
          DOT(23...24)("."),
          IDENTIFIER(24...25)("a"),
          nil,
          nil,
          nil,
          nil,
          "a="
        ),
        CallNode(27...37)(
          SelfNode(27...31)(),
          nil,
          BRACKET_LEFT_RIGHT_EQUAL(31...32)("["),
          BRACKET_LEFT(31...32)("["),
          ArgumentsNode(32...36)(
            [IntegerNode(32...33)(), IntegerNode(35...36)()]
          ),
          BRACKET_RIGHT(36...37)("]"),
          nil,
          "[]="
        )],
       (38...39),
       LocalVariableReadNode(40...43)(:foo, 0),
       nil,
       nil
     ),
     MultiWriteNode(45...63)(
       [CallNode(45...52)(
          SelfNode(45...49)(),
          COLON_COLON(49...51)("::"),
          IDENTIFIER(51...52)("a"),
          nil,
          nil,
          nil,
          nil,
          "a="
        ),
        LocalVariableWriteNode(54...57)(:foo, 0, nil, (54...57), nil)],
       (58...59),
       LocalVariableReadNode(60...63)(:foo, 0),
       nil,
       nil
     )]
  )
)
