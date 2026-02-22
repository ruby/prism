# typed: true

module Prism
  class ParseResult < Result
    # The :line tracepoint event gets fired whenever the Ruby VM encounters an
    # expression on a new line. The types of expressions that can trigger this
    # event are:
    #
    # * if statements
    # * unless statements
    # * nodes that are children of statements lists
    #
    # In order to keep track of the newlines, we have a list of offsets that
    # come back from the parser. We assign these offsets to the first nodes that
    # we find in the tree that are on those lines.
    #
    # Note that the logic in this file should be kept in sync with the Java
    # MarkNewlinesVisitor, since that visitor is responsible for marking the
    # newlines for JRuby/TruffleRuby.
    #
    # This file is autoloaded only when `mark_newlines!` is called, so the
    # re-opening of the various nodes in this file will only be performed in
    # that case. We do that to avoid storing the extra `@newline` instance
    # variable on every node if we don't need it.
    class Newlines < Visitor
      # Create a new Newlines visitor with the given newline offsets.
      sig { params(lines: Integer).void }
      def initialize(lines); end

      # Permit block nodes to mark newlines within themselves.
      sig { params(node: BlockNode).void }
      def visit_block_node(node); end

      # Permit lambda nodes to mark newlines within themselves.
      sig { params(node: LambdaNode).void }
      def visit_lambda_node(node); end

      # Mark if nodes as newlines.
      sig { params(node: IfNode).void }
      def visit_if_node(node); end

      # Mark unless nodes as newlines.
      sig { params(node: UnlessNode).void }
      def visit_unless_node(node); end

      # Permit statements lists to mark newlines within themselves.
      sig { params(node: StatementsNode).void }
      def visit_statements_node(node); end
    end
  end

  class Node
    abstract!

    sig { returns(T::Boolean) }
    def newline_flag?; end

    sig { params(lines: T::Array[T::Boolean]).void }
    def newline_flag!(lines); end
  end

  class BeginNode < Node
    sig { params(lines: T::Array[T::Boolean]).void }
    def newline_flag!(lines); end
  end

  class ParenthesesNode < Node
    sig { params(lines: T::Array[T::Boolean]).void }
    def newline_flag!(lines); end
  end

  class IfNode < Node
    sig { params(lines: T::Array[T::Boolean]).void }
    def newline_flag!(lines); end
  end

  class UnlessNode < Node
    sig { params(lines: T::Array[T::Boolean]).void }
    def newline_flag!(lines); end
  end

  class UntilNode < Node
    sig { params(lines: T::Array[T::Boolean]).void }
    def newline_flag!(lines); end
  end

  class WhileNode < Node
    sig { params(lines: T::Array[T::Boolean]).void }
    def newline_flag!(lines); end
  end

  class RescueModifierNode < Node
    sig { params(lines: T::Array[T::Boolean]).void }
    def newline_flag!(lines); end
  end

  class InterpolatedMatchLastLineNode < Node
    sig { params(lines: T::Array[T::Boolean]).void }
    def newline_flag!(lines); end
  end

  class InterpolatedRegularExpressionNode < Node
    sig { params(lines: T::Array[T::Boolean]).void }
    def newline_flag!(lines); end
  end

  class InterpolatedStringNode < Node
    sig { params(lines: T::Array[T::Boolean]).void }
    def newline_flag!(lines); end
  end

  class InterpolatedSymbolNode < Node
    sig { params(lines: T::Array[T::Boolean]).void }
    def newline_flag!(lines); end
  end

  class InterpolatedXStringNode < Node
    sig { params(lines: T::Array[T::Boolean]).void }
    def newline_flag!(lines); end
  end
end
