# frozen_string_literal: true

require "set"

require_relative "../prism/test_helper"
require_relative "runner"
require_relative "terminals"

module Prism
  module Grammars
    class ConformanceTest < TestCase
      EXCLUDES = [
        :arguments_node,                  # In `a[1] = 2`, the arguments include the assigned value.
        :back_reference_read_node,        # In `alias $x $&`, the alias reduces both operands together.
        :block_node,                      # In `Foo::Bar { |a| 42 }`, the block is part of the command production.
        :call_node,                       # In `-1**2`, one production covers both exponentiation and negation.
        :constant_path_node,              # In `::X ||= 1`, the path is part of the assignment production.
        :else_node,                       # In `a ? b : c`, Prism creates an else node for the ternary's false branch.
        :ensure_node,                     # In `begin; x; ensure; y; end`, the node includes the enclosing end.
        :float_node,                      # In `1.5i`, the float is part of one imaginary terminal.
        :global_variable_read_node,       # In `alias $x $y`, the alias reduces both operands together.
        :if_node,                         # In `if a; b; elsif c; d; end`, the elsif node includes the enclosing end.
        :implicit_node,                   # In `case x; in {foo:}; end`, the label implies a capture of foo.
        :implicit_rest_node,              # In `x, = y`, the trailing comma implies a rest target.
        :in_node,                         # In `case x; in A; a; in B; b; end`, the first arm's reduction includes the remaining arms.
        :integer_node,                    # In `1i`, the integer is part of one imaginary terminal.
        :interpolated_symbol_node,        # In `f("x#{y}": 1)`, the quoted label reduces with its value.
        :it_parameters_node,              # In `proc { it }`, the inferred parameter list has no dedicated reduction.
        :local_variable_read_node,        # In `x = 1; case y; in ^x; end`, the pin and its variable reduce together.
        :local_variable_target_node,      # In `case x; in {foo:}; end`, the capture excludes the label's colon.
        :match_predicate_node,            # In `if a in x: 1, then end`, the node excludes the trailing comma.
        :numbered_parameters_node,        # In `proc { _1 }`, the inferred parameter list has no dedicated reduction.
        :parameters_node,                 # In `def f(a, b, *c,); end`, the node excludes the trailing comma.
        :parentheses_node,                # In `not()`, the parentheses are part of the not production.
        :program_node,                    # An empty source file produces a zero-width program node.
        :rational_node,                   # In `1ri`, the rational is part of one imaginary terminal.
        :rescue_modifier_node,            # In `a, b = f rescue 42`, the rescue modifier is part of the assignment production.
        :rescue_node,                     # In `begin; x; rescue; y; end`, the reduction includes a trailing statement separator.
        :splat_node,                      # In `a, *b = c`, the splat is part of the multiple-assignment target.
        :statements_node,                 # An empty source file produces a zero-width statements node.
        :string_node,                     # In `%w(a b)`, the word reduces with its separator.
        :symbol_node,                     # In `%i(a b)`, the symbol reduces with its separator.
        :when_node,                       # In `case x; when 1; a; when 2; b; end`, the first arm's reduction includes the remaining arms.
      ].freeze

      # It is unclear if these are supposed to be accepted by the 3.4 and 4.0
      # grammars. https://bugs.ruby-lang.org/issues/21168
      except = %w[
        3.4/command_call_do_block_in_arguments.txt
        3.4-4.0/command_call_do_block_in_index_arguments.txt
      ]

      # Cache these because they are expensive to create.
      runners =
        Hash.new do |hash, version|
          hash[version] = Runner.new(File.join(__dir__, "#{version}.y"))
        end

      Fixture.each_with_all_versions(except: except) do |fixture, version|
        define_method(fixture.test_name(version)) do
          assert_reductions(fixture.read, version, runners[version])
        end
      end

      private

      def assert_reductions(source, version, runner)
        result = Prism.parse_lex(source, version: version)
        assert_predicate result, :success?, result.errors.first&.message

        ast, tokens = result.value
        ranges = runner.run(Terminals.translate(tokens)).to_set(&:range)
        stack = [ast]

        until stack.empty?
          node = stack.pop
          stack.concat(node.compact_child_nodes)
          next if EXCLUDES.include?(node.type)

          location = node.location
          range = location.start_offset...location.end_offset
          assert ranges.include?(range), "No reduction at #{node.type} range #{range}"
        end
      end
    end
  end
end
