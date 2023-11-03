# typed: true

module Prism
  class ParseResult
    sig { returns(ProgramNode) }
    def value; end

    sig { returns(T::Array[Comment]) }
    def comments; end

    sig { returns(T::Array[ParseError]) }
    def errors; end

    sig { returns(T::Array[ParseWarning]) }
    def warnings; end

    sig { returns(Source) }
    def source; end
  end

  class ParseError
    sig { returns(String) }
    def message; end

    sig { returns(Location) }
    def location; end
  end

  class ParseWarning
    sig { returns(String) }
    def message; end

    sig { returns(Location) }
    def location; end
  end

  class Node
    sig { returns(T::Array[T.nilable(Node)]) }
    def child_nodes; end

    sig { returns(Location) }
    def location; end

    sig { returns(String) }
    def slice; end
  end

  class Comment
    sig { returns(Location) }
    def location; end

    sig { returns(T::Boolean) }
    def trailing?; end
  end

  class InlineComment < Comment
    sig { override.returns(T::Boolean) }
    def trailing?; end
  end

  class EmbDocComment < Comment
  end

  class DATAComment < Comment
  end

  class Location
    sig { params(source: Source, start_offset: Integer, length: Integer).void }
    def initialize(source, start_offset, length); end

    sig { returns(String) }
    def slice; end

    sig { returns(T::Array[Comment]) }
    def comments; end

    sig { params(options: T.untyped).returns(Location) }
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

  class Source
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

  class Token
    sig { params(type: T.untyped, value: String, location: Location).void }
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

    sig { returns(Location) }
    def location; end
  end

  class NodeInspector
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
    sig { params(node: Node).returns(String) }
    def header(node); end

    # Generates a string that represents a list of nodes. It handles properly
    # using the box drawing characters to make the output look nice.
    sig { params(prefix: String, nodes: T::Array[Node]).returns(String) }
    def list(prefix, nodes); end

    # Generates a string that represents a location field on a node.
    sig { params(value: Location).returns(String) }
    def location(value); end

    # Generates a string that represents a child node.
    sig { params(node: Node, append: String).returns(String) }
    def child_node(node, append); end

    # Returns a new inspector that can be used to inspect a child node.
    sig { params(append: String).returns(NodeInspector) }
    def child_inspector(append); end

    # Returns the output as a string.
    sig { returns(String) }
    def to_str; end
  end

  class BasicVisitor
    sig { params(node: T.nilable(Node)).void }
    def visit(node); end

    sig { params(nodes: T::Array[T.nilable(Node)]).void }
    def visit_all(nodes); end

    sig { params(node: Node).void }
    def visit_child_nodes(node); end
  end
end
