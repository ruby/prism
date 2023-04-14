ProgramNode(3...151)(
  ScopeNode(0...0)([IDENTIFIER(3...12)("modelCode")]),
  StatementsNode(3...151)(
    [LocalVariableWriteNode(3...151)(
       (3...12),
       InterpolatedStringNode(31...151)(
         HEREDOC_START(15...29)("<<ENDModelCode"),
         [StringNode(31...42)(
            nil,
            STRING_CONTENT(31...42)("   \r\n" + "class "),
            nil,
            "   \r\n" + "class "
          ),
          StringInterpolatedNode(42...60)(
            EMBEXPR_BEGIN(42...44)("\#{"),
            StatementsNode(44...59)([InstanceVariableReadNode(44...59)()]),
            EMBEXPR_END(59...60)("}")
          ),
          StringNode(60...151)(
            nil,
            STRING_CONTENT(60...151)(
              " < ActiveRecord::Base\r\n" +
              "  def self.listAll\r\n" +
              "      find_by_sql(\"{'0'.CT.''}\")\r\n" +
              "  end\r\n" +
              "end\r\n" +
              "\r\n"
            ),
            nil,
            " < ActiveRecord::Base\r\n" +
            "  def self.listAll\r\n" +
            "      find_by_sql(\"{'0'.CT.''}\")\r\n" +
            "  end\r\n" +
            "end\r\n" +
            "\r\n"
          )],
         HEREDOC_END(151...165)("ENDModelCode\r\n")
       ),
       (13...14),
       0
     )]
  )
)
