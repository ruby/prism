# typed: strict

class Prism::Source
  sig { returns(String) }
  attr_reader :source

  sig { returns(Integer) }
  attr_reader :start_line

  sig { returns(T::Array[Integer]) }
  attr_reader :offsets

  sig { params(source: String, start_line: Integer, offsets: T::Array[Integer]).void }
  def initialize(source, start_line = 1, offsets = []); end

  sig { returns(Encoding) }
  def encoding; end

  sig { params(byte_offset: Integer, length: Integer).returns(String) }
  def slice(byte_offset, length); end

  sig { params(byte_offset: Integer).returns(Integer) }
  def line(byte_offset); end

  sig { params(byte_offset: Integer).returns(Integer) }
  def line_start(byte_offset); end

  sig { params(byte_offset: Integer).returns(Integer) }
  def column(byte_offset); end

  sig { params(byte_offset: Integer).returns(Integer) }
  def character_offset(byte_offset); end

  sig { params(byte_offset: Integer).returns(Integer) }
  def character_column(byte_offset); end

  sig { params(byte_offset: Integer, encoding: Encoding).returns(Integer) }
  def code_units_offset(byte_offset, encoding); end

  sig { params(byte_offset: Integer, encoding: Encoding).returns(Integer) }
  def code_units_column(byte_offset, encoding); end
end

class Prism::Location
  sig { returns(Prism::Source) }
  attr_reader :source

  sig { returns(Integer) }
  attr_reader :start_offset

  sig { returns(Integer) }
  attr_reader :length

  sig { params(source: Prism::Source, start_offset: Integer, length: Integer).void }
  def initialize(source, start_offset, length); end

  sig { returns(T::Array[Prism::Comment]) }
  def leading_comments; end

  sig { params(comment: Prism::Comment).void }
  def leading_comment(comment); end

  sig { returns(T::Array[Prism::Comment]) }
  def trailing_comments; end

  sig { params(comment: Prism::Comment).void }
  def trailing_comment(comment); end

  sig { returns(T::Array[Prism::Comment]) }
  def comments; end

  sig { params(source: Prism::Source, start_offset: Integer, length: Integer).returns(Prism::Location) }
  def copy(source: self.source, start_offset: self.start_offset, length: self.length); end

  sig { returns(Prism::Location) }
  def chop; end

  sig { returns(String) }
  def inspect; end

  sig { returns(String) }
  def slice; end

  sig { returns(Integer) }
  def start_character_offset; end

  sig { params(encoding: Encoding).returns(Integer) }
  def start_code_units_offset(encoding = Encoding::UTF_16LE); end

  sig { returns(Integer) }
  def end_offset; end

  sig { returns(Integer) }
  def end_character_offset; end

  sig { params(encoding: Encoding).returns(Integer) }
  def end_code_units_offset(encoding = Encoding::UTF_16LE); end

  sig { returns(Integer) }
  def start_line; end

  sig { returns(String) }
  def start_line_slice; end

  sig { returns(Integer) }
  def end_line; end

  sig { returns(Integer) }
  def start_column; end

  sig { returns(Integer) }
  def start_character_column; end

  sig { params(encoding: Encoding).returns(Integer) }
  def start_code_units_column(encoding = Encoding::UTF_16LE); end

  sig { returns(Integer) }
  def end_column; end

  sig { returns(Integer) }
  def end_character_column; end

  sig { params(encoding: Encoding).returns(Integer) }
  def end_code_units_column(encoding = Encoding::UTF_16LE); end

  sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
  def deconstruct_keys(keys); end

  sig { params(q: T.untyped).void }
  def pretty_print(q); end

  sig { params(other: T.untyped).returns(T::Boolean) }
  def ==(other); end

  sig { params(other: Prism::Location).returns(Prism::Location) }
  def join(other); end
end

