# typed: strict

module Prism
  sig { params(source: String, options: T::Hash[Symbol, T.untyped]).returns(String) }
  def self.dump(source, **options); end

  sig { params(filepath: String, options: T::Hash[Symbol, T.untyped]).returns(String) }
  def self.dump_file(filepath, **options); end

  sig { params(source: String, options: T::Hash[Symbol, T.untyped]).returns(Prism::ParseResult[T::Array[T.untyped]]) }
  def self.lex(source, **options); end

  sig { params(filepath: String, options: T::Hash[Symbol, T.untyped]).returns(Prism::ParseResult[T::Array[T.untyped]]) }
  def self.lex_file(filepath, **options); end

  sig { params(source: String, options: T::Hash[Symbol, T.untyped]).returns(Prism::ParseResult[T::Array[T.untyped]]) }
  def self.lex_compat(source, **options); end

  sig { params(source: String).returns(T::Array[T.untyped]) }
  def self.lex_ripper(source); end

  sig { params(source: String, serialized: String).returns(Prism::ParseResult[Prism::ProgramNode]) }
  def self.load(source, serialized); end

  sig { params(source: String, options: T::Hash[Symbol, T.untyped]).returns(Prism::ParseResult[Prism::ProgramNode]) }
  def self.parse(source, **options); end
  
  sig { params(filepath: String, options: T::Hash[Symbol, T.untyped]).returns(Prism::ParseResult[Prism::ProgramNode]) }
  def self.parse_file(filepath, **options); end

  sig { params(source: String, options: T::Hash[Symbol, T.untyped]).returns(T::Array[Prism::Comment]) }
  def self.parse_comments(source, **options); end

  sig { params(filepath: String, options: T::Hash[Symbol, T.untyped]).returns(T::Array[Prism::Comment]) }
  def self.parse_file_comments(filepath, **options); end

  sig { params(source: String, options: T::Hash[Symbol, T.untyped]).returns(Prism::ParseResult[[Prism::ProgramNode, T::Array[T.untyped]]]) }
  def self.parse_lex(source, **options); end

  sig { params(filepath: String, options: T::Hash[Symbol, T.untyped]).returns(Prism::ParseResult[[Prism::ProgramNode, T::Array[T.untyped]]]) }
  def self.parse_lex_file(filepath, **options); end

  sig { params(source: String, options: T::Hash[Symbol, T.untyped]).returns(T::Boolean) }
  def self.parse_success?(source, **options); end

  sig { params(source: String, options: T::Hash[Symbol, T.untyped]).returns(T::Boolean) }
  def self.parse_failure?(source, **options); end

  sig { params(filepath: String, options: T::Hash[Symbol, T.untyped]).returns(T::Boolean) }
  def self.parse_file_success?(filepath, **options); end

  sig { params(filepath: String, options: T::Hash[Symbol, T.untyped]).returns(T::Boolean) }
  def self.parse_file_failure?(filepath, **options); end
end
