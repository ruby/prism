ProgramNode(0...1)(
  ScopeNode(0...0)([]),
  StatementsNode(0...1)(
    [CallNode(0...1)(
       nil,
       nil,
       IDENTIFIER(0...1)("p"),
       nil,
       ArgumentsNode(9...19)(
         [HeredocNode(9...19)(
            HEREDOC_START(2...8)("<<~\"E\""),
            [StringNode(9...19)(
               nil,
               STRING_CONTENT(9...19)("  x\\n   y\n"),
               nil,
               "x\n" + " y\n"
             )],
            HEREDOC_END(19...21)("E\n"),
            2
          )]
       ),
       nil,
       nil,
       "p"
     )]
  )
)
