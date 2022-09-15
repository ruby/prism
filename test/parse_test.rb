# frozen_string_literal: true

require "test_helper"

class ParseTest < Test::Unit::TestCase
  include YARP::DSL

  test "false" do
    assert_equal VariableReference(KEYWORD_FALSE("false")), expression("false")
  end

  test "float" do
    assert_equal FloatLiteral(FLOAT("1.0")), expression("1.0")
  end

  test "imaginary" do
    assert_equal ImaginaryLiteral(IMAGINARY_NUMBER("1i")), expression("1i")
  end

  test "nil" do
    assert_equal VariableReference(KEYWORD_NIL("nil")), expression("nil")
  end

  test "rational" do
    assert_equal RationalLiteral(RATIONAL_NUMBER("1r")), expression("1r")
  end

  test "self" do
    assert_equal VariableReference(KEYWORD_SELF("self")), expression("self")
  end

  test "true" do
    assert_equal VariableReference(KEYWORD_TRUE("true")), expression("true")
  end

  test "TERM < FACTOR" do
    actual = expression("1 + 2 * 3")
    expected = Binary(
      IntegerLiteral(INTEGER("1")),
      PLUS("+"),
      Binary(
        IntegerLiteral(INTEGER("2")),
        STAR("*"),
        IntegerLiteral(INTEGER("3"))
      )
    )

    assert_equal expected, actual
  end

  test "FACTOR < EXPONENT" do
    actual = expression("1 * 2 ** 3")
    expected = Binary(
      IntegerLiteral(INTEGER("1")),
      STAR("*"),
      Binary(
        IntegerLiteral(INTEGER("2")),
        STAR_STAR("**"),
        IntegerLiteral(INTEGER("3"))
      )
    )

    assert_equal expected, actual
  end

  test "FACTOR > TERM" do
    actual = expression("1 * 2 + 3")
    expected = Binary(
      Binary(
        IntegerLiteral(INTEGER("1")),
        STAR("*"),
        IntegerLiteral(INTEGER("2"))
      ),
      PLUS("+"),
      IntegerLiteral(INTEGER("3"))
    )

    assert_equal expected, actual
  end

  test "MODIFIER left associativity" do
    actual = expression("a if b if c")
    expected = IfModifier(
      IfModifier(
        VariableReference(IDENTIFIER("a")),
        KEYWORD_IF("if"),
        VariableReference(IDENTIFIER("b"))
      ),
      KEYWORD_IF("if"),
      VariableReference(IDENTIFIER("c"))
    )

    assert_equal expected, actual
  end

  private

  def expression(source)
    YARP.parse(source) => YARP::Program[statements: YARP::Statements[body: [node]]]
    node
  end
end
