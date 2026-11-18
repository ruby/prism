# frozen_string_literal: true

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
        :else_node,                       # In `a ? b : c`, Prism creates an else node for the ternary's false branch.
        :ensure_node,                     # In `begin; x; ensure; y; end`, the node includes the enclosing end.
        :float_node,                      # In `1.5i`, the float is part of one imaginary terminal.
        :global_variable_read_node,       # In `alias $x $y`, the alias reduces both operands together.
        :if_node,                         # In `if a; b; elsif c; d; end`, the elsif node includes the enclosing end.
        :implicit_node,                   # In `case x; in {foo:}; end`, the label implies a capture of foo.
        :implicit_rest_node,              # In `x, = y`, the trailing comma implies a rest target.
        :integer_node,                    # In `1i`, the integer is part of one imaginary terminal.
        :interpolated_symbol_node,        # In `f("x#{y}": 1)`, the quoted label reduces with its value.
        :it_parameters_node,              # In `proc { it }`, the inferred parameter list has no dedicated reduction.
        :local_variable_read_node,        # In `x = 1; case y; in ^x; end`, the pin and its variable reduce together.
        :local_variable_target_node,      # In `case x; in {foo:}; end`, the capture excludes the label's colon.
        :match_predicate_node,            # In `if a in x: 1, then end`, the node excludes the trailing comma.
        :numbered_parameters_node,        # In `proc { _1 }`, the inferred parameter list has no dedicated reduction.
        :parentheses_node,                # In `not()`, the parentheses are part of the not production.
        :program_node,                    # An empty source file produces a zero-width program node.
        :rational_node,                   # In `1ri`, the rational is part of one imaginary terminal.
        :rescue_modifier_node,            # In `a, b = f rescue 42`, the rescue modifier is part of the assignment production.
        :splat_node,                      # In `a, *b = c`, the splat is part of the multiple-assignment target.
        :statements_node,                 # An empty source file produces a zero-width statements node.
        :string_node,                     # In `%w(a b)`, the word reduces with its separator.
        :symbol_node,                     # In `%i(a b)`, the symbol reduces with its separator.
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
        ranges = runner.run(Terminals.translate(tokens)).group_by { |reduction| reduction.range.begin }
        ranges.default = [].freeze

        stack = [ast]
        until stack.empty?
          node = stack.pop
          stack.concat(node.compact_child_nodes)
          next if EXCLUDES.include?(node.type)

          location = node.location
          range = location.start_offset...location.end_offset
          assert matching_range?(node, ranges, range, source), "No reduction at #{node.type} range #{range}"
        end
      end

      def matching_range?(node, ranges, range, source)
        candidates = ranges[range.begin]

        case node.type
        when :when_node
          # The case_body reduction includes subsequent arms. Use the end
          # of this arm's statements or its `when` header if the body is empty.
          candidates.any? do |reduction|
            reduction.rule.lhs.id.s_value == "case_body" &&
              if (body_end = clause_body_end(reduction, ranges))
                body_end == range.end
              else
                condition_range, separator_range = reduction.child_ranges[1, 2]
                (separator_range && node.then_keyword_loc ? separator_range.end : condition_range.end) == range.end
              end
          end
        when :in_node
          # The p_case_body reduction includes subsequent arms. Use the end
          # of this arm's statements or its `in` header if the body is empty.
          candidates.any? do |reduction|
            reduction.rule.lhs.id.s_value == "p_case_body" &&
              if (body_end = clause_body_end(reduction, ranges))
                body_end == range.end
              else
                condition_range, separator_range = reduction.child_ranges[4, 2]
                (separator_range && node.then_keyword_loc ? separator_range.end : condition_range.end) == range.end
              end
          end
        when :parameters_node
          # An f_args reduction can include a trailing comma outside the range
          # of the node.
          candidates.any? do |reduction|
            reduction.range == range ||
              (reduction.rule.lhs.id.s_value == "f_args" &&
                source.byteslice(range.end...reduction.range.end).b.match?(/\A[ \t\r\n]*,\z/))
          end
        when :constant_path_node
          # A compound assignment can reduce the constant path and assignment
          # together. The constant before tOP_ASGN ends the path.
          candidates.any? do |reduction|
            reduction.range == range || begin
              prefix = reduction.rule.rhs.take(4).map { |symbol| symbol.id.s_value }

              if prefix == %w[primary_value tCOLON2 tCONSTANT tOP_ASGN]
                reduction.child_ranges[2].end == range.end
              elsif prefix.first(3) == %w[tCOLON3 tCONSTANT tOP_ASGN]
                reduction.child_ranges[1].end == range.end
              end
            end
          end
        when :rescue_node
          # Prism includes subsequent rescue clauses and ends at the last
          # clause's last statement or exception header.
          candidates.any? do |reduction|
            reduction.rule.lhs.id.s_value == "opt_rescue" && begin
              while (subsequent = reduction_for(ranges, reduction.child_ranges.last))
                reduction = subsequent
              end

              (clause_body_end(reduction, ranges) || reduction.child_ranges.first(3).compact.last.end) == range.end
            end
          end
        else
          candidates.any? { |reduction| reduction.range == range }
        end
      end

      def clause_body_end(reduction, ranges)
        reduction_for(ranges, reduction.child_ranges[-2])&.child_ranges&.first&.end
      end

      def reduction_for(ranges, range)
        range && ranges[range.begin].find { |candidate| candidate.range.equal?(range) }
      end
    end
  end
end
