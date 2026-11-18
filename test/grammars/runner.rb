# frozen_string_literal: true

require "lrama"

module Prism
  module Grammars
    class Runner
      class Error < StandardError; end

      class Reduction
        attr_reader :rule, :range, :child_ranges

        def initialize(rule, range, child_ranges)
          @rule = rule
          @range = range
          @child_ranges = child_ranges
        end
      end

      def initialize(filepath)
        grammar = Lrama::Parser.new(File.read(filepath), filepath).parse
        grammar.prepare
        grammar.validate!

        states = Lrama::States.new(grammar, Lrama::Tracer.new($stderr))
        states.compute
        states.compute_ielr if grammar.ielr_defined?

        @tables = Lrama::Context.new(states)
        @pact = @tables.yypact
        @pgoto = @tables.yypgoto
        @final = @tables.yyfinal

        @rules = grammar.rules
        @terminals = grammar.terms.to_h { |symbol| [symbol.id.s_value, symbol.number] }
      end

      def run(terminals)
        heredocs = {}
        input =
          terminals.map do |terminal|
            if terminal.heredoc?
              location = terminal.location
              heredocs[location.start_offset] = location.start_offset...location.end_offset
            end

            @terminals.fetch(terminal.type) { raise Error, "unknown grammar terminal #{terminal.type.inspect}" }
          end

        stack = [0]
        cursor = 0

        spans = []
        reductions = []

        until (state = stack.last) == @final
          terminal = input.fetch(cursor) { raise Error, "token stream ended before grammar accepted" }
          base = @pact.fetch(state)

          action = base == @tables.yypact_ninf ? nil : table_entry(base, terminal)
          action ||= -@tables.yydefact.fetch(state)

          if action.zero? || action == @tables.yytable_ninf
            name = terminals.fetch(cursor).type
            raise Error, "LR rejection in state #{state} at token #{cursor + 1}: #{name}"
          elsif action.positive?
            stack << action
            location = terminals.fetch(cursor).location
            spans << (location.start_offset...location.end_offset)
            cursor += 1
          else
            rule = @rules.fetch(-action - 1)
            stack.pop(rule.rhs.length)

            parts = spans.pop(rule.rhs.length)
            spans << (
              if !(children = parts.compact).empty?
                range = children.first.begin...children.last.end
                case rule.lhs.id.s_value
                when "string1", "xstring"
                  range = heredocs.fetch(range.begin, range)
                end

                reductions << Reduction.new(rule, range, parts)
                range
              end
            )

            nonterminal = rule.lhs.number - @tables.yyntokens
            stack << (table_entry(@pgoto.fetch(nonterminal), stack.last) || @tables.yydefgoto.fetch(nonterminal))
          end
        end

        if cursor < input.length
          raise Error, "grammar accepted before token #{cursor + 1}: #{terminals.fetch(cursor).type}"
        end

        reductions
      end

      private

      def table_entry(base, symbol)
        index = base + symbol
        @tables.yytable[index] if index.between?(0, @tables.yylast) && @tables.yycheck[index] == symbol
      end
    end
  end
end
