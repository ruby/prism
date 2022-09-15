# frozen_string_literal: true

require "test_helper"

class ParseTest < Test::Unit::TestCase
  include YARP::DSL

  test "TERM < FACTOR" do
    actual = YARP.parse("1 + 2 * 3")
    expected = Program(Statements([
      Binary(
        IntegerLiteral(INTEGER("1")),
        PLUS("+"),
        Binary(
          IntegerLiteral(INTEGER("2")),
          STAR("*"),
          IntegerLiteral(INTEGER("3"))
        )
      )
    ]))

    assert_equal expected, actual
  end

  test "FACTOR < EXPONENT" do
    actual = YARP.parse("1 * 2 ** 3")
    expected = Program(Statements([
      Binary(
        IntegerLiteral(INTEGER("1")),
        STAR("*"),
        Binary(
          IntegerLiteral(INTEGER("2")),
          STAR_STAR("**"),
          IntegerLiteral(INTEGER("3"))
        )
      )
    ]))

    assert_equal expected, actual
  end

  test "FACTOR > TERM" do
    actual = YARP.parse("1 * 2 + 3")
    expected = Program(Statements([
      Binary(
        Binary(
          IntegerLiteral(INTEGER("1")),
          STAR("*"),
          IntegerLiteral(INTEGER("2"))
        ),
        PLUS("+"),
        IntegerLiteral(INTEGER("3"))
      )
    ]))

    assert_equal expected, actual
  end

  test "MODIFIER left associativity" do
    actual = YARP.parse("a if b if c")
    expected = Program(
      Statements([
        IfModifier(
          IfModifier(
            VariableReference(Identifier(IDENTIFIER("a"))),
            KEYWORD_IF("if"),
            VariableReference(Identifier(IDENTIFIER("b")))
          ),
          KEYWORD_IF("if"),
          VariableReference(Identifier(IDENTIFIER("c")))
        )
      ])
    )

    assert_equal expected, actual
  end
end
