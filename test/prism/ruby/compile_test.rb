# frozen_string_literal: true
# typed: ignore

require_relative "../test_helper"
require "open3"

module Prism
  class CompileTest < TestCase
    def test_executor
      [
        [3, "1 + 2"],
        [6, "2 * 3"],
        [[1, 2, 3], "[1, 2, 3]"],
        [[1, 2, 5], "[1, 2, 2 + 3]"],
        [{ a: 1, b: 2 }, "{ a: 1, b: 2 }"],
        [{ a: 1, b: 2, c: 3, d: 4 }, "h = { b: 2, c: 3 }; { a: 1, **h, d: 4 }"],
        ["a1c", %q{"a#{1}c"}],
        [:a1c, %q{:"a#{1}c"}],
        [/a1c/, %q{/a#{1}c/}],
        [1, "a = 1; a"],
        [1, "@a = 1; @a"],
        [1, "$a = 1; $a"],
        [5, "a = 1; while a < 5; a += 1; end; a"],
        [Object, "::Object::Object"],
        [CompileTest, "Prism::CompileTest"],
        [Prism, "self.class::Prism"],
        [1..2, "1..2"],
        [1...2, "1...2"],
        ["abc", %q{/\w+/ =~ "abc"; $&}],
        ["a", %q{/bc/ =~ "abc"; $`}],
        ["c", %q{/ab/ =~ "abc"; $'}],
        ["b", %q{/a(b)c/ =~ "abc"; $+}],
        ["b", %q{/a(b)c/ =~ "abc"; $1}],
        [5, "::CompileTestFoo = 5; ::CompileTestFoo"],
        [10, "CompileTestBar = 10; CompileTestBar"],
        [15, "self.class::CompileTestBaz = 15; self.class::CompileTestBaz"],
        [true, "1 in Integer"],
        [TOPLEVEL_BINDING.receiver, "self"]
      ].each do |(expected, source)|
        assert_equal(expected, vm.run(compile_unit(source)))
      end
    end

    def test_blocks_without_parameters
      [
        [3, "a = 0; 3.times { a += 1 }; a"],
        [[2, 2], "[1, 2].map { 2 }"],
        [nil, "proc {}.call"],
        [1, "proc { || 1 }.call"],
        [1, "proc { 1 }.call(2, 3)"],
        [2, "a = 1; p = proc { a }; a = 2; p.call"],
        [[1, 2], "a = 0; p = proc { a += 1 }; [p.call, p.call]"],
        [[1, 1], "p = proc { a ||= 0; a += 1 }; [p.call, p.call]"],
        [[2, 1], "a = 1; result = proc { |; a| a = 2 }.call; [result, a]"],
        [4, "a = 0; 2.times { 2.times { a += 1 } }; a"],
        [1, "a = 0; write = proc { a += 1 }; read = proc { a }; write.call; read.call"],
        [3, "a = 0; for i in [1, 2]; proc { a += i }.call; end; a"],
        [2, "p = proc { a = 1; proc { a += 1 } }.call; p.call"],
        [2, "proc { if true; 2; else; 3; end }.call"],
        [TOPLEVEL_BINDING.receiver, "proc { self }.call"],
        [nil, "nil&.missing { raise 'not called' }"]
      ].each do |expected, source|
        assert_run(expected, source)
      end
    end

    def test_compile_ids
      unit = Prism.compile("a = 1; proc { |b, c| if b; c + a; else; a; end }.call(2, 3)", freeze: true).value
      unit.graphs.each_with_index do |graph, graph_id|
        assert_equal(graph.signature.requireds, graph.blocks[0].params)
        assert_equal(graph_id, graph.id)
        graph.blocks.each_with_index do |block, block_id|
          assert_equal(block_id, block.id)
        end
      end
      locals = unit.graphs.flat_map(&:locals)
      assert_equal((0...locals.length).to_a, locals.map(&:id))
      assert_same(unit.graphs[0], unit.graphs[1].parent)
      assert_equal(4, vm.run(unit))
    end

    def test_disasm
      unit = compile_unit("a = 1; a + 2")
      assert_equal(<<~TEXT, unit.disasm)
        g0 (program, scope=g0):
          bb0:
            branch bb1
          bb1:
            trace_line 1
            %0 = load_object(1)
            store_lvar v0, %0
            %1 = load_lvar v0
            %2 = load_object(2)
            %3 = call %1.+(%2)
            return %3
      TEXT
      assert_equal(3, vm.run(unit))
    end

    def test_disasm_uses_ids
      local = Compile::Local.new(9, :a)
      insn = Compile::Insn.new(:load_lvar, 0, [0], local)
      block = Compile::Block.new(4, [insn], [])
      graph = Compile::Graph.new(3, :program, nil, nil, [block], [local], 1, Compile::Signature.new([], nil, false))
      output = Compile::Unit.new([graph]).disasm
      assert_include(output, "g3 (program, scope=g3):")
      assert_include(output, "bb4:")
      assert_include(output, "%0 = load_lvar v9")
    end

    def test_disasm_blocks_and_branches
      source = "a = 1; proc { |b, c| if b; c + a; else; a; end }.call(2, 3)"
      unit = Prism.compile(source, freeze: true).value
      output = unit.disasm
      assert_include(output, "g1(%0, %1) [autosplat] (block, parent=g0, scope=g1):")
      assert_include(output, "bb0(%0, %1):")
      assert_match(/call_with_block %\d+\.proc &%\d+/, output)
      assert_match(/branchif %\d+ bb\d+ bb\d+/, output)
      assert_match(/branch bb\d+\(%\d+\)/, output)
      assert_not_include(output, "#<Prism::Compile::")
      assert_equal(output, unit.disasm)
      assert_equal(4, vm.run(unit))
    end

    def test_disasm_literals
      output = compile_unit('"a\\nb"').disasm
      assert_include(output, 'load_object("a\nb")')
      output = compile_unit("__ENCODING__").disasm
      assert_include(output, "load_object(encoding(UTF-8))")
      output = compile_unit("/a/i").disasm
      assert_include(output, "load_object(/a/i)")
    end

    def test_compile_cli_disasm
      stdout, stderr, status = Open3.capture3(RbConfig.ruby, File.expand_path("../../../bin/prism", __dir__), "compile", "-e", "1 + 2")
      assert_predicate(status, :success?, stderr)
      assert_equal(compile_unit("1 + 2").disasm, stdout)
    end

    def test_coerce_array_instruction
      insns = [Compile::Insn.new(:coerce_array, 0, [1, 0], nil), Compile::Insn.new(:return, 0, [1], nil)]
      array = [1, 2]
      assert_same(array, run_instructions(insns, [array], 2))
      assert_equal([nil], run_instructions(insns, [nil], 2))
      assert_equal([1], run_instructions(insns, [1], 2))
      item = Object.new
      item.define_singleton_method(:to_ary) { array }
      assert_same(array, run_instructions(insns, [item], 2))
      item.define_singleton_method(:to_ary) { nil }
      assert_equal([item], run_instructions(insns, [item], 2))
      item.define_singleton_method(:to_ary) { 1 }
      assert_raise(TypeError) { run_instructions(insns, [item], 2) }
    end

    def test_signature_and_branch_parameters
      unit = compile_unit("def signature_branch(first, second); if first; second; else; first; end; end; signature_branch(1, 2)")
      graph = unit.graphs.find { |candidate| candidate.kind == :def }
      assert_equal([0, 1], graph.signature.requireds)
      assert_equal(graph.signature.requireds, graph.blocks[0].params)
      assert(graph.blocks.drop(1).any? { |block| !block.params.empty? })
      assert_equal(2, vm.run(unit))
    end

    def test_required_block_parameters
      [
        [[2, 3], "[1, 2].map { |a| a + 1 }"],
        [nil, "proc { |a| a }.call"],
        [1, "proc { |a| a }.call(1, 2)"],
        [[1, 2], "proc { |a| a }.call([1, 2])"],
        [[nil, nil], "proc { |a, b| [a, b] }.call"],
        [[1, nil], "proc { |a, b| [a, b] }.call(1)"],
        [[1, 2], "proc { |a, b| [a, b] }.call(1, 2, 3)"],
        [[1, 2], "proc { |a, b| [a, b] }.call([1, 2, 3])"],
        [[nil, nil], "proc { |a, b| [a, b] }.call(nil)"],
        [[[1, 2], [3, nil]], "[[1, 2], [3]].map { |a, b| [a, b] }"],
        [[[:a, 1]], "{ a: 1 }.map { |a, b| [a, b] }"],
        [[2, 9], "a = 9; p = proc { |a| a += 1 }; [p.call(1), a]"],
        [[1, 2], "p = proc { |a; b| b ||= a }; [p.call(1), p.call(2)]"],
        [[2, 3], "p = proc { |a| proc { a += 1 } }.call(1); [p.call, p.call]"],
        [6, "a = 1; proc { |b| proc { |c| a + b + c }.call(3) }.call(2)"],
        [nil, "class CompileTestYieldRequired; def value; yield; end; end; CompileTestYieldRequired.new.value { |a| a }"]
      ].each do |expected, source|
        assert_run(expected, source)
      end
    end

    def test_required_block_parameters_conversion
      calls = []
      value = Object.new
      value.define_singleton_method(:to_ary) { calls << :to_ary; [1, 2] }
      scope = Module.new
      scope.const_set(:Value, value)
      graph = compile_unit("proc { |a, b| [a, b] }.call(Value)").graphs[0]
      assert_equal([1, 2], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      assert_equal([:to_ary], calls)

      value.define_singleton_method(:to_ary) { nil }
      assert_equal([value, nil], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      value.define_singleton_method(:to_ary) { 1 }
      assert_raise(TypeError) { vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)) }

      graph = compile_unit("proc { |a| a }.call(Value)").graphs[0]
      assert_same(value, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
    end

    def test_required_block_parameters_trace
      unit = compile_unit("proc { |a, b| a + b }")
      graph = unit.graphs[1]
      assert_equal(2, graph.signature.requireds.length)
      assert_equal(graph.signature.requireds, graph.blocks[0].params)
      assert_equal([:store_lvar, :store_lvar, :trace_b_call], graph.blocks[0].insns.first(3).map(&:kind))
    end

    def test_block_autosplat_metadata
      { "proc {}" => false, "proc { |a| a }" => false, "proc { |a, b| a }" => true }.each do |source, expected|
        unit = compile_unit(source)
        assert_equal(expected, unit.graphs[1].signature.autosplat)
        assert_equal(false, unit.graphs[0].signature.autosplat)
      end
      unit = compile_unit("for i in [1]; end")
      assert_equal(false, unit.graphs[1].signature.autosplat)
      unit = compile_unit("class CompileTestAutosplat; def value(a, b); a; end; end")
      assert_equal(false, unit.graphs[2].signature.autosplat)
    end

    def test_block_capture_lifetime
      assert_run([2, 3], <<~RUBY)
        class CompileTestBlockCapture
          def make(a)
            proc { a += 1 }
          end
        end
        p = CompileTestBlockCapture.new.make(1)
        [p.call, p.call]
      RUBY
      assert_run([1, 10, 2], <<~RUBY)
        class CompileTestBlockInvocations
          def make(a)
            proc { a += 1 }
          end
        end
        o = CompileTestBlockInvocations.new
        first = o.make(0)
        second = o.make(9)
        [first.call, second.call, first.call]
      RUBY
    end

    def test_block_self_and_nesting
      assert_run([3, 4], <<~RUBY)
        class CompileTestBlockContext
          A = 3
          def value
            @a = 4
            proc { [A, @a] }.call
          end
        end
        CompileTestBlockContext.new.value
      RUBY
      assert_run(true, "object = Object.new; object.instance_exec { self }.equal?(object)")
      assert_run(true, "object = BasicObject.new; object.instance_exec { self }.equal?(object)")
      assert_post_execution("2\n", "a = 1; proc { END { puts a } }.call; a = 2")
    end

    def test_yield_without_arguments
      assert_run([6, 2], <<~RUBY)
        class CompileTestYield
          def twice
            yield
            yield
          end
          def nested
            proc { yield }.call
          end
          def self.value
            yield
          end
        end
        a = 0
        o = CompileTestYield.new
        o.twice { a += 1 }
        result = o.nested { a += 2 }
        [result + CompileTestYield.value { 2 }, 2]
      RUBY
      assert_run_raises(LocalJumpError, "class CompileTestMissingYield; def value; yield; end; end; CompileTestMissingYield.new.value", "no block given (yield)")
    end

    def test_yield_captured_block
      assert_run(42, <<~RUBY)
        class CompileTestCapturedYield
          def make
            proc { yield() }
          end
        end
        p = CompileTestCapturedYield.new.make { 42 }
        p.call
      RUBY
      assert_run(6, <<~RUBY)
        class CompileTestForYield
          def value
            a = 0
            for i in [1, 2]
              a += yield
            end
            a
          end
        end
        CompileTestForYield.new.value { 3 }
      RUBY
      assert_run_raises(LocalJumpError, <<~RUBY, "no block given (yield)")
        class CompileTestUncapturedYield
          def make
            proc { yield }
          end
        end
        p = CompileTestUncapturedYield.new.make
        p.call { 42 }
      RUBY
    end

    def test_block_graph
      unit = compile_unit("a = 1; proc { a += 1; b = 2 }")
      parent, child = unit.graphs
      assert_equal(:block, child.kind)
      assert_same(parent, child.parent)
      assert_equal([:b], child.locals.map(&:name))
      assert_empty(child.blocks[0].params)
      assert_equal(:trace_b_call, child.blocks[0].insns.first.kind)
      assert_equal([:trace_b_return, :return], child.blocks[0].insns.last(2).map(&:kind))
    end

    def test_for
      [
        [6, "a = 0; for i in [1, 2, 3]; a += i; end; a"],
        [3, "for i in [1, 2, 3]; end; i"],
        [nil, "for i in []; end; i"],
        [4, "i = 4; for i in []; end; i"],
        [[1, 2], "for i in [1, 2]; 99; end"],
        [[1, 2], "for i in [1, 2]; end"],
        [2, "for i in [1, 2]; a = i; end; a"],
        [6, "a = 0; for i in 1..3; a += i; end; a"],
        [[[:a, 1], [:b, 2]], "a = []; for i in { a: 1, b: 2 }; a << i; end; a"],
        [[1, 2], "a = []; for i in [[1, 2]]; a = i; end; a"],
        [nil, "for i in Array.new(1); end; i"],
        [1, "a = 0; for i in (a += 1; [1, 2]); end; a"],
        [9, "a = 0; for i in [1, 2]; for j in [3, 4]; a += i; end; a += i; end; a"],
        [3, "a = 0; for i in [1, 2]; if i == 1; a += 1; else; a += 2; end; end; a"]
      ].each do |expected, source|
        assert_run(expected, source)
      end
      assert_run_raises(NoMethodError, "for i in nil; end")
      assert_post_execution("2\n", "for i in [1, 2]; END { puts i }; end")
    end

    def test_for_block_traces
      {
        "for i in [1]; i + 1; end" => :store_lvar,
        "for i in [1]; end" => :store_lvar,
        "for i in [1]; if i; 2; else; 3; end; end" => :store_lvar,
        "for @i in [1]; end" => :store_ivar,
        "for @@i in [1]; end" => :store_cvar,
        "for $i in [1]; end" => :store_gvar
      }.each do |source, store|
        graph = compile_unit(source).graphs.find { |candidate| candidate.kind == :block }
        entry = graph.blocks[0].insns
        assert_equal([store, :trace_b_call], entry.first(2).map(&:kind))
        traces = graph.blocks.flat_map(&:insns).select { |insn| insn.kind == :trace_b_return }
        assert_equal(1, traces.length)
        tail = graph.blocks.find { |block| block.insns.include?(traces[0]) }.insns
        assert_equal([:trace_b_return, :return], tail.last(2).map(&:kind))
        assert_equal(tail.last.opnds, traces[0].opnds)
      end
    end

    def test_for_instance_variable_target
      assert_run([[1, 2], 2], "a = []; for @compile_test_for in [1, 2]; a << @compile_test_for; end; [a, @compile_test_for]")
      assert_run(4, "@compile_test_for = 4; for @compile_test_for in []; end; @compile_test_for")
      assert_run(nil, "for @compile_test_for in Array.new(1); end; @compile_test_for")
      assert_run([6, 3], <<~RUBY)
        class CompileTestForIvar
          def value
            total = 0
            for @item in [1, 2, 3]
              total += @item
            end
            [total, @item]
          end
        end
        CompileTestForIvar.new.value
      RUBY

      graph = compile_unit("for @item in [1]; end").graphs[0]
      assert_raise(FrozenError) { vm.run_frame(Compile::VM::Frame.new(graph, Object.new.freeze, [Object].freeze)) }
    ensure
      recv = TOPLEVEL_BINDING.receiver
      recv.remove_instance_variable(:@compile_test_for) if recv.instance_variable_defined?(:@compile_test_for)
    end

    def test_for_class_variable_target
      scope = Class.new
      graph = compile_unit("a = []; for @@item in [1, 2]; a << @@item; end; [a, @@item]").graphs[0]
      assert_equal([[1, 2], 2], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      assert_equal(2, scope.class_variable_get(:@@item))

      graph = compile_unit("for @@item in []; end; @@item").graphs[0]
      assert_equal(2, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      graph = compile_unit("for @@item in Array.new(1); end; @@item").graphs[0]
      assert_nil(vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      assert_run_raises(RuntimeError, "for @@compile_test_for in [1]; end", "class variable access from toplevel")
      assert_run([], "for @@compile_test_for in []; end")
      assert_run(2, "class CompileTestForCvar; def value; for @@item in [1, 2]; end; @@item; end; end; CompileTestForCvar.new.value")
    end

    def test_for_global_variable_target
      assert_run([[1, 2], 2], "a = []; for $compile_test_for in [1, 2]; a << $compile_test_for; end; [a, $compile_test_for]")
      assert_run(4, "$compile_test_for = 4; for $compile_test_for in []; end; $compile_test_for")
      assert_run(nil, "for $compile_test_for in Array.new(1); end; $compile_test_for")
      assert_run([1, 2], "for $compile_test_for in [1, 2]; 99; end")
    ensure
      $compile_test_for = nil
    end

    def test_for_constant_target
      ["A", "self::A"].each do |target|
        scope = Module.new
        graph = compile_unit("a = []; result = (for #{target} in [1, 2]; a << #{target}; end); [result, a, #{target}]").graphs[0]
        capture_warnings do
          assert_equal([[1, 2], [1, 2], 2], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
        end
        assert_equal(2, scope.const_get(:A, false))

        graph = compile_unit("for #{target} in []; end; #{target}").graphs[0]
        assert_equal(2, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))

        scope = Module.new
        graph = compile_unit("for #{target} in []; end").graphs[0]
        assert_equal([], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
        refute(scope.const_defined?(:A, false))
      end

      capture_warnings { assert_run(2, "for ::CompileTestForConstant in [1, 2]; end; ::CompileTestForConstant") }
      assert_run(3, "module CompileTestForConstantScope; for A in [3]; end; end; CompileTestForConstantScope::A")
    ensure
      Object.send(:remove_const, :CompileTestForConstant) if Object.const_defined?(:CompileTestForConstant, false)
    end

    def test_for_constant_path_target_evaluation
      scope = Module.new
      graph = compile_unit("a = []; for (a << 1; self)::A in [1, 2]; a << 2; end; [a, A]").graphs[0]
      capture_warnings do
        assert_equal([[1, 2, 1, 2], 2], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      end
      graph = compile_unit("a = []; for (a << 1; self)::A in []; end; a").graphs[0]
      assert_equal([], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      assert_run_raises(TypeError, "for 1.itself::A in [1]; end")
      assert_run([], "for 1.itself::A in []; end")

      graph = compile_unit("for self::A in [1]; end").graphs[0]
      frozen_scope = Module.new.freeze
      assert_raise(FrozenError) { vm.run_frame(Compile::VM::Frame.new(graph, frozen_scope, [frozen_scope, Object].freeze)) }
    end

    def test_block_lexical_scopes
      unit = compile_unit("a = 1; proc { proc { a } }; for i in [1]; proc { a += i }; end")
      program, outer, inner, loop_graph, loop_block = unit.graphs
      assert_same(program, program.scope)
      assert_empty(outer.locals)
      assert_same(outer, outer.scope)
      assert_same(inner, inner.scope)
      assert_same(program, loop_graph.scope)
      assert_same(loop_graph, loop_block.parent)
      assert_same(loop_block, loop_block.scope)

      assert_run(1, "a = 1; proc { proc { a } }.call.call")
      assert_run(12, "a = 0; 2.times { |; x| x = 1; for i in [1, 2]; proc { x += i; a += x }.call; end }; a")
    end

    def test_for_shares_locals_storage
      machine = Compile::VM.new
      frames = []
      machine.define_singleton_method(:run_frame) do |frame, args = []|
        frames << frame
        super(frame, args)
      end
      machine.run(compile_unit("for i in [1]; end; proc {}.call"))
      program, loop_frame, block_frame = frames
      assert_same(program.locals, loop_frame.locals)
      refute_same(program.locals, block_frame.locals)
      assert_same(program.locals, block_frame.locals.parent)
    end

    def test_for_uses_block_call
      unit = compile_unit("for i in [1, 2]; end")
      insns = unit.graphs[0].blocks.flat_map(&:insns)
      block_insn = insns.find { |insn| insn.kind == :new_block }
      call_insn = insns.find { |insn| insn.kind == :call_with_block }
      assert_equal(:block, block_insn.data.kind)
      assert_equal(:each, call_insn.data)
      assert_equal(block_insn.opnds[0], call_insn.opnds[-1])
      assert_same(unit.graphs[0].scope, block_insn.data.scope)
    end

    def test_for_custom_each
      collection = Object.new
      def collection.each
        yield
        yield 1
        yield 2, 3
        :finished
      end
      scope = Module.new
      scope.const_set(:Items, collection)
      graph = compile_unit("a = []; result = (for i in Items; a << i; end); [result, a, i]").graphs[0]
      assert_equal([:finished, [nil, 1, 2], 2], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
    end

    def test_for_method_scope
      assert_run([6, 2], <<~RUBY)
        class CompileTestForMethod
          def value(n)
            total = 0
            for i in 1..n
              total += i
            end
            total
          end
        end
        o = CompileTestForMethod.new
        [o.value(3), o.value(1) + o.value(1)]
      RUBY
    end

    def test_pre_execution
      [
        [nil, "BEGIN {}"],
        [nil, "BEGIN { 1 }"],
        [nil, "1; BEGIN { 2 }"],
        [2, "BEGIN { a = 2 }; a"],
        [1, "a = 1; BEGIN { a = 2 }; a"],
        [1, "BEGIN { a = 0; a += 1 }; a"],
        [[1, 2, 3], "BEGIN { a = []; a << 1 }; a << 3; BEGIN { a << 2 }; a"],
        [[1, 2], "BEGIN { BEGIN { a = []; a << 1 }; a << 2 }; a"],
        [[1, 2, 3], "BEGIN { a = nil if false; a << 2 if true; BEGIN { a = []; a << 1 }; a << 3 }; a"],
        [[1, 2, 3, 4], "BEGIN { a = []; if true; a << 1; end }; if true; a << 3; end; BEGIN { if false; a << 0; else; a << 2; end }; a << 4; a"],
        [[1, 2, 3, 4], "BEGIN { BEGIN { BEGIN { a = []; a << 1 }; a << 2 }; a << 3 }; a << 4; a"],
        [2, "BEGIN { a = (if true; 2; else; 3; end) }; a"],
        [TOPLEVEL_BINDING.receiver, "BEGIN { a = self }; a"]
      ].each do |expected, source|
        assert_run(expected, source)
      end
      assert_run_raises(RuntimeError, 'raise "body"; BEGIN { raise "pre" }', "pre")
    end

    def test_pre_execution_repeated_runs
      unit = compile_unit("BEGIN { a = 0 }; a += 1")
      assert_equal(1, vm.run(unit))
      assert_equal(1, vm.run(unit))
    end

    def test_pre_and_post_execution
      assert_post_execution("pre\nbody\n2\n", 'puts "body"; BEGIN { puts "pre"; a = 1; END { puts a } }; a = 2')
    end

    def test_post_execution
      assert_post_execution("body\n2\n", 'a = 1; END { puts a }; a = 2; puts "body"')
      assert_post_execution("second\nfirst\n", 'END { puts "first" }; END { puts "second" }')
      assert_post_execution("3\n", 'a = 1; END { puts a }; END { a += 1 }; a = 2')
      assert_post_execution("body\n", 'if false; END { puts "unreachable" }; end; END {}; puts "body"')
      assert_post_execution("nil\n", 'END { a = 2 }; END { p a }')
      assert_post_execution("outer\ninner\nfirst\n", 'END { puts "first" }; END { puts "outer"; END { puts "inner" } }')
    end

    def test_post_execution_registers_once
      assert_post_execution("3\n", 'a = 0; while a < 3; END { puts a }; a += 1; end')
      assert_post_execution("1\n", 'class CompileTestEndMethod; def value(a); END { puts a }; end; end; o = CompileTestEndMethod.new; o.value(1); o.value(2)')
    end

    def test_post_execution_vm_state
      assert_post_execution("1\n1\n", <<~RUBY)
        unit = Prism.compile("END { puts 1 }").value
        machine = Prism::Compile::VM.new
        machine.run(unit)
        machine.run(unit)
        Prism::Compile::VM.new.run(unit)
      RUBY
      assert_post_execution("second\nfirst\n", <<~RUBY)
        machine = Prism::Compile::VM.new
        machine.run(Prism.compile('END { puts "first" }').value)
        machine.run(Prism.compile('END { puts "second" }').value)
      RUBY
    end

    def test_post_execution_scope
      assert_post_execution("CompileTestEndModule\n1\n3\n", <<~RUBY)
        module CompileTestEndModule
          A = 1
          a = 2
          END { puts self.name; puts A; puts a }
          a = 3
        end
      RUBY
      assert_post_execution("2\n", 'a = 1; END { END { puts a }; a = 2 }')
    end

    def test_post_execution_graph
      unit = compile_unit("a = 1; END { a += 1 }")
      parent, child = unit.graphs
      assert_equal(:post_execution, child.kind)
      assert_same(parent, child.parent)
      assert_same(parent.scope, child.scope)
      assert_empty(child.locals)
      local_insns = child.blocks.flat_map(&:insns).select { |insn| [:load_lvar, :store_lvar].include?(insn.kind) }
      assert_equal(2, local_insns.length)
      local_insns.each { |insn| assert_same(parent.locals[0], insn.data) }
    end

    def test_vm_runs_multiple_units
      assert_equal(40, vm.run(compile_unit("module CompileTestVMPersistent; A = 40; end")))
      assert_equal(42, vm.run(compile_unit("CompileTestVMPersistent::A + 2")))
    end

    def test_compiled_methods_retain_vm
      machine = Compile::VM.new
      frames = []
      machine.define_singleton_method(:run_frame) do |frame, args = []|
        frames << frame
        super(frame, args)
      end

      machine.run(compile_unit(<<~RUBY))
        class CompileTestVMOwner
          def value; 1; end
          def self.value; 2; end
        end
      RUBY
      frames.clear

      assert_equal(1, CompileTestVMOwner.new.value)
      assert_equal(2, CompileTestVMOwner.value)
      assert_equal([:def, :def], frames.map { |frame| frame.graph.kind })
    end

    def test_frame_isolation
      graph = compile_unit("a ||= 0; a += 1").graphs[0]
      recv = TOPLEVEL_BINDING.receiver
      first = Compile::VM::Frame.new(graph, recv, [Object].freeze)
      second = Compile::VM::Frame.new(graph, recv, [Object].freeze)

      assert_equal(1, vm.run_frame(first))
      assert_equal(1, vm.run_frame(second))
      first.locals[graph.locals[0].id] = 10
      assert_equal(1, second.locals[graph.locals[0].id])
    end

    def test_frames_share_locals
      graph = compile_unit("a ||= 0; a += 1").graphs[0]
      locals = Compile::VM::Locals.new(graph.locals)
      recv = TOPLEVEL_BINDING.receiver
      first = Compile::VM::Frame.new(graph, recv, [Object].freeze, locals)
      second = Compile::VM::Frame.new(graph, recv, [Object].freeze, locals)

      assert_equal(1, vm.run_frame(first))
      assert_equal(2, vm.run_frame(second))
      refute_same(first.values, second.values)
      assert_equal(2, locals[graph.locals[0].id])
    end

    def test_locals_parent
      outer_local = Compile::Local.new(0, :a)
      inner_local = Compile::Local.new(1, :a)
      parent = Compile::VM::Locals.new([outer_local])
      child = Compile::VM::Locals.new([inner_local], parent)

      parent[outer_local.id] = 1
      assert_nil(child[inner_local.id])
      assert_equal(1, child[outer_local.id])
      child[outer_local.id] = 2
      child[inner_local.id] = 3
      assert_equal(2, parent[outer_local.id])
      assert_equal(3, child[inner_local.id])
      assert_raise(KeyError) { child[2] }
      assert_raise(KeyError) { child[2] = 4 }
    end

    def test_locals_ids_are_unit_relative
      first = compile_unit("a = 1; proc { a }")
      second = compile_unit("a = 2; a")
      assert_equal(first.graphs[0].locals[0].id, second.graphs[0].locals[0].id)
      captured = vm.run(first)
      assert_equal(2, vm.run(second))
      assert_equal(1, captured.call)
    end

    def test_recursive_frames
      assert_run([10, 6], <<~RUBY)
        class CompileTestRecursiveFrames
          def sum(n)
            if n == 0
              0
            else
              subtotal = sum(n - 1)
              n + subtotal
            end
          end
        end
        o = CompileTestRecursiveFrames.new
        [o.sum(4), o.sum(3)]
      RUBY
    end

    def test_match_last_line
      [
        [1, '$_ = "abc"; if /b/; 1; else; 2; end'],
        [2, '$_ = "abc"; if /z/; 1; else; 2; end'],
        [2, '$_ = nil; if /a/; 1; else; 2; end'],
        [1, '$_ = "A"; if /a/i; 1; else; 2; end'],
        [1, '$_ = "a\nb"; if /a.b/m; 1; else; 2; end'],
        [1, '$_ = "ab"; if /a b/x; 1; else; 2; end'],
        ["b", '$_ = "abc"; if /a(b)c/; $1; end'],
        [nil, '$_ = "abc"; if /a(b)c/; end; if /z/; end; $1'],
        ["abc", '$_ = "abc"; if /a/; end; $_'],
        [1, '$_ = "abc"; 1 if /a/'],
        [2, '$_ = "abc"; unless /a/; 1; else; 2; end'],
        [2, '$_ = "a"; n = 0; while /a/; n += 1; if n == 2; $_ = "b"; end; end; n']
      ].each do |expected, source|
        assert_run(expected, source)
      end
      assert_run_raises(TypeError, '$_ = 1; if /a/; 1; else; 2; end')
    ensure
      TOPLEVEL_BINDING.eval("$_ = nil")
    end

    def test_interpolated_match_last_line
      [
        [1, '$_ = "abc"; a = "b"; if /#{a}/; 1; else; 2; end'],
        [2, '$_ = "abc"; a = "z"; if /#{a}/; 1; else; 2; end'],
        [2, '$_ = nil; if /#{"a"}/; 1; else; 2; end'],
        [1, '$_ = "A"; if /#{"a"}/i; 1; else; 2; end'],
        [1, '$_ = "a\nb"; if /a#{"."}b/m; 1; else; 2; end'],
        [1, '$_ = "ab"; if /a #{"b"}/x; 1; else; 2; end'],
        ["b", '$_ = "abc"; if /a(#{"b"})c/; $1; end'],
        [nil, '$_ = "abc"; if /a(#{"b"})c/; end; if /#{"z"}/; end; $1'],
        [1, '$_ = "abc"; 1 if /#{"a"}/'],
        [2, '$_ = "abc"; unless /#{"a"}/; 1; else; 2; end'],
        [1, '$_ = "a"; if /#{($_ = "b"; "b")}/; 1; else; 2; end'],
        [[1, 2], '$_ = "ab"; a = []; if /#{(a << 1; "a")}#{(a << 2; "b")}/; end; a'],
        [2, '$_ = "a"; n = 0; while /#{(n += 1; "a")}/; $_ = "b"; end; n'],
        [1, '$_ = nil; n = 0; if /#{(n += 1; "a")}/; end; n'],
        [1, '$_ = "a"; if /#{(if true; "a"; else; "b"; end)}/; 1; else; 2; end']
      ].each do |expected, source|
        assert_run(expected, source)
      end
      assert_run_raises(TypeError, '$_ = 1; if /#{"a"}/; end')
      assert_run_raises(RuntimeError, 'if /#{raise "interpolation failed"}/; end', "interpolation failed")
    ensure
      TOPLEVEL_BINDING.eval("$_ = nil")
    end

    def test_match_write
      [
        [[0, "abc"], 'result = (/(?<word>abc)/ =~ "abc"); [result, word]'],
        [[1, "abc"], 'result = (/(?<word>abc)/ =~ "zabc"); [result, word]'],
        [[nil, nil], 'word = 1; result = (/(?<word>abc)/ =~ "xyz"); [result, word]'],
        [["a", "b"], '/(?<first>a)(?<second>b)/ =~ "ab"; [first, second]'],
        [[nil, "b"], '/(?<first>a)?(?<second>b)/ =~ "b"; [first, second]'],
        ["b", '/(?<word>a)|(?<word>b)/ =~ "b"; word'],
        [nil, '/(?<word>a)/ =~ "a"; /(?<word>a)/ =~ "b"; word'],
        [nil, '/(?<word>a)/ =~ nil; word'],
        [["a", 1], 'a = 0; /(?<word>a)/ =~ (a += 1; "a"); [word, a]'],
        ["a", 'if /(?<word>a)/ =~ "a"; word; else; 1; end'],
        ["a", 'word = 1; /(?<word>a)/ =~ "a"; word'],
        [["a", "a"], '/(?<word>a)/ =~ "a"; [word, $1]']
      ].each do |expected, source|
        assert_run(expected, source)
      end
    end

    def test_match_write_method_scope
      assert_run(["a", nil, "a"], <<~RUBY)
        class CompileTestMatchWrite
          def value(string)
            /(?<word>a)/ =~ string
            word
          end
        end
        o = CompileTestMatchWrite.new
        [o.value("a"), o.value("b"), o.value("a")]
      RUBY
    end

    def test_pinned_variable
      [
        [true, "a = 1; 1 in ^a"],
        [false, "a = 1; 2 in ^a"],
        [true, "a = Integer; 1 in ^a"],
        [false, "a = Integer; nil in ^a"],
        [true, "a = nil; nil in ^a"],
        [true, "a = false; false in ^a"],
        [true, "a = 1; (a = 2) in ^a"],
        [true, "a = 1; b = 2; 2 in ^a | ^b"],
        [false, "a = 1; b = 2; 3 in ^a | ^b"],
        [true, "@compile_test_pin = 1; 1 in ^@compile_test_pin"],
        [false, "@compile_test_pin = 1; 2 in ^@compile_test_pin"]
      ].each do |expected, source|
        assert_run(expected, source)
      end

      assert_run([true, false], "class CompileTestPinnedCvar; @@pin = 1; [(1 in ^@@pin), (2 in ^@@pin)]; end")
      assert_run([true, false], "$compile_test_pin = 1; [(1 in ^$compile_test_pin), (2 in ^$compile_test_pin)]")
    ensure
      TOPLEVEL_BINDING.receiver.remove_instance_variable(:@compile_test_pin) if TOPLEVEL_BINDING.receiver.instance_variable_defined?(:@compile_test_pin)
      $compile_test_pin = nil
    end

    def test_pinned_variable_case_equality
      assert_run([true, [2]], <<~RUBY)
        class CompileTestPinnedMatcher
          def initialize; @calls = []; end
          def ===(value); @calls << value; :matched; end
          def calls; @calls; end
        end
        a = CompileTestPinnedMatcher.new
        result = (2 in ^a | ^a)
        [result, a.calls]
      RUBY
    end

    def test_pinned_expression
      [
        [true, "3 in ^(1 + 2)"],
        [false, "4 in ^(1 + 2)"],
        [true, "1 in ^(Integer.itself)"],
        [true, "nil in ^(nil)"],
        [true, "false in ^(false)"],
        [true, "2 in ^(if true; 2; else; 3; end)"],
        [true, "2 in ^(nil&.missing || 2)"],
        [true, "a = 1; (a = 2) in ^(a)"],
        [[true, 1], "a = 0; result = (1 in ^(a += 1)); [result, a]"],
        [[false, 1], "a = 0; result = (2 in ^(a += 1)); [result, a]"],
        [[true, 1], "a = 0; result = (1 in ^(a += 1) | ^(a += 1)); [result, a]"],
        [[true, 2], "a = 0; result = (2 in ^(a += 1) | ^(a += 1)); [result, a]"],
        [[false, 2], "a = 0; result = (3 in ^(a += 1) | ^(a += 1)); [result, a]"]
      ].each do |expected, source|
        assert_run(expected, source)
      end
      assert_run_raises(RuntimeError, '1 in ^(raise "pin failed")', "pin failed")
    end

    def test_pinned_expression_case_equality
      assert_run([true, [2]], <<~RUBY)
        class CompileTestPinnedExpressionMatcher
          def initialize; @calls = []; end
          def ===(value); @calls << value; :matched; end
          def calls; @calls; end
        end
        a = CompileTestPinnedExpressionMatcher.new
        result = (2 in ^(a.itself))
        [result, a.calls]
      RUBY
    end

    def test_safe_navigation
      assert_run(nil, "nil&.missing")
      assert_run(false, "false&.itself")
      assert_run(3, "1&.+(2)")
      assert_run(nil, "nil&.missing&.another")
      assert_run(3, "1&.+(1)&.+(1)")
      assert_run(2, "(if true; 1; else; nil; end)&.+(1)")
      assert_run(3, "1&.+(if false; 1; else; 2; end)")
      assert_run(4, "1 + 1&.+(2)")
      assert_run(nil, "nil&.missing(1&.+(2))")
      assert_run_raises(NoMethodError, "false&.missing")
      assert_run_raises(NoMethodError, "nil&.missing.another")
      assert_run(3, "class CompileTestSafeBasic < BasicObject; def value; 3; end; end; CompileTestSafeBasic.new&.value")
      assert_run(4, "class CompileTestSafeNilPredicate; def nil?; true; end; def value; 4; end; end; CompileTestSafeNilPredicate.new&.value")
    end

    def test_safe_navigation_evaluation_order
      assert_run([], "a = []; nil&.missing(a << 1); a")
      assert_run([], "a = []; nil&.missing(a << 1)&.another(a << 2); a")
      assert_run([1, 2, 3], "a = []; (a << 1)&.push((a << 2; 3)); a")
      assert_run(1, "a = 0; (a += 1)&.itself; a")
      assert_run(3, "a = 0; while a < 3; nil&.missing(a += 10); a += 1; end; a")
    end

    def test_safe_navigation_assignment
      assert_run(nil, "nil&.value = 1")
      assert_run(0, "a = 0; nil&.value = (a += 1); a")
      assert_run([2, 2], <<~RUBY)
        class CompileTestSafeSetter
          def value=(value); @value = value; 99; end
          def value; @value; end
        end
        o = CompileTestSafeSetter.new
        result = (o&.value = 2)
        [result, o.value]
      RUBY
    end

    def test_safe_navigation_return
      assert_run([1, 2], <<~RUBY)
        class CompileTestSafeReturn
          def value(receiver)
            receiver&.itself(if receiver; return 1; end)
            2
          end
        end
        o = CompileTestSafeReturn.new
        [o.value(true), o.value(nil)]
      RUBY
    end

    def test_if
      [
        [1, "if true; 1; else; 2; end"],
        [2, "if false; 1; else; 2; end"],
        [2, "if nil; 1; else; 2; end"],
        [1, "if 0; 1; else; 2; end"],
        [nil, "if false; 1; end"],
        [nil, "if true; end"],
        [nil, "if false; 1; else; end"],
        [2, "if true; 1; 2; else; 3; end"],
        [3, "if false; 1; elsif false; 2; elsif true; 3; else; 4; end"],
        [4, "if false; 1; elsif false; 2; else; 4; end"],
        [nil, "if false; 1; elsif false; 2; end"],
        [2, "if true; if false; 1; else; 2; end; else; 3; end"],
        [3, "1 + (if false; 1; else; 2; end)"],
        [1, "1 if true"],
        [nil, "1 if false"],
        [1, "true ? 1 : 2"],
        [2, "false ? 1 : 2"],
        [3, "false ? 1 : true ? 3 : 4"],
        [2, "if false || true; 2; else; 3; end"],
        [1, "(if true; false; else; true; end) ? 2 : 1"]
      ].each do |expected, source|
        assert_run(expected, source)
      end
    end

    def test_if_evaluation_order
      assert_run([1, 2], "a = []; if (a << 1); a << 2; else; a << 3; end; a")
      assert_run([1, 3], "a = []; if (a << 1) && false; a << 2; elsif (a << 3); a; else; a << 4; end")
      assert_run(2, "a = 0; if true; a = 2; else; a = 3; end; a")
      assert_run(nil, "if false; a = 1; end; a")
      assert_run(3, "a = 0; while a < 3; if a < 2; a += 1; else; a += 1; end; end; a")
    end

    def test_if_return
      assert_run([1, 2, 3], <<~RUBY)
        class CompileTestIfReturn
          def value(a)
            if a == 1
              return 1
            elsif a == 2
              return 2
            end
            3
          end
        end
        o = CompileTestIfReturn.new
        [o.value(1), o.value(2), o.value(3)]
      RUBY

      assert_run(2, "class CompileTestIfReturnBoth; def value; if false; return 1; else; return 2; end; 3; end; end; CompileTestIfReturnBoth.new.value")
      assert_run(1, "class CompileTestIfReturnExpression; def value; 10 + (if true; return 1; else; 2; end); end; end; CompileTestIfReturnExpression.new.value")
      assert_run(1, "class CompileTestIfReturnModifier; def value; return 1 if true; 2; end; end; CompileTestIfReturnModifier.new.value")
    end

    def test_unless
      [
        [1, "unless false; 1; else; 2; end"],
        [1, "unless nil; 1; else; 2; end"],
        [2, "unless true; 1; else; 2; end"],
        [2, "unless 0; 1; else; 2; end"],
        [nil, "unless true; 1; end"],
        [nil, "unless false; end"],
        [nil, "unless true; 1; else; end"],
        [2, "unless false; 1; 2; else; 3; end"],
        [3, "1 + (unless true; 1; else; 2; end)"],
        [1, "1 unless false"],
        [nil, "1 unless true"],
        [2, "unless false; unless true; 1; else; 2; end; else; 3; end"],
        [3, "unless true; 1; else; unless false; 3; else; 4; end; end"],
        [2, "unless (unless false; true; else; false; end); 1; else; 2; end"],
        [2, "if true; unless true; 1; else; 2; end; else; 3; end"],
        [2, "unless false; if false; 1; else; 2; end; else; 3; end"],
        [1, "unless false && true; 1; else; 2; end"]
      ].each do |expected, source|
        assert_run(expected, source)
      end
    end

    def test_unless_evaluation_order
      assert_run([1, 3], "a = []; unless (a << 1); a << 2; else; a << 3; end; a")
      assert_run([1, 2], "a = []; unless (a << 1) && false; a << 2; else; a << 3; end; a")
      assert_run(2, "a = 0; unless false; a = 2; else; a = 3; end; a")
      assert_run(nil, "unless true; a = 1; end; a")
      assert_run(3, "a = 0; while a < 3; unless a > 1; a += 1; else; a += 1; end; end; a")
    end

    def test_unless_return
      assert_run([1, 2], <<~RUBY)
        class CompileTestUnlessReturn
          def value(a)
            unless a
              return 1
            else
              return 2
            end
            3
          end
        end
        o = CompileTestUnlessReturn.new
        [o.value(false), o.value(true)]
      RUBY

      assert_run(1, "class CompileTestUnlessReturnExpression; def value; 10 + (unless false; return 1; else; 2; end); end; end; CompileTestUnlessReturnExpression.new.value")
      assert_run(1, "class CompileTestUnlessReturnModifier; def value; return 1 unless false; 2; end; end; CompileTestUnlessReturnModifier.new.value")
    end

    PRIVATE_CONSTANT = 1
    private_constant :PRIVATE_CONSTANT

    def test_const_get_recv_rel
      assert_raise(NameError) { vm.run(compile_unit("String::Integer")) }
      assert_raise(NameError) { vm.run(compile_unit("Prism::CompileTest::PRIVATE_CONSTANT")) }
      assert_raise(TypeError) { vm.run(compile_unit("Float::INFINITY::Foo")) }
      assert_raise(NameError) { vm.run(compile_unit("::String::Integer")) }
      assert_raise(NameError) { vm.run(compile_unit("::Prism::CompileTest::PRIVATE_CONSTANT")) }
      assert_raise(NameError) { vm.run(compile_unit("String.itself::Integer")) }
      assert_raise(NameError) { vm.run(compile_unit("Prism::CompileTest.itself::PRIVATE_CONSTANT")) }
      assert_raise(TypeError) { vm.run(compile_unit("1.itself::Foo")) }
    end

    def test_const_set_recv_rel
      assert_run_raises(TypeError, "1.itself::CompileTestNotModule = 1")
    end

    def test_constant_logical_write
      ["A", "self::A", "::CompileTestConstantAssignment"].each do |target|
        ["&&=", "||="].each do |operator|
          [:undefined, nil, false, 1].each do |initial|
            scope = Module.new
            owner, name = target.start_with?("::") ? [Object, :CompileTestConstantAssignment] : [scope, :A]
            owner.const_set(name, initial) unless initial == :undefined
            source = "a = 0; result = (#{target} #{operator} (a += 1; 2)); [result, a]"
            graph = compile_unit(source).graphs[0]

            if initial == :undefined && operator == "&&="
              assert_raise(NameError) { vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)) }
              refute owner.const_defined?(name, false)
            else
              writes = operator == "&&=" ? !!initial : initial == :undefined || !initial
              expected = [writes ? 2 : initial, writes ? 1 : 0]
              capture_warnings do
                assert_equal(expected, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)), source)
              end
              assert_equal(writes ? 2 : initial, owner.const_get(name, false))
            end
          ensure
            owner.send(:remove_const, name) if owner&.const_defined?(name, false)
          end
        end
      end
    end

    def test_constant_operator_write
      ["A", "self::A", "::CompileTestConstantOperatorAssignment"].each do |target|
        scope = Module.new
        owner, name = target.start_with?("::") ? [Object, :CompileTestConstantOperatorAssignment] : [scope, :A]
        owner.const_set(name, 3)
        graph = compile_unit("a = 0; result = (#{target} += (a += 1; 2)); [result, a]").graphs[0]
        capture_warnings do
          assert_equal([5, 1], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
        end
        assert_equal(5, owner.const_get(name, false))
        owner.send(:remove_const, name)
        assert_raise(NameError) { vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)) }
      ensure
        owner.send(:remove_const, name) if owner&.const_defined?(name, false)
      end
    end

    def test_constant_compound_write_receiver
      ["&&=", "||=", "+="].each do |operator|
        scope = Module.new
        scope.const_set(:A, operator == "||=" ? false : 1)
        graph = compile_unit("a = []; result = ((a << 1; self)::A #{operator} (a << 2; 3)); [result, a]").graphs[0]
        capture_warnings do
          assert_equal([operator == "+=" ? 4 : 3, [1, 2]], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
        end
      end

      assert_run([1], "a = []; (a << 1; Object)::CompileTestConstReceiver ||= 3; a")
      assert_run(2, "module CompileTestConstNested; A ||= (if true; 2; else; 3; end); end")
    ensure
      Object.send(:remove_const, :CompileTestConstReceiver) if Object.const_defined?(:CompileTestConstReceiver, false)
    end

    def test_constant_compound_write_lookup
      scope = Class.new(Class.new { const_set(:A, 1) })
      graph = compile_unit("A ||= 2").graphs[0]
      assert_equal(1, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      refute scope.const_defined?(:A, false)

      outer = Module.new { const_set(:A, 3) }
      inner = Module.new
      assert_equal(3, vm.run_frame(Compile::VM::Frame.new(graph, inner, [inner, outer, Object].freeze)))
      refute inner.const_defined?(:A, false)

      scope = Module.new { const_set(:A, 4); private_constant :A }
      assert_equal(4, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      graph = compile_unit("self::A ||= 2").graphs[0]
      capture_warnings { assert_equal(2, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze))) }
      ["&&=", "+="].each do |operator|
        graph = compile_unit("self::A #{operator} 2").graphs[0]
        assert_raise(NameError) { vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)) }
      end

      ["&&=", "||=", "+="].each do |operator|
        assert_run_raises(TypeError, "1.itself::A #{operator} 2")
      end
    end

    def test_constant_or_write_does_not_call_const_missing
      scope = Module.new
      def scope.const_missing(name) = raise("const_missing called")
      graph = compile_unit("self::A ||= 2").graphs[0]
      assert_equal(2, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      graph = compile_unit("B ||= 3").graphs[0]
      assert_equal(3, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
    end

    def test_constant_compound_write_const_missing
      scope = Module.new
      def scope.const_missing(name) = 4
      ["A &&= 2", "self::B += 3"].zip([2, 7]) do |source, expected|
        graph = compile_unit(source).graphs[0]
        assert_equal(expected, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      end
      assert_equal(2, scope.const_get(:A, false))
      assert_equal(7, scope.const_get(:B, false))
    end

    def test_constant_or_write_autoload
      scope = Module.new
      Object.const_set(:CompileTestConstAutoload, scope)
      Tempfile.create(["compile_const_autoload", ".rb"]) do |file|
        file.write("CompileTestConstAutoload::A = 3")
        file.flush
        scope.autoload(:A, file.path)
        graph = compile_unit("self::A ||= 2").graphs[0]
        assert_equal(3, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
        assert_equal(3, scope.const_get(:A, false))
      end
    ensure
      Object.send(:remove_const, :CompileTestConstAutoload) if Object.const_defined?(:CompileTestConstAutoload, false)
    end

    def test_define_module
      assert_run(42, "module CompileTestModuleBody; 42; end")
      assert_run(nil, "module CompileTestModuleEmpty; end")
      assert_run("CompileTestModuleSelf", "(module CompileTestModuleSelf; self; end).name")
      assert_run("CompileTestModuleAbs", "(module ::CompileTestModuleAbs; self; end).name")
      assert_run("CompileTestModuleOuter::Inner", "module CompileTestModuleOuter; (module Inner; self; end).name; end")
      assert_run("CompileTestModuleOuter::Recv", "(module CompileTestModuleOuter::Recv; self; end).name")
      assert_run("CompileTestModuleOuter::Dynamic", "(module CompileTestModuleOuter.itself::Dynamic; self; end).name")
      assert_run([1, 2], "module CompileTestModuleReopen; A = 1; end; module CompileTestModuleReopen; B = 2; end; [CompileTestModuleReopen::A, CompileTestModuleReopen::B]")
      assert_run(3, "module CompileTestModuleMethods; def value; 3; end; end; class CompileTestModuleUser; include CompileTestModuleMethods; end; CompileTestModuleUser.new.value")
      assert_run(4, "module CompileTestModuleSingleton; def self.value; 4; end; end; CompileTestModuleSingleton.value")
      assert_run(5, "module CompileTestModuleCvar; @@value = 5; def self.value; @@value; end; end; CompileTestModuleCvar.value")
    end

    def test_define_module_scope
      assert_run([1, 2], <<~RUBY)
        module CompileTestModuleScope
          A = 1
          module Inner
            B = 2
            def self.values; [A, B]; end
          end
        end
        CompileTestModuleScope::Inner.values
      RUBY
      assert_run([2, 1], "a = 1; b = (module CompileTestModuleLocal; a = 2; end); [b, a]")
      assert_run_raises(NameError, "module CompileTestModuleQualified; A = 1; end; module CompileTestModuleQualified::Inner; A; end")
      assert_run(nil, "a = 1; module CompileTestModuleNoCapture; a = 2 if false; a; end")
      assert_run(true, "module CompileTestModulePrivate; M = Module.new; private_constant :M; module M; end; true; end")
      assert_run_raises(NameError, "module CompileTestModulePrivate::M; end")
    end

    def test_define_module_errors
      assert_run_raises(TypeError, "CompileTestModuleNotModule = 1; module CompileTestModuleNotModule; end", /\ACompileTestModuleNotModule is not a module$/)
      assert_run_raises(TypeError, "class CompileTestModuleIsClass; end; module CompileTestModuleIsClass; end", /\ACompileTestModuleIsClass is not a module$/)
      assert_run_raises(TypeError, "module 1.itself::CompileTestModuleBadScope; end", "1 is not a class/module")
      assert_run_raises(NameError, "module CompileTestModuleMissingParent::Inner; end")
    end

    def test_define_module_ir
      unit = compile_unit("module CompileTestModuleIR; 1; end")
      assert_equal(:module, unit.graphs[1].kind)
      assert_equal([:trace_class, :trace_line, :load_object, :trace_end, :return], unit.graphs[1].blocks[0].insns.map(&:kind))
    end

    def test_define_class
      assert_run(42, "class CompileTestBody; 42; end")
      assert_run(nil, "class CompileTestEmpty; end")
      assert_run("CompileTestSelf", "(class CompileTestSelf; self; end).name")
      assert_run("CompileTestAbs", "(class ::CompileTestAbs; self; end).name")
      assert_run("CompileTestOuter::Inner", "class CompileTestOuter; (class Inner; self; end).name; end")
      assert_run("CompileTestOuter::Recv", "(class CompileTestOuter::Recv; self; end).name")
      assert_run(String, "class CompileTestSuper < String; end; CompileTestSuper.superclass")
      assert_run(String, "class ::CompileTestAbsSuper < String; end; CompileTestAbsSuper.superclass")
      assert_run(String, "class CompileTestOuter::RecvSuper < String; end; CompileTestOuter::RecvSuper.superclass")
    end

    def test_define_class_reopen
      assert_run([String, 1, 2], <<~RUBY)
        class CompileTestReopen < String; A = 1; end
        class CompileTestReopen; B = 2; end
        [CompileTestReopen.superclass, CompileTestReopen::A, CompileTestReopen::B]
      RUBY

      assert_run(true, "class CompileTestReopen < String; end; true")
    end

    def test_define_class_errors
      assert_run(true, "class CompileTestErrors; P = Class.new; private_constant :P; true; end")

      assert_run_raises(TypeError, "class CompileTestErrors < String; end")
      assert_run_raises(TypeError, "class CompileTestErrors < nil; end")
      assert_run_raises(TypeError, "class CompileTestBadSuper < 1; end")
      assert_run_raises(TypeError, "class 1::CompileTestBadScope; end")
      assert_run_raises(TypeError, "CompileTestNotClass = 1; class CompileTestNotClass; end")
      assert_run_raises(NameError, "class CompileTestErrors::P; end")
    end

    def test_define_class_error_messages
      assert_run_raises(TypeError, "CompileTestMessageNotClass = 1; class CompileTestMessageNotClass; end", /\ACompileTestMessageNotClass is not a class$/)
      assert_run_raises(TypeError, "class 1.itself::CompileTestMessageScope; end", "1 is not a class/module")
    end

    def test_define_class_checks_superclass_first
      message = "superclass must be an instance of Class (given an instance of Integer)"
      assert_run(true, "class CompileTestSuperFirst; P = Class.new; private_constant :P; true; end")

      assert_run_raises(TypeError, "class CompileTestSuperFirstNew < 2; end", message)
      assert_run_raises(TypeError, "class ::CompileTestSuperFirstNewAbs < 2; end", message)
      assert_run_raises(TypeError, "class 1.itself::CompileTestSuperFirstScope < 2; end", message)
      assert_run_raises(TypeError, "CompileTestSuperFirstNest = 1; class CompileTestSuperFirstNest < 2; end", message)
      assert_run_raises(TypeError, "CompileTestSuperFirstAbs = 1; class ::CompileTestSuperFirstAbs < 2; end", message)
      assert_run_raises(TypeError, "CompileTestSuperFirstRecv = 1; class Object::CompileTestSuperFirstRecv < 2; end", message)
      assert_run_raises(TypeError, "class CompileTestSuperFirst::P < 2; end", message)
    end

    def test_define_class_basic_object_operands
      assert_run_raises(TypeError, "class CompileTestBasicSuper < BasicObject.new; end", "superclass must be an instance of Class (given an instance of BasicObject)")
      assert_run_raises(TypeError, "CompileTestBasicConst = BasicObject.new; class CompileTestBasicConst; end", /\ACompileTestBasicConst is not a class$/)
      assert_run_raises(NoMethodError, "class BasicObject.new::CompileTestBasicScope; end", /undefined method 'inspect'/)
      assert_run_raises(NoMethodError, "BasicObject.new::CompileTestBasicStore = 1", /undefined method 'inspect'/)
      assert_run_raises(NoMethodError, "BasicObject.new::CompileTestBasicLoad", /undefined method 'inspect'/)
    end

    def test_define_class_nesting
      assert_run([1, 2, 3], <<~RUBY)
        class CompileTestNesting
          X = 1
          class Inner
            Y = 2
            class Innermost
              Z = 3
              [X, Y, Z]
            end
          end
        end
      RUBY

      assert_run_raises(NameError, "class CompileTestNesting::Inner; X; end")
    end

    def test_coerce_hash
      assert_run({}, "{ **nil }")
      assert_run(false, "h = { a: 1 }; { **h }.equal?(h)")
      assert_run(nil, "{ **Hash.new(5) }.default")

      assert_run_raises(TypeError, "{ **1 }", "no implicit conversion of Integer into Hash")
      assert_run_raises(TypeError, "{ **BasicObject.new }", "no implicit conversion of BasicObject into Hash")

      Object.const_set(:CompileTestToHashNil, Class.new { def to_hash = nil }.new)
      assert_run_raises(TypeError, "{ **CompileTestToHashNil }", /#to_hash gives nil/)
    end

    def test_new_hash_empty
      assert_run({}, "{}")
      assert_run(0, "h = {}; h.size")
    end

    def test_merge_hash
      Object.const_set(:CompileTestHashSubclass, Class.new(Hash))

      assert_run(Hash, "{ **CompileTestHashSubclass.new }.class")
      assert_run(Hash, "{ **CompileTestHashSubclass.new, a: 1 }.class")
      assert_run(nil, "{ **Hash.new(5), a: 1 }.default")
      assert_run(nil, "{ **Hash.new(5), **Hash.new(5) }.default")
      assert_run(nil, "{ **Hash.new(5), **{} }.default")
      assert_run(nil, "{ **Hash.new(5), **nil }.default")
      assert_run(nil, "{ **nil, **Hash.new(5) }.default")
      assert_run(false, "{ **Hash.new.compare_by_identity }.compare_by_identity?")
      assert_run(false, "{ **Hash.new.compare_by_identity, a: 1 }.compare_by_identity?")
      assert_run_raises(TypeError, "{ **1, a: 1 }", "no implicit conversion of Integer into Hash")
      assert_run_raises(TypeError, "{ **1, **nil }", "no implicit conversion of Integer into Hash")
    end

    def test_merge_hash_conversion_order
      log = []
      splat = ->(tag) { Class.new { define_method(:to_hash) { log << tag; { tag => 1 } } }.new }
      Object.const_set(:CompileTestSplatX, splat[:x])
      Object.const_set(:CompileTestSplatY, splat[:y])

      assert_run({ x: 1, y: 1 }, "{ **CompileTestSplatX, **CompileTestSplatY }")
      assert_equal([:x, :y], log)

      log.clear
      assert_run({ x: 1, a: { y: 1 } }, "{ **CompileTestSplatX, a: CompileTestSplatY.to_hash }")
      assert_equal([:x, :y], log)

      assert_run({ x: 1 }, "{ **CompileTestSplatX, **nil }")
    end

    def test_coerce_string
      Object.const_set(:CompileTestBasicToS, Class.new { def to_s = BasicObject.new }.new)
      Object.const_set(:CompileTestPrivateToS, Class.new { private def to_s = "private" }.new)

      assert_run(String, '"#{CompileTestBasicToS}".class')
      assert_run("private", '"#{CompileTestPrivateToS}"')
    end

    def test_alias
      Object.const_set(:CompileTestAlias, Class.new { def a = 1; private def secret = 2 })

      assert_run(nil, "class CompileTestAlias; alias b a; end")
      assert_run(1, "CompileTestAlias.new.b")
      assert_run(1, %q{class CompileTestAlias; x = :c; alias :"#{x}" :a; end; CompileTestAlias.new.c})
      assert_run(true, "class CompileTestAlias; alias hidden secret; end; CompileTestAlias.private_method_defined?(:hidden)")
    end

    def test_alias_targets_lexical_class
      outer = Class.new { def a = 1 }
      outer.const_set(:Inner, Class.new { def a = 2 })
      Object.const_set(:CompileTestAliasOuter, outer)

      assert_run(2, "class CompileTestAliasOuter; class Inner; alias b a; end; end; CompileTestAliasOuter::Inner.new.b")
      assert_equal(false, outer.method_defined?(:b))

      assert_run(1, "alias compile_test_top_alias itself; 1.compile_test_top_alias")
      assert_equal(true, Object.method_defined?(:compile_test_top_alias))
    end

    def test_alias_errors
      Object.const_set(:CompileTestAliasErrors, Class.new.freeze)

      assert_run_raises(FrozenError, "class CompileTestAliasErrors; alias a to_s; end")
      assert_run_raises(NameError, "class CompileTestAliasMissing; alias a nope; end", "undefined method 'nope' for class 'CompileTestAliasMissing'")
    end

    def test_undef
      parent = Class.new { def a = 1; def b = 2; def c = 3; def d = 4; def e = 5 }
      Object.const_set(:CompileTestUndef, Class.new(parent))

      assert_run(nil, "class CompileTestUndef; undef a; end")
      assert_equal(false, CompileTestUndef.method_defined?(:a))
      assert_equal(true, parent.method_defined?(:a))

      assert_run(nil, "class CompileTestUndef; undef b, c; end")
      assert_equal(false, CompileTestUndef.method_defined?(:b))
      assert_equal(false, CompileTestUndef.method_defined?(:c))

      assert_run(nil, %q{class CompileTestUndef; x = :d; undef :"#{x}"; end})
      assert_equal(false, CompileTestUndef.method_defined?(:d))
      assert_equal(true, CompileTestUndef.method_defined?(:e))
    end

    def test_undef_errors
      assert_run_raises(NameError, "class CompileTestUndefMissing; undef nope; end", "undefined method 'nope' for class 'CompileTestUndefMissing'")
    end

    def test_alias_undef_ignore_method_overrides
      Object.const_set(:CompileTestAliasOverride, Class.new {
        def a = 1
        def self.alias_method(*) = raise("alias_method called")
        def self.undef_method(*) = raise("undef_method called")
      })

      assert_run(1, "class CompileTestAliasOverride; alias b a; undef a; end; CompileTestAliasOverride.new.b")
      assert_equal(false, CompileTestAliasOverride.method_defined?(:a))
    end

    def test_alias_undef_hooks
      log = []
      Object.const_set(:CompileTestAliasHooks, Class.new {
        def a = 1
        define_singleton_method(:method_added) { |name| log << [:added, name] }
        define_singleton_method(:method_undefined) { |name| log << [:undefined, name] }
      })

      assert_run(nil, "class CompileTestAliasHooks; alias b a; undef a; end")
      assert_equal([[:added, :b], [:undefined, :a]], log)
    end

    def test_cvar
      assert_run(1, "class CompileTestCVar; @@a = 1; @@a; end")
      assert_equal(1, CompileTestCVar.class_variable_get(:@@a))
      assert_equal(false, Object.class_variable_defined?(:@@a))

      assert_run_raises(NameError, "class CompileTestCVarMissing; @@a; end", "uninitialized class variable @@a in CompileTestCVarMissing")
    end

    def test_cvar_toplevel
      message = "class variable access from toplevel"

      assert_run_raises(RuntimeError, "@@compile_test_top", message)
      assert_run_raises(RuntimeError, "@@compile_test_top = 1", message)
      assert_run_raises(RuntimeError, "@@compile_test_top ||= 1", message)
      assert_run_raises(RuntimeError, "@@compile_test_top &&= 1", message)
      assert_run_raises(RuntimeError, "@@compile_test_top += 1", message)
      assert_equal(false, Object.class_variable_defined?(:@@compile_test_top))
    end

    def test_cvar_or_write
      Object.const_set(:CompileTestCVarSide, [])

      assert_run(1, "class CompileTestCVarOr; @@a ||= 1; @@a ||= 2; @@a; end")
      assert_run(3, "class CompileTestCVarOr; @@b = nil; @@b ||= 3; @@b; end")
      assert_run(4, "class CompileTestCVarOr; @@c = false; @@c ||= 4; @@c; end")
      assert_run(5, "class CompileTestCVarOr; @@d = 5; @@d ||= CompileTestCVarSide.push(1); @@d; end")
      assert_equal([], CompileTestCVarSide)
      assert_equal([:@@a, :@@b, :@@c, :@@d], CompileTestCVarOr.class_variables(false).sort)
    end

    def test_cvar_and_write_and_operator_write
      assert_run(3, "class CompileTestCVarAnd; @@a = 1; @@a &&= 3; @@a; end")
      assert_run(false, "class CompileTestCVarAnd; @@b = false; @@b &&= 3; @@b; end")
      assert_run(4, "class CompileTestCVarAnd; @@c = 1; @@c += 3; @@c; end")

      assert_run_raises(NameError, "class CompileTestCVarAnd; @@missing &&= 1; end", "uninitialized class variable @@missing in CompileTestCVarAnd")
      assert_run_raises(NameError, "class CompileTestCVarAnd; @@missing += 1; end", "uninitialized class variable @@missing in CompileTestCVarAnd")
    end

    def test_cvar_or_write_inherits
      Object.const_set(:CompileTestCVarParent, Class.new { class_variable_set(:@@a, 1) })
      Object.const_set(:CompileTestCVarModule, Module.new { class_variable_set(:@@m, 2) })

      assert_run(1, "class CompileTestCVarChild < CompileTestCVarParent; @@a ||= 5; @@a; end")
      assert_equal([], CompileTestCVarChild.class_variables(false))

      Object.const_set(:CompileTestCVarIncluder, Class.new { include CompileTestCVarModule })
      assert_run(2, "class CompileTestCVarIncluder; @@m ||= 5; @@m; end")
      assert_equal([], CompileTestCVarIncluder.class_variables(false))
    end

    def test_cvar_or_write_uses_innermost_scope
      Object.const_set(:CompileTestCVarOuter, Class.new { class_variable_set(:@@a, 1) })

      assert_run(9, "class CompileTestCVarOuter; class Inner; @@a ||= 9; @@a; end; end")
      assert_equal(1, CompileTestCVarOuter.class_variable_get(:@@a))
      assert_equal([:@@a], CompileTestCVarOuter::Inner.class_variables(false))
    end

    def test_cvar_skips_singleton_scopes
      klass = Class.new { class_variable_set(:@@a, 1) }

      graph = compile_unit("@@a ||= 5").graphs[0]
      assert_equal(1, vm.run_frame(Compile::VM::Frame.new(graph, klass, [klass.singleton_class, klass, Object].freeze)))

      error = assert_raise(RuntimeError) { vm.run_frame(Compile::VM::Frame.new(graph, klass, [klass.singleton_class, Object].freeze)) }
      assert_equal("class variable access from toplevel", error.message)
    end

    def test_cvar_or_write_reopened_object
      assert_run(1, "class Object; @@compile_test_object ||= 1; @@compile_test_object; end")
    ensure
      Object.remove_class_variable(:@@compile_test_object) if Object.class_variable_defined?(:@@compile_test_object)
    end

    def test_cvar_or_write_errors
      Object.const_set(:CompileTestCVarFrozen, Class.new.freeze)
      assert_run_raises(FrozenError, "class CompileTestCVarFrozen; @@a ||= 1; end")

      Object.const_set(:CompileTestCVarOvertaken, Class.new { class_variable_set(:@@compile_test_overtaken, 1) })

      begin
        Object.class_variable_set(:@@compile_test_overtaken, 2)
        assert_run_raises(RuntimeError, "class CompileTestCVarOvertaken; @@compile_test_overtaken ||= 3; end", "class variable @@compile_test_overtaken of CompileTestCVarOvertaken is overtaken by Object")
      ensure
        Object.remove_class_variable(:@@compile_test_overtaken)
      end
    end

    def test_cvar_ignores_method_overrides
      Object.const_set(:CompileTestCVarOverride, Class.new {
        def self.class_variable_defined?(*) = raise("class_variable_defined? called")
        def self.class_variable_get(*) = raise("class_variable_get called")
        def self.class_variable_set(*) = raise("class_variable_set called")
        def self.singleton_class? = raise("singleton_class? called")
      })

      assert_run(1, "class CompileTestCVarOverride; @@a ||= 1; @@a; end")
    end

    def test_gvar_or_write
      Object.const_set(:CompileTestGVarSide, [])

      assert_run(1, "$compile_test_or_new ||= 1")
      assert_run(1, "$compile_test_or_new ||= 2")
      assert_run(3, "$compile_test_or_nil = nil; $compile_test_or_nil ||= 3; $compile_test_or_nil")
      assert_run(4, "$compile_test_or_false = false; $compile_test_or_false ||= 4; $compile_test_or_false")
      assert_run(5, "$compile_test_or_set = 5; $compile_test_or_set ||= CompileTestGVarSide.push(1)")
      assert_equal([], CompileTestGVarSide)
    end

    def test_gvar_or_write_special_variables
      assert_run(IO, "$stdout ||= 1; $stdout.class")
      assert_run(String, "$PROGRAM_NAME ||= 'x'; $PROGRAM_NAME.class")
    end

    def test_gvar_or_write_does_not_read_undefined
      verbose, stderr = $VERBOSE, $stderr
      $VERBOSE = true
      $stderr = StringIO.new

      vm.run(compile_unit("$compile_test_or_silent ||= 1"))
      assert_equal("", $stderr.string)
    ensure
      $VERBOSE, $stderr = verbose, stderr
    end

    def test_gvar_and_write_leaves_undefined
      assert_run(nil, "$compile_test_and_new &&= 5")
      assert_nil(eval("defined?($compile_test_and_new)"))

      assert_run(6, "$compile_test_and_set = 1; $compile_test_and_set &&= 6; $compile_test_and_set")
    end

    def test_define_method
      assert_run(:a, "class CompileTestDef; def a; end; end")
      assert_nil(CompileTestDef.new.a)

      assert_run(3, "class CompileTestDefArgs; def add(a, b) = a + b; end; CompileTestDefArgs.new.add(1, 2)")
      assert_run(1, "class CompileTestDefSelf; def set(a) = @a = a; def get = @a; end; o = CompileTestDefSelf.new; o.set(1); o.get")
      assert_run(3, "class CompileTestDefRecurse; def count(n); n > 0 && count(n - 1); n; end; end; CompileTestDefRecurse.new.count(3)")
    end

    def test_return
      source = "class CompileTestReturn; def none; return; 1; end; def one; return 1; 2; end; def many; return 1, 2; end; def array; return [1]; end; nil; end; CompileTestReturn.new"

      assert_run(nil, "#{source}.none")
      assert_run(1, "#{source}.one")
      assert_run([1, 2], "#{source}.many")
      assert_run([1], "#{source}.array")
    end

    def test_define_method_nesting
      assert_run(1, "class CompileTestDefConst; A = 1; def a = A; end; CompileTestDefConst.new.a")
      assert_run(1, "class CompileTestDefNested; def a; def b = 1; end; end; CompileTestDefNested.new.a; CompileTestDefNested.new.b")
      assert_equal(true, CompileTestDefNested.public_method_defined?(:b))
    end

    def test_define_method_arguments
      source = "class CompileTestDefArity; def a(b) = b; end; CompileTestDefArity.new"
      assert_run_raises(ArgumentError, "#{source}.a", "wrong number of arguments (given 0, expected 1)")
      assert_run_raises(ArgumentError, "#{source}.a(1, 2)", "wrong number of arguments (given 2, expected 1)")
    end

    def test_define_method_rest_parameter
      source = "class CompileTestDefRest; def a(*args) = args; end; CompileTestDefRest.new"
      assert_run([], "#{source}.a")
      assert_run([1, 2, 3], "#{source}.a(1, 2, 3)")
      assert_run([[1, 2]], "#{source}.a([1, 2])")
      source = "class CompileTestDefRequiredRest; def a(first, *rest) = [first, rest]; end; CompileTestDefRequiredRest.new"
      assert_run([1, []], "#{source}.a(1)")
      assert_run([1, [2, 3]], "#{source}.a(1, 2, 3)")
      assert_run_raises(ArgumentError, "#{source}.a", "wrong number of arguments (given 0, expected 1+)")
      assert_run([[1, 2], [1]], "class CompileTestDefRestFresh; def a(*args); args << 2; end; end; input = [1]; [CompileTestDefRestFresh.new.a(input[0]), input]")
      assert_run([1, 2], "class CompileTestDefRestCapture; def a(*args); proc { args << 2 }.call; args; end; end; CompileTestDefRestCapture.new.a(1)")
    end

    def test_define_method_anonymous_rest_parameter
      source = "class CompileTestDefAnonymousRest; def a(*) = 1; end; CompileTestDefAnonymousRest.new"
      assert_run(1, "#{source}.a")
      assert_run(1, "#{source}.a(2, 3)")
      source = "class CompileTestDefRequiredAnonymousRest; def a(first, *) = first; end; CompileTestDefRequiredAnonymousRest.new"
      assert_run(1, "#{source}.a(1, 2, 3)")
      assert_run_raises(ArgumentError, "#{source}.a", "wrong number of arguments (given 0, expected 1+)")
    end

    def test_define_singleton_method_rest_parameter
      assert_run([1, [2, 3]], "object = Object.new; def object.a(first, *rest) = [first, rest]; object.a(1, 2, 3)")
    end

    def test_rest_parameter_entry_values
      ["def rest_only(*args) = args", "def rest_only(*) = 1"].each do |source|
        graph = compile_unit(source).graphs.find { |candidate| candidate.kind == :def }
        assert_empty(graph.signature.requireds)
        assert_equal(0, graph.signature.rest)
        assert_equal([0], graph.blocks[0].params)
      end
      assert_nil(compile_unit("1").graphs[0].signature.rest)
    end

    def test_compiled_method_rest_parameter
      unit = Prism.compile("def a(first, *rest) = rest", freeze: true).value
      graph = unit.graphs.find { |candidate| candidate.kind == :def }
      entry = graph.blocks[0]
      assert_equal([0, 1], entry.params)
      assert_equal([0], graph.signature.requireds)
      assert_equal(1, graph.signature.rest)
      assert_include(unit.disasm, "g1(%0, *%1) (def, scope=g1):")
      assert_include(unit.disasm, "bb0(%0, %1):")
      assert_include(unit.disasm, "store_lvar v1, %1")
    end

    def test_define_method_basic_object
      source = "class CompileTestDefBasic < BasicObject; def a(b) = b; end; CompileTestDefBasic.new"
      assert_run(1, "#{source}.a(1)")
      assert_run_raises(ArgumentError, "#{source}.a", "wrong number of arguments (given 0, expected 1)")
    end

    def test_define_method_visibility
      assert_run(:compile_test_toplevel, "def compile_test_toplevel = 1")
      assert_equal(true, Object.private_method_defined?(:compile_test_toplevel))
      assert_run(1, "compile_test_toplevel")

      assert_run(:compile_test_inner, "def compile_test_outer; def compile_test_inner = 1; end; compile_test_outer")
      assert_equal(true, Object.public_method_defined?(:compile_test_inner))

      assert_run(nil, "class CompileTestDefVisibility; def a = 1; def initialize; end; nil; end")
      assert_equal(true, CompileTestDefVisibility.public_method_defined?(:a))
      assert_equal(true, CompileTestDefVisibility.private_method_defined?(:initialize))
    ensure
      [:compile_test_toplevel, :compile_test_outer, :compile_test_inner].each do |name|
        Object.send(:remove_method, name) if Object.private_method_defined?(name, false) || Object.public_method_defined?(name, false)
      end
    end

    def test_define_method_ignores_method_overrides
      Object.const_set(:CompileTestDefOverride, Class.new {
        def self.define_method(*) = raise("define_method called")
        def self.private(*) = raise("private called")
      })

      assert_run(1, "class CompileTestDefOverride; def a = 1; end; CompileTestDefOverride.new.a")
    end

    def test_define_method_hooks
      log = []
      Object.const_set(:CompileTestDefHooks, Class.new {
        define_singleton_method(:method_added) { |name| log << name }
      })

      assert_run(:a, "class CompileTestDefHooks; def a; end; end")
      assert_equal([:a], log)
    end

    def test_define_singleton_method
      assert_run(1, "o = Object.new; def o.a = 1; o.a")
      assert_run(:a, "o = Object.new; def o.a; end")
      assert_run(3, "o = Object.new; def o.add(a, b) = a + b; o.add(1, 2)")
      assert_run(true, "o = Object.new; def o.me = self; o.me.equal?(o)")
      assert_run(1, "class CompileTestDefs; def self.a = 1; end; CompileTestDefs.a")
      assert_equal(false, CompileTestDefs.method_defined?(:a))
    end

    def test_define_singleton_method_visibility
      assert_run(true, "o = Object.new; def o.a = 1; o.singleton_class.public_method_defined?(:a)")
      assert_run(true, "o = Object.new; def o.initialize = 1; o.singleton_class.public_method_defined?(:initialize)")
    end

    def test_define_singleton_method_nesting
      assert_run(1, "class CompileTestDefsNest; A = 1; O = Object.new; def O.a = A; end; CompileTestDefsNest::O.a")
    end

    def test_define_singleton_method_errors
      assert_run_raises(TypeError, "def (1.itself).a; end", "can't define singleton")
      assert_run_raises(TypeError, "def (:a.itself).a; end", "can't define singleton")
      assert_run_raises(FrozenError, "o = Object.new.freeze; def o.a; end")
    end

    def test_define_singleton_method_basic_object
      assert_run(1, "o = BasicObject.new; def o.a = 1; o.a")
    end

    def test_define_singleton_method_ignores_method_overrides
      Object.const_set(:CompileTestDefsOverride, Class.new {
        def self.singleton_class = raise("singleton_class called")
        def self.define_singleton_method(*) = raise("define_singleton_method called")
      })

      assert_run(1, "def CompileTestDefsOverride.a = 1; CompileTestDefsOverride.a")
    end

    def test_define_singleton_method_hooks
      log = []
      Object.const_set(:CompileTestDefsHooks, Class.new {
        define_singleton_method(:singleton_method_added) { |name| log << name }
      })
      log.clear

      assert_run(:a, "def CompileTestDefsHooks.a; end")
      assert_equal([:a], log)
    end

    def test_singleton_class
      assert_run(1, "class << Object.new; 1; end")
      assert_run(nil, "class << Object.new; end")
      assert_run(Object.singleton_class, "class << Object; self; end")
      assert_run(1, "class CompileTestSingleton; class << self; def a = 1; end; end; CompileTestSingleton.a")
      assert_run(1, "o = Object.new; class << o; def a = 1; end; o.a")
      assert_equal(false, CompileTestSingleton.method_defined?(:a))
    end

    def test_singleton_class_special_constants
      assert_run(NilClass, "class << nil; self; end")
      assert_run(TrueClass, "class << true; self; end")
      assert_run(FalseClass, "class << false; self; end")
    end

    def test_singleton_class_errors
      assert_run_raises(TypeError, "class << 1; end", "can't define singleton")
      assert_run_raises(TypeError, "class << :a; end", "can't define singleton")
      assert_run_raises(FrozenError, "o = Object.new.freeze; class << o; def a; end; end")
    end

    def test_singleton_class_scope
      assert_run(1, "a = 1; class << Object.new; a = 2; end; a")
      assert_run(1, "class CompileTestSingletonConst; A = 1; class << self; def a = A; end; end; CompileTestSingletonConst.a")

      assert_run(2, "class CompileTestSingletonStore; class << self; B = 2; B; end; end")
      assert_equal(2, CompileTestSingletonStore.singleton_class.const_get(:B, false))
      assert_equal(false, CompileTestSingletonStore.const_defined?(:B, false))

      assert_run(1, "class CompileTestSingletonCVar; @@a = 1; class << self; def a = @@a; end; end; CompileTestSingletonCVar.a")
    end

    def test_singleton_class_basic_object
      assert_run(1, "class CompileTestSingletonBasic < BasicObject; end; class << CompileTestSingletonBasic.new; 1; end")
    end

    def test_singleton_class_ignores_method_overrides
      Object.const_set(:CompileTestSingletonOverride, Class.new {
        def self.singleton_class = raise("singleton_class called")
      })

      assert_run(1, "class << CompileTestSingletonOverride; def a = 1; end; CompileTestSingletonOverride.a")
    end

    def test_singleton_class_hooks
      log = []
      Object.const_set(:CompileTestSingletonHooks, Class.new {
        define_singleton_method(:singleton_method_added) { |name| log << name }
      })
      log.clear

      assert_run(:a, "class << CompileTestSingletonHooks; def a; end; end")
      assert_equal([:a], log)
    end

    def test_compile_result
      result = Prism.compile("1 + 2 # comment")

      assert_kind_of Compile::Result, result
      assert_predicate result, :success?
      assert_kind_of Compile::Unit, result.value
      assert_equal 1, result.comments.length
      assert_equal 3, vm.run(result.value)
    end

    def test_compile_errors
      result = Prism.compile("1 +")

      assert_predicate result, :failure?
      assert_nil result.value
      refute_empty result.errors
    end

    def test_compile_errors_without_error_nodes
      result = Prism.compile("def foo; break; end")

      assert_predicate result, :failure?
      assert_nil result.value
    end

    def test_compile_warnings
      result = Prism.compile("foo = 1")

      assert_predicate result, :success?
      refute_empty result.warnings
    end

    def test_compile_raise_error
      error = assert_raise(SyntaxError) { Prism.compile("1 +\n", raise_error: :plain, filepath: "test.rb") }
      assert_equal "test.rb", error.path

      assert_nothing_raised { Prism.compile("1 +", raise_error: nil) }
      assert_raise(ArgumentError) { Prism.compile("1", raise_error: :bogus) }
    end

    def test_compile_options
      assert_raise(ArgumentError) { Prism.compile("1", bogus: true) }
      assert_raise(TypeError) { Prism.compile(nil) }

      unit = Prism.compile("1", line: 10).value
      trace_line = unit.graphs[0].blocks.flat_map(&:insns).find { |insn| insn.kind == :trace_line }
      assert_equal 10, trace_line.data
    end

    def test_compile_freeze
      result = Prism.compile("class CompileTestFreeze; def a(b) = b; end; CompileTestFreeze.new.a('c')", freeze: true)
      assert_predicate result, :frozen?

      unit = result.value
      assert_predicate unit, :frozen?
      assert_predicate unit.graphs, :frozen?

      unit.graphs.each do |graph|
        assert_predicate graph, :frozen?
        assert_predicate graph.blocks, :frozen?
        assert_predicate graph.signature, :frozen?
        assert_predicate graph.signature.requireds, :frozen?
        assert_predicate graph.locals, :frozen?
        graph.locals.each { |local| assert_predicate local, :frozen? }

        graph.blocks.each do |block|
          assert_predicate block, :frozen?
          assert_predicate block.insns, :frozen?
          assert_predicate block.params, :frozen?

          block.insns.each do |insn|
            assert_predicate insn, :frozen?
            assert_predicate insn.opnds, :frozen?
          end
        end
      end

      value = vm.run(unit)
      assert_equal "c", value
      refute_predicate value, :frozen?
    end

    def test_compile_file
      Tempfile.create(["test_compile_file", ".rb"]) do |file|
        file.write("1 + 2")
        file.flush

        assert_equal 3, vm.run(Prism.compile_file(file.path).value)
        assert_equal 3, vm.run(Prism.compile_file(Pathname.new(file.path)).value)
      end

      assert_raise(Errno::ENOENT) { Prism.compile_file("idontexist.rb") }
      assert_raise(TypeError) { Prism.compile_file(nil) }
    end

    def test_compile_file_raise_error
      Tempfile.create(["test_compile_file_raise_error", ".rb"]) do |file|
        file.write("1 +\n")
        file.flush

        assert_nil Prism.compile_file(file.path).value

        error = assert_raise(SyntaxError) { Prism.compile_file(file.path, raise_error: :plain) }
        assert_equal file.path, error.path
      end
    end

    private

    def run_instructions(insns, args, nvalues)
      block = Compile::Block.new(0, insns, [0])
      signature = Compile::Signature.new([0], nil, false)
      graph = Compile::Graph.new(0, :block, nil, nil, [block], [], nvalues, signature)
      frame = Compile::VM::Frame.new(graph, TOPLEVEL_BINDING.receiver, [Object].freeze)
      vm.run_frame(frame, args)
    end

    def assert_post_execution(expected, source)
      script = 'Prism::Compile::VM.new.run(Prism.compile(ARGV.fetch(0), raise_error: :plain).value)'
      stdout, stderr, status = Open3.capture3(RbConfig.ruby, "-I", File.expand_path("../../../lib", __dir__), "-rprism", "-e", script, source)
      assert_predicate(status, :success?, stderr)
      assert_equal(expected, stdout)
    end

    def vm
      @vm ||= Compile::VM.new
    end

    def compile_unit(source)
      Prism.compile(source, raise_error: :plain).value
    end

    def assert_run(expected, source)
      assert_equal(expected, vm.run(compile_unit(source)))
    end

    def assert_run_raises(error, source, message = nil)
      if message
        assert_raise_with_message(error, message) { vm.run(compile_unit(source)) }
      else
        assert_raise(error) { vm.run(compile_unit(source)) }
      end
    end
  end
end
