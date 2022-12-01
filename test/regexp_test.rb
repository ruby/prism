# frozen_string_literal: true

require "test_helper"

class RegexpTest < Test::Unit::TestCase
  test "named captures with <>" do
    assert_equal(["foo"], YARP.named_captures("(?<foo>bar)"))
  end

  test "named captures with ''" do
    assert_equal(["foo"], YARP.named_captures("(?'foo'bar)"))
  end

  test "nested named captures with <>" do
    assert_equal(["foo", "bar"], YARP.named_captures("(?<foo>(?<bar>baz))"))
  end

  test "nested named captures with ''" do
    assert_equal(["foo", "bar"], YARP.named_captures("(?'foo'(?'bar'baz))"))
  end

  test "allows duplicate named captures" do
    assert_equal(["foo", "foo"], YARP.named_captures("(?<foo>bar)(?<foo>baz)"))
  end
end
