ProgramNode(0...19)(
  ScopeNode(0...0)([]),
  StatementsNode(0...19)(
    [IfNode(0...19)(
       KEYWORD_IF(0...2)("if"),
       CallNode(3...6)(
         nil,
         nil,
         IDENTIFIER(3...6)("foo"),
         nil,
         nil,
         nil,
         nil,
         "foo"
       ),
       StatementsNode(12...15)(
         [CallNode(12...15)(
            nil,
            nil,
            IDENTIFIER(12...15)("bar"),
            nil,
            nil,
            nil,
            nil,
            "bar"
          )]
       ),
       nil,
       KEYWORD_END(16...19)("end")
     )]
  )
)
