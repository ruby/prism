# This script finds all of the comments within a given source file for a method.

require "prism"

class FindMethodComments < Prism::Visitor
  def initialize(target, comments, nesting = [], candidates = [])
    @target = target
    @comments = comments
    @nesting = nesting
    @candidates = candidates
  end

  # These visit methods are specific to each class. Defining a visitor allows
  # you to group functionality that applies to all node types into a single
  # class. You can find which method corresponds to which node type by looking
  # at the class name, calling #type on the node, or by looking at the #accept
  # method definition on the node.
  def visit_module_node(node)
    visitor = FindMethodComments.new(@target, @comments, [*@nesting, node.name])
    node.each_child_node { |child| child.accept(visitor) }
  end

  def visit_class_node(node)
    # We could keep track of an internal state where we push the class name here
    # and then pop it after the visit is complete. However, it is often simpler
    # and cleaner to generate a new visitor instance when the state changes,
    # because then the state is immutable and it's easier to reason about. This
    # also provides for more debugging opportunity in the initializer.
    visitor = FindMethodComments.new(@target, @comments, [*@nesting, node.name])
    node.each_child_node { |child| child.accept(visitor) }
  end

  def visit_statements_node(node)
    visitor = FindMethodComments.new(@target, @comments, @nesting, node.comments)
    node.each_child_node { |child| child.accept(visitor) }
  end

  def visit_def_node(node)
    if [*@nesting, node.name] == @target
      # Each comment is attached to a single node. A comment on its own line
      # within a body is attached to the statements of that body, so
      # documentation above a method is attached to the statements around the
      # method rather than to the method itself. We kept the comments attached
      # to those statements as we descended, which are ordered by where they
      # start, so here we walk back from the method and take the ones on the
      # lines directly above it.
      expected_line = node.location.start_line - 1

      @candidates.reverse_each do |comment|
        next if comment.location.start_offset > node.location.start_offset
        break if comment.location.start_line != expected_line

        @comments.unshift(comment)
        expected_line -= 1
      end
    else
      super
    end
  end
end

# Most of the time, the concept of "finding" something in the AST can be
# accomplished either with a queue or with a visitor. In this case we will use a
# visitor, but a queue would work just as well.
def find_comments(result, path)
  target = path.split(/::|#/).map(&:to_sym)
  comments = []

  result.value.accept(FindMethodComments.new(target, comments))
  comments
end

# Comments are only attached to nodes when the attach_comments option is set.
result = Prism.parse_stream(DATA, attach_comments: true)

find_comments(result, "Foo#foo").each do |comment|
  puts comment.inspect
  puts comment.slice
end

# =>
# #<Prism::InlineComment @location=#<Prism::Location @start_offset=205 @length=27 start_line=13>>
# # This is the documentation
# #<Prism::InlineComment @location=#<Prism::Location @start_offset=235 @length=21 start_line=14>>
# # for the foo method.

find_comments(result, "Foo::Bar#bar").each do |comment|
  puts comment.inspect
  puts comment.slice
end

# =>
# #<Prism::InlineComment @location=#<Prism::Location @start_offset=126 @length=23 start_line=7>>
# # This is documentation
# #<Prism::InlineComment @location=#<Prism::Location @start_offset=154 @length=21 start_line=8>>
# # for the bar method.

__END__
# This is the documentation
# for the Foo module.
module Foo
  # This is documentation
  # for the Bar class.
  class Bar
    # This is documentation
    # for the bar method.
    def bar
    end
  end

  # This is the documentation
  # for the foo method.
  def foo
  end
end
