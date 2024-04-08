# typed: strict

module Prism
  sig { params(source: String, filepath: T.nilable(String), line: T.nilable(Integer), offset: T.nilable(Integer), encoding: T.nilable(Encoding), frozen_string_literal: T.nilable(T::Boolean), verbose: T.nilable(T::Boolean), scopes: T.nilable(T::Array[T::Array[Symbol]])).returns(String) }
  def self.dump(source, filepath: nil, line: nil, offset: nil, encoding: nil, frozen_string_literal: nil, verbose: nil, scopes: nil); end

  sig { params(filepath: String, line: T.nilable(Integer), offset: T.nilable(Integer), encoding: T.nilable(Encoding), frozen_string_literal: T.nilable(T::Boolean), verbose: T.nilable(T::Boolean), scopes: T.nilable(T::Array[T::Array[Symbol]])).returns(String) }
  def self.dump_file(filepath, line: nil, offset: nil, encoding: nil, frozen_string_literal: nil, verbose: nil, scopes: nil); end

  sig { params(source: String, filepath: T.nilable(String), line: T.nilable(Integer), offset: T.nilable(Integer), encoding: T.nilable(Encoding), frozen_string_literal: T.nilable(T::Boolean), verbose: T.nilable(T::Boolean), scopes: T.nilable(T::Array[T::Array[Symbol]])).returns(Prism::ParseResult[T::Array[T.untyped]]) }
  def self.lex(source, filepath: nil, line: nil, offset: nil, encoding: nil, frozen_string_literal: nil, verbose: nil, scopes: nil); end

  sig { params(filepath: String, line: T.nilable(Integer), offset: T.nilable(Integer), encoding: T.nilable(Encoding), frozen_string_literal: T.nilable(T::Boolean), verbose: T.nilable(T::Boolean), scopes: T.nilable(T::Array[T::Array[Symbol]])).returns(Prism::ParseResult[T::Array[T.untyped]]) }
  def self.lex_file(filepath, line: nil, offset: nil, encoding: nil, frozen_string_literal: nil, verbose: nil, scopes: nil); end

  sig { params(source: String, filepath: T.nilable(String), line: T.nilable(Integer), offset: T.nilable(Integer), encoding: T.nilable(Encoding), frozen_string_literal: T.nilable(T::Boolean), verbose: T.nilable(T::Boolean), scopes: T.nilable(T::Array[T::Array[Symbol]])).returns(Prism::ParseResult[T::Array[T.untyped]]) }
  def self.lex_compat(source, filepath: nil, line: nil, offset: nil, encoding: nil, frozen_string_literal: nil, verbose: nil, scopes: nil); end

  sig { params(source: String).returns(T::Array[T.untyped]) }
  def self.lex_ripper(source); end

  sig { params(source: String, serialized: String).returns(Prism::ParseResult[Prism::ProgramNode]) }
  def self.load(source, serialized); end

  sig { params(source: String, filepath: T.nilable(String), line: T.nilable(Integer), offset: T.nilable(Integer), encoding: T.nilable(Encoding), frozen_string_literal: T.nilable(T::Boolean), verbose: T.nilable(T::Boolean), scopes: T.nilable(T::Array[T::Array[Symbol]])).returns(Prism::ParseResult[Prism::ProgramNode]) }
  def self.parse(source, filepath: nil, line: nil, offset: nil, encoding: nil, frozen_string_literal: nil, verbose: nil, scopes: nil); end

  sig { params(filepath: String, line: T.nilable(Integer), offset: T.nilable(Integer), encoding: T.nilable(Encoding), frozen_string_literal: T.nilable(T::Boolean), verbose: T.nilable(T::Boolean), scopes: T.nilable(T::Array[T::Array[Symbol]])).returns(Prism::ParseResult[Prism::ProgramNode]) }
  def self.parse_file(filepath, line: nil, offset: nil, encoding: nil, frozen_string_literal: nil, verbose: nil, scopes: nil); end

  sig { params(stream: T.any(IO, StringIO), filepath: T.nilable(String), line: T.nilable(Integer), offset: T.nilable(Integer), encoding: T.nilable(Encoding), frozen_string_literal: T.nilable(T::Boolean), verbose: T.nilable(T::Boolean), scopes: T.nilable(T::Array[T::Array[Symbol]])).returns(Prism::ParseResult[Prism::ProgramNode]) }
  def self.parse_stream(stream, filepath: nil, line: nil, offset: nil, encoding: nil, frozen_string_literal: nil, verbose: nil, scopes: nil); end

  sig { params(source: String, filepath: T.nilable(String), line: T.nilable(Integer), offset: T.nilable(Integer), encoding: T.nilable(Encoding), frozen_string_literal: T.nilable(T::Boolean), verbose: T.nilable(T::Boolean), scopes: T.nilable(T::Array[T::Array[Symbol]])).returns(T::Array[Prism::Comment]) }
  def self.parse_comments(source, filepath: nil, line: nil, offset: nil, encoding: nil, frozen_string_literal: nil, verbose: nil, scopes: nil); end

  sig { params(filepath: String, line: T.nilable(Integer), offset: T.nilable(Integer), encoding: T.nilable(Encoding), frozen_string_literal: T.nilable(T::Boolean), verbose: T.nilable(T::Boolean), scopes: T.nilable(T::Array[T::Array[Symbol]])).returns(T::Array[Prism::Comment]) }
  def self.parse_file_comments(filepath, line: nil, offset: nil, encoding: nil, frozen_string_literal: nil, verbose: nil, scopes: nil); end

  sig { params(source: String, filepath: T.nilable(String), line: T.nilable(Integer), offset: T.nilable(Integer), encoding: T.nilable(Encoding), frozen_string_literal: T.nilable(T::Boolean), verbose: T.nilable(T::Boolean), scopes: T.nilable(T::Array[T::Array[Symbol]])).returns(Prism::ParseResult[[Prism::ProgramNode, T::Array[T.untyped]]]) }
  def self.parse_lex(source, filepath: nil, line: nil, offset: nil, encoding: nil, frozen_string_literal: nil, verbose: nil, scopes: nil); end

  sig { params(filepath: String, line: T.nilable(Integer), offset: T.nilable(Integer), encoding: T.nilable(Encoding), frozen_string_literal: T.nilable(T::Boolean), verbose: T.nilable(T::Boolean), scopes: T.nilable(T::Array[T::Array[Symbol]])).returns(Prism::ParseResult[[Prism::ProgramNode, T::Array[T.untyped]]]) }
  def self.parse_lex_file(filepath, line: nil, offset: nil, encoding: nil, frozen_string_literal: nil, verbose: nil, scopes: nil); end

  sig { params(source: String, filepath: T.nilable(String), line: T.nilable(Integer), offset: T.nilable(Integer), encoding: T.nilable(Encoding), frozen_string_literal: T.nilable(T::Boolean), verbose: T.nilable(T::Boolean), scopes: T.nilable(T::Array[T::Array[Symbol]])).returns(T::Boolean) }
  def self.parse_success?(source, filepath: nil, line: nil, offset: nil, encoding: nil, frozen_string_literal: nil, verbose: nil, scopes: nil); end

  sig { params(source: String, filepath: T.nilable(String), line: T.nilable(Integer), offset: T.nilable(Integer), encoding: T.nilable(Encoding), frozen_string_literal: T.nilable(T::Boolean), verbose: T.nilable(T::Boolean), scopes: T.nilable(T::Array[T::Array[Symbol]])).returns(T::Boolean) }
  def self.parse_failure?(source, filepath: nil, line: nil, offset: nil, encoding: nil, frozen_string_literal: nil, verbose: nil, scopes: nil); end

  sig { params(filepath: String, line: T.nilable(Integer), offset: T.nilable(Integer), encoding: T.nilable(Encoding), frozen_string_literal: T.nilable(T::Boolean), verbose: T.nilable(T::Boolean), scopes: T.nilable(T::Array[T::Array[Symbol]])).returns(T::Boolean) }
  def self.parse_file_success?(filepath, line: nil, offset: nil, encoding: nil, frozen_string_literal: nil, verbose: nil, scopes: nil); end

  sig { params(filepath: String, line: T.nilable(Integer), offset: T.nilable(Integer), encoding: T.nilable(Encoding), frozen_string_literal: T.nilable(T::Boolean), verbose: T.nilable(T::Boolean), scopes: T.nilable(T::Array[T::Array[Symbol]])).returns(T::Boolean) }
  def self.parse_file_failure?(filepath, line: nil, offset: nil, encoding: nil, frozen_string_literal: nil, verbose: nil, scopes: nil); end
end
