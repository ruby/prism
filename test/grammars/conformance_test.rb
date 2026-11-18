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
      runners = Hash.new { |hash, version| hash[version] = Runner.new(File.join(__dir__, "#{version}.y")) }

      Fixture.each_with_all_versions(except: except) do |fixture, version|
        define_method(fixture.test_name(version)) do
          result = Prism.lex(fixture.read, version: version)
          assert_predicate result, :success?, result.errors.first&.message

          runner = runners[version]
          terminals = Terminals.translate(result.value)
          assert_nothing_raised(Runner::Error) { runner.run(terminals) }
        end
      end
    end
  end
end
