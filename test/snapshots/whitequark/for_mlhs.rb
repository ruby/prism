ProgramNode(0...28)(
  [:a, :b],
  StatementsNode(0...28)(
    [ForNode(0...28)(
       MultiWriteNode(4...8)(
         [LocalVariableWriteNode(4...5)(:a, 0, nil, (4...5), nil),
          LocalVariableWriteNode(7...8)(:b, 0, nil, (7...8), nil)],
         nil,
         nil,
         nil,
         nil
       ),
       CallNode(12...15)(
         nil,
         nil,
         IDENTIFIER(12...15)("foo"),
         nil,
         nil,
         nil,
         nil,
         "foo"
       ),
       StatementsNode(17...23)(
         [CallNode(17...23)(
            nil,
            nil,
            IDENTIFIER(17...18)("p"),
            nil,
            ArgumentsNode(19...23)(
              [LocalVariableReadNode(19...20)(:a, 0),
               LocalVariableReadNode(22...23)(:b, 0)]
            ),
            nil,
            nil,
            "p"
          )]
       ),
       (0...3),
       (9...11),
       nil,
       (25...28)
     )]
  )
)
