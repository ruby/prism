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
        :global_variable_read_node,       # In `alias $x $y`, the alias reduces both operands together.
        :if_node,                         # In `if a; b; elsif c; d; end`, the elsif node includes the enclosing end.
        :implicit_node,                   # In `case x; in {foo:}; end`, the label implies a capture of foo.
        :implicit_rest_node,              # In `x, = y`, the trailing comma implies a rest target.
        :it_parameters_node,              # In `proc { it }`, the inferred parameter list has no dedicated reduction.
        :local_variable_read_node,        # In `x = 1; case y; in ^x; end`, the pin and its variable reduce together.
        :local_variable_target_node,      # In `case x; in {foo:}; end`, the capture excludes the label's colon.
        :numbered_parameters_node,        # In `proc { _1 }`, the inferred parameter list has no dedicated reduction.
        :parentheses_node,                # In `not()`, the parentheses are part of the not production.
        :rescue_modifier_node,            # In `a, b = f rescue 42`, the rescue modifier is part of the assignment production.
        :splat_node,                      # In `a, *b = c`, the splat is part of the multiple-assignment target.
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
        when :ensure_node
          # The clause starts at opt_ensure and ends at the enclosing k_end.
          closing_start = node.end_keyword_loc.start_offset
          candidates.any? { |reduction| reduction.rule.lhs.id.s_value == "opt_ensure" && reduction.range.end <= closing_start } &&
            ranges[closing_start].any? { |reduction| reduction.rule.lhs.id.s_value == "k_end" && reduction.range.end == range.end }
        when :interpolated_symbol_node
          # A quoted label reduces with its value. The tLABEL_END child
          # ends the symbol's range.
          candidates.any? do |reduction|
            rule = reduction.rule
            reduction.range == range ||
              (rule.lhs.id.s_value == "assoc" && rule.rhs[2]&.id&.s_value == "tLABEL_END" &&
                reduction.child_ranges[2].end == range.end)
          end
        when :integer_node, :float_node, :rational_node
          # An imaginary literal reduces as one number. Prism gives the
          # coefficient a range that ends before the `i`.
          candidates.any? do |reduction|
            next true if reduction.range == range
            next false if reduction.range.end != range.end + 1 || source.getbyte(range.end) != "i".ord

            if reduction.rule.lhs.id.s_value == "numeric"
              # Unary minus is a separate terminal in the numeric production.
              reduction = reduction_for(ranges, reduction.child_ranges.last)
            end

            reduction&.rule&.lhs&.id&.s_value == "simple_numeric" &&
              reduction.rule.rhs.first.id.s_value == "tIMAGINARY"
          end
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
          # An f_args reduction can include a trailing comma outside Prism's
          # parameter range.
          candidates.any? do |reduction|
            reduction.range == range ||
              (reduction.rule.lhs.id.s_value == "f_args" &&
                source.byteslice(range.end...reduction.range.end).b.match?(/\A[ \t\r\n]*,\z/))
          end
        when :match_predicate_node
          # The expr reduction for `a in x: 1,` includes the pattern's trailing
          # comma outside Prism's match predicate range.
          candidates.any? do |reduction|
            rule = reduction.rule
            reduction.range == range ||
              (rule.lhs.id.s_value == "expr" && rule.rhs[1]&.id&.s_value == "keyword_in" &&
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
