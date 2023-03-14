UntilNode(
  KEYWORD_UNTIL("until"),
  TrueNode(),
  StatementsNode([ReturnNode(KEYWORD_RETURN("return"), nil)])
)
