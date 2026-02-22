# typed: true

module Prism
  class ParseResult < Result
    # An object to represent the set of errors on a parse result. This object
    # can be used to format the errors in a human-readable way.
    class Errors
      # The parse result that contains the errors.
      sig { returns(ParseResult) }
      attr_reader :parse_result

      # Initialize a new set of errors from the given parse result.
      sig { params(parse_result: ParseResult).void }
      def initialize(parse_result); end

      # Formats the errors in a human-readable way and return them as a string.
      sig { returns(String) }
      def format; end
    end
  end
end
