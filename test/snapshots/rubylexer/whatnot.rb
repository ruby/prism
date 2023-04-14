ProgramNode(0...216)(
  ScopeNode(0...0)([IDENTIFIER(0...3)("aaa")]),
  StatementsNode(0...216)(
    [LocalVariableWriteNode(0...204)(
       (0...3),
       InterpolatedStringNode(30...204)(
         HEREDOC_START(4...13)("<<whatnot"),
         [StringNode(30...204)(
            nil,
            STRING_CONTENT(30...204)(
              "gonna take it down, to the nitty-grit\n" +
              "gonna tell you mother-fuckers why you ain't shit\n" +
              "cause suckers like you just make me strong\n" +
              "you been pumpin' that bullshit all day long\n"
            ),
            nil,
            "gonna take it down, to the nitty-grit\n" +
            "gonna tell you mother-fuckers why you ain't shit\n" +
            "cause suckers like you just make me strong\n" +
            "you been pumpin' that bullshit all day long\n"
          )],
         HEREDOC_END(204...212)("whatnot\n")
       ),
       (3...4),
       0
     ),
     CallNode(15...16)(
       nil,
       nil,
       IDENTIFIER(15...16)("p"),
       nil,
       ArgumentsNode(17...214)(
         [InterpolatedStringNode(17...214)(
            STRING_BEGIN(17...18)("\""),
            [StringInterpolatedNode(18...213)(
               EMBEXPR_BEGIN(18...20)("\#{"),
               StatementsNode(20...29)(
                 [StringNode(20...29)(
                    STRING_BEGIN(20...21)("'"),
                    STRING_CONTENT(21...28)("uh,yeah"),
                    STRING_END(28...29)("'"),
                    "uh,yeah"
                  )]
               ),
               EMBEXPR_END(212...213)("}")
             )],
            STRING_END(213...214)("\"")
          )]
       ),
       nil,
       nil,
       "p"
     ),
     CallNode(215...216)(
       nil,
       nil,
       IDENTIFIER(215...216)("p"),
       nil,
       ArgumentsNode(217...220)([LocalVariableReadNode(217...220)(0)]),
       nil,
       nil,
       "p"
     )]
  )
)
