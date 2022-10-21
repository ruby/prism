# frozen_string_literal: true

require "test_helper"

class ParseTest < Test::Unit::TestCase
  include YARP::DSL

  test "and keyword" do
    assert_parses AndNode(expression("1"), KEYWORD_AND("and"), expression("2")), "1 and 2"
  end

  test "and operator" do
    assert_parses AndNode(expression("1"), AMPERSAND_AMPERSAND("&&"), expression("2")), "1 && 2"
  end

  test "binary !=" do
    assert_parses CallNode(expression("1"), nil, BANG_EQUAL("!="), ArgumentsNode([expression("2")]), "!="), "1 != 2"
  end

  test "binary !~" do
    assert_parses CallNode(expression("1"), nil, BANG_TILDE("!~"), ArgumentsNode([expression("2")]), "!~"), "1 !~ 2"
  end

  test "binary ==" do
    assert_parses CallNode(expression("1"), nil, EQUAL_EQUAL("=="), ArgumentsNode([expression("2")]), "=="), "1 == 2"
  end

  test "binary ===" do
    assert_parses CallNode(expression("1"), nil, EQUAL_EQUAL_EQUAL("==="), ArgumentsNode([expression("2")]), "==="), "1 === 2"
  end

  test "binary =~" do
    assert_parses CallNode(expression("1"), nil, EQUAL_TILDE("=~"), ArgumentsNode([expression("2")]), "=~"), "1 =~ 2"
  end

  test "binary <=>" do
    assert_parses CallNode(expression("1"), nil, LESS_EQUAL_GREATER("<=>"), ArgumentsNode([expression("2")]), "<=>"), "1 <=> 2"
  end

  test "binary >" do
    assert_parses CallNode(expression("1"), nil, GREATER(">"), ArgumentsNode([expression("2")]), ">"), "1 > 2"
  end

  test "binary >=" do
    assert_parses CallNode(expression("1"), nil, GREATER_EQUAL(">="), ArgumentsNode([expression("2")]), ">="), "1 >= 2"
  end

  test "binary <" do
    assert_parses CallNode(expression("1"), nil, LESS("<"), ArgumentsNode([expression("2")]), "<"), "1 < 2"
  end

  test "binary <=" do
    assert_parses CallNode(expression("1"), nil, LESS_EQUAL("<="), ArgumentsNode([expression("2")]), "<="), "1 <= 2"
  end

  test "binary ^" do
    assert_parses CallNode(expression("1"), nil, CARET("^"), ArgumentsNode([expression("2")]), "^"), "1 ^ 2"
  end

  test "binary |" do
    assert_parses CallNode(expression("1"), nil, PIPE("|"), ArgumentsNode([expression("2")]), "|"), "1 | 2"
  end

  test "binary &" do
    assert_parses CallNode(expression("1"), nil, AMPERSAND("&"), ArgumentsNode([expression("2")]), "&"), "1 & 2"
  end

  test "binary >>" do
    assert_parses CallNode(expression("1"), nil, GREATER_GREATER(">>"), ArgumentsNode([expression("2")]), ">>"), "1 >> 2"
  end

  test "binary <<" do
    assert_parses CallNode(expression("1"), nil, LESS_LESS("<<"), ArgumentsNode([expression("2")]), "<<"), "1 << 2"
  end

  test "binary -" do
    assert_parses CallNode(expression("1"), nil, MINUS("-"), ArgumentsNode([expression("2")]), "-"), "1 - 2"
  end

  test "binary +" do
    assert_parses CallNode(expression("1"), nil, PLUS("+"), ArgumentsNode([expression("2")]), "+"), "1 + 2"
  end

  test "binary %" do
    assert_parses CallNode(expression("1"), nil, PERCENT("%"), ArgumentsNode([expression("2")]), "%"), "1 % 2"
  end

  test "binary /" do
    assert_parses CallNode(expression("1"), nil, SLASH("/"), ArgumentsNode([expression("2")]), "/"), "1 / 2"
  end

  test "binary *" do
    assert_parses CallNode(expression("1"), nil, STAR("*"), ArgumentsNode([expression("2")]), "*"), "1 * 2"
  end

  test "binary **" do
    assert_parses CallNode(expression("1"), nil, STAR_STAR("**"), ArgumentsNode([expression("2")]), "**"), "1**2"
  end

  test "break" do
    assert_parses BreakNode(KEYWORD_BREAK("break"), nil, nil, nil), "break"
  end

  test "break()" do
    assert_parses BreakNode(KEYWORD_BREAK("break"), PARENTHESIS_LEFT("("), ArgumentsNode([]), PARENTHESIS_RIGHT(")")), "break()"
  end

  test "break(1)" do
    assert_parses BreakNode(KEYWORD_BREAK("break"), PARENTHESIS_LEFT("("), ArgumentsNode([expression("1")]), PARENTHESIS_RIGHT(")")), "break(1)"
  end

  test "break(1, 2, 3)" do
    assert_parses BreakNode(KEYWORD_BREAK("break"), PARENTHESIS_LEFT("("), ArgumentsNode([expression("1"), expression("2"), expression("3")]), PARENTHESIS_RIGHT(")")), "break(1, 2, 3)"
  end

  test "call with ? identifier" do
    assert_parses CallNode(nil, nil, IDENTIFIER("a?"), nil, "a?"), "a?"
  end

  test "call with ! identifier" do
    assert_parses CallNode(nil, nil, IDENTIFIER("a!"), nil, "a!"), "a!"
  end

  test "call with ::" do
    expected = CallNode(
      CallNode(nil, nil, IDENTIFIER("a"), nil, "a"),
      COLON_COLON("::"),
      IDENTIFIER("b"),
      nil,
      "b"
    )

    assert_parses expected, "a::b"
  end

  test "call with no parentheses or arguments" do
    expected = CallNode(
      CallNode(
        CallNode(nil, nil, IDENTIFIER("a"), nil, "a"),
        DOT("."),
        IDENTIFIER("b"),
        ArgumentsNode([]),
        "b"
      ),
      DOT("."),
      IDENTIFIER("c"),
      ArgumentsNode([]),
      "c"
    )

    assert_parses expected, "a.b.c"
  end

  test "character literal" do
    assert_parses StringNode(STRING_BEGIN("?"), STRING_CONTENT("a"), nil), "?a"
  end

  test "class" do
    expected = ClassNode(
      Scope([IDENTIFIER("a")]),
      KEYWORD_CLASS("class"),
      ConstantRead(CONSTANT("A")),
      nil,
      nil,
      Statements([
        LocalVariableWrite(
          IDENTIFIER("a"),
          EQUAL("="),
          IntegerLiteral(INTEGER("1"))
        )
      ]),
      KEYWORD_END("end")
    )

    assert_parses expected, "class A a = 1 end"
  end

  test "class with superclass" do
    expected = ClassNode(
      Scope([IDENTIFIER("a")]),
      KEYWORD_CLASS("class"),
      ConstantRead(CONSTANT("A")),
      LESS("<"),
      ConstantRead(CONSTANT("B")),
      Statements([
        LocalVariableWrite(
          IDENTIFIER("a"),
          EQUAL("="),
          IntegerLiteral(INTEGER("1"))
        )
      ]),
      KEYWORD_END("end")
    )

    assert_parses expected, "class A < B a = 1 end"
  end

  test "class variable read" do
    assert_parses ClassVariableRead(CLASS_VARIABLE("@@abc")), "@@abc"
  end

  test "class variable write" do
    assert_parses ClassVariableWrite(CLASS_VARIABLE("@@abc"), EQUAL("="), expression("1")), "@@abc = 1"
  end

  test "constant path" do
    assert_parses ConstantPathNode(ConstantRead(CONSTANT("A")), COLON_COLON("::"), ConstantRead(CONSTANT("B"))), "A::B"
  end

  test "constant path with multiple levels" do
    expected = ConstantPathNode(
      ConstantRead(CONSTANT("A")),
      COLON_COLON("::"),
      ConstantPathNode(
        ConstantRead(CONSTANT("B")),
        COLON_COLON("::"),
        ConstantRead(CONSTANT("C"))
      )
    )

    assert_parses expected, "A::B::C"
  end

  test "constant path with variable parent" do
    expected = ConstantPathNode(
      CallNode(nil, nil, IDENTIFIER("a"), nil, "a"),
      COLON_COLON("::"),
      ConstantRead(CONSTANT("B"))
    )

    assert_parses expected, "a::B"
  end

  test "constant read" do
    assert_parses ConstantRead(CONSTANT("ABC")), "ABC"
  end

  test "constant path write single" do
    assert_parses ConstantPathWriteNode(ConstantRead(CONSTANT("A")), EQUAL("="), expression("1")), "A = 1"
  end

  test "constant path write multiple" do
    expected = ConstantPathWriteNode(
      ConstantPathNode(ConstantRead(CONSTANT("A")), COLON_COLON("::"), ConstantRead(CONSTANT("B"))),
      EQUAL("="),
      expression("1")
    )

    assert_parses expected, "A::B = 1"
  end

  test "def without parentheses" do
    expected = DefNode(
      KEYWORD_DEF("def"),
      IDENTIFIER("a"),
      nil,
      ParametersNode([]),
      nil,
      Statements([]),
      KEYWORD_END("end"),
      Scope([])
    )

    assert_parses expected, "def a\nend"
  end

  test "def with parentheses" do
    expected = DefNode(
      KEYWORD_DEF("def"),
      IDENTIFIER("a"),
      PARENTHESIS_LEFT("("),
      ParametersNode([]),
      PARENTHESIS_RIGHT(")"),
      Statements([]),
      KEYWORD_END("end"),
      Scope([])
    )

    assert_parses expected, "def a()\nend"
  end

  test "def with scope" do
    expected = DefNode(
      KEYWORD_DEF("def"),
      IDENTIFIER("a"),
      nil,
      ParametersNode([]),
      nil,
      Statements([expression("b = 1")]),
      KEYWORD_END("end"),
      Scope([IDENTIFIER("b")])
    )

    assert_parses expected, "def a\nb = 1\nend"
  end

  test "def with required parameter" do
    expected = DefNode(
      KEYWORD_DEF("def"),
      IDENTIFIER("a"),
      nil,
      ParametersNode([RequiredParameterNode(IDENTIFIER("b"))]),
      nil,
      Statements([]),
      KEYWORD_END("end"),
      Scope([IDENTIFIER("b")])
    )

    assert_parses expected, "def a b\nend"
  end

  test "def with multiple required parameters" do
    expected = DefNode(
      KEYWORD_DEF("def"),
      IDENTIFIER("a"),
      nil,
      ParametersNode([
        RequiredParameterNode(IDENTIFIER("b")),
        RequiredParameterNode(IDENTIFIER("c")),
        RequiredParameterNode(IDENTIFIER("d"))
      ]),
      nil,
      Statements([]),
      KEYWORD_END("end"),
      Scope([IDENTIFIER("b"), IDENTIFIER("c"), IDENTIFIER("d")])
    )

    assert_parses expected, "def a b, c, d\nend"
  end

  test "defined? without parentheses" do
    assert_parses DefinedNode(KEYWORD_DEFINED("defined?"), nil, expression("1"), nil), "defined? 1"
  end

  test "defined? with parentheses" do
    assert_parses DefinedNode(KEYWORD_DEFINED("defined?"), PARENTHESIS_LEFT("("), expression("1"), PARENTHESIS_RIGHT(")")), "defined?(1)"
  end

  test "defined? binding power" do
    expected =
      AndNode(
        DefinedNode(KEYWORD_DEFINED("defined?"), nil, expression("1"), nil),
        KEYWORD_AND("and"),
        DefinedNode(KEYWORD_DEFINED("defined?"), nil, expression("2"), nil)
      )

    assert_parses expected, "defined? 1 and defined? 2"
  end

  test "false" do
    assert_parses FalseNode(KEYWORD_FALSE("false")), "false"
  end

  test "float" do
    assert_parses FloatLiteral(FLOAT("1.0")), "1.0"
  end

  test "global variable read" do
    assert_parses GlobalVariableRead(GLOBAL_VARIABLE("$abc")), "$abc"
  end

  test "global variable write" do
    assert_parses GlobalVariableWrite(GLOBAL_VARIABLE("$abc"), EQUAL("="), expression("1")), "$abc = 1"
  end

  test "identifier" do
    assert_parses CallNode(nil, nil, IDENTIFIER("a"), nil, "a"), "a"
  end

  test "if" do
    assert_parses IfNode(KEYWORD_IF("if"), expression("true"), Statements([expression("1")]), nil, KEYWORD_END("end")), "if true; 1; end"
  end

  test "if modifier" do
    assert_parses IfNode(KEYWORD_IF("if"), expression("true"), Statements([expression("1")]), nil, nil), "1 if true"
  end

  test "if else" do
    expected = IfNode(
      KEYWORD_IF("if"),
      expression("true"),
      Statements([expression("1")]),
      ElseNode(
        KEYWORD_ELSE("else"),
        Statements([expression("2")]),
        KEYWORD_END("end")
      ),
      KEYWORD_END("end")
    )

    assert_parses expected, "if true\n1 else 2 end"
  end

  test "imaginary" do
    assert_parses ImaginaryLiteral(IMAGINARY_NUMBER("1i")), "1i"
  end

  test "instance variable read" do
    assert_parses InstanceVariableRead(INSTANCE_VARIABLE("@abc")), "@abc"
  end

  test "instance variable write" do
    assert_parses InstanceVariableWrite(INSTANCE_VARIABLE("@abc"), EQUAL("="), expression("1")), "@abc = 1"
  end

  test "local variable write" do
    assert_parses LocalVariableWrite(IDENTIFIER("abc"), EQUAL("="), expression("1")), "abc = 1"
  end

  test "module" do
    expected = ModuleNode(
      Scope([IDENTIFIER("a")]),
      KEYWORD_MODULE("module"),
      ConstantRead(CONSTANT("A")),
      Statements([
        LocalVariableWrite(
          IDENTIFIER("a"),
          EQUAL("="),
          IntegerLiteral(INTEGER("1"))
        )
      ]),
      KEYWORD_END("end")
    )

    assert_parses expected, "module A a = 1 end"
  end

  test "next" do
    assert_parses NextNode(KEYWORD_NEXT("next"), nil, nil, nil), "next"
  end

  test "next()" do
    assert_parses NextNode(KEYWORD_NEXT("next"), PARENTHESIS_LEFT("("), ArgumentsNode([]), PARENTHESIS_RIGHT(")")), "next()"
  end

  test "next(1)" do
    assert_parses NextNode(KEYWORD_NEXT("next"), PARENTHESIS_LEFT("("), ArgumentsNode([expression("1")]), PARENTHESIS_RIGHT(")")), "next(1)"
  end

  test "next(1, 2, 3)" do
    assert_parses NextNode(KEYWORD_NEXT("next"), PARENTHESIS_LEFT("("), ArgumentsNode([expression("1"), expression("2"), expression("3")]), PARENTHESIS_RIGHT(")")), "next(1, 2, 3)"
  end

  test "nil" do
    assert_parses NilNode(KEYWORD_NIL("nil")), "nil"
  end

  test "or keyword" do
    assert_parses OrNode(expression("1"), KEYWORD_OR("or"), expression("2")), "1 or 2"
  end

  test "or operator" do
    assert_parses OrNode(expression("1"), PIPE_PIPE("||"), expression("2")), "1 || 2"
  end

  test "operator and assignment" do
    assert_parses OperatorAndAssignmentNode(expression("a"), AMPERSAND_AMPERSAND_EQUAL("&&="), expression("b")), "a &&= b"
  end

  test "operator or assignment" do
    assert_parses OperatorOrAssignmentNode(expression("a"), PIPE_PIPE_EQUAL("||="), expression("b")), "a ||= b"
  end

  test "operator assignment" do
    assert_parses OperatorAssignmentNode(expression("a"), PLUS_EQUAL("+="), expression("b")), "a += b"
  end

  test "post execution" do
    assert_parses PostExecutionNode(KEYWORD_END_UPCASE("END"), BRACE_LEFT("{"), Statements([expression("1")]), BRACE_RIGHT("}")), "END { 1 }"
  end

  test "pre execution" do
    assert_parses PreExecutionNode(KEYWORD_BEGIN_UPCASE("BEGIN"), BRACE_LEFT("{"), Statements([expression("1")]), BRACE_RIGHT("}")), "BEGIN { 1 }"
  end

  test "pre execution missing {" do
    expected = PreExecutionNode(
      KEYWORD_BEGIN_UPCASE("BEGIN"),
      MISSING(""),
      Statements([expression("1")]),
      BRACE_RIGHT("}")
    )

    assert_parses expected, "BEGIN 1 }"
  end

  test "pre execution missing { error" do
    result = YARP.parse("BEGIN 1 }")
    result => { errors: [{ message: "Expected '{' after 'BEGIN'." }] }
    assert result.failure?
  end

  test "range inclusive" do
    assert_parses RangeNode(expression("1"), DOT_DOT(".."), expression("2")), "1..2"
  end

  test "range exclusive" do
    assert_parses RangeNode(expression("1"), DOT_DOT_DOT("..."), expression("2")), "1...2"
  end

  test "rational" do
    assert_parses RationalLiteral(RATIONAL_NUMBER("1r")), "1r"
  end

  test "redo" do
    assert_parses RedoNode(KEYWORD_REDO("redo")), "redo"
  end

  test "retry" do
    assert_parses RetryNode(KEYWORD_RETRY("retry")), "retry"
  end

  test "self" do
    assert_parses SelfNode(KEYWORD_SELF("self")), "self"
  end

  test "string empty" do
    assert_parses StringNode(STRING_BEGIN("'"), STRING_CONTENT(""), STRING_END("'")), "''"
  end

  test "string interpolation disallowed" do
    assert_parses StringNode(STRING_BEGIN("'"), STRING_CONTENT("abc"), STRING_END("'")), "'abc'"
  end

  test "string interpolation allowed, but not used" do
    expected = InterpolatedStringNode(
      STRING_BEGIN("\""),
      [StringNode(nil, STRING_CONTENT("abc"), nil)],
      STRING_END("\"")
    )

    assert_parses expected, "\"abc\""
  end

  test "string interpolation allowed, sed" do
    expected = InterpolatedStringNode(
      STRING_BEGIN("\""),
      [
        StringNode(nil, STRING_CONTENT("aaa "), nil),
        StringInterpolatedNode(
          EMBEXPR_BEGIN("\#{"),
          Statements([CallNode(nil, nil, IDENTIFIER("bbb"), nil, "bbb")]),
          EMBEXPR_END("}")
        ),
        StringNode(nil, STRING_CONTENT(" ccc"), nil)
      ],
      STRING_END("\"")
    )

    assert_parses expected, "\"aaa \#{bbb} ccc\""
  end

  test "string list" do
    expected = StringListNode(
      PERCENT_LOWER_W("%w["),
      [
        StringNode(nil, STRING_CONTENT("a"), nil),
        StringNode(nil, STRING_CONTENT("b"), nil),
        StringNode(nil, STRING_CONTENT("c"), nil)
      ],
      STRING_END("]")
    )

    assert_parses expected, "%w[a b c]"
  end

  test "super" do
    assert_parses ForwardingSuperNode(KEYWORD_SUPER("super")), "super"
  end

  test "super()" do
    assert_parses SuperNode(KEYWORD_SUPER("super"), PARENTHESIS_LEFT("("), ArgumentsNode([]), PARENTHESIS_RIGHT(")")), "super()"
  end

  test "super(1)" do
    assert_parses SuperNode(KEYWORD_SUPER("super"), PARENTHESIS_LEFT("("), ArgumentsNode([expression("1")]), PARENTHESIS_RIGHT(")")), "super(1)"
  end

  test "super(1, 2, 3)" do
    assert_parses SuperNode(KEYWORD_SUPER("super"), PARENTHESIS_LEFT("("), ArgumentsNode([expression("1"), expression("2"), expression("3")]), PARENTHESIS_RIGHT(")")), "super(1, 2, 3)"
  end

  test "symbol list" do
    expected = SymbolListNode(
      PERCENT_LOWER_I("%i["),
      [SymbolNode(STRING_CONTENT("a")), SymbolNode(STRING_CONTENT("b")), SymbolNode(STRING_CONTENT("c"))],
      STRING_END("]")
    )

    assert_parses expected, "%i[a b c]"
  end

  test "ternary" do
    expected = Ternary(
      CallNode(nil, nil, IDENTIFIER("a"), nil, "a"),
      QUESTION_MARK("?"),
      CallNode(nil, nil, IDENTIFIER("b"), nil, "b"),
      COLON(":"),
      CallNode(nil, nil, IDENTIFIER("c"), nil, "c")
    )

    assert_parses expected, "a ? b : c"
  end

  test "true" do
    assert_parses TrueNode(KEYWORD_TRUE("true")), "true"
  end

  test "unary !" do
    assert_parses CallNode(expression("1"), nil, BANG("!"), nil, "!"), "!1"
  end

  test "unary -" do
    assert_parses CallNode(expression("1"), nil, MINUS("-"), nil, "-@"), "-1"
  end

  test "unary +" do
    assert_parses CallNode(expression("1"), nil, PLUS("+"), nil, "+@"), "+1"
  end

  test "unary ~" do
    assert_parses CallNode(expression("1"), nil, TILDE("~"), nil, "~"), "~1"
  end

  test "unless" do
    assert_parses UnlessNode(KEYWORD_UNLESS("unless"), expression("true"), Statements([expression("1")])), "unless true; 1; end"
  end

  test "unless modifier" do
    assert_parses UnlessNode(KEYWORD_UNLESS("unless"), expression("true"), Statements([expression("1")])), "1 unless true"
  end

  test "until" do
    assert_parses UntilNode(KEYWORD_UNTIL("until"), expression("true"), Statements([expression("1")])), "until true; 1; end"
  end

  test "until modifier" do
    assert_parses UntilNode(KEYWORD_UNTIL("until"), expression("true"), Statements([expression("1")])), "1 until true"
  end

  test "while" do
    assert_parses WhileNode(KEYWORD_WHILE("while"), expression("true"), Statements([expression("1")])), "while true; 1; end"
  end

  test "while modifier" do
    assert_parses WhileNode(KEYWORD_WHILE("while"), expression("true"), Statements([expression("1")])), "1 while true"
  end

  test "yield" do
    assert_parses YieldNode(KEYWORD_YIELD("yield"), nil, nil, nil), "yield"
  end

  test "yield()" do
    assert_parses YieldNode(KEYWORD_YIELD("yield"), PARENTHESIS_LEFT("("), ArgumentsNode([]), PARENTHESIS_RIGHT(")")), "yield()"
  end

  test "yield(1)" do
    assert_parses YieldNode(KEYWORD_YIELD("yield"), PARENTHESIS_LEFT("("), ArgumentsNode([expression("1")]), PARENTHESIS_RIGHT(")")), "yield(1)"
  end

  test "yield(1, 2, 3)" do
    assert_parses YieldNode(KEYWORD_YIELD("yield"), PARENTHESIS_LEFT("("), ArgumentsNode([expression("1"), expression("2"), expression("3")]), PARENTHESIS_RIGHT(")")), "yield(1, 2, 3)"
  end

  test "TERM < FACTOR" do
    expected = CallNode(
      expression("1"),
      nil,
      PLUS("+"),
      ArgumentsNode([
        CallNode(expression("2"), nil, STAR("*"), ArgumentsNode([expression("3")]), "*")
      ]),
      "+"
    )

    assert_parses expected, "1 + 2 * 3"
  end

  test "FACTOR < EXPONENT" do
    expected = CallNode(
      expression("1"),
      nil,
      STAR("*"),
      ArgumentsNode([
        CallNode(expression("2"), nil, STAR_STAR("**"), ArgumentsNode([expression("3")]), "**")
      ]),
      "*"
    )

    assert_parses expected, "1 * 2 ** 3"
  end

  test "FACTOR > TERM" do
    expected = CallNode(
      CallNode(expression("1"), nil, STAR("*"), ArgumentsNode([expression("2")]), "*"),
      nil,
      PLUS("+"),
      ArgumentsNode([expression("3")]),
      "+"
    )

    assert_parses expected, "1 * 2 + 3"
  end

  test "MODIFIER left associativity" do
    expected = IfNode(
      KEYWORD_IF("if"),
      expression("c"),
      Statements([IfNode(KEYWORD_IF("if"), expression("b"), Statements([expression("a")]), nil, nil)]),
      nil,
      nil
    )

    assert_parses expected, "a if b if c"
  end

  private

  def assert_serializes(expected, source)
    YARP.load(source, YARP.dump(source)) => YARP::Program[statements: YARP::Statements[body: [*, node]]]
    assert_equal expected, node
  end

  def assert_parses(expected, source)
    assert_equal expected, expression(source)
    assert_serializes expected, source
  end

  def expression(source)
    YARP.parse(source) => YARP::ParseResult[node: YARP::Program[statements: YARP::Statements[body: [*, node]]]]
    node
  end
end
