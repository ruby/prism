ProgramNode(0...21)(
  ScopeNode(0...0)([]),
  StatementsNode(0...21)(
    [CallNode(0...6)(
       RegularExpressionNode(1...6)(
         REGEXP_BEGIN(1...2)("/"),
         STRING_CONTENT(2...5)("wat"),
         REGEXP_END(5...6)("/"),
         "wat"
       ),
       nil,
       BANG(0...1)("!"),
       nil,
       nil,
       nil,
       nil,
       "!"
     ),
     IfNode(8...21)(
       KEYWORD_IF(8...10)("if"),
       RegularExpressionNode(11...16)(
         REGEXP_BEGIN(11...12)("/"),
         STRING_CONTENT(12...15)("wat"),
         REGEXP_END(15...16)("/"),
         "wat"
       ),
       nil,
       nil,
       KEYWORD_END(18...21)("end")
     )]
  )
)
