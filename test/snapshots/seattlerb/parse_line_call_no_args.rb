ProgramNode(0...23)(
  [],
  StatementsNode(0...23)(
    [CallNode(0...23)(
       nil,
       nil,
       IDENTIFIER(0...1)("f"),
       nil,
       nil,
       nil,
       BlockNode(2...23)(
         [:x, :y],
         BlockParametersNode(5...11)(
           ParametersNode(6...10)(
             [RequiredParameterNode(6...7)(:x),
              RequiredParameterNode(9...10)(:y)],
             [],
             [],
             nil,
             [],
             nil,
             nil
           ),
           [],
           (5...6),
           (10...11)
         ),
         StatementsNode(14...19)(
           [CallNode(14...19)(
              LocalVariableReadNode(14...15)(:x, 0),
              nil,
              PLUS(16...17)("+"),
              nil,
              ArgumentsNode(18...19)([LocalVariableReadNode(18...19)(:y, 0)]),
              nil,
              nil,
              "+"
            )]
         ),
         (2...4),
         (20...23)
       ),
       "f"
     )]
  )
)
