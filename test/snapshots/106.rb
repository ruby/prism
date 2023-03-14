CallNode(
  nil,
  nil,
  IDENTIFIER("foo"),
  nil,
  ArgumentsNode(
    [CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar"),
     ParenthesesNode(
       StatementsNode(
         [CallNode(
            nil,
            nil,
            IDENTIFIER("baz"),
            nil,
            nil,
            nil,
            BlockNode(nil, nil, (14..16), (17..20)),
            "baz"
          )]
       ),
       (9..10),
       (20..21)
     )]
  ),
  nil,
  nil,
  "foo"
)
