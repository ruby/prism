# frozen_string_literal: true

require "test_helper"

class ParseTest < Test::Unit::TestCase
  include YARP::DSL

  test "binary" do
    assert_equal Binary(expression("1"), "+", expression("2")), expression("1 + 2")
  end

  test "character literal" do
    assert_equal CharacterLiteral("?a"), expression("?a")
  end

  test "class variable" do
    assert_equal VariableReference("@@abc"), expression("@@abc")
  end

  test "false" do
    assert_equal VariableReference("false"), expression("false")
  end

  test "float" do
    assert_equal FloatLiteral("1.0"), expression("1.0")
  end

  test "global variable" do
    assert_equal VariableReference("$abc"), expression("$abc")
  end

  test "identifier" do
    assert_equal VariableReference("a"), expression("a")
  end

  test "if modifier" do
    assert_equal IfModifier(expression("1"), "if", expression("true")), expression("1 if true")
  end

  test "imaginary" do
    assert_equal ImaginaryLiteral("1i"), expression("1i")
  end

  test "instance variable" do
    assert_equal VariableReference("@abc"), expression("@abc")
  end

  test "nil" do
    assert_equal VariableReference("nil"), expression("nil")
  end

  test "rational" do
    assert_equal RationalLiteral("1r"), expression("1r")
  end

  test "redo" do
    assert_equal Redo("redo"), expression("redo")
  end

  test "retry" do
    assert_equal Retry("retry"), expression("retry")
  end

  test "self" do
    assert_equal VariableReference("self"), expression("self")
  end

  test "ternary" do
    expected = Ternary(
      VariableReference("a"),
      "?",
      VariableReference("b"),
      ":",
      VariableReference("c")
    )

    assert_equal expected, expression("a ? b : c")
  end

  test "true" do
    assert_equal VariableReference("true"), expression("true")
  end

  test "unless modifier" do
    assert_equal UnlessModifier(expression("1"), "unless", expression("true")), expression("1 unless true")
  end

  test "until modifier" do
    assert_equal UntilModifier(expression("1"), "until", expression("true")), expression("1 until true")
  end

  test "while modifier" do
    assert_equal WhileModifier(expression("1"), "while", expression("true")), expression("1 while true")
  end

  test "TERM < FACTOR" do
    actual = expression("1 + 2 * 3")
    expected = Binary(
      expression("1"),
      "+",
      Binary(expression("2"), "*", expression("3"))
    )

    assert_equal expected, actual
  end

  test "FACTOR < EXPONENT" do
    actual = expression("1 * 2 ** 3")
    expected = Binary(
      expression("1"),
      "*",
      Binary(expression("2"), "**", expression("3"))
    )

    assert_equal expected, actual
  end

  test "FACTOR > TERM" do
    actual = expression("1 * 2 + 3")
    expected = Binary(
      Binary(expression("1"), "*", expression("2")),
      "+",
      expression("3")
    )

    assert_equal expected, actual
  end

  test "MODIFIER left associativity" do
    actual = expression("a if b if c")
    expected = IfModifier(
      IfModifier(expression("a"), "if", expression("b")),
      "if",
      expression("c")
    )

    assert_equal expected, actual
  end

  private

  def expression(source)
    YARP.parse(source) => YARP::Program[statements: YARP::Statements[body: [node]]]
    node
  end
end
