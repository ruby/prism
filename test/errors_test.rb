# frozen_string_literal: true

require "test_helper"

class ErrorsTest < Test::Unit::TestCase
  include YARP::DSL

  test "constant path with invalid token after" do
    expected = ConstantPathNode(
      ConstantReadNode(),
      COLON_COLON("::"),
      MissingNode()
    )

    assert_errors expected, "A::$b", ["Expected identifier or constant after '::'"]
  end

  test "module name recoverable" do
    expected = ModuleNode(
      Scope([]),
      KEYWORD_MODULE("module"),
      ConstantReadNode(),
      StatementsNode(
        [ModuleNode(
           Scope([]),
           KEYWORD_MODULE("module"),
           MissingNode(),
           StatementsNode([]),
           MISSING("")
         )]
      ),
      KEYWORD_END("end")
    )

    assert_errors expected, "module Parent module end", [
      "Expected to find a module name after `module`."
    ]
  end

  test "for loops index missing" do
    expected = ForNode(
      MissingNode(),
      expression("1..10"),
      StatementsNode([expression("i")]),
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
      StatementsNode([]),
      Location(),
      Location(),
      nil,
      Location()
    )

    assert_errors expected, "for end", ["Expected index after for.", "Expected keyword in.", "Expected collection."]
  end

  test "pre execution missing {" do
    expected = PreExecutionNode(
      StatementsNode([expression("1")]),
      Location(),
      Location(),
      Location()
    )

    assert_errors expected, "BEGIN 1 }", ["Expected '{' after 'BEGIN'."]
  end

  test "pre execution context" do
    expected = PreExecutionNode(
      StatementsNode([
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
    assert_errors expression('(1 + 2'), '(1 + 2', ["Expected to be able to parse an expression.", "Expected a closing parenthesis."]
  end

  test "(1, 2, 3)" do
    assert_errors expression("(1, 2, 3)"), "(1, 2, 3)", ["Expected to be able to parse an expression.", "Expected a closing parenthesis."]
  end

  test "return(1, 2, 3)" do
    errors = ["Expected to be able to parse an expression.", "Expected a closing parenthesis."]

    assert_errors expression("return(1, 2, 3)"), "return(1, 2, 3)", errors
  end

  test "return 1,;" do
    assert_errors expression("return 1,;"), "return 1,;", ["Expected to be able to parse an argument."]
  end

  test "next(1, 2, 3)" do
    errors = ["Expected to be able to parse an expression.", "Expected a closing parenthesis."]

    assert_errors expression("next(1, 2, 3)"), "next(1, 2, 3)", errors
  end

  test "next 1,;" do
    assert_errors expression("next 1,;"), "next 1,;", ["Expected to be able to parse an argument."]
  end

  test "break(1, 2, 3)" do
    errors = ["Expected to be able to parse an expression.", "Expected a closing parenthesis."]

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
    expected = ConstantPathNode(nil, UCOLON_COLON("::"), ConstantReadNode())
    assert_errors expected, "::foo", ["Expected a constant after ::."]
  end

  test "top level constant starting with downcased identifier" do
    expected = ConstantPathNode(nil, UCOLON_COLON("::"), ConstantReadNode())
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
      "Expected '.' or '::' after receiver"
    ]
  end

  test "def with multiple statements receiver" do
    assert_errors expression("def (\na\nb\n).c; end"), "def (\na\nb\n).c; end", [
      "Expected closing ')' for receiver.",
      "Expected '.' or '::' after receiver",
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
        nil,
        StatementsNode([CallNode(nil, nil, IDENTIFIER("x"), nil, nil, nil, nil, "x")]),
        Location(),
        Location()
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
        [HashNode(
           nil,
           [AssocSplatNode(
              CallNode(
                nil,
                nil,
                IDENTIFIER("kwargs"),
                nil,
                nil,
                nil,
                nil,
                "kwargs"
              ),
              Location()
            )],
           nil
         ),
         SplatNode(
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
      ArgumentsNode([
        BlockArgumentNode(expression("block"), Location()),
        expression("foo")
      ]),
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
          [SplatNode(
             STAR("*"),
             CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar")
           )]
        ),
        MISSING(""),
        nil,
        "foo"
      ),
      CallNode(nil, nil, IDENTIFIER("baz"), nil, nil, nil, nil, "baz"),
      KEYWORD_AND("and")
    )

    assert_errors expected, "foo(*bar and baz)", [
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
         SplatNode(
           STAR("*"),
           CallNode(nil, nil, IDENTIFIER("args"), nil, nil, nil, nil, "args")
         )]
      ),
      PARENTHESIS_RIGHT(")"),
      nil,
      "a"
    )

    assert_errors expected, "a(foo: bar, *args)", ["Unexpected splat argument after double splat."]
  end

  test "module definition in method body" do
    expected = DefNode(
      IDENTIFIER("foo"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      StatementsNode(
        [ModuleNode(
           Scope([]),
           KEYWORD_MODULE("module"),
           ConstantReadNode(),
           StatementsNode([]),
           KEYWORD_END("end")
         )]
      ),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_errors expected, "def foo;module A;end;end", ["Module definition in method body"]
  end

  test "module definition in method body within block" do
    expected = DefNode(
      IDENTIFIER("foo"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      StatementsNode(
        [CallNode(
           nil,
           nil,
           IDENTIFIER("bar"),
           nil,
           nil,
           nil,
           BlockNode(
             nil,
             StatementsNode(
               [ModuleNode(
                  Scope([]),
                  KEYWORD_MODULE("module"),
                  ConstantReadNode(),
                  StatementsNode([]),
                  KEYWORD_END("end")
                )]
             ),
             Location(),
             Location()
           ),
           "bar"
         )]
      ),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_errors expected, "
      def foo
        bar do
          module Foo;end
        end
      end
    ", ["Module definition in method body"]
  end

  private

  def assert_errors(expected, source, errors)
    assert_nil Ripper.sexp_raw(source)

    result = YARP.parse(source)
    result => YARP::ParseResult[value: YARP::ProgramNode[statements: YARP::StatementsNode[body: [*, node]]]]

    assert_equal expected, node
    assert_equal errors, result.errors.map(&:message)
  end

  def expression(source)
    YARP.parse(source) => YARP::ParseResult[value: YARP::ProgramNode[statements: YARP::StatementsNode[body: [*, node]]]]
    node
  end

  # This method is just named this way to mirror the other DSL methods.
  def Location()
    YARP::Location.new(0, 0)
  end
end
