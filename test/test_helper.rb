# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "yarp"
require "ripper"
require "pp"
require "test-unit"
require "tempfile"

# Here we're going to override the == method in order to avoid having to
# specifically track offsets and compare them.
YARP::Location.prepend(
  Module.new do
    def ==(other)
      true
    end
  end
)
