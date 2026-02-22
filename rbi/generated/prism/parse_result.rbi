# typed: true

module Prism
  # This represents a source of Ruby code that has been parsed. It is used in
  # conjunction with locations to allow them to resolve line numbers and source
  # ranges.
  class Source
    # Create a new source object with the given source code. This method should
    # be used instead of `new` and it will return either a `Source` or a
    # specialized and more performant `ASCIISource` if no multibyte characters
    # are present in the source code.
    sig { params(source: String, start_line: Integer, offsets: T::Array[Integer]).returns(Source) }
    def self.for(source, start_line = T.unsafe(nil), offsets = T.unsafe(nil)); end

    # The source code that this source object represents.
    sig { returns(String) }
    attr_reader :source

    # The line number where this source starts.
    sig { returns(Integer) }
    attr_reader :start_line

    # The list of newline byte offsets in the source code.
    sig { returns(T::Array[Integer]) }
    attr_reader :offsets

    # Create a new source object with the given source code.
    sig { params(source: String, start_line: Integer, offsets: T::Array[Integer]).void }
    def initialize(source, start_line = T.unsafe(nil), offsets = T.unsafe(nil)); end

    # Replace the value of start_line with the given value.
    sig { params(start_line: Integer).void }
    def replace_start_line(start_line); end

    # Replace the value of offsets with the given value.
    sig { params(offsets: T::Array[Integer]).void }
    def replace_offsets(offsets); end

    # Returns the encoding of the source code, which is set by parameters to the
    # parser or by the encoding magic comment.
    sig { returns(Encoding) }
    def encoding; end

    # Returns the lines of the source code as an array of strings.
    sig { returns(T::Array[String]) }
    def lines; end

    # Perform a byteslice on the source code using the given byte offset and
    # byte length.
    sig { params(byte_offset: Integer, length: Integer).returns(String) }
    def slice(byte_offset, length); end

    # Converts the line number and column in bytes to a byte offset.
    sig { params(line: Integer, column: Integer).returns(Integer) }
    def byte_offset(line, column); end

    # Binary search through the offsets to find the line number for the given
    # byte offset.
    sig { params(byte_offset: Integer).returns(Integer) }
    def line(byte_offset); end

    # Return the byte offset of the start of the line corresponding to the given
    # byte offset.
    sig { params(byte_offset: Integer).returns(Integer) }
    def line_start(byte_offset); end

    # Returns the byte offset of the end of the line corresponding to the given
    # byte offset.
    sig { params(byte_offset: Integer).returns(Integer) }
    def line_end(byte_offset); end

    # Return the column in bytes for the given byte offset.
    sig { params(byte_offset: Integer).returns(Integer) }
    def column(byte_offset); end

    # Return the character offset for the given byte offset.
    sig { params(byte_offset: Integer).returns(Integer) }
    def character_offset(byte_offset); end

    # Return the column in characters for the given byte offset.
    sig { params(byte_offset: Integer).returns(Integer) }
    def character_column(byte_offset); end

    # Returns the offset from the start of the file for the given byte offset
    # counting in code units for the given encoding.
    #
    # This method is tested with UTF-8, UTF-16, and UTF-32. If there is the
    # concept of code units that differs from the number of characters in other
    # encodings, it is not captured here.
    #
    # We purposefully replace invalid and undefined characters with replacement
    # characters in this conversion. This happens for two reasons. First, it's
    # possible that the given byte offset will not occur on a character
    # boundary. Second, it's possible that the source code will contain a
    # character that has no equivalent in the given encoding.
    sig { params(byte_offset: Integer, encoding: Encoding).returns(Integer) }
    def code_units_offset(byte_offset, encoding); end

    # Generate a cache that targets a specific encoding for calculating code
    # unit offsets.
    sig { params(encoding: Encoding).returns(CodeUnitsCache) }
    def code_units_cache(encoding); end

    # Returns the column in code units for the given encoding for the
    # given byte offset.
    sig { params(byte_offset: Integer, encoding: Encoding).returns(Integer) }
    def code_units_column(byte_offset, encoding); end

    # Freeze this object and the objects it contains.
    sig { void }
    def deep_freeze; end

    # Binary search through the offsets to find the line number for the given
    # byte offset.
    sig { params(byte_offset: Integer).returns(Integer) }
    private def find_line(byte_offset); end
  end

  # A cache that can be used to quickly compute code unit offsets from byte
  # offsets. It purposefully provides only a single #[] method to access the
  # cache in order to minimize surface area.
  #
  # Note that there are some known issues here that may or may not be addressed
  # in the future:
  #
  # * The first is that there are issues when the cache computes values that are
  #   not on character boundaries. This can result in subsequent computations
  #   being off by one or more code units.
  # * The second is that this cache is currently unbounded. In theory we could
  #   introduce some kind of LRU cache to limit the number of entries, but this
  #   has not yet been implemented.
  class CodeUnitsCache
    class UTF16Counter
      sig { params(source: String, encoding: Encoding).void }
      def initialize(source, encoding); end

      sig { params(byte_offset: Integer, byte_length: Integer).returns(Integer) }
      def count(byte_offset, byte_length); end
    end

    class LengthCounter
      sig { params(source: String, encoding: Encoding).void }
      def initialize(source, encoding); end

      sig { params(byte_offset: Integer, byte_length: Integer).returns(Integer) }
      def count(byte_offset, byte_length); end
    end

    # Initialize a new cache with the given source and encoding.
    sig { params(source: String, encoding: Encoding).void }
    def initialize(source, encoding); end

    # Retrieve the code units offset from the given byte offset.
    sig { params(byte_offset: Integer).returns(Integer) }
    def [](byte_offset); end
  end

  # Specialized version of Prism::Source for source code that includes ASCII
  # characters only. This class is used to apply performance optimizations that
  # cannot be applied to sources that include multibyte characters.
  #
  # In the extremely rare case that a source includes multi-byte characters but
  # is marked as binary because of a magic encoding comment and it cannot be
  # eagerly converted to UTF-8, this class will be used as well. This is because
  # at that point we will treat everything as single-byte characters.
  class ASCIISource < Source
    # Return the character offset for the given byte offset.
    sig { params(byte_offset: Integer).returns(Integer) }
    def character_offset(byte_offset); end

    # Return the column in characters for the given byte offset.
    sig { params(byte_offset: Integer).returns(Integer) }
    def character_column(byte_offset); end

    # Returns the offset from the start of the file for the given byte offset
    # counting in code units for the given encoding.
    #
    # This method is tested with UTF-8, UTF-16, and UTF-32. If there is the
    # concept of code units that differs from the number of characters in other
    # encodings, it is not captured here.
    sig { params(byte_offset: Integer, encoding: Encoding).returns(Integer) }
    def code_units_offset(byte_offset, encoding); end

    # Returns a cache that is the identity function in order to maintain the
    # same interface. We can do this because code units are always equivalent to
    # byte offsets for ASCII-only sources.
    sig { params(encoding: Encoding).returns(T.untyped) }
    def code_units_cache(encoding); end

    # Specialized version of `code_units_column` that does not depend on
    # `code_units_offset`, which is a more expensive operation. This is
    # essentially the same as `Prism::Source#column`.
    sig { params(byte_offset: Integer, encoding: Encoding).returns(Integer) }
    def code_units_column(byte_offset, encoding); end
  end

  # This represents a location in the source.
  class Location
    # A Source object that is used to determine more information from the given
    # offset and length.
    sig { returns(Source) }
    attr_reader :source

    # The byte offset from the beginning of the source where this location
    # starts.
    sig { returns(Integer) }
    attr_reader :start_offset

    # The length of this location in bytes.
    sig { returns(Integer) }
    attr_reader :length

    # Create a new location object with the given source, start byte offset, and
    # byte length.
    sig { params(source: Source, start_offset: Integer, length: Integer).void }
    def initialize(source, start_offset, length); end

    # These are the comments that are associated with this location that exist
    # before the start of this location.
    sig { returns(T::Array[Comment]) }
    def leading_comments; end

    # Attach a comment to the leading comments of this location.
    sig { params(comment: Comment).void }
    def leading_comment(comment); end

    # These are the comments that are associated with this location that exist
    # after the end of this location.
    sig { returns(T::Array[Comment]) }
    def trailing_comments; end

    # Attach a comment to the trailing comments of this location.
    sig { params(comment: Comment).void }
    def trailing_comment(comment); end

    # Returns all comments that are associated with this location (both leading
    # and trailing comments).
    sig { returns(T::Array[Comment]) }
    def comments; end

    # Create a new location object with the given options.
    sig { params(source: Source, start_offset: Integer, length: Integer).returns(Location) }
    def copy(source: T.unsafe(nil), start_offset: T.unsafe(nil), length: T.unsafe(nil)); end

    # Returns a new location that is the result of chopping off the last byte.
    sig { returns(Location) }
    def chop; end

    # Returns a string representation of this location.
    sig { returns(String) }
    def inspect; end

    # Returns all of the lines of the source code associated with this location.
    sig { returns(T::Array[String]) }
    def source_lines; end

    # The source code that this location represents.
    sig { returns(String) }
    def slice; end

    # The source code that this location represents starting from the beginning
    # of the line that this location starts on to the end of the line that this
    # location ends on.
    sig { returns(String) }
    def slice_lines; end

    # The character offset from the beginning of the source where this location
    # starts.
    sig { returns(Integer) }
    def start_character_offset; end

    # The offset from the start of the file in code units of the given encoding.
    sig { params(encoding: Encoding).returns(Integer) }
    def start_code_units_offset(encoding); end

    # The start offset from the start of the file in code units using the given
    # cache to fetch or calculate the value.
    sig { params(cache: T.untyped).returns(Integer) }
    def cached_start_code_units_offset(cache); end

    # The byte offset from the beginning of the source where this location ends.
    sig { returns(Integer) }
    def end_offset; end

    # The character offset from the beginning of the source where this location
    # ends.
    sig { returns(Integer) }
    def end_character_offset; end

    # The offset from the start of the file in code units of the given encoding.
    sig { params(encoding: Encoding).returns(Integer) }
    def end_code_units_offset(encoding); end

    # The end offset from the start of the file in code units using the given
    # cache to fetch or calculate the value.
    sig { params(cache: T.untyped).returns(Integer) }
    def cached_end_code_units_offset(cache); end

    # The line number where this location starts.
    sig { returns(Integer) }
    def start_line; end

    # The content of the line where this location starts before this location.
    sig { returns(String) }
    def start_line_slice; end

    # The line number where this location ends.
    sig { returns(Integer) }
    def end_line; end

    # The column in bytes where this location starts from the start of
    # the line.
    sig { returns(Integer) }
    def start_column; end

    # The column in characters where this location ends from the start of
    # the line.
    sig { returns(Integer) }
    def start_character_column; end

    # The column in code units of the given encoding where this location
    # starts from the start of the line.
    sig { params(encoding: Encoding).returns(Integer) }
    def start_code_units_column(encoding = T.unsafe(nil)); end

    # The start column in code units using the given cache to fetch or calculate
    # the value.
    sig { params(cache: T.untyped).returns(Integer) }
    def cached_start_code_units_column(cache); end

    # The column in bytes where this location ends from the start of the
    # line.
    sig { returns(Integer) }
    def end_column; end

    # The column in characters where this location ends from the start of
    # the line.
    sig { returns(Integer) }
    def end_character_column; end

    # The column in code units of the given encoding where this location
    # ends from the start of the line.
    sig { params(encoding: Encoding).returns(Integer) }
    def end_code_units_column(encoding = T.unsafe(nil)); end

    # The end column in code units using the given cache to fetch or calculate
    # the value.
    sig { params(cache: T.untyped).returns(Integer) }
    def cached_end_code_units_column(cache); end

    # Implement the hash pattern matching interface for Location.
    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
    def deconstruct_keys(keys); end

    # Implement the pretty print interface for Location.
    sig { params(q: PP).void }
    def pretty_print(q); end

    # Returns true if the given other location is equal to this location.
    sig { params(other: T.untyped).returns(T::Boolean) }
    def ==(other); end

    # Returns a new location that stretches from this location to the given
    # other location. Raises an error if this location is not before the other
    # location or if they don't share the same source.
    sig { params(other: Location).returns(Location) }
    def join(other); end

    # Join this location with the first occurrence of the string in the source
    # that occurs after this location on the same line, and return the new
    # location. This will raise an error if the string does not exist.
    sig { params(string: String).returns(Location) }
    def adjoin(string); end
  end

  # This represents a comment that was encountered during parsing. It is the
  # base class for all comment types.
  class Comment
    # The Location of this comment in the source.
    sig { returns(Location) }
    attr_reader :location

    # Create a new comment object with the given location.
    sig { params(location: Location).void }
    def initialize(location); end

    # Implement the hash pattern matching interface for Comment.
    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
    def deconstruct_keys(keys); end

    # Returns the content of the comment by slicing it from the source code.
    sig { returns(String) }
    def slice; end

    # Returns true if this comment happens on the same line as other code and
    # false if the comment is by itself. This can only be true for inline
    # comments and should be false for block comments.
    sig { returns(T::Boolean) }
    def trailing?; end
  end

  # InlineComment objects are the most common. They correspond to comments in
  # the source file like this one that start with #.
  class InlineComment < Comment
    # Returns true if this comment happens on the same line as other code and
    # false if the comment is by itself.
    sig { returns(T::Boolean) }
    def trailing?; end

    # Returns a string representation of this comment.
    sig { returns(String) }
    def inspect; end
  end

  # EmbDocComment objects correspond to comments that are surrounded by =begin
  # and =end.
  class EmbDocComment < Comment
    # Returns false. This can only be true for inline comments.
    sig { returns(T::Boolean) }
    def trailing?; end

    # Returns a string representation of this comment.
    sig { returns(String) }
    def inspect; end
  end

  # This represents a magic comment that was encountered during parsing.
  class MagicComment
    # A Location object representing the location of the key in the source.
    sig { returns(Location) }
    attr_reader :key_loc

    # A Location object representing the location of the value in the source.
    sig { returns(Location) }
    attr_reader :value_loc

    # Create a new magic comment object with the given key and value locations.
    sig { params(key_loc: Location, value_loc: Location).void }
    def initialize(key_loc, value_loc); end

    # Returns the key of the magic comment by slicing it from the source code.
    sig { returns(String) }
    def key; end

    # Returns the value of the magic comment by slicing it from the source code.
    sig { returns(String) }
    def value; end

    # Implement the hash pattern matching interface for MagicComment.
    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
    def deconstruct_keys(keys); end

    # Returns a string representation of this magic comment.
    sig { returns(String) }
    def inspect; end
  end

  # This represents an error that was encountered during parsing.
  class ParseError
    # The type of error. This is an _internal_ symbol that is used for
    # communicating with translation layers. It is not meant to be public API.
    sig { returns(Symbol) }
    attr_reader :type

    # The message associated with this error.
    sig { returns(String) }
    attr_reader :message

    # A Location object representing the location of this error in the source.
    sig { returns(Location) }
    attr_reader :location

    # The level of this error.
    sig { returns(Symbol) }
    attr_reader :level

    # Create a new error object with the given message and location.
    sig { params(type: Symbol, message: String, location: Location, level: Symbol).void }
    def initialize(type, message, location, level); end

    # Implement the hash pattern matching interface for ParseError.
    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
    def deconstruct_keys(keys); end

    # Returns a string representation of this error.
    sig { returns(String) }
    def inspect; end
  end

  # This represents a warning that was encountered during parsing.
  class ParseWarning
    # The type of warning. This is an _internal_ symbol that is used for
    # communicating with translation layers. It is not meant to be public API.
    sig { returns(Symbol) }
    attr_reader :type

    # The message associated with this warning.
    sig { returns(String) }
    attr_reader :message

    # A Location object representing the location of this warning in the source.
    sig { returns(Location) }
    attr_reader :location

    # The level of this warning.
    sig { returns(Symbol) }
    attr_reader :level

    # Create a new warning object with the given message and location.
    sig { params(type: Symbol, message: String, location: Location, level: Symbol).void }
    def initialize(type, message, location, level); end

    # Implement the hash pattern matching interface for ParseWarning.
    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
    def deconstruct_keys(keys); end

    # Returns a string representation of this warning.
    sig { returns(String) }
    def inspect; end
  end

  # This represents the result of a call to Prism.parse or Prism.parse_file.
  # It contains the requested structure, any comments that were encounters,
  # and any errors that were encountered.
  class Result
    # The list of comments that were encountered during parsing.
    sig { returns(T::Array[Comment]) }
    attr_reader :comments

    # The list of magic comments that were encountered during parsing.
    sig { returns(T::Array[MagicComment]) }
    attr_reader :magic_comments

    # An optional location that represents the location of the __END__ marker
    # and the rest of the content of the file. This content is loaded into the
    # DATA constant when the file being parsed is the main file being executed.
    sig { returns(T.nilable(Location)) }
    attr_reader :data_loc

    # The list of errors that were generated during parsing.
    sig { returns(T::Array[ParseError]) }
    attr_reader :errors

    # The list of warnings that were generated during parsing.
    sig { returns(T::Array[ParseWarning]) }
    attr_reader :warnings

    # A Source instance that represents the source code that was parsed.
    sig { returns(Source) }
    attr_reader :source

    # Create a new result object with the given values.
    sig { params(comments: T::Array[Comment], magic_comments: T::Array[MagicComment], data_loc: T.nilable(Location), errors: T::Array[ParseError], warnings: T::Array[ParseWarning], source: Source).void }
    def initialize(comments, magic_comments, data_loc, errors, warnings, source); end

    # Implement the hash pattern matching interface for Result.
    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
    def deconstruct_keys(keys); end

    # Returns the encoding of the source code that was parsed.
    sig { returns(Encoding) }
    def encoding; end

    # Returns true if there were no errors during parsing and false if there
    # were.
    sig { returns(T::Boolean) }
    def success?; end

    # Returns true if there were errors during parsing and false if there were
    # not.
    sig { returns(T::Boolean) }
    def failure?; end

    # Create a code units cache for the given encoding.
    sig { params(encoding: Encoding).returns(T.untyped) }
    def code_units_cache(encoding); end
  end

  # This is a result specific to the `parse` and `parse_file` methods.
  class ParseResult < Result
    # The syntax tree that was parsed from the source code.
    sig { returns(ProgramNode) }
    attr_reader :value

    # Create a new parse result object with the given values.
    sig { params(value: ProgramNode, comments: T::Array[Comment], magic_comments: T::Array[MagicComment], data_loc: T.nilable(Location), errors: T::Array[ParseError], warnings: T::Array[ParseWarning], source: Source).void }
    def initialize(value, comments, magic_comments, data_loc, errors, warnings, source); end

    # Implement the hash pattern matching interface for ParseResult.
    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
    def deconstruct_keys(keys); end

    # Attach the list of comments to their respective locations in the tree.
    sig { void }
    def attach_comments!; end

    # Walk the tree and mark nodes that are on a new line, loosely emulating
    # the behavior of CRuby's `:line` tracepoint event.
    sig { void }
    def mark_newlines!; end

    # Returns a string representation of the syntax tree with the errors
    # displayed inline.
    sig { returns(String) }
    def errors_format; end
  end

  # This is a result specific to the `lex` and `lex_file` methods.
  class LexResult < Result
    # The list of tokens that were parsed from the source code.
    sig { returns(T::Array[[Token, Integer]]) }
    attr_reader :value

    # Create a new lex result object with the given values.
    sig { params(value: T::Array[[Token, Integer]], comments: T::Array[Comment], magic_comments: T::Array[MagicComment], data_loc: T.nilable(Location), errors: T::Array[ParseError], warnings: T::Array[ParseWarning], source: Source).void }
    def initialize(value, comments, magic_comments, data_loc, errors, warnings, source); end

    # Implement the hash pattern matching interface for LexResult.
    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
    def deconstruct_keys(keys); end
  end

  # This is a result specific to the `parse_lex` and `parse_lex_file` methods.
  class ParseLexResult < Result
    # A tuple of the syntax tree and the list of tokens that were parsed from
    # the source code.
    sig { returns([ProgramNode, T::Array[[Token, Integer]]]) }
    attr_reader :value

    # Create a new parse lex result object with the given values.
    sig { params(value: [ProgramNode, T::Array[[Token, Integer]]], comments: T::Array[Comment], magic_comments: T::Array[MagicComment], data_loc: T.nilable(Location), errors: T::Array[ParseError], warnings: T::Array[ParseWarning], source: Source).void }
    def initialize(value, comments, magic_comments, data_loc, errors, warnings, source); end

    # Implement the hash pattern matching interface for ParseLexResult.
    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
    def deconstruct_keys(keys); end
  end

  # This represents a token from the Ruby source.
  class Token
    # The Source object that represents the source this token came from.
    sig { returns(Source) }
    attr_reader :source

    # The type of token that this token is.
    sig { returns(Symbol) }
    attr_reader :type

    # A byteslice of the source that this token represents.
    sig { returns(String) }
    attr_reader :value

    # Create a new token object with the given type, value, and location.
    sig { params(source: Source, type: Symbol, value: String, location: T.any(Location, Integer)).void }
    def initialize(source, type, value, location); end

    # Implement the hash pattern matching interface for Token.
    sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
    def deconstruct_keys(keys); end

    # A Location object representing the location of this token in the source.
    sig { returns(Location) }
    def location; end

    # Implement the pretty print interface for Token.
    sig { params(q: PP).void }
    def pretty_print(q); end

    # Returns true if the given other token is equal to this token.
    sig { params(other: T.untyped).returns(T::Boolean) }
    def ==(other); end

    # Returns a string representation of this token.
    sig { returns(String) }
    def inspect; end

    # Freeze this object and the objects it contains.
    sig { void }
    def deep_freeze; end
  end

  # This object is passed to the various Prism.* methods that accept the
  # `scopes` option as an element of the list. It defines both the local
  # variables visible at that scope as well as the forwarding parameters
  # available at that scope.
  class Scope
    # The list of local variables that are defined in this scope. This should be
    # defined as an array of symbols.
    sig { returns(T::Array[Symbol]) }
    attr_reader :locals

    # The list of local variables that are forwarded to the next scope. This
    # should by defined as an array of symbols containing the specific values of
    sig { returns(T::Array[Symbol]) }
    attr_reader :forwarding

    # Create a new scope object with the given locals and forwarding.
    sig { params(locals: T::Array[Symbol], forwarding: T::Array[Symbol]).void }
    def initialize(locals, forwarding); end
  end

  # Create a new scope with the given locals and forwarding options that is
  # suitable for passing into one of the Prism.* methods that accepts the
  # `scopes` option.
  sig { params(locals: T::Array[Symbol], forwarding: T::Array[Symbol]).returns(Scope) }
  def self.scope(locals: T.unsafe(nil), forwarding: T.unsafe(nil)); end
end
