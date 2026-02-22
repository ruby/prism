# typed: true

# The Prism Ruby parser.
#
# "Parsing Ruby is suddenly manageable!"
#   - You, hopefully
module Prism
  # Raised when requested to parse as the currently running Ruby version but Prism has no support for it.
  class CurrentVersionError < ArgumentError
    # Initialize a new exception for the given ruby version string.
    sig { params(version: String).void }
    def initialize(version); end
  end

  # Returns a parse result whose value is an array of tokens that closely
  # resembles the return value of Ripper.lex.
  #
  # For supported options, see Prism.parse.
  sig { params(source: String, options: T.untyped).returns(LexCompat::Result) }
  def self.lex_compat(source, **options); end

  # Load the serialized AST using the source as a reference into a tree.
  sig { params(source: String, serialized: String, freeze: T::Boolean).returns(ParseResult) }
  def self.load(source, serialized, freeze = T.unsafe(nil)); end

  VERSION = T.let(nil, String)
  BACKEND = T.let(nil, Symbol)

  sig { params(source: String, filepath: String, command_line: String, encoding: T.any(Encoding, FalseClass), freeze: T::Boolean, frozen_string_literal: T::Boolean, line: Integer, main_script: T::Boolean, partial_script: T::Boolean, scopes: T::Array[T::Array[Symbol]], version: String).returns(ParseResult) }
  def self.parse(source, filepath: T.unsafe(nil), command_line: T.unsafe(nil), encoding: T.unsafe(nil), freeze: T.unsafe(nil), frozen_string_literal: T.unsafe(nil), line: T.unsafe(nil), main_script: T.unsafe(nil), partial_script: T.unsafe(nil), scopes: T.unsafe(nil), version: T.unsafe(nil)); end

  sig { params(source: String, filepath: String, command_line: String, encoding: T.any(Encoding, FalseClass), freeze: T::Boolean, frozen_string_literal: T::Boolean, line: Integer, main_script: T::Boolean, partial_script: T::Boolean, scopes: T::Array[T::Array[Symbol]], version: String).void }
  def self.profile(source, filepath: T.unsafe(nil), command_line: T.unsafe(nil), encoding: T.unsafe(nil), freeze: T.unsafe(nil), frozen_string_literal: T.unsafe(nil), line: T.unsafe(nil), main_script: T.unsafe(nil), partial_script: T.unsafe(nil), scopes: T.unsafe(nil), version: T.unsafe(nil)); end

  sig { params(source: String, filepath: String, command_line: String, encoding: T.any(Encoding, FalseClass), freeze: T::Boolean, frozen_string_literal: T::Boolean, line: Integer, main_script: T::Boolean, partial_script: T::Boolean, scopes: T::Array[T::Array[Symbol]], version: String).returns(LexResult) }
  def self.lex(source, filepath: T.unsafe(nil), command_line: T.unsafe(nil), encoding: T.unsafe(nil), freeze: T.unsafe(nil), frozen_string_literal: T.unsafe(nil), line: T.unsafe(nil), main_script: T.unsafe(nil), partial_script: T.unsafe(nil), scopes: T.unsafe(nil), version: T.unsafe(nil)); end

  sig { params(source: String, filepath: String, command_line: String, encoding: T.any(Encoding, FalseClass), freeze: T::Boolean, frozen_string_literal: T::Boolean, line: Integer, main_script: T::Boolean, partial_script: T::Boolean, scopes: T::Array[T::Array[Symbol]], version: String).returns(ParseLexResult) }
  def self.parse_lex(source, filepath: T.unsafe(nil), command_line: T.unsafe(nil), encoding: T.unsafe(nil), freeze: T.unsafe(nil), frozen_string_literal: T.unsafe(nil), line: T.unsafe(nil), main_script: T.unsafe(nil), partial_script: T.unsafe(nil), scopes: T.unsafe(nil), version: T.unsafe(nil)); end

  sig { params(source: String, filepath: String, command_line: String, encoding: T.any(Encoding, FalseClass), freeze: T::Boolean, frozen_string_literal: T::Boolean, line: Integer, main_script: T::Boolean, partial_script: T::Boolean, scopes: T::Array[T::Array[Symbol]], version: String).returns(String) }
  def self.dump(source, filepath: T.unsafe(nil), command_line: T.unsafe(nil), encoding: T.unsafe(nil), freeze: T.unsafe(nil), frozen_string_literal: T.unsafe(nil), line: T.unsafe(nil), main_script: T.unsafe(nil), partial_script: T.unsafe(nil), scopes: T.unsafe(nil), version: T.unsafe(nil)); end

  sig { params(source: String, filepath: String, command_line: String, encoding: T.any(Encoding, FalseClass), freeze: T::Boolean, frozen_string_literal: T::Boolean, line: Integer, main_script: T::Boolean, partial_script: T::Boolean, scopes: T::Array[T::Array[Symbol]], version: String).returns(T::Array[Comment]) }
  def self.parse_comments(source, filepath: T.unsafe(nil), command_line: T.unsafe(nil), encoding: T.unsafe(nil), freeze: T.unsafe(nil), frozen_string_literal: T.unsafe(nil), line: T.unsafe(nil), main_script: T.unsafe(nil), partial_script: T.unsafe(nil), scopes: T.unsafe(nil), version: T.unsafe(nil)); end

  sig { params(source: String, filepath: String, command_line: String, encoding: T.any(Encoding, FalseClass), freeze: T::Boolean, frozen_string_literal: T::Boolean, line: Integer, main_script: T::Boolean, partial_script: T::Boolean, scopes: T::Array[T::Array[Symbol]], version: String).returns(T::Boolean) }
  def self.parse_success?(source, filepath: T.unsafe(nil), command_line: T.unsafe(nil), encoding: T.unsafe(nil), freeze: T.unsafe(nil), frozen_string_literal: T.unsafe(nil), line: T.unsafe(nil), main_script: T.unsafe(nil), partial_script: T.unsafe(nil), scopes: T.unsafe(nil), version: T.unsafe(nil)); end

  sig { params(source: String, filepath: String, command_line: String, encoding: T.any(Encoding, FalseClass), freeze: T::Boolean, frozen_string_literal: T::Boolean, line: Integer, main_script: T::Boolean, partial_script: T::Boolean, scopes: T::Array[T::Array[Symbol]], version: String).returns(T::Boolean) }
  def self.parse_failure?(source, filepath: T.unsafe(nil), command_line: T.unsafe(nil), encoding: T.unsafe(nil), freeze: T.unsafe(nil), frozen_string_literal: T.unsafe(nil), line: T.unsafe(nil), main_script: T.unsafe(nil), partial_script: T.unsafe(nil), scopes: T.unsafe(nil), version: T.unsafe(nil)); end

  sig { params(stream: T.untyped, filepath: String, command_line: String, encoding: T.any(Encoding, FalseClass), freeze: T::Boolean, frozen_string_literal: T::Boolean, line: Integer, main_script: T::Boolean, partial_script: T::Boolean, scopes: T::Array[T::Array[Symbol]], version: String).returns(ParseResult) }
  def self.parse_stream(stream, filepath: T.unsafe(nil), command_line: T.unsafe(nil), encoding: T.unsafe(nil), freeze: T.unsafe(nil), frozen_string_literal: T.unsafe(nil), line: T.unsafe(nil), main_script: T.unsafe(nil), partial_script: T.unsafe(nil), scopes: T.unsafe(nil), version: T.unsafe(nil)); end

  sig { params(filepath: String, command_line: String, encoding: T.any(Encoding, FalseClass), freeze: T::Boolean, frozen_string_literal: T::Boolean, line: Integer, main_script: T::Boolean, partial_script: T::Boolean, scopes: T::Array[T::Array[Symbol]], version: String).returns(ParseResult) }
  def self.parse_file(filepath, command_line: T.unsafe(nil), encoding: T.unsafe(nil), freeze: T.unsafe(nil), frozen_string_literal: T.unsafe(nil), line: T.unsafe(nil), main_script: T.unsafe(nil), partial_script: T.unsafe(nil), scopes: T.unsafe(nil), version: T.unsafe(nil)); end

  sig { params(filepath: String, command_line: String, encoding: T.any(Encoding, FalseClass), freeze: T::Boolean, frozen_string_literal: T::Boolean, line: Integer, main_script: T::Boolean, partial_script: T::Boolean, scopes: T::Array[T::Array[Symbol]], version: String).void }
  def self.profile_file(filepath, command_line: T.unsafe(nil), encoding: T.unsafe(nil), freeze: T.unsafe(nil), frozen_string_literal: T.unsafe(nil), line: T.unsafe(nil), main_script: T.unsafe(nil), partial_script: T.unsafe(nil), scopes: T.unsafe(nil), version: T.unsafe(nil)); end

  sig { params(filepath: String, command_line: String, encoding: T.any(Encoding, FalseClass), freeze: T::Boolean, frozen_string_literal: T::Boolean, line: Integer, main_script: T::Boolean, partial_script: T::Boolean, scopes: T::Array[T::Array[Symbol]], version: String).returns(LexResult) }
  def self.lex_file(filepath, command_line: T.unsafe(nil), encoding: T.unsafe(nil), freeze: T.unsafe(nil), frozen_string_literal: T.unsafe(nil), line: T.unsafe(nil), main_script: T.unsafe(nil), partial_script: T.unsafe(nil), scopes: T.unsafe(nil), version: T.unsafe(nil)); end

  sig { params(filepath: String, command_line: String, encoding: T.any(Encoding, FalseClass), freeze: T::Boolean, frozen_string_literal: T::Boolean, line: Integer, main_script: T::Boolean, partial_script: T::Boolean, scopes: T::Array[T::Array[Symbol]], version: String).returns(ParseLexResult) }
  def self.parse_lex_file(filepath, command_line: T.unsafe(nil), encoding: T.unsafe(nil), freeze: T.unsafe(nil), frozen_string_literal: T.unsafe(nil), line: T.unsafe(nil), main_script: T.unsafe(nil), partial_script: T.unsafe(nil), scopes: T.unsafe(nil), version: T.unsafe(nil)); end

  sig { params(filepath: String, command_line: String, encoding: T.any(Encoding, FalseClass), freeze: T::Boolean, frozen_string_literal: T::Boolean, line: Integer, main_script: T::Boolean, partial_script: T::Boolean, scopes: T::Array[T::Array[Symbol]], version: String).returns(String) }
  def self.dump_file(filepath, command_line: T.unsafe(nil), encoding: T.unsafe(nil), freeze: T.unsafe(nil), frozen_string_literal: T.unsafe(nil), line: T.unsafe(nil), main_script: T.unsafe(nil), partial_script: T.unsafe(nil), scopes: T.unsafe(nil), version: T.unsafe(nil)); end

  sig { params(filepath: String, command_line: String, encoding: T.any(Encoding, FalseClass), freeze: T::Boolean, frozen_string_literal: T::Boolean, line: Integer, main_script: T::Boolean, partial_script: T::Boolean, scopes: T::Array[T::Array[Symbol]], version: String).returns(T::Array[Comment]) }
  def self.parse_file_comments(filepath, command_line: T.unsafe(nil), encoding: T.unsafe(nil), freeze: T.unsafe(nil), frozen_string_literal: T.unsafe(nil), line: T.unsafe(nil), main_script: T.unsafe(nil), partial_script: T.unsafe(nil), scopes: T.unsafe(nil), version: T.unsafe(nil)); end

  sig { params(filepath: String, command_line: String, encoding: T.any(Encoding, FalseClass), freeze: T::Boolean, frozen_string_literal: T::Boolean, line: Integer, main_script: T::Boolean, partial_script: T::Boolean, scopes: T::Array[T::Array[Symbol]], version: String).returns(T::Boolean) }
  def self.parse_file_success?(filepath, command_line: T.unsafe(nil), encoding: T.unsafe(nil), freeze: T.unsafe(nil), frozen_string_literal: T.unsafe(nil), line: T.unsafe(nil), main_script: T.unsafe(nil), partial_script: T.unsafe(nil), scopes: T.unsafe(nil), version: T.unsafe(nil)); end

  sig { params(filepath: String, command_line: String, encoding: T.any(Encoding, FalseClass), freeze: T::Boolean, frozen_string_literal: T::Boolean, line: Integer, main_script: T::Boolean, partial_script: T::Boolean, scopes: T::Array[T::Array[Symbol]], version: String).returns(T::Boolean) }
  def self.parse_file_failure?(filepath, command_line: T.unsafe(nil), encoding: T.unsafe(nil), freeze: T.unsafe(nil), frozen_string_literal: T.unsafe(nil), line: T.unsafe(nil), main_script: T.unsafe(nil), partial_script: T.unsafe(nil), scopes: T.unsafe(nil), version: T.unsafe(nil)); end
end
