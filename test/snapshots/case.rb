CaseNode(
  nil,
  [WhenNode(
     KEYWORD_WHEN("when"),
     [CallNode(
        CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
        nil,
        EQUAL_EQUAL("=="),
        nil,
        ArgumentsNode(
          [CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar")]
        ),
        nil,
        nil,
        "=="
      )],
     nil
   )],
  nil,
  (174..178),
  (195..198)
)
