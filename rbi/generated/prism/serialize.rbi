# typed: true

module Prism
  # A module responsible for deserializing parse results.
  module Serialize
    # The major version of prism that we are expecting to find in the serialized
    # strings.
    MAJOR_VERSION = T.let(nil, Integer)

    # The minor version of prism that we are expecting to find in the serialized
    # strings.
    MINOR_VERSION = T.let(nil, Integer)

    # The patch version of prism that we are expecting to find in the serialized
    # strings.
    PATCH_VERSION = T.let(nil, Integer)

    # Deserialize the dumped output from a request to parse or parse_file.
    #
    # The formatting of the source of this method is purposeful to illustrate
    # the structure of the serialized data.
    sig { params(input: String, serialized: String, freeze: T::Boolean).returns(ParseResult) }
    def self.load_parse(input, serialized, freeze); end

    # Deserialize the dumped output from a request to lex or lex_file.
    #
    # The formatting of the source of this method is purposeful to illustrate
    # the structure of the serialized data.
    sig { params(input: String, serialized: String, freeze: T::Boolean).returns(LexResult) }
    def self.load_lex(input, serialized, freeze); end

    # Deserialize the dumped output from a request to parse_comments or
    # parse_file_comments.
    #
    # The formatting of the source of this method is purposeful to illustrate
    # the structure of the serialized data.
    sig { params(input: String, serialized: String, freeze: T::Boolean).returns(T::Array[Comment]) }
    def self.load_parse_comments(input, serialized, freeze); end

    # Deserialize the dumped output from a request to parse_lex or
    # parse_lex_file.
    #
    # The formatting of the source of this method is purposeful to illustrate
    # the structure of the serialized data.
    sig { params(input: String, serialized: String, freeze: T::Boolean).returns(ParseLexResult) }
    def self.load_parse_lex(input, serialized, freeze); end

    class ConstantPool
      sig { returns(Integer) }
      attr_reader :size

      sig { params(input: String, serialized: String, base: Integer, size: Integer).void }
      def initialize(input, serialized, base, size); end

      sig { params(index: Integer, encoding: Encoding).returns(Symbol) }
      def get(index, encoding); end
    end

    FastStringIO = T.let(nil, T.untyped)

    class Loader
      sig { returns(String) }
      attr_reader :input

      sig { returns(StringIO) }
      attr_reader :io

      sig { returns(Source) }
      attr_reader :source

      sig { params(source: Source, serialized: String).void }
      def initialize(source, serialized); end

      sig { returns(T::Boolean) }
      def eof?; end

      sig { params(constant_pool: ConstantPool).void }
      def load_constant_pool(constant_pool); end

      sig { void }
      def load_header; end

      sig { returns(Encoding) }
      def load_encoding; end

      sig { params(freeze: T::Boolean).returns(T::Array[Integer]) }
      def load_line_offsets(freeze); end

      sig { params(freeze: T::Boolean).returns(T::Array[Comment]) }
      def load_comments(freeze); end

      sig { params(freeze: T::Boolean).returns(T::Array[MagicComment]) }
      def load_magic_comments(freeze); end

      DIAGNOSTIC_TYPES = T.let(nil, T::Array[Symbol])

      sig { returns(Symbol) }
      def load_error_level; end

      sig { params(encoding: Encoding, freeze: T::Boolean).returns(T::Array[ParseError]) }
      def load_errors(encoding, freeze); end

      sig { returns(Symbol) }
      def load_warning_level; end

      sig { params(encoding: Encoding, freeze: T::Boolean).returns(T::Array[ParseWarning]) }
      def load_warnings(encoding, freeze); end

      sig { returns(T::Array[[Token, Integer]]) }
      def load_tokens; end

      # variable-length integer using https://en.wikipedia.org/wiki/LEB128
      # This is also what protobuf uses: https://protobuf.dev/programming-guides/encoding/#varints
      sig { returns(Integer) }
      def load_varuint; end

      sig { returns(Integer) }
      def load_varsint; end

      sig { returns(Integer) }
      def load_integer; end

      sig { returns(Float) }
      def load_double; end

      sig { returns(Integer) }
      def load_uint32; end

      sig { params(constant_pool: ConstantPool, encoding: Encoding, freeze: T::Boolean).returns(T.nilable(Node)) }
      def load_optional_node(constant_pool, encoding, freeze); end

      sig { params(encoding: Encoding).returns(String) }
      def load_embedded_string(encoding); end

      sig { params(encoding: Encoding).returns(String) }
      def load_string(encoding); end

      sig { params(freeze: T::Boolean).returns(Location) }
      def load_location_object(freeze); end

      # Load a location object from the serialized data. Note that we are lying
      # about the signature a bit here, because we sometimes load it as a packed
      # integer instead of an object.
      sig { params(freeze: T::Boolean).returns(Location) }
      def load_location(freeze); end

      # Load an optional location object from the serialized data if it is
      # present. Note that we are lying about the signature a bit here, because
      # we sometimes load it as a packed integer instead of an object.
      sig { params(freeze: T::Boolean).returns(T.nilable(Location)) }
      def load_optional_location(freeze); end

      sig { params(freeze: T::Boolean).returns(T.nilable(Location)) }
      def load_optional_location_object(freeze); end

      sig { params(constant_pool: ConstantPool, encoding: Encoding).returns(Symbol) }
      def load_constant(constant_pool, encoding); end

      sig { params(constant_pool: ConstantPool, encoding: Encoding).returns(T.nilable(Symbol)) }
      def load_optional_constant(constant_pool, encoding); end

      sig { params(constant_pool: ConstantPool, encoding: Encoding, freeze: T::Boolean).returns(Node) }
      def load_node(constant_pool, encoding, freeze); end

      sig { void }
      def define_load_node_lambdas; end
    end

    # The token types that can be indexed by their enum values.
    TOKEN_TYPES = T.let(nil, T::Array[T.nilable(Symbol)])
  end
end
