ProgramNode(0...0)(
  ScopeNode(0...0)([IDENTIFIER(0...1)("a")]),
  StatementsNode(0...0)(
    [MultiWriteNode(0...0)(
       [LocalVariableWriteNode(0...1)((0...1), nil, nil, 0),
        ConstantPathWriteNode(3...7)(
          ConstantPathNode(3...7)(
            CallNode(3...4)(
              nil,
              nil,
              IDENTIFIER(3...4)("b"),
              nil,
              nil,
              nil,
              nil,
              "b"
            ),
            ConstantReadNode(6...7)(),
            (4...6)
          ),
          nil,
          nil
        )],
       EQUAL(8...9)("="),
       ArrayNode(0...0)(
         [IntegerNode(10...11)((10...11), 10),
          IntegerNode(13...14)((13...14), 10)],
         nil,
         nil
       ),
       nil,
       nil
     )]
  )
)
