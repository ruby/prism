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
    sig { params(opening: ::T.nilable(String)).returns(::T.nilable(T::Boolean)) }
    def self.heredoc?(opening); end
  end

  class InterpolatedStringNode < Node
    # Returns true if this node was represented as a heredoc in the source code.
    sig { returns(::T.nilable(T::Boolean)) }
    def heredoc?; end
  end

  class InterpolatedXStringNode < Node
    # Returns true if this node was represented as a heredoc in the source code.
    sig { returns(::T.nilable(T::Boolean)) }
    def heredoc?; end
  end

  class StringNode < Node
    # Returns true if this node was represented as a heredoc in the source code.
    sig { returns(::T.nilable(T::Boolean)) }
    def heredoc?; end

    # Occasionally it's helpful to treat a string as if it were interpolated so
    # that there's a consistent interface for working with strings.
    sig { returns(InterpolatedStringNode) }
    def to_interpolated; end
  end

  class XStringNode < Node
    # Returns true if this node was represented as a heredoc in the source code.
    sig { returns(::T.nilable(T::Boolean)) }
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

    # An error class raised when error recovery nodes are found while computing a
    # constant path's full name. For example:
    # Foo:: -> raises because the constant path is missing the last part
    class ErrorRecoveryNodesInConstantPathError < StandardError; end

    # Returns the list of parts for the full name of this constant path.
    # For example: [:Foo, :Bar]
    sig { returns(T::Array[Symbol]) }
    def full_name_parts; end

    # Returns the full name of this constant path. For example: "Foo::Bar"
    sig { returns(String) }
    def full_name; end
  end

  class ConstantPathTargetNode < Node
    # Returns the list of parts for the full name of this constant path.
    # For example: [:Foo, :Bar]
    sig { returns(T::Array[Symbol]) }
    def full_name_parts; end

    # Returns the full name of this constant path. For example: "Foo::Bar"
    sig { returns(String) }
    def full_name; end
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
    sig { returns(T::Array[::T.any([Symbol, Symbol], [Symbol])]) }
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
    sig { returns(::T.nilable(Location)) }
    def full_message_loc; end
  end

  class InNode < Node
    sig { returns(String) }
    def in; end

    sig { returns(Location) }
    def in_loc; end

    sig { returns(::T.nilable(String)) }
    def then; end

    sig { returns(::T.nilable(Location)) }
    def then_loc; end
  end

  class MatchPredicateNode < Node
    sig { returns(String) }
    def operator; end

    sig { returns(Location) }
    def operator_loc; end
  end

  class UnlessNode < Node
    sig { returns(String) }
    def keyword; end

    sig { returns(Location) }
    def keyword_loc; end
  end

  class UntilNode < Node
    sig { returns(String) }
    def keyword; end

    sig { returns(Location) }
    def keyword_loc; end

    sig { returns(::T.nilable(String)) }
    def closing; end

    sig { returns(::T.nilable(Location)) }
    def closing_loc; end
  end

  class WhenNode < Node
    sig { returns(String) }
    def keyword; end

    sig { returns(Location) }
    def keyword_loc; end
  end

  class WhileNode < Node
    sig { returns(String) }
    def keyword; end

    sig { returns(Location) }
    def keyword_loc; end

    sig { returns(::T.nilable(String)) }
    def closing; end

    sig { returns(::T.nilable(Location)) }
    def closing_loc; end
  end
end
