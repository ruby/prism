# frozen_string_literal: true

require "test_helper"

module YARP
  class LocationTest < Test::Unit::TestCase
    test "AliasNode" do
      assert_location(AliasNode, "alias foo bar")
    end

    test "AndNode" do
      assert_location(AndNode, "foo and bar")
      assert_location(AndNode, "foo && bar")
    end

    test "ArgumentsNode" do
      assert_location(ArgumentsNode, "foo(bar, baz, qux)", 4...17, &:arguments)
    end

    test "ArrayNode" do
      assert_location(ArrayNode, "[foo, bar, baz]")
      assert_location(ArrayNode, "%i[foo bar baz]")
      assert_location(ArrayNode, "%I[foo bar baz]")
      assert_location(ArrayNode, "%w[foo bar baz]")
      assert_location(ArrayNode, "%W[foo bar baz]")
    end

    test "AssocNode" do
      assert_location(AssocNode, "{ foo: :bar }", 2...11) { |node| node.elements.first }
      assert_location(AssocNode, "{ :foo => :bar }", 2...14) { |node| node.elements.first }
    end

    test "AssocSplatNode" do
      assert_location(AssocSplatNode, "{ **foo }", 2...7) { |node| node.elements.first }
    end

    test "BeginNode" do
      assert_location(BeginNode, "begin foo end")
      assert_location(BeginNode, "begin foo rescue bar end")
      assert_location(BeginNode, "begin foo rescue bar\nelse baz end")
      assert_location(BeginNode, "begin foo rescue bar\nelse baz\nensure qux end")
    end

    test "BlockArgumentNode" do
      assert_location(BlockArgumentNode, "foo(&bar)", 4...8) { |node| node.arguments.arguments.last }
    end

    test "BlockNode" do
      assert_location(BlockNode, "foo {}", 4...6, &:block)
      assert_location(BlockNode, "foo do end", 4...10, &:block)
    end

    test "BlockParameterNode" do
      assert_location(BlockParameterNode, "def foo(&bar) end", 8...12) { |node| node.parameters.block }
    end

    test "BlockParametersNode" do
      assert_location(BlockParametersNode, "foo { |bar| baz }", 7...10) { |node| node.block.parameters }
      assert_location(BlockParametersNode, "foo { |bar; baz| baz }", 7...15) { |node| node.block.parameters }
    end

    test "BreakNode" do
      assert_location(BreakNode, "break")
      assert_location(BreakNode, "break foo")
      assert_location(BreakNode, "break foo, bar")
      assert_location(BreakNode, "break(foo)")
    end

    test "CallNode" do
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
    end

    test "CaseNode" do
      assert_location(CaseNode, "case foo; when bar; end")
      assert_location(CaseNode, "case foo; when bar; else; end")
      assert_location(CaseNode, "case foo; when bar; when baz; end")
      assert_location(CaseNode, "case foo; when bar; when baz; else; end")
    end

    test "ClassVariableReadNode" do
      assert_location(ClassVariableReadNode, "@@foo")
    end

    test "ClassVariableWriteNode" do
      assert_location(ClassVariableWriteNode, "@@foo = bar")
    end

    test "FalseNode" do
      assert_location(FalseNode, "false")
    end

    test "FloatNode" do
      assert_location(FloatNode, "0.0")
      assert_location(FloatNode, "1.0")
      assert_location(FloatNode, "1.0e10")
      assert_location(FloatNode, "1.0e-10")
    end

    test "ForwardingArgumentsNode" do
      assert_location(ForwardingArgumentsNode, "def foo(...); bar(...); end", 18...21) do |node|
        node.statements.body.first.arguments.arguments.first
      end
    end

    test "ForwardingParameterNode" do
      assert_location(ForwardingParameterNode, "def foo(...); end", 8...11) do |node|
        node.parameters.keyword_rest
      end
    end

    test "ForwardingSuperNode" do
      assert_location(ForwardingSuperNode, "super")
      assert_location(ForwardingSuperNode, "super {}")
    end

    test "ImaginaryNode" do
      assert_location(ImaginaryNode, "1i")
      assert_location(ImaginaryNode, "1ri")
    end

    test "InstanceVariableReadNode" do
      assert_location(InstanceVariableReadNode, "@foo")
    end

    test "InstanceVariableWriteNode" do
      assert_location(InstanceVariableWriteNode, "@foo = bar")
    end

    test "IntegerNode" do
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

    test "NextNode" do
      assert_location(NextNode, "next")
      assert_location(NextNode, "next foo")
      assert_location(NextNode, "next foo, bar")
      assert_location(NextNode, "next(foo)")
    end

    test "PostExecutionNode" do
      assert_location(PostExecutionNode, "END { foo }")
    end

    test "PreExecutionNode" do
      assert_location(PreExecutionNode, "BEGIN { foo }")
    end

    test "RangeNode" do
      assert_location(RangeNode, "1..2")
      assert_location(RangeNode, "1...2")

      assert_location(RangeNode, "..2")
      assert_location(RangeNode, "...2")

      assert_location(RangeNode, "1..")
      assert_location(RangeNode, "1...")
    end

    test "SuperNode" do
      assert_location(SuperNode, "super foo")
      assert_location(SuperNode, "super foo, bar")

      assert_location(SuperNode, "super()")
      assert_location(SuperNode, "super(foo)")
      assert_location(SuperNode, "super(foo, bar)")

      assert_location(SuperNode, "super() {}")
    end

    test "UndefNode" do
      assert_location(UndefNode, "undef foo")
      assert_location(UndefNode, "undef foo, bar")
    end

    test "XStringNode" do
      assert_location(XStringNode, "`foo`")
      assert_location(XStringNode, "%x[foo]")
    end

    private

    def assert_location(kind, source, expected = 0...source.length)
      YARP.parse(source) => ParseResult[comments: [], errors: [], value: node]

      node => ProgramNode[statements: [*, node]]
      node = yield node if block_given?

      assert_kind_of kind, node
      assert_equal expected.begin, node.location.start_offset
      assert_equal expected.end, node.location.end_offset
    end
  end
end
