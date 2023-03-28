ProgramNode(0...41)(
  ScopeNode(0...0)([IDENTIFIER(0...1)("c"), IDENTIFIER(35...36)("d")]),
  StatementsNode(0...41)(
    [LocalVariableWriteNode(0...30)(
       IDENTIFIER(0...1)("c"),
       EQUAL(2...3)("="),
       HeredocNode(12...30)(
         HEREDOC_START(4...11)("<<'CCC'"),
         [StringNode(12...30)(
            nil,
            STRING_CONTENT(12...30)("line2\n" + "line3\n" + "line4\n"),
            nil,
            "line2\n" + "line3\n" + "line4\n"
          )],
         HEREDOC_END(30...34)("CCC\n"),
         0
       )
     ),
     LocalVariableWriteNode(35...41)(
       IDENTIFIER(35...36)("d"),
       EQUAL(37...38)("="),
       IntegerNode(39...41)()
     )]
  )
)
