# frozen_string_literal: true

require "test_helper"

class ParseTest < Test::Unit::TestCase
  include YARP::DSL

  test "empty string" do
    YARP.parse("") => YARP::ParseResult[node: YARP::Program[statements: YARP::Statements[body: []]]]
  end

  test "comment inline" do
    YARP.parse("# comment") => YARP::ParseResult[comments: [YARP::Comment[type: :inline]]]
  end

  test "comment __END__" do
    source = <<~RUBY
      __END__
      comment
    RUBY

    YARP.parse(source) => YARP::ParseResult[comments: [YARP::Comment[type: :__END__]]]
  end

  test "comment embedded document" do
    source = <<~RUBY
      =begin
      comment
      =end
    RUBY

    YARP.parse(source) => YARP::ParseResult[comments: [YARP::Comment[type: :embdoc]]]
  end

  test "alias bare" do
    expected = AliasNode(
      SymbolNode(nil, IDENTIFIER("foo"), nil),
      SymbolNode(nil, IDENTIFIER("bar"), nil),
      Location()
    )

    assert_parses expected, "alias foo bar"
  end

  test "alias symbols" do
    expected = AliasNode(
      SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("foo"), nil),
      SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("bar"), nil),
      Location()
    )

    assert_parses expected, "alias :foo :bar"
  end

  test "alias global variables" do
    expected = AliasNode(
      GlobalVariableRead(GLOBAL_VARIABLE("$foo")),
      GlobalVariableRead(GLOBAL_VARIABLE("$bar")),
      Location()
    )

    assert_parses expected, "alias $foo $bar"
  end

  test "alias backreference global variables" do
    expected = AliasNode(
      GlobalVariableRead(GLOBAL_VARIABLE("$a")),
      GlobalVariableRead(BACK_REFERENCE("$'")),
      Location()
    )

    assert_parses expected, "alias $a $'"
  end

  test "and keyword" do
    assert_parses AndNode(expression("1"), expression("2"), KEYWORD_AND("and")), "1 and 2"
  end

  test "and operator" do
    assert_parses AndNode(expression("1"), expression("2"), AMPERSAND_AMPERSAND("&&")), "1 && 2"
  end

  test "array literal" do
    expected = ArrayNode(
      [IntegerNode(), FloatNode(), RationalNode(), ImaginaryNode()],
      BRACKET_LEFT("["),
      BRACKET_RIGHT("]")
    )

    assert_parses expected, "[1, 1.0, 1r, 1i]"
  end

  test "array literal empty" do
    assert_parses ArrayNode([], BRACKET_LEFT("["), BRACKET_RIGHT("]")), "[]"
  end

  test "array with splat" do
    expected = ArrayNode(
      [
        StarNode(
          IDENTIFIER("a"),
          CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")
        )
      ],
      BRACKET_LEFT("["),
      BRACKET_RIGHT("]")
    )

    assert_parses expected, "[*a]"
  end

  test "array literal with newlines" do
    expected = ArrayNode(
      [SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("a"), nil),
        SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("b"), nil),
        SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("c"), nil),
        IntegerNode(),
        SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("d"), nil)],
      BRACKET_LEFT("["),
      BRACKET_RIGHT("]")
    )

    assert_parses expected, "[:a, :b,\n:c,1,\n\n\n\n:d,\n]"
  end

  test "empty array literal" do
    assert_parses ArrayNode([], BRACKET_LEFT("["), BRACKET_RIGHT("]")), "[\n]\n"
  end

  test "empty parenteses" do
    assert_parses ParenthesesNode(PARENTHESIS_LEFT("("), Statements([]), PARENTHESIS_RIGHT(")")), "()"
  end


  test "parentesized expression" do
    expected = ParenthesesNode(
      PARENTHESIS_LEFT("("),
      Statements(
        [CallNode(
           IntegerNode(),
           nil,
           PLUS("+"),
           nil,
           ArgumentsNode([IntegerNode()]),
           nil,
           nil,
           "+"
         )]
      ),
      PARENTHESIS_RIGHT(")")
    )

    assert_parses expected, "(1 + 1)"
  end

  test "parentesized with multiple statements" do
    expected = ParenthesesNode(
      PARENTHESIS_LEFT("("),
      Statements(
        [CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a"),
         CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b"),
         CallNode(nil, nil, IDENTIFIER("c"), nil, nil, nil, nil, "c")]
      ),
      PARENTHESIS_RIGHT(")")
    )
    assert_parses expected, "(a; b; c)"
  end

  test "parentesized with empty statements" do
    assert_parses ParenthesesNode(PARENTHESIS_LEFT("("), Statements([]), PARENTHESIS_RIGHT(")")), "(\n;\n;\n)"
  end

  test "binary !=" do
    assert_parses CallNode(expression("1"), nil, BANG_EQUAL("!="), nil, ArgumentsNode([expression("2")]), nil, nil, "!="), "1 != 2"
  end

  test "binary !~" do
    assert_parses CallNode(expression("1"), nil, BANG_TILDE("!~"), nil, ArgumentsNode([expression("2")]), nil, nil, "!~"), "1 !~ 2"
  end

  test "binary ==" do
    assert_parses CallNode(expression("1"), nil, EQUAL_EQUAL("=="), nil, ArgumentsNode([expression("2")]), nil, nil, "=="), "1 == 2"
  end

  test "binary ===" do
    assert_parses CallNode(expression("1"), nil, EQUAL_EQUAL_EQUAL("==="), nil, ArgumentsNode([expression("2")]), nil, nil, "==="), "1 === 2"
  end

  test "binary =~" do
    assert_parses CallNode(expression("1"), nil, EQUAL_TILDE("=~"), nil, ArgumentsNode([expression("2")]), nil, nil, "=~"), "1 =~ 2"
  end

  test "binary <=>" do
    assert_parses CallNode(expression("1"), nil, LESS_EQUAL_GREATER("<=>"), nil, ArgumentsNode([expression("2")]), nil, nil, "<=>"), "1 <=> 2"
  end

  test "binary >" do
    assert_parses CallNode(expression("1"), nil, GREATER(">"), nil, ArgumentsNode([expression("2")]), nil, nil, ">"), "1 > 2"
  end

  test "binary >=" do
    assert_parses CallNode(expression("1"), nil, GREATER_EQUAL(">="), nil, ArgumentsNode([expression("2")]), nil, nil, ">="), "1 >= 2"
  end

  test "binary <" do
    assert_parses CallNode(expression("1"), nil, LESS("<"), nil, ArgumentsNode([expression("2")]), nil, nil, "<"), "1 < 2"
  end

  test "binary <=" do
    assert_parses CallNode(expression("1"), nil, LESS_EQUAL("<="), nil, ArgumentsNode([expression("2")]), nil, nil, "<="), "1 <= 2"
  end

  test "binary ^" do
    assert_parses CallNode(expression("1"), nil, CARET("^"), nil, ArgumentsNode([expression("2")]), nil, nil, "^"), "1 ^ 2"
  end

  test "binary |" do
    assert_parses CallNode(expression("1"), nil, PIPE("|"), nil, ArgumentsNode([expression("2")]), nil, nil, "|"), "1 | 2"
  end

  test "binary &" do
    assert_parses CallNode(expression("1"), nil, AMPERSAND("&"), nil, ArgumentsNode([expression("2")]), nil, nil, "&"), "1 & 2"
  end

  test "binary >>" do
    assert_parses CallNode(expression("1"), nil, GREATER_GREATER(">>"), nil, ArgumentsNode([expression("2")]), nil, nil, ">>"), "1 >> 2"
  end

  test "binary <<" do
    assert_parses CallNode(expression("1"), nil, LESS_LESS("<<"), nil, ArgumentsNode([expression("2")]), nil, nil, "<<"), "1 << 2"
  end

  test "binary -" do
    assert_parses CallNode(expression("1"), nil, MINUS("-"), nil, ArgumentsNode([expression("2")]), nil, nil, "-"), "1 - 2"
  end

  test "binary +" do
    assert_parses CallNode(expression("1"), nil, PLUS("+"), nil, ArgumentsNode([expression("2")]), nil, nil, "+"), "1 + 2"
  end

  test "binary %" do
    assert_parses CallNode(expression("1"), nil, PERCENT("%"), nil, ArgumentsNode([expression("2")]), nil, nil, "%"), "1 % 2"
  end

  test "binary /" do
    assert_parses CallNode(expression("1"), nil, SLASH("/"), nil, ArgumentsNode([expression("2")]), nil, nil, "/"), "1 / 2"
  end

  test "binary / with no space" do
    expected = CallNode(
      CallNode(
        expression("1"),
        nil,
        SLASH("/"),
        nil,
        ArgumentsNode([expression("2")]),
        nil,
        nil,
        "/"
      ),
      nil,
      SLASH("/"),
      nil,
      ArgumentsNode([expression("3")]),
      nil,
      nil,
      "/"
    )

    assert_parses expected, "1/2/3"
  end

  test "binary *" do
    assert_parses CallNode(expression("1"), nil, STAR("*"), nil, ArgumentsNode([expression("2")]), nil, nil, "*"), "1 * 2"
  end

  test "binary **" do
    assert_parses CallNode(expression("1"), nil, STAR_STAR("**"), nil, ArgumentsNode([expression("2")]), nil, nil, "**"), "1**2"
  end

  test "break" do
    expected = BreakNode(nil, Location())

    assert_parses expected, "break"
  end

  test "break 1" do
    expected = BreakNode(ArgumentsNode([expression("1")]), Location())

    assert_parses expected, "break 1"
  end

  test "break 1, 2, 3" do
    expected = BreakNode(
      ArgumentsNode([
        expression("1"),
        expression("2"),
        expression("3"),
      ]),
      Location()
    )

    assert_parses expected, "break 1, 2, 3"
  end

  test "break 1, 2,\n3" do
    expected = BreakNode(
      ArgumentsNode([
        expression("1"),
        expression("2"),
        expression("3"),
      ]),
      Location()
    )

    assert_parses expected, "break 1, 2,\n3"
  end

  test "break()" do
    expected = BreakNode(
      ArgumentsNode([expression("()")]),
      Location()
    )

    assert_parses expected, "break()"
  end

  test "break(1)" do
    expected = BreakNode(
      ArgumentsNode([expression("(1)")]),
      Location()
    )

    assert_parses expected, "break(1)"
  end

  test "break (1), (2), (3)" do
    expected = BreakNode(
      ArgumentsNode([
        expression("(1)"),
        expression("(2)"),
        expression("(3)"),
      ]),
      Location()
    )

    assert_parses expected, "break (1), (2), (3)"
  end

  test "break [1, 2, 3]" do
    expected = BreakNode(
      ArgumentsNode([expression("[1, 2, 3]")]),
      Location()
    )

    assert_parses expected, "break [1, 2, 3]"
  end

  test "break multiple statements inside of parentheses" do
    expected = BreakNode(
      ArgumentsNode([
        ParenthesesNode(
          PARENTHESIS_LEFT("("),
          Statements([expression("1"), expression("2")]),
          PARENTHESIS_RIGHT(")")
        )
      ]),
      Location()
    )

    assert_parses expected, <<~RUBY
      break(
        1
        2
      )
    RUBY
  end

  test "call with ? identifier" do
    assert_parses CallNode(nil, nil, IDENTIFIER("a?"), nil, nil, nil, nil, "a?"), "a?"
  end

  test "call with ! identifier" do
    assert_parses CallNode(nil, nil, IDENTIFIER("a!"), nil, nil, nil, nil, "a!"), "a!"
  end

  test "call with ::" do
    expected = CallNode(
      expression("a"),
      COLON_COLON("::"),
      IDENTIFIER("b"),
      nil,
      nil,
      nil,
      nil,
      "b"
    )

    assert_parses expected, "a::b"
  end

  test "call with .() shorthand" do
    expected = CallNode(
      CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a"),
      DOT("."),
      NOT_PROVIDED(""),
      PARENTHESIS_LEFT("("),
      nil,
      PARENTHESIS_RIGHT(")"),
      nil,
      "call"
    )

    assert_parses expected, "a.()"
  end

  test "call with .() shorthand and arguments" do
    expected = CallNode(
      expression("a"),
      DOT("."),
      NOT_PROVIDED(""),
      PARENTHESIS_LEFT("("),
      ArgumentsNode([expression("1"), expression("2"), expression("3")]),
      PARENTHESIS_RIGHT(")"),
      nil,
      "call"
    )

    assert_parses expected, "a.(1, 2, 3)"
  end

  test "call with no parentheses or arguments" do
    expected = CallNode(
      CallNode(
        expression("a"),
        DOT("."),
        IDENTIFIER("b"),
        nil,
        nil,
        nil,
        nil,
        "b"
      ),
      DOT("."),
      IDENTIFIER("c"),
      nil,
      nil,
      nil,
      nil,
      "c"
    )

    assert_parses expected, "a.b.c"
  end

  test "call with parentheses and no arguments" do
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("a"),
      PARENTHESIS_LEFT("("),
      nil,
      PARENTHESIS_RIGHT(")"),
      nil,
      "a"
    )

    assert_parses expected, "a()"
  end

  test "call with parentheses and arguments" do
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("a"),
      PARENTHESIS_LEFT("("),
      ArgumentsNode([expression("b"), expression("c")]),
      PARENTHESIS_RIGHT(")"),
      nil,
      "a"
    )

    assert_parses expected, "a(b, c)"
  end

  test "call nested with parentheses and no arguments" do
    expected = CallNode(
      expression("a"),
      DOT("."),
      IDENTIFIER("b"),
      PARENTHESIS_LEFT("("),
      nil,
      PARENTHESIS_RIGHT(")"),
      nil,
      "b"
    )

    assert_parses expected, "a.b()"
  end

  test "call nested with parentheses and arguments" do
    expected = CallNode(
      expression("a"),
      DOT("."),
      IDENTIFIER("b"),
      PARENTHESIS_LEFT("("),
      ArgumentsNode([expression("c"), expression("d")]),
      PARENTHESIS_RIGHT(")"),
      nil,
      "b"
    )

    assert_parses expected, "a.b(c, d)"
  end

  test "call with =" do
    expected = CallNode(
      CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
      DOT("."),
      EQUAL("="),
      nil,
      ArgumentsNode([IntegerNode()]),
      nil,
      nil,
      "bar="
    )

    assert_parses expected, "foo.bar = 1"
  end

  test "safe call" do
    expected = CallNode(
      expression("a"),
      AMPERSAND_DOT("&."),
      IDENTIFIER("b"),
      nil,
      nil,
      nil,
      nil,
      "b"
    )

    assert_parses expected, "a&.b"
  end

  test "safe call with &.() shorthand and no arguments" do
    expected = CallNode(
      expression("a"),
      AMPERSAND_DOT("&."),
      NOT_PROVIDED(""),
      PARENTHESIS_LEFT("("),
      nil,
      PARENTHESIS_RIGHT(")"),
      nil,
      "call"
    )

    assert_parses expected, "a&.()"
  end

  test "safe call with parentheses and no arguments" do
    expected = CallNode(
      expression("a"),
      AMPERSAND_DOT("&."),
      IDENTIFIER("b"),
      PARENTHESIS_LEFT("("),
      nil,
      PARENTHESIS_RIGHT(")"),
      nil,
      "b"
    )

    assert_parses expected, "a&.b()"
  end

  test "safe call with parentheses and arguments" do
    expected = CallNode(
      expression("a"),
      AMPERSAND_DOT("&."),
      IDENTIFIER("b"),
      PARENTHESIS_LEFT("("),
      ArgumentsNode([expression("c")]),
      PARENTHESIS_RIGHT(")"),
      nil,
      "b"
    )

    assert_parses expected, "a&.b(c)"
  end

  test "call without parentheses" do
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("a"),
      nil,
      ArgumentsNode([expression("b"), expression("c")]),
      nil,
      nil,
      "a"
    )

    assert_parses expected, "a b, c"
  end

  test "call without parentheses with a receiver" do
    expected = CallNode(
      expression("a"),
      DOT("."),
      IDENTIFIER("b"),
      nil,
      ArgumentsNode([expression("c"), expression("d")]),
      nil,
      nil,
      "b"
    )

    assert_parses expected, "a.b c, d"
  end

  test "call with splat arguments" do
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("a"),
      PARENTHESIS_LEFT("("),
      ArgumentsNode(
        [StarNode(
           STAR("*"),
           CallNode(nil, nil, IDENTIFIER("args"), nil, nil, nil, nil, "args")
         )]
      ),
      PARENTHESIS_RIGHT(")"),
      nil,
      "a"
    )

    assert_parses expected, "a(*args)"
  end

  test "call with double splat arguments" do
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("a"),
      PARENTHESIS_LEFT("("),
      ArgumentsNode(
        [KeywordStarNode(
           STAR_STAR("**"),
           expression("kwargs")
         )]
      ),
      PARENTHESIS_RIGHT(")"),
      nil,
      "a"
    )

    assert_parses expected, "a(**kwargs)"
  end

  test "call with block arguments" do
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("a"),
      PARENTHESIS_LEFT("("),
      ArgumentsNode(
        [BlockArgumentNode(
           AMPERSAND("&"),
           expression("block")
         )]
      ),
      PARENTHESIS_RIGHT(")"),
      nil,
      "a"
    )

    assert_parses expected, "a(&block)"
  end

  test "call with arg followed by kwarg" do
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("some_func"),
      nil,
      ArgumentsNode(
        [IntegerNode(),
         HashNode(
           nil,
           [AssocNode(
              SymbolNode(nil, LABEL("kwarg"), LABEL_END(":")),
              IntegerNode(),
              nil
            )],
           nil
         )]
      ),
      nil,
      nil,
      "some_func"
    )

    assert_parses expected, "some_func 1, kwarg: 2"
  end

  test "character literal" do
    assert_parses StringNode(STRING_BEGIN("?"), STRING_CONTENT("a"), nil, "a"), "?a"
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
          IntegerNode()
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
          IntegerNode()
        )
      ]),
      KEYWORD_END("end")
    )

    assert_parses expected, "class A < B a = 1 end"
  end

  test "class variable read" do
    assert_parses ClassVariableReadNode(), "@@abc"
  end

  test "class variable write" do
    assert_parses ClassVariableWriteNode(Location(), expression("1"), Location()), "@@abc = 1"
  end

  test "constant path" do
    assert_parses ConstantPathNode(ConstantRead(CONSTANT("A")), COLON_COLON("::"), ConstantRead(CONSTANT("B"))), "A::B"
  end

  test "constant path with multiple levels" do
    expected = ConstantPathNode(
      ConstantPathNode(
        ConstantRead(CONSTANT("A")),
        COLON_COLON("::"),
        ConstantRead(CONSTANT("B"))
      ),
      COLON_COLON("::"),
      ConstantRead(CONSTANT("C"))
    )

    assert_parses expected, "A::B::C"
  end

  test "constant path with variable parent" do
    expected = ConstantPathNode(
      CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a"),
      COLON_COLON("::"),
      ConstantRead(CONSTANT("B"))
    )

    assert_parses expected, "a::B"
  end

  test "constant read" do
    assert_parses ConstantRead(CONSTANT("ABC")), "ABC"
  end

  test "top-level constant read" do
    assert_parses ConstantPathNode(nil, COLON_COLON("::"), ConstantRead(CONSTANT("A"))), "::A"
  end

  test "top-level constant assignment" do
    expected = ConstantPathWriteNode(
      ConstantPathNode(nil, COLON_COLON("::"), ConstantRead(CONSTANT("A"))),
      EQUAL("="),
      IntegerNode()
    )

    assert_parses expected, "::A = 1"
  end

  test "top-level constant path read" do
    expected = ConstantPathNode(
      ConstantPathNode(nil, COLON_COLON("::"), ConstantRead(CONSTANT("A"))),
      COLON_COLON("::"),
      ConstantRead(CONSTANT("B"))
    )

    assert_parses expected, "::A::B"
  end

  test "top-level constant path assignment" do
    expected = ConstantPathWriteNode(
      ConstantPathNode(
        ConstantPathNode(nil, COLON_COLON("::"), ConstantRead(CONSTANT("A"))),
        COLON_COLON("::"),
        ConstantRead(CONSTANT("B"))
      ),
      EQUAL("="),
      IntegerNode()
    )

    assert_parses expected, "::A::B = 1"
  end

  test "top level constant with method inside" do
    expected = CallNode(
      ConstantPathNode(nil, COLON_COLON("::"), ConstantRead(CONSTANT("A"))),
      COLON_COLON("::"),
      IDENTIFIER("foo"),
      nil,
      nil,
      nil,
      nil,
      "foo"
    )

    assert_parses expected, "::A::foo"
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
      IDENTIFIER("a"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def a\nend"
  end

  test "def with parentheses" do
    expected = DefNode(
      IDENTIFIER("a"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      Location(),
      Location(),
      nil,
      Location()
    )

    assert_parses expected, "def a()\nend"
  end

  test "def with scope" do
    expected = DefNode(
      IDENTIFIER("a"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([expression("b = 1")]),
      Scope([IDENTIFIER("b")]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def a\nb = 1\nend"
  end

  test "def with required parameter" do
    expected = DefNode(
      IDENTIFIER("a"),
      nil,
      ParametersNode(
        [RequiredParameterNode(IDENTIFIER("b"))],
        [],
        nil,
        [],
        nil,
        nil
      ),
      Statements([]),
      Scope([IDENTIFIER("b")]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def a b\nend"
  end

  test "def with keyword parameter (no parenthesis)" do
    expected = DefNode(
      IDENTIFIER("a"),
      nil,
      ParametersNode(
        [],
        [],
        nil,
        [KeywordParameterNode(LABEL("b:"), nil)],
        nil,
        nil
      ),
      Statements([]),
      Scope([LABEL("b")]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def a b:\nend"
  end

  test "def with keyword parameter (parenthesis)" do
    expected = DefNode(
      IDENTIFIER("a"),
      nil,
      ParametersNode(
        [],
        [],
        nil,
        [KeywordParameterNode(LABEL("b:"), nil)],
        nil,
        nil
      ),
      Statements([]),
      Scope([LABEL("b")]),
      Location(),
      nil,
      Location(),
      Location(),
      nil,
      Location()
    )

    assert_parses expected, "def a(b:)\nend"
  end

  test "def with multiple required parameters" do
    expected = DefNode(
      IDENTIFIER("a"),
      nil,
      ParametersNode(
        [
          RequiredParameterNode(IDENTIFIER("b")),
          RequiredParameterNode(IDENTIFIER("c")),
          RequiredParameterNode(IDENTIFIER("d"))
        ],
        [],
        nil,
        [],
        nil,
        nil
      ),
      Statements([]),
      Scope([IDENTIFIER("b"), IDENTIFIER("c"), IDENTIFIER("d")]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def a b, c, d\nend"
  end

  test "def with required and optional parameters" do
    expected = DefNode(
      IDENTIFIER("a"),
      nil,
      ParametersNode(
        [RequiredParameterNode(IDENTIFIER("b"))],
        [OptionalParameterNode(IDENTIFIER("c"), EQUAL("="), expression("2"))],
        nil,
        [],
        nil,
        nil
      ),
      Statements([]),
      Scope([IDENTIFIER("b"), IDENTIFIER("c")]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def a b, c = 2\nend"
  end

  test "def with optional parameters" do
    expected = DefNode(
      IDENTIFIER("a"),
      nil,
      ParametersNode(
        [],
        [
          OptionalParameterNode(IDENTIFIER("b"), EQUAL("="), expression("1")),
          OptionalParameterNode(IDENTIFIER("c"), EQUAL("="), expression("2"))
        ],
        nil,
        [],
        nil,
        nil
      ),
      Statements([]),
      Scope([IDENTIFIER("b"), IDENTIFIER("c")]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def a b = 1, c = 2\nend"
  end

  test "def with optional keyword parameters (no parenthesis)" do
    expected = DefNode(
      IDENTIFIER("a"),
      nil,
      ParametersNode(
        [],
        [KeywordParameterNode(LABEL("c:"), expression("1"))],
        nil,
        [KeywordParameterNode(LABEL("b:"), nil)],
        nil,
        nil
      ),
      Statements([]),
      Scope([LABEL("b"), LABEL("c")]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def a b:, c: 1 \nend"
  end

  test "def with optional keyword parameters (parenthesis)" do
    expected = DefNode(
      IDENTIFIER("a"),
      nil,
      ParametersNode(
        [],
        [KeywordParameterNode(LABEL("c:"), expression("1"))],
        nil,
        [KeywordParameterNode(LABEL("b:"), nil)],
        nil,
        nil
      ),
      Statements([]),
      Scope([LABEL("b"), LABEL("c")]),
      Location(),
      nil,
      Location(),
      Location(),
      nil,
      Location()
    )

    assert_parses expected, "def a(b:, c: 1)\nend"
  end

  test "def with optional keyword parameters and line break" do
    expected = DefNode(
      IDENTIFIER("a"),
      nil,
      ParametersNode(
        [],
        [KeywordParameterNode(LABEL("b:"), expression("1"))],
        nil,
        [KeywordParameterNode(LABEL("c:"), nil)],
        nil,
        nil
      ),
      Statements([]),
      Scope([LABEL("b"), LABEL("c")]),
      Location(),
      nil,
      Location(),
      Location(),
      nil,
      Location()
    )

    assert_parses expected, <<~RUBY
      def a(b:
        1, c:)
      end
    RUBY
  end

  test "def with rest parameter" do
    expected = DefNode(
      IDENTIFIER("a"),
      nil,
      ParametersNode(
        [],
        [],
        RestParameterNode(STAR("*"), IDENTIFIER("b")),
        [],
        nil,
        nil
      ),
      Statements([]),
      Scope([IDENTIFIER("b")]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def a *b\nend"
  end

  test "def with rest parameter without name" do
    expected = DefNode(
      IDENTIFIER("a"),
      nil,
      ParametersNode([], [], RestParameterNode(STAR("*"), nil), [], nil, nil),
      Statements([]),
      Scope([STAR("*")]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def a *\nend"
  end

  test "def with keyword rest parameter" do
    expected = DefNode(
      IDENTIFIER("a"),
      nil,
      ParametersNode(
        [],
        [],
        nil,
        [],
        KeywordRestParameterNode(STAR_STAR("**"), IDENTIFIER("b")),
        nil
      ),
      Statements([]),
      Scope([IDENTIFIER("b")]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def a **b\nend"
  end

  test "def with keyword rest parameter without name" do
    expected = DefNode(
      IDENTIFIER("a"),
      nil,
      ParametersNode(
        [],
        [],
        nil,
        [],
        KeywordRestParameterNode(STAR_STAR("**"), nil),
        nil
      ),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def a **\nend"
  end

  test "def with forwarding parameter" do
    expected = DefNode(
      IDENTIFIER("a"),
      nil,
      ParametersNode([], [], nil, [], ForwardingParameterNode(), nil),
      Statements([]),
      Scope([DOT_DOT_DOT("...")]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def a ...\nend"
  end

  test "def with block parameter" do
    expected = DefNode(
      IDENTIFIER("a"),
      nil,
      ParametersNode(
        [],
        [],
        nil,
        [],
        nil,
        BlockParameterNode(IDENTIFIER("b"), Location())
      ),
      Statements([]),
      Scope([IDENTIFIER("b")]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def a &b\nend"
  end

  test "def with block parameter without name" do
    expected = DefNode(
      IDENTIFIER("a"),
      nil,
      ParametersNode(
        [],
        [],
        nil,
        [],
        nil,
        BlockParameterNode(nil, Location())
      ),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def a &\nend"
  end

  test "def with **nil" do
    expected = DefNode(
      IDENTIFIER("m"),
      nil,
      ParametersNode(
        [RequiredParameterNode(IDENTIFIER("a"))],
        [],
        nil,
        [KeywordParameterNode(LABEL("b:"), nil)],
        NoKeywordsParameterNode(Location(), Location()),
        nil
      ),
      Statements([]),
      Scope([IDENTIFIER("a"), LABEL("b")]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def m a, b:, **nil\nend"
  end

  test "method call with label keyword args" do
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("hi"),
      nil,
      ArgumentsNode(
        [
          HashNode(
            nil,
            [
              AssocNode(
                SymbolNode(nil, LABEL("there"), LABEL_END(":")),
                SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("friend"), nil),
                nil
              )
            ],
            nil
          )
        ]
      ),
      nil,
      nil,
      "hi"
    )

    assert_parses expected, "hi there: :friend"
  end

  test "method call with rocket keyword args" do
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("hi"),
      nil,
      ArgumentsNode(
        [
          AssocNode(
            SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("there"), nil),
            SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("friend"), nil),
            EQUAL_GREATER("=>")
          )
        ]
      ),
      nil,
      nil,
      "hi"
    )
    assert_parses expected, "hi :there => :friend"
  end

  test "method call with mixed format keyword args" do
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("hi"),
      nil,
      ArgumentsNode(
        [
          HashNode(
            nil,
            [
              AssocNode(
                SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("there"), nil),
                SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("friend"), nil),
                EQUAL_GREATER("=>")
              ),
              AssocSplatNode(
                HashNode(BRACE_LEFT("{"), [], BRACE_RIGHT("}")),
                Location()
              ),
              AssocNode(
                SymbolNode(nil, LABEL("whatup"), LABEL_END(":")),
                SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("dog"), nil),
                nil
              )
            ],
            nil
          )
        ]
      ),
      nil,
      nil,
      "hi"
    )

    assert_parses expected, "hi :there => :friend, **{}, whatup: :dog"
  end

  test "method call with parens + keyword args" do
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("hi"),
      PARENTHESIS_LEFT("("),
      ArgumentsNode(
        [
          HashNode(
            nil,
            [
              AssocNode(
                SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("there"), nil),
                SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("friend"), nil),
                EQUAL_GREATER("=>")
              ),
              AssocSplatNode(
                HashNode(BRACE_LEFT("{"), [], BRACE_RIGHT("}")),
                Location()
              ),
              AssocNode(
                SymbolNode(nil, LABEL("whatup"), LABEL_END(":")),
                SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("dog"), nil),
                nil
              )
            ],
            nil
          )
        ]
      ),
      PARENTHESIS_RIGHT(")"),
      nil,
      "hi"
    )

    assert_parses expected, "hi(:there => :friend, **{}, whatup: :dog)"
  end

  test "method call with explicit hash" do
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("hi"),
      nil,
      ArgumentsNode(
        [
          IntegerNode(),
          HashNode(
            BRACE_LEFT("{"),
            [
              AssocNode(
                SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("there"), nil),
                SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("friend"), nil),
                EQUAL_GREATER("=>")
              ),
              AssocSplatNode(
                HashNode(BRACE_LEFT("{"), [], BRACE_RIGHT("}")),
                Location()
              ),
              AssocNode(
                SymbolNode(nil, LABEL("whatup"), LABEL_END(":")),
                SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("dog"), nil),
                nil
              )
            ],
            BRACE_RIGHT("}")
          )
        ]
      ),
      nil,
      nil,
      "hi"
    )

    assert_parses expected, "hi 123, { :there => :friend, **{}, whatup: :dog }"
  end

  test "method call with ..." do
    expected = DefNode(
      IDENTIFIER("a"),
      nil,
      ParametersNode([], [], nil, [], ForwardingParameterNode(), nil),
      Statements(
        [
          CallNode(
            nil,
            nil,
            IDENTIFIER("b"),
            PARENTHESIS_LEFT("("),
            ArgumentsNode([ForwardingArgumentsNode()]),
            PARENTHESIS_RIGHT(")"),
            nil,
            "b"
          )
        ]
      ),
      Scope([DOT_DOT_DOT("...")]),
      Location(),
      nil,
      Location(),
      Location(),
      nil,
      Location()
    )

    assert_parses expected, "def a(...); b(...); end"
  end

  test "method call with ... after args" do
    expected = DefNode(
      IDENTIFIER("a"),
      nil,
      ParametersNode([], [], nil, [], ForwardingParameterNode(), nil),
      Statements(
        [
          CallNode(
            nil,
            nil,
            IDENTIFIER("b"),
            PARENTHESIS_LEFT("("),
            ArgumentsNode(
              [IntegerNode(), IntegerNode(), ForwardingArgumentsNode()]
            ),
            PARENTHESIS_RIGHT(")"),
            nil,
            "b"
          )
        ]
      ),
      Scope([DOT_DOT_DOT("...")]),
      Location(),
      nil,
      Location(),
      Location(),
      nil,
      Location()
    )

    assert_parses expected, "def a(...); b(1, 2, ...); end"
  end

  test "method call with interpolated ..." do
    expected = DefNode(
      IDENTIFIER("a"),
      nil,
      ParametersNode([], [], nil, [], ForwardingParameterNode(), nil),
      Statements(
        [
          InterpolatedStringNode(
            STRING_BEGIN("\""),
            [
              StringNode(nil, STRING_CONTENT("foo"), nil, "foo"),
              StringInterpolatedNode(
                EMBEXPR_BEGIN("\#{"),
                Statements(
                  [
                    CallNode(
                      nil,
                      nil,
                      IDENTIFIER("b"),
                      PARENTHESIS_LEFT("("),
                      ArgumentsNode([ForwardingArgumentsNode()]),
                      PARENTHESIS_RIGHT(")"),
                      nil,
                      "b"
                    )
                  ]
                ),
                EMBEXPR_END("}")
              )
            ],
            STRING_END("\"")
          )
        ]
      ),
      Scope([DOT_DOT_DOT("...")]),
      Location(),
      nil,
      Location(),
      Location(),
      nil,
      Location()
    )

    assert_parses expected, "def a(...); \"foo\#{b(...)}\"; end"
  end

  test "method call with *rest" do
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("foo"),
      PARENTHESIS_LEFT("("),
      ArgumentsNode(
        [StarNode(
           STAR("*"),
           CallNode(nil, nil, IDENTIFIER("rest"), nil, nil, nil, nil, "rest")
         )]
      ),
      PARENTHESIS_RIGHT(")"),
      nil,
      "foo"
    )
    assert_parses expected, "foo(*rest)"
  end

  test "method call with *" do
    expected = DefNode(
      IDENTIFIER("a"),
      nil,
      ParametersNode([], [], RestParameterNode(STAR("*"), nil), [], nil, nil),
      Statements(
        [
          CallNode(
            nil,
            nil,
            IDENTIFIER("b"),
            PARENTHESIS_LEFT("("),
            ArgumentsNode([StarNode(STAR("*"), nil)]),
            PARENTHESIS_RIGHT(")"),
            nil,
            "b"
          )
        ]
      ),
      Scope([STAR("*")]),
      Location(),
      nil,
      Location(),
      Location(),
      nil,
      Location()
    )

    assert_parses expected, "def a(*); b(*); end"
  end

  test "method call in multiple lines" do
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("foo"),
      PARENTHESIS_LEFT("("),
      ArgumentsNode(
        [SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("a"), nil),
         SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("b"), nil)]
      ),
      PARENTHESIS_RIGHT(")"),
      nil,
      "foo"
    )

    assert_parses expected, "foo(:a,\n\n\t\s:b\n)"
  end

  test "def with identifier receiver" do
    expected = DefNode(
      IDENTIFIER("b"),
      expression("a"),
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      Location(),
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def a.b\nend"
  end

  test "def - with identifier receiver" do
    expected = DefNode(
      MINUS("-"),
      expression("a"),
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      Location(),
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def a.-;end"
  end

  test "def with local variable identifier receiver" do
    expected = DefNode(
      IDENTIFIER("a"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "a = 1; def a\nend"
  end

  test "def with colon_colon nil receiver" do
    expected = DefNode(
      IDENTIFIER("a"),
      NilNode(),
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      Location(),
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def nil::a\nend"
  end

  test "def with nil receiver" do
    expected = DefNode(
      IDENTIFIER("a"),
      NilNode(),
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      Location(),
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def nil.a\nend"
  end

  test "def with self receiver" do
    expected = DefNode(
      IDENTIFIER("a"),
      SelfNode(),
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      Location(),
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def self.a\nend"
  end

  test "def with true receiver" do
    expected = DefNode(
      IDENTIFIER("a"),
      TrueNode(),
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      Location(),
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def true.a\nend"
  end

  test "def with false receiver" do
    expected = DefNode(
      IDENTIFIER("a"),
      FalseNode(),
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      Location(),
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def false.a\nend"
  end

  test "def with constant receiver" do
    expected = DefNode(
      IDENTIFIER("a"),
      ConstantRead(CONSTANT("Const")),
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      Location(),
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "Const = 1; def Const.a\nend"
  end

  test "def with instance variable receiver" do
    expected = DefNode(
      IDENTIFIER("a"),
      InstanceVariableReadNode(),
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      Location(),
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def @var.a\nend"
  end

  test "def with class variable receiver" do
    expected = DefNode(
      IDENTIFIER("a"),
      ClassVariableReadNode(),
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      Location(),
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def @@var.a\nend"
  end

  test "def with global variable receiver" do
    expected = DefNode(
      IDENTIFIER("a"),
      GlobalVariableRead(GLOBAL_VARIABLE("$var")),
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      Location(),
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def $var.a\nend"
  end

  test "def with __FILE__ receiver" do
    expected = DefNode(
      IDENTIFIER("a"),
      SourceFileNode(),
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      Location(),
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def __FILE__.a\nend"
  end

  test "def with __LINE__ receiver" do
    expected = DefNode(
      IDENTIFIER("a"),
      SourceLineNode(),
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      Location(),
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def __LINE__.a\nend"
  end

  test "def with __ENCODING__ receiver" do
    expected = DefNode(
      IDENTIFIER("a"),
      SourceEncodingNode(),
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      Location(),
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def __ENCODING__.a\nend"
  end

  test "def with expression as receiver" do
    expected = DefNode(
      IDENTIFIER("a"),
      ParenthesesNode(
        PARENTHESIS_LEFT("("),
        CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b"),
        PARENTHESIS_RIGHT(")")
      ),
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      Location(),
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def (b).a\nend"
  end

  test "def with assignment expression as receiver" do
    expected = DefNode(
      IDENTIFIER("a"),
      ParenthesesNode(
        PARENTHESIS_LEFT("("),
        LocalVariableWrite(
          IDENTIFIER("c"),
          EQUAL("="),
          CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")
        ),
        PARENTHESIS_RIGHT(")")
      ),
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      Location(),
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def (c = b).a\nend"
  end

  test "def with literal expression as receiver" do
    expected = DefNode(
      IDENTIFIER("a"),
      ParenthesesNode(
        PARENTHESIS_LEFT("("),
        IntegerNode(),
        PARENTHESIS_RIGHT(")")
      ),
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      Location(),
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def (1).a\nend"
  end

  test "def with expression as reciever and colon colon operator" do
    expected = DefNode(
      IDENTIFIER("b"),
      ParenthesesNode(
        PARENTHESIS_LEFT("("),
        CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a"),
        PARENTHESIS_RIGHT(")")
      ),
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      Location(),
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def (a)::b\nend"
  end

  test "defined? without parentheses" do
    assert_parses DefinedNode(nil, expression("1"), nil, Location()), "defined? 1"
  end

  test "defined? with parentheses" do
    assert_parses DefinedNode(PARENTHESIS_LEFT("("), expression("1"), PARENTHESIS_RIGHT(")"), Location()), "defined?(1)"
  end

  test "defined? binding power" do
    expected =
      AndNode(
        DefinedNode(nil, expression("1"), nil, Location()),
        DefinedNode(nil, expression("2"), nil, Location()),
        KEYWORD_AND("and")
      )

    assert_parses expected, "defined? 1 and defined? 2"
  end

  test "not without parentheses" do
    expected = CallNode(
      CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
      nil,
      KEYWORD_NOT("not"),
      nil,
      nil,
      nil,
      nil,
      "!"
    )

    assert_parses expected, "not foo"
  end

  test "not with parentheses" do
    expected = CallNode(
      CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
      nil,
      KEYWORD_NOT("not"),
      PARENTHESIS_LEFT("("),
      nil,
      PARENTHESIS_RIGHT(")"),
      nil,
      "!"
    )

    assert_parses expected, "not(foo)"
  end

  test "not binding power" do
    expected =
      AndNode(
        CallNode(
          CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
          nil,
          KEYWORD_NOT("not"),
          nil,
          nil,
          nil,
          nil,
          "!"
        ),
        CallNode(
          CallNode(nil, nil, IDENTIFIER("bar"), nil, nil, nil, nil, "bar"),
          nil,
          KEYWORD_NOT("not"),
          nil,
          nil,
          nil,
          nil,
          "!"
        ),
        KEYWORD_AND("and")
      )

    assert_parses expected, "not foo and not bar"
  end

  test "false" do
    assert_parses FalseNode(), "false"
  end

  test "float" do
    assert_parses FloatNode(), "1.0"
  end

  test "global variable read" do
    assert_parses GlobalVariableRead(GLOBAL_VARIABLE("$abc")), "$abc"
  end

  test "global variable write" do
    assert_parses GlobalVariableWrite(GLOBAL_VARIABLE("$abc"), EQUAL("="), expression("1")), "$abc = 1"
  end

  test "heredocs" do
    expected = HeredocNode(
      HEREDOC_START("<<-EOF"),
      [StringNode(nil, STRING_CONTENT("  a\n"), nil, "  a\n")],
      HEREDOC_END("EOF\n"),
      0
    )

    assert_parses expected, "<<-EOF\n  a\nEOF\n"
  end

  test "heredocs with multiple lines" do
    expected = HeredocNode(
      HEREDOC_START("<<-EOF"),
      [StringNode(nil, STRING_CONTENT("  a\n  b\n"), nil, "  a\n  b\n")],
      HEREDOC_END("EOF\n"),
      0
    )

    assert_parses expected, "<<-EOF\n  a\n  b\nEOF\n"
  end

  test "heredocs with single quotes" do
    expected = HeredocNode(
      HEREDOC_START("<<-'EOF'"),
      [StringNode(nil, STRING_CONTENT("  a \#{1}\n"), nil, "  a \#{1}\n")],
      HEREDOC_END("EOF\n"),
      0
    )

    assert_parses expected, "<<-'EOF'\n  a \#{1}\nEOF\n"
  end

  test "heredocs with double quotes" do
    expected = HeredocNode(
      HEREDOC_START("<<-\"EOF\""),
      [
        StringNode(nil, STRING_CONTENT("  a\n"), nil, "  a\n"),
        StringInterpolatedNode(
          EMBEXPR_BEGIN("\#{"),
          Statements([CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]),
          EMBEXPR_END("}")
        ),
        StringNode(nil, STRING_CONTENT("\n"), nil, "\n")
      ],
      HEREDOC_END("EOF\n"),
      0
    )

    assert_parses expected, "<<-\"EOF\"\n  a\n\#{b}\nEOF\n"
  end

  test "heredocs with backticks" do
    expected = InterpolatedXStringNode(
      HEREDOC_START("<<-`EOF`"),
      [
        StringNode(nil, STRING_CONTENT("  a\n"), nil, "  a\n"),
        StringInterpolatedNode(
          EMBEXPR_BEGIN("\#{"),
          Statements([CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]),
          EMBEXPR_END("}")
        ),
        StringNode(nil, STRING_CONTENT("\n"), nil, "\n")
      ],
      HEREDOC_END("EOF\n")
    )

    assert_parses expected, "<<-`EOF`\n  a\n\#{b}\nEOF\n"
  end

  test "heredocs with dashes" do
    expected = HeredocNode(
      HEREDOC_START("<<-EOF"),
      [StringNode(nil, STRING_CONTENT("  a\n  b\n"), nil, "  a\n  b\n")],
      HEREDOC_END("  EOF\n"),
      0
    )

    assert_parses expected, "<<-EOF\n  a\n  b\n  EOF\n"
  end

  test "heredocs with interpolation" do
    expected = HeredocNode(
      HEREDOC_START("<<-EOF"),
      [
        StringNode(nil, STRING_CONTENT("  a\n"), nil, "  a\n"),
        StringInterpolatedNode(
          EMBEXPR_BEGIN("\#{"),
          Statements([CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]),
          EMBEXPR_END("}")
        ),
        StringNode(nil, STRING_CONTENT("\n"), nil, "\n")
      ],
      HEREDOC_END("EOF\n"),
      0
    )

    assert_parses expected, "<<-EOF\n  a\n\#{b}\nEOF\n"
  end

  test "heredocs on the same line" do
    expected = CallNode(
      HeredocNode(
        HEREDOC_START("<<-FIRST"),
        [StringNode(nil, STRING_CONTENT("  a\n"), nil, "  a\n")],
        HEREDOC_END("FIRST\n"),
        0
      ),
      nil,
      PLUS("+"),
      nil,
      ArgumentsNode(
        [HeredocNode(
           HEREDOC_START("<<-SECOND"),
           [StringNode(nil, STRING_CONTENT("  b\n"), nil, "  b\n")],
           HEREDOC_END("SECOND\n"),
           0
         )]
      ),
      nil,
      nil,
      "+"
    )

    assert_parses expected, "<<-FIRST + <<-SECOND\n  a\nFIRST\n  b\nSECOND\n"
  end

  test "identifier" do
    assert_parses CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a"), "a"
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

  test "if elsif" do
    expected = IfNode(
      KEYWORD_IF("if"),
      TrueNode(),
      Statements([TrueNode()]),
      IfNode(
        KEYWORD_ELSIF("elsif"),
        FalseNode(),
        Statements([FalseNode()]),
        IfNode(
          KEYWORD_ELSIF("elsif"),
          NilNode(),
          Statements([NilNode()]),
          ElseNode(
            KEYWORD_ELSE("else"),
            Statements([SelfNode()]),
            KEYWORD_END("end")
          ),
          nil
        ),
        nil
      ),
      KEYWORD_END("end")
    )

    assert_parses expected, "if true then true elsif false then false elsif nil then nil else self end"
  end

  test "imaginary" do
    assert_parses ImaginaryNode(), "1i"
  end

  test "instance variable read" do
    assert_parses InstanceVariableReadNode(), "@abc"
  end

  test "instance variable write" do
    assert_parses InstanceVariableWriteNode(Location(), expression("1"), Location()), "@abc = 1"
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
          IntegerNode()
        )
      ]),
      KEYWORD_END("end")
    )

    assert_parses expected, "module A a = 1 end"
  end

  test "next" do
    assert_parses NextNode(nil, Location()), "next"
  end

  test "next 1" do
    expected = NextNode(ArgumentsNode([expression("1")]), Location())

    assert_parses expected, "next 1"
  end

  test "next 1, 2, 3" do
    expected = NextNode(
      ArgumentsNode([expression("1"), expression("2"), expression("3")]),
      Location()
    )

    assert_parses expected, "next 1, 2, 3"
  end

  test "next 1, 2,\n3" do
    expected = NextNode(
      ArgumentsNode([expression("1"), expression("2"), expression("3")]),
      Location()
    )

    assert_parses expected, "next 1, 2,\n3"
  end

  test "next()" do
    expected = NextNode(ArgumentsNode([expression("()")]), Location())

    assert_parses expected, "next()"
  end

  test "next(1)" do
    expected = NextNode(ArgumentsNode([expression("(1)"),]), Location())

    assert_parses expected, "next(1)"
  end

  test "next (1), (2), (3)" do
    expected = NextNode(
      ArgumentsNode([
        expression("(1)"),
        expression("(2)"),
        expression("(3)"),
      ]),
      Location()
    )

    assert_parses expected, "next (1), (2), (3)"
  end

  test "next [1, 2, 3]" do
    expected = NextNode(
      ArgumentsNode([expression("[1, 2, 3]")]),
      Location()
    )

    assert_parses expected, "next [1, 2, 3]"
  end

  test "next multiple statements inside of parentheses" do
    expected = NextNode(
      ArgumentsNode([
        ParenthesesNode(
          PARENTHESIS_LEFT("("),
          Statements([expression("1"), expression("2")]),
          PARENTHESIS_RIGHT(")")
        )
      ]),
      Location()
    )

    assert_parses expected, <<~RUBY
      next(
        1
        2
      )
    RUBY
  end

  test "nil" do
    assert_parses NilNode(), "nil"
  end

  test "or keyword" do
    assert_parses OrNode(expression("1"), KEYWORD_OR("or"), expression("2")), "1 or 2"
  end

  test "or operator" do
    assert_parses OrNode(expression("1"), PIPE_PIPE("||"), expression("2")), "1 || 2"
  end

  test "operator and assignment" do
    assert_parses OperatorAndAssignmentNode(expression("a"), expression("b"), Location()), "a &&= b"
  end

  test "operator or assignment" do
    assert_parses OperatorOrAssignmentNode(expression("a"), PIPE_PIPE_EQUAL("||="), expression("b")), "a ||= b"
  end

  test "operator assignment" do
    assert_parses OperatorAssignmentNode(expression("a"), PLUS_EQUAL("+="), expression("b")), "a += b"
  end

  test "post execution" do
    assert_parses PostExecutionNode(Statements([expression("1")]), Location(), Location(), Location()), "END { 1 }"
  end

  test "pre execution" do
    assert_parses PreExecutionNode(Statements([expression("1")]), Location(), Location(), Location()), "BEGIN { 1 }"
  end

  test "range inclusive" do
    assert_parses RangeNode(expression("1"), DOT_DOT(".."), expression("2")), "1..2"
  end

  test "range exclusive" do
    assert_parses RangeNode(expression("1"), DOT_DOT_DOT("..."), expression("2")), "1...2"
  end

  test "rational" do
    assert_parses RationalNode(), "1r"
  end

  test "redo" do
    assert_parses RedoNode(), "redo"
  end

  test "xstring, `, no interpolation" do
    assert_parses XStringNode(BACKTICK("`"), STRING_CONTENT("foo"), STRING_END("`")), "`foo`"
  end

  test "xstring with interpolation" do
    expected = InterpolatedXStringNode(
      BACKTICK("`"),
      [
        StringNode(nil, STRING_CONTENT("foo "), nil, "foo "),
        StringInterpolatedNode(
          EMBEXPR_BEGIN("\#{"),
          Statements([expression("bar")]),
          EMBEXPR_END("}")
        ),
       StringNode(nil, STRING_CONTENT(" baz"), nil, " baz")
      ],
      STRING_END("`")
    )

    assert_parses expected, "`foo \#{bar} baz`"
  end

  test "xstring with %x" do
    assert_parses XStringNode(PERCENT_LOWER_X("%x["), STRING_CONTENT("foo"), STRING_END("]")), "%x[foo]"
  end

  test "regular expression, /, no interpolation" do
    assert_parses RegularExpressionNode(REGEXP_BEGIN("/"), STRING_CONTENT("abc"), REGEXP_END("/i")), "/abc/i"
  end

  test "regular expression with interpolation" do
    expected = InterpolatedRegularExpressionNode(
      REGEXP_BEGIN("/"),
      [
        StringNode(nil, STRING_CONTENT("aaa "), nil, "aaa "),
        StringInterpolatedNode(
          EMBEXPR_BEGIN("\#{"),
          Statements([expression("bbb")]),
          EMBEXPR_END("}")
        ),
       StringNode(nil, STRING_CONTENT(" ccc"), nil, " ccc")
      ],
      REGEXP_END("/")
    )

    assert_parses expected, "/aaa \#{bbb} ccc/"
  end

  test "regular expression with interpolated variable" do
    expected = InterpolatedRegularExpressionNode(
      REGEXP_BEGIN("/"),
      [
        StringNode(nil, STRING_CONTENT("aaa "), nil, "aaa "),
        expression("$bbb")
      ],
      REGEXP_END("/")
    )

    assert_parses expected, "/aaa \#$bbb/"
  end

  test "regular expression with %r" do
    assert_parses RegularExpressionNode(REGEXP_BEGIN("%r{"), STRING_CONTENT("abc"), REGEXP_END("}i")), "%r{abc}i"
  end

  test "regular expression with named capture groups" do
    expected = ArrayNode(
      [
        CallNode(
          RegularExpressionNode(
            REGEXP_BEGIN("/"),
            STRING_CONTENT("(?<foo>bar)"),
            REGEXP_END("/")
          ),
          nil,
          EQUAL_TILDE("=~"),
          nil,
          ArgumentsNode([expression("baz")]),
          nil,
          nil,
          "=~"
        ),
        # This is the important bit of the test here, that this is a local
        # variable and not a method call.
        LocalVariableRead(IDENTIFIER("foo"))
      ],
      BRACKET_LEFT("["),
      BRACKET_RIGHT("]")
    )

    assert_parses expected, "[/(?<foo>bar)/ =~ baz, foo]"
  end

  test "retry" do
    assert_parses RetryNode(), "retry"
  end

  test "return" do
    expected = ReturnNode(
      KEYWORD_RETURN("return"),
      nil,
    )

    assert_parses expected, "return"
  end

  test "return 1" do
    expected = ReturnNode(
      KEYWORD_RETURN("return"),
      ArgumentsNode([
        expression("1"),
      ]),
    )
    assert_parses expected, "return 1"
  end

  test "return 1, 2, 3" do
    expected = ReturnNode(
      KEYWORD_RETURN("return"),
      ArgumentsNode([
        expression("1"),
        expression("2"),
        expression("3"),
      ]),
    )
    assert_parses expected, "return 1, 2, 3"
  end

  test "return 1, 2,\n3" do
    expected = ReturnNode(
      KEYWORD_RETURN("return"),
      ArgumentsNode([
        expression("1"),
        expression("2"),
        expression("3"),
      ]),
    )
    assert_parses expected, "return 1, 2,\n3"
  end

  test "return()" do
    expected = ReturnNode(
      KEYWORD_RETURN("return"),
      ArgumentsNode([
        expression("()"),
      ]),
    )
    assert_parses expected, "return()"
  end

  test "return(1)" do
    expected = ReturnNode(
      KEYWORD_RETURN("return"),
      ArgumentsNode([
        expression("(1)"),
      ]),
    )

    assert_parses expected, "return(1)"
  end

  test "return (1), (2), (3)" do
    expected = ReturnNode(
      KEYWORD_RETURN("return"),
      ArgumentsNode([
        expression("(1)"),
        expression("(2)"),
        expression("(3)"),
      ]),
    )
    assert_parses expected, "return (1), (2), (3)"
  end

  test "return [1, 2, 3]" do
    expected = ReturnNode(
      KEYWORD_RETURN("return"),
      ArgumentsNode([expression("[1, 2, 3]")])
    )

    assert_parses expected, "return [1, 2, 3]"
  end

  test "return multiple statements inside of parentheses" do
    expected = ReturnNode(
      KEYWORD_RETURN("return"),
      ArgumentsNode([
        ParenthesesNode(
          PARENTHESIS_LEFT("("),
          Statements([expression("1"), expression("2")]),
          PARENTHESIS_RIGHT(")")
        )
      ])
    )

    assert_parses expected, <<~RUBY
      return(
        1
        2
      )
    RUBY
  end

  test "self" do
    assert_parses SelfNode(), "self"
  end

  test "source encoding" do
    assert_parses SourceEncodingNode(), "__ENCODING__"
  end

  test "source file" do
    assert_parses SourceFileNode(), "__FILE__"
  end

  test "source line" do
    assert_parses SourceLineNode(), "__LINE__"
  end

  test "string empty" do
    assert_parses StringNode(STRING_BEGIN("'"), STRING_CONTENT(""), STRING_END("'"), ""), "''"
  end

  test "string interpolation disallowed" do
    assert_parses StringNode(STRING_BEGIN("'"), STRING_CONTENT("abc"), STRING_END("'"), "abc"), "'abc'"
  end

  test "%q string interpolation disallowed" do
    assert_parses StringNode(STRING_BEGIN("%q{"), STRING_CONTENT("abc"), STRING_END("}"), "abc"), "%q{abc}"
  end

  test "string interpolation allowed, but not used" do
    assert_parses StringNode(STRING_BEGIN("\""), STRING_CONTENT("abc"), STRING_END("\""), "abc"), "\"abc\""
  end

  test "%Q string interpolation allowed, but not used" do
    expected = StringNode(
      STRING_BEGIN("%Q{"),
      STRING_CONTENT("abc"),
      STRING_END("}"),
      "abc"
    )

    assert_parses expected, "%Q{abc}"
  end

  test "% string interpolation allowed, but not used" do
    expected = StringNode(
      STRING_BEGIN("%{"),
      STRING_CONTENT("abc"),
      STRING_END("}"),
      "abc"
    )

    assert_parses expected, "%{abc}"
  end

  test "string interpolation allowed, sed" do
    expected = InterpolatedStringNode(
      STRING_BEGIN("\""),
      [
        StringNode(nil, STRING_CONTENT("aaa "), nil, "aaa "),
        StringInterpolatedNode(
          EMBEXPR_BEGIN("\#{"),
          Statements([CallNode(nil, nil, IDENTIFIER("bbb"), nil, nil, nil, nil, "bbb")]),
          EMBEXPR_END("}")
        ),
        StringNode(nil, STRING_CONTENT(" ccc"), nil, " ccc")
      ],
      STRING_END("\"")
    )

    assert_parses expected, "\"aaa \#{bbb} ccc\""
  end

  test "string interpolation allowed, not actually interpolated" do
    assert_parses StringNode(STRING_BEGIN("\""), STRING_CONTENT("\#@---"), STRING_END("\""), "\#@---"), "\"#@---\""
  end

  test "%Q string interpolation allowed, sed" do
    expected = InterpolatedStringNode(
      STRING_BEGIN("%Q{"),
      [
        StringNode(nil, STRING_CONTENT("aaa "), nil, "aaa "),
        StringInterpolatedNode(
          EMBEXPR_BEGIN("\#{"),
          Statements([CallNode(nil, nil, IDENTIFIER("bbb"), nil, nil, nil, nil, "bbb")]),
          EMBEXPR_END("}")
        ),
        StringNode(nil, STRING_CONTENT(" ccc"), nil, " ccc")
      ],
      STRING_END("}")
    )

    assert_parses expected, "%Q{aaa \#{bbb} ccc}"
  end

  test "% string interpolation allowed, sed" do
    expected = InterpolatedStringNode(
      STRING_BEGIN("%{"),
      [
        StringNode(nil, STRING_CONTENT("aaa "), nil, "aaa "),
        StringInterpolatedNode(
          EMBEXPR_BEGIN("\#{"),
          Statements([CallNode(nil, nil, IDENTIFIER("bbb"), nil, nil, nil, nil, "bbb")]),
          EMBEXPR_END("}")
        ),
        StringNode(nil, STRING_CONTENT(" ccc"), nil, " ccc")
      ],
      STRING_END("}")
    )

    assert_parses expected, "%{aaa \#{bbb} ccc}"
  end

  test "% string with any non-closing token" do
    %w[! @ $ % ^ & * _ + - | : ; " ' , . ~ ? / ` # \\].each do |token|
      expected = StringNode(
        STRING_BEGIN("%#{token}"),
        STRING_CONTENT("abc"),
        STRING_END(token),
        "abc"
      )

      assert_parses expected, "%#{token}abc#{token}"
    end
  end

  test "% string with any closing token" do
    [["{", "}"], ["[", "]"], ["(", ")"]].each do |(opening, closing)|
      expected = StringNode(
        STRING_BEGIN("%#{opening}"),
        STRING_CONTENT("abc"),
        STRING_END(closing),
        "abc"
      )

      assert_parses expected, "%#{opening}abc#{closing}"
    end
  end

  test "string list" do
    expected = ArrayNode(
      [
        StringNode(nil, STRING_CONTENT("a"), nil, "a"),
        StringNode(nil, STRING_CONTENT("b"), nil, "b"),
        StringNode(nil, STRING_CONTENT("c"), nil, "c")
      ],
      PERCENT_LOWER_W("%w["),
      STRING_END("]")
    )

    assert_parses expected, "%w[a b c]"
  end

  test "string list with interpolation allowed but not used" do
    expected = ArrayNode(
      [
        StringNode(nil, STRING_CONTENT("a"), nil, "a"),
        StringNode(nil, STRING_CONTENT("b"), nil, "b"),
        StringNode(nil, STRING_CONTENT("c"), nil, "c")
      ],
      PERCENT_UPPER_W("%W["),
      STRING_END("]")
    )

    assert_parses expected, "%W[a b c]"
  end

  test "string list with interpolation allowed and used" do
    expected = ArrayNode(
      [
        StringNode(nil, STRING_CONTENT("a"), nil, "a"),
        InterpolatedStringNode(
          nil,
          [
            StringNode(nil, STRING_CONTENT("b"), nil, "b"),
            StringInterpolatedNode(
              EMBEXPR_BEGIN("\#{"),
              Statements([expression("c")]),
              EMBEXPR_END("}")
            ),
            StringNode(nil, STRING_CONTENT("d"), nil, "d")
          ],
          nil
        ),
        StringNode(nil, STRING_CONTENT("e"), nil, "e")
      ],
      PERCENT_UPPER_W("%W["),
      STRING_END("]")
    )

    assert_parses expected, "%W[a b\#{c}d e]"
  end

  test "string with \\ escapes" do
    assert_parses StringNode(STRING_BEGIN("'"), STRING_CONTENT("\\\\ foo \\\\ bar"), STRING_END("'"), "\\ foo \\ bar"), "'\\\\ foo \\\\ bar'"
  end

  test "string with ' escapes" do
    assert_parses StringNode(STRING_BEGIN("'"), STRING_CONTENT("\\' foo \\' bar"), STRING_END("'"), "' foo ' bar"), "'\\' foo \\' bar'"
  end

  test "string with octal escapes" do
    assert_parses StringNode(STRING_BEGIN("\""), STRING_CONTENT("\\7 \\43 \\141"), STRING_END("\""), "\a # a"), "\"\\7 \\43 \\141\""
  end

  test "string with hexadecimal escapes" do
    assert_parses StringNode(STRING_BEGIN("\""), STRING_CONTENT("\\x7 \\x23 \\x61"), STRING_END("\""), "\a # a"), "\"\\x7 \\x23 \\x61\""
  end

  test "string with embedded global variables" do
    expected = InterpolatedStringNode(STRING_BEGIN("\""), [expression("$foo")], STRING_END("\""))
    assert_parses expected, "\"\#$foo\""
  end

  test "string with embedded instance variables" do
    expected = InterpolatedStringNode(STRING_BEGIN("\""), [expression("@foo")], STRING_END("\""))
    assert_parses expected, "\"\#@foo\""
  end

  test "string with embedded class variables" do
    expected = InterpolatedStringNode(STRING_BEGIN("\""), [expression("@@foo")], STRING_END("\""))
    assert_parses expected, "\"\#@@foo\""
  end

  test "super" do
    assert_parses ForwardingSuperNode(nil), "super"
  end

  test "super()" do
    assert_parses SuperNode(KEYWORD_SUPER("super"), PARENTHESIS_LEFT("("), nil, PARENTHESIS_RIGHT(")"), nil), "super()"
  end

  test "super(1)" do
    assert_parses SuperNode(KEYWORD_SUPER("super"), PARENTHESIS_LEFT("("), ArgumentsNode([expression("1")]), PARENTHESIS_RIGHT(")"), nil), "super(1)"
  end

  test "super(1, 2, 3)" do
    assert_parses SuperNode(KEYWORD_SUPER("super"), PARENTHESIS_LEFT("("), ArgumentsNode([expression("1"), expression("2"), expression("3")]), PARENTHESIS_RIGHT(")"), nil), "super(1, 2, 3)"
  end

  test "symbol" do
    assert_parses SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("a"), nil), ":a"
  end

  test "symbol with keyword" do
    assert_parses SymbolNode(SYMBOL_BEGIN(":"), KEYWORD_DO("do"), nil), ":do"
  end

  test "symbol with instance variable" do
    assert_parses SymbolNode(SYMBOL_BEGIN(":"), INSTANCE_VARIABLE("@a"), nil), ":@a"
  end

  test "symbol with class variable" do
    assert_parses SymbolNode(SYMBOL_BEGIN(":"), CLASS_VARIABLE("@@a"), nil), ":@@a"
  end

  test "symbol with global variable" do
    assert_parses SymbolNode(SYMBOL_BEGIN(":"), GLOBAL_VARIABLE("$a"), nil), ":$a"
  end

  test "symbol with operators" do
    operators = {
      "&" => :AMPERSAND,
      "`" => :BACKTICK,
      "!@" => :BANG_AT,
      "!~" => :BANG_TILDE,
      "!" => :BANG,
      "[]" => :BRACKET_LEFT_RIGHT,
      "[]=" => :BRACKET_LEFT_RIGHT_EQUAL,
      "^" => :CARET,
      "==" => :EQUAL_EQUAL,
      "===" => :EQUAL_EQUAL_EQUAL,
      "=~" => :EQUAL_TILDE,
      ">=" => :GREATER_EQUAL,
      ">>" => :GREATER_GREATER,
      ">" => :GREATER,
      "<=>" => :LESS_EQUAL_GREATER,
      "<=" => :LESS_EQUAL,
      "<<" => :LESS_LESS,
      "<" => :LESS,
      "-@" => :MINUS_AT,
      "-" => :MINUS,
      "%" => :PERCENT,
      "|" => :PIPE,
      "+@" => :PLUS_AT,
      "+" => :PLUS,
      "/" => :SLASH,
      "**" => :STAR_STAR,
      "*" => :STAR,
      "~@" => :TILDE_AT,
      "~" => :TILDE
    }

    operators.each do |operator, method_name|
      contents = method(method_name).call(operator)
      assert_parses SymbolNode(SYMBOL_BEGIN(":"), contents, nil), ":#{operator}"
    end
  end

  test "symbol list" do
    expected = ArrayNode(
      [
        SymbolNode(nil, STRING_CONTENT("a"), nil),
        SymbolNode(nil, STRING_CONTENT("b"), nil),
        SymbolNode(nil, STRING_CONTENT("c"), nil)
      ],
      PERCENT_LOWER_I("%i["),
      STRING_END("]")
    )

    assert_parses expected, "%i[a b c]"
  end

  test "symbol list with ignored interpolation" do
    expected = ArrayNode(
      [
        SymbolNode(nil, STRING_CONTENT("a"), nil),
        SymbolNode(nil, STRING_CONTENT("b\#{1}"), nil),
        SymbolNode(nil, STRING_CONTENT("\#{2}c"), nil),
        SymbolNode(nil, STRING_CONTENT("d\#{3}f"), nil)
      ],
      PERCENT_LOWER_I("%i["),
      STRING_END("]")
    )

    assert_parses expected, "%i[a b\#{1} \#{2}c d\#{3}f]"
  end

  test "symbol list with interpreted interpolation" do
    expected = ArrayNode(
      [
        SymbolNode(nil, STRING_CONTENT("a"), nil),
        InterpolatedSymbolNode(
          nil,
          [SymbolNode(nil, STRING_CONTENT("b"), nil),
            StringInterpolatedNode(
              EMBEXPR_BEGIN("\#{"),
              Statements([IntegerNode()]),
              EMBEXPR_END("}")
            )],
          nil
        ),
        InterpolatedSymbolNode(
          nil,
          [StringInterpolatedNode(
              EMBEXPR_BEGIN("\#{"),
              Statements([IntegerNode()]),
              EMBEXPR_END("}")
            ),
            SymbolNode(nil, STRING_CONTENT("c"), nil)],
          nil
        ),
        InterpolatedSymbolNode(
          nil,
          [SymbolNode(nil, STRING_CONTENT("d"), nil),
            StringInterpolatedNode(
              EMBEXPR_BEGIN("\#{"),
              Statements([IntegerNode()]),
              EMBEXPR_END("}")
            ),
            SymbolNode(nil, STRING_CONTENT("f"), nil)],
          nil
        )
      ],
      PERCENT_UPPER_I("%I["),
      STRING_END("]")
    )

    assert_parses expected, "%I[a b\#{1} \#{2}c d\#{3}f]"
  end

  test "dynamic symbol" do
    expected = SymbolNode(SYMBOL_BEGIN(":'"), STRING_CONTENT("abc"), STRING_END("'"))
    assert_parses expected, ":'abc'"
  end

  test "dynamic symbol with interpolation" do
    expected = InterpolatedSymbolNode(
      SYMBOL_BEGIN(":\""),
      [StringNode(nil, STRING_CONTENT("abc"), nil, "abc"),
       StringInterpolatedNode(
         EMBEXPR_BEGIN("\#{"),
         Statements([expression("1")]),
         EMBEXPR_END("}")
       )],
      STRING_END("\"")
    )
    assert_parses expected, ":\"abc\#{1}\""
  end

  test "alias with dynamic symbol" do
    expected = AliasNode(
      SymbolNode(SYMBOL_BEGIN(":'"), STRING_CONTENT("abc"), STRING_END("'")),
      SymbolNode(SYMBOL_BEGIN(":'"), STRING_CONTENT("def"), STRING_END("'")),
      Location()
    )

    assert_parses expected, "alias :'abc' :'def'"
  end

  test "alias with dynamic symbol with interpolation" do
    expected = AliasNode(
      InterpolatedSymbolNode(
        SYMBOL_BEGIN(":\""),
        [StringNode(nil, STRING_CONTENT("abc"), nil, "abc"),
         StringInterpolatedNode(
           EMBEXPR_BEGIN("\#{"),
           Statements([expression("1")]),
           EMBEXPR_END("}")
         )],
        STRING_END("\"")
      ),
      SymbolNode(SYMBOL_BEGIN(":'"), STRING_CONTENT("def"), STRING_END("'")),
      Location()
    )

    assert_parses expected, "alias :\"abc\#{1}\" :'def'"
  end

  test "undef with dynamic symbols" do
    expected = UndefNode(
      [SymbolNode(SYMBOL_BEGIN(":'"), STRING_CONTENT("abc"), STRING_END("'"))],
      Location()
    )
    assert_parses expected, "undef :'abc'"
  end

  test "undef with dynamic symbols with interpolation" do
    expected = UndefNode(
      [
        InterpolatedSymbolNode(
          SYMBOL_BEGIN(":\""),
          [StringNode(nil, STRING_CONTENT("abc"), nil, "abc"),
            StringInterpolatedNode(
              EMBEXPR_BEGIN("\#{"),
              Statements([expression("1")]),
              EMBEXPR_END("}")
            )],
          STRING_END("\"")
        )
      ],
      Location()
    )
    assert_parses expected, "undef :\"abc\#{1}\""
  end

  test "%s symbol" do
    expected = SymbolNode(SYMBOL_BEGIN("%s["), STRING_CONTENT("abc"), STRING_END("]"))
    assert_parses expected, "%s[abc]"
  end

  test "alias with %s symbol" do
    expected = AliasNode(
      SymbolNode(SYMBOL_BEGIN("%s["), STRING_CONTENT("abc"), STRING_END("]")),
      SymbolNode(SYMBOL_BEGIN("%s["), STRING_CONTENT("def"), STRING_END("]")),
      Location()
    )

    assert_parses expected, "alias %s[abc] %s[def]"
  end

  test "ternary" do
    expected = Ternary(
      CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a"),
      QUESTION_MARK("?"),
      CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b"),
      COLON(":"),
      CallNode(nil, nil, IDENTIFIER("c"), nil, nil, nil, nil, "c")
    )

    assert_parses expected, "a ? b : c"
  end

  test "true" do
    assert_parses TrueNode(), "true"
  end

  test "unary !" do
    assert_parses CallNode(expression("1"), nil, BANG("!"), nil, nil, nil, nil, "!"), "!1"
  end

  test "unary -" do
    assert_parses CallNode(expression("1"), nil, UMINUS("-"), nil, nil, nil, nil, "-@"), "-1"
  end

  test "unary ~" do
    assert_parses CallNode(expression("1"), nil, TILDE("~"), nil, nil, nil, nil, "~"), "~1"
  end

  test "undef bare" do
    assert_parses UndefNode([SymbolNode(nil, IDENTIFIER("a"), nil)], Location()), "undef a"
  end

  test "undef bare, multiple" do
    assert_parses UndefNode([SymbolNode(nil, IDENTIFIER("a"), nil), SymbolNode(nil, IDENTIFIER("b"), nil)], Location()), "undef a, b"
  end

  test "undef symbol" do
    assert_parses UndefNode([SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("a"), nil)], Location()), "undef :a"
  end

  test "undef symbol, multiple" do
    expected = UndefNode(
      [
        SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("a"), nil),
        SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("b"), nil),
        SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("c"), nil)
      ],
      Location()
    )

    assert_parses expected, "undef :a, :b, :c"
  end

  test "unless" do
    assert_parses UnlessNode(KEYWORD_UNLESS("unless"), expression("true"), Statements([expression("1")]), nil, KEYWORD_END("end")), "unless true; 1; end"
  end

  test "unless modifier" do
    assert_parses UnlessNode(KEYWORD_UNLESS("unless"), expression("true"), Statements([expression("1")]), nil, nil), "1 unless true"
  end

  test "unless else" do
    expected = UnlessNode(
      KEYWORD_UNLESS("unless"),
      expression("true"),
      Statements([expression("1")]),
      ElseNode(
        KEYWORD_ELSE("else"),
        Statements([expression("2")]),
        KEYWORD_END("end")
      ),
      KEYWORD_END("end")
    )

    assert_parses expected, "unless true\n1 else 2 end"
  end

  test "unless elsif" do
    expected = UnlessNode(
      KEYWORD_UNLESS("unless"),
      TrueNode(),
      Statements([TrueNode()]),
      IfNode(
        KEYWORD_ELSIF("elsif"),
        FalseNode(),
        Statements([FalseNode()]),
        IfNode(
          KEYWORD_ELSIF("elsif"),
          NilNode(),
          Statements([NilNode()]),
          ElseNode(
            KEYWORD_ELSE("else"),
            Statements([SelfNode()]),
            KEYWORD_END("end")
          ),
          nil
        ),
        nil
      ),
      KEYWORD_END("end")
    )

    assert_parses expected, "unless true then true elsif false then false elsif nil then nil else self end"
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
    assert_parses YieldNode(KEYWORD_YIELD("yield"), PARENTHESIS_LEFT("("), nil, PARENTHESIS_RIGHT(")")), "yield()"
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
      nil,
      ArgumentsNode([
        CallNode(expression("2"), nil, STAR("*"), nil, ArgumentsNode([expression("3")]), nil, nil, "*")
      ]),
      nil,
      nil,
      "+"
    )

    assert_parses expected, "1 + 2 * 3"
  end

  test "FACTOR < EXPONENT" do
    expected = CallNode(
      expression("1"),
      nil,
      STAR("*"),
      nil,
      ArgumentsNode([
        CallNode(expression("2"), nil, STAR_STAR("**"), nil, ArgumentsNode([expression("3")]), nil, nil, "**")
      ]),
      nil,
      nil,
      "*"
    )

    assert_parses expected, "1 * 2 ** 3"
  end

  test "FACTOR > TERM" do
    expected = CallNode(
      CallNode(expression("1"), nil, STAR("*"), nil, ArgumentsNode([expression("2")]), nil, nil, "*"),
      nil,
      PLUS("+"),
      nil,
      ArgumentsNode([expression("3")]),
      nil,
      nil,
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

  test "begin statements" do
    expected = BeginNode(
      KEYWORD_BEGIN("begin"),
      Statements([expression("a")]),
      nil,
      nil,
      nil,
      KEYWORD_END("end"),
    )

    assert_parses expected, "begin\na\nend"
    assert_parses expected, "begin; a; end"
    assert_parses expected, "begin a\n end"
    assert_parses expected, "begin a; end"
  end


  test "begin rescue, else" do
    expected = BeginNode(
      KEYWORD_BEGIN("begin"),
      Statements([CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")]),
      RescueNode(
        KEYWORD_RESCUE("rescue"),
        [],
        nil,
        nil,
        Statements([CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]),
        nil
      ),
      ElseNode(
        KEYWORD_ELSE("else"),
        Statements([CallNode(nil, nil, IDENTIFIER("c"), nil, nil, nil, nil, "c")]),
        SEMICOLON(";")
      ),
      nil,
      KEYWORD_END("end")
    )

    assert_parses expected, "begin; a; rescue; b; else; c; end"
  end

  test "begin rescue, else and ensure" do
    expected = BeginNode(
      KEYWORD_BEGIN("begin"),
      Statements([CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a")]),
      RescueNode(
        KEYWORD_RESCUE("rescue"),
        [],
        nil,
        nil,
        Statements([CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b")]),
        nil
      ),
      ElseNode(
        KEYWORD_ELSE("else"),
        Statements([CallNode(nil, nil, IDENTIFIER("c"), nil, nil, nil, nil, "c")]),
        SEMICOLON(";")
      ),
      EnsureNode(
        KEYWORD_ENSURE("ensure"),
        Statements([CallNode(nil, nil, IDENTIFIER("d"), nil, nil, nil, nil, "d")]),
        KEYWORD_END("end")
      ),
      nil
    )

    assert_parses expected, "begin; a; rescue; b; else; c; ensure; d; end"
  end


  test "endless method definition without arguments" do
    expected = DefNode(
      IDENTIFIER("foo"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([expression("123")]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      Location(),
      nil
    )

    assert_parses expected, "def foo = 123"
  end

  test "endless method definition with arguments" do
    expected = DefNode(
      IDENTIFIER("foo"),
      nil,
      ParametersNode(
        [RequiredParameterNode(IDENTIFIER("bar"))],
        [],
        nil,
        [],
        nil,
        nil
      ),
      Statements([expression("123")]),
      Scope([IDENTIFIER("bar")]),
      Location(),
      nil,
      Location(),
      Location(),
      Location(),
      nil
    )

    assert_parses expected, "def foo(bar) = 123"
  end

  test "singleton class defintion" do
    expected = SClassNode(
      Scope([]),
      KEYWORD_CLASS("class"),
      LESS_LESS("<<"),
      expression("self"),
      Statements([]),
      KEYWORD_END("end"),
    )

    assert_parses expected, "class << self\nend"
    assert_parses expected, "class << self;end"
  end

  test "singleton class definition with method invocation for rhs" do
    expected = SClassNode(
      Scope([]),
      KEYWORD_CLASS("class"),
      LESS_LESS("<<"),
      CallNode(
        CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
        DOT("."),
        IDENTIFIER("bar"),
        nil,
        nil,
        nil,
        nil,
        "bar"
      ),
      Statements([]),
      KEYWORD_END("end"),
    )

    assert_parses expected, "class << foo.bar\nend"
    assert_parses expected, "class << foo.bar;end"
  end

  test "singleton class defintion with statement" do
    expected = SClassNode(
      Scope([]),
      KEYWORD_CLASS("class"),
      LESS_LESS("<<"),
      expression("self"),
      Statements(
        [CallNode(
          IntegerNode(),
          nil,
          PLUS("+"),
          nil,
          ArgumentsNode([IntegerNode()]),
          nil,
          nil,
          "+"
        )]
      ),
      KEYWORD_END("end"),
    )

    assert_parses expected, "class << self\n1 + 2\nend"
    assert_parses expected, "class << self;1 + 2;end"
  end

  test "for loop" do
    expected = ForNode(
      expression("i"),
      expression("1..10"),
      Statements([expression("i")]),
      Location(),
      Location(),
      nil,
      Location()
    )

    assert_parses expected, "for i in 1..10\ni\nend"
  end

  test "for loop with do keyword" do
    expected = ForNode(
      expression("i"),
      expression("1..10"),
      Statements([expression("i")]),
      Location(),
      Location(),
      Location(),
      Location()
    )

    assert_parses expected, "for i in 1..10 do\ni\nend"
  end

  test "for loop no newlines" do
    expected = ForNode(
      expression("i"),
      expression("1..10"),
      Statements([expression("i")]),
      Location(),
      Location(),
      nil,
      Location()
    )

    assert_parses expected, "for i in 1..10 i end"
  end

  test "for loop with semicolons" do
    expected = ForNode(
      expression("i"),
      expression("1..10"),
      Statements([expression("i")]),
      Location(),
      Location(),
      nil,
      Location()
    )

    assert_parses expected, "for i in 1..10; i; end"
  end

  test "for loop with 2 indexes" do
    expected = ForNode(
      MultiTargetNode([
        expression("i"),
        expression("j"),
      ]),
      expression("1..10"),
      Statements([expression("i")]),
      Location(),
      Location(),
      nil,
      Location()
    )

    assert_parses expected, "for i,j in 1..10\ni\nend"
  end

  test "for loop with 3 indexes" do
    expected = ForNode(
      MultiTargetNode([
        expression("i"),
        expression("j"),
        expression("k"),
      ]),
      expression("1..10"),
      Statements([expression("i")]),
      Location(),
      Location(),
      nil,
      Location()
    )

    assert_parses expected, "for i,j,k in 1..10\ni\nend"
  end

  test "rescue modifier" do
    expected = RescueModifierNode(
      CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
      KEYWORD_RESCUE("rescue"),
      NilNode()
    )

    assert_parses expected, "foo rescue nil"
    assert_parses expected, "foo rescue\nnil"
  end

  test "rescue modifier within a ternary operator" do
    expected = RescueModifierNode(
      CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
      KEYWORD_RESCUE("rescue"),
      Ternary(
        NilNode(),
        QUESTION_MARK("?"),
        IntegerNode(),
        COLON(":"),
        IntegerNode()
      )
    )

    assert_parses expected, "foo rescue nil ? 1 : 2"
  end

  test "rescue modifier with logical operator" do
    expected = RescueModifierNode(
      CallNode(nil, nil, IDENTIFIER("foo"), nil, nil, nil, nil, "foo"),
      KEYWORD_RESCUE("rescue"),
      OrNode(NilNode(), PIPE_PIPE("||"), IntegerNode())
    )

    assert_parses expected, "foo rescue nil || 1"
  end

  test "begin with rescue statement" do
    expected = BeginNode(
      KEYWORD_BEGIN("begin"),
      Statements([expression("a")]),
      RescueNode(
        KEYWORD_RESCUE("rescue"),
        [],
        nil,
        nil,
        Statements([expression("b")]),
        nil
      ),
      nil,
      nil,
      KEYWORD_END("end"),
    )

    assert_parses expected, "begin\na\nrescue\nb\nend"
    assert_parses expected, "begin;a;rescue;b;end"
    assert_parses expected, "begin\na;rescue\nb;end"
  end

  test "begin with rescue statement and exception" do
    expected = BeginNode(
      KEYWORD_BEGIN("begin"),
      Statements([expression("a")]),
      RescueNode(
        KEYWORD_RESCUE("rescue"),
        [ConstantRead(CONSTANT("Exception"))],
        nil,
        nil,
        Statements([expression("b")]),
        nil
      ),
      nil,
      nil,
      KEYWORD_END("end"),
    )

    assert_parses expected, "begin\na\nrescue Exception\nb\nend"
  end

  test "begin with rescue statement with variable" do
    expected = BeginNode(
      KEYWORD_BEGIN("begin"),
      Statements([expression("a")]),
      RescueNode(
        KEYWORD_RESCUE("rescue"),
        [ConstantRead(CONSTANT("Exception"))],
        EQUAL_GREATER("=>"),
        IDENTIFIER("ex"),
        Statements([expression("b")]),
        nil,
      ),
      nil,
      nil,
      KEYWORD_END("end"),
    )

    assert_parses expected, "begin\na\nrescue Exception => ex\nb\nend"
  end

  test "begin with rescue statement and exception list" do
    expected = BeginNode(
      KEYWORD_BEGIN("begin"),
      Statements([expression("a")]),
      RescueNode(
        KEYWORD_RESCUE("rescue"),
        [ConstantRead(CONSTANT("Exception")), ConstantRead(CONSTANT("CustomException"))],
        nil,
        nil,
        Statements([expression("b")]),
        nil
      ),
      nil,
      nil,
      KEYWORD_END("end"),
    )

    assert_parses expected, "begin\na\nrescue Exception, CustomException\nb\nend"
  end

  test "begin with rescue statement and exception list with variable" do
    expected = BeginNode(
      KEYWORD_BEGIN("begin"),
      Statements([expression("a")]),
      RescueNode(
        KEYWORD_RESCUE("rescue"),
        [ConstantRead(CONSTANT("Exception")), ConstantRead(CONSTANT("CustomException"))],
        EQUAL_GREATER("=>"),
        IDENTIFIER("ex"),
        Statements([expression("b")]),
        nil
      ),
      nil,
      nil,
      KEYWORD_END("end"),
    )

    assert_parses expected, "begin\na\nrescue Exception, CustomException => ex\nb\nend"
  end

  test "begin with multiple rescue statements" do
    expected = BeginNode(
      KEYWORD_BEGIN("begin"),
      Statements([expression("a")]),
      RescueNode(
        KEYWORD_RESCUE("rescue"),
        [],
        nil,
        nil,
        Statements([expression("b")]),
        RescueNode(
          KEYWORD_RESCUE("rescue"),
          [],
          nil,
          nil,
          Statements([expression("c")]),
          RescueNode(
            KEYWORD_RESCUE("rescue"),
            [],
            nil,
            nil,
            Statements([expression("d")]),
            nil
          )
        )
      ),
      nil,
      nil,
      KEYWORD_END("end"),
    )

    assert_parses expected, "begin\na\nrescue\nb\nrescue\nc\nrescue\nd\nend"
  end

  test "begin with multiple rescue statements with exception classes and variables" do
    expected = BeginNode(
      KEYWORD_BEGIN("begin"),
      Statements([expression("a")]),
      RescueNode(
        KEYWORD_RESCUE("rescue"),
        [ConstantRead(CONSTANT("Exception"))],
        EQUAL_GREATER("=>"),
        IDENTIFIER("ex"),
        Statements([expression("b")]),
        RescueNode(
          KEYWORD_RESCUE("rescue"),
          [ConstantRead(CONSTANT("AnotherException")), ConstantRead(CONSTANT("OneMoreException"))],
          EQUAL_GREATER("=>"),
          IDENTIFIER("ex"),
          Statements([expression("c")]),
          nil
        )
      ),
      nil,
      nil,
      KEYWORD_END("end"),
    )

    assert_parses expected, "begin\na\nrescue Exception => ex\nb\nrescue AnotherException, OneMoreException => ex\nc\nend"
  end

  test "ensure statements" do
    expected = BeginNode(
      KEYWORD_BEGIN("begin"),
      Statements([expression("a")]),
      nil,
      nil,
      EnsureNode(
        KEYWORD_ENSURE("ensure"),
        Statements([expression("b")]),
        KEYWORD_END("end"),
      ),
      nil
    )

    assert_parses expected, "begin\na\nensure\nb\nend"
    assert_parses expected, "begin; a; ensure; b; end"
    assert_parses expected, "begin a\n ensure b\n end"
    assert_parses expected, "begin a; ensure b; end"
  end

  test "parses empty hash" do
    assert_parses HashNode(BRACE_LEFT("{"), [], BRACE_RIGHT("}")), "{}"
  end

  test "parses hash with hashrocket keys" do
    expected = HashNode(
      BRACE_LEFT("{"),
      [
        AssocNode(
          CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a"),
          CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b"),
          EQUAL_GREATER("=>")
        ),
        AssocNode(
          CallNode(nil, nil, IDENTIFIER("c"), nil, nil, nil, nil, "c"),
          CallNode(nil, nil, IDENTIFIER("d"), nil, nil, nil, nil, "d"),
          EQUAL_GREATER("=>")
        )
      ],
      BRACE_RIGHT("}")
    )

    assert_parses expected, "{ a => b, c => d }"
  end

  test "hash with label keys" do
    expected = HashNode(
      BRACE_LEFT("{"),
      [
        AssocNode(SymbolNode(nil, LABEL("a"), LABEL_END(":")), expression("b"), nil),
        AssocNode(SymbolNode(nil, LABEL("c"), LABEL_END(":")), expression("d"), nil),
        AssocSplatNode(expression("e"), Location()),
        AssocNode(SymbolNode(nil, LABEL("f"), LABEL_END(":")), expression("g"), nil),
      ],
      BRACE_RIGHT("}")
    )

    assert_parses expected, "{ a: b, c: d, **e, f: g }"
  end

  test "parses hash with splat" do
    expected = HashNode(
      BRACE_LEFT("{"),
      [
        AssocNode(
          CallNode(nil, nil, IDENTIFIER("a"), nil, nil, nil, nil, "a"),
          CallNode(nil, nil, IDENTIFIER("b"), nil, nil, nil, nil, "b"),
          EQUAL_GREATER("=>")
        ),
        AssocSplatNode(
          CallNode(nil, nil, IDENTIFIER("c"), nil, nil, nil, nil, "c"),
          Location()
        )
      ],
      BRACE_RIGHT("}")
    )

    assert_parses expected, "{ a => b, **c }"
  end

  test "parses empty hash with statements after it" do
    assert_parses HashNode(BRACE_LEFT("{"), [], BRACE_RIGHT("}")), "{\n}\n"
  end

  test "begin with rescue and ensure statements" do
    expected = BeginNode(
      KEYWORD_BEGIN("begin"),
      Statements([expression("a")]),
      RescueNode(
        KEYWORD_RESCUE("rescue"),
        [ConstantRead(CONSTANT("Exception"))],
        EQUAL_GREATER("=>"),
        IDENTIFIER("ex"),
        Statements([expression("b")]),
        nil
      ),
      nil,
      EnsureNode(
        KEYWORD_ENSURE("ensure"),
        Statements([expression("b")]),
        KEYWORD_END("end"),
      ),
      nil,
    )

    assert_parses expected, "begin\na\nrescue Exception => ex\nb\nensure\nb\nend"
  end

  test "simple #[] call" do
    expected = CallNode(
      expression("foo"),
      nil,
      BRACKET_LEFT_RIGHT("["),
      BRACKET_LEFT("["),
      ArgumentsNode([expression("bar")]),
      BRACKET_RIGHT("]"),
      nil,
      "[]"
    )

    assert_parses expected, "foo[bar]"
  end

  test "block with braces on #[] call" do
    expected = CallNode(
      expression("foo"),
      nil,
      BRACKET_LEFT_RIGHT("["),
      BRACKET_LEFT("["),
      ArgumentsNode([expression("bar")]),
      BRACKET_RIGHT("]"),
      BlockNode(
        BRACE_LEFT("{"),
        nil,
        Statements([expression("baz")]),
        BRACE_RIGHT("}")
      ),
      "[]"
    )

    assert_parses expected, "foo[bar] { baz }"
  end

  test "block with keywords on #[] call" do
    expected = CallNode(
      expression("foo"),
      nil,
      BRACKET_LEFT_RIGHT("["),
      BRACKET_LEFT("["),
      ArgumentsNode([expression("bar")]),
      BRACKET_RIGHT("]"),
      BlockNode(
        KEYWORD_DO("do"),
        nil,
        Statements([expression("baz")]),
        KEYWORD_END("end")
      ),
      "[]"
    )

    assert_parses expected, "foo[bar] do\nbaz\nend"
  end

  test "simple #[]= call" do
    expected = CallNode(
      expression("foo"),
      nil,
      BRACKET_LEFT_RIGHT_EQUAL("["),
      BRACKET_LEFT("["),
      ArgumentsNode([expression("bar"), expression("baz")]),
      BRACKET_RIGHT("]"),
      nil,
      "[]="
    )

    assert_parses expected, "foo[bar] = baz"
  end

  test "multiple arguments #[] call" do
    expected = CallNode(
      expression("foo"),
      nil,
      BRACKET_LEFT_RIGHT("["),
      BRACKET_LEFT("["),
      ArgumentsNode([expression("bar"), expression("baz")]),
      BRACKET_RIGHT("]"),
      nil,
      "[]"
    )

    assert_parses expected, "foo[bar, baz]"
  end

  test "multiple arguments #[]= call" do
    expected = CallNode(
      expression("foo"),
      nil,
      BRACKET_LEFT_RIGHT_EQUAL("["),
      BRACKET_LEFT("["),
      ArgumentsNode([expression("bar"), expression("baz"), expression("qux")]),
      BRACKET_RIGHT("]"),
      nil,
      "[]="
    )

    assert_parses expected, "foo[bar, baz] = qux"
  end

  test "chained #[] calls" do
    expected = CallNode(
      CallNode(
        expression("foo"),
        nil,
        BRACKET_LEFT_RIGHT("["),
        BRACKET_LEFT("["),
        ArgumentsNode([expression("bar")]),
        BRACKET_RIGHT("]"),
        nil,
        "[]"
      ),
      nil,
      BRACKET_LEFT_RIGHT("["),
      BRACKET_LEFT("["),
      ArgumentsNode([expression("baz")]),
      BRACKET_RIGHT("]"),
      nil,
      "[]"
    )

    assert_parses expected, "foo[bar][baz]"
  end

  test "chained #[] and #[]= calls" do
    expected = CallNode(
      CallNode(
        expression("foo"),
        nil,
        BRACKET_LEFT_RIGHT("["),
        BRACKET_LEFT("["),
        ArgumentsNode([expression("bar")]),
        BRACKET_RIGHT("]"),
        nil,
        "[]"
      ),
      nil,
      BRACKET_LEFT_RIGHT_EQUAL("["),
      BRACKET_LEFT("["),
      ArgumentsNode([expression("baz"), expression("qux")]),
      BRACKET_RIGHT("]"),
      nil,
      "[]="
    )

    assert_parses expected, "foo[bar][baz] = qux"
  end

  test "nested #[] and #[]= calls" do
    expected = CallNode(
      expression("foo"),
      nil,
      BRACKET_LEFT_RIGHT("["),
      BRACKET_LEFT("["),
      ArgumentsNode([
        CallNode(
          expression("bar"),
          nil,
          BRACKET_LEFT_RIGHT_EQUAL("["),
          BRACKET_LEFT("["),
          ArgumentsNode([expression("baz"), expression("qux")]),
          BRACKET_RIGHT("]"),
          nil,
          "[]="
        ),
      ]),
      BRACKET_RIGHT("]"),
      nil,
      "[]"
    )

    assert_parses expected, "foo[bar[baz] = qux]"
  end

  test "#[] call with block" do
    expected = CallNode(
      expression("foo"),
      nil,
      BRACKET_LEFT_RIGHT("["),
      BRACKET_LEFT("["),
      ArgumentsNode([expression("bar")]),
      BRACKET_RIGHT("]"),
      BlockNode(
        BRACE_LEFT("{"),
        nil,
        Statements([expression("baz")]),
        BRACE_RIGHT("}")
      ),
      "[]"
    )

    assert_parses expected, "foo[bar] { baz }"
  end

  test "encoding magic comment" do
    assert YARP.parse("#encoding: utf-8").errors.empty?
    assert YARP.parse("#encoding: UTF-8").errors.empty?
    assert YARP.parse("# -*- encoding: UTF-8 -*-").errors.empty?
    assert YARP.parse("# -*- encoding: utf-8 -*-").errors.empty?
    refute YARP.parse("#encoding: utf8").errors.empty?
  end

  test "multiline string addition" do
    expected = CallNode(
      StringNode(
        STRING_BEGIN("\""),
        STRING_CONTENT("foo"),
        STRING_END("\""),
        "foo"
      ),
      nil,
      PLUS("+"),
      nil,
      ArgumentsNode(
        [StringNode(
           STRING_BEGIN("\""),
           STRING_CONTENT("bar"),
           STRING_END("\""),
           "bar"
         )]
      ),
      nil,
      nil,
      "+"
    )

    assert_parses expected, "\"foo\" +\n\n\"bar\""
  end

  test "each block curly braces" do
    expected = CallNode(
      CallNode(nil, nil, IDENTIFIER("x"), nil, nil, nil, nil, "x"),
      DOT("."),
      IDENTIFIER("each"),
      nil,
      nil,
      nil,
      BlockNode(BRACE_LEFT("{"), nil, nil, BRACE_RIGHT("}")),
      "each"
    )

    assert_parses expected, "x.each { }"
  end

  test "method call with block with one argument" do
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("foo"),
      nil,
      nil,
      nil,
      BlockNode(
        BRACE_LEFT("{"),
        ParametersNode(
          [RequiredParameterNode(IDENTIFIER("x"))],
          [],
          nil,
          [],
          nil,
          nil
        ),
        nil,
        BRACE_RIGHT("}")
      ),
      "foo"
    )

    assert_parses expected, "foo { |x| }"
  end

  test "method call with block and arguments" do
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("foo"),
      nil,
      nil,
      nil,
      BlockNode(
        BRACE_LEFT("{"),
        ParametersNode(
          [RequiredParameterNode(IDENTIFIER("x"))],
          [OptionalParameterNode(
            IDENTIFIER("y"),
            EQUAL("="),
            IntegerNode()
          )],
          nil,
          [KeywordParameterNode(LABEL("z:"), nil)],
          nil,
          nil
        ),
        Statements([LocalVariableRead(IDENTIFIER("x"))]),
        BRACE_RIGHT("}")
      ),
      "foo"
    )

    assert_parses expected, "foo { |x, y = 2, z:| x }"
  end

  test "block with normal args before the block" do
    expected = CallNode(
      CallNode(nil, nil, IDENTIFIER("x"), nil, nil, nil, nil, "x"),
      DOT("."),
      IDENTIFIER("reduce"),
      PARENTHESIS_LEFT("("),
      ArgumentsNode([IntegerNode()]),
      PARENTHESIS_RIGHT(")"),
      BlockNode(
        BRACE_LEFT("{"),
        ParametersNode(
          [RequiredParameterNode(IDENTIFIER("x")),
          RequiredParameterNode(IDENTIFIER("memo"))],
          [],
          nil,
          [],
          nil,
          nil
        ),
        Statements(
          [OperatorAssignmentNode(
            LocalVariableRead(IDENTIFIER("memo")),
            PLUS_EQUAL("+="),
            LocalVariableRead(IDENTIFIER("x"))
          )]
        ),
        BRACE_RIGHT("}")
      ),
      "reduce"
    )

    assert_parses expected, "x.reduce(0) { |x, memo| memo += x }"
  end

  test "def + without parentheses" do
    expected = DefNode(
      PLUS("+"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def +\nend"
  end

  test "def + with parentheses" do
    expected = DefNode(
      PLUS("+"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      Location(),
      Location(),
      nil,
      Location()
    )

    assert_parses expected, "def +()\nend"
  end

  test "def + with required parameter" do
    expected = DefNode(
      PLUS("+"),
      nil,
      ParametersNode(
        [RequiredParameterNode(IDENTIFIER("b"))],
        [],
        nil,
        [],
        nil,
        nil
      ),
      Statements([]),
      Scope([IDENTIFIER("b")]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def + b\nend"
  end

  test "def + with keyword rest parameter" do
    expected = DefNode(
      PLUS("+"),
      nil,
      ParametersNode(
        [],
        [],
        nil,
        [],
        KeywordRestParameterNode(STAR_STAR("**"), IDENTIFIER("b")),
        nil
      ),
      Statements([]),
      Scope([IDENTIFIER("b")]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def + **b\nend"
  end

  test "def -" do
    expected = DefNode(
      MINUS("-"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def -\nend"
  end

  test "def ==" do
    expected = DefNode(
      EQUAL_EQUAL("=="),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def ==\nend"
  end

  test "def |" do
    expected = DefNode(
      PIPE("|"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def |\nend"
  end

  test "def ^" do
    expected = DefNode(
      CARET("^"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def ^\nend"
  end

  test "def &" do
    expected = DefNode(
      AMPERSAND("&"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def &\nend"
  end

  test "def <=>" do
    expected = DefNode(
      LESS_EQUAL_GREATER("<=>"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def <=>\nend"
  end

  test "def ===" do
    expected = DefNode(
      EQUAL_EQUAL_EQUAL("==="),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def ===\nend"
  end

  test "def =~" do
    expected = DefNode(
      EQUAL_TILDE("=~"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def =~\nend"
  end

  test "def !~" do
    expected = DefNode(
      BANG_TILDE("!~"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def !~\nend"
  end

  test "def >" do
    expected = DefNode(
      GREATER(">"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def >\nend"
  end

  test "def >=" do
    expected = DefNode(
      GREATER_EQUAL(">="),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def >=\nend"
  end

  test "def <" do
    expected = DefNode(
      LESS("<"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def <\nend"
  end

  test "def <=" do
    expected = DefNode(
      LESS_EQUAL("<="),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def <=\nend"
  end

  test "def !=" do
    expected = DefNode(
      BANG_EQUAL("!="),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def !=\nend"
  end

  test "def <<" do
    expected = DefNode(
      LESS_LESS("<<"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def <<\nend"
  end

  test "def >>" do
    expected = DefNode(
      GREATER_GREATER(">>"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def >>\nend"
  end

  test "def *" do
    expected = DefNode(
      STAR("*"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def *\nend"
  end

  test "def /" do
    expected = DefNode(
      SLASH("/"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def /\nend"
  end

  test "def %" do
    expected = DefNode(
      PERCENT("%"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def %\nend"
  end

  test "def **" do
    expected = DefNode(
      STAR_STAR("**"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def **\nend"
  end

  test "def !" do
    expected = DefNode(
      BANG("!"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def !\nend"
  end

  test "def ~" do
    expected = DefNode(
      TILDE("~"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def ~\nend"
  end

  test "def +@" do
    expected = DefNode(
      PLUS_AT("+@"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def +@\nend"
  end

  test "def -@" do
    expected = DefNode(
      MINUS_AT("-@"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def -@\nend"
  end

  test "def []" do
    expected = DefNode(
      BRACKET_LEFT_RIGHT("[]"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def []\nend"
  end

  test "def []=" do
    expected = DefNode(
      BRACKET_LEFT_RIGHT_EQUAL("[]="),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def []=\nend"
  end

  test "def + with self receiver" do
    expected = DefNode(
      PLUS("+"),
      SelfNode(),
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      Location(),
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def self.+\nend"
  end

  test "def `" do
    expected = DefNode(
      BACKTICK("`"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def `\nend"
  end

  test "def self.`" do
    expected = DefNode(
      BACKTICK("`"),
      SelfNode(),
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      Location(),
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def self.`\nend"
  end

  test "def % with self receiver" do
    expected = DefNode(
      PLUS("+"),
      SelfNode(),
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      Location(),
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def self.+\nend"
  end

  test "def def" do
    expected = DefNode(
      KEYWORD_DEF("def"),
      nil,
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      nil,
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def def\nend"
  end

  test "def ensure with self receiver" do
    expected = DefNode(
      KEYWORD_ENSURE("ensure"),
      SelfNode(),
      ParametersNode([], [], nil, [], nil, nil),
      Statements([]),
      Scope([]),
      Location(),
      Location(),
      nil,
      nil,
      nil,
      Location()
    )

    assert_parses expected, "def self.ensure\nend"
  end

  test "unary minus precedence" do
    expected = CallNode(
      expression("-foo"),
      nil,
      STAR("*"),
      nil,
      ArgumentsNode([expression("bar")]),
      nil,
      nil,
      "*"
    )

    assert_parses expected, "-foo*bar"
  end

  test "unary plus precedence" do
    expected = CallNode(
      expression("+foo"),
      nil,
      STAR_STAR("**"),
      nil,
      ArgumentsNode([expression("bar")]),
      nil,
      nil,
      "**"
    )

    assert_parses expected, "+foo**bar"
  end

  test "simple stabby lambda with braces" do
    expected = LambdaNode(
      Scope([]),
      nil,
      BlockVarNode(
        ParametersNode([], [], nil, [], nil, nil),
        []
      ),
      nil,
      Statements([expression("foo")])
    )

    assert_parses expected, "-> { foo }"
  end

  test "simple stabby lambda with do...end" do
    expected = LambdaNode(
      Scope([]),
      nil,
      BlockVarNode(
        ParametersNode([], [], nil, [], nil, nil),
        []
      ),
      nil,
      Statements([expression("foo")])
    )

    assert_parses expected, "-> do; foo; end"
  end

  test "stabby lambda with parameters with braces" do
    expected = LambdaNode(
      Scope([
        IDENTIFIER("a"),
        IDENTIFIER("b"),
        LABEL("c"),
        LABEL("d"),
        IDENTIFIER("e"),
        IDENTIFIER("f"),
        IDENTIFIER("g")
      ]),
      PARENTHESIS_LEFT("("),
      BlockVarNode(
        ParametersNode(
          [RequiredParameterNode(IDENTIFIER("a"))],
          [OptionalParameterNode(
            IDENTIFIER("b"),
            EQUAL("="),
            IntegerNode()
          )],
          RestParameterNode(STAR("*"), IDENTIFIER("e")),
          [KeywordParameterNode(LABEL("c:"), nil), KeywordParameterNode(LABEL("d:"), nil)],
          KeywordRestParameterNode(STAR_STAR("**"), IDENTIFIER("f")),
          BlockParameterNode(IDENTIFIER("g"), Location())
        ),
        []
      ),
      PARENTHESIS_RIGHT(")"),
      Statements([expression("a")])
    )

    assert_parses expected, "-> (a, b = 1, c:, d:, *e, **f, &g) { a }"
  end

  test "stabby lambda with non-parenthesised parameters with braces" do
    expected = LambdaNode(
      Scope([
        IDENTIFIER("a"),
        IDENTIFIER("b"),
        LABEL("c"),
        LABEL("d"),
        IDENTIFIER("e"),
      ]),
      nil,
      BlockVarNode(
        ParametersNode(
          [RequiredParameterNode(IDENTIFIER("a"))],
          [OptionalParameterNode(
            IDENTIFIER("b"),
            EQUAL("="),
            IntegerNode()
          )],
          nil,
          [KeywordParameterNode(LABEL("c:"), nil), KeywordParameterNode(LABEL("d:"), nil)],
          nil,
          BlockParameterNode(IDENTIFIER("e"), Location())
        ),
        []
      ),
      nil,
      Statements([expression("a")])
    )

    assert_parses expected, "-> a, b = 1, c:, d:, &e { a }"
  end

  test "stabby lambda with parameters with do..end" do
    expected = LambdaNode(
      Scope([
        IDENTIFIER("a"),
        IDENTIFIER("b"),
        LABEL("c"),
        LABEL("d"),
        IDENTIFIER("e"),
        IDENTIFIER("f"),
        IDENTIFIER("g")
      ]),
      PARENTHESIS_LEFT("("),
      BlockVarNode(
        ParametersNode(
          [RequiredParameterNode(IDENTIFIER("a"))],
          [OptionalParameterNode(
            IDENTIFIER("b"),
            EQUAL("="),
            IntegerNode()
          )],
          RestParameterNode(STAR("*"), IDENTIFIER("e")),
          [KeywordParameterNode(LABEL("c:"), nil), KeywordParameterNode(LABEL("d:"), nil)],
          KeywordRestParameterNode(STAR_STAR("**"), IDENTIFIER("f")),
          BlockParameterNode(IDENTIFIER("g"), Location())
        ),
        []
      ),
      PARENTHESIS_RIGHT(")"),
      Statements([expression("a")])
    )

    assert_parses expected, "-> (a, b = 1, c:, d:, *e, **f, &g) do\n  a\nend"
  end

  test "nested lambdas" do
    expected = LambdaNode(
      Scope([IDENTIFIER("a")]),
      PARENTHESIS_LEFT("("),
      BlockVarNode(
        ParametersNode(
          [RequiredParameterNode(IDENTIFIER("a"))],
          [],
          nil,
          [],
          nil,
          nil
        ),
        []
      ),
      PARENTHESIS_RIGHT(")"),
      Statements(
        [LambdaNode(
          Scope([IDENTIFIER("b")]),
          nil,
          BlockVarNode(
            ParametersNode(
              [RequiredParameterNode(IDENTIFIER("b"))],
              [],
              nil,
              [],
              nil,
              nil
            ),
            []
          ),
          nil,
          Statements([CallNode(
            expression("a"),
            nil,
            STAR("*"),
            nil,
            ArgumentsNode([expression("b")]),
            nil,
            nil,
            "*"
          )])
        )]
      )
    )

    assert_parses expected, "-> (a) { -> b { a * b } }"
  end

  test "lambdas with block locals" do
    expected = LambdaNode(
      Scope([IDENTIFIER("a"), IDENTIFIER("b"), IDENTIFIER("c"), IDENTIFIER("d")]),
      PARENTHESIS_LEFT("("),
      BlockVarNode(
        ParametersNode(
          [RequiredParameterNode(IDENTIFIER("a"))],
          [],
          nil,
          [],
          nil,
          nil
        ),
        [IDENTIFIER("b"), IDENTIFIER("c"), IDENTIFIER("d")]
      ),
      PARENTHESIS_RIGHT(")"),
      Statements([expression("b")])
    )

    assert_parses expected, "-> (a; b, c, d) { b }"
  end

  test "blocks with keywords" do
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("foo"),
      nil,
      nil,
      nil,
      BlockNode(KEYWORD_DO("do"), nil, nil, KEYWORD_END("end")),
      "foo"
    )

    assert_parses expected, "foo do end"
  end

  test "blocks with keywords on commands with arguments" do
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("foo"),
      nil,
      ArgumentsNode([expression("bar")]),
      nil,
      BlockNode(KEYWORD_DO("do"), nil, nil, KEYWORD_END("end")),
      "foo"
    )

    assert_parses expected, "foo bar do end"
  end

  test "blocks with keywords on nested commands with arguments" do
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("foo"),
      nil,
      ArgumentsNode([expression("bar baz")]),
      nil,
      BlockNode(KEYWORD_DO("do"), nil, nil, KEYWORD_END("end")),
      "foo"
    )

    assert_parses expected, "foo bar baz do end"
  end

  test "blocks with keywords on arguments within parentheses" do
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("foo"),
      nil,
      ArgumentsNode([
        expression("bar"),
        ParenthesesNode(PARENTHESIS_LEFT("("), Statements([expression("baz do end")]), PARENTHESIS_RIGHT(")"))
      ]),
      nil,
      nil,
      "foo"
    )

    assert_parses expected, "foo bar, (baz do end)"
  end

  test "method call with hash and a do block" do
    expected = CallNode(
      nil,
      nil,
      IDENTIFIER("foo"),
      nil,
      ArgumentsNode([
        SymbolNode(SYMBOL_BEGIN(":"), IDENTIFIER("a"), nil),
        HashNode(
          nil,
          [AssocNode(
              SymbolNode(nil, LABEL("b"), LABEL_END(":")),
              TrueNode(),
              nil
            )],
          nil
        )
      ]),
      nil,
      BlockNode(
        KEYWORD_DO("do"),
        ParametersNode([
          RequiredParameterNode(IDENTIFIER("a")),
          RequiredParameterNode(IDENTIFIER("b"))
          ], [], nil, [], nil, nil),
        Statements([
          CallNode(
            nil,
            nil, IDENTIFIER("puts"),
            nil,
            ArgumentsNode([LocalVariableRead(IDENTIFIER("a"))]),
            nil,
            nil,
            "puts"
          )]),
        KEYWORD_END("end")
      ),
      "foo"
    )

    assert_parses expected, "foo :a, b: true do |a, b| puts a end"
  end

  private

  def assert_serializes(expected, source)
    YARP.load(source, YARP.dump(source)) => YARP::Program[statements: YARP::Statements[body: [*, node]]]
    assert_equal expected, node
  end

  def assert_parses(expected, source)
    assert_equal expected, expression(source)
    assert_serializes expected, source

    YARP.lex_ripper(source).zip(YARP.lex_compat(source)).each do |(ripper, yarp)|
      assert_equal ripper[0...-1], yarp[0...-1]
    end
  end

  def expression(source)
    result = YARP.parse(source)
    assert_empty result.errors, PP.pp(result.node, +"")

    result.node => YARP::Program[statements: YARP::Statements[body: [*, node]]]
    node
  end

  # This method is just named this way to mirror the other DSL methods.
  def Location()
    YARP::Location.new(0, 0)
  end
end

# Here we're going to override the == method in order to avoid having to
# specifically track offsets and compare them.
YARP::Location.prepend(
  Module.new do
    def ==(other)
      true
    end
  end
)
