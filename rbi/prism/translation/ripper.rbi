# typed: strict

class Prism::Translation::Ripper < Prism::Compiler
  Result = type_member

  sig { returns(T::Boolean) }
  def error?; end

  sig { returns(T.nilable(Result)) }
  def parse; end

  sig { params(source: String, filename: String, lineno: Integer, raise_errors: T.untyped).returns(T.untyped) }
  def self.sexp_raw(source, filename = "-", lineno = 1, raise_errors: false); end

  sig { params(source: String, filename: String, lineno: Integer, raise_errors: T.untyped).returns(T.untyped) }
  def self.sexp(source, filename = "-", lineno = 1, raise_errors: false); end
end

class Prism::Translation::Ripper::SexpBuilder < Prism::Translation::Ripper
  Result = type_member { { fixed: T::Array[T.untyped] } }
end

class Prism::Translation::Ripper::SexpBuilderPP < Prism::Translation::Ripper::SexpBuilder
  Result = type_member { { fixed: T::Array[T.untyped] } }
end
