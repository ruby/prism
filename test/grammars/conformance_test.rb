# frozen_string_literal: true

require_relative "../prism/test_helper"
require_relative "runner"
require_relative "terminals"

module Prism
  module Grammars
    class ConformanceTest < TestCase
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
        ast, tokens = result.value

        ranges = runner.run(Terminals.translate(tokens)).group_by { |reduction| reduction.range.begin }
        ranges.default = [].freeze

        stack = [ast]
        while (node = stack.pop)
          recurse = true

          case node.type
          when :arguments_node
            # In `a[1] = 2`, the arguments include the assigned value.
          when :call_node
            if (receiver = node.receiver)&.type == :parentheses_node && node.message_loc&.slice == "not"
              receiver_range = location_range(receiver.location)

              # The regular traversal checks a receiver with its own reduction.
              # Otherwise, check the parentheses as part of the not expression.
              if ranges[receiver_range.begin].none? { |reduction| reduction.range == receiver_range }
                recurse = false
                stack.concat(receiver.compact_child_nodes)

                assert_reduction(ranges, node) do |reduction, range|
                  rule = reduction.rule

                  reduction.range == range &&
                    rule.lhs.id.s_value == "primary" &&
                    rule.rhs.first.id.s_value == "keyword_not" &&
                    rule.rhs.last.id.s_value == "rparen" &&
                    reduction.child_ranges[1].begin == receiver_range.begin &&
                    reduction.child_ranges[-1].end == receiver_range.end
                end
              end
            elsif (block = node.block)&.type == :block_node
              block_range = location_range(block.location)

              # The regular traversal checks blocks with standalone reductions.
              # In `Foo::Bar { ... }`, the command reduction owns the braces.
              if ranges[block_range.begin].none? { |reduction| reduction.range == block_range }
                recurse = false
                stack.concat(node.compact_child_nodes.reject { |child| child.equal?(block) })

                parameters = block.parameters
                if parameters&.type == :it_parameters_node || parameters&.type == :numbered_parameters_node
                  # Inferred parameters use the full block span checked below.
                  assert_equal block_range, location_range(parameters.location)
                  stack << block.body if block.body
                else
                  stack.concat(block.compact_child_nodes)
                end

                assert_reduction(ranges, node) do |reduction, range|
                  rule = reduction.rule

                  reduction.range == range &&
                    rule.lhs.id.s_value == "command" &&
                    rule.rhs[-2]&.id&.s_value == "brace_body" &&
                    reduction.child_ranges[-3].begin == block_range.begin &&
                    reduction.child_ranges[-1].end == block_range.end
                end
              end
            else
              # In `-1**2`, one production covers both exponentiation and negation.
            end
          when :else_node
            # In `a ? b : c`, Prism creates an else node for the ternary's false branch.
          when :implicit_node
            # In a shorthand hash pattern, p_kw includes the label's colon.
            assert_reduction(ranges, node) do |reduction, range|
              rule = reduction.rule

              reduction.range == range ||
                (rule.lhs.id.s_value == "p_kw" && rule.rhs.length == 1 &&
                  reduction.range.end == range.end + 1 && source.getbyte(range.end) == ":".ord)
            end
          when :implicit_rest_node
            # In `x, = y`, the trailing comma implies a rest target.
          when :local_variable_target_node
            # In `case x; in {foo:}; end`, the capture excludes the label's colon.
          when :splat_node
            # In `a, *b = c`, the splat is part of the multiple-assignment target.
          when :string_node
            if node.opening_loc
              assert_reduction(ranges, node)
            else
              # Undelimited fragments can reduce with surrounding syntax, as
              # in `%w(a b)` or the text of an interpolated string.
            end
          when :symbol_node
            # In `%i(a b)`, the symbol reduces with its separator.
          when :alias_global_variable_node
            # A global alias reduces both operands with the alias keyword.
            recurse = false
            operands = node.compact_child_nodes.map { |operand| location_range(operand.location) }

            assert_reduction(ranges, node) do |reduction, range|
              rule = reduction.rule

              reduction.range == range &&
                rule.lhs.id.s_value == "stmt" &&
                rule.rhs.first&.id&.s_value == "keyword_alias" &&
                reduction.child_ranges.drop(1) == operands
            end
          when :pinned_variable_node
            # The pin and its local variable reduce together. Check the
            # variable against the identifier child of p_var_ref.
            if node.variable.type == :local_variable_read_node
              recurse = false
              variable_range = location_range(node.variable.location)

              assert_reduction(ranges, node) do |reduction, range|
                reduction.rule.lhs.id.s_value == "p_var_ref" &&
                  reduction.range == range &&
                  reduction.child_ranges.last == variable_range
              end
            else
              assert_reduction(ranges, node)
            end
          when :if_node
            # An elsif arm reduces as if_tail. The surrounding if owns its end.
            assert_reduction(ranges, node) do |reduction, range|
              reduction.range == range ||
                (reduction.rule.lhs.id.s_value == "if_tail" &&
                  reduction.rule.rhs.first.id.s_value == "k_elsif" &&
                  matches_closing_end?(node, ranges, range, reduction))
            end
          when :ensure_node
            # The clause starts at opt_ensure and ends at the enclosing k_end.
            assert_reduction(ranges, node) do |reduction, range|
              reduction.rule.lhs.id.s_value == "opt_ensure" && matches_closing_end?(node, ranges, range, reduction)
            end
          when :interpolated_symbol_node
            # A quoted label reduces with its value. The tLABEL_END child
            # ends the symbol's range.
            assert_reduction(ranges, node) do |reduction, range|
              rule = reduction.rule
              reduction.range == range ||
                (rule.lhs.id.s_value == "assoc" && rule.rhs[2]&.id&.s_value == "tLABEL_END" &&
                  reduction.child_ranges[2].end == range.end)
            end
          when :integer_node, :float_node, :rational_node
            # An imaginary literal reduces as one number. Prism gives the
            # coefficient a range that ends before the `i`.
            assert_reduction(ranges, node) do |reduction, range|
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
            assert_reduction(ranges, node) do |reduction, range|
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
            assert_reduction(ranges, node) do |reduction, range|
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
            assert_reduction(ranges, node) do |reduction, range|
              reduction.range == range ||
                (reduction.rule.lhs.id.s_value == "f_args" &&
                  source.byteslice(range.end...reduction.range.end).b.match?(/\A[ \t\r\n]*,\z/))
            end
          when :match_predicate_node
            # The expr reduction for `a in x: 1,` includes the pattern's trailing
            # comma outside Prism's match predicate range.
            assert_reduction(ranges, node) do |reduction, range|
              rule = reduction.rule
              reduction.range == range ||
                (rule.lhs.id.s_value == "expr" && rule.rhs[1]&.id&.s_value == "keyword_in" &&
                  source.byteslice(range.end...reduction.range.end).b.match?(/\A[ \t\r\n]*,\z/))
            end
          when :constant_path_node
            # A compound assignment can reduce the constant path and assignment
            # together. The constant before tOP_ASGN ends the path.
            assert_reduction(ranges, node) do |reduction, range|
              reduction.range == range || begin
                prefix = reduction.rule.rhs.take(4).map { |symbol| symbol.id.s_value }

                if prefix == %w[primary_value tCOLON2 tCONSTANT tOP_ASGN]
                  reduction.child_ranges[2].end == range.end
                elsif prefix.first(3) == %w[tCOLON3 tCONSTANT tOP_ASGN]
                  reduction.child_ranges[1].end == range.end
                end
              end
            end
          when :multi_write_node
            if (value = node.value).type == :rescue_modifier_node
              value_range = location_range(value.location)

              # A multiple assignment can reduce its RHS and rescue together
              # with the targets. Use the RHS and fallback child spans then.
              if ranges[value_range.begin].none? { |reduction| reduction.range == value_range }
                recurse = false
                stack.concat(node.compact_child_nodes.reject { |child| child.equal?(value) })
                stack.concat(value.compact_child_nodes)

                assert_reduction(ranges, node) do |reduction, range|
                  rule = reduction.rule

                  reduction.range == range &&
                    rule.lhs.id.s_value == "stmt" &&
                    rule.rhs.first.id.s_value == "mlhs" &&
                    rule.rhs[4]&.id&.s_value == "modifier_rescue" &&
                    reduction.child_ranges[3].begin == value_range.begin &&
                    reduction.child_ranges[-1].end == value_range.end
                end
              else
                assert_reduction(ranges, node)
              end
            else
              assert_reduction(ranges, node)
            end
          when :rescue_node
            # Prism includes subsequent rescue clauses and ends at the last
            # clause's last statement or exception header.
            assert_reduction(ranges, node) do |reduction, range|
              reduction.rule.lhs.id.s_value == "opt_rescue" && begin
                while (subsequent = reduction_for(ranges, reduction.child_ranges.last))
                  reduction = subsequent
                end

                (clause_body_end(reduction, ranges) || reduction.child_ranges.first(3).compact.last.end) == range.end
              end
            end
          else
            assert_reduction(ranges, node)
          end

          stack.concat(node.compact_child_nodes) if recurse
        end
      end

      def location_range(location)
        location.start_offset...location.end_offset
      end

      def assert_reduction(ranges, node)
        range = location_range(node.location)
        match =
          if block_given?
            ranges[range.begin].any? { |reduction| yield reduction, range }
          else
            ranges[range.begin].any? { |reduction| reduction.range == range }
          end

        assert match, "No reduction at #{node.type} range #{range}"
      end

      def matches_closing_end?(node, ranges, range, reduction)
        closing = node.end_keyword_loc
        return false if closing.nil? || reduction.range.end > closing.start_offset

        ranges[closing.start_offset].any? { |ending| ending.rule.lhs.id.s_value == "k_end" && ending.range.end == range.end }
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
