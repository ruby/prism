CallNode(
  ConstantPathNode(ConstantReadNode(), COLON_COLON("::"), ConstantReadNode()),
  COLON_COLON("::"),
  CONSTANT("C"),
  PARENTHESIS_LEFT("("),
  ArgumentsNode(
    [SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("foo"), nil, "foo")]
  ),
  PARENTHESIS_RIGHT(")"),
  nil,
  "C"
)
