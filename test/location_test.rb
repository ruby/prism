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

    test "BlockNode" do
      assert_location(BlockNode, "foo {}", 4...6) { |node| node.arguments.arguments.last }
    end

    test "BlockParameterNode" do
      assert_location(BlockParameterNode, "def foo(&bar) end", 8...12) { |node| node.parameters.block }
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

      assert_location(CallNode, "foo.()")
      assert_location(CallNode, "foo.(bar)")

      assert_location(CallNode, "foo&.()")
      assert_location(CallNode, "foo&.(bar)")

      assert_location(CallNode, "foo::()")
      assert_location(CallNode, "foo::(bar)")
      assert_location(CallNode, "foo::(bar, baz)")
    end

    test "NextNode" do
      assert_location(NextNode, "next")
      assert_location(NextNode, "next foo")
      assert_location(NextNode, "next foo, bar")
      assert_location(NextNode, "next(foo)")
    end

    test "UndefNode" do
      assert_location(UndefNode, "undef foo")
      assert_location(UndefNode, "undef foo, bar")
    end

    private

    def assert_location(kind, source, expected = 0...source.length)
      YARP.parse(source) => ParseResult[comments: [], errors: [], node:]

      node => Program[statements: [*, node]]
      node = yield node if block_given?

      assert_kind_of kind, node
      assert_equal expected.begin, node.location.start_offset
      assert_equal expected.end, node.location.end_offset
    end
  end
end
