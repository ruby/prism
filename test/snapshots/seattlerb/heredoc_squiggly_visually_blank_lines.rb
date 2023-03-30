ProgramNode(0...21)(
  ScopeNode(0...0)([IDENTIFIER(0...1)("a")]),
  StatementsNode(0...21)(
    [LocalVariableWriteNode(0...21)(
       (0...1),
       InterpolatedStringNode(11...21)(
         HEREDOC_START(4...10)("<<~EOF"),
         [StringNode(11...21)(
            nil,
            STRING_CONTENT(11...21)("  x\n" + " \n" + "  z\n"),
            nil,
            "x\n" + "\n" + "z\n"
          )],
         HEREDOC_END(21...25)("EOF\n")
       ),
       (2...3),
       0
     )]
  )
)
