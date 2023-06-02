ProgramNode(0...28)(
  [],
  StatementsNode(0...28)(
    [DefNode(0...28)(
       (4...5),
       nil,
       ParametersNode(6...16)(
         [],
         [],
         [],
         nil,
         [KeywordParameterNode(6...12)((6...8), NilNode(9...12)())],
         KeywordRestParameterNode(14...16)((14...16), nil),
         nil
       ),
       StatementsNode(19...24)(
         [CallNode(19...24)(
            nil,
            nil,
            IDENTIFIER(19...20)("b"),
            PARENTHESIS_LEFT(20...21)("("),
            ArgumentsNode(21...23)(
              [KeywordHashNode(21...23)(
                 [AssocSplatNode(21...23)(nil, (21...23))]
               )]
            ),
            PARENTHESIS_RIGHT(23...24)(")"),
            nil,
            "b"
          )]
       ),
       [LABEL(6...7)("a"), USTAR_STAR(14...16)("**")],
       (0...3),
       nil,
       (5...6),
       (16...17),
       nil,
       (25...28)
     )]
  )
)
