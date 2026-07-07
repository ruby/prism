# frozen_string_literal: true

require_relative "../test_helper"

module Prism
  class ParseStreamTest < TestCase
    def test_single_line
      io = StringIO.new("1 + 2")
      result = Prism.parse_stream(io)

      assert result.success?
      assert_kind_of Prism::CallNode, result.statement
    end

    def test_multi_line
      io = StringIO.new("1 + 2\n3 + 4")
      result = Prism.parse_stream(io)

      assert result.success?
      assert_kind_of Prism::CallNode, result.statement
      assert_kind_of Prism::CallNode, result.statement
    end

    def test_multi_read
      io = StringIO.new("a" * 4096 * 4)
      result = Prism.parse_stream(io)

      assert result.success?
      assert_kind_of Prism::CallNode, result.statement
    end

    def test___END__
      io = StringIO.new(<<~RUBY)
        1 + 2
        3 + 4
        __END__
        5 + 6
      RUBY
      result = Prism.parse_stream(io)

      assert result.success?
      assert_equal 2, result.value.statements.body.length
      assert_equal "5 + 6\n", io.read
    end

    def test_false___END___in_string
      io = StringIO.new(<<~RUBY)
        1 + 2
        3 + 4
        "
        __END__
        "
        5 + 6
      RUBY
      result = Prism.parse_stream(io)

      assert result.success?
      assert_equal 4, result.value.statements.body.length
    end

    def test_false___END___in_regexp
      io = StringIO.new(<<~RUBY)
        1 + 2
        3 + 4
        /
        __END__
        /
        5 + 6
      RUBY
      result = Prism.parse_stream(io)

      assert result.success?
      assert_equal 4, result.value.statements.body.length
    end

    def test_false___END___in_list
      io = StringIO.new(<<~RUBY)
        1 + 2
        3 + 4
        %w[
        __END__
        ]
        5 + 6
      RUBY
      result = Prism.parse_stream(io)

      assert result.success?
      assert_equal 4, result.value.statements.body.length
    end

    def test_false___END___in_heredoc
      io = StringIO.new(<<~RUBY)
        1 + 2
        3 + 4
        <<-EOF
        __END__
        EOF
        5 + 6
      RUBY
      result = Prism.parse_stream(io)

      assert result.success?
      assert_equal 4, result.value.statements.body.length
    end

    def test_nul_bytes
      io = StringIO.new(<<~RUBY)
        1 # \0\0\0\t
        2 # \0\0\0
        3
      RUBY
      result = Prism.parse_stream(io)

      assert result.success?
      assert_equal 3, result.value.statements.body.length
    end

    def test_long_line
      # The important point of this test is that the character at 4095
      # is a multi-byte character (U+3042 HIRAGANA LETTER A) in this
      # case. gets(4095) may return 4095 or more bytes if the last
      # character is a multi-byte character. For example,
      # StringIO.new("\u3042").gets(1).bytesize is 3 not 1.
      long_string = "\"" + ("a" * 4093) + "\u3042" + "\""
      io = StringIO.new(long_string)
      result = Prism.parse_stream(io)

      assert result.success?
      assert_equal long_string[1..-2], result.value.statements.body[0].content
    end
  end
end
