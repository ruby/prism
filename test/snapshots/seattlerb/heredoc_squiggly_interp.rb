ProgramNode(0...36)(
  ScopeNode(0...0)([IDENTIFIER(0...1)("a")]),
  StatementsNode(0...36)(
    [LocalVariableWriteNode(0...36)(
       (0...1),
       InterpolatedStringNode(11...36)(
         HEREDOC_START(4...10)("<<~EOF"),
         [StringNode(11...22)(
            nil,
            STRING_CONTENT(11...22)("      w\n" + "  x"),
            nil,
            "    w\n" + "x"
          ),
          StringInterpolatedNode(22...27)(
            EMBEXPR_BEGIN(22...24)("\#{"),
            StatementsNode(24...26)([IntegerNode(24...26)()]),
            EMBEXPR_END(26...27)("}")
          ),
          StringNode(27...36)(
            nil,
            STRING_CONTENT(27...36)(" y\n" + "    z\n"),
            nil,
            " y\n" + "  z\n"
          )],
         HEREDOC_END(36...42)("  EOF\n")
       ),
       (2...3),
       0
     )]
  )
)
