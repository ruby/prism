# frozen_string_literal: true

require "test_helper"

class ErrorsTest < Test::Unit::TestCase
  include YARP::DSL

  test "constant path with invalid token after" do
    expected = ConstantPathNode(
      ConstantRead(CONSTANT("A")),
      COLON_COLON("::"),
      MissingNode()
    )

    assert_errors expected, "A::$b", "Expected identifier or constant after '::'"
  end

  test "pre execution missing {" do
    expected = PreExecutionNode(
      KEYWORD_BEGIN_UPCASE("BEGIN"),
      MISSING(""),
      Statements([expression("1")]),
      BRACE_RIGHT("}")
    )

    assert_errors expected, "BEGIN 1 }", "Expected '{' after 'BEGIN'."
  end

  test "pre execution context" do
    expected = PreExecutionNode(
      KEYWORD_BEGIN_UPCASE("BEGIN"),
      BRACE_LEFT("{"),
      Statements([
        CallNode(
          expression("1"),
          nil,
          PLUS("+"),
          nil,
          ArgumentsNode([MissingNode()]),
          nil,
          "+"
        )
      ]),
      BRACE_RIGHT("}")
    )

    assert_errors expected, "BEGIN { 1 + }", "Expected a value after the operator."
  end

  private

  def assert_errors(expected, source, error)
    result = YARP.parse(source)
    result => YARP::ParseResult[node: YARP::Program[statements: YARP::Statements[body: [*, node]]]]

    assert_equal expected, node
    assert_equal [error], result.errors.map(&:message)
  end

  def expression(source)
    YARP.parse(source) => YARP::ParseResult[node: YARP::Program[statements: YARP::Statements[body: [*, node]]]]
    node
  end
end
