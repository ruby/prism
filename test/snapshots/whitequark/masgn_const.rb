ProgramNode(0...34)(
  ScopeNode(0...0)([IDENTIFIER(5...8)("foo")]),
  StatementsNode(0...34)(
    [MultiWriteNode(0...14)(
       [ConstantPathWriteNode(0...3)(
          ConstantPathNode(0...3)(nil, ConstantReadNode(2...3)(), (0...2)),
          nil,
          nil
        ),
        LocalVariableWriteNode(5...8)(IDENTIFIER(5...8)("foo"), nil, nil)],
       EQUAL(9...10)("="),
       LocalVariableReadNode(11...14)(IDENTIFIER(11...14)("foo")),
       nil,
       nil
     ),
     MultiWriteNode(16...34)(
       [ConstantPathWriteNode(16...23)(
          ConstantPathNode(16...23)(
            SelfNode(16...20)(),
            ConstantReadNode(22...23)(),
            (20...22)
          ),
          nil,
          nil
        ),
        LocalVariableWriteNode(25...28)(IDENTIFIER(25...28)("foo"), nil, nil)],
       EQUAL(29...30)("="),
       LocalVariableReadNode(31...34)(IDENTIFIER(31...34)("foo")),
       nil,
       nil
     )]
  )
)
