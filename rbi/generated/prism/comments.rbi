# typed: true

module Prism
  # The module containing definitions of all of the various comment attachment
  # objects.
  module Comments
    # The base class for all comment attachment types.
    class Base; end

    # Comments for alias method nodes, which can have comments between the
    # two arguments.
    #
    #     alias a
    #       # comment
    #       # comment
    #       b
    class AliasMethodComments < Base
      # The comments in the gap between the two arguments.
      sig { returns(T::Array[Comment]) }
      attr_reader :gap_comments

      sig { params(gap_comments: T::Array[Comment]).void }
      def initialize(gap_comments); end
    end

    # Comments for argument list nodes, which can have comments between
    # arguments.
    #
    #     foo(a,
    #       # comment
    #       b)
    class ArgumentsComments < Base
      # The comments between arguments.
      sig { returns(T::Array[Comment]) }
      attr_reader :inner_comments

      sig { params(inner_comments: T::Array[Comment]).void }
      def initialize(inner_comments); end
    end

    # Comments for binary expressions like &&. Captures a comment trailing the
    # operator and any comments in the gap between the operator and the
    # right-hand side.
    #
    #     a && # comment
    #       # comment
    #       b
    class BinaryComments < Base
      # The comment trailing the operator.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :operator_comment

      # The comments in the gap between the operator and the right-hand side.
      sig { returns(T::Array[Comment]) }
      attr_reader :gap_comments

      sig { params(operator_comment: ::T.nilable(Comment), gap_comments: T::Array[Comment]).void }
      def initialize(operator_comment, gap_comments); end
    end

    # Comments for nodes with a body delimited by a keyword and end, such as
    # begin, while, until, if, unless, and similar nodes. The opening comment
    # trails the keyword (or the last token on the opening line).
    #
    #     begin # opening comment
    #       bar
    #     end # trailing comment
    class BodyComments < Base
      # The comment trailing the opening keyword.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :opening_comment

      # The comment trailing the end keyword.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :end_comment

      # The comments within the body of the node.
      sig { returns(T::Array[Comment]) }
      attr_reader :body_comments

      sig { params(opening_comment: ::T.nilable(Comment), end_comment: ::T.nilable(Comment), body_comments: T::Array[Comment]).void }
      def initialize(opening_comment, end_comment, body_comments); end
    end

    # Comments for call nodes with a call operator (e.g., dot or &.).
    # Captures a trailing comment, gap comments between the receiver and
    # operator, the operator comment, and gap comments between the operator
    # and the message.
    #
    #     foo
    #       # receiver gap comment
    #       . # operator comment
    #       # message gap comment
    #       bar # trailing comment
    class CallComments < Base
      # The comment trailing the call.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :trailing_comment

      # The comments between the receiver and the call operator.
      sig { returns(T::Array[Comment]) }
      attr_reader :receiver_gap_comments

      # The comment trailing the call operator.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :operator_comment

      # The comments between the call operator and the message.
      sig { returns(T::Array[Comment]) }
      attr_reader :message_gap_comments

      sig { params(trailing_comment: ::T.nilable(Comment), receiver_gap_comments: T::Array[Comment], operator_comment: ::T.nilable(Comment), message_gap_comments: T::Array[Comment]).void }
      def initialize(trailing_comment, receiver_gap_comments, operator_comment, message_gap_comments); end
    end

    # Comments for call-write nodes (e.g., foo.bar = 1, foo.bar += 1) which
    # have both a call operator and an assignment operator with potential
    # comments on each.
    #
    #     foo. # call operator comment
    #       # call gap comment
    #       bar += # operator comment
    #       # operator gap comment
    #       1
    class CallWriteComments < Base
      # The comment trailing the call operator.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :call_operator_comment

      # The comments between the call operator and the message.
      sig { returns(T::Array[Comment]) }
      attr_reader :call_gap_comments

      # The comment trailing the assignment operator.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :operator_comment

      # The comments between the assignment operator and the value.
      sig { returns(T::Array[Comment]) }
      attr_reader :operator_gap_comments

      sig { params(call_operator_comment: ::T.nilable(Comment), call_gap_comments: T::Array[Comment], operator_comment: ::T.nilable(Comment), operator_gap_comments: T::Array[Comment]).void }
      def initialize(call_operator_comment, call_gap_comments, operator_comment, operator_gap_comments); end
    end

    # Comments for case/case-in nodes. Captures the comment on the case
    # keyword, comments between the keyword and predicate, comments between
    # the predicate and the first when/in clause, and the trailing comment
    # on end.
    #
    #     case # opening comment
    #       # keyword gap comment
    #       foo
    #       # predicate gap comment
    #     when bar
    #       baz
    #     end # end comment
    class CaseComments < Base
      # The comment trailing the case keyword.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :opening_comment

      # The comments between the case keyword and the predicate.
      sig { returns(T::Array[Comment]) }
      attr_reader :keyword_gap_comments

      # The comments between the predicate and the first when/in clause.
      sig { returns(T::Array[Comment]) }
      attr_reader :predicate_gap_comments

      # The comment trailing the end keyword.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :end_comment

      # The comments within the body of the node.
      sig { returns(T::Array[Comment]) }
      attr_reader :body_comments

      sig { params(opening_comment: ::T.nilable(Comment), keyword_gap_comments: T::Array[Comment], predicate_gap_comments: T::Array[Comment], end_comment: ::T.nilable(Comment), body_comments: T::Array[Comment]).void }
      def initialize(opening_comment, keyword_gap_comments, predicate_gap_comments, end_comment, body_comments); end
    end

    # Comments for class nodes, which can have comments on the class keyword,
    # in the gap between the keyword and the constant, on the inheritance
    # operator, in the gap between the operator and the superclass, and on
    # the end keyword.
    #
    #     class # opening comment
    #       # keyword gap comment
    #       Foo < # inheritance operator comment
    #       # inheritance gap comment
    #       Bar
    #       baz
    #     end # end comment
    class ClassComments < Base
      # The comment trailing the class keyword.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :opening_comment

      # The comments between the class keyword and the constant.
      sig { returns(T::Array[Comment]) }
      attr_reader :keyword_gap_comments

      # The comment trailing the inheritance operator.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :inheritance_operator_comment

      # The comments between the inheritance operator and the superclass.
      sig { returns(T::Array[Comment]) }
      attr_reader :inheritance_gap_comments

      # The comment trailing the end keyword.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :end_comment

      # The comments within the body of the node.
      sig { returns(T::Array[Comment]) }
      attr_reader :body_comments

      sig { params(opening_comment: ::T.nilable(Comment), keyword_gap_comments: T::Array[Comment], inheritance_operator_comment: ::T.nilable(Comment), inheritance_gap_comments: T::Array[Comment], end_comment: ::T.nilable(Comment), body_comments: T::Array[Comment]).void }
      def initialize(opening_comment, keyword_gap_comments, inheritance_operator_comment, inheritance_gap_comments, end_comment, body_comments); end
    end

    # Comments for clause nodes such as when, in, rescue, else, and ensure
    # that have a single opening keyword.
    #
    #     when foo # opening comment
    class ClauseComments < Base
      # The comment trailing the opening keyword.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :opening_comment

      # The comments within the body of the node.
      sig { returns(T::Array[Comment]) }
      attr_reader :body_comments

      sig { params(opening_comment: ::T.nilable(Comment), body_comments: T::Array[Comment]).void }
      def initialize(opening_comment, body_comments); end
    end

    # Comments for collection nodes with opening and closing delimiters,
    # such as arrays, hashes, block parameters, and similar nodes.
    #
    #     [ # opening comment
    #       1, 2, 3
    #     ] # closing comment
    class CollectionComments < Base
      # The comment trailing the opening delimiter.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :opening_comment

      # The comment trailing the closing delimiter.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :closing_comment

      # The comments between elements of the collection.
      sig { returns(T::Array[Comment]) }
      attr_reader :inner_comments

      sig { params(opening_comment: ::T.nilable(Comment), closing_comment: ::T.nilable(Comment), inner_comments: T::Array[Comment]).void }
      def initialize(opening_comment, closing_comment, inner_comments); end
    end

    # Comments for def nodes, which can have comments on the def keyword,
    # in the gap between the keyword and the method name, the opening and
    # closing parentheses of the parameter list, and a trailing comment on
    # end.
    #
    #     def # opening comment
    #       # keyword gap comment
    #       foo( # lparen comment
    #         a, b
    #       ) # rparen comment
    #       bar
    #     end # end comment
    class DefComments < Base
      # The comment trailing the def keyword.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :opening_comment

      # The comments between the def keyword and the method name.
      sig { returns(T::Array[Comment]) }
      attr_reader :keyword_gap_comments

      # The comment trailing the opening parenthesis.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :lparen_comment

      # The comment trailing the closing parenthesis.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :rparen_comment

      # The comment trailing the end keyword.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :end_comment

      # The comments within the body of the node.
      sig { returns(T::Array[Comment]) }
      attr_reader :body_comments

      sig { params(opening_comment: ::T.nilable(Comment), keyword_gap_comments: T::Array[Comment], lparen_comment: ::T.nilable(Comment), rparen_comment: ::T.nilable(Comment), end_comment: ::T.nilable(Comment), body_comments: T::Array[Comment]).void }
      def initialize(opening_comment, keyword_gap_comments, lparen_comment, rparen_comment, end_comment, body_comments); end
    end

    # Comments for embedded statements nodes (e.g., string interpolation).
    #
    #     "foo #{ # opening comment
    #       bar
    #     }"
    class EmbeddedStatementsComments < Base
      # The comment trailing the opening delimiter.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :opening_comment

      # The comments within the body of the node.
      sig { returns(T::Array[Comment]) }
      attr_reader :body_comments

      sig { params(opening_comment: ::T.nilable(Comment), body_comments: T::Array[Comment]).void }
      def initialize(opening_comment, body_comments); end
    end

    # Comments for endless def nodes (def foo = body), which can have
    # comments on the def keyword, in the gap between the keyword and the
    # method name, the parentheses, and the = operator.
    #
    #     def # opening comment
    #       # keyword gap comment
    #       foo( # lparen comment
    #         a
    #       ) = # operator comment
    #       bar
    class EndlessDefComments < Base
      # The comment trailing the def keyword.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :opening_comment

      # The comments between the def keyword and the method name.
      sig { returns(T::Array[Comment]) }
      attr_reader :keyword_gap_comments

      # The comment trailing the opening parenthesis.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :lparen_comment

      # The comment trailing the closing parenthesis.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :rparen_comment

      # The comment trailing the = operator.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :operator_comment

      sig { params(opening_comment: ::T.nilable(Comment), keyword_gap_comments: T::Array[Comment], lparen_comment: ::T.nilable(Comment), rparen_comment: ::T.nilable(Comment), operator_comment: ::T.nilable(Comment)).void }
      def initialize(opening_comment, keyword_gap_comments, lparen_comment, rparen_comment, operator_comment); end
    end

    # Comments for find pattern nodes (e.g., [*a, b, *c] in pattern matching),
    # which have opening and closing delimiters and gap comments around the
    # left and right splat operators.
    #
    #     in [ # opening comment
    #       # pre left gap comment
    #       *a, b,
    #       # post right gap comment
    #     ] # closing comment
    class FindPatternComments < Base
      # The comment trailing the opening delimiter.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :opening_comment

      # The comment trailing the closing delimiter.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :closing_comment

      # The comments before the left splat operator.
      sig { returns(T::Array[Comment]) }
      attr_reader :pre_left_gap_comments

      # The comments after the right splat operator.
      sig { returns(T::Array[Comment]) }
      attr_reader :post_right_gap_comments

      # The comments between elements of the pattern.
      sig { returns(T::Array[Comment]) }
      attr_reader :inner_comments

      sig { params(opening_comment: ::T.nilable(Comment), closing_comment: ::T.nilable(Comment), pre_left_gap_comments: T::Array[Comment], post_right_gap_comments: T::Array[Comment], inner_comments: T::Array[Comment]).void }
      def initialize(opening_comment, closing_comment, pre_left_gap_comments, post_right_gap_comments, inner_comments); end
    end

    # Comments for for loop nodes, which have for, in, and optionally do
    # keywords, each of which may have a trailing comment.
    #
    #     for a in # in comment
    #       b
    #     do # do comment
    #       c
    #     end # end comment
    class ForComments < Base
      # The comment trailing the for keyword.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :for_comment

      # The comment trailing the in keyword.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :in_comment

      # The comment trailing the do keyword.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :do_comment

      # The comment trailing the end keyword.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :end_comment

      # The comments within the body of the node.
      sig { returns(T::Array[Comment]) }
      attr_reader :body_comments

      sig { params(for_comment: ::T.nilable(Comment), in_comment: ::T.nilable(Comment), do_comment: ::T.nilable(Comment), end_comment: ::T.nilable(Comment), body_comments: T::Array[Comment]).void }
      def initialize(for_comment, in_comment, do_comment, end_comment, body_comments); end
    end

    # Comments for hash pattern nodes (e.g., { a:, **b } in pattern matching),
    # which have opening and closing delimiters and gap comments after the
    # rest operator.
    #
    #     in { a:, **b,
    #       # post rest gap comment
    #     } # closing comment
    class HashPatternComments < Base
      # The comment trailing the opening delimiter.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :opening_comment

      # The comment trailing the closing delimiter.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :closing_comment

      # The comments after the rest operator.
      sig { returns(T::Array[Comment]) }
      attr_reader :post_rest_gap_comments

      # The comments between elements of the pattern.
      sig { returns(T::Array[Comment]) }
      attr_reader :inner_comments

      sig { params(opening_comment: ::T.nilable(Comment), closing_comment: ::T.nilable(Comment), post_rest_gap_comments: T::Array[Comment], inner_comments: T::Array[Comment]).void }
      def initialize(opening_comment, closing_comment, post_rest_gap_comments, inner_comments); end
    end

    # Comments for keyword call nodes with parentheses, such as yield and
    # super.
    #
    #     yield( # lparen comment
    #       foo
    #     ) # rparen comment
    class KeywordCallComments < Base
      # The comment trailing the opening parenthesis.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :lparen_comment

      # The comment trailing the closing parenthesis.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :rparen_comment

      sig { params(lparen_comment: ::T.nilable(Comment), rparen_comment: ::T.nilable(Comment)).void }
      def initialize(lparen_comment, rparen_comment); end
    end

    # Comments for keyword hash nodes (implicit hashes in argument lists),
    # which can have comments between elements.
    #
    #     foo(a: 1,
    #       # comment
    #       b: 2)
    class KeywordHashComments < Base
      # The comments between elements of the keyword hash.
      sig { returns(T::Array[Comment]) }
      attr_reader :inner_comments

      sig { params(inner_comments: T::Array[Comment]).void }
      def initialize(inner_comments); end
    end

    # Comments for leaf nodes that can only have a trailing comment on the
    # same line (e.g., variable reads, literals, break/next/return keywords).
    #
    #     foo # trailing comment
    class LeafComments < Base
      # The comment trailing the node.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :trailing_comment

      sig { params(trailing_comment: ::T.nilable(Comment)).void }
      def initialize(trailing_comment); end
    end

    # Comments for logical keyword operators (and, or) which have comments
    # in the gaps before and after the keyword operator.
    #
    #     a
    #     # left gap comment
    #     and # operator comment
    #     # right gap comment
    #     b
    class LogicalKeywordComments < Base
      # The comment trailing the operator keyword.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :operator_comment

      # The comments between the left operand and the operator.
      sig { returns(T::Array[Comment]) }
      attr_reader :left_gap_comments

      # The comments between the operator and the right operand.
      sig { returns(T::Array[Comment]) }
      attr_reader :right_gap_comments

      sig { params(operator_comment: ::T.nilable(Comment), left_gap_comments: T::Array[Comment], right_gap_comments: T::Array[Comment]).void }
      def initialize(operator_comment, left_gap_comments, right_gap_comments); end
    end

    # Comments for module nodes, which can have comments on the module keyword,
    # in the gap between the keyword and the constant, and on the end keyword.
    #
    #     module # opening comment
    #       # keyword gap comment
    #       Foo
    #       bar
    #     end # end comment
    class ModuleComments < Base
      # The comment trailing the module keyword.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :opening_comment

      # The comments between the module keyword and the constant.
      sig { returns(T::Array[Comment]) }
      attr_reader :keyword_gap_comments

      # The comment trailing the end keyword.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :end_comment

      # The comments within the body of the node.
      sig { returns(T::Array[Comment]) }
      attr_reader :body_comments

      sig { params(opening_comment: ::T.nilable(Comment), keyword_gap_comments: T::Array[Comment], end_comment: ::T.nilable(Comment), body_comments: T::Array[Comment]).void }
      def initialize(opening_comment, keyword_gap_comments, end_comment, body_comments); end
    end

    # Comments for parameter list nodes, which can have comments between
    # parameters.
    #
    #     def foo(a,
    #       # comment
    #       b)
    #     end
    class ParametersComments < Base
      # The comments between parameters.
      sig { returns(T::Array[Comment]) }
      attr_reader :inner_comments

      sig { params(inner_comments: T::Array[Comment]).void }
      def initialize(inner_comments); end
    end

    # Comments for nodes wrapped in parentheses, such as parenthesized
    # expressions or ternary if/unless with parenthesized predicates.
    #
    #     ( # opening comment
    #       # opening gap comment
    #       foo
    #       # closing gap comment
    #     )
    class ParenthesizedComments < Base
      # The comment trailing the opening parenthesis.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :opening_comment

      # The comments between the opening parenthesis and the body.
      sig { returns(T::Array[Comment]) }
      attr_reader :opening_gap_comments

      # The comments between the body and the closing parenthesis.
      sig { returns(T::Array[Comment]) }
      attr_reader :closing_gap_comments

      # The comments within the body of the node.
      sig { returns(T::Array[Comment]) }
      attr_reader :body_comments

      sig { params(opening_comment: ::T.nilable(Comment), opening_gap_comments: T::Array[Comment], closing_gap_comments: T::Array[Comment], body_comments: T::Array[Comment]).void }
      def initialize(opening_comment, opening_gap_comments, closing_gap_comments, body_comments); end
    end

    # Comments for prefix operator nodes (e.g., !, ~, not, splat, block
    # argument) where a comment can trail the operator and gap comments can
    # appear before the operand.
    #
    #     ! # operator comment
    #       # gap comment
    #       foo
    class PrefixComments < Base
      # The comment trailing the operator.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :operator_comment

      # The comments between the operator and the operand.
      sig { returns(T::Array[Comment]) }
      attr_reader :gap_comments

      sig { params(operator_comment: ::T.nilable(Comment), gap_comments: T::Array[Comment]).void }
      def initialize(operator_comment, gap_comments); end
    end

    # Comments for undef nodes, which can have a comment trailing the keyword
    # and comments between the names.
    #
    #     undef # keyword comment
    #       foo,
    #       # comment
    #       bar
    class UndefComments < Base
      # The comment trailing the undef keyword.
      sig { returns(::T.nilable(Comment)) }
      attr_reader :keyword_comment

      # The comments between the names.
      sig { returns(T::Array[Comment]) }
      attr_reader :inner_comments

      sig { params(keyword_comment: ::T.nilable(Comment), inner_comments: T::Array[Comment]).void }
      def initialize(keyword_comment, inner_comments); end
    end
  end
end
