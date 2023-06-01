ProgramNode(0...47)(
  [],
  StatementsNode(0...47)(
    [InterpolatedStringNode(0...47)(
       (0...7),
       [StringNode(8...12)(nil, STRING_CONTENT(8...12)("pre\n"), nil, "pre\n"),
        StringInterpolatedNode(12...36)(
          EMBEXPR_BEGIN(12...14)("\#{"),
          StatementsNode(15...35)(
            [InterpolatedStringNode(15...35)(
               (15...21),
               [StringNode(22...30)(
                  nil,
                  STRING_CONTENT(22...30)("  hello\n"),
                  nil,
                  "  hello\n"
                )],
               (30...35)
             )]
          ),
          EMBEXPR_END(35...36)("}")
        ),
        StringNode(36...42)(
          nil,
          STRING_CONTENT(36...42)("\n" + "post\n"),
          nil,
          "\n" + "post\n"
        )],
       (42...47)
     )]
  )
)
