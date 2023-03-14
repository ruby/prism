LambdaNode(
  Scope([]),
  nil,
  BlockParametersNode(ParametersNode([], [], nil, [], nil, nil), []),
  nil,
  BeginNode(
    nil,
    StatementsNode([]),
    RescueNode(
      KEYWORD_RESCUE("rescue"),
      [],
      nil,
      nil,
      StatementsNode([]),
      nil
    ),
    ElseNode(KEYWORD_ELSE("else"), StatementsNode([]), KEYWORD_ELSE("else")),
    EnsureNode(
      KEYWORD_ENSURE("ensure"),
      StatementsNode([]),
      KEYWORD_END("end")
    ),
    KEYWORD_END("end")
  )
)
