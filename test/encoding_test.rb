# frozen_string_literal: true

require "test_helper"

class EncodingTest < Test::Unit::TestCase
  %w[
    ascii
    ascii-8bit
    big5
    binary
    iso-8859-1
    iso-8859-2
    iso-8859-3
    iso-8859-4
    iso-8859-5
    iso-8859-6
    iso-8859-7
    iso-8859-8
    iso-8859-9
    iso-8859-10
    iso-8859-11
    iso-8859-13
    iso-8859-14
    iso-8859-15
    iso-8859-16
    us-ascii
    utf-8
    windows-1251
    windows-1252
  ].each do |encoding|
    test encoding do
      result = YARP.parse("# encoding: #{encoding}\nident")
      actual = result.value.statements.body.first.message.value.encoding
      assert_equal Encoding.find(encoding), actual
    end
  end
end
