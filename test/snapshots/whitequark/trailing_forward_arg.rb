ProgramNode(0...40)(
  ScopeNode(0...0)([]),
  StatementsNode(0...40)(
    [DefNode(0...40)(
       IDENTIFIER(4...7)("foo"),
       nil,
       ParametersNode(8...17)(
         [RequiredParameterNode(8...9)(), RequiredParameterNode(11...12)()],
         [],
         nil,
         [],
         ForwardingParameterNode(14...17)(),
         nil
       ),
       StatementsNode(20...35)(
         [CallNode(20...35)(
            nil,
            nil,
            IDENTIFIER(20...23)("bar"),
            PARENTHESIS_LEFT(23...24)("("),
            ArgumentsNode(24...34)(
              [LocalVariableReadNode(24...25)(1),
               IntegerNode(27...29)(),
               ForwardingArgumentsNode(31...34)()]
            ),
            PARENTHESIS_RIGHT(34...35)(")"),
            nil,
            "bar"
          )]
       ),
       ScopeNode(0...3)(
         [IDENTIFIER(8...9)("a"),
          IDENTIFIER(11...12)("b"),
          UDOT_DOT_DOT(14...17)("...")]
       ),
       (0...3),
       nil,
       (7...8),
       (17...18),
       nil,
       (37...40)
     )]
  )
)
