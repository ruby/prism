# typed: true

module Prism
  # Query methods that allow categorizing strings based on their context for
  # where they could be valid in a Ruby syntax tree.
  class StringQuery
    sig { params(string: String, version: ::T.nilable(String)).returns(T::Boolean) }
    def self.local?(string, version: T.unsafe(nil)); end

    sig { params(string: String, version: ::T.nilable(String)).returns(T::Boolean) }
    def self.constant?(string, version: T.unsafe(nil)); end

    sig { params(string: String, version: ::T.nilable(String)).returns(T::Boolean) }
    def self.method_name?(string, version: T.unsafe(nil)); end

    sig { params(string: String, version: ::T.nilable(String)).returns(T::Boolean) }
    def self.keyword?(string, version: T.unsafe(nil)); end

    # The string that this query is wrapping.
    sig { returns(String) }
    attr_reader :string

    # Initialize a new query with the given string.
    sig { params(string: String).void }
    def initialize(string); end

    # Whether or not this string is a valid local variable name.
    sig { params(version: ::T.nilable(String)).returns(T::Boolean) }
    def local?(version: T.unsafe(nil)); end

    # Whether or not this string is a valid constant name.
    sig { params(version: ::T.nilable(String)).returns(T::Boolean) }
    def constant?(version: T.unsafe(nil)); end

    # Whether or not this string is a valid method name.
    sig { params(version: ::T.nilable(String)).returns(T::Boolean) }
    def method_name?(version: T.unsafe(nil)); end

    # Whether or not this string is a valid keyword.
    sig { params(version: ::T.nilable(String)).returns(T::Boolean) }
    def keyword?(version: T.unsafe(nil)); end
  end
end
