# typed: strict

module Prism
  sig { params(source: String, command_line: T.nilable(String), encoding: T.nilable(T.any(FalseClass, Encoding)), filepath: T.nilable(String), frozen_string_literal: T.nilable(T::Boolean), line: T.nilable(Integer), scopes: T.nilable(T::Array[T::Array[Symbol]]), version: T.nilable(String)).returns(String) }
  def self.dump(source, command_line: nil, encoding: nil, filepath: nil, frozen_string_literal: nil, line: nil, scopes: nil, version: nil); end

  sig { params(filepath: String, command_line: T.nilable(String), encoding: T.nilable(T.any(FalseClass, Encoding)), frozen_string_literal: T.nilable(T::Boolean), line: T.nilable(Integer), scopes: T.nilable(T::Array[T::Array[Symbol]]), version: T.nilable(String)).returns(String) }
  def self.dump_file(filepath, command_line: nil, encoding: nil, frozen_string_literal: nil, line: nil, scopes: nil, version: nil); end

  sig { params(source: String, command_line: T.nilable(String), encoding: T.nilable(T.any(FalseClass, Encoding)), filepath: T.nilable(String), frozen_string_literal: T.nilable(T::Boolean), line: T.nilable(Integer), scopes: T.nilable(T::Array[T::Array[Symbol]]), version: T.nilable(String)).returns(Prism::LexResult) }
  def self.lex(source, command_line: nil, encoding: nil, filepath: nil, frozen_string_literal: nil, line: nil, scopes: nil, version: nil); end

  sig { params(filepath: String, command_line: T.nilable(String), encoding: T.nilable(T.any(FalseClass, Encoding)), frozen_string_literal: T.nilable(T::Boolean), line: T.nilable(Integer), scopes: T.nilable(T::Array[T::Array[Symbol]]), version: T.nilable(String)).returns(Prism::LexResult) }
  def self.lex_file(filepath, command_line: nil, encoding: nil, frozen_string_literal: nil, line: nil, scopes: nil, version: nil); end

  sig { params(source: String, options: T::Hash[Symbol, T.untyped]).returns(Prism::LexCompat::Result) }
  def self.lex_compat(source, **options); end

  sig { params(source: String).returns(T::Array[T.untyped]) }
  def self.lex_ripper(source); end

  sig { params(source: String, serialized: String).returns(Prism::ParseResult) }
  def self.load(source, serialized); end

  sig { params(source: String, command_line: T.nilable(String), encoding: T.nilable(T.any(FalseClass, Encoding)), filepath: T.nilable(String), frozen_string_literal: T.nilable(T::Boolean), line: T.nilable(Integer), scopes: T.nilable(T::Array[T::Array[Symbol]]), version: T.nilable(String)).returns(Prism::ParseResult) }
  def self.parse(source, command_line: nil, encoding: nil, filepath: nil, frozen_string_literal: nil, line: nil, scopes: nil, version: nil); end

  sig { params(filepath: String, command_line: T.nilable(String), encoding: T.nilable(T.any(FalseClass, Encoding)), frozen_string_literal: T.nilable(T::Boolean), line: T.nilable(Integer), scopes: T.nilable(T::Array[T::Array[Symbol]]), version: T.nilable(String)).returns(Prism::ParseResult) }
  def self.parse_file(filepath, command_line: nil, encoding: nil, frozen_string_literal: nil, line: nil, scopes: nil, version: nil); end

  sig { params(source: String, command_line: T.nilable(String), encoding: T.nilable(T.any(FalseClass, Encoding)), filepath: T.nilable(String), frozen_string_literal: T.nilable(T::Boolean), line: T.nilable(Integer), scopes: T.nilable(T::Array[T::Array[Symbol]]), version: T.nilable(String)).void }
  def self.profile(source, command_line: nil, encoding: nil, filepath: nil, frozen_string_literal: nil, line: nil, scopes: nil, version: nil); end

  sig { params(filepath: String, command_line: T.nilable(String), encoding: T.nilable(T.any(FalseClass, Encoding)), frozen_string_literal: T.nilable(T::Boolean), line: T.nilable(Integer), scopes: T.nilable(T::Array[T::Array[Symbol]]), version: T.nilable(String)).void }
  def self.profile_file(filepath, command_line: nil, encoding: nil, frozen_string_literal: nil, line: nil, scopes: nil, version: nil); end

  sig { params(stream: T.any(IO, StringIO), command_line: T.nilable(String), encoding: T.nilable(T.any(FalseClass, Encoding)), filepath: T.nilable(String), frozen_string_literal: T.nilable(T::Boolean), line: T.nilable(Integer), scopes: T.nilable(T::Array[T::Array[Symbol]]), version: T.nilable(String)).returns(Prism::ParseResult) }
  def self.parse_stream(stream, command_line: nil, encoding: nil, filepath: nil, frozen_string_literal: nil, line: nil, scopes: nil, version: nil); end

  sig { params(source: String, command_line: T.nilable(String), encoding: T.nilable(T.any(String, Encoding)), filepath: T.nilable(String), frozen_string_literal: T.nilable(T::Boolean), line: T.nilable(Integer), scopes: T.nilable(T::Array[T::Array[Symbol]]), version: T.nilable(String)).returns(T::Array[Prism::Comment]) }
  def self.parse_comments(source, command_line: nil, encoding: nil, filepath: nil, frozen_string_literal: nil, line: nil, scopes: nil, version: nil); end

  sig { params(filepath: String, command_line: T.nilable(String), encoding: T.nilable(T.any(FalseClass, Encoding)), frozen_string_literal: T.nilable(T::Boolean), line: T.nilable(Integer), scopes: T.nilable(T::Array[T::Array[Symbol]]), version: T.nilable(String)).returns(T::Array[Prism::Comment]) }
  def self.parse_file_comments(filepath, command_line: nil, encoding: nil, frozen_string_literal: nil, line: nil, scopes: nil, version: nil); end

  sig { params(source: String, command_line: T.nilable(String), encoding: T.nilable(T.any(FalseClass, Encoding)), filepath: T.nilable(String), frozen_string_literal: T.nilable(T::Boolean), line: T.nilable(Integer), scopes: T.nilable(T::Array[T::Array[Symbol]]), version: T.nilable(String)).returns(Prism::ParseLexResult) }
  def self.parse_lex(source, command_line: nil, encoding: nil, filepath: nil, frozen_string_literal: nil, line: nil, scopes: nil, version: nil); end

  sig { params(filepath: String, command_line: T.nilable(String), encoding: T.nilable(T.any(FalseClass, Encoding)), frozen_string_literal: T.nilable(T::Boolean), line: T.nilable(Integer), scopes: T.nilable(T::Array[T::Array[Symbol]]), version: T.nilable(String)).returns(Prism::ParseLexResult) }
  def self.parse_lex_file(filepath, command_line: nil, encoding: nil, frozen_string_literal: nil, line: nil, scopes: nil, version: nil); end

  sig { params(source: String, command_line: T.nilable(String), encoding: T.nilable(T.any(FalseClass, Encoding)), filepath: T.nilable(String), frozen_string_literal: T.nilable(T::Boolean), line: T.nilable(Integer), scopes: T.nilable(T::Array[T::Array[Symbol]]), version: T.nilable(String)).returns(T::Boolean) }
  def self.parse_success?(source, command_line: nil, encoding: nil, filepath: nil, frozen_string_literal: nil, line: nil, scopes: nil, version: nil); end

  sig { params(source: String, command_line: T.nilable(String), encoding: T.nilable(T.any(FalseClass, Encoding)), filepath: T.nilable(String), frozen_string_literal: T.nilable(T::Boolean), line: T.nilable(Integer), scopes: T.nilable(T::Array[T::Array[Symbol]]), version: T.nilable(String)).returns(T::Boolean) }
  def self.parse_failure?(source, command_line: nil, encoding: nil, filepath: nil, frozen_string_literal: nil, line: nil, scopes: nil, version: nil); end

  sig { params(filepath: String, command_line: T.nilable(String), encoding: T.nilable(T.any(FalseClass, Encoding)), frozen_string_literal: T.nilable(T::Boolean), line: T.nilable(Integer), scopes: T.nilable(T::Array[T::Array[Symbol]]), version: T.nilable(String)).returns(T::Boolean) }
  def self.parse_file_success?(filepath, command_line: nil, encoding: nil, frozen_string_literal: nil, line: nil, scopes: nil, version: nil); end

  sig { params(filepath: String, command_line: T.nilable(String), encoding: T.nilable(T.any(FalseClass, Encoding)), frozen_string_literal: T.nilable(T::Boolean), line: T.nilable(Integer), scopes: T.nilable(T::Array[T::Array[Symbol]]), version: T.nilable(String)).returns(T::Boolean) }
  def self.parse_file_failure?(filepath, command_line: nil, encoding: nil, frozen_string_literal: nil, line: nil, scopes: nil, version: nil); end
end
