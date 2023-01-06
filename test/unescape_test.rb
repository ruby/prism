# frozen_string_literal: true

require "test_helper"

class UnescapeTest < Test::Unit::TestCase
  test "backslash" do
    assert_unescapes("\\", "\\\\")
  end

  test "single quote" do
    assert_unescapes("'", "\\'")
  end

  test "single char" do
    assert_unescapes("\a", "\\a")
    assert_unescapes("\b", "\\b")
    assert_unescapes("\e", "\\e")
    assert_unescapes("\f", "\\f")
    assert_unescapes("\n", "\\n")
    assert_unescapes("\r", "\\r")
    assert_unescapes("\s", "\\s")
    assert_unescapes("\t", "\\t")
    assert_unescapes("\v", "\\v")
  end

  test "octal" do
    assert_unescapes("\a", "\\7")
    assert_unescapes("#", "\\43")
    assert_unescapes("a", "\\141")
  end

  test "hexidecimal" do
    assert_unescapes("\a", "\\x7")
    assert_unescapes("#", "\\x23")
    assert_unescapes("a", "\\x61")
  end

  test "unnecessary escapes" do
    assert_unescapes("\\d", "\\d")
    assert_unescapes("\\g", "\\g")
  end

  private

  def assert_unescapes(expected, source)
    assert_equal(expected, YARP.unescape(source))
  end
end
