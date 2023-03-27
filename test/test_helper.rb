# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "yarp"
require "ripper"
require "pp"
require "test-unit"
require "tempfile"

module YARP
  module Assertions
    private

    def assert_equal_nodes(expected, actual, compare_location: true)
      assert_equal expected.class, actual.class
  
      case expected
      when Array
        assert_equal expected.size, actual.size
  
        expected.zip(actual).each do |(expected, actual)|
          assert_equal_nodes(
            expected,
            actual,
            compare_location: compare_location
          )
        end
      when YARP::Node
        deconstructed_expected = expected.deconstruct_keys(nil)
        deconstructed_actual = actual.deconstruct_keys(nil)
        assert_equal deconstructed_expected.keys, deconstructed_actual.keys
  
        deconstructed_expected.each_key do |key|
          assert_equal_nodes(
            deconstructed_expected[key],
            deconstructed_actual[key],
            compare_location: compare_location
          )
        end
      when YARP::Location
        if compare_location
          assert_equal expected.start_offset, actual.start_offset
          assert_equal expected.end_offset, actual.end_offset
        end
      else
        assert_equal expected, actual
      end
    end
  end
end

Test::Unit::TestCase.include(YARP::Assertions)
