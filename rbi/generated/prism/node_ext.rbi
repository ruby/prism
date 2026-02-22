# typed: true

module Prism
  class Node
    abstract!

    sig { params(replacements: String).void }
    def deprecated(*replacements); end
  end

  module RegularExpressionOptions
    # Returns a numeric value that represents the flags that were used to create
    # the regular expression.
    sig { params(flags: Integer).returns(Integer) }
    def self.options(flags); end
  end

  class InterpolatedMatchLastLineNode < Node
    # Returns a numeric value that represents the flags that were used to create
    # the regular expression.
    sig { returns(Integer) }
    def options; end
  end

  class InterpolatedRegularExpressionNode < Node
    # Returns a numeric value that represents the flags that were used to create
    # the regular expression.
    sig { returns(Integer) }
    def options; end
  end

  class MatchLastLineNode < Node
    # Returns a numeric value that represents the flags that were used to create
    # the regular expression.
    sig { returns(Integer) }
    def options; end
  end

  class RegularExpressionNode < Node
    # Returns a numeric value that represents the flags that were used to create
    # the regular expression.
    sig { returns(Integer) }
    def options; end
  end

  module HeredocQuery
    # Returns true if this node was represented as a heredoc in the source code.
    sig { params(opening: T.nilable(String)).returns(T.nilable(T::Boolean)) }
    def self.heredoc?(opening); end
  end

  class InterpolatedStringNode < Node
    # Returns true if this node was represented as a heredoc in the source code.
    sig { returns(T.nilable(T::Boolean)) }
    def heredoc?; end
  end

  class InterpolatedXStringNode < Node
    # Returns true if this node was represented as a heredoc in the source code.
    sig { returns(T.nilable(T::Boolean)) }
    def heredoc?; end
  end

  class StringNode < Node
    # Returns true if this node was represented as a heredoc in the source code.
    sig { returns(T.nilable(T::Boolean)) }
    def heredoc?; end

    # Occasionally it's helpful to treat a string as if it were interpolated so
    # that there's a consistent interface for working with strings.
    sig { returns(InterpolatedStringNode) }
    def to_interpolated; end
  end

  class XStringNode < Node
    # Returns true if this node was represented as a heredoc in the source code.
    sig { returns(T.nilable(T::Boolean)) }
    def heredoc?; end

    # Occasionally it's helpful to treat a string as if it were interpolated so
    # that there's a consistent interface for working with strings.
    sig { returns(InterpolatedXStringNode) }
    def to_interpolated; end
  end

  class ImaginaryNode < Node
    # Returns the value of the node as a Ruby Complex.
    sig { returns(Complex) }
    def value; end
  end

  class RationalNode < Node
    # Returns the value of the node as a Ruby Rational.
    sig { returns(Rational) }
    def value; end

    # Returns the value of the node as an IntegerNode or a FloatNode. This
    # method is deprecated in favor of #value or #numerator/#denominator.
    sig { returns(T.any(IntegerNode, FloatNode)) }
    def numeric; end
  end

  class ConstantReadNode < Node
    # Returns the list of parts for the full name of this constant.
    # For example: [:Foo]
    sig { returns(T::Array[Symbol]) }
    def full_name_parts; end

    # Returns the full name of this constant. For example: "Foo"
    sig { returns(String) }
    def full_name; end
  end

  class ConstantWriteNode < Node
    # Returns the list of parts for the full name of this constant.
    # For example: [:Foo]
    sig { returns(T::Array[Symbol]) }
    def full_name_parts; end

    # Returns the full name of this constant. For example: "Foo"
    sig { returns(String) }
    def full_name; end
  end

  class ConstantPathNode < Node
    # An error class raised when dynamic parts are found while computing a
    # constant path's full name. For example:
    # Foo::Bar::Baz -> does not raise because all parts of the constant path are
    # simple constants
    # var::Bar::Baz -> raises because the first part of the constant path is a
    # local variable
    class DynamicPartsInConstantPathError < StandardError; end

    # An error class raised when missing nodes are found while computing a
    # constant path's full name. For example:
    # Foo:: -> raises because the constant path is missing the last part
    class MissingNodesInConstantPathError < StandardError; end

    # Returns the list of parts for the full name of this constant path.
    # For example: [:Foo, :Bar]
    sig { returns(T::Array[Symbol]) }
    def full_name_parts; end

    # Returns the full name of this constant path. For example: "Foo::Bar"
    sig { returns(String) }
    def full_name; end

    # Previously, we had a child node on this class that contained either a
    # constant read or a missing node. To not cause a breaking change, we
    # continue to supply that API.
    sig { returns(T.any(ConstantReadNode, MissingNode)) }
    def child; end
  end

  class ConstantPathTargetNode < Node
    # Returns the list of parts for the full name of this constant path.
    # For example: [:Foo, :Bar]
    sig { returns(T::Array[Symbol]) }
    def full_name_parts; end

    # Returns the full name of this constant path. For example: "Foo::Bar"
    sig { returns(String) }
    def full_name; end

    # Previously, we had a child node on this class that contained either a
    # constant read or a missing node. To not cause a breaking change, we
    # continue to supply that API.
    sig { returns(T.any(ConstantReadNode, MissingNode)) }
    def child; end
  end

  class ConstantTargetNode < Node
    # Returns the list of parts for the full name of this constant.
    # For example: [:Foo]
    sig { returns(T::Array[Symbol]) }
    def full_name_parts; end

    # Returns the full name of this constant. For example: "Foo"
    sig { returns(String) }
    def full_name; end
  end

  class ParametersNode < Node
    # Mirrors the Method#parameters method.
    sig { returns(T::Array[T.any([Symbol, Symbol], [Symbol])]) }
    def signature; end
  end

  class CallNode < Node
    # When a call node has the attribute_write flag set, it means that the call
    # is using the attribute write syntax. This is either a method call to []=
    # or a method call to a method that ends with =. Either way, the = sign is
    # present in the source.
    #
    # Prism returns the message_loc _without_ the = sign attached, because there
    # can be any amount of space between the message and the = sign. However,
    # sometimes you want the location of the full message including the inner
    # space and the = sign. This method provides that.
    sig { returns(T.nilable(Location)) }
    def full_message_loc; end
  end

  class CallOperatorWriteNode < Node
    # Returns the binary operator used to modify the receiver. This method is
    # deprecated in favor of #binary_operator.
    sig { returns(Symbol) }
    def operator; end

    # Returns the location of the binary operator used to modify the receiver.
    # This method is deprecated in favor of #binary_operator_loc.
    sig { returns(Location) }
    def operator_loc; end
  end

  class ClassVariableOperatorWriteNode < Node
    # Returns the binary operator used to modify the receiver. This method is
    # deprecated in favor of #binary_operator.
    sig { returns(Symbol) }
    def operator; end

    # Returns the location of the binary operator used to modify the receiver.
    # This method is deprecated in favor of #binary_operator_loc.
    sig { returns(Location) }
    def operator_loc; end
  end

  class ConstantOperatorWriteNode < Node
    # Returns the binary operator used to modify the receiver. This method is
    # deprecated in favor of #binary_operator.
    sig { returns(Symbol) }
    def operator; end

    # Returns the location of the binary operator used to modify the receiver.
    # This method is deprecated in favor of #binary_operator_loc.
    sig { returns(Location) }
    def operator_loc; end
  end

  class ConstantPathOperatorWriteNode < Node
    # Returns the binary operator used to modify the receiver. This method is
    # deprecated in favor of #binary_operator.
    sig { returns(Symbol) }
    def operator; end

    # Returns the location of the binary operator used to modify the receiver.
    # This method is deprecated in favor of #binary_operator_loc.
    sig { returns(Location) }
    def operator_loc; end
  end

  class GlobalVariableOperatorWriteNode < Node
    # Returns the binary operator used to modify the receiver. This method is
    # deprecated in favor of #binary_operator.
    sig { returns(Symbol) }
    def operator; end

    # Returns the location of the binary operator used to modify the receiver.
    # This method is deprecated in favor of #binary_operator_loc.
    sig { returns(Location) }
    def operator_loc; end
  end

  class IndexOperatorWriteNode < Node
    # Returns the binary operator used to modify the receiver. This method is
    # deprecated in favor of #binary_operator.
    sig { returns(Symbol) }
    def operator; end

    # Returns the location of the binary operator used to modify the receiver.
    # This method is deprecated in favor of #binary_operator_loc.
    sig { returns(Location) }
    def operator_loc; end
  end

  class InstanceVariableOperatorWriteNode < Node
    # Returns the binary operator used to modify the receiver. This method is
    # deprecated in favor of #binary_operator.
    sig { returns(Symbol) }
    def operator; end

    # Returns the location of the binary operator used to modify the receiver.
    # This method is deprecated in favor of #binary_operator_loc.
    sig { returns(Location) }
    def operator_loc; end
  end

  class LocalVariableOperatorWriteNode < Node
    # Returns the binary operator used to modify the receiver. This method is
    # deprecated in favor of #binary_operator.
    sig { returns(Symbol) }
    def operator; end

    # Returns the location of the binary operator used to modify the receiver.
    # This method is deprecated in favor of #binary_operator_loc.
    sig { returns(Location) }
    def operator_loc; end
  end

  class CaseMatchNode < Node
    # Returns the else clause of the case match node. This method is deprecated
    # in favor of #else_clause.
    sig { returns(T.nilable(ElseNode)) }
    def consequent; end
  end

  class CaseNode < Node
    # Returns the else clause of the case node. This method is deprecated in
    # favor of #else_clause.
    sig { returns(T.nilable(ElseNode)) }
    def consequent; end
  end

  class IfNode < Node
    # Returns the subsequent if/elsif/else clause of the if node. This method is
    # deprecated in favor of #subsequent.
    sig { returns(T.nilable(T.any(IfNode, ElseNode))) }
    def consequent; end
  end

  class RescueNode < Node
    # Returns the subsequent rescue clause of the rescue node. This method is
    # deprecated in favor of #subsequent.
    sig { returns(T.nilable(RescueNode)) }
    def consequent; end
  end

  class UnlessNode < Node
    # Returns the else clause of the unless node. This method is deprecated in
    # favor of #else_clause.
    sig { returns(T.nilable(ElseNode)) }
    def consequent; end
  end
end
