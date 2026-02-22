# typed: true

module Prism
  # Query methods that allow categorizing strings based on their context for
  # where they could be valid in a Ruby syntax tree.
  class StringQuery
    sig { params(string: String).returns(T::Boolean) }
    def self.local?(string); end

    sig { params(string: String).returns(T::Boolean) }
    def self.constant?(string); end

    sig { params(string: String).returns(T::Boolean) }
    def self.method_name?(string); end

    # The string that this query is wrapping.
    sig { returns(String) }
    attr_reader :string

    # Initialize a new query with the given string.
    sig { params(string: String).void }
    def initialize(string); end

    # Whether or not this string is a valid local variable name.
    sig { returns(T::Boolean) }
    def local?; end

    # Whether or not this string is a valid constant name.
    sig { returns(T::Boolean) }
    def constant?; end

    # Whether or not this string is a valid method name.
    sig { returns(T::Boolean) }
    def method_name?; end
  end
end
