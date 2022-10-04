# frozen_string_literal: true

require "test_helper"

class ParseTest < Test::Unit::TestCase
  include YARP::DSL

  test "binary" do
    assert_parses Binary(expression("1"), PLUS("+"), expression("2")), "1 + 2"
  end

  test "character literal" do
    assert_parses CharacterLiteral(CHARACTER_LITERAL("?a")), "?a"
  end

  test "class variable read" do
    assert_parses ClassVariableRead(CLASS_VARIABLE("@@abc")), "@@abc"
  end

  test "class variable write" do
    assert_parses ClassVariableWrite(CLASS_VARIABLE("@@abc"), EQUAL("="), expression("1")), "@@abc = 1"
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
    assert_parses CallNode(IDENTIFIER("a")), "a"
  end

  test "if" do
    assert_parses IfNode(KEYWORD_IF("if"), expression("true"), Statements([expression("1")])), "if true; 1; end"
  end

  test "if modifier" do
    assert_parses IfNode(KEYWORD_IF("if"), expression("true"), Statements([expression("1")])), "1 if true"
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

  test "local variable read" do
    assert_parses LocalVariableRead(IDENTIFIER("abc")), "abc = 1; abc"
  end

  test "nil" do
    assert_parses NilNode(KEYWORD_NIL("nil")), "nil"
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

  test "ternary" do
    expected = Ternary(
      CallNode(IDENTIFIER("a")),
      QUESTION_MARK("?"),
      CallNode(IDENTIFIER("b")),
      COLON(":"),
      CallNode(IDENTIFIER("c"))
    )

    assert_parses expected, "a ? b : c"
  end

  test "true" do
    assert_parses TrueNode(KEYWORD_TRUE("true")), "true"
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

  test "TERM < FACTOR" do
    expected = Binary(
      expression("1"),
      PLUS("+"),
      Binary(expression("2"), STAR("*"), expression("3"))
    )

    assert_parses expected, "1 + 2 * 3"
  end

  test "FACTOR < EXPONENT" do
    expected = Binary(
      expression("1"),
      STAR("*"),
      Binary(expression("2"), STAR_STAR("**"), expression("3"))
    )

    assert_parses expected, "1 * 2 ** 3"
  end

  test "FACTOR > TERM" do
    expected = Binary(
      Binary(expression("1"), STAR("*"), expression("2")),
      PLUS("+"),
      expression("3")
    )

    assert_parses expected, "1 * 2 + 3"
  end

  test "MODIFIER left associativity" do
    expected = IfNode(
      KEYWORD_IF("if"),
      expression("c"),
      Statements([
        IfNode(KEYWORD_IF("if"), expression("b"), Statements([expression("a")]))
      ])
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
    YARP.parse(source) => YARP::Program[statements: YARP::Statements[body: [*, node]]]
    node
  end
end
