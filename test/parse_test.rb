# frozen_string_literal: true

require "test_helper"

class ParseTest < Test::Unit::TestCase
  include YARP::DSL

  test "TERM < FACTOR" do
    assert_equal higher_precedence(PLUS("+"), STAR("*")), YARP.parse("1 + 2 * 3")
  end

  test "FACTOR < EXPONENT" do
    assert_equal higher_precedence(STAR("*"), STAR_STAR("**")), YARP.parse("1 * 2 ** 3")
  end

  test "FACTOR > TERM" do
    assert_equal lower_precedence(STAR("*"), PLUS("+")), YARP.parse("1 * 2 + 3")
  end

  test "MODIFIER left associativity" do
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

    assert_equal expected, YARP.parse("a if b if c")
  end

  private

  def lower_precedence(first_operator, second_operator)
    Program(Statements([
      Binary(
        Binary(
          IntegerLiteral(INTEGER("1")),
          first_operator,
          IntegerLiteral(INTEGER("2"))
        ),
        second_operator,
        IntegerLiteral(INTEGER("3"))
      )
    ]))
  end

  def higher_precedence(first_operator, second_operator)
    Program(Statements([
      Binary(
        IntegerLiteral(INTEGER("1")),
        first_operator,
        Binary(
          IntegerLiteral(INTEGER("2")),
          second_operator,
          IntegerLiteral(INTEGER("3"))
        )
      )
    ]))
  end
end
