# frozen_string_literal: true

require_relative "test_helper"

# There have also been changes made in other versions of Ruby, so we only want
# to test on the most recent versions.
return if !defined?(RubyVM::InstructionSequence) || RUBY_VERSION < "3.4.0"

module Prism
  class NewlineTest < TestCase
    base = __dir__
    Dir["{,api/,encoding/,result/,ruby/}*.rb", base: base].each do |relative|
      define_method(:"test_#{relative}") do
        assert_newlines(base, relative)
      end
    end

    private

    def assert_newlines(base, relative)
      filepath = File.join(base, relative)
      source = File.read(filepath, binmode: true, external_encoding: Encoding::UTF_8)
      expected = rubyvm_lines(source)

      result = Prism.parse_file(filepath)
      assert_empty result.errors
      actual = prism_lines(result)

      lines = source.lines
      lines.each.with_index(1) do |line, line_number|
        # Lines like `while (foo = bar)` result in two line flags in the
        # bytecode but only one newline flag in the AST. We need to remove the
        # extra line flag from the bytecode to make the test pass.
        if line.match?(/while \(/)
          index = expected.index(line_number)
          expected.delete_at(index) if index
        end

        # For statements like `foo = [` or `foo =` where the value continues
        # on the following lines, the line event in the bytecode is emitted on
        # the line of the first sub-expression of the value (e.g., the first
        # array element) instead of on the first line of the statement, while
        # prism marks the newline flag on the node that starts the statement.
        # The same is true for statements that begin with a multi-line array
        # or hash literal, like `[` alone on a line. To compensate, move the
        # newline flag to the line the bytecode uses, or drop it if another
        # node already has a newline flag on that line.
        if line.match?(/[\w\])"'] =( \[| \{| begin)?$/) || line.match?(/\A\s*[\[{]$/)
          if actual.count(line_number) > expected.count(line_number)
            target = ((line_number + 1)..lines.length).find do |candidate|
              !lines[candidate - 1].match?(/\A\s*(#|\z)/)
            end

            index = actual.index(line_number) #: Integer
            if target && expected.count(target) > actual.count(target)
              actual[index] = target
            else
              actual.delete_at(index)
            end
          end
        end
      end

      assert_equal expected, actual.sort
    end

    def rubyvm_lines(source)
      queue = [ignore_warnings { RubyVM::InstructionSequence.compile(source) }]
      lines = []

      while iseq = queue.shift
        lines.concat(iseq.trace_points.filter_map { |line, event| line if event == :line })
        iseq.each_child { |insn| queue << insn unless insn.label.start_with?("ensure in ") }
      end

      lines.sort
    end

    def prism_lines(result)
      result.mark_newlines!

      queue = [result.value]
      newlines = []

      while node = queue.shift
        queue.concat(node.compact_child_nodes)
        newlines << result.source.line(node.location.start_offset) if node&.newline_flag?
      end

      newlines.sort
    end
  end
end
