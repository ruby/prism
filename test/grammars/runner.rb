# frozen_string_literal: true

require "lrama"

module Prism
  module Grammars
    class Runner
      class Error < StandardError; end

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
        input =
          terminals.map do |name|
            @terminals.fetch(name) { raise Error, "unknown grammar terminal #{name.inspect}" }
          end

        stack = [0]
        cursor = 0

        until (state = stack.last) == @final
          terminal = input.fetch(cursor) { raise Error, "token stream ended before grammar accepted" }
          base = @pact.fetch(state)

          action = base == @tables.yypact_ninf ? nil : table_entry(base, terminal)
          action ||= -@tables.yydefact.fetch(state)

          if action.zero? || action == @tables.yytable_ninf
            name = terminals.fetch(cursor)
            raise Error, "LR rejection in state #{state} at token #{cursor + 1}: #{name}"
          elsif action.positive?
            stack << action
            cursor += 1
          else
            rule = @rules.fetch(-action - 1)
            stack.pop(rule.rhs.length)

            nonterminal = rule.lhs.number - @tables.yyntokens
            stack << (table_entry(@pgoto.fetch(nonterminal), stack.last) || @tables.yydefgoto.fetch(nonterminal))
          end
        end

        if cursor < input.length
          raise Error, "grammar accepted before token #{cursor + 1}: #{terminals.fetch(cursor)}"
        end
      end

      private

      def table_entry(base, symbol)
        index = base + symbol
        @tables.yytable[index] if index.between?(0, @tables.yylast) && @tables.yycheck[index] == symbol
      end
    end
  end
end