class Prism::Comment
  abstract!

  sig { returns(Prism::Location) }
  attr_reader :location

  sig { params(location: Prism::Location).void }
  def initialize(location); end

  sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
  def deconstruct_keys(keys); end

  sig { returns(String) }
  def slice; end

  sig { abstract.returns(T::Boolean) }
  def trailing?; end
end

class Prism::InlineComment < Prism::Comment
  sig { override.returns(T::Boolean) }
  def trailing?; end

  sig { returns(String) }
  def inspect; end
end

class Prism::EmbDocComment < Prism::Comment
  sig { override.returns(T::Boolean) }
  def trailing?; end

  sig { returns(String) }
  def inspect; end
end

class Prism::MagicComment
  sig { returns(Prism::Location) }
  attr_reader :key_loc

  sig { returns(Prism::Location) }
  attr_reader :value_loc

  sig { params(key_loc: Prism::Location, value_loc: Prism::Location).void }
  def initialize(key_loc, value_loc); end

  sig { returns(String) }
  def key; end

  sig { returns(String) }
  def value; end

  sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
  def deconstruct_keys(keys); end

  sig { returns(String) }
  def inspect; end
end

class Prism::ParseError
  sig { returns(Symbol) }
  attr_reader :type

  sig { returns(String) }
  attr_reader :message

  sig { returns(Prism::Location) }
  attr_reader :location

  sig { returns(Symbol) }
  attr_reader :level

  sig { params(type: Symbol, message: String, location: Prism::Location, level: Symbol).void }
  def initialize(type, message, location, level); end

  sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
  def deconstruct_keys(keys); end

  sig { returns(String) }
  def inspect; end
end

class Prism::ParseWarning
  sig { returns(Symbol) }
  attr_reader :type

  sig { returns(String) }
  attr_reader :message

  sig { returns(Prism::Location) }
  attr_reader :location

  sig { returns(Symbol) }
  attr_reader :level

  sig { params(type: Symbol, message: String, location: Prism::Location, level: Symbol).void }
  def initialize(type, message, location, level); end

  sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
  def deconstruct_keys(keys); end

  sig { returns(String) }
  def inspect; end
end

class Prism::ParseResult
  Value = type_member

  sig { returns(Value) }
  attr_reader :value

  sig { returns(T::Array[Prism::Comment]) }
  attr_reader :comments

  sig { returns(T::Array[Prism::MagicComment]) }
  attr_reader :magic_comments

  sig { returns(T.nilable(Prism::Location)) }
  attr_reader :data_loc

  sig { returns(T::Array[Prism::ParseError]) }
  attr_reader :errors

  sig { returns(T::Array[Prism::ParseWarning]) }
  attr_reader :warnings

  sig { returns(Prism::Source) }
  attr_reader :source

  sig { params(value: Value, comments: T::Array[Prism::Comment], magic_comments: T::Array[Prism::MagicComment], data_loc: T.nilable(Prism::Location), errors: T::Array[Prism::ParseError], warnings: T::Array[Prism::ParseWarning], source: Prism::Source).void }
  def initialize(value, comments, magic_comments, data_loc, errors, warnings, source); end

  sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
  def deconstruct_keys(keys); end

  sig { returns(Encoding) }
  def encoding; end

  sig { returns(T::Boolean) }
  def success?; end

  sig { returns(T::Boolean) }
  def failure?; end
end

class Prism::Token
  sig { returns(Prism::Source) }
  attr_reader :source

  sig { returns(Symbol) }
  attr_reader :type

  sig { returns(String) }
  attr_reader :value

  sig { params(source: Prism::Source, type: Symbol, value: String, location: T.any(Integer, Prism::Location)).void }
  def initialize(source, type, value, location); end

  sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
  def deconstruct_keys(keys); end

  sig { returns(Prism::Location) }
  def location; end

  sig { params(q: T.untyped).void }
  def pretty_print(q); end

  sig { params(other: T.untyped).returns(T::Boolean) }
  def ==(other); end
end
