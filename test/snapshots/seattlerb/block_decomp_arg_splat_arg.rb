ProgramNode(0...18)(
  [],
  StatementsNode(0...18)(
    [CallNode(0...18)(
       nil,
       nil,
       IDENTIFIER(0...1)("f"),
       nil,
       nil,
       nil,
       BlockNode(2...18)(
         [:a, :b, :c],
         BlockParametersNode(4...16)(
           ParametersNode(5...15)(
             [RequiredDestructuredParameterNode(5...15)(
                [RequiredParameterNode(6...7)(:a),
                 SplatNode(9...11)(
                   (9...10),
                   RequiredParameterNode(10...11)(:b)
                 ),
                 RequiredParameterNode(13...14)(:c)],
                (5...6),
                (14...15)
              )],
             [],
             [],
             nil,
             [],
             nil,
             nil
           ),
           [],
           (4...5),
           (15...16)
         ),
         nil,
         (2...3),
         (17...18)
       ),
       "f"
     )]
  )
)
