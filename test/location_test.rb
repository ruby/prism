# frozen_string_literal: true

require "test_helper"

module YARP
  class LocationTest < Test::Unit::TestCase
    def test_AliasNode
      assert_location(AliasNode, "alias foo bar")
    end

    def test_AlternationPatternNode
      assert_location(AlternationPatternNode, "foo => bar | baz", 7...16, &:pattern)
    end

    def test_AndNode
      assert_location(AndNode, "foo and bar")
      assert_location(AndNode, "foo && bar")
    end

    def test_ArgumentsNode
      assert_location(ArgumentsNode, "foo(bar, baz, qux)", 4...17, &:arguments)
    end

    def test_ArrayNode
      assert_location(ArrayNode, "[foo, bar, baz]")
      assert_location(ArrayNode, "%i[foo bar baz]")
      assert_location(ArrayNode, "%I[foo bar baz]")
      assert_location(ArrayNode, "%w[foo bar baz]")
      assert_location(ArrayNode, "%W[foo bar baz]")
    end

    def test_ArrayPatternNode
      assert_location(ArrayPatternNode, "foo => bar, baz", 7...15, &:pattern)
      assert_location(ArrayPatternNode, "foo => [bar, baz]", 7...17, &:pattern)
      assert_location(ArrayPatternNode, "foo => *bar", 7...11, &:pattern)
      assert_location(ArrayPatternNode, "foo => []", 7...9, &:pattern)
      assert_location(ArrayPatternNode, "foo => Foo[]", 7...12, &:pattern)
      assert_location(ArrayPatternNode, "foo => Foo[bar]", 7...15, &:pattern)
    end

    def test_AssocNode
      assert_location(AssocNode, "{ foo: :bar }", 2...11) { |node| node.elements.first }
      assert_location(AssocNode, "{ :foo => :bar }", 2...14) { |node| node.elements.first }
      assert_location(AssocNode, "foo(bar: :baz)", 4...13) { |node| node.arguments.arguments.first.elements.first }
    end

    def test_AssocSplatNode
      assert_location(AssocSplatNode, "{ **foo }", 2...7) { |node| node.elements.first }
      assert_location(AssocSplatNode, "foo(**bar)", 4...9) { |node| node.arguments.arguments.first.elements.first }
    end

    def test_BeginNode
      assert_location(BeginNode, "begin foo end")
      assert_location(BeginNode, "begin foo rescue bar end")
      assert_location(BeginNode, "begin foo; rescue bar\nelse baz end")
      assert_location(BeginNode, "begin foo; rescue bar\nelse baz\nensure qux end")

      assert_location(BeginNode, "class Foo\nrescue then end", &:statements)
      assert_location(BeginNode, "module Foo\nrescue then end", &:statements)
    end

    def test_BlockArgumentNode
      assert_location(BlockArgumentNode, "foo(&bar)", 4...8) { |node| node.arguments.arguments.last }
    end

    def test_BlockNode
      assert_location(BlockNode, "foo {}", 4...6, &:block)
      assert_location(BlockNode, "foo do end", 4...10, &:block)
    end

    def test_BlockParameterNode
      assert_location(BlockParameterNode, "def foo(&bar) end", 8...12) { |node| node.parameters.block }
    end

    def test_BlockParametersNode
      assert_location(BlockParametersNode, "foo { || }", 6...8) { |node| node.block.parameters }
      assert_location(BlockParametersNode, "foo { |bar| baz }", 6...11) { |node| node.block.parameters }
      assert_location(BlockParametersNode, "foo { |bar; baz| baz }", 6...16) { |node| node.block.parameters }

      assert_location(BlockParametersNode, "-> () {}", 3...5, &:parameters)
      assert_location(BlockParametersNode, "-> (bar) { baz }", 3...8, &:parameters)
      assert_location(BlockParametersNode, "-> (bar; baz) { baz }", 3...13, &:parameters)
    end

    def test_BreakNode
      assert_location(BreakNode, "break")
      assert_location(BreakNode, "break foo")
      assert_location(BreakNode, "break foo, bar")
      assert_location(BreakNode, "break(foo)")
    end

    def test_CallNode
      assert_location(CallNode, "foo")
      assert_location(CallNode, "foo?")
      assert_location(CallNode, "foo!")

      assert_location(CallNode, "foo()")
      assert_location(CallNode, "foo?()")
      assert_location(CallNode, "foo!()")

      assert_location(CallNode, "foo(bar)")
      assert_location(CallNode, "foo?(bar)")
      assert_location(CallNode, "foo!(bar)")

      assert_location(CallNode, "!foo")
      assert_location(CallNode, "~foo")
      assert_location(CallNode, "+foo")
      assert_location(CallNode, "-foo")

      assert_location(CallNode, "not foo")
      assert_location(CallNode, "not(foo)")
      assert_location(CallNode, "not()")

      assert_location(CallNode, "foo + bar")
      assert_location(CallNode, "foo -\n  bar")

      assert_location(CallNode, "Foo()")
      assert_location(CallNode, "Foo(bar)")

      assert_location(CallNode, "Foo::Bar()")
      assert_location(CallNode, "Foo::Bar(baz)")

      assert_location(CallNode, "Foo::bar")
      assert_location(CallNode, "Foo::bar()")
      assert_location(CallNode, "Foo::bar(baz)")

      assert_location(CallNode, "Foo.bar")
      assert_location(CallNode, "Foo.bar()")
      assert_location(CallNode, "Foo.bar(baz)")

      assert_location(CallNode, "foo::bar")
      assert_location(CallNode, "foo::bar()")
      assert_location(CallNode, "foo::bar(baz)")

      assert_location(CallNode, "foo.bar")
      assert_location(CallNode, "foo.bar()")
      assert_location(CallNode, "foo.bar(baz)")

      assert_location(CallNode, "foo&.bar")
      assert_location(CallNode, "foo&.bar()")
      assert_location(CallNode, "foo&.bar(baz)")

      assert_location(CallNode, "foo[]")
      assert_location(CallNode, "foo[bar]")
      assert_location(CallNode, "foo[bar, baz]")

      assert_location(CallNode, "foo[] = 1")
      assert_location(CallNode, "foo[bar] = 1")
      assert_location(CallNode, "foo[bar, baz] = 1")

      assert_location(CallNode, "foo.()")
      assert_location(CallNode, "foo.(bar)")

      assert_location(CallNode, "foo&.()")
      assert_location(CallNode, "foo&.(bar)")

      assert_location(CallNode, "foo::()")
      assert_location(CallNode, "foo::(bar)")
      assert_location(CallNode, "foo::(bar, baz)")

      assert_location(CallNode, "foo bar baz")
      assert_location(CallNode, "foo bar('baz')")
    end

    def test_CaseNode
      assert_location(CaseNode, "case foo; when bar; end")
      assert_location(CaseNode, "case foo; when bar; else; end")
      assert_location(CaseNode, "case foo; when bar; when baz; end")
      assert_location(CaseNode, "case foo; when bar; when baz; else; end")
    end

    def test_ClassVariableReadNode
      assert_location(ClassVariableReadNode, "@@foo")
    end

    def test_ClassVariableWriteNode
      assert_location(ClassVariableWriteNode, "@@foo = bar")
    end

    def test_ConstantPathNode
      assert_location(ConstantPathNode, "Foo::Bar")
      assert_location(ConstantPathNode, "::Foo")
      assert_location(ConstantPathNode, "::Foo::Bar")
    end

    def test_ConstantReadNode
      assert_location(ConstantReadNode, "Foo")
      assert_location(ConstantReadNode, "Foo::Bar", 5...8, &:child)
    end

    def test_FalseNode
      assert_location(FalseNode, "false")
    end

    def test_FloatNode
      assert_location(FloatNode, "0.0")
      assert_location(FloatNode, "1.0")
      assert_location(FloatNode, "1.0e10")
      assert_location(FloatNode, "1.0e-10")
    end

    def test_ForNode
      assert_location(ForNode, "for foo in bar; end")
      assert_location(ForNode, "for foo, bar in baz do end")
    end

    def test_ForwardingArgumentsNode
      assert_location(ForwardingArgumentsNode, "def foo(...); bar(...); end", 18...21) do |node|
        node.statements.body.first.arguments.arguments.first
      end
    end

    def test_ForwardingParameterNode
      assert_location(ForwardingParameterNode, "def foo(...); end", 8...11) do |node|
        node.parameters.keyword_rest
      end
    end

    def test_ForwardingSuperNode
      assert_location(ForwardingSuperNode, "super")
      assert_location(ForwardingSuperNode, "super {}")
    end

    def test_HashNode
      assert_location(HashNode, "{ foo: 2 }")
      assert_location(HashNode, "{ \nfoo: 2, \nbar: 3 \n}")
    end

    def test_IfNode
      assert_location(IfNode, "if type in 1;elsif type in B;end")
    end

    def test_ImaginaryNode
      assert_location(ImaginaryNode, "1i")
      assert_location(ImaginaryNode, "1ri")
    end

    def test_InstanceVariableReadNode
      assert_location(InstanceVariableReadNode, "@foo")
    end

    def test_InstanceVariableWriteNode
      assert_location(InstanceVariableWriteNode, "@foo = bar")
    end

    def test_IntegerNode
      assert_location(IntegerNode, "0")
      assert_location(IntegerNode, "1")
      assert_location(IntegerNode, "1_000")
      assert_location(IntegerNode, "0x1")
      assert_location(IntegerNode, "0x1_000")
      assert_location(IntegerNode, "0b1")
      assert_location(IntegerNode, "0b1_000")
      assert_location(IntegerNode, "0o1")
      assert_location(IntegerNode, "0o1_000")
    end

    def test_InterpolatedRegularExpressionNode
      assert_location(InterpolatedRegularExpressionNode, "/\#{foo}/")
    end

    def test_InterpolatedStringNode
      assert_location(InterpolatedStringNode, "<<~A\nhello world\nA")
    end

    def test_InterpolatedSymbolNode
      assert_location(InterpolatedSymbolNode, ':"#{foo}bar"')
    end

    def test_InterpolatedXStringNode
      assert_location(InterpolatedXStringNode, '`foo #{bar} baz`')
    end

    def test_KeywordHashNode
      assert_location(KeywordHashNode, "foo(a, b: 1)", 7...11) { |node| node.arguments.arguments[1] }
    end

    def test_NextNode
      assert_location(NextNode, "next")
      assert_location(NextNode, "next foo")
      assert_location(NextNode, "next foo, bar")
      assert_location(NextNode, "next(foo)")
    end

    def test_NilNode
      assert_location(NilNode, "nil")
    end

    def test_NoKeywordsParameterNode
      assert_location(NoKeywordsParameterNode, "def foo(**nil); end", 8...13) { |node| node.parameters.keyword_rest }
    end

    def test_OperatorAndAssignmentNode
      assert_location(OperatorAndAssignmentNode, "foo = 1; foo &&= bar", 9...20)

      assert_location(OperatorAndAssignmentNode, "foo &&= bar")
      assert_location(OperatorAndAssignmentNode, "foo.foo &&= bar")
      assert_location(OperatorAndAssignmentNode, "foo[foo] &&= bar")

      assert_location(OperatorAndAssignmentNode, "@foo &&= bar")
      assert_location(OperatorAndAssignmentNode, "@@foo &&= bar")
      assert_location(OperatorAndAssignmentNode, "$foo &&= bar")

      assert_location(OperatorAndAssignmentNode, "Foo &&= bar")
      assert_location(OperatorAndAssignmentNode, "Foo::Foo &&= bar")
    end

    def test_OperatorOrAssignmentNode
      assert_location(OperatorOrAssignmentNode, "foo = 1; foo ||= bar", 9...20)

      assert_location(OperatorOrAssignmentNode, "foo ||= bar")
      assert_location(OperatorOrAssignmentNode, "foo.foo ||= bar")
      assert_location(OperatorOrAssignmentNode, "foo[foo] ||= bar")

      assert_location(OperatorOrAssignmentNode, "@foo ||= bar")
      assert_location(OperatorOrAssignmentNode, "@@foo ||= bar")
      assert_location(OperatorOrAssignmentNode, "$foo ||= bar")

      assert_location(OperatorOrAssignmentNode, "Foo ||= bar")
      assert_location(OperatorOrAssignmentNode, "Foo::Foo ||= bar")
    end

    def test_OrNode
      assert_location(OrNode, "foo || bar")
      assert_location(OrNode, "foo or bar")
    end

    def test_ParenthesesNode
      assert_location(ParenthesesNode, "()")
      assert_location(ParenthesesNode, "(foo)")
      assert_location(ParenthesesNode, "foo (bar), baz", 4...9) { |node| node.arguments.arguments.first }
      assert_location(ParenthesesNode, "def (foo).bar; end", 4...9, &:receiver)
    end

    def test_PostExecutionNode
      assert_location(PostExecutionNode, "END { foo }")
    end

    def test_PreExecutionNode
      assert_location(PreExecutionNode, "BEGIN { foo }")
    end

    def test_RangeNode
      assert_location(RangeNode, "1..2")
      assert_location(RangeNode, "1...2")

      assert_location(RangeNode, "..2")
      assert_location(RangeNode, "...2")

      assert_location(RangeNode, "1..")
      assert_location(RangeNode, "1...")
    end

    def test_RationalNode
      assert_location(RationalNode, "1r")
      assert_location(RationalNode, "1.0r")
    end

    def test_RedoNode
      assert_location(RedoNode, "redo")
    end

    def test_RescueNode
      code = <<~RUBY
      begin
        body
      rescue TypeError
      rescue ArgumentError
      end
      RUBY
      assert_location(RescueNode, code, 13...50) { |node| node.rescue_clause }
      assert_location(RescueNode, code, 30...50) { |node| node.rescue_clause.consequent }
    end

    def test_RetryNode
      assert_location(RetryNode, "retry")
    end

    def test_SelfNode
      assert_location(SelfNode, "self")
    end

    def test_SourceEncodingNode
      assert_location(SourceEncodingNode, "__ENCODING__")
    end

    def test_SourceFileNode
      assert_location(SourceFileNode, "__FILE__")
    end

    def test_SourceLineNode
      assert_location(SourceLineNode, "__LINE__")
    end

    def test_StatementsNode
      assert_location(StatementsNode, "foo { 1 }", 6...7) { |node| node.block.statements }

      assert_location(StatementsNode, "(1)", 1...2, &:statements)

      assert_location(StatementsNode, "def foo; 1; end", 9...10, &:statements)
      assert_location(StatementsNode, "def foo = 1", 10...11, &:statements)
      assert_location(StatementsNode, "def foo; 1\n2; end", 9...12, &:statements)

      assert_location(StatementsNode, "if foo; bar; end", 8...11, &:statements)
      assert_location(StatementsNode, "foo if bar", 0...3, &:statements)

      assert_location(StatementsNode, "if foo; foo; elsif bar; bar; end", 24...27) { |node| node.consequent.statements }
      assert_location(StatementsNode, "if foo; foo; else; bar; end", 19...22) { |node| node.consequent.statements }

      assert_location(StatementsNode, "unless foo; bar; end", 12...15, &:statements)
      assert_location(StatementsNode, "foo unless bar", 0...3, &:statements)

      assert_location(StatementsNode, "case; when foo; bar; end", 16...19) { |node| node.conditions.first.statements }

      assert_location(StatementsNode, "while foo; bar; end", 11...14, &:statements)
      assert_location(StatementsNode, "foo while bar", 0...3, &:statements)

      assert_location(StatementsNode, "until foo; bar; end", 11...14, &:statements)
      assert_location(StatementsNode, "foo until bar", 0...3, &:statements)

      assert_location(StatementsNode, "for foo in bar; baz; end", 16...19, &:statements)

      assert_location(StatementsNode, "begin; foo; end", 7...10, &:statements)
      assert_location(StatementsNode, "begin; rescue; foo; end", 15...18) { |node| node.rescue_clause.statements }
      assert_location(StatementsNode, "begin; ensure; foo; end", 15...18) { |node| node.ensure_clause.statements }
      assert_location(StatementsNode, "begin; rescue; else; foo; end", 21...24) { |node| node.else_clause.statements }

      assert_location(StatementsNode, "class Foo; foo; end", 11...14, &:statements)
      assert_location(StatementsNode, "module Foo; foo; end", 12...15, &:statements)
      assert_location(StatementsNode, "class << self; foo; end", 15...18, &:statements)

      assert_location(StatementsNode, "-> { foo }", 5...8, &:statements)
      assert_location(StatementsNode, "BEGIN { foo }", 8...11, &:statements)
      assert_location(StatementsNode, "END { foo }", 6...9, &:statements)

      assert_location(StatementsNode, "\"\#{foo}\"", 3...6) { |node| node.parts.first.statements }
    end

    def test_SuperNode
      assert_location(SuperNode, "super foo")
      assert_location(SuperNode, "super foo, bar")

      assert_location(SuperNode, "super()")
      assert_location(SuperNode, "super(foo)")
      assert_location(SuperNode, "super(foo, bar)")

      assert_location(SuperNode, "super() {}")
    end

    def test_TrueNode
      assert_location(TrueNode, "true")
    end

    def test_UndefNode
      assert_location(UndefNode, "undef foo")
      assert_location(UndefNode, "undef foo, bar")
    end

    def test_UntilNode
      assert_location(UntilNode, "foo = bar until baz")
      assert_location(UntilNode, "until bar;baz;end")
    end

    def test_WhileNode
      assert_location(WhileNode, "foo = bar while foo != baz")
      assert_location(WhileNode, "while a;bar;baz;end")
    end

    def test_XStringNode
      assert_location(XStringNode, "`foo`")
      assert_location(XStringNode, "%x[foo]")
    end

    private

    def assert_location(kind, source, expected = 0...source.length)
      YARP.parse_dup(source) => ParseResult[comments: [], errors: [], value: node]

      node => ProgramNode[statements: [*, node]]
      node = yield node if block_given?

      assert_kind_of kind, node
      assert_equal expected.begin, node.location.start_offset
      assert_equal expected.end, node.location.end_offset
    end
  end
end
