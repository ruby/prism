# frozen_string_literal: true

require "test_helper"

class LocationTest < Test::Unit::TestCase
  test "AliasNode" do
    assert_location(YARP::AliasNode, "alias foo bar")
  end

  test "AndNode" do
    assert_location(YARP::AndNode, "foo and bar")
  end

  test "ArgumentsNode" do
    assert_location(YARP::ArgumentsNode, "foo(bar, baz, qux)", 4...17, &:arguments)
  end

  test "ArrayNode" do
    assert_location(YARP::ArrayNode, "[foo, bar, baz]")
    assert_location(YARP::ArrayNode, "%i[foo bar baz]")
    assert_location(YARP::ArrayNode, "%I[foo bar baz]")
    assert_location(YARP::ArrayNode, "%w[foo bar baz]")
    assert_location(YARP::ArrayNode, "%W[foo bar baz]")
  end

  test "AssocNode" do
    assert_location(YARP::AssocNode, "{ foo: :bar }", 2...11) { |node| node.elements.first }
  end

  test "AssocSplatNode" do
    assert_location(YARP::AssocSplatNode, "{ **foo }", 2...7) { |node| node.elements.first }
  end

  test "BeginNode" do
    assert_location(YARP::BeginNode, "begin foo end")
    assert_location(YARP::BeginNode, "begin foo rescue bar end")
    assert_location(YARP::BeginNode, "begin foo rescue bar\nelse baz end")
    assert_location(YARP::BeginNode, "begin foo rescue bar\nelse baz\nensure qux end")
  end

  private

  def assert_location(kind, source, expected = 0...source.length)
    YARP.parse(source) => YARP::ParseResult[comments: [], errors: [], node:]

    node => YARP::Program[statements: [*, node]]
    node = yield node if block_given?

    assert_kind_of kind, node
    assert_equal expected.begin, node.location.start_offset
    assert_equal expected.end, node.location.end_offset
  end
end
