ProgramNode(0...27)(
  [],
  StatementsNode(0...27)(
    [ReturnNode(0...27)(
       (0...6),
       ArgumentsNode(7...27)(
         [CallNode(7...27)(
            nil,
            nil,
            IDENTIFIER(7...10)("foo"),
            nil,
            ArgumentsNode(11...14)(
              [CallNode(11...14)(
                 nil,
                 nil,
                 IDENTIFIER(11...14)("arg"),
                 nil,
                 nil,
                 nil,
                 nil,
                 "arg"
               )]
            ),
            nil,
            BlockNode(15...27)(
              [:bar],
              BlockParametersNode(18...23)(
                ParametersNode(19...22)(
                  [RequiredParameterNode(19...22)(:bar)],
                  [],
                  [],
                  nil,
                  [],
                  nil,
                  nil
                ),
                [],
                (18...19),
                (22...23)
              ),
              nil,
              (15...17),
              (24...27)
            ),
            "foo"
          )]
       )
     )]
  )
)
