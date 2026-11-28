# frozen_string_literal: true

require_relative "../test_helper"

module Prism
  class HeredocTest < TestCase
    def test_word_separators_spanning_a_heredoc
      %w[%w %i].each do |literal|
        { "\nA\n " => [], "first\nbody\nA\n  second" => %w[first second] }.each do |contents, expected|
          source = "[<<A, #{literal}[#{contents}]]"
          result = Prism.parse(source)

          assert_empty result.errors, source
          assert_equal expected, result.statement.elements.last.elements.map(&:unescaped), source
        end
      end
    end

    def test_long_heredoc_terminator
      [17, 32, 77].each do |length|
        terminator = "A" * length
        body = +""
        length.times do |index|
          line = terminator.dup
          line[index] = "B"
          body << line << "\n"
        end

        assert_equal body, Prism.parse_statement("<<#{terminator}\n#{body}#{terminator}\n").unescaped
      end
    end

    def test_heredoc?
      refute Prism.parse_statement("\"foo\"").heredoc?
      refute Prism.parse_statement("\"foo \#{1}\"").heredoc?
      refute Prism.parse_statement("`foo`").heredoc?
      refute Prism.parse_statement("`foo \#{1}`").heredoc?

      assert Prism.parse_statement("<<~HERE\nfoo\nHERE\n").heredoc?
      assert Prism.parse_statement("<<~HERE\nfoo \#{1}\nHERE\n").heredoc?
      assert Prism.parse_statement("<<~`HERE`\nfoo\nHERE\n").heredoc?
      assert Prism.parse_statement("<<~`HERE`\nfoo \#{1}\nHERE\n").heredoc?
    end
  end
end
