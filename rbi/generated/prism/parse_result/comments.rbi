# typed: true

module Prism
  class ParseResult < Result
    # When we've parsed the source, we have both the syntax tree and the list of
    # comments that we found in the source. This class is responsible for
    # walking the tree and finding the nearest location to attach each comment.
    #
    # It does this by first finding the nearest locations to each comment.
    # Locations can either come from nodes directly or from location fields on
    # nodes. For example, a `ClassNode` has an overall location encompassing the
    # entire class, but it also has a location for the `class` keyword.
    #
    # Once the nearest locations are found, it determines which one to attach
    # to. If it's a trailing comment (a comment on the same line as other source
    # code), it will favor attaching to the nearest location that occurs before
    # the comment. Otherwise it will favor attaching to the nearest location
    # that is after the comment.
    class Comments
      # A target for attaching comments that is based on a specific node's
      # location.
      class NodeTarget
        sig { returns(Node) }
        attr_reader :node

        sig { params(node: Node).void }
        def initialize(node); end

        sig { returns(Integer) }
        def start_offset; end

        sig { returns(Integer) }
        def end_offset; end

        sig { params(comment: Comment).returns(T::Boolean) }
        def encloses?(comment); end

        sig { params(comment: Comment).void }
        def leading_comment(comment); end

        sig { params(comment: Comment).void }
        def trailing_comment(comment); end
      end

      # A target for attaching comments that is based on a location field on a
      # node. For example, the `end` token of a ClassNode.
      class LocationTarget
        sig { returns(Location) }
        attr_reader :location

        sig { params(location: Location).void }
        def initialize(location); end

        sig { returns(Integer) }
        def start_offset; end

        sig { returns(Integer) }
        def end_offset; end

        sig { params(comment: Comment).returns(T::Boolean) }
        def encloses?(comment); end

        sig { params(comment: Comment).void }
        def leading_comment(comment); end

        sig { params(comment: Comment).void }
        def trailing_comment(comment); end
      end

      # The parse result that we are attaching comments to.
      sig { returns(ParseResult) }
      attr_reader :parse_result

      # Create a new Comments object that will attach comments to the given
      # parse result.
      sig { params(parse_result: ParseResult).void }
      def initialize(parse_result); end

      # Attach the comments to their respective locations in the tree by
      # mutating the parse result.
      sig { void }
      def attach!; end

      # Responsible for finding the nearest targets to the given comment within
      # the context of the given encapsulating node.
      sig { params(node: Node, comment: Comment).returns([T.untyped, T.untyped, T.untyped]) }
      private def nearest_targets(node, comment); end
    end
  end
end
