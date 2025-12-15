# frozen_string_literal: true
# typed: ignore

require_relative "../test_helper"

# Needs Prism.parse_file(file, version: "current")
return if RUBY_VERSION < "3.3"

require_relative 'inline_method'

module Prism
  class NodeForTest < TestCase
    INDENT = ' ' * 4

    def m(foo)
      42
    end
    M_LOCATION = [__LINE__-3, 4, __LINE__-1, 7]

    def été; 42; end
    UTF8_LOCATION = [__LINE__-1, 4, __LINE__-1, 22]

    define_method(:define_method_method) { 42 }
    DEFINE_METHOD_LOCATION = [__LINE__-1, 41, __LINE__-1, 47]

    def return_block(&block)
      block
    end

    iter = Object.new
    def iter.each(&block)
      block.call(block)
    end

    for pr in iter
      42
    end
    FOR_BODY_PROC = pr
    FOR_BODY_PROC_LOCATION = [__LINE__-4, 4, __LINE__-2, 7]

    def with_location(callable, locs, file = __FILE__)
      source_location = [file, *locs]
      if RUBY_VERSION >= "4.1"
        assert_equal callable.source_location, source_location
      else
        callable.define_singleton_method(:source_location) { source_location }
      end
      callable
    end

    def test_def_method
      node = Prism.node_for(with_location(NodeForTest.instance_method(:m), M_LOCATION))
      assert_instance_of(Prism::DefNode, node)
      assert_equal "def m(foo)\n#{INDENT}  42\n#{INDENT}end", node.slice

      node = Prism.node_for(with_location(method(:m), M_LOCATION))
      assert_instance_of(Prism::DefNode, node)
      assert_equal "def m(foo)\n      42\n    end", node.slice
    end

    def test_def_method_utf8
      node = Prism.node_for(with_location(method(:été), UTF8_LOCATION))
      assert_instance_of(Prism::DefNode, node)
      assert_equal "def été; 42; end", node.slice
    end

    def test_inline_method
      node = Prism.node_for(with_location(method(:inline_method), *INLINE_LOCATION_AND_FILE))
      assert_instance_of(Prism::DefNode, node)
      assert_equal "def inline_method = 42", node.slice
    end

    def test_define_method
      node = Prism.node_for(with_location(method(:define_method_method), DEFINE_METHOD_LOCATION))
      assert_instance_of(Prism::CallNode, node)
      assert_equal "define_method(:define_method_method) { 42 }", node.slice
      assert_equal "{ 42 }", node.block.slice
    end

    def test_lambda
      node = Prism.node_for(with_location(-> { 42 }, [__LINE__, 42, __LINE__, 51]))
      assert_instance_of(Prism::LambdaNode, node)
      assert_equal "-> { 42 }", node.slice
      assert_equal "{ 42 }", node.opening_loc.join(node.closing_loc).slice

      node = Prism.node_for(with_location(lambda { 42 }, [__LINE__, 49, __LINE__, 55]))
      assert_instance_of(Prism::CallNode, node)
      assert_equal "lambda { 42 }", node.slice
      assert_equal "{ 42 }", node.block.slice
    end

    def test_proc
      node = Prism.node_for(with_location(proc { 42 }, [__LINE__, 47, __LINE__, 53]))
      assert_instance_of(Prism::CallNode, node)
      assert_equal "proc { 42 }", node.slice
      assert_equal "{ 42 }", node.block.slice

      node = Prism.node_for(with_location(return_block { 42 }, [__LINE__, 55, __LINE__, 61]))
      assert_instance_of(Prism::CallNode, node)
      assert_equal "return_block { 42 }", node.slice
      assert_equal "{ 42 }", node.block.slice

      heredoc_proc = proc { <<~END }
        heredoc
      END
      node = Prism.node_for(with_location(heredoc_proc, [__LINE__-3, 26, __LINE__-3, 36]))
      assert_instance_of(Prism::CallNode, node)
      assert_equal "proc { <<~END }", node.slice
      assert_equal "heredoc\n", node.block.body.body.first.unescaped
    end

    def test_method_to_proc
      node = Prism.node_for(with_location(method(:inline_method).to_proc, *INLINE_LOCATION_AND_FILE))
      assert_instance_of(Prism::DefNode, node)
      assert_equal "def inline_method = 42", node.slice
    end

    def test_for
      node = Prism.node_for(with_location(FOR_BODY_PROC, FOR_BODY_PROC_LOCATION))
      assert_instance_of(Prism::ForNode, node)
      assert_equal "for pr in iter\n#{INDENT}  42\n#{INDENT}end", node.slice
      assert_equal "42", node.statements.slice
    end

    def test_eval
      l = with_location(eval("-> { 42 }"), [1, 0, 1, 9], "(eval at #{__FILE__}:#{__LINE__})")
      e = assert_raise(ArgumentError) { Prism.node_for(l) }
      assert_include e.message, 'eval'

      l = eval "-> { 42 }", nil, __FILE__, __LINE__
      l = with_location(l, [__LINE__-1, 0, __LINE__-1, 9])
      e = assert_raise(ArgumentError) { Prism.node_for(l) }
      assert_include e.message, 'Could not find node'
    end
  end
end
