RescueModifierNode(
  CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
  KEYWORD_RESCUE("rescue"),
  TernaryNode(
    NilNode(),
    QUESTION_MARK("?"),
    IntegerNode(),
    COLON(":"),
    IntegerNode()
  )
)
