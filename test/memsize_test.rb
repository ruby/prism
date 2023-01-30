# frozen_string_literal: true

require "test_helper"

class MemsizeTest < Test::Unit::TestCase
  test "memsize" do
    length, memsize = YARP.memsize("2 + 3")

    assert_equal 5, length
    assert_kind_of Integer, memsize
  end
end
