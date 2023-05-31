ProgramNode(0...47)(
  [],
  StatementsNode(0...47)(
    [ArrayNode(0...17)(
       [StringNode(1...15)(
          STRING_BEGIN(1...2)("\""),
          STRING_CONTENT(2...14)("  some text\n"),
          STRING_END(14...15)("\""),
          "  some text\n"
        )],
       (0...1),
       (16...17)
     ),
     ArrayNode(19...47)(
       [InterpolatedStringNode(20...46)(
          HEREDOC_START(20...27)("<<-FILE"),
          [StringNode(29...41)(
             nil,
             STRING_CONTENT(29...41)("  some text\n"),
             nil,
             "  some text\n"
           )],
          HEREDOC_END(41...46)("FILE\n")
        )],
       (19...20),
       (46...47)
     )]
  )
)
