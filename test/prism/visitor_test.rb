# frozen_string_literal: true

require_relative "test_helper"

module Prism
  class VisitorTest < TestCase
    def test_visitor_visit_method_called_for_every_node
      visited = []
      visitor = Class.new(Visitor) {
        define_method :visit do |node|
          visited << node
          super(node)
        end
      }.new
      tree = Prism.parse("1 + 2").value

      all_nodes = []
      collect_all_children = -> node {
        all_nodes << node
        node.compact_child_nodes.each { |child| collect_all_children.call(child) }
      }
      collect_all_children.call(tree)

      visitor.visit(tree)
      assert_equal all_nodes.map(&:class), visited.map(&:class)
      assert_equal_nodes all_nodes, visited
    end
  end
end
