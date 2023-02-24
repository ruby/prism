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

    assert_errors expected, "A::$b", ["Expected identifier or constant after '::'"]
  end

  test "module name recoverable" do
    expected = ModuleNode(
      Scope([]),
      KEYWORD_MODULE("module"),
      ConstantRead(CONSTANT("Parent")),
      Statements([
        ModuleNode(
          Scope([]),
          KEYWORD_MODULE("module"),
          MissingNode(),
          Statements([]),
          MISSING("")
        )
      ]),
      KEYWORD_END("end")
    )

    assert_errors expected, "module Parent module end", ["Expected to find a module name after `module`."]
  end

  test "for loops index missing" do
    expected = ForNode(
      MissingNode(),
      expression("1..10"),
      Statements([expression("i")]),
      Location(),
      Location(),
      nil,
      Location()
    )

    assert_errors expected, "for in 1..10\ni\nend", ["Expected index after for."]
  end

  test "for loops only end" do
    expected = ForNode(
      MissingNode(),
      MissingNode(),
      Statements([]),
      Location(),
      Location(),
      nil,
      Location()
    )

    assert_errors expected, "for end", ["Expected index after for.", "Expected keyword in.", "Expected collection."]
  end

  test "pre execution missing {" do
    expected = PreExecutionNode(
      Statements([expression("1")]),
      Location(),
      Location(),
      Location()
    )

    assert_errors expected, "BEGIN 1 }", ["Expected '{' after 'BEGIN'."]
  end

  test "pre execution context" do
    expected = PreExecutionNode(
      Statements([
        CallNode(
          expression("1"),
          nil,
          PLUS("+"),
          nil,
          ArgumentsNode([MissingNode()]),
          nil,
          nil,
          "+"
        )
      ]),
      Location(),
      Location(),
      Location()
    )

    assert_errors expected, "BEGIN { 1 + }", ["Expected a value after the operator."]
  end

  test "unterminated embdoc" do
    assert_errors expression("1"), "1\n=begin\n", ["Unterminated embdoc"]
  end

  test "unterminated %i list" do
    assert_errors expression("%i["), "%i[", ["Expected a closing delimiter for a `%i` list."]
  end

  test "unterminated %w list" do
    assert_errors expression("%w["), "%w[", ["Expected a closing delimiter for a `%w` list."]
  end

  test "unterminated %W list" do
    assert_errors expression("%W["), "%W[", ["Expected a closing delimiter for a `%W` list."]
  end

  test "unterminated regular expression" do
    assert_errors expression("/hello"), "/hello", ["Expected a closing delimiter for a regular expression."]
  end

  test "unterminated xstring" do
    assert_errors expression("`hello"), "`hello", ["Expected a closing delimiter for an xstring."]
  end

  test "unterminated string" do
    assert_errors expression('"hello'), '"hello', ["Expected a closing delimiter for an interpolated string."]
  end

  test "unterminated %s symbol" do
    assert_errors expression("%s[abc"), "%s[abc", ["Expected a closing delimiter for a dynamic symbol."]
  end

  test "unterminated parenthesized expression" do
    assert_errors expression('(1 + 2'), '(1 + 2', ["Expected a closing parenthesis."]
  end

  test "(1, 2, 3)" do
    assert_errors expression("(1, 2, 3)"), "(1, 2, 3)", ["Expected a closing parenthesis."]
  end

  test "return(1, 2, 3)" do
    errors = [
      "Expected a closing parenthesis.",
      "Expected an ',' to delimit arguments.",
      "Expected to be able to parse an argument."
    ]

    assert_errors expression("return(1, 2, 3)"), "return(1, 2, 3)", errors
  end

  test "return 1,;" do
    assert_errors expression("return 1,;"), "return 1,;", ["Expected to be able to parse an argument."]
  end

  test "next(1, 2, 3)" do
    errors = [
      "Expected a closing parenthesis.",
      "Expected an ',' to delimit arguments.",
      "Expected to be able to parse an argument."
    ]

    assert_errors expression("next(1, 2, 3)"), "next(1, 2, 3)", errors
  end

  test "next 1,;" do
    assert_errors expression("next 1,;"), "next 1,;", ["Expected to be able to parse an argument."]
  end

  test "break(1, 2, 3)" do
    errors = [
      "Expected a closing parenthesis.",
      "Expected an ',' to delimit arguments.",
      "Expected to be able to parse an argument."
    ]

    assert_errors expression("break(1, 2, 3)"), "break(1, 2, 3)", errors
  end

  test "break 1,;" do
    assert_errors expression("break 1,;"), "break 1,;", ["Expected to be able to parse an argument."]
  end

  test "argument forwarding when parent is not forwarding" do
    assert_errors expression('def a(x, y, z); b(...); end'), 'def a(x, y, z); b(...); end', ["unexpected ... when parent method is not forwarding."]
  end

  test "argument forwarding only effects its own internals" do
    assert_errors expression('def a(...); b(...); end; def c(x, y, z); b(...); end'), 'def a(...); b(...); end; def c(x, y, z); b(...); end', ["unexpected ... when parent method is not forwarding."]
  end

  test "top level constant with downcased identifier" do
    expected = ConstantPathNode(nil, COLON_COLON("::"), ConstantRead(MISSING("")))
    assert_errors expected, "::foo", ["Expected a constant after ::."]
  end

  test "top level constant starting with downcased identifier" do
    expected = ConstantPathNode(nil, COLON_COLON("::"), ConstantRead(MISSING("")))
    assert_errors expected, "::foo::A", ["Expected a constant after ::."]
  end

  test "aliasing global variable with non global variable" do
    assert_errors expression("alias $a b"), "alias $a b", ["Expected a global variable."]
  end

  test "aliasing non global variable with global variable" do
    assert_errors expression("alias a $b"), "alias a $b", ["Expected a bare word or symbol argument."]
  end

  test "aliasing global variable with global number variable" do
    assert_errors expression("alias $a $1"), "alias $a $1", ["Can't make alias for number variables."]
  end

  test "def with expression receiver and no identifier" do
    assert_errors expression("def (a); end"), "def (a); end", [
      "Expected '.' or '::' after receiver",
      "Expected a method name after receiver.",
    ]
  end

  test "def with multiple statements receiver" do
    assert_errors expression("def (\na\nb\n).c; end"), "def (\na\nb\n).c; end", [
      "Expected to be able to parse receiver.",
      "Expected closing ')' for receiver.",
      "Expected '.' or '::' after receiver",
      "Expected a method name after receiver.",
      "Expected to be able to parse an expression.",
      "Expected `end` to close `def` statement.",
    ]
  end

  test "def with empty expression receiver" do
    assert_errors expression("def ().a; end"), "def ().a; end", ["Expected to be able to parse receiver."]
  end

  test "block beginning with '{' and ending with 'end'" do
    expected = CallNode(
      CallNode(nil, nil, IDENTIFIER("x"), nil, nil, nil, nil, "x"),
      DOT("."),
      IDENTIFIER("each"),
      nil,
      nil,
      nil,
      BlockNode(
        BRACE_LEFT("{"),
        nil,
        Statements([CallNode(nil, nil, IDENTIFIER("x"), nil, nil, nil, nil, "x")]),
        MISSING("")
      ),
      "each"
    )

    assert_errors expected, "x.each { x end", ["Expected block beginning with '{' to end with '}'."]
  end

  test "double splat followed by splat argument" do
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("a"),
      PARENTHESIS_LEFT("("),
      ArgumentsNode(
        [KeywordStarNode(
           STAR_STAR("**"),
           CallNode(nil, nil, IDENTIFIER("kwargs"), nil, nil, nil, nil, "kwargs")
         ),
         StarNode(
           STAR("*"),
           CallNode(nil, nil, IDENTIFIER("args"), nil, nil, nil, nil, "args")
         )]
      ),
      PARENTHESIS_RIGHT(")"),
      nil,
      "a"
    )

    assert_errors expected, "a(**kwargs, *args)", ["Unexpected splat argument after double splat."]
  end

  test "arguments after block" do
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("a"),
      PARENTHESIS_LEFT("("),
      ArgumentsNode(
        [BlockArgumentNode(
           AMPERSAND("&"),
           CallNode(nil, nil, IDENTIFIER("block"), nil, nil, nil, nil, "block")
         ),
         CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo")]
      ),
      PARENTHESIS_RIGHT(")"),
      nil,
      "a"
    )

    assert_errors expected, "a(&block, foo)", ["Unexpected argument after block argument."]
  end

  test "arguments binding power for and" do
    expected = AndNode(
      CallNode(
        nil,
        nil,
        IDENTIFIER("foo"),
        PARENTHESIS_LEFT("("),
        ArgumentsNode(
          [StarNode(
             STAR("*"),
             CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar")
           ),
           MissingNode()]
        ),
        MISSING(""),
        nil,
        "foo"
      ),
      CallNode(nil, nil, IDENTIFIER("baz"), nil, nil, nil, nil, "baz"),
      KEYWORD_AND("and")
    )

    assert_errors expected, "foo(*bar and baz)", [
      "Expected a ',' to delimit arguments.",
      "Expected to be able to parse an argument.",
      "Expected a ')' to close the argument list."
    ]
  end


  test "splat argument after keyword argument" do
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("a"),
      PARENTHESIS_LEFT("("),
      ArgumentsNode(
        [HashNode(
           nil,
           [AssocNode(
              SymbolNode(nil, LABEL("foo"), LABEL_END(":")),
              CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar"),
              nil
            )],
           nil
         ),
         StarNode(
           STAR("*"),
           CallNode(nil, nil, IDENTIFIER("args"), nil, nil, nil, nil, "args")
         )]
      ),
      PARENTHESIS_RIGHT(")"),
      nil,
      "a"
    )

    assert_errors expected, "a(foo: bar, *args)", ["Expected a key in the hash literal.", "Expected a ',' to delimit arguments."]
  end

  private

  def assert_errors(expected, source, errors)
    result = YARP.parse(source)
    result => YARP::ParseResult[node: YARP::Program[statements: YARP::Statements[body: [*, node]]]]

    assert_equal expected, node
    assert_equal errors, result.errors.map(&:message)
  end

  def expression(source)
    YARP.parse(source) => YARP::ParseResult[node: YARP::Program[statements: YARP::Statements[body: [*, node]]]]
    node
  end

  # This method is just named this way to mirror the other DSL methods.
  def Location()
    YARP::Location.new(0, 0)
  end
end
