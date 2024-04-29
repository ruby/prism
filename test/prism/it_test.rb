# frozen_string_literal: true

require_relative "test_helper"

module Prism
  class ItTest < TestCase
    def test_regular
      lambda = parse("-> { it }")

      assert_kind_of Prism::ItParametersNode, lambda.parameters
      assert_kind_of Prism::ItLocalVariableReadNode, lambda.body.body.first
    end

    def test_write
      lambda = parse("-> { it = 1 }")

      refute_kind_of Prism::ItParametersNode, lambda.parameters
      refute_kind_of Prism::ItLocalVariableReadNode, lambda.body.body.first
    end

    def test_target
      lambda = parse("-> { (_, it) = 1 }")

      refute_kind_of Prism::ItParametersNode, lambda.parameters
      refute_kind_of Prism::ItLocalVariableReadNode, lambda.body.body.first.lefts.last
    end

    def test_def_receiver
      lambda = parse("-> { def it.foo; end }")

      assert_kind_of Prism::ItParametersNode, lambda.parameters
      assert_kind_of Prism::ItLocalVariableReadNode, lambda.body.body.first.receiver
    end

    def test_pinned
      lambda = parse("-> { foo in ^it }")

      assert_kind_of Prism::ItParametersNode, lambda.parameters
      assert_kind_of Prism::ItLocalVariableReadNode, lambda.body.body.first.pattern.variable
    end

    def test_error_ordinary
      result = Prism.parse("-> (foo) { it }")

      assert result.failure?
      assert_includes result.errors.first.message, "ordinary parameter is defined"
    end

    def test_error_numbered
      result = Prism.parse("-> { _1 + it }")

      assert result.failure?
      assert_includes result.errors.first.message, "numbered parameter is defined"
    end

    private

    def parse(source)
      Prism.parse(source).value.statements.body.first.tap do |lambda|
        assert_kind_of Prism::LambdaNode, lambda
      end
    end
  end
end
