ProgramNode(0...27)(
  [IDENTIFIER(0...1)("s")],
  StatementsNode(0...27)(
    [LocalVariableWriteNode(0...27)(
       (0...1),
       InterpolatedStringNode(4...27)(
         (4...10),
         [StringNode(11...23)(
            nil,
            STRING_CONTENT(11...23)("a\\247b\n" + "cöd\n"),
            nil,
            "a\xA7b\n" + "cöd\n"
          )],
         (23...27)
       ),
       (2...3),
       0
     )]
  )
)
