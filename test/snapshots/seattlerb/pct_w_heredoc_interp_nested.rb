ProgramNode(0...26)(
  ScopeNode(0...0)([]),
  StatementsNode(0...26)(
    [ArrayNode(0...30)(
       [StringNode(4...5)(nil, STRING_CONTENT(4...5)("1"), nil, "1"),
        InterpolatedStringNode(6...12)(
          nil,
          [StringInterpolatedNode(6...12)(
             EMBEXPR_BEGIN(6...8)("\#{"),
             StatementsNode(15...17)(
               [HeredocNode(15...17)(
                  HEREDOC_START(8...11)("<<A"),
                  [StringNode(15...17)(
                     nil,
                     STRING_CONTENT(15...17)("2\n"),
                     nil,
                     "2\n"
                   )],
                  HEREDOC_END(17...19)("A\n"),
                  0
                )]
             ),
             EMBEXPR_END(11...12)("}")
           )],
          nil
        ),
        StringNode(13...14)(nil, STRING_CONTENT(13...14)("3"), nil, "3"),
        StringNode(15...16)(nil, STRING_CONTENT(15...16)("2"), nil, "2"),
        StringNode(17...18)(nil, STRING_CONTENT(17...18)("A"), nil, "A"),
        StringNode(25...26)(nil, STRING_CONTENT(25...26)("4"), nil, "4"),
        StringNode(27...28)(nil, STRING_CONTENT(27...28)("5"), nil, "5")],
       PERCENT_UPPER_W(0...3)("%W("),
       STRING_END(29...30)(")")
     ),
     IntegerNode(25...26)()]
  )
)
