ProgramNode(16...55)(
  ScopeNode(0...0)([]),
  StatementsNode(16...55)(
    [InterpolatedStringNode(16...55)(
       HEREDOC_START(0...14)("<<ENDModelCode"),
       [StringNode(16...27)(
          nil,
          STRING_CONTENT(16...27)("   \r\n" + "class "),
          nil,
          "   \r\n" + "class "
        ),
        StringInterpolatedNode(27...45)(
          EMBEXPR_BEGIN(27...29)("\#{"),
          StatementsNode(29...44)([InstanceVariableReadNode(29...44)()]),
          EMBEXPR_END(44...45)("}")
        ),
        StringNode(45...55)(
          nil,
          STRING_CONTENT(45...55)(" \r\n" + "end\r\n" + "\r\n"),
          nil,
          " \r\n" + "end\r\n" + "\r\n"
        )],
       HEREDOC_END(55...69)("ENDModelCode\r\n")
     )]
  )
)
