class Prism::ParseResult
  sig { returns(Prism::ProgramNode) }
  def value; end

  sig { returns(T::Array[Prism::Comment]) }
  def comments; end

  sig { returns(T::Array[Prism::ParseError]) }
  def errors; end

  sig { returns(T::Array[Prism::ParseWarning]) }
  def warnings; end

  sig { returns(Prism::Source) }
  def source; end
end

class Prism::ParseError
  sig { returns(String) }
  def message; end

  sig { returns(Prism::Location) }
  def location; end
end

class Prism::ParseWarning
  sig { returns(String) }
  def message; end

  sig { returns(Prism::Location) }
  def location; end
end

class Prism::Node
  sig { returns(T::Array[T.nilable(Prism::Node)]) }
  def child_nodes; end

  sig { returns(Prism::Location) }
  def location; end

  sig { returns(String) }
  def slice; end

  sig { returns(String) }
  def to_dot; end
end

class Prism::Comment
  sig { returns(Prism::Location) }
  def location; end

  sig { returns(T::Boolean) }
  def trailing?; end
end

class Prism::InlineComment < Prism::Comment
  sig { override.returns(T::Boolean) }
  def trailing?; end
end

class Prism::EmbDocComment < Prism::Comment
end

class Prism::DATAComment < Prism::Comment
end

class Prism::Location
  sig { params(source: Prism::Source, start_offset: Integer, length: Integer).void }
  def initialize(source, start_offset, length); end

  sig { returns(String) }
  def slice; end

  sig { returns(T::Array[Prism::Comment]) }
  def comments; end

  sig { params(options: T.untyped).returns(Prism::Location) }
  def copy(**options); end

  sig { returns(Integer) }
  def start_offset; end

  sig { returns(Integer) }
  def end_offset; end

  sig { returns(Integer) }
  def start_line; end

  sig { returns(Integer) }
  def end_line; end

  sig { returns(Integer) }
  def start_column; end

  sig { returns(Integer) }
  def end_column; end
end

class Prism::Source
  sig { params(source: String, start_line: Integer, offsets: T::Array[Integer]).void }
  def initialize(source, start_line, offsets); end

  sig { params(offset: Integer, length: Integer).returns(String) }
  def slice(offset, length); end

  sig { params(value: Integer).returns(Integer) }
  def line(value); end

  sig { params(value: Integer).returns(Integer) }
  def line_offset(value); end

  sig { params(value: Integer).returns(Integer) }
  def column(value); end

  sig { returns(String) }
  def source; end

  sig { returns(T::Array[Integer]) }
  def offsets; end
end

class Prism::Token
  sig { params(type: T.untyped, value: String, location: Prism::Location).void }
  def initialize(type, value, location); end

  sig { params(keys: T.untyped).returns(T.untyped) }
  def deconstruct_keys(keys); end

  sig { params(q: T.untyped).returns(T.untyped) }
  def pretty_print(q); end

  sig { params(other: T.untyped).returns(T::Boolean) }
  def ==(other); end

  sig { returns(T.untyped) }
  def type; end

  sig { returns(String) }
  def value; end

  sig { returns(Prism::Location) }
  def location; end
end

class Prism::NodeInspector
  sig { params(prefix: String).void }
  def initialize(prefix); end

  sig { returns(String) }
  def prefix; end

  sig { returns(String) }
  def output; end

  # Appends a line to the output with the current prefix.
  sig { params(line: String).void }
  def <<(line); end

  # This generates a string that is used as the header of the inspect output
  # for any given node.
  sig { params(node: Prism::Node).returns(String) }
  def header(node); end

  # Generates a string that represents a list of nodes. It handles properly
  # using the box drawing characters to make the output look nice.
  sig { params(prefix: String, nodes: T::Array[Prism::Node]).returns(String) }
  def list(prefix, nodes); end

  # Generates a string that represents a location field on a node.
  sig { params(value: Prism::Location).returns(String) }
  def location(value); end

  # Generates a string that represents a child node.
  sig { params(node: Prism::Node, append: String).returns(String) }
  def child_node(node, append); end

  # Returns a new inspector that can be used to inspect a child node.
  sig { params(append: String).returns(Prism::NodeInspector) }
  def child_inspector(append); end

  # Returns the output as a string.
  sig { returns(String) }
  def to_str; end
end

class Prism::BasicVisitor
  sig { params(node: T.nilable(Prism::Node)).void }
  def visit(node); end

  sig { params(nodes: T::Array[T.nilable(Prism::Node)]).void }
  def visit_all(nodes); end

  sig { params(node: Prism::Node).void }
  def visit_child_nodes(node); end
end
