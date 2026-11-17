# frozen_string_literal: true
# typed: ignore

require_relative "../test_helper"
require "open3"

module Prism
  class CompileTest < TestCase
    def test_literal_string_encodings
      [
        ["US-ASCII", '"\xFF"', Encoding::ASCII_8BIT],
        ["ASCII-8BIT", '"\u00E9"', Encoding::UTF_8],
        ["UTF-8", '"\xFF"', Encoding::UTF_8],
        ["ISO-8859-1", '"\xE9"', Encoding::ISO_8859_1],
        ["US-ASCII", '"plain"', Encoding::US_ASCII]
      ].each do |encoding, literal, expected_encoding|
        [false, true].each do |frozen|
          source = "# encoding: #{encoding}\n# frozen_string_literal: #{frozen}\n#{literal}"
          value = vm.run(compile_unit(source))
          assert_equal(eval(source).bytes, value.bytes)
          assert_equal(expected_encoding, value.encoding)
          assert_equal(frozen, value.frozen?)
        end
      end
    end

    def test_literal_symbol_encodings
      [
        ["US-ASCII", ':"\xFF"', Encoding::ASCII_8BIT],
        ["ASCII-8BIT", ':"\u00E9"', Encoding::UTF_8],
        ["ISO-8859-1", ':"\xE9"', Encoding::ISO_8859_1],
        ["UTF-8", ':plain', Encoding::US_ASCII],
        ["ISO-8859-1", ':plain', Encoding::US_ASCII]
      ].each do |encoding, literal, expected_encoding|
        source = "# encoding: #{encoding}\n#{literal}"
        value = vm.run(compile_unit(source))
        assert_same(eval(source), value)
        assert_equal(expected_encoding, value.encoding)
      end
    end

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

    def test_break_loops
      [
        "while true; break; end",
        "while true; break(); end",
        "while true; break nil; end",
        "while true; break false; end",
        "while true; break 3; end",
        "while true; break [1, 2]; 99; end",
        "while true; break 1, 2; end",
        "while true; break *[1, 2]; end",
        "while true; break 1, *[2, 3], 4; end",
        "while true; break *nil; end",
        "until false; break 3; end",
        "begin; break 3; end while false",
        "begin; break 3; end until true",
        "i = 0; while i < 2; i += 1; break i if i == 2; end",
        "while true; inner = while true; break 2; end; break inner + 1; end",
        "events = []; result = while true; events << 1; break(events << 2) if events.length == 1; events << 3; end; [result, events]",
        "while true; begin; raise 'failure'; rescue; break 3; end; end",
        "before = $!; result = while true; begin; raise 'failure'; rescue; break 3; end; end; [result, $!.equal?(before)]"
      ].each { |source| assert_run(eval(source), source) }
    end

    def test_break_blocks
      [
        "[1, 2].each { break }",
        "[1, 2].each { break 3 }",
        "[1].each { break [1, 2]; 99 }",
        "-> { break [1, 2]; 99 }.call",
        "events = []; result = [1].each { break(events << 2); 99 }; [result, events]",
        "[1, 2].map { break 1, 2 }",
        "[1, 2].map { break 1, *[2, 3] }",
        "events = []; result = [1, 2].each { |i| events << i; break i if i == 2 }; [result, events]",
        "[1, 2].map { [3, 4].each { break 5 }; 6 }",
        "[1, 2].map { result = while true; break 3; end; result + 1 }",
        "while true; result = [1, 2].each { break 3 }; break result + 1; end",
        "[1].each { begin; raise 'failure'; rescue; break 3; end }",
        "[1].each { begin; break 3; rescue Exception; 4; end }",
        "for i in [1, 2]; break i; end",
        "for i in [1, 2]; for j in [3, 4]; break j; end; break i; end",
        "-> { break 3 }.call",
        "-> { inner = while true; break 3; end; inner + 1 }.call"
      ].each { |source| assert_run(eval(source), source) }
    end

    def test_break_forwarded_block
      assert_run([3, 4, 5], <<~RUBY)
        class CompileTestBreakForwarding
          def invoke
            yield
            :unreachable
          end

          def forward(&block)
            invoke(&block)
            :unreachable
          end

          def call_block(&block)
            block.call
            :unreachable
          end
        end
        object = CompileTestBreakForwarding.new
        [object.invoke { break 3 }, object.forward { break 4 }, object.call_block { break 5 }]
      RUBY
    end

    def test_break_super_block
      assert_run([3, :after], <<~RUBY)
        class CompileTestBreakSuperParent
          def run
            yield
            :unreachable
          end
        end
        class CompileTestBreakSuperChild < CompileTestBreakSuperParent
          def run
            [super { break 3 }, :after]
          end
        end
        CompileTestBreakSuperChild.new.run
      RUBY
    end

    def test_break_escaped_block
      assert_run_raises(LocalJumpError, "proc { break 3 }.call", "break from proc-closure")
      assert_run(:handled, "begin; proc { break 3 }.call; rescue LocalJumpError; :handled; end")
      assert_run(true, "proc { break 3 }.instance_of?(Proc)")
      assert_run([:break, 3], "begin; proc { break 3 }.call; rescue LocalJumpError => e; [e.reason, e.exit_value]; end")
    end

    def test_next_loops
      [
        "i = 0; while i < 3; i += 1; next; end",
        "i = 0; events = []; while i < 3; i += 1; next if i < 2; events << i; end; events",
        "i = 0; events = []; until i == 3; i += 1; next if i < 2; events << i; end; events",
        "i = 0; events = []; begin; i += 1; next if i < 2; events << i; end while i < 3; events",
        "i = 0; events = []; begin; i += 1; next if i < 2; events << i; end until i == 3; events",
        "i = 0; events = []; while i < 2; i += 1; next(events << i); end; events",
        "i = 0; events = []; while i < 2; i += 1; next 1, *(events << i; [2]); end; events",
        "i = 0; events = []; while i < 2; i += 1; j = 0; while j < 2; j += 1; next if j == 1; events << j; end; next if i == 1; events << i; end; events",
        "i = 0; events = []; while i < 2; i += 1; events << [1].map { next 3 }; events << 4; end; events",
        "i = 0; before = $!; events = []; while i < 2; events << $!.equal?(before); i += 1; begin; raise 'failure'; rescue; next; end; end; events"
      ].each { |source| assert_run(eval(source), source) }
    end

    def test_next_blocks
      [
        "[1, 2].map { next }",
        "[1, 2].map { next() }",
        "[1, 2].map { next false }",
        "[1, 2].map { |i| next i + 1 }",
        "[1, 2].map { |i| next i if i == 1; i + 1 }",
        "[1, 2].map { next 1, 2 }",
        "[1, 2].map { next 1, *[2, 3] }",
        "[1, 2].map { next *nil }",
        "[1, 2].map { [3, 4].map { next 5 }; 6 }",
        "proc { next 3 }.call",
        "-> { next 3 }.call",
        "-> { i = 0; while i < 2; i += 1; next; end; i + 1 }.call",
        "[1, 2].map { |i| (raise 'failure') rescue (next i) }",
        "before = $!; result = [1, 2].map { begin; raise 'failure'; rescue; next $!.message; end }; [result, $!.equal?(before)]",
        "events = []; for i in [1, 2, 3]; next if i == 1; events << i; end; events",
        "events = []; for i in [1, 2]; for j in [3, 4]; next if j == 3; events << j; end; next if i == 1; events << i; end; events"
      ].each { |source| assert_run(eval(source), source) }
    end

    def test_next_yielded_block
      assert_run([2, 3, :after], <<~RUBY)
        class CompileTestNextYield
          def invoke
            [yield(1), yield(2), :after]
          end

          def forward(&block)
            invoke(&block)
          end
        end
        CompileTestNextYield.new.forward { |i| next i + 1 }
      RUBY
    end

    def test_redo_loops
      [
        "i = 0; checks = 0; while (checks += 1; i < 3); i += 1; redo if i < 2; end; [i, checks]",
        "i = 0; checks = 0; until (checks += 1; i == 3); i += 1; redo if i < 2; end; [i, checks]",
        "i = 0; checks = 0; begin; i += 1; redo if i < 3; end while (checks += 1; false); [i, checks]",
        "i = 0; checks = 0; begin; i += 1; redo if i < 3; end until (checks += 1; true); [i, checks]",
        "i = 0; events = []; while i < 2; i += 1; j = 0; while j < 2; j += 1; redo if j == 1; events << j; end; redo if i == 1; events << i; end; events",
        "i = 0; before = $!; events = []; while i < 2; events << $!.equal?(before); i += 1; begin; raise 'failure'; rescue; redo if i < 2; end; end; events",
        "i = 0; result = while true; i += 1; redo if i < 2; break i; end; result"
      ].each { |source| assert_run(eval(source), source) }
    end

    def test_redo_blocks
      [
        "attempts = 0; result = [1, 2].map { |value| attempts += 1; redo if attempts == 1; value }; [result, attempts]",
        "attempts = 0; [1].map { |value| attempts += 1; value += 1; redo if attempts < 2; value }",
        "attempts = 0; events = []; proc { |value = (events << :default; 1)| attempts += 1; value += 1; redo if attempts < 2; [value, events] }.call",
        "attempts = 0; proc { |(a, b)| attempts += 1; a += 1; redo if attempts < 2; [a, b] }.call([1, 2])",
        "attempts = 0; ->(value) { attempts += 1; value += 1; redo if attempts < 2; value }.call(1)",
        "attempts = 0; proc { attempts += 1; redo if attempts < 2; attempts }.call",
        "attempts = 0; [1].each { attempts += 1; redo if attempts < 2; break attempts }",
        "attempts = 0; [1].map { attempts += 1; redo if attempts < 2; next attempts }",
        "attempts = 0; [1].map { i = 0; while i < 2; i += 1; redo if i == 1; end; attempts += 1; redo if attempts < 2; attempts }",
        "attempts = 0; before = $!; events = []; result = [1].map { events << $!.equal?(before); attempts += 1; begin; raise 'failure'; rescue; redo if attempts < 2; attempts; end }; [result, events]",
        "attempts = 0; events = []; for value in [1, 2]; attempts += 1; value += 1; redo if attempts == 1; events << value; end; events",
        "attempts = 0; events = []; for a, b in [[1, 2]]; attempts += 1; a += 1; redo if attempts < 2; events << [a, b]; end; events"
      ].each { |source| assert_run(eval(source), source) }
    end

    def test_redo_for_target_assignment
      assert_run([2, [1]], <<~RUBY)
        object = Object.new
        def object.value=(value)
          @assignments ||= []
          @assignments << value
        end
        def object.assignments
          @assignments
        end
        attempts = 0
        for object.value in [1]
          attempts += 1
          redo if attempts < 2
        end
        [attempts, object.assignments]
      RUBY
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
          r0 (default, entry=bb0):
          bb0: [region=r0]
            branch bb1
          bb1: [region=r0]
            trace_line 1
            %0 = load_object(1)
            store_lvar v0, %0
            %1 = load_lvar v0
            %2 = load_object(2)
            %3 = call %1.+(%2)
            return_value %3
      TEXT
      assert_equal(3, vm.run(unit))
    end

    def test_setter_assignment_results
      setup = <<~RUBY
        target = []
        def target.[]=(*arguments, **keywords)
          self << [arguments, keywords]
          :setter_return
        end
        def target.value=(value)
          self << value
          :setter_return
        end
      RUBY
      [
        'target[*[]] = 7',
        'target[*[0]] = 7',
        'target[*[1, 2], 3, 4] = 7',
        'target[0, *[1, 2], 3] = 7',
        'target[*[1], *[2], 3] = 7',
        'target[*nil] = 7',
        'target[*[0]] = nil',
        'target[*[0]] = false',
        'target[*[0]] = [7, 8]',
        'target[*[0]] = *[7, 8]',
        'target[*[0]] = 7, 8',
        'target[*[0]] = {answer: 7}',
        'target[*[0], {answer: 1}] = 7',
        'target[0, {answer: 1}] = 7',
        'target.value = 7',
        'target&.value = 7',
        'target.[]=(*[0, 7])'
      ].each do |assignment|
        source = setup + "result = (#{assignment}); [result, target]"
        assert_run(eval(source), source)
      end
      assert_run(nil, 'target = nil; target&.value = raise("skipped")')
    end

    def test_splatted_setter_assignment_evaluation_order
      assert_run([[:receiver, :indices, :rhs, :setter], true, [:changed]], <<~RUBY)
        events = []
        target = Object.new
        target.define_singleton_method(:[]=) do |*arguments|
          events << :setter
          arguments[-1] << :changed
          :setter_return
        end
        receiver = -> { events << :receiver; target }
        indices = -> { events << :indices; [1, 2] }
        rhs = []
        result = (receiver.call[*indices.call] = (events << :rhs; rhs))
        [events, result.equal?(rhs), result]
      RUBY
    end

    def test_constant_pool_identifier_encoding
      source = <<~RUBY.encode(Encoding::ISO_8859_1)
        # encoding: ISO-8859-1
        module Étage
          def self.café(entrée, clé:, supplément: 1)
            entrée + clé + supplément
          end
        end
        Étage.café(1, clé: 2, supplément: 3)
      RUBY
      unit = Prism.compile(source, freeze: true, raise_error: :plain).value
      scope = Module.new
      frame = Compile::VM::Frame.new(unit.graphs[0], scope, [scope, Object].freeze)
      assert_equal(6, vm.run_frame(frame))
      name = ->(value) { value.encode(Encoding::ISO_8859_1).to_sym }
      assert(scope.const_defined?(name.call("Étage"), false))
      assert_include(unit.graphs.flat_map(&:locals).map(&:name), name.call("entrée"))
      signature = unit.graphs.find { |graph| graph.kind == :def }.signature
      assert_equal([name.call("clé")], signature.required_keywords.keys)
      assert_equal([name.call("supplément")], signature.optional_keywords.keys)
      calls = unit.graphs.flat_map(&:blocks).flat_map(&:insns).select { |insn| insn.kind == :call }
      assert_include(calls.map { |insn| insn.data.name }, name.call("café"))
    end

    def test_statement_effect_context
      [
        '[1, 2]; 7',
        '-> { [1, 2]; 7 }.call',
        'BEGIN { [1, 2] }; 7',
        'true && [1, 2]; 7'
      ].each do |source|
        unit = compile_unit(source)
        assert_equal(7, vm.run(unit), source)
        kinds = unit.graphs.flat_map(&:blocks).flat_map(&:insns).map(&:kind)
        assert_not_include(kinds, :new_array, source)
        assert_not_include(kinds, :new_array_static, source)
      end
      assert_run([1, 2], '[1, 2]')
    end

    def test_discarded_variable_reads
      ["value = 1; value; 7", "-> { it; 7 }.call(1)", "proc { _1; 7 }.call(1)"].each do |source|
        unit = compile_unit(source)
        assert_equal(7, vm.run(unit), source)
        assert_not_include(unit.graphs.flat_map(&:blocks).flat_map(&:insns).map(&:kind), :load_lvar, source)
      end
      unit = compile_unit(%q{/(a)/ =~ "a"; $1; 7})
      assert_equal(7, vm.run(unit))
      kinds = unit.graphs[0].blocks.flat_map(&:insns).map(&:kind)
      assert_not_include(kinds, :load_last_match)
      assert_not_include(kinds, :load_last_match_group)
    end

    def test_assignment_effect_context
      ["value", "@value", "$compile_test_effect_value", "box[0]"].each do |target|
        [
          ["=", "nil", "[1, 2]", [1, 2]],
          ["&&=", "true", "[1, 2]", [1, 2]],
          ["&&=", "false", "raise('rhs ran')", false],
          ["||=", "nil", "[1, 2]", [1, 2]],
          ["||=", "false", "[1, 2]", [1, 2]],
          ["||=", "1", "raise('rhs ran')", 1],
          ["+=", "[1]", "[2]", [1, 2]]
        ].each do |operator, initial, rhs, expected|
          source = "box = []; #{target} = #{initial}; #{target} #{operator} #{rhs}; #{target}"
          unit = compile_unit(source)
          assert_equal(expected, vm.run(unit), source)
          assert(unit.graphs[0].blocks.all? { |block| block.params.empty? }, source)
        end
      end
      assert_run([1, 2], "a, b = [1, 2]; [a, b]")
    ensure
      $compile_test_effect_value = nil
    end

    def test_undef_effect_context
      unit = compile_unit("class CompileTestUndefEffect; def value; 1; end; undef value; end; 7")
      assert_equal(7, vm.run(unit))
      assert_not_include(unit.graphs[1].blocks.flat_map(&:insns).map(&:kind), :load_nil)
      assert_equal(false, CompileTestUndefEffect.method_defined?(:value))
    end

    def test_discarded_super_and_yield_calls
      assert_run([:done, [[1, 2]]], <<~RUBY)
        class CompileTestYieldEffect
          def value
            yield [1, 2]
            :done
          end
        end
        events = []
        result = CompileTestYieldEffect.new.value { |value| events << value }
        [result, events]
      RUBY
      assert_run([:done, [[1, 2]]], <<~RUBY)
        class CompileTestSuperEffectBase
          def value(value)
            yield value
          end
        end
        class CompileTestSuperEffect < CompileTestSuperEffectBase
          def value
            super([1, 2])
            :done
          end
        end
        events = []
        result = CompileTestSuperEffect.new.value { |value| events << value }
        [result, events]
      RUBY
      assert_run_raises(LocalJumpError, "class CompileTestYieldMissingBlock; def value; yield [1, 2]; 7; end; end; CompileTestYieldMissingBlock.new.value")
    end

    def test_control_flow_effect_context
      [
        "if true; [1, 2]; else; [3, 4]; end; 7",
        "if false; [1, 2]; elsif true; [3, 4]; end; 7",
        "unless false; [1, 2]; else; [3, 4]; end; 7",
        "true ? [1, 2] : [3, 4]; 7",
        "false || [1, 2]; 7",
        "([1, 2]); 7",
        "i = 0; while i < 2; i += 1; [1, 2]; end; 7",
        "i = 0; until i == 2; i += 1; [1, 2]; end; 7",
        "while true; break 1; end; 7",
        "until false; break 1; end; 7",
        "while true; begin; break 1; ensure; end; end; 7"
      ].each do |source|
        unit = compile_unit(source)
        assert_equal(7, vm.run(unit), source)
        graph = unit.graphs[0]
        assert(graph.blocks.all? { |block| block.params.empty? }, source)
        assert_not_include(graph.blocks.flat_map(&:insns).map(&:kind), :new_array_static, source)
      end
      assert_run([1, 2], "result = while true; break [1, 2]; end; result")
      assert_run([:break], "events = []; while true; break(events << :break); end; events")
      assert_run([:next, :next], "events = []; i = 0; while i < 2; i += 1; next(events << :next); end; events")
      assert_run([1, 2], "-> { return [1, 2]; 7 }.call")
    end

    def test_rescue_modifier_effect_context
      ["[1, 2] rescue [3, 4]; 7", "raise rescue [3, 4]; 7"].each do |source|
        unit = compile_unit(source)
        assert_equal(7, vm.run(unit), source)
        instructions = unit.graphs[0].blocks.flat_map(&:insns)
        assert_not_include(instructions.map(&:kind), :new_array_static, source)
      end
      assert_run([:body, :rescue], "events = []; (events << :body; raise) rescue events << :rescue; events")
      assert_run([1, 2], "raise rescue [1, 2]")
      assert_run_raises(SyntaxError, "raise SyntaxError rescue 1; 7")
    end

    def test_discarded_construction
      ["{}", "{a: 1}", "1..2", "(1..)", "(..2)", "/abc/", "# frozen_string_literal: true\n" + '"a#{"b"}"', ':"a#{"b"}"', "-> { raise 'body ran' }"].each do |expression|
        source = "#{expression}; 7"
        unit = compile_unit(source)
        assert_equal(7, vm.run(unit), source)
        assert_equal(1, unit.graphs.size, source)
        kinds = unit.graphs[0].blocks.flat_map(&:insns).map(&:kind)
        [:new_hash, :new_hash_static, :new_range_inc, :new_range_exc, :new_string, :new_symbol, :new_block].each do |kind|
          assert_not_include(kinds, kind, source)
        end
      end
      assert_run([:key, :value, :splat], <<~RUBY)
        events = []
        key = Object.new
        key.define_singleton_method(:hash) { raise 'hash ran' }
        splat = Object.new
        splat.define_singleton_method(:to_hash) { raise 'to_hash ran' }
        {(events << :key; key) => (events << :value; 1), **(events << :splat; splat)}
        events
      RUBY
      assert_run([:left, :right], <<~RUBY)
        events = []
        left = Object.new
        left.define_singleton_method(:<=>) { |other| raise 'comparison ran' }
        (events << :left; left)..(events << :right; Object.new)
        events
      RUBY
    end

    def test_discarded_dynamic_interpolation
      ['"a#{value}b"', ':"a#{value}b"', '/a#{value}b/'].each do |expression|
        assert_run([:to_s], <<~RUBY)
          events = []
          value = Object.new
          value.define_singleton_method(:to_s) { events << :to_s; 'x' }
          #{expression}
          events
        RUBY
      end
      assert_run_raises(RegexpError, 'value = "["; /#{value}/; 7')
      assert_run(1, 'count = 0; 2.times { /#{count += 1}/o; nil }; count')
      assert_run_raises(Encoding::CompatibilityError, 'a = "é"; b = "\xFF".b; "#{a}#{b}"; 7')
      assert_run_raises(Encoding::CompatibilityError, 'a = "é"; b = "\xFF".b; :"#{a}#{b}"; 7')
    end

    def test_discarded_command_strings
      scope = Module.new
      commands = []
      scope.define_singleton_method(:`) { |command| commands << command; :ignored }
      graph = compile_unit('`first`; value = "second"; `#{value}`; 7').graphs[0]
      assert_equal(7, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      assert_equal(["first", "second"], commands)
    end

    def test_literal_effect_context
      ["123", "2r", "3i", "nil", "true", '"text"', ":name", "__ENCODING__", "__FILE__", "__LINE__", "self"].each do |literal|
        source = "#{literal}; 7"
        unit = compile_unit(source)
        assert_equal(7, vm.run(unit), source)
        instructions = unit.graphs[0].blocks.flat_map(&:insns)
        assert_equal([7], instructions.select { |insn| insn.kind == :load_object }.map(&:data), source)
        [:load_nil, :load_true, :load_self].each { |kind| assert_not_include(instructions.map(&:kind), kind, source) }
      end

      [[123, "123"], [Rational(2), "2r"], [Complex(0, 3), "3i"], [nil, "nil"], [true, "true"],
        ["text", '"text"'], [:name, ":name"], [Encoding::UTF_8, "__ENCODING__"], [1, "__LINE__"],
        [TOPLEVEL_BINDING.receiver, "self"]].each do |expected, source|
        assert_run(expected, source)
      end
    end

    def test_float_effect_context
      unit = compile_unit("1.5; 7")
      assert_equal(7, vm.run(unit))
      objects = unit.graphs[0].blocks.flat_map(&:insns).select { |insn| insn.kind == :load_object }.map(&:data)
      assert_not_include(objects, 1.5)
      assert_run(1.5, "1.5")
    end

    def test_false_effect_context
      unit = compile_unit("false; 7")
      assert_equal(7, vm.run(unit))
      assert_not_include(unit.graphs[0].blocks.flat_map(&:insns).map(&:kind), :load_false)
      assert_run(false, "false")
      assert_run(false, "false && raise('rhs ran')")
    end

    def test_begin_compilation_context
      [
        'begin; [1, 2]; end; 7',
        'begin; [1, 2]; rescue; end; 7',
        'begin; raise; rescue; [1, 2]; end; 7',
        'begin; raise; rescue; [1, 2]; ensure; [3, 4]; end; 7',
        'begin; [1, 2]; ensure; [3, 4]; end; 7',
        'begin; 1; rescue; 2; else; [1, 2]; end; 7',
        'begin; ensure; end; 7',
        'begin; rescue; else; ensure; end; 7'
      ].each do |source|
        unit = compile_unit(source)
        assert_equal(7, vm.run(unit), source)
        kinds = unit.graphs[0].blocks.flat_map(&:insns).map(&:kind)
        assert_not_include(kinds, :new_array_static, source)
        assert_not_include(kinds, :new_array, source)
      end

      assert_run([1, 2], 'begin; [1, 2]; rescue; end')
      assert_run([1, 2], 'begin; [1, 2]; ensure; [3, 4]; end')
      assert_run([1, 2], 'begin; 1; rescue; 2; else; [1, 2]; end')
      assert_run([1, 2], 'begin; raise; rescue; [1, 2]; ensure; [3, 4]; end')
      assert_run([1, 2], 'events = []; begin; events << 1; ensure; events << 2; end; events')
      assert_run([1, 2, 3], 'events = []; begin; events << 1; raise; rescue; events << 2; ensure; events << 3; end; events')
    end

    def test_discarded_array_preserves_effects_and_splat_coercion
      source = <<~'RUBY'
        events = []
        value = Object.new
        value.define_singleton_method(:to_a) { events << :coerce; [1] }
        [events << :first, *value, events << :last]
        events
      RUBY
      unit = compile_unit(source)
      assert_equal([:first, :coerce, :last], vm.run(unit))
      kinds = unit.graphs[0].blocks.flat_map(&:insns).map(&:kind)
      assert_equal(1, kinds.count(:new_array))
      assert_not_include(kinds, :new_array_static)
      assert_not_include(kinds, :concat_array)
      assert_include(kinds, :coerce_array_to_a)
    end

    def test_call_info_flags
      [
        ["target", true, true, false],
        ["target()", true, false, false],
        ["target(1)", true, false, false],
        ["self.target", true, false, false],
        ["object.target", false, false, false],
        ["object&.target", false, false, false],
        ["target {}", true, false, false],
        ["object.target {}", false, false, false],
        ["target(&block)", true, false, true],
        ["object.target(&nil)", false, false, true],
        ["def caller(&); target(&); end", true, false, true],
        ["def caller(...); target(...); end", true, false, true]
      ].each do |source, ignore_visibility, variable_call, block_argument|
        unit = Prism.compile(source, freeze: true).value
        call = unit.graphs.flat_map(&:blocks).flat_map(&:insns).find do |insn|
          insn.kind == :call && insn.data.name == :target
        end
        assert_equal(ignore_visibility, call.data.ignore_visibility, source)
        assert_equal(variable_call, call.data.variable_call, source)
        assert_equal(block_argument, call.data.block_argument, source)
        assert_equal(block_argument || source.include?("{}"), call.data.block, source)
        assert_predicate(call.data, :frozen?)
      end
    end

    def test_generated_call_info_flags
      [
        "self.target += 1", "self.target &&= 1", "self.target ||= 1",
        "self[0] += 1", "self[0] &&= 1", "self[0] ||= 1",
        "for self.target in []; end", "for self[0] in []; end"
      ].each do |source|
        calls = compile_unit(source).graphs.flat_map(&:blocks).flat_map(&:insns).select do |insn|
          insn.kind == :call && [:target, :target=, :[], :[]=].include?(insn.data.name)
        end
        assert_not_empty(calls, source)
        calls.each do |call|
          assert_equal(true, call.data.ignore_visibility, source)
          assert_equal(false, call.data.variable_call, source)
        end
      end
    end

    def test_super_call_info_flags
      [
        ["def caller; super; end", false],
        ["def caller; super(); end", false],
        ["def caller; super {}; end", false],
        ["def caller; super() {}; end", false],
        ["def caller(&block); super(&block); end", true],
        ["def caller(&); super(&); end", true]
      ].each do |source, block_argument|
        call = compile_unit(source).graphs.flat_map(&:blocks).flat_map(&:insns).find { |insn| insn.kind == :call_super }
        assert_equal(true, call.data.ignore_visibility, source)
        assert_equal(false, call.data.variable_call, source)
        assert_equal(block_argument, call.data.block_argument, source)
      end
    end

    def test_call_info_flags_disasm
      assert_include(compile_unit("target").disasm, "[ignore_visibility, variable_call]")
      assert_include(compile_unit("target(&nil)").disasm, "[ignore_visibility, block_argument]")
      assert_not_include(compile_unit("target {}").disasm, "block_argument")
    end

    def test_call_block_operands
      [
        ["target()", false, 2],
        ["target(1)", false, 3],
        ["target {}", true, 3],
        ["target(1) {}", true, 4],
        ["target(&nil)", true, 3],
        ["target(*values, key: 1, &nil)", true, 5]
      ].each do |source, block, noperands|
        call = compile_unit(source).graphs[0].blocks.flat_map(&:insns).find do |insn|
          insn.kind == :call && insn.data.name == :target
        end
        assert_equal(block, call.data.block, source)
        assert_equal(noperands, call.opnds.length, source)
      end

      assert_run([[1, 2], { key: 3 }, 4], "->(*args, **kwargs, &block) { [args, kwargs, block.call] }.call(*[1, 2], key: 3) { 4 }")
      assert_run(true, "f = ->(&block) { block.nil? }; f.call { 1 }; f.call")
      assert_run(true, "f = ->(&block) { block.nil? }; f.call { 1 }; f.call(&nil)")
    end

    def test_call_visibility
      klass = Class.new do
        def secret(*args, **kwargs, &block)
          [args, kwargs, block&.call]
        end
        private :secret

        def shared = 42
        protected :shared

        def public_send(*) = raise("public_send called")
        def protected_methods(*) = raise("protected_methods called")
        def method(*) = raise("method called")
      end
      receiver = klass.new
      [
        ["secret(1, key: 2) { 3 }", [[1], { key: 2 }, 3]],
        ["self.secret(*[1], key: 2, &-> { 3 })", [[1], { key: 2 }, 3]],
        ["other = self; other.shared", 42],
        ["other = self; other&.shared", 42]
      ].each do |source, expected|
        graph = compile_unit(source).graphs[0]
        assert_equal(expected, vm.run_frame(Compile::VM::Frame.new(graph, receiver, [Object].freeze)))
      end

      graph = compile_unit("other = self; other.secret").graphs[0]
      error = assert_raise(NoMethodError) do
        vm.run_frame(Compile::VM::Frame.new(graph, receiver, [Object].freeze))
      end
      assert_equal(:secret, error.name)
      assert_equal(receiver, error.receiver)

      scope = Module.new
      scope.const_set(:Receiver, receiver)
      ["Receiver.secret", "Receiver.shared", "Receiver.shared {}", "Receiver&.secret"].each do |source|
        graph = compile_unit(source).graphs[0]
        assert_raise(NoMethodError) { vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)) }
      end
    end

    def test_call_visibility_method_missing
      klass = Class.new do
        def secret = :secret
        private :secret

        def method_missing(name, *args, **kwargs, &block)
          [name, args, kwargs, block&.call]
        end
      end
      receiver = klass.new
      source = "other = self; other.secret(1, key: 2) { 3 }"
      graph = compile_unit(source).graphs[0]
      assert_equal([:secret, [1], { key: 2 }, 3], vm.run_frame(Compile::VM::Frame.new(graph, receiver, [Object].freeze)))
    end

    def test_disasm_uses_ids
      local = Compile::Local.new(9, :a)
      insn = Compile::Insn.new(:load_lvar, 0, [0], local)
      blocks = []
      region = Compile::Region.new(7, :default, nil, blocks, 0, nil)
      block = Compile::Block.new(4, [insn], [], region)
      blocks << block
      graph = Compile::Graph.new(3, :program, nil, nil, blocks, [region], [local], 1, 0, Compile::Signature.new([], [], [], nil, [], {}, {}, {}, nil, nil, false, false, false))
      output = Compile::Unit.new([graph]).disasm
      assert_include(output, "g3 (program, scope=g3):")
      assert_include(output, "bb4:")
      assert_include(output, "r7 (default, entry=bb4):")
      assert_include(output, "[region=r7]")
      assert_include(output, "%0 = load_lvar v9")
    end

    def test_disasm_blocks_and_branches
      source = "a = 1; proc { |b, c| if b; c + a; else; a; end }.call(2, 3)"
      unit = Prism.compile(source, freeze: true).value
      output = unit.disasm
      assert_include(output, "g1(%0, %1) [autosplat] (block, parent=g0, scope=g1):")
      assert_include(output, "bb0(%0, %1):")
      assert_match(/call %\d+\.proc &%\d+/, output)
      assert_match(/branchif %\d+ bb\d+ bb\d+/, output)
      assert_match(/branch bb\d+\(%\d+\)/, output)
      assert_not_include(output, "#<Prism::Compile::")
      assert_equal(output, unit.disasm)
      assert_equal(4, vm.run(unit))
    end

    def test_static_literal_collections
      [
        "[nil, true, false]",
        "{nil => true, false => nil, true => false}",
        "{a: nil, b: true, c: false}",
        "[/a/i, /b/mx, __LINE__, __ENCODING__]",
        "{/a/i => nil, __LINE__ => true, __ENCODING__ => false}",
        "[1, 1.5, 2r, 3i, :value, nil, true, false]",
        "[[nil, true], {a: false}, (nil..1)]"
      ].each { |source| assert_run(eval(source), source) }

      [
        ["[nil, true, false, /a/i, __LINE__, __ENCODING__]", :new_array_static],
        ["{a: nil, b: true, c: false, d: /a/i, e: __LINE__, f: __ENCODING__}", :new_hash_static]
      ].each do |source, kind|
        instructions = compile_unit(source).graphs[0].blocks.flat_map(&:insns)
        assert_include(instructions.map(&:kind), kind)
      end
      assert_run([[nil, true, false], [nil, true, false]], "2.times.map { [nil, true, false] }")
      assert_run([false, false], "values = 2.times.map { {a: nil} }; [values[0].equal?(values[1]), values[0].frozen?]")
    end

    def test_static_literal_source_location
      source = "[\n__LINE__,\n__ENCODING__\n]"
      unit = Prism.compile(source, line: 10, raise_error: :plain).value
      assert_equal([11, Encoding::UTF_8], vm.run(unit))
      source = "# frozen_string_literal: true\n[__FILE__]"
      unit = Prism.compile(source, version: "3.4", filepath: "literal.rb", raise_error: :plain).value
      assert_equal(["literal.rb"], vm.run(unit))
      assert_include(unit.graphs[0].blocks.flat_map(&:insns).map(&:kind), :new_array_static)
    end

    def test_static_literal_nil_ranges
      ["nil..1", "1..nil", "nil..nil", "nil...1", "1...nil", "nil...nil", "(..1)", "(1..)", "(...1)", "(1...)"].each do |source|
        assert_run(eval(source), source)
        instructions = compile_unit(source).graphs[0].blocks.flat_map(&:insns)
        assert_not_include(instructions.map(&:kind), :new_range_inc)
        assert_not_include(instructions.map(&:kind), :new_range_exc)
      end
    end

    def test_static_literal_interpolation
      [
        '["#{"a"}"]',
        '{a: "#{"a"}"}',
        '[:"#{"a"}", /#{"a"}/i]',
        '{:"#{"a"}" => /#{"a"}/i}',
        '# frozen_string_literal: true' + "\n" + '["a" "b", "#{"a"}"]'
      ].each { |source| assert_run(eval(source), source) }
      assert_run([true, true], 'values = 2.times.map { ["#{"a"}"] }; [values[0][0].frozen?, values[0][0].equal?(values[1][0])]')
      assert_include(compile_unit('["#{"a"}"]').graphs[0].blocks.flat_map(&:insns).map(&:kind), :new_array_static)
    end

    def test_static_literal_concatenation_encodings
      [
        ["US-ASCII", '["a#{"\xFF"}", "#{"\xFF"}a"]'],
        ["ASCII-8BIT", '["a#{"\u00E9"}", "#{"\u00E9"}a"]'],
        ["ISO-8859-1", '["a#{"\u00E9"}", "#{"\u00E9"}a"]'],
        ["ISO-8859-1", '["a#{"\xE9"}", "#{"\xE9"}a"]'],
        ["US-ASCII", '[:"a#{"\xFF"}", :"#{"\xFF"}a"]'],
        ["ASCII-8BIT", '[:"a#{"\u00E9"}", :"#{"\u00E9"}a"]'],
        ["ISO-8859-1", '[:"a#{"\u00E9"}", :"#{"\xE9"}a"]'],
        ["US-ASCII", '["a" "\xFF", "\xFF" "a"]'],
        ["ASCII-8BIT", '["a" "\u00E9", "\u00E9" "a"]'],
        ["ASCII-8BIT", '["#{"a#{"\u00E9"}"}"]']
      ].each do |encoding, literal|
        source = "# encoding: #{encoding}\n# frozen_string_literal: true\n#{literal}"
        unit = compile_unit(source)
        expected = eval(source)
        actual = vm.run(unit)
        assert_equal(expected, actual)
        assert_equal(expected.map(&:encoding), actual.map(&:encoding))
        assert(actual.all?(&:frozen?))
        instructions = unit.graphs[0].blocks.flat_map(&:insns).map(&:kind)
        assert_include(instructions, :new_array_static)
        assert_not_include(instructions, :new_string)
        assert_not_include(instructions, :new_symbol)
      end
    end

    def test_static_literal_concatenation_encoding_resolution
      fragments = ['""', '"a"', '"\u0061"', '"\u00E9"', '"\xFF"', '"\xC3\xA9"']
      ["US-ASCII", "ASCII-8BIT", "UTF-8", "ISO-8859-1"].each do |encoding|
        fragments.product(fragments).each do |left, right|
          source = "# encoding: #{encoding}\n# frozen_string_literal: true\n" + '["#{' + left + '}#{' + right + '}"]'
          begin
            expected = eval(source).first
          rescue Encoding::CompatibilityError
            assert_raise(Encoding::CompatibilityError, source) { compile_unit(source) }
            next
          end

          value = vm.run(compile_unit(source)).first
          assert_equal([expected.bytes, expected.encoding, expected.valid_encoding?], [value.bytes, value.encoding, value.valid_encoding?], source)
        end
      end
    end

    def test_static_literal_concatenation_incompatible_encodings
      ['["\xFF#{"\u00E9"}"]', '[:"\xFF#{"\u00E9"}"]'].each do |literal|
        source = "# encoding: US-ASCII\n# frozen_string_literal: true\n#{literal}"
        assert_raise(Encoding::CompatibilityError) { eval(source) }
        assert_raise(Encoding::CompatibilityError) { compile_unit(source) }
      end
    end

    def test_signature_arity
      ["", "a", "a, b", "a = 1", "*a", "a, *b, c", "a = 1, b", "a:", "a:, b: 1", "a: 1", "a:, **kw", "a: 1, **kw", "**kw", "**nil", "&block", "...", "a, ...", "(a, b)"].each do |parameters|
        source = "def value(#{parameters}); end"
        klass = Class.new
        klass.class_eval(source)
        graph = compile_unit(source).graphs.find { |candidate| candidate.kind == :def }
        assert_equal(klass.instance_method(:value).arity, graph.signature.arity, parameters)
      end
    end

    def test_defined_effect_context
      scope = Module.new
      events = []
      receiver = Object.new
      receiver.define_singleton_method(:foo) { :called }
      scope.define_singleton_method(:side_effect) { events << :receiver; receiver }

      [
        "defined?(side_effect.foo); nil",
        "(defined?(side_effect.foo)); nil",
        "if true; defined?(side_effect.foo); end; nil",
        "unless false; defined?(side_effect.foo); end; nil",
        "true ? defined?(side_effect.foo) : nil; nil",
        "false || defined?(side_effect.foo); nil",
        "i = 0; while i < 1; i += 1; defined?(side_effect.foo); end; nil",
        "defined?(side_effect.foo) rescue nil; nil",
        "raise rescue defined?(side_effect.foo); nil",
        "[defined?(side_effect.foo)]; nil",
        "begin; defined?(side_effect.foo); rescue; end; nil",
        "begin; raise; rescue; defined?(side_effect.foo); end; nil",
        "begin; ensure; defined?(side_effect.foo); end; nil"
      ].each do |source|
        graph = compile_unit(source).graphs[0]
        assert_nil(vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
        assert_empty(events, source)
      end

      graph = compile_unit("defined?(side_effect.foo); nil").graphs[0]
      assert_not_include(graph.blocks.flat_map(&:insns).map(&:kind), :call)
      graph = compile_unit("defined?(side_effect.foo)").graphs[0]
      assert_equal("method", vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      assert_equal([:receiver], events)
    end

    def test_defined_method_signatures_across_vms
      scope = Module.new
      first_vm = Compile::VM.new
      graph = compile_unit("class Item; def respond_to?(name); name == :virtual; end; end; Item.new").graphs[0]
      receiver = first_vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze))
      query = compile_unit("defined?(virtual)").graphs[0]
      GC.start
      assert_equal("method", vm.run_frame(Compile::VM::Frame.new(query, receiver, [scope, Object].freeze)))

      klass = scope.const_get(:Item)
      klass.class_eval("alias saved_query respond_to?")
      replacement = compile_unit("class Item; def respond_to?(name, private); false; end; end").graphs[0]
      capture_warnings { first_vm.run_frame(Compile::VM::Frame.new(replacement, scope, [scope, Object].freeze)) }
      GC.start
      assert_nil(vm.run_frame(Compile::VM::Frame.new(query, receiver, [scope, Object].freeze)))
      assert_equal(1, Compile::VM::MethodDefinition.arity(klass.instance_method(:saved_query)))
      assert_equal(2, Compile::VM::MethodDefinition.arity(klass.instance_method(:respond_to?)))

      capture_warnings { klass.define_method(:respond_to?) { |name| name == :virtual } }
      assert_equal("method", vm.run_frame(Compile::VM::Frame.new(query, receiver, [scope, Object].freeze)))
    end

    def test_defined_constant_paths
      [
        "defined?(::Object)",
        "defined?(::CompileDefinedPathMissing)",
        "defined?(Object::Object)",
        "defined?(String::Object)",
        "defined?(CompileDefinedPathMissing::Value)",
        "defined?(nil::Value)",
        "defined?(1::Value)",
        "defined?((raise Exception, 'suppressed')::Value)",
        "defined?([::Object, Object::Object])",
        "defined?({a: CompileDefinedPathMissing::Value})",
        "defined?(puts(CompileDefinedPathMissing::Value))",
        "defined?(Object::Object.new)",
        "defined?((Object::Object)::Missing)",
        "defined?((begin; ::Object; end)::Object)"
      ].each { |source| assert_run(eval(source), source) }
    end

    def test_defined_constant_path_lookup
      scope = Module.new
      parent = Class.new
      parent.const_set(:Inherited, false)
      namespace = Class.new(parent)
      namespace.const_set(:Value, nil)
      namespace.const_set(:Private, 1)
      namespace.private_constant(:Private)
      nested = Module.new
      nested.const_set(:Value, 2)
      namespace.const_set(:Nested, nested)
      namespace.autoload(:Lazy, "/must/not/be/loaded")
      scope.const_set(:Namespace, namespace)
      events = []
      [scope, namespace, parent, nested].each do |owner|
        [:ancestors, :const_defined?, :const_get, :constants, :const_missing].each do |name|
          owner.define_singleton_method(name) { |*args| events << [name, args]; raise "reflection method called" }
        end
      end
      ["defined?(Namespace::Value)", "defined?(Namespace::Private)", "defined?(Namespace::Inherited)", "defined?(Namespace::Missing)", "defined?(Namespace::Nested::Value)", "defined?(Namespace::Missing::Value)", "defined?(Namespace::Lazy)", "defined?(Namespace::Lazy::Value)"].each do |source|
        events.clear
        expected = scope.module_eval(source)
        graph = compile_unit(source).graphs[0]
        actual = vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze))
        assert_equal(expected, actual, source)
        assert_empty(events, source)
      end
      assert_equal("/must/not/be/loaded", namespace.autoload?(:Lazy))
    end

    def test_defined_constant_path_evaluation
      scope = Module.new
      events = []
      namespace = Module.new
      namespace.const_set(:Value, 1)
      nested = Module.new
      nested.const_set(:Value, 2)
      namespace.const_set(:Nested, nested)
      namespace.define_singleton_method(:next) { events << :next; nested }
      scope.define_singleton_method(:namespace) { events << :namespace; namespace }
      scope.define_singleton_method(:broken) { events << :broken; raise Exception, "receiver failed" }
      ["defined?(namespace()::Value)", "defined?(namespace()::Missing)", "defined?(namespace()::Nested::Value)", "defined?(namespace().next::Value)", "defined?(broken::Value)", "defined?(missing::Value)", "defined?(namespace()::Value.to_s)", "defined?(namespace()::Missing.to_s)"].each do |source|
        events.clear
        expected = scope.module_eval(source)
        native_events = events.dup
        events.clear
        graph = compile_unit(source).graphs[0]
        assert_equal(expected, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)), source)
        assert_equal(native_events, events, source)
      end
    end

    def test_defined_constant_path_parent_autoload
      [:native, :interpreted].each do |mode|
        scope = Module.new
        Object.const_set(:CompileDefinedPathAutoload, scope)
        Tempfile.create(["compile_defined_path_autoload", ".rb"]) do |file|
          file.write("CompileDefinedPathAutoload::Parent = Module.new; CompileDefinedPathAutoload::Parent.const_set(:Value, false)")
          file.flush
          scope.autoload(:Parent, file.path)
          source = "defined?(CompileDefinedPathAutoload::Parent::Value)"
          result = if mode == :native
            eval(source)
          else
            vm.run(compile_unit(source))
          end
          assert_equal("constant", result)
          assert_nil(scope.autoload?(:Parent))
        end
        Object.send(:remove_const, :CompileDefinedPathAutoload)
      end
    ensure
      Object.send(:remove_const, :CompileDefinedPathAutoload) if Object.const_defined?(:CompileDefinedPathAutoload, false)
    end

    def test_defined_calls
      [
        "defined?(puts)",
        "defined?(compile_defined_missing)",
        "defined?(1.to_s)",
        "value = Object.new; def value.respond_to?(name); name == :virtual; end; value.instance_eval { defined?(virtual) }",
        "value = Object.new; def value.respond_to?(a, b, c); end; begin; value.instance_eval { defined?(virtual) }; rescue ArgumentError => error; error.message; end",
        "begin; raise 'outer'; rescue; previous = $!; result = defined?((raise 'inner').work); [result, $!.equal?(previous)]; end",
        "defined?(:value.to_s)",
        "defined?(nil.to_s)",
        "defined?(nil&.to_s)",
        "defined?(nil&.compile_defined_missing)",
        "defined?(self.puts)",
        "defined?(puts(raise('must not run')))",
        "defined?(puts(CompileDefinedCallMissing))",
        "defined?(puts(*nil, **nil, &raise('must not run')))",
        "defined?(compile_defined_missing { raise('must not run') })",
        "defined?(CompileDefinedCallMissing.foo { raise('must not run') })",
        "defined?([1.to_s, puts])",
        "defined?({a: compile_defined_missing})",
        "value = Object.new; def value.work; raise 'must not run'; end; defined?(value.work)",
        "value = Object.new; def value.work=(*); raise 'must not run'; end; defined?(value.work = raise('must not run'))",
        "value = Object.new; def value.work; end; value.singleton_class.send(:private, :work); defined?(value.work)",
        "defined?((raise Exception, 'suppressed').work)",
        "def compile_defined_forward(...); defined?(puts(...)); end; compile_defined_forward(1)",
        "def compile_defined_forward(*, **, &); defined?(puts(*, **, &)); end; compile_defined_forward(1, a: 2)"
      ].each { |source| capture_warnings { assert_run(eval(source), source) } }
    end

    def test_defined_call_receivers
      scope = Module.new
      events = []
      leaf = Object.new
      leaf.define_singleton_method(:finish) { |*| raise "final method called" }
      middle = Object.new
      middle.define_singleton_method(:next) { |*| events << :next; leaf }
      middle.define_singleton_method(:finish) { |*| raise "final method called" }
      scope.define_singleton_method(:value) { |*| events << :value; middle }
      scope.define_singleton_method(:argument) { events << :argument; :argument }
      scope.define_singleton_method(:broken) { events << :broken; raise Exception, "receiver failed" }
      sources = [
        "defined?(value.next.finish)",
        "defined?(value.next.next.finish)",
        "defined?(value.finish(argument))",
        "defined?(value.finish(missing_argument))",
        "defined?(value(argument).next(argument).finish(argument))",
        "defined?(value.missing(argument))",
        "defined?(missing_receiver.finish)",
        "defined?(broken.finish)",
        "defined?(value { raise('must not run') }.finish)",
        "defined?(value.missing { raise('must not run') })"
      ]
      sources.each do |source|
        events.clear
        expected = scope.module_eval(source)
        native_events = events.dup
        events.clear
        graph = compile_unit(source).graphs[0]
        actual = vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze))
        assert_equal(expected, actual, source)
        assert_equal(native_events, events, source)
      end
    end

    def test_defined_call_hooks
      scope = Module.new
      events = []
      query_result = false
      target = Object.new
      target.define_singleton_method(:known) { raise "final method called" }
      target.define_singleton_method(:respond_to?) { |*args| events << [:respond_to?, *args]; query_result }
      target.define_singleton_method(:respond_to_missing?) do |name, include_private|
        events << [:respond_to_missing?, name, include_private]
        raise "hook failed" if name == :broken
        name == :virtual
      end
      target.define_singleton_method(:method_missing) { |*args| events << [:method_missing, *args]; :unexpected }
      scope.const_set(:Target, target)
      scope.define_singleton_method(:respond_to_missing?) do |name, include_private|
        events << [:implicit_missing, name, include_private]
        raise "hook failed" if name == :broken
        name == :virtual
      end
      [false, true].each do |result|
        query_result = result
        ["defined?(Target.known)", "defined?(Target.virtual)", "defined?(Target.missing)", "defined?(Target.broken)", "defined?(virtual)", "defined?(missing)", "defined?(broken)", "defined?(broken(nil))"].each do |source|
          events.clear
          expected = begin
            scope.module_eval(source)
          rescue RuntimeError => error
            [error.class, error.message]
          end
          native_events = events.dup
          events.clear
          graph = compile_unit(source).graphs[0]
          actual = begin
            vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze))
          rescue RuntimeError => error
            [error.class, error.message]
          end
          assert_equal(expected, actual, source)
          assert_equal(native_events, events, source)
        end
      end
    end

    def test_defined_call_visibility
      source = <<~RUBY_SOURCE
        class CompileDefinedCallVisibility
          private def hidden; raise 'called'; end
          protected def guarded; raise 'called'; end
          def check(other)
            [defined?(hidden), defined?(self.hidden), defined?(other.hidden), defined?(guarded), defined?(self.guarded), defined?(other.guarded)]
          end
        end
        value = CompileDefinedCallVisibility.new
        [value.check(value), defined?(value.guarded)]
      RUBY_SOURCE
      capture_warnings { assert_run(eval(source), source) }
      assert_run(nil, "value = BasicObject.new; defined?(value.missing)")
    end

    def test_method_definition_effect_context
      ["def example; [1, 2]; end; 7", "def self.example; [1, 2]; end; 7"].each do |source|
        unit = compile_unit(source)
        objects = unit.graphs[0].blocks.flat_map(&:insns).select { |insn| insn.kind == :load_object }.map(&:data)
        assert_not_include(objects, :example, source)
      end
      assert_run([1, 2], "class CompileTestDefEffect; def value; [1, 2]; end; end; CompileTestDefEffect.new.value")
      assert_run([1, 2], "class CompileTestSingletonDefEffect; def self.value; [1, 2]; end; end; CompileTestSingletonDefEffect.value")
      assert_run(:value, "class CompileTestDefValue; def value; end; end")
      assert_run(:value, "class CompileTestSingletonDefValue; def self.value; end; end")
      assert_run([:receiver], "events = []; receiver = Object.new; def (receiver.tap { events << :receiver }).value; 1; end; events")
    end

    def test_method_definition_signatures
      scope = Module.new
      first_vm = Compile::VM.new
      source = "class Item; def query(name); name; end; alias saved_query query; end"
      graph = compile_unit(source).graphs[0]
      first_vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze))
      klass = scope.const_get(:Item)
      GC.start
      assert_equal(1, Compile::VM::MethodDefinition.arity(klass.instance_method(:query)))

      source = "class Item; def query(name, private); false; end; end"
      graph = compile_unit(source).graphs[0]
      capture_warnings { vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)) }
      GC.start
      assert_equal(1, Compile::VM::MethodDefinition.arity(klass.instance_method(:saved_query)))
      assert_equal(2, Compile::VM::MethodDefinition.arity(klass.instance_method(:query)))
      capture_warnings { klass.define_method(:query) { |name| name } }
      assert_equal(1, Compile::VM::MethodDefinition.arity(klass.instance_method(:query)))
    end

    def test_defined_method_instructions
      receiver = Object.new
      receiver.define_singleton_method(:work) { raise "method called" }
      receiver.define_singleton_method(:hidden) { raise "method called" }
      receiver.singleton_class.send(:private, :hidden)
      [
        [:defined_explicit_method, :work, true],
        [:defined_explicit_method, :hidden, false],
        [:defined_explicit_method, :missing, false],
        [:defined_implicit_method, :work, true],
        [:defined_implicit_method, :hidden, true],
        [:defined_implicit_method, :missing, false]
      ].each do |kind, name, expected|
        insns = [Compile::Insn.new(:load_object, 0, [0], receiver), Compile::Insn.new(kind, 0, [1, 0], name), Compile::Insn.new(:return_value, 0, [1], nil)]
        assert_equal(expected, run_instructions(insns, [nil], 2))
      end
    end

    def test_defined_containers
      [
        "defined?([])",
        "defined?({})",
        "defined?([nil, false, true])",
        "defined?(%w[a b])",
        "defined?(%i[a b])",
        "defined?([CompileDefinedContainerMissing])",
        "defined?([@compile_defined_container_missing, 1])",
        "defined?([1, $compile_defined_container_missing])",
        "defined?([[nil], {a: [false, true]}])",
        "defined?([{a: [CompileDefinedContainerMissing]}])",
        "defined?({nil => false, true => nil})",
        "defined?({a: CompileDefinedContainerMissing})",
        "defined?({CompileDefinedContainerMissing => 1})",
        "a = nil; defined?({a:})",
        "defined?([value = 1]); value",
        "defined?({a: value = 1}); value",
        "defined?([*(nil)])",
        "defined?([*CompileDefinedContainerMissing])",
        "defined?({**nil})",
        "defined?({**CompileDefinedContainerMissing})",
        "defined?([*(begin; nil; end)])",
        "defined?([{a: [*nil]}, **{}])",
        "defined?([(raise('must not run') rescue nil)])",
        "defined?([value = raise('must not run')])",
        "def compile_defined_splat(*); defined?([*]); end; compile_defined_splat(1, 2)",
        "def compile_defined_keywords(**); defined?({**}); end; compile_defined_keywords(a: 1)"
      ].each { |source| capture_warnings { assert_run(eval(source), source) } }
    end

    def test_defined_containers_skip_conversions
      [
        "o = Object.new; def o.to_a; raise 'to_a called'; end; defined?([*o])",
        "o = Object.new; def o.to_hash; raise 'to_hash called'; end; defined?({**o})",
        "o = Object.new; def o.hash; raise 'hash called'; end; defined?({o => 1})",
        "o = Object.new; def o.to_a; raise 'to_a called'; end; defined?([{a: [*o]}])"
      ].each { |source| assert_run(eval(source), source) }
    end

    def test_defined_containers_do_not_construct_values
      ["defined?([nil, true])", "defined?({a: nil})", "a = nil; defined?({a:, **a})"].each do |source|
        kinds = compile_unit(source).graphs[0].blocks.flat_map(&:insns).map(&:kind)
        [:new_array, :new_array_static, :new_hash, :new_hash_static, :coerce_array_to_a, :coerce_hash].each do |kind|
          assert_not_include(kinds, kind, source)
        end
      end
    end

    def test_defined_runtime_variables
      [
        "o = Object.new; o.instance_eval { defined?(@missing) }",
        "o = Object.new; o.instance_eval { @value = nil; defined?(@value) }",
        "o = Object.new; def o.instance_variable_defined?(*); raise 'must not run'; end; o.instance_eval { @value = false; defined?(@value) }",
        "defined?($compile_defined_state_missing)",
        "$compile_defined_state_value = nil; defined?($compile_defined_state_value)",
        "$compile_defined_state_value = false; defined?($compile_defined_state_value)",
        "class CompileDefinedStateCvar; defined?(@@missing); end",
        "class CompileDefinedStateCvar; @@value = nil; defined?(@@value); end",
        "class CompileDefinedStateCvar; @@value = false; proc { defined?(@@value) }.call; end",
        "defined?(@@compile_defined_state_missing)",
        "defined?(CompileDefinedStateMissing)",
        "class CompileDefinedStateConst; Value = nil; defined?(Value); end",
        "class CompileDefinedStateConst; private_constant :Value; defined?(Value); end"
      ].each { |source| capture_warnings { assert_run(eval(source), source) } }
    end

    def test_defined_bare_constant_lookup
      scope = Module.new
      scope.const_set(:Value, false)
      scope.autoload(:LazyValue, "/must/not/be/loaded")
      scope.define_singleton_method(:const_defined?) { |*| raise "const_defined? called" }
      scope.define_singleton_method(:const_missing) { |*| raise "const_missing called" }
      ["Value", "LazyValue", "MissingValue"].each do |name|
        source = "defined?(#{name})"
        graph = compile_unit(source).graphs[0]
        assert_equal(scope.module_eval(source), vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      end
      assert_equal("/must/not/be/loaded", scope.autoload?(:LazyValue))
    end

    def test_defined_yield
      [
        "defined?(yield)",
        "def compile_defined_yield; defined?(yield raise('must not run')); end; compile_defined_yield",
        "def compile_defined_yield; defined?(yield raise('must not run')); end; compile_defined_yield { raise('block must not run') }",
        "def compile_defined_yield; proc { defined?(yield) }.call; end; compile_defined_yield { 1 }"
      ].each { |source| capture_warnings { assert_run(eval(source), source) } }
    end

    def test_defined_super
      [
        "defined?(super)",
        "defined?(super())",
        "defined?(super {})",
        "class CompileDefinedSuperBase; end; class CompileDefinedSuperChild < CompileDefinedSuperBase; def value; defined?(super); end; end; CompileDefinedSuperChild.new.value",
        "class CompileDefinedSuperBase; def value; raise 'must not run'; end; end; class CompileDefinedSuperChild < CompileDefinedSuperBase; def value; defined?(super); end; end; CompileDefinedSuperChild.new.value",
        "class CompileDefinedSuperChild; def value; defined?(super(raise('must not run'), &raise('must not run'))); end; end; CompileDefinedSuperChild.new.value",
        "class CompileDefinedSuperChild; def value; proc { defined?(super()) }.call; end; end; CompileDefinedSuperChild.new.value",
        "class CompileDefinedSuperChild; alias other value; end; CompileDefinedSuperChild.new.other",
        "class CompileDefinedSuperBase; def self.value; end; end; class CompileDefinedSuperChild; def self.value; defined?(super); end; end; CompileDefinedSuperChild.value"
      ].each { |source| capture_warnings { assert_run(eval(source), source) } }
    end

    def test_defined_regexp_references
      [
        "/a/ =~ ''; [defined?($&), defined?($`), defined?($'), defined?($+), defined?($1), defined?($2)]",
        "/(a)?(b)/ =~ 'b'; [defined?($&), defined?($`), defined?($'), defined?($+), defined?($1), defined?($2), defined?($3)]",
        "/()/ =~ ''; [defined?($&), defined?($1), defined?($+)]",
        "/(a)/ =~ 'a'; /b/ =~ 'a'; [defined?($&), defined?($1), defined?($+)]"
      ].each do |source|
        expected = eval(source, TOPLEVEL_BINDING)
        assert_run(expected, source)
      end
    end

    def test_defined_locals
      [
        "value = nil; defined?(value)",
        "if false; value = 1; end; defined?(value)",
        "value = 1; proc { defined?(value) }.call",
        "[1].map { defined?(it) }",
        "[1].map { defined?(_1) }",
        "->(value) { defined?(value) }.call(1)",
        "defined?(value = raise('must not run'))"
      ].each { |source| assert_run(eval(source), source) }
    end

    def test_defined_result_strings_are_frozen
      source = <<~RUBY
        # frozen_string_literal: false
        local = 1
        [defined?(nil), defined?(false), defined?(true), defined?(self),
         defined?(local), defined?(local = 2), defined?(puts), defined?(Object),
         defined?(1 + 2), defined?([1, 2])]
      RUBY
      unit = compile_unit(source)
      values = vm.run(unit)
      assert_equal(eval(source), values)
      values.each { |value| assert_predicate(value, :frozen?) }
      assert_equal(values, vm.run(unit))
      assert_run_raises(FrozenError, '(defined?(nil)).replace("changed")')
      assert_run(nil, 'defined?(missing_defined_result_method)')
    end

    def test_back_reference_compilation_context
      assert_run(["a", "x", "y", "a"], %q{/(a)/ =~ "xay"; [$&, $`, $', $+]})
      unit = compile_unit(%q{/(a)/ =~ "xay"; $&; $`; $'; $+; $1})
      assert_equal("a", vm.run(unit))
      kinds = unit.graphs[0].blocks.flat_map(&:insns).map(&:kind)
      assert_equal(1, kinds.count(:load_last_match))
      [:load_last_match_match, :load_last_match_pre, :load_last_match_post, :load_last_match_paren].each do |kind|
        assert_not_include(kinds, kind)
      end
    end

    def test_defined_wrappers
      [
        "defined?(())",
        "defined?((nil))",
        "defined?(((true)))",
        "value = 1; defined?((value))",
        "value = 1; defined?((value;))",
        "defined?((raise('first'); raise('second')))",
        "defined?(begin; end)",
        "defined?(begin; nil; end)",
        "value = 1; defined?(begin; value; end)",
        "defined?(begin; raise('first'); raise('second'); end)",
        "defined?(begin; raise('body'); rescue; raise('rescue'); end)",
        "defined?(begin; raise('body'); ensure; raise('ensure'); end)",
        "defined?(begin; raise('body'); rescue; raise('rescue'); else; raise('else'); end)",
        "defined?((begin; (false); end))"
      ].each { |source| assert_run(eval(source), source) }
    end

    def test_defined_shareable_constant
      [:literal, :experimental_copy, :experimental_everything].each do |mode|
        ["Value = raise('must not run')", "Value ||= raise('must not run')", "Value += raise('must not run')"].each do |write|
          source = "# shareable_constant_value: #{mode}\ndefined?(#{write})"
          scope = Module.new
          graph = compile_unit(source).graphs[0]
          assert_equal("assignment", scope.module_eval(source))
          assert_equal("assignment", vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
          assert_equal(false, scope.const_defined?(:Value, false))
        end
      end
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

    def test_vm_compilation_warnings_across_files
      machine = Compile::VM.new
      output = capture_warnings do
        first = machine.compile("{a: 1, a: 2}", "first.rb")
        second = machine.compile("\n{b: 3, b: 4}", "second.rb")
        assert_equal({a: 2}, machine.run(first))
        assert_equal({b: 4}, machine.run(second))
      end
      assert_equal(<<~TEXT, output)
        first.rb:1: warning: key :a is duplicated and overwritten on line 1
        second.rb:2: warning: key :b is duplicated and overwritten on line 2
      TEXT
    end

    def test_compile_and_interpret_cli_warnings
      cli = File.expand_path("../../../bin/prism", __dir__)
      ["compile", "interpret"].each do |command|
        stdout, stderr, status = Open3.capture3(RbConfig.ruby, cli, command, "-e", "\n{a: 1, a: 2}")
        assert_predicate(status, :success?, stderr)
        assert_equal("-e:2: warning: key :a is duplicated and overwritten on line 2\n", stderr)
        assert_empty(stdout) if command == "interpret"
      end
    end

    def test_interpret_cli_warning_levels
      cli = File.expand_path("../../../bin/prism", __dir__)
      source = "unused = 1; puts :done"
      [[], ["-w"], ["-W0"]].each do |flags|
        stdout, stderr, status = Open3.capture3(RbConfig.ruby, *flags, cli, "interpret", "-e", source)
        assert_predicate(status, :success?, stderr)
        assert_equal("done\n", stdout)
        if flags == ["-w"]
          assert_include(stderr, "-e:1: warning: assigned but unused variable - unused\n")
        else
          assert_empty(stderr)
        end
      end
      _, stderr, status = Open3.capture3(RbConfig.ruby, "-W0", cli, "interpret", "-e", "{a: 1, a: 2}")
      assert_predicate(status, :success?, stderr)
      assert_empty(stderr)
    end

    def test_coerce_array_to_ary_instruction
      insns = [Compile::Insn.new(:coerce_array_to_ary, 0, [1, 0], nil), Compile::Insn.new(:return_value, 0, [1], nil)]
      array = [1, 2]
      assert_same(array, run_instructions(insns, [array], 2))
      assert_equal([nil], run_instructions(insns, [nil], 2))
      assert_equal([1], run_instructions(insns, [1], 2))
      item = Object.new
      converted = array
      item.define_singleton_method(:to_ary) { converted }
      assert_same(array, run_instructions(insns, [item], 2))
      converted = nil
      assert_equal([item], run_instructions(insns, [item], 2))
      converted = 1
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

    def test_block_local_variables
      [
        [[nil, nil], "proc { |; a, b| [a, b] }.call(1, 2)"],
        [[[nil, nil], 1, 2], "a = 1; b = 2; result = proc { |; a, b| [a, b] }.call; [result, a, b]"],
        [[1, 1], "p = proc { |; a| a ||= 0; a += 1 }; [p.call, p.call]"],
        [[2, 3, 2], "factory = proc { |; a| a = 1; proc { a += 1 } }; p = factory.call; q = factory.call; [p.call, p.call, q.call]"],
        [[1, [2], 3, nil], "proc { |a, *rest, b; c| [a, rest, b, c] }.call(1, 2, 3)"]
      ].each { |expected, source| assert_run(expected, source) }
    end

    def test_block_local_variables_metadata
      graph = compile_unit("proc { |; a, b| [a, b] }").graphs[1]
      assert_equal([:a, :b], graph.locals.map(&:name))
      assert_empty(graph.signature.requireds)
      assert_nil(graph.signature.rest)
      assert_empty(graph.signature.posts)
      assert_empty(graph.blocks[0].params)
      assert_not_include(graph.blocks[0].insns.map(&:kind), :store_lvar)
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

    def test_destructured_block_parameters
      [
        [[1, 2], "proc { |(a, b)| [a, b] }.call([1, 2])"],
        [[1, nil], "proc { |(a, b)| [a, b] }.call(1, 2)"],
        [[nil, nil], "proc { |(a, b)| [a, b] }.call"],
        [[[1, 2], nil], "proc { |(a, b)| [a, b] }.call([[1, 2]])"],
        [[1, 2, 3], "proc { |(a, b), c| [a, b, c] }.call([[1, 2], 3])"],
        [[1, 2, 3], "proc { |(a, (b, c))| [a, b, c] }.call([1, [2, 3]])"],
        [[1, [], 2, nil], "proc { |(a, *b, c, d)| [a, b, c, d] }.call([1, 2])"],
        [[1, 4], "proc { |(a, *, b)| [a, b] }.call([1, 2, 3, 4])"],
        [[1, 2], "proc { |(*a)| a }.call([1, 2])"],
        [[1, 2, [3]], "proc { |(a, b), *rest| [a, b, rest] }.call([[1, 2], 3])"],
        [[[1], 2, 3], "proc { |*rest, (a, b)| [rest, a, b] }.call(1, [2, 3])"],
        [[[], 1, nil, nil, nil], "proc { |*rest, (a, b), (c, d)| [rest, a, b, c, d] }.call(1)"],
        [[1, 2, 3], "proc { |(a, b), c = (a || 3), x:| [a, b, c] }.call([1, 2], x: 1)"],
        [[1, 2], "proc { |(a, b)| proc { [a, b] }.call }.call([1, 2])"],
        [[[1, [2, 3]], [1, 2]], "input = [1, 2]; result = proc { |(a, *b)| b << 3; [a, b] }.call(input); [result, input]"]
      ].each { |expected, source| assert_run(expected, source) }
    end

    def test_destructured_method_parameters
      vm.run(compile_unit("class CompileTestDestructured; def value((a, b), *rest, (c, d)); [a, b, rest, c, d]; end; end"))
      source = "CompileTestDestructured.new"
      assert_run([1, 2, [], 3, 4], "#{source}.value([1, 2], [3, 4])")
      assert_run([1, nil, [2], 3, nil], "#{source}.value(1, 2, 3)")
      assert_run_raises(ArgumentError, "#{source}.value([1, 2])", "wrong number of arguments (given 1, expected 2+)")
      assert_run([1, 2, 3], "class CompileTestDestructuredDefault; def value((a, b), c = (a || 3)); [a, b, c]; end; end; CompileTestDestructuredDefault.new.value([1, 2])")
      assert_run([1, 2, [3], 4], "object = Object.new; def object.value((a, (b, *c, d))); [a, b, c, d]; end; object.value([1, [2, 3, 4]])")
    end

    def test_destructured_parameter_conversion
      scope = Module.new
      events = []
      converted = [1, 2]
      value = Object.new
      value.define_singleton_method(:to_ary) { events << :convert; converted }
      scope.const_set(:Value, value)
      scope.const_set(:Events, events)
      graph = compile_unit("proc { |(a, b), c = (Events << :default; 3), x:| Events << :body; [a, b, c] }.call(Value, x: 1)").graphs[0]
      frame = -> { Compile::VM::Frame.new(graph, scope, [scope, Object].freeze) }
      assert_equal([1, 2, 3], vm.run_frame(frame.call))
      assert_equal([:default, :convert, :body], events)
      events.clear
      converted = nil
      assert_equal([value, nil, 3], vm.run_frame(frame.call))
      converted = 1
      assert_raise(TypeError) { vm.run_frame(frame.call) }
    end

    def test_parameter_local_layout
      source = "def value(a, (b, c), d = 4, *rest, e, opt: 5, req:, **kwargs, &block); extra = 6; [a, b, c, d, rest, e, opt, req, kwargs, block.call, extra]; end"
      graph = Prism.compile(source, freeze: true).value.graphs[1]
      signature = graph.signature
      assert_equal([:a, :"<destructured>", :d, :rest, :e, :req, :opt, :kwargs, :block, :b, :c, :extra], graph.locals.map(&:name))
      inputs = [*signature.requireds, *signature.optionals, signature.rest, *signature.posts, *signature.required_keywords.values, *signature.optional_keywords.values, signature.keyword_rest, signature.block]
      stores = graph.blocks[0].insns.select { |insn| insn.kind == :store_lvar }.take(inputs.length)
      assert_equal(inputs, stores.map { |insn| insn.opnds[0] })
      assert_equal(graph.locals.take(inputs.length), stores.map(&:data))
      tuple = [2, 3]
      callback = proc { 9 }
      frame = Compile::VM::Frame.new(graph, TOPLEVEL_BINDING.receiver, [Object].freeze, &callback)
      assert_equal([1, 2, 3, 4, [5], 6, 5, 7, { z: 8 }, 9, 6], vm.run_frame(frame, [1, tuple, 4, 5, 6], { req: 7, z: 8 }))
      assert_same(tuple, frame.locals[graph.locals[1].id])
      assert_same(callback, frame.locals[graph.locals[8].id])
    end

    def test_destructured_parameter_local_layout
      graph = compile_unit("def value((a, b), *, (c, d), **, &); a = 9; c = 10; local = 1; [a, b, c, d, local]; end").graphs[1]
      assert_equal([:"<destructured>", :*, :"<destructured>", :**, :&, :a, :b, :c, :d, :local], graph.locals.map(&:name))
      left = [1, 2]
      right = [3, 4]
      callback = proc { 5 }
      frame = Compile::VM::Frame.new(graph, TOPLEVEL_BINDING.receiver, [Object].freeze, &callback)
      assert_equal([9, 2, 10, 4, 1], vm.run_frame(frame, [left, 6, right], { x: 7 }))
      assert_same(left, frame.locals[graph.locals[0].id])
      assert_equal([6], frame.locals[graph.locals[1].id])
      assert_same(right, frame.locals[graph.locals[2].id])
      assert_equal({ x: 7 }, frame.locals[graph.locals[3].id])
      assert_same(callback, frame.locals[graph.locals[4].id])
    end

    def test_forwarding_parameter_local_layout
      graph = compile_unit("def value(a, ...); local = 1; local; end").graphs[1]
      assert_equal([:a, :*, :**, :&, :local], graph.locals.map(&:name))
      graph = compile_unit("proc { |opt: 1, req:| local = 2; [opt, req, local] }").graphs[1]
      assert_equal([:req, :opt, :local], graph.locals.map(&:name))
      assert_run([1, 3, 2], "proc { |opt: 1, req:| local = 2; [opt, req, local] }.call(req: 3)")
      graph = compile_unit("->(opt: 1, req:) { local = 2; [opt, req, local] }").graphs[1]
      assert_equal([:req, :opt, :local], graph.locals.map(&:name))
      assert_run([1, 3, 2], "->(opt: 1, req:) { local = 2; [opt, req, local] }.call(req: 3)")
    end

    def test_repeated_parameter_local_layout
      graph = compile_unit("def value(_, _); _; end").graphs[1]
      assert_equal([:_, :_], graph.locals.map(&:name))
      assert_equal(2, graph.locals.map(&:id).uniq.length)
      frame = Compile::VM::Frame.new(graph, TOPLEVEL_BINDING.receiver, [Object].freeze)
      assert_equal(1, vm.run_frame(frame, [1, 2]))
      assert_equal([1, 2], graph.locals.map { |local| frame.locals[local.id] })
      graph = compile_unit("def value(_ = 1, _ = 2); _; end").graphs[1]
      [[[], 2], [[3], 2], [[3, 4], 3]].each do |args, expected|
        frame = Compile::VM::Frame.new(graph, TOPLEVEL_BINDING.receiver, [Object].freeze)
        assert_equal(expected, vm.run_frame(frame, args))
      end
    end

    def test_destructured_parameters_metadata
      unit = Prism.compile("proc { |(a, b), *rest, (c, d)| [a, b, c, d] }", freeze: true).value
      graph = unit.graphs[1]
      assert_equal([0], graph.signature.requireds)
      assert_equal([2], graph.signature.posts)
      assert_equal([0, 1, 2], graph.blocks[0].params)
      assert_equal(2, graph.blocks.flat_map(&:insns).count { |insn| insn.kind == :expand_array })
      assert_equal(2, graph.blocks.flat_map(&:insns).count { |insn| insn.kind == :coerce_array_to_ary })
      assert_include(unit.disasm, "coerce_array_to_ary(%0)")
      assert_match(/expand_array %\d+, lefts=2, rights=0, rest=false/, unit.disasm)
    end

    def test_keyword_rest_method_parameters
      vm.run(compile_unit("class CompileTestKeywordRest; def value(**kwargs); kwargs; end; end"))
      source = "CompileTestKeywordRest.new"
      assert_run({}, "#{source}.value")
      assert_run({ x: 1, y: 2 }, "#{source}.value(x: 1, y: 2)")
      assert_run({ "x" => 1 }, "#{source}.value(**{ 'x' => 1 })")
      assert_run_raises(ArgumentError, "#{source}.value({ x: 1 })", "wrong number of arguments (given 1, expected 0)")
      assert_run([{ x: 1, y: 2 }, { x: 1 }], "input = { x: 1 }.freeze; result = #{source}.value(**input); result[:y] = 2; [result, input]")
      assert_run([1, 2, { z: 3 }], "class CompileTestKeywordRestMixed; def value(x:, y: 2, **rest); [x, y, rest]; end; end; CompileTestKeywordRestMixed.new.value(x: 1, z: 3)")
      assert_run([1, 4, {}], "object = Object.new; def object.value(x:, y: 2, **rest); [x, y, rest]; end; object.value(x: 1, y: 4)")
      assert_run(1, "class CompileTestKeywordRestAnonymous; def value(**); 1; end; end; CompileTestKeywordRestAnonymous.new.value(x: 2)")
      assert_run_raises(ArgumentError, "class CompileTestKeywordRestRequired; def value(x:, **rest); rest; end; end; CompileTestKeywordRestRequired.new.value(y: 1)", "missing keyword: :x")
    end

    def test_keyword_rest_block_parameters
      [
        [{}, "proc { |**kwargs| kwargs }.call"],
        [{ x: 1 }, "proc { |**kwargs| kwargs }.call(x: 1)"],
        [{}, "proc { |**kwargs| kwargs }.call({ x: 1 })"],
        [[[1], { x: 2 }], "proc { |*args, **kwargs| [args, kwargs] }.call(1, x: 2)"],
        [[1, 2, { z: 3 }], "proc { |x:, y: 2, **kwargs| [x, y, kwargs] }.call(x: 1, z: 3)"],
        [[1, 2, {}], "proc { |x:, y: 2, **kwargs| [x, y, kwargs] }.call(x: 1)"],
        [[1, 4, {}], "proc { |x:, y: 2, **kwargs| [x, y, kwargs] }.call(x: 1, y: 4)"],
        [2, "proc { |**kwargs| proc { kwargs[:x] + 1 }.call }.call(x: 1)"],
        [1, "proc { |**| 1 }.call(x: 2)"],
        [[1, { y: 2 }], "proc { |x:, **| [x, { y: 2 }] }.call(x: 1, z: 3)"],
        [[{ x: 1 }, {}], "p = proc { |**kwargs| kwargs }; a = p.call; a[:x] = 1; [a, p.call]"]
      ].each { |expected, source| assert_run(expected, source) }
    end

    def test_keyword_rest_parameters_metadata
      unit = Prism.compile("proc { |x:, y: 2, **rest| rest }", freeze: true).value
      graph = unit.graphs[1]
      assert_equal({ x: 0 }, graph.signature.required_keywords)
      assert_equal({ y: 1 }, graph.signature.optional_keywords)
      assert_equal(3, graph.signature.keyword_rest)
      assert_equal([0, 1, 2, 3], graph.blocks[0].params)
      assert_include(unit.disasm, "**%3")
      graph = compile_unit("proc { |**| 1 }").graphs[1]
      assert_equal(0, graph.signature.keyword_rest)
      assert_equal([0], graph.blocks[0].params)
      assert_equal([:**], graph.locals.map(&:name))
      assert_nil(compile_unit("proc {}").graphs[1].signature.keyword_rest)
    end

    def test_anonymous_argument_forwarding
      vm.run(compile_unit(<<~RUBY))
        class CompileTestAnonymousForwarding
          def collect(*args, **kwargs)
            [args, kwargs]
          end

          def positional(*)
            collect(*)
          end

          def keywords(**)
            collect(**)
          end

          def both(*, **)
            collect(*, **)
          end

          def mixed(first, optional = 2, *, last, x:, y: 5, **)
            [first, optional, last, x, y, collect(0, *, 9, **, extra: 10)]
          end

          def repeated(*, **)
            collect(*, 0, *, **)
          end

          def keyword_merge(**)
            collect(x: 0, **, y: 3)
          end

          def batched(*, **)
            collect(*, 1, 2, 3, *, 4, 5, **)
          end

          def restore(*, **)
            def inner_forward(*, **)
              collect(*, **)
            end
            [inner_forward(9, y: 10), proc { collect(*, **) }.call, collect(*, **)]
          end

          def capture(*, **)
            proc { proc { collect(*, **) } }
          end

          def loop_forward(*, **)
            out = []
            for i in [1, 2]
              out << collect(*, **)
            end
            out
          end

          def with_block(*, **)
            collect_with_block(*, **) { 3 }
          end

          def collect_with_block(*args, **kwargs)
            [args, kwargs, yield]
          end

          def safe(receiver, *, **)
            receiver&.collect(*, **)
          end

          def arrays(*)
            first = [0, *, 9, *]
            first << 10
            [first, [*]]
          end

          def hashes(**)
            first = { x: 0, **, y: 3 }
            first[:z] = 4
            [first, { ** }]
          end
        end
      RUBY
      receiver = "CompileTestAnonymousForwarding.new"
      [
        [[[], {}], "positional"],
        [[[1, 2], {}], "positional(1, 2)"],
        [[[nil, false], {}], "positional(nil, false)"],
        [[[{ x: 1 }], {}], "positional(x: 1)"],
        [[[], {}], "keywords"],
        [[[], { x: 1 }], "keywords(x: 1)"],
        [[[], {}], "both"],
        [[[1, 2], { x: 3 }], "both(1, 2, x: 3)"],
        [[[{ x: 1 }], { y: 2 }], "both({ x: 1 }, y: 2)"],
        [[1, 2, 5, 6, 5, [[0, 3, 4, 9], { z: 7, extra: 10 }]], "mixed(1, 2, 3, 4, 5, x: 6, z: 7)"],
        [[1, 2, 3, 4, 5, [[0, 9], { extra: 10 }]], "mixed(1, 3, x: 4)"],
        [[[1, 2, 0, 1, 2], { x: 3 }], "repeated(1, 2, x: 3)"],
        [[[0], {}], "repeated"],
        [[[], { x: 1, y: 3, z: 4 }], "keyword_merge(x: 1, y: 2, z: 4)"],
        [[[7, 8, 1, 2, 3, 7, 8, 4, 5], { x: 6 }], "batched(7, 8, x: 6)"],
        [[[[9], { y: 10 }], [[1, 2], { x: 3 }], [[1, 2], { x: 3 }]], "restore(1, 2, x: 3)"],
        [[[1, 2], { x: 3 }], "capture(1, 2, x: 3).call.call"],
        [[[[1], { x: 2 }], [[1], { x: 2 }]], "loop_forward(1, x: 2)"],
        [[[1], { x: 2 }, 3], "with_block(1, x: 2)"],
        [nil, "safe(nil, 1, x: 2)"],
        [[[1], { x: 2 }], "safe(#{receiver}, 1, x: 2)"],
        [[[0, 1, 2, 9, 1, 2, 10], [1, 2]], "arrays(1, 2)"],
        [[[0, 9, 10], []], "arrays"],
        [[{ x: 1, y: 3, z: 4 }, { x: 1 }], "hashes(x: 1)"]
      ].each { |expected, call| assert_run(expected, "#{receiver}.#{call}") }
    end

    def test_super
      vm.run(compile_unit(<<~RUBY))
        class CompileTestSuperBase
          def value(*args, **kwargs, &block)
            [args, kwargs, block && block.call]
          end
          alias explicit value
          alias empty value
          alias no_block value
          alias replacement value
          alias explicit_block value
          alias defaults value
          alias posts value
          alias destructured value
          alias anonymous value
          alias dots value
          alias reassigned value
          alias capture value
          alias iter value

          def self.value(*args, **kwargs, &block)
            [args, kwargs, block && block.call]
          end
        end
        class CompileTestSuperChild < CompileTestSuperBase
          def value(a = 1, *rest, x: 2, **kwargs, &block)
            a += 10
            rest << 99
            x += 10
            kwargs[:extra] = 3
            block = nil
            super
          end
          alias renamed value

          def explicit(a, *rest, **kwargs, &block)
            super(a + 1, *rest, x: 2, **kwargs, &block)
          end

          def empty(...)
            super()
          end

          def no_block(...)
            super(&nil)
          end

          def replacement(...)
            super { :replacement }
          end

          def explicit_block(...)
            super(0) { :replacement }
          end

          def defaults(a = 1, b = 2, x: 3, y: 4)
            super
          end

          def posts(a, *rest, b, c)
            b = 8
            super
          end

          def destructured((a, b), *rest, (c, d))
            a = 9
            c = 10
            super
          end

          def anonymous(*, **, &)
            super
          end

          def dots(...)
            super(...)
          end

          def reassigned(*rest, **kwargs)
            rest = 7
            kwargs = nil
            super
          end

          def capture(a, *rest, x:, **kwargs)
            proc { |a| -> { super } }
          end

          def iter(a)
            out = []
            for a in [2, 3]
              out << super
            end
            out
          end

          def missing
            super
          end

          def self.value(...)
            super
          end
        end
      RUBY
      receiver = "CompileTestSuperChild.new"
      [
        [[[11, 99], { x: 12, extra: 3 }, nil], "value"],
        [[[13, 4, 99], { x: 15, y: 6, extra: 3 }, 7], "value(3, 4, x: 5, y: 6) { 7 }"],
        [[[11, 99], { x: 12, extra: 3 }, 7], "renamed { 7 }"],
        [[[2, 3, 4], { x: 5, y: 6 }, 7], "explicit(1, 3, 4, x: 5, y: 6) { 7 }"],
        [[[], {}, 3], "empty(1, x: 2) { 3 }"],
        [[[], {}, nil], "no_block(1, x: 2) { 3 }"],
        [[[1], { x: 2 }, :replacement], "replacement(1, x: 2) { 3 }"],
        [[[0], {}, :replacement], "explicit_block(1, x: 2) { 3 }"],
        [[[1, 2], { x: 3, y: 4 }, nil], "defaults"],
        [[[5, 2], { x: 6, y: 4 }, 7], "defaults(5, x: 6) { 7 }"],
        [[[1, 2, 8, 4], {}, nil], "posts(1, 2, 3, 4)"],
        [[[[1, 2], 3, [4, 5]], {}, nil], "destructured([1, 2], 3, [4, 5])"],
        [[[1, 2], { x: 3 }, 4], "anonymous(1, 2, x: 3) { 4 }"],
        [[[1, 2], { x: 3 }, 4], "dots(1, 2, x: 3) { 4 }"],
        [[[7], {}, 4], "reassigned(1, x: 2) { 4 }"],
        [[[1, 2], { x: 3, y: 4 }, 5], "capture(1, 2, x: 3, y: 4) { 5 }.call(99).call"],
        [[[[2], {}, 4], [[3], {}, 4]], "iter(1) { 4 }"]
      ].each { |expected, call| assert_run(expected, "#{receiver}.#{call}") }
      assert_run([[1], { x: 2 }, 3], "CompileTestSuperChild.value(1, x: 2) { 3 }")
      assert_run_raises(NoMethodError, "#{receiver}.missing")
      assert_run_raises(NoMethodError, "super()", "super called outside of method")
      assert_run_raises(NoMethodError, "super", "super called outside of method")
    end

    def test_super_parameter_local_layout
      vm.run(compile_unit(<<~RUBY))
        class CompileTestSuperLayoutBase
          def value(*args, **kwargs, &block)
            [args, kwargs, block && block.call]
          end
          alias repeated value
        end
        class CompileTestSuperLayoutChild < CompileTestSuperLayoutBase
          def value(a, (b, c), d = 4, *rest, (e, f), opt: 5, req:, **kwargs, &block)
            local = 100
            b = 99
            e = 88
            d += 1
            opt += 1
            req += 1
            kwargs[:extra] = 9
            [super, local]
          end

          def repeated(_, _)
            _ += 10
            super
          end
        end
      RUBY
      assert_run([[[1, [2, 3], 5, 7, [8, 9]], { req: 11, opt: 6, z: 11, extra: 9 }, 12], 100], "CompileTestSuperLayoutChild.new.value(1, [2, 3], 4, 7, [8, 9], req: 10, z: 11) { 12 }")
      assert_run([[11, 2], {}, nil], "CompileTestSuperLayoutChild.new.repeated(1, 2)")
    end

    def test_super_lookup
      assert_run([:two, [:one, :base]], <<~RUBY)
        class CompileTestSuperLookupBase
          def value
            :base
          end
        end
        module CompileTestSuperLookupOne
          def value
            [:one, super]
          end
        end
        module CompileTestSuperLookupTwo
          def value
            [:two, super()]
          end
        end
        class CompileTestSuperLookupChild < CompileTestSuperLookupBase
          include CompileTestSuperLookupOne
          prepend CompileTestSuperLookupTwo
        end
        CompileTestSuperLookupChild.new.value
      RUBY
      assert_run([:missing, [1], { x: 2 }, 3], <<~RUBY)
        class CompileTestSuperMissingBase
          def method_missing(name, *args, **kwargs, &block)
            [name, args, kwargs, block.call]
          end
        end
        class CompileTestSuperMissingChild < CompileTestSuperMissingBase
          def missing(...)
            super
          end
        end
        CompileTestSuperMissingChild.new.missing(1, x: 2) { 3 }
      RUBY
    end

    def test_super_rebound_receiver
      assert_run(2, <<~RUBY)
        class CompileTestSuperReboundBase
          def value
            @value
          end
        end
        class CompileTestSuperReboundChild < CompileTestSuperReboundBase
          def initialize(value)
            @value = value
          end

          def value
            proc { super() }
          end
        end
        first = CompileTestSuperReboundChild.new(1)
        second = CompileTestSuperReboundChild.new(2)
        second.instance_exec(&first.value)
      RUBY
    end

    def test_super_argument_order
      assert_run([[[1, 2, 3], { x: 4 }, 5], [:first, :splat, :keyword, :block]], <<~RUBY)
        class CompileTestSuperOrderBase
          def value(*args, **kwargs, &block)
            [args, kwargs, block.call]
          end
        end
        class CompileTestSuperOrderChild < CompileTestSuperOrderBase
          def value(events)
            result = super((events << :first; 1), *(events << :splat; [2, 3]), x: (events << :keyword; 4)) { events << :block; 5 }
            [result, events]
          end
        end
        CompileTestSuperOrderChild.new.value([])
      RUBY
    end

    def test_super_signature_and_disasm
      unit = compile_unit("class SuperMetadataParent; end; class SuperMetadataChild < SuperMetadataParent; def value(a = 1, *rest, x: 2, **kwargs); super; end; end")
      graph = unit.graphs.find { |candidate| candidate.kind == :def }
      kinds = graph.blocks.flat_map(&:insns).map(&:kind)
      assert_include(kinds, :call_super)
      assert_include(kinds, :load_block)
      assert_include(kinds, :coerce_array_to_a)
      assert_include(unit.disasm, " = call_super(")
      assert_include(unit.disasm, "load_block")
    end

    def test_expression_splat_coercion
      scope = Module.new
      events = []
      input = Object.new
      input.define_singleton_method(:to_a) { events << :to_a; [1, 2] }
      input.define_singleton_method(:to_ary) { raise "to_ary called" }
      scope.const_set(:Input, input)
      graph = compile_unit("[*Input, 3]").graphs[0]
      assert_equal([1, 2, 3], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      assert_equal([:to_a], events)
      assert_run([1, 2, 3], "proc { |*args| args }.call(1, *[2, 3])")
      assert_run([], "[*nil]")
      assert_run([1], "[*1]")
    end

    def test_lambdas
      [
        [nil, "-> {}.call"],
        [1, "-> { 1 }.call"],
        [1, "->() do 1 end.call"],
        [true, "-> {}.lambda?"],
        [false, "proc {}.lambda?"],
        [[1, 2], "->(a, b) { [a, b] }.call(1, 2)"],
        [[1, 2], "->(a) { a }.call([1, 2])"],
        [[1, 2], "-> { it }.call([1, 2])"],
        [3, "-> { _1 + _2 }.call(1, 2)"],
        [[1, 2], "->((a, b)) { [a, b] }.call([1, 2])"],
        [[1, 2, [3, 4], 5], "->(a, b = 2, *rest, c) { [a, b, rest, c] }.call(1, 2, 3, 4, 5)"],
        [[1, 2, [], 3], "->(a, b = 2, *rest, c) { [a, b, rest, c] }.call(1, 3)"],
        [[1, 2, { z: 3 }, 4], "->(x:, y: 2, **rest, &block) { [x, y, rest, block.call] }.call(x: 1, z: 3) { 4 }"],
        [[1, 2], "a = 1; f = ->(a; b) { b = a + 1; [a, b] }; f.call(a)"],
        [[2, 3, 3], "a = 1; f = -> { a += 1 }; [f.call, f.call, a]"],
        [[2, 1], "a = 1; result = ->(a) { a += 1 }.call(1); [result, a]"],
        [3, "a = 2; ->(b = a + 1) { b }.call"],
        [3, "->(a = 1, b = a + 2) { b }.call"],
        [3, "->(a = 1, b: a + 2) { b }.call"],
        [3, "->(a) { ->(b) { a + b } }.call(1).call(2)"],
        [[2, 4], "[1, 2].map(&->(a) { a * 2 })"],
        [1, "-> { return 1; 2 }.call"],
        [true, "1 in ->(value) { value == 1 }"],
        [false, "2 in ->(value) { value == 1 }"],
        [[true, true], "factory = -> { ->(x) { if x..false; true; else; false; end } }; a = factory.call; b = factory.call; [a.call(true), b.call(false)]"]
      ].each { |expected, source| assert_run(expected, source) }
    end

    def test_lambda_arity
      [
        ["-> {}.call(1)", "wrong number of arguments (given 1, expected 0)"],
        ["->(a) { a }.call", "wrong number of arguments (given 0, expected 1)"],
        ["->(a, b) {}.call([1, 2])", "wrong number of arguments (given 1, expected 2)"],
        ["->(a = 1) {}.call(1, 2)", "wrong number of arguments (given 2, expected 0..1)"],
        ["->(a, *rest) {}.call", "wrong number of arguments (given 0, expected 1+)"],
        ["-> { it }.call", "wrong number of arguments (given 0, expected 1)"],
        ["-> { _2 }.call(1)", "wrong number of arguments (given 1, expected 2)"],
        ["->(x:) {}.call", "missing keyword: :x"],
        ["->(x:) {}.call(x: 1, y: 2)", "unknown keyword: :y"],
        ["->(**nil) {}.call(x: 1)", "no keywords accepted"],
        ["->(&nil) {}.call { 1 }", "no block accepted"],
        ["->(a = raise('default ran'), x:) {}.call", "missing keyword: :x"]
      ].each { |source, message| assert_run_raises(ArgumentError, source, message) }
    end

    def test_lambda_captures
      vm.run(compile_unit(<<~RUBY))
        class CompileTestLambda
          A = 3

          def make(a)
            -> { a += 1 }
          end

          def context
            @value = 2
            -> { [self, @value, A] }
          end

          def local_return
            result = -> { return 1 }.call
            [result, 2]
          end

          def collect(*args, **kwargs, &block)
            [args, kwargs, block && block.call]
          end

          def forward(...)
            -> { collect(...) }
          end

          def yield_and_block
            ->(&block) { [block.call, yield] }
          end
        end
      RUBY
      receiver = "CompileTestLambda.new"
      assert_run([2, 3, 11], "object = #{receiver}; a = object.make(1); b = object.make(10); [a.call, a.call, b.call]")
      assert_run([true, 2, 3], "object = #{receiver}; result = object.context.call; [result[0].equal?(object), result[1], result[2]]")
      assert_run([1, 2], "#{receiver}.local_return")
      assert_run([[1], { x: 2 }, 3], "#{receiver}.forward(1, x: 2) { 3 }.call")
      assert_run([:inner, :outer], "#{receiver}.yield_and_block { :outer }.call { :inner }")
    end

    def test_lambda_graph
      unit = Prism.compile("->(a, b) { return a + b }", freeze: true).value
      graph = unit.graphs[1]
      assert_equal(:lambda, graph.kind)
      assert_same(unit.graphs[0], graph.parent)
      assert_same(graph, graph.scope)
      assert_equal(false, graph.signature.autosplat)
      assert_equal(2, graph.signature.requireds.length)
      assert_include(unit.disasm, "(lambda, parent=g0, scope=g1)")
      assert_include(graph.blocks[0].insns.map(&:kind), :trace_b_call)
      body = graph.blocks[0].insns.last.data
      assert_equal([:trace_b_return, :return_value], body.insns.last(2).map(&:kind))
      unit = compile_unit("->(x) { if x..false; true; else; false; end }")
      assert_equal([1, 0], unit.graphs.map(&:nflip_flops))
    end

    def test_forwarding_parameters
      vm.run(compile_unit(<<~RUBY))
        class CompileTestForwarding
          def collect(*args, **kwargs, &block)
            [args, kwargs, block && block.call]
          end

          def forward(...)
            collect(...)
          end

          def leading(first, ...)
            [first, collect(0, ...)]
          end

          def optional(first = 7, ...)
            [first, collect(...)]
          end

          def destructured((a, b), ...)
            [a, b, collect(...)]
          end

          def chain(...)
            forward(...)
          end

          def capture(...)
            proc { |ignored| proc { collect(...) } }
          end

          def distinguish(...)
            proc { |&inner| [collect(...), inner.call, yield] }
          end

          def iter(...)
            out = []
            for i in [1, 2]
              out << collect(...)
            end
            out
          end

          def safe(receiver, ...)
            receiver&.collect(...)
          end

          def restore(...)
            def inner_dots(...)
              collect(...)
            end
            [inner_dots(9, y: 10) { :inner }, collect(...)]
          end

          def capture_block(&block)
            block
          end

          def forward_block(...)
            capture_block(...)
          end

          def reject_target(**nil, &nil)
            1
          end

          def reject(...)
            reject_target(...)
          end
        end
      RUBY
      receiver = "CompileTestForwarding.new"
      [
        [[[], {}, nil], "forward"],
        [[[1, 2], {}, nil], "forward(1, 2)"],
        [[[], { x: 1 }, nil], "forward(x: 1)"],
        [[[1, 2], { x: 3 }, 4], "forward(1, 2, x: 3) { 4 }"],
        [[[{ x: 1 }], { y: 2 }, nil], "forward({ x: 1 }, y: 2)"],
        [[[nil, false], {}, nil], "forward(nil, false)"],
        [[1, [[0, 2, 3], { x: 4 }, 5]], "leading(1, 2, 3, x: 4) { 5 }"],
        [[1, [[0], {}, nil]], "leading(1)"],
        [[7, [[], {}, nil]], "optional"],
        [[7, [[], { x: 1 }, nil]], "optional(x: 1)"],
        [[1, [[2, 3], { x: 4 }, 5]], "optional(1, 2, 3, x: 4) { 5 }"],
        [[1, 2, [[3], { x: 4 }, 5]], "destructured([1, 2], 3, x: 4) { 5 }"],
        [[[1], { x: 2 }, 3], "chain(1, x: 2) { 3 }"],
        [[[1], { x: 2 }, 3], "capture(1, x: 2) { 3 }.call(99).call"],
        [[[[1], { x: 2 }, :outer], :inner, :outer], "distinguish(1, x: 2) { :outer }.call { :inner }"],
        [[[[1], { x: 2 }, 3], [[1], { x: 2 }, 3]], "iter(1, x: 2) { 3 }"],
        [nil, "safe(nil, 1, x: 2) { 3 }"],
        [[[1], { x: 2 }, 3], "safe(#{receiver}, 1, x: 2) { 3 }"],
        [[[[9], { y: 10 }, :inner], [[1], { x: 2 }, :outer]], "restore(1, x: 2) { :outer }"],
        [1, "reject"]
      ].each { |expected, call| assert_run(expected, "#{receiver}.#{call}") }
      assert_run_raises(ArgumentError, "#{receiver}.leading(x: 1)", "wrong number of arguments (given 0, expected 1+)")
      assert_run_raises(ArgumentError, "#{receiver}.reject(x: 1)", "no keywords accepted")
      assert_run_raises(ArgumentError, "#{receiver}.reject { 2 }", "no block accepted")
      assert_run_raises(RuntimeError, "#{receiver}.forward { raise('forwarded failure') }", "forwarded failure")
      object = vm.run(compile_unit(receiver))
      callback = proc { 3 }
      assert_same(callback, object.forward_block(&callback))
    end

    def test_forwarding_argument_evaluation_order
      assert_run([[[0, 1, 2, 3], { x: 4 }, 5], [:receiver, :first, :second, :block]], <<~RUBY)
        class CompileTestDotsOrder
          def collect(*args, **kwargs, &block)
            [args, kwargs, block.call]
          end

          def forward(events, ...)
            result = (events << :receiver; self).collect((events << :first; 0), (events << :second; 1), ...)
            [result, events]
          end
        end
        events = []
        CompileTestDotsOrder.new.forward(events, 2, 3, x: 4) { events << :block; 5 }
      RUBY
    end

    def test_forwarding_parameter_signature
      unit = Prism.compile("def forward(a, ...); target(0, ...); end", freeze: true).value
      graph = unit.graphs[1]
      signature = graph.signature
      assert_equal([:a, :*, :**, :&], graph.locals.map(&:name))
      assert_equal(1, signature.requireds.length)
      assert_not_nil(signature.rest)
      assert_not_nil(signature.keyword_rest)
      assert_not_nil(signature.block)
      assert_equal([*signature.requireds, signature.rest, signature.keyword_rest, signature.block], graph.blocks[0].params)
      call = graph.blocks.flat_map(&:insns).find { |insn| insn.kind == :call && insn.data.block }
      assert_equal(true, call.data.splat)
      assert_equal(true, call.data.keywords)
    end

    def test_anonymous_block_forwarding
      vm.run(compile_unit(<<~RUBY))
        class CompileTestAnonymousBlock
          def capture(&block)
            block
          end

          def forward(&)
            capture(&)
          end

          def collect(*args, **kwargs, &block)
            [args, kwargs, block && block.call]
          end

          def all(*, **, &)
            collect(*, **, &)
          end

          def make(&)
            proc { proc { capture(&) } }
          end

          def distinguish(&)
            proc { |&inner| [capture(&).call, inner.call, yield] }
          end

          def iter(&)
            out = []
            for i in [1, 2]
              out << capture(&).call
            end
            out
          end

          def restore(&)
            def inner_forward(&)
              capture(&)
            end
            [inner_forward { :inner }.call, capture(&).call]
          end

          def safe(receiver, &)
            receiver&.capture(&)
          end
        end
      RUBY
      receiver = "CompileTestAnonymousBlock.new"
      [
        [nil, "forward"],
        [3, "forward { 3 }.call"],
        [[[], {}, nil], "all"],
        [[[1, 2], { x: 3 }, 4], "all(1, 2, x: 3) { 4 }"],
        [3, "make { 3 }.call.call.call"],
        [[:outer, :inner, :outer], "distinguish { :outer }.call { :inner }"],
        [[3, 3], "iter { 3 }"],
        [[:inner, :outer], "restore { :outer }"],
        [nil, "safe(nil) { 3 }"],
        [3, "safe(#{receiver}) { 3 }.call"]
      ].each { |expected, call| assert_run(expected, "#{receiver}.#{call}") }
      assert_run_raises(RuntimeError, "#{receiver}.all { raise('callback failed') }", "callback failed")
      object = vm.run(compile_unit(receiver))
      callback = proc { 3 }
      assert_same(callback, object.forward(&callback))
      assert_same(callback, object.make(&callback).call.call)
    end

    def test_anonymous_block_forwarding_signature
      unit = Prism.compile("def forward(*, **, &); target(*, **, &); end", freeze: true).value
      graph = unit.graphs[1]
      assert_equal([:*, :**, :&], graph.locals.map(&:name))
      assert_not_nil(graph.signature.block)
      assert_include(graph.blocks[0].params, graph.signature.block)
      call = graph.blocks.flat_map(&:insns).find { |insn| insn.kind == :call && insn.data.block }
      assert_equal(true, call.data.splat)
      assert_equal(true, call.data.keywords)
      load = graph.blocks.flat_map(&:insns).find { |insn| insn.kind == :load_lvar && insn.data.name == :& }
      assert_equal(load.opnds[0], call.opnds[-1])
    end

    def test_block_argument_expressions
      assert_run(3, "proc { |&block| proc { |&passed| passed.call }.call(&block) }.call { 3 }")
      assert_run(nil, "proc { |&block| block }.call(&nil)")
      assert_run(["1", "2"], "[1, 2].map(&:to_s)")
    end

    def test_anonymous_forwarding_evaluation_order
      assert_run([[[0, 1, 2, 3], { x: 4, y: 5 }], [:receiver, :before, :after, :keyword]], <<~RUBY)
        class CompileTestForwardingOrder
          def collect(*args, **kwargs)
            [args, kwargs]
          end

          def forward(events, *, **)
            result = (events << :receiver; self).collect((events << :before; 0), *, (events << :after; 3), **, y: (events << :keyword; 5))
            [result, events]
          end
        end
        CompileTestForwardingOrder.new.forward([], 1, 2, x: 4)
      RUBY
    end

    def test_anonymous_forwarding_metadata
      unit = Prism.compile("def forward(*, **); target(*, **); end", freeze: true).value
      graph = unit.graphs[1]
      assert_equal([:*, :**], graph.locals.map(&:name))
      call = graph.blocks.flat_map(&:insns).find { |insn| insn.kind == :call }
      assert_equal(true, call.data.splat)
      assert_equal(true, call.data.keywords)
      assert_equal(:target, call.data.name)
      assert_include(unit.disasm, "[splat] [keywords]")
      assert_equal(false, compile_unit("target(1)").graphs[0].blocks.flat_map(&:insns).find { |insn| insn.kind == :call }.data.splat)
    end

    def test_no_block_method_parameters
      vm.run(compile_unit(<<~RUBY))
        class CompileTestNoBlock
          def value(&nil)
            1
          end

          def positional(a, &nil)
            a
          end

          def default(a = raise('default ran'), &nil)
            a
          end

          def keyword(x:, &nil)
            x
          end

          def no_keywords(**nil, &nil)
            1
          end
        end
      RUBY
      assert_run(1, "CompileTestNoBlock.new.value")
      assert_run(2, "CompileTestNoBlock.new.positional(2)")
      assert_run(3, "CompileTestNoBlock.new.keyword(x: 3)")
      assert_run_raises(ArgumentError, "CompileTestNoBlock.new.value { 2 }", "no block accepted")
      assert_run_raises(ArgumentError, "CompileTestNoBlock.new.default { 2 }", "no block accepted")
      assert_run_raises(ArgumentError, "CompileTestNoBlock.new.positional { 2 }", "wrong number of arguments (given 0, expected 1)")
      assert_run_raises(ArgumentError, "CompileTestNoBlock.new.keyword { 2 }", "missing keyword: :x")
      assert_run_raises(ArgumentError, "CompileTestNoBlock.new.keyword(x: 1, y: 2) { 2 }", "unknown keyword: :y")
      assert_run_raises(ArgumentError, "CompileTestNoBlock.new.no_keywords(x: 1) { 2 }", "no keywords accepted")
    end

    def test_no_block_block_parameters
      assert_run(1, "proc { |&nil| 1 }.call")
      assert_run(2, "proc { |a, &nil| a }.call(2)")
      assert_run([1, 2], "proc { |a, &nil| a }.call([1, 2])")
      assert_run_raises(ArgumentError, "proc { |&nil| 1 }.call { 2 }", "no block accepted")
      assert_run_raises(ArgumentError, "proc { |a = raise('default ran'), &nil| a }.call { 2 }", "no block accepted")
      assert_run(3, "class CompileTestNoBlockYield; def make; proc { |&nil| yield }; end; end; CompileTestNoBlockYield.new.make { 3 }.call")
    end

    def test_no_block_parameter_signature
      unit = Prism.compile("proc { |&nil| 1 }", freeze: true).value
      graph = unit.graphs[1]
      assert_equal(true, graph.signature.no_block)
      assert_nil(graph.signature.block)
      assert_empty(graph.blocks[0].params)
      assert_empty(graph.locals)
      assert_include(unit.disasm, "g1(&nil)")
      assert_equal(false, compile_unit("proc {}").graphs[1].signature.no_block)
      assert_equal(true, compile_unit("def no_block(&nil); end").graphs[1].signature.no_block)
    end

    def test_no_keywords_method_parameters
      vm.run(compile_unit("class CompileTestNoKeywords; def value(**nil); 1; end; end"))
      assert_run(1, "CompileTestNoKeywords.new.value")
      assert_run(1, "CompileTestNoKeywords.new.value(**{})")
      assert_run_raises(ArgumentError, "CompileTestNoKeywords.new.value(x: 1)", "no keywords accepted")
      assert_run_raises(ArgumentError, "CompileTestNoKeywords.new.value({ x: 1 })", "wrong number of arguments (given 1, expected 0)")
      vm.run(compile_unit("class CompileTestNoKeywordsPositional; def value(a, **nil); a; end; end"))
      assert_run({ x: 1 }, "CompileTestNoKeywordsPositional.new.value({ x: 1 })")
      assert_run_raises(ArgumentError, "CompileTestNoKeywordsPositional.new.value(x: 1)", "no keywords accepted")
      assert_run_raises(ArgumentError, "class CompileTestNoKeywordsDefault; def value(a = raise('default ran'), **nil); a; end; end; CompileTestNoKeywordsDefault.new.value(x: 1)", "no keywords accepted")
      assert_run_raises(ArgumentError, "object = Object.new; def object.value(**nil); 1; end; object.value(x: 1)", "no keywords accepted")
    end

    def test_no_keywords_block_parameters
      assert_run(1, "proc { |**nil| 1 }.call")
      assert_run(1, "proc { |**nil| 1 }.call(**{})")
      assert_run({ x: 1 }, "proc { |a, **nil| a }.call({ x: 1 })")
      assert_run([[1, 2]], "proc { |a, **nil| [a] }.call([1, 2])")
      assert_run([1, [2]], "proc { |a, *rest, **nil| [a, rest] }.call([1, 2])")
      assert_run_raises(ArgumentError, "proc { |**nil| 1 }.call(x: 1)", "no keywords accepted")
      assert_run_raises(ArgumentError, "proc { |*args, **nil| args }.call(x: 1)", "no keywords accepted")
      assert_run_raises(ArgumentError, "proc { |a = raise('default ran'), **nil| a }.call(x: 1)", "no keywords accepted")
    end

    def test_no_keywords_parameters_metadata
      unit = Prism.compile("proc { |**nil| 1 }", freeze: true).value
      graph = unit.graphs[1]
      assert_equal(true, graph.signature.no_keywords)
      assert_empty(graph.blocks[0].params)
      assert_empty(graph.locals)
      assert_include(unit.disasm, "g1(**nil)")
      assert_equal(false, compile_unit("proc {}").graphs[1].signature.no_keywords)
      assert_equal(true, compile_unit("def no_keywords(**nil); end").graphs[1].signature.no_keywords)
    end

    def test_optional_keyword_method_parameters
      vm.run(compile_unit("class CompileTestOptionalKeywords; def value(x: 1, y: x + 2); [x, y]; end; end"))
      source = "CompileTestOptionalKeywords.new"
      assert_run([1, 3], "#{source}.value")
      assert_run([4, 6], "#{source}.value(x: 4)")
      assert_run([1, 8], "#{source}.value(y: 8)")
      assert_run([4, 8], "#{source}.value(y: 8, x: 4)")
      assert_run([nil, false], "#{source}.value(x: nil, y: false)")
      assert_run([1, 3], "#{source}.value(**{})")
      assert_run_raises(ArgumentError, "#{source}.value(z: 1)", "unknown keyword: :z")
      assert_run_raises(ArgumentError, "#{source}.value({ x: 1 })", "wrong number of arguments (given 1, expected 0)")
      assert_run(3, "object = Object.new; def object.value(x: 3); x; end; object.value")
      assert_run([1, 2, [], 3, 4, 5], "class CompileTestOptionalKeywordsMixed; def value(a, b = 2, *rest, c, x:, y: x + 1); [a, b, rest, c, x, y]; end; end; CompileTestOptionalKeywordsMixed.new.value(1, 3, x: 4)")
    end

    def test_optional_keyword_block_parameters
      [
        [[1, 2], "proc { |x: 1, y: (x + 1)| [x, y] }.call"],
        [[1, 4], "proc { |x: 1, y: (x + 1)| [x, y] }.call(y: 4)"],
        [[nil, false], "proc { |x: 1, y: 2| [x, y] }.call(x: nil, y: false)"],
        [[1, 3], "proc { |x:, y: (x + 2)| [x, y] }.call(x: 1)"],
        [[2, 1], "proc { |x: 2, y:| [x, y] }.call(y: 1)"],
        [[2, 3], "proc { |a = 2, x: (a + 1)| [a, x] }.call"],
        [[1, [], 2, 3], "proc { |a, *rest, b, x: 3| [a, rest, b, x] }.call([1, 2])"],
        [[nil, { x: 2 }], "proc { |a, x: 1| [a, x] }.call(x: { x: 2 })"]
      ].each { |expected, source| assert_run(expected, source) }
      assert_run_raises(ArgumentError, "proc { |x: 1| x }.call(y: 2)", "unknown keyword: :y")
      assert_run_raises(ArgumentError, "proc { |x:, y: 1| x }.call", "missing keyword: :x")
    end

    def test_optional_keyword_defaults
      [
        [[[1, 2], [1, 2]], "events = []; p = proc { |x: (events << 1; 1), y: (events << 2; x + 1)| [x, y] }; result = p.call; [result, events]"],
        [[[4, 5], [2]], "events = []; p = proc { |x: (events << 1; 1), y: (events << 2; x + 1)| [x, y] }; result = p.call(x: 4); [result, events]"],
        [[nil, []], "events = []; p = proc { |x: (events << 1)| x }; result = p.call(x: nil); [result, events]"],
        [3, "proc { |x: (if true; 3; else; 4; end)| x }.call"],
        [2, "proc { |x: proc { 2 }.call| x }.call"],
        [[1, 1], "proc { |x: 1, y: proc { x }.call| [x, y] }.call"],
        [[[1], [1]], "p = proc { |x: []| x << 1 }; [p.call, p.call]"],
        [4, "a = 3; proc { |x: (a + 1)| x }.call"],
        [[[1, 2], [:positional, :keyword]], "events = []; p = proc { |a = (events << :positional; 1), x: (events << :keyword; 2)| [a, x] }; result = p.call; [result, events]"]
      ].each { |expected, source| assert_run(expected, source) }
      assert_run_raises(RuntimeError, "proc { |x: raise('default ran')| x }.call", "default ran")
      assert_run(1, "proc { |x: raise('default ran')| x }.call(x: 1)")
      assert_run_raises(ArgumentError, "proc { |x:, y: raise('default ran')| y }.call", "missing keyword: :x")
      assert_run_raises(ArgumentError, "proc { |x: raise('default ran')| x }.call(y: 1)", "unknown keyword: :y")
    end

    def test_optional_keyword_parameters_metadata
      unit = Prism.compile("proc { |a, x:, y: 1, z: (y + 1)| [a, x, y, z] }", freeze: true).value
      graph = unit.graphs[1]
      assert_equal({ x: 1 }, graph.signature.required_keywords)
      assert_equal({ y: 2, z: 4 }, graph.signature.optional_keywords)
      assert_equal({ y: 3, z: 5 }, graph.signature.optional_keyword_specifieds)
      assert_equal((0..5).to_a, graph.blocks[0].params)
      assert_predicate(graph.signature.optional_keywords, :frozen?)
      assert_predicate(graph.signature.optional_keyword_specifieds, :frozen?)
      assert_equal(2, graph.blocks.flat_map(&:insns).count { |insn| insn.kind == :branch_if })
      assert_include(unit.disasm, "y: %2?%3, z: %4?%5")
    end

    def test_required_keyword_method_parameters
      vm.run(compile_unit("class CompileTestKeywords; def value(x:, y:); [x, y]; end; end"))
      source = "CompileTestKeywords.new"
      assert_run([1, 2], "#{source}.value(x: 1, y: 2)")
      assert_run([1, 2], "#{source}.value(y: 2, x: 1)")
      assert_run([nil, false], "#{source}.value(x: nil, y: false)")
      assert_run_raises(ArgumentError, "#{source}.value", "missing keywords: :x, :y")
      assert_run_raises(ArgumentError, "#{source}.value(y: 2)", "missing keyword: :x")
      assert_run_raises(ArgumentError, "#{source}.value(x: 1, y: 2, z: 3)", "unknown keyword: :z")
      assert_run_raises(ArgumentError, "#{source}.value({ x: 1, y: 2 })", "wrong number of arguments (given 1, expected 0)")
      assert_run([1, 2, [], 3, 4], "class CompileTestKeywordsMixed; def value(a, b = 2, *rest, c, x:); [a, b, rest, c, x]; end; end; CompileTestKeywordsMixed.new.value(1, 3, x: 4)")
      assert_run(2, "object = Object.new; def object.value(x:); x; end; object.value(x: 2)")
      assert_run(3, "class CompileTestKeywordYield; def value(x:); x + yield; end; end; CompileTestKeywordYield.new.value(x: 1) { 2 }")
      assert_run(2, "class CompileTestKeywordCapture; def value(x:); proc { x + 1 }.call; end; end; CompileTestKeywordCapture.new.value(x: 1)")
      assert_run_raises(ArgumentError, "class CompileTestKeywordDefault; def value(a = raise('default ran'), x:); a; end; end; CompileTestKeywordDefault.new.value", "missing keyword: :x")
    end

    def test_required_keyword_block_parameters
      [
        [1, "proc { |x:| x }.call(x: 1)"],
        [[nil, false], "proc { |x:, y:| [x, y] }.call(y: false, x: nil)"],
        [[1, 2], "proc { |a, x:| [a, x] }.call(1, x: 2)"],
        [[[1, 2], nil, 3], "proc { |a, b, x:| [a, b, x] }.call([1, 2], x: 3)"],
        [[2, [], 3], "proc { |a = 2, *rest, x:| [a, rest, x] }.call(x: 3)"],
        [2, "proc { |x:| proc { x + 1 }.call }.call(x: 1)"],
        [{ x: 1 }, "proc { |a| a }.call(x: 1)"],
        [[{ x: 1 }], "proc { |*args| args }.call(x: 1)"]
      ].each { |expected, source| assert_run(expected, source) }
      assert_run_raises(ArgumentError, "proc { |x:| x }.call", "missing keyword: :x")
      assert_run_raises(ArgumentError, "proc { |x:| x }.call({ x: 1 })", "missing keyword: :x")
      assert_run_raises(ArgumentError, "proc { |x:| x }.call(x: 1, y: 2, z: 3)", "unknown keywords: :y, :z")
    end

    def test_keyword_calls
      assert_run("abc", 'String.new("abc", capacity: 10)')
      assert_run(3, "proc { |x:, y:| x + y }.call(**{ x: 1, y: 2 })")
      assert_run(2, "proc { |x:| x }.call(**{ x: 1 }, x: 2)")
      assert_run(nil, "nil&.missing(x: raise('not called'))")
      vm.run(compile_unit("class CompileTestKeywordHash; def value(a); a; end; end"))
      source = "CompileTestKeywordHash.new"
      assert_run({ x: 1 }, "#{source}.value(x: 1)")
      assert_run({ x: 1 }, "#{source}.value({ x: 1 })")
    end

    def test_required_keyword_parameters_metadata
      unit = Prism.compile("proc { |a, x:, y:| [a, x, y] }.call(1, x: 2, y: 3)", freeze: true).value
      graph = unit.graphs[1]
      assert_equal({ x: 1, y: 2 }, graph.signature.required_keywords)
      assert_equal([0, 1, 2], graph.blocks[0].params)
      assert_predicate(graph.signature.required_keywords, :frozen?)
      call = unit.graphs[0].blocks.flat_map(&:insns).find { |insn| insn.kind == :call && insn.data.name == :call }
      assert_equal(true, call.data.keywords)
      assert_predicate(call.data, :frozen?)
      assert_include(unit.disasm, "x: %1, y: %2")
      assert_include(unit.disasm, "[keywords]")
    end

    def test_optional_method_parameters
      vm.run(compile_unit("class CompileTestOptionals; def value(a = 1, b = a + 2); [a, b]; end; end"))
      source = "CompileTestOptionals.new"
      assert_run([1, 3], "#{source}.value")
      assert_run([4, 6], "#{source}.value(4)")
      assert_run([4, 8], "#{source}.value(4, 8)")
      assert_run([nil, nil], "#{source}.value(nil, nil)")
      assert_run_raises(ArgumentError, "#{source}.value(1, 2, 3)", "wrong number of arguments (given 3, expected 0..2)")
      vm.run(compile_unit("class CompileTestOptionalRequired; def value(a, b = a + 1); [a, b]; end; end"))
      source = "CompileTestOptionalRequired.new"
      assert_run([2, 3], "#{source}.value(2)")
      assert_run_raises(ArgumentError, "#{source}.value", "wrong number of arguments (given 0, expected 1..2)")
      assert_run([1, 2], "object = Object.new; def object.value(a = 1, b = a + 1); [a, b]; end; object.value")
    end

    def test_optional_parameter_defaults
      [
        [[[1, 2], [1, 2]], "events = []; p = proc { |a = (events << 1; 1), b = (events << 2; a + 1)| [a, b] }; result = p.call; [result, events]"],
        [[[4, 5], [2]], "events = []; p = proc { |a = (events << 1; 1), b = (events << 2; a + 1)| [a, b] }; result = p.call(4); [result, events]"],
        [[nil, []], "events = []; p = proc { |a = (events << 1)| a }; result = p.call(nil); [result, events]"],
        [3, "proc { |a = (if true; 3; else; 4; end)| a }.call"],
        [2, "proc { |a = proc { 2 }.call| a }.call"],
        [[1, 1], "proc { |a = 1, b = proc { a }.call| [a, b] }.call"],
        [[[1], [1]], "p = proc { |a = []| a << 1 }; [p.call, p.call]"],
        [4, "a = 3; proc { |b = (a + 1)| b }.call"],
        [1, "proc { |a = raise('default ran')| a }.call(1)"]
      ].each { |expected, source| assert_run(expected, source) }
      assert_run_raises(RuntimeError, "proc { |a = raise('default ran')| a }.call", "default ran")
    end

    def test_optional_block_parameters
      [
        [[1, 2], "proc { |a = 1, b = (a + 1)| [a, b] }.call"],
        [[3, 4], "proc { |a = 1, b = 2| [a, b] }.call([3, 4])"],
        [[3, 4], "proc { |a = 1, b = 2| [a, b] }.call(3, 4, 5)"],
        [[3, 4], "proc { |a = 1| a }.call([3, 4])"],
        [[[3, 4], []], "proc { |a = 1, *rest| [a, rest] }.call([3, 4])"],
        [[nil, 2], "proc { |a, b = 2| [a, b] }.call"],
        [[1, 2, nil], "proc { |a, b = 2, c| [a, b, c] }.call(1)"],
        [[1, 2, 3], "proc { |a, b = 2, c| [a, b, c] }.call(1, 3)"],
        [[1, 2, [], 3], "proc { |a, b = 2, *rest, c| [a, b, rest, c] }.call(1, 3)"],
        [[1, 4, [5], 6], "proc { |a, b = 2, *rest, c| [a, b, rest, c] }.call([1, 4, 5, 6])"],
        [[2, [], 3], "proc { |a = 2, *rest, b| [a, rest, b] }.call(3)"],
        [[2, 3], "proc { |a = 1, b| [a, b] }.call(2, 3, 4)"],
        [[1, nil], "proc { |a = 1, b| [a, b] }.call"]
      ].each { |expected, source| assert_run(expected, source) }
    end

    def test_optional_method_parameters_with_posts_and_rest
      vm.run(compile_unit("class CompileTestOptionalPosts; def value(a, b = 2, *rest, c); [a, b, rest, c]; end; end"))
      source = "CompileTestOptionalPosts.new"
      assert_run([1, 2, [], 3], "#{source}.value(1, 3)")
      assert_run([1, 4, [], 3], "#{source}.value(1, 4, 3)")
      assert_run([1, 4, [5], 6], "#{source}.value(1, 4, 5, 6)")
      assert_run_raises(ArgumentError, "#{source}.value(1)", "wrong number of arguments (given 1, expected 2+)")
      vm.run(compile_unit("class CompileTestOptionalPost; def value(a = 2, b); [a, b]; end; end"))
      source = "CompileTestOptionalPost.new"
      assert_run([2, 3], "#{source}.value(3)")
      assert_run([4, 3], "#{source}.value(4, 3)")
      assert_run_raises(ArgumentError, "#{source}.value(1, 2, 3)", "wrong number of arguments (given 3, expected 1..2)")
    end

    def test_optional_parameters_metadata
      unit = Prism.compile("proc { |a, b = 1, c = (b + 1), *rest, d| [a, b, c, rest, d] }", freeze: true).value
      graph = unit.graphs[1]
      signature = graph.signature
      assert_equal([0], signature.requireds)
      assert_equal([1, 3], signature.optionals)
      assert_equal([2, 4], signature.optional_specifieds)
      assert_equal(5, signature.rest)
      assert_equal([6], signature.posts)
      assert_equal((0..6).to_a, graph.blocks[0].params)
      assert_predicate(signature.optionals, :frozen?)
      assert_predicate(signature.optional_specifieds, :frozen?)
      assert_equal(2, graph.blocks.flat_map(&:insns).count { |insn| insn.kind == :branch_if })
      assert_include(unit.disasm, "%1?%2, %3?%4")
    end

    def test_post_block_parameters
      [
        [[nil, [], nil, nil], "proc { |a, *rest, b, c| [a, rest, b, c] }.call"],
        [[1, [], nil, nil], "proc { |a, *rest, b, c| [a, rest, b, c] }.call(1)"],
        [[1, [], 2, nil], "proc { |a, *rest, b, c| [a, rest, b, c] }.call(1, 2)"],
        [[1, [], 2, 3], "proc { |a, *rest, b, c| [a, rest, b, c] }.call(1, 2, 3)"],
        [[1, [2], 3, 4], "proc { |a, *rest, b, c| [a, rest, b, c] }.call(1, 2, 3, 4)"],
        [[1, [2], 3], "proc { |a, *rest, b| [a, rest, b] }.call([1, 2, 3])"],
        [[[], 1, nil], "proc { |*rest, a, b| [rest, a, b] }.call(1)"],
        [[[1, 2], 3], "proc { |*rest, a| [rest, a] }.call([1, 2, 3])"],
        [2, "proc { |*, a| a }.call([1, 2])"],
        [[1, 3], "proc { |a, *, b| [a, b] }.call([1, 2, 3])"],
        [[1, 2, [], nil], "proc { |a, b, *rest, c| [a, b, rest, c] }.call(1, 2)"],
        [3, "proc { |*rest, a| proc { |b| a + b }.call(1) }.call(2)"],
        [1, "proc { |_, *rest, _| _ }.call(1, 2)"],
        [[[1, 2], [3]], "p = proc { |*rest, a| rest << a }; [p.call(1, 2), p.call(3)]"]
      ].each { |expected, source| assert_run(expected, source) }
    end

    def test_post_method_parameters
      vm.run(compile_unit("class CompileTestPosts; def value(a, *rest, b, c); [a, rest, b, c]; end; end"))
      source = "CompileTestPosts.new"
      assert_run([1, [], 2, 3], "#{source}.value(1, 2, 3)")
      assert_run([1, [2, 3], 4, 5], "#{source}.value(1, 2, 3, 4, 5)")
      assert_run_raises(ArgumentError, "#{source}.value(1, 2)", "wrong number of arguments (given 2, expected 3+)")
      assert_run_raises(ArgumentError, "#{source}.value([1, 2, 3])", "wrong number of arguments (given 1, expected 3+)")
      assert_run([[], 1], "class CompileTestPostOnly; def value(*rest, a); [rest, a]; end; end; CompileTestPostOnly.new.value(1)")
      assert_run([1, 3], "class CompileTestPostAnonymous; def value(a, *, b); [a, b]; end; end; CompileTestPostAnonymous.new.value(1, 2, 3)")
      assert_run(2, "object = Object.new; def object.value(*, a); a; end; object.value(1, 2)")
    end

    def test_post_parameters_metadata
      unit = Prism.compile("proc { |a, *rest, b, c| [a, rest, b, c] }", freeze: true).value
      graph = unit.graphs[1]
      assert_equal([0], graph.signature.requireds)
      assert_equal(1, graph.signature.rest)
      assert_equal([2, 3], graph.signature.posts)
      assert_equal([0, 1, 2, 3], graph.blocks[0].params)
      assert_equal(true, graph.signature.autosplat)
      assert_predicate(graph.signature.posts, :frozen?)
      assert_equal([:store_lvar] * 4 + [:trace_b_call], graph.blocks[0].insns.first(5).map(&:kind))
      assert_include(unit.disasm, "g1(%0, *%1, %2, %3) [autosplat]")
      assert_empty(compile_unit("proc { _1 }").graphs[1].signature.posts)
    end

    def test_numbered_block_parameters
      [
        [[2, 3], "[1, 2].map { _1 + 1 }"],
        [nil, "proc { _1 }.call"],
        [1, "proc { _1 }.call(1, 2)"],
        [[1, 2], "proc { _1 }.call([1, 2])"],
        [[nil, nil], "proc { [_1, _2] }.call"],
        [[1, nil], "proc { [_1, _2] }.call(1)"],
        [[1, 2], "proc { [_1, _2] }.call([1, 2, 3])"],
        [3, "proc { _3 }.call(1, 2, 3, 4)"],
        [4, "proc { x = 1; x + _3 }.call([1, 2, 3])"],
        [9, "proc { _9 }.call(1, 2, 3, 4, 5, 6, 7, 8, 9)"],
        [[[:a, 1]], "{ a: 1 }.map { [_1, _2] }"],
        [[1, 3], "[proc { _1 }.call(1), proc { _2 }.call(2, 3)]"],
        [2, "proc { proc { _2 }.call(1, 2) }.call"],
        [4, "proc { for i in [1]; for j in [2]; a = _1 + i + j; end; end; a }.call(1)"],
        [3, "a = 1; proc { a + _1 }.call(2)"]
      ].each { |expected, source| assert_run(expected, source) }
    end

    def test_numbered_block_parameters_metadata
      unit = Prism.compile("proc { x = 1; _3 }", freeze: true).value
      graph = unit.graphs[1]
      assert_equal([0, 1, 2], graph.signature.requireds)
      assert_equal(graph.signature.requireds, graph.blocks[0].params)
      assert_equal(true, graph.signature.autosplat)
      assert_nil(graph.signature.rest)
      stores = graph.blocks[0].insns.first(3)
      assert_equal([:store_lvar] * 3, stores.map(&:kind))
      assert_equal([:_1, :_2, :_3], stores.map { |insn| insn.data.name })
      assert_equal([0, 1, 2], stores.map { |insn| insn.opnds[0] })
      assert_equal(false, compile_unit("proc { _1 }").graphs[1].signature.autosplat)
    end

    def test_it_block_parameter
      [
        [[2, 3], "[1, 2].map { it + 1 }"],
        [nil, "proc { it }.call"],
        [1, "proc { it }.call(1, 2)"],
        [[1, 2], "proc { it }.call([1, 2])"],
        [[nil, nil], "proc { [it, it] }.call"],
        [3, "a = 1; proc { a + it }.call(2)"],
        [[1, 2, 1], "proc { [it, proc { it }.call(2), it] }.call(1)"],
        [2, "proc { proc { it }.call(2) }.call(1)"],
        [3, "proc { for i in [1, 2]; a = it + i; end; a }.call(1)"],
        [4, "proc { for i in [1]; for j in [2]; a = it + i + j; end; end; a }.call(1)"],
        [[9, 9], "it = 9; [1, 2].map { it }"],
        [2, "proc { it = 2; it }.call(1)"],
        [3, "class CompileTestYieldIt; def value; yield; end; end; CompileTestYieldIt.new.value { it || 3 }"]
      ].each { |expected, source| assert_run(expected, source) }
    end

    def test_it_block_parameter_metadata
      unit = Prism.compile("proc { it }", freeze: true).value
      graph = unit.graphs[1]
      assert_equal([0], graph.signature.requireds)
      assert_nil(graph.signature.rest)
      assert_equal(false, graph.signature.autosplat)
      assert_equal([0], graph.blocks[0].params)
      assert_equal([:it], graph.locals.map(&:name))
      assert_equal([:store_lvar, :trace_b_call], graph.blocks[0].insns.first(2).map(&:kind))
      body = graph.blocks[0].insns.last.data
      assert_include(body.insns.map(&:kind), :load_lvar)
    end

    def test_rest_block_parameters
      [
        [[], "proc { |*args| args }.call"],
        [[1, 2], "proc { |*args| args }.call(1, 2)"],
        [[[1, 2]], "proc { |*args| args }.call([1, 2])"],
        [[nil], "proc { |*args| args }.call(nil)"],
        [[nil, []], "proc { |a, *rest| [a, rest] }.call"],
        [[1, []], "proc { |a, *rest| [a, rest] }.call(1)"],
        [[1, [2, 3]], "proc { |a, *rest| [a, rest] }.call(1, 2, 3)"],
        [[1, [2, 3]], "proc { |a, *rest| [a, rest] }.call([1, 2, 3])"],
        [[1, nil, []], "proc { |a, b, *rest| [a, b, rest] }.call(1)"],
        [[1, 2, [3]], "proc { |a, b, *rest| [a, b, rest] }.call([1, 2, 3])"],
        [1, "proc { |*| 1 }.call(2, 3)"],
        [nil, "proc { |a, *| a }.call"],
        [1, "proc { |a, *| a }.call([1, 2])"],
        [[[1], [2]], "[1, 2].map { |*args| args }"],
        [[1, 2], "proc { |*args| proc { args << 2 }.call; args }.call(1)"],
        [[2, 9], "args = 9; result = proc { |*args| args[0] }.call(2); [result, args]"],
        [[[1, 2], [3, 2]], "p = proc { |*args| args << 2 }; [p.call(1), p.call(3)]"]
      ].each { |expected, source| assert_run(expected, source) }
    end

    def test_rest_block_parameters_conversion
      calls = []
      value = Object.new
      converted = [1, 2, 3]
      value.define_singleton_method(:to_ary) { calls << :to_ary; converted }
      scope = Module.new
      scope.const_set(:Value, value)
      run = ->(source) { vm.run_frame(Compile::VM::Frame.new(compile_unit(source).graphs[0], scope, [scope, Object].freeze)) }
      assert_equal([value], run.call("proc { |*args| args }.call(Value)"))
      assert_empty(calls)
      assert_equal([1, [2, 3]], run.call("proc { |a, *rest| [a, rest] }.call(Value)"))
      assert_equal([:to_ary], calls)
      converted = nil
      assert_equal([value, []], run.call("proc { |a, *rest| [a, rest] }.call(Value)"))
      converted = 1
      assert_raise(TypeError) { run.call("proc { |a, *rest| [a, rest] }.call(Value)") }
    end

    def test_rest_block_parameters_metadata
      { "proc { |*args| args }" => [[], 0, false], "proc { |*| 1 }" => [[], 0, false],
        "proc { |a, *rest| rest }" => [[0], 1, true], "proc { |a, *| a }" => [[0], 1, true] }.each do |source, expected|
        graph = Prism.compile(source, freeze: true).value.graphs[1]
        signature = graph.signature
        assert_equal(expected, [signature.requireds, signature.rest, signature.autosplat])
        assert_equal([*signature.requireds, signature.rest], graph.blocks[0].params)
      end
      graph = compile_unit("proc { |a, *rest| rest }").graphs[1]
      assert_equal([:store_lvar, :store_lvar, :trace_b_call], graph.blocks[0].insns.first(3).map(&:kind))
    end

    def test_required_block_parameters_conversion
      calls = []
      value = Object.new
      converted = [1, 2]
      value.define_singleton_method(:to_ary) { calls << :to_ary; converted }
      scope = Module.new
      scope.const_set(:Value, value)
      graph = compile_unit("proc { |a, b| [a, b] }.call(Value)").graphs[0]
      assert_equal([1, 2], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      assert_equal([:to_ary], calls)

      converted = nil
      assert_equal([value, nil], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      converted = 1
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

    def test_block_parameters
      [
        [nil, "proc { |&block| block }.call"],
        [3, "proc { |&block| block.call }.call { 3 }"],
        [true, "proc { |&block| block.is_a?(Proc) }.call { 3 }"],
        [[1, 2, 3], "proc { |a, b = 2, &block| [a, b, block.call] }.call(1) { 3 }"],
        [[1, 2, [3], 4, 5], "proc { |a, b = 2, *rest, c, &block| [a, b, rest, c, block.call] }.call(1, 2, 3, 4) { 5 }"],
        [[1, 2, { z: 3 }, 4], "proc { |x:, y: 2, **rest, &block| [x, y, rest, block.call] }.call(x: 1, z: 3) { 4 }"],
        [[1, 2], "proc { |a, &block| a }.call([1, 2])"],
        [3, "proc { |&| 3 }.call { 4 }"],
        [3, "proc { |&| 3 }.call"],
        [3, "proc { |&block| proc { block.call } }.call { 3 }.call"],
        [3, "proc { |&block| block = 3; block }.call { 4 }"]
      ].each { |expected, source| assert_run(expected, source) }
    end

    def test_method_block_parameters
      vm.run(compile_unit(<<~RUBY))
        class CompileTestBlockParameter
          def capture(&block)
            block
          end

          def mixed(a, b = 2, *rest, c, x:, y: 5, **keywords, &block)
            [a, b, rest, c, x, y, keywords, block.call]
          end

          def make(&outer)
            proc { |&inner| [inner.call, yield, outer.call] }
          end

          def anonymous(&)
            yield
          end
        end
      RUBY
      assert_run(nil, "CompileTestBlockParameter.new.capture")
      assert_run(3, "CompileTestBlockParameter.new.capture { 3 }.call")
      assert_run([1, 2, [3], 4, 5, 5, { z: 6 }, 7], "CompileTestBlockParameter.new.mixed(1, 2, 3, 4, x: 5, z: 6) { 7 }")
      assert_run([:inner, :outer, :outer], "CompileTestBlockParameter.new.make { :outer }.call { :inner }")
      assert_run(3, "CompileTestBlockParameter.new.anonymous { 3 }")
      object = vm.run(compile_unit("CompileTestBlockParameter.new"))
      callback = proc { 3 }
      assert_same(callback, object.capture(&callback))
    end

    def test_block_parameter_signature
      unit = compile_unit("proc { |a, &block| block }")
      graph = unit.graphs[1]
      signature = graph.signature
      assert_not_nil(signature.block)
      assert_include(graph.blocks[0].params, signature.block)
      assert_equal(false, signature.autosplat)
      assert_include(unit.disasm, "&%#{signature.block}")
    end

    def test_implicit_rest_block_parameters
      [
        [1, "proc { |a,| a }.call([1, 2])"],
        [1, "proc { |a,| a }.call(1, 2)"],
        [1, "proc { |a,| a }.call(1)"],
        [nil, "proc { |a,| a }.call"],
        [nil, "proc { |a,| a }.call([])"],
        [nil, "proc { |a,| a }.call(nil)"],
        [[1, 2], "proc { |a, b,| [a, b] }.call([1, 2, 3])"],
        [[1, nil], "proc { |a, b,| [a, b] }.call([1])"],
        [[1, 3], "[[1, 2], [3, 4]].map { |a,| a }"],
        [[1, 2], "proc { |a| a }.call([1, 2])"],
        [[1, 2], "proc { |a,| a }.call([[1, 2], 3])"]
      ].each { |expected, source| assert_run(expected, source) }

      signature = compile_unit("proc { |a,| a }").graphs[1].signature
      assert_equal(true, signature.autosplat)
      assert_equal(1, signature.requireds.length)
      assert_nil(signature.rest)
    end

    def test_implicit_rest_block_parameter_conversion
      scope = Module.new
      events = []
      converted = [1, 2]
      input = Object.new
      input.define_singleton_method(:to_ary) { events << :convert; converted }
      scope.const_set(:Input, input)
      graph = compile_unit("proc { |a,| a }.call(Input)").graphs[0]
      run = -> { vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)) }
      assert_equal(1, run.call)
      assert_equal([:convert], events)
      events.clear
      converted = nil
      assert_same(input, run.call)
      assert_equal([:convert], events)
      converted = 1
      assert_raise(TypeError) { run.call }
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

    def test_yield_arguments
      [
        [[1, 2], "yield(1, 2)", "", "{ |*values| values }"],
        [[[1, 2]], "yield([1, 2])", "", "{ |*values| values }"],
        [[1, 2], "yield([1, 2])", "", "{ |a, b| [a, b] }"],
        [[], "yield(*nil)", "", "{ |*values| values }"],
        [[1, 2, 3, 4], "yield(1, *[2, 3], 4)", "", "{ |*values| values }"],
        [[1, 2], "yield(*[1], *[2])", "", "{ |*values| values }"],
        [[[1, 2], { key: 3 }], "yield(*args, **kwargs)", "(1, 2, key: 3)", "{ |*values, **keys| [values, keys] }"],
        [{ key: 3 }, "yield(key: 3)", "", "{ |value| value }"],
        [{ key: 3 }, "yield(**kwargs)", "(key: 3)", "{ |key:| { key: key } }"],
        [:ok, "yield(**{})", "(&-> { :ok })", ""],
        [3, "yield(1, 2)", "(&->(a, b) { a + b })", ""],
        [3, "yield(key: 3)", "(&->(key:) { key })", ""],
        [[1, 2], "proc { yield(1, 2) }.call", "", "{ |a, b| [a, b] }"],
        [3, "yield(1, 2)", "", "{ |a, b| break a + b }"]
      ].each_with_index do |(expected, expression, arguments, block), index|
        assert_run(expected, <<~RUBY)
          class CompileTestYieldArguments#{index}
            def value(*args, **kwargs)
              #{expression}
            end
          end
          CompileTestYieldArguments#{index}.new.value#{arguments} #{block}
        RUBY
      end
    end

    def test_yield_anonymous_arguments
      assert_run([[1, 2], { key: 3 }], <<~RUBY)
        class CompileTestYieldAnonymousArguments
          def value(*, **)
            yield(*, **)
          end
        end
        CompileTestYieldAnonymousArguments.new.value(1, 2, key: 3) { |*args, **kwargs| [args, kwargs] }
      RUBY
    end

    def test_yield_argument_evaluation
      assert_run([[1, 2], { key: 3 }, [:first, :splat, :keyword]], <<~RUBY)
        class CompileTestYieldArgumentEvaluation
          def value(events)
            yield((events << :first; 1), *(events << :splat; [2]), key: (events << :keyword; 3))
          end
        end
        events = []
        CompileTestYieldArgumentEvaluation.new.value(events) { |*args, **kwargs| [args, kwargs, events] }
      RUBY
      assert_run_raises(RuntimeError, <<~RUBY, "argument")
        class CompileTestYieldArgumentFailure
          def value
            yield(raise 'argument')
          end
        end
        CompileTestYieldArgumentFailure.new.value
      RUBY
    end

    def test_yield_argument_metadata
      unit = Prism.compile("def compile_test_yield_metadata(*args, **kwargs); yield(1, *args, **kwargs); end", freeze: true).value
      insn = unit.graphs.flat_map(&:blocks).flat_map(&:insns).find { |candidate| candidate.kind == :yield }
      assert_equal(4, insn.opnds.length)
      assert_equal(true, insn.data.splat)
      assert_equal(true, insn.data.keywords)
      assert_equal(false, insn.data.block)
      assert_nil(insn.data.name)
      assert_predicate(insn.data, :frozen?)
      assert_match(/yield\([^\n]+\) \[splat\] \[keywords\]/, unit.disasm)
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
      body = child.blocks[0].insns.last.data
      assert_equal([:trace_b_return, :return_value], body.insns.last(2).map(&:kind))
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

    def test_for_effect_context_preserves_block_result
      assert_run([1, 2], <<~RUBY)
        class CompileTestForBodyResult
          attr_reader :result
          def each
            @result = yield 1
            :ignored
          end
        end
        collection = CompileTestForBodyResult.new
        for i in collection
          [i, 2]
        end
        collection.result
      RUBY
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
        assert_equal([:trace_b_return, :return_value], tail.last(2).map(&:kind))
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

    def test_for_index_target
      assert_run([1, 2, 3], "a = []; i = 0; for a[i] in [1, 2, 3]; i += 1; end; a")
      assert_run({ a: 2 }, "h = {}; for h[:a] in [1, 2]; end; h")
      assert_run([0, 4, 5, 3], "a = [0, 1, 2, 3]; for a[1, 2] in [[4, 5]]; end; a")
      assert_run([], "for (raise('receiver ran'))[raise('index ran')] in []; end")
      assert_run_raises(RuntimeError, "for [][raise('index failed')] in [1]; end", "index failed")
      assert_run_raises(NoMethodError, "for nil[0] in [1]; end")
    end

    def test_for_index_target_evaluation
      scope = Module.new
      events = []
      receiver = Object.new
      receiver.define_singleton_method(:[]=) { |*args| events << [:write, args]; :ignored }
      collection = Object.new
      collection.define_singleton_method(:each) do |&block|
        events << :each
        block.call(1)
        block.call(2, 3)
        :finished
      end
      scope.const_set(:Receiver, receiver)
      scope.const_set(:Collection, collection)
      scope.const_set(:Events, events)
      source = "for (Events << :receiver; Receiver)[(Events << :first; 4), (Events << :second; 5)] in (Events << :collection; Collection); Events << :body; end"
      graph = compile_unit(source).graphs[0]
      assert_equal(:finished, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      assert_equal([:collection, :each, :receiver, :first, :second, [:write, [4, 5, 1]], :body,
                    :receiver, :first, :second, [:write, [4, 5, 2]], :body], events)
      events.clear
      graph = compile_unit("for Receiver[] in [[1, 2]]; end").graphs[0]
      assert_equal([[1, 2]], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      assert_equal([[:write, [[1, 2]]]], events)
    end

    def test_for_call_target
      scope = Module.new
      events = []
      receiver = Object.new
      receiver.define_singleton_method(:value=) { |value| events << [:write, value]; :ignored }
      collection = Object.new
      collection.define_singleton_method(:each) do |&block|
        events << :each
        block.call(1)
        block.call(2, 3)
        block.call([4, 5])
        block.call
        :finished
      end
      scope.const_set(:Receiver, receiver)
      scope.const_set(:Collection, collection)
      scope.const_set(:Events, events)
      source = "for (Events << :receiver; Receiver).value in (Events << :collection; Collection); Events << :body; end"
      graph = compile_unit(source).graphs[0]
      assert_equal(:finished, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      assert_equal([:collection, :each, :receiver, [:write, 1], :body, :receiver, [:write, 2], :body,
                    :receiver, [:write, [4, 5]], :body, :receiver, [:write, nil], :body], events)
      assert_run([], "for (raise('receiver ran')).value in []; end")
      assert_run_raises(RuntimeError, "for (raise('receiver failed')).value in [1]; end", "receiver failed")
      assert_run_raises(RuntimeError, "object = Object.new; def object.value=(v); raise 'setter failed'; end; for object.value in [1]; end", "setter failed")
    end

    def test_for_call_target_safe_navigation
      scope = Module.new
      events = []
      receiver = Object.new
      receiver.define_singleton_method(:value=) { |value| events << [:write, value] }
      scope.const_set(:Receivers, [nil, receiver])
      scope.const_set(:Events, events)
      source = "for (Events << :receiver; Receivers.shift)&.value in [1, 2]; Events << :body; end"
      graph = compile_unit(source).graphs[0]
      assert_equal([1, 2], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      assert_equal([:receiver, :body, :receiver, [:write, 2], :body], events)
      assert_run_raises(NoMethodError, "for false&.missing in [1]; end")
      assert_run([], "for (raise('receiver ran'))&.value in []; end")
      loop_graph = compile_unit("for nil&.value in [1]; end").graphs[1]
      assert_include(loop_graph.blocks.flat_map(&:insns).map(&:kind), :nil_p)
      assert_include(loop_graph.blocks.flat_map(&:insns).map(&:kind), :branch_if)
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
      machine.define_singleton_method(:run_frame) do |frame, args = [], kwargs = {}, passed_block = frame.block|
        frames << frame
        super(frame, args, kwargs, passed_block)
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
      call_insn = insns.find { |insn| insn.kind == :call && insn.data.block }
      assert_equal(:block, block_insn.data.kind)
      assert_equal(:each, call_insn.data.name)
      assert_equal(block_insn.opnds[0], call_insn.opnds[-1])
      assert_same(unit.graphs[0].scope, block_insn.data.scope)
    end

    def test_multi_write
      [
        [[1, 2], "a, b = 1, 2; [a, b]"],
        [[1, nil], "a, b = 1; [a, b]"],
        [[nil, nil], "a, b = nil; [a, b]"],
        [[nil, nil], "a, b = []; [a, b]"],
        [[2, 1], "a = 1; b = 2; a, b = b, a; [a, b]"],
        [[1, [2, 3], 4], "a, *b, c = [1, 2, 3, 4]; [a, b, c]"],
        [[1, [], 2, nil], "a, *b, c, d = [1, 2]; [a, b, c, d]"],
        [[1, 4], "a, *, b = [1, 2, 3, 4]; [a, b]"],
        [[1, 2], "*a = [1, 2]; a"],
        [1, "a, = [1, 2]; a"],
        [[1, 2, 3, [4], 5], "a, (b, c), *d, e = [1, [2, 3], 4, 5]; [a, b, c, d, e]"],
        [[2, 3], "a, (a, b) = [1, [2, 3]]; [a, b]"],
        [[1, 2, 1, 2], "a, b = (c, d = [1, 2]); [a, b, c, d]"],
        [[1, 1, nil], "result = (a, b = 1); [result, a, b]"],
        [[1, [1]], "result = (*a = 1); [result, a]"],
        [[true, 1, 2], "input = [1, 2]; result = (a, b = input); [result.equal?(input), a, b]"],
        [1, "a = 0; proc { a, b = 1, 2 }.call; a"],
        [[[2, 3], [1, 2]], "input = [1, 2]; a, *b = input; b << 3; [b, input]"]
      ].each { |expected, source| assert_run(expected, source) }
    end

    def test_multi_write_splatted_index_targets
      assert_run([0, 1, 2], 'a = [0, 0, 0]; a[*[1]], a[*[2]] = 1, 2; a')
      setup = <<~RUBY
        target = []
        def target.[]=(*arguments)
          self << arguments
          :setter_return
        end
      RUBY
      [
        'target[*[1]], target[*[2]] = 7, 8',
        'target[0, *[1, 2], 3], target[*[], 4] = 7, 8',
        'target[*[1], *[2]], target[[3, 4]] = 7, 8',
        'target[*nil], target[*[]] = 7, 8',
        'target[*[1]], (target[*[2]], target[*[3]]) = 7, [8, 9]'
      ].each do |assignment|
        source = setup + "result = (#{assignment}); [result, target]"
        assert_run(eval(source), source)
      end
    end

    def test_multi_write_splatted_index_target_evaluation_order
      assert_run([[:receiver, :indices, :to_a, :receiver, :indices, :to_a, :rhs, :write, :write], [[1, 7], [1, 8]]], <<~RUBY)
        events = []
        target = []
        target.define_singleton_method(:[]=) { |*args| events << :write; self << args }
        indices = Object.new
        indices.define_singleton_method(:to_a) { events << :to_a; [1] }
        indices.define_singleton_method(:to_ary) { raise "to_ary must not be called" }
        receiver = -> { events << :receiver; target }
        index = -> { events << :indices; indices }
        receiver.call[*index.call], receiver.call[*index.call] = (events << :rhs; [7, 8])
        [events, target]
      RUBY
    end

    def test_splatted_index_targets_in_for_and_rescue
      assert_run([[1, 2, 7], [1, 2, 8]], <<~RUBY)
        target = []
        def target.[]=(*arguments); self << arguments; end
        for target[*[1, 2]] in [7, 8]
        end
        target
      RUBY
      assert_run("failure", <<~RUBY)
        target = []
        def target.[]=(*arguments); self << arguments; end
        begin
          raise "failure"
        rescue => target[*[1, 2]]
          target[0][2].message
        end
      RUBY
    end

    def test_multi_write_implicit_rest
      [
        [nil, "a, = []; a"],
        [nil, "a, = nil; a"],
        [1, "a, = 1; a"],
        [[1, 2], "a, b, = [1, 2, 3]; [a, b]"],
        [[1, nil], "a, b, = [1]; [a, b]"],
        [[1, 3], "(a,), b = [1, 2], 3; [a, b]"],
        [[1, 3], "a, (b,) = 1, [3, 4]; [a, b]"],
        [[1, 2, 3], "a, (b, c,), = [1, [2, 3, 4], 5]; [a, b, c]"],
        [[true, 1], "input = [1, 2]; result = (a, = input); [result.equal?(input), a]"],
        [[1, 3], "out = []; for a, in [[1, 2], [3, 4]]; out << a; end; out"]
      ].each { |expected, source| assert_run(expected, source) }
    end

    def test_multi_write_implicit_rest_conversion
      scope = Module.new
      events = []
      item = Object.new
      item.define_singleton_method(:to_ary) { events << :convert; [1, 2, 3] }
      receiver = Object.new
      receiver.define_singleton_method(:value=) { |value| events << [:write, value] }
      scope.const_set(:Item, item)
      scope.const_set(:Receiver, receiver)
      scope.const_set(:Events, events)
      source = "result = ((Events << :receiver; Receiver).value, = (Events << :rhs; Item)); result"
      graph = compile_unit(source).graphs[0]
      assert_same(item, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      assert_equal([:receiver, :rhs, :convert, [:write, 1]], events)
    end

    def test_multi_write_evaluation
      scope = Module.new
      events = []
      receiver = Object.new
      receiver.define_singleton_method(:[]=) { |index, value| events << [:index_write, index, value]; :ignored }
      receiver.define_singleton_method(:value=) { |value| events << [:setter, value]; :ignored }
      item = Object.new
      fail_conversion = false
      item.define_singleton_method(:to_ary) do
        events << :convert
        raise 'conversion failed' if fail_conversion
        [1, 2]
      end
      scope.const_set(:Receiver, receiver)
      scope.const_set(:Item, item)
      scope.const_set(:Events, events)
      source = "(Events << :receiver; Receiver)[(Events << :index; 0)], (Events << :call_receiver; Receiver).value = (Events << :rhs; Item)"
      graph = compile_unit(source).graphs[0]
      frame = -> { Compile::VM::Frame.new(graph, scope, [scope, Object].freeze) }
      assert_same(item, vm.run_frame(frame.call))
      assert_equal([:receiver, :index, :call_receiver, :rhs, :convert, [:index_write, 0, 1], [:setter, 2]], events)
      events.clear
      fail_conversion = true
      assert_raise_with_message(RuntimeError, "conversion failed") { vm.run_frame(frame.call) }
      assert_equal([:receiver, :index, :call_receiver, :rhs, :convert], events)
    end

    def test_multi_write_nested_conversion_order
      scope = Module.new
      events = []
      item = Object.new
      item.define_singleton_method(:to_ary) { events << [:convert, scope.const_get(:A)]; [2, 3] }
      scope.const_set(:Item, item)
      scope.const_set(:Events, events)
      source = "(Events << :a; self)::A, ((Events << :b; self)::B, (Events << :c; self)::C) = (Events << :rhs; [1, Item]); [A, B, C]"
      graph = compile_unit(source).graphs[0]
      assert_equal([1, 2, 3], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      assert_equal([:a, :b, :c, :rhs, [:convert, 1]], events)
    end

    def test_multi_write_variable_kinds
      scope = Class.new
      graph = compile_unit("@a, @@b, $compile_test_multi_write, A = 1, 2, 3, 4; [@a, @@b, $compile_test_multi_write, A]").graphs[0]
      assert_equal([1, 2, 3, 4], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
    ensure
      $compile_test_multi_write = nil
    end

    def test_for_multi_target
      [
        [[[1, 2], [3, 4]], "out = []; for a, b in [[1, 2], [3, 4]]; out << [a, b]; end; out"],
        [[1, nil], "for a, b in [1]; end; [a, b]"],
        [[nil, nil], "for a, b in Array.new(1); end; [a, b]"],
        [[nil, nil], "for a, b in []; end; [a, b]"],
        [[1, [2, 3], 4], "for a, *b, c in [[1, 2, 3, 4]]; end; [a, b, c]"],
        [[1, [], 2, nil], "for a, *b, c, d in [[1, 2]]; end; [a, b, c, d]"],
        [[1, [], nil], "for a, *b, c in [[1]]; end; [a, b, c]"],
        [[1, 4], "for a, *, b in [[1, 2, 3, 4]]; end; [a, b]"],
        [1, "for a, in [[1, 2]]; end; a"],
        [[1, 2], "for *a in [[1, 2]]; end; a"],
        [[1, 2, 3], "for a, (b, c) in [[1, [2, 3]]]; end; [a, b, c]"],
        [[1, 2, nil], "for a, (b, c) in [[1, 2]]; end; [a, b, c]"],
        [[1, 2, [3, 4], 5], "for a, (b, *c), d in [[1, [2, 3, 4], 5]]; end; [a, b, c, d]"],
        [2, "for a, a in [[1, 2]]; end; a"],
        [[[1, 2]], "for a, b in [[1, 2]]; 99; end"],
        [[[:a, 1]], "out = []; for a, b in { a: 1 }; out << [a, b]; end; out"],
        [[[2, 3], [1, 2]], "items = [[1, 2]]; for a, *b in items; b << 3; end; [b, items[0]]"]
      ].each do |expected, source|
        assert_run(expected, source)
      end
    end

    def test_for_multi_target_calls_and_indices
      scope = Module.new
      events = []
      receiver = Object.new
      receiver.define_singleton_method(:[]=) { |index, value| events << [:index_write, index, value] }
      receiver.define_singleton_method(:value=) { |value| events << [:setter, value] }
      item = Object.new
      item.define_singleton_method(:to_ary) { events << :convert; [1, 2] }
      scope.const_set(:Receiver, receiver)
      scope.const_set(:Items, [item])
      scope.const_set(:Events, events)
      source = "for (Events << :index_receiver; Receiver)[(Events << :index; 0)], (Events << :call_receiver; Receiver).value in Items; Events << :body; end"
      graph = compile_unit(source).graphs[0]
      vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze))
      assert_equal([:index_receiver, :index, :call_receiver, :convert, [:index_write, 0, 1], [:setter, 2], :body], events)
    end

    def test_for_multi_target_signature
      unit = compile_unit("for a, b in [[1, 2]]; end")
      graph = unit.graphs[1]
      assert_empty(graph.signature.requireds)
      assert_equal(0, graph.signature.rest)
      assert_equal(false, graph.signature.autosplat)
      assert_equal([0], graph.blocks[0].params)
      assert_include(unit.disasm, "coerce_array_to_ary(")
      assert_include(unit.disasm, "expand_array")
    end

    def test_for_multi_target_yields
      collection = Object.new
      def collection.each
        yield
        yield nil
        yield 1
        yield 2, 3, 4
        yield [5, 6]
        :finished
      end
      scope = Module.new
      scope.const_set(:Items, collection)
      graph = compile_unit("out = []; result = (for a, *b in Items; out << [a, b]; end); [result, out]").graphs[0]
      assert_equal([:finished, [[nil, []], [nil, []], [1, []], [2, [3, 4]], [5, [6]]]], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      graph = compile_unit("out = []; for *a in Items; out << a; end; out").graphs[0]
      assert_equal([[], [nil], [1], [2, 3, 4], [5, 6]], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
    end

    def test_for_multi_target_parent_order
      events = []
      item = Object.new
      item.define_singleton_method(:to_ary) { events << :convert; [1, 2, 3, 4, 5] }
      scope = Module.new
      scope.const_set(:Items, [item])
      scope.const_set(:Events, events)
      targets = (0...5).map { |i| "(Events << #{i}; self)::A#{i}" }.join(", ")
      graph = compile_unit("for #{targets} in Items; Events << :body; end; [A0, A1, A2, A3, A4]").graphs[0]
      assert_equal([1, 2, 3, 4, 5], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      assert_equal([0, 1, 2, 3, 4, :convert, :body], events)

      scope = Module.new
      graph = compile_unit("a = 9; events = []; for a, (events << a; self)::A in [[1, 2]]; end; [a, A, events]").graphs[0]
      assert_equal([1, 2, [9]], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      graph = compile_unit("a = []; for (a << 1; self)::A, b in []; end; a").graphs[0]
      assert_equal([], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
    end

    def test_for_multi_target_nested_conversion_order
      events = []
      scope = Module.new
      item = Object.new
      item.define_singleton_method(:to_ary) { events << [:convert, scope.const_get(:A)]; [2, 3] }
      scope.const_set(:Items, [[1, item]])
      scope.const_set(:Events, events)
      source = "for (Events << :a; self)::A, ((Events << :b; self)::B, (Events << :c; self)::C) in Items; Events << :body; end; [A, B, C]"
      graph = compile_unit(source).graphs[0]
      assert_equal([1, 2, 3], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      assert_equal([:a, :b, :c, [:convert, 1], :body], events)
    end

    def test_for_multi_target_conversion
      item = Object.new
      scope = Module.new
      scope.const_set(:Items, [item])
      graph = compile_unit("for a, b in Items; end; [a, b]").graphs[0]
      conversion = -> { nil }
      item.define_singleton_method(:to_ary) { conversion.call }
      assert_equal([item, nil], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      conversion = -> { 1 }
      assert_raise(TypeError) { vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)) }
      conversion = -> { raise "conversion failed" }
      assert_raise_with_message(RuntimeError, "conversion failed") { vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)) }
    end

    def test_for_multi_target_variable_kinds
      scope = Class.new
      graph = compile_unit("for @a, @@b, $compile_test_multi, A in [[1, 2, 3, 4]]; end; [@a, @@b, $compile_test_multi, A]").graphs[0]
      assert_equal([1, 2, 3, 4], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
    ensure
      $compile_test_multi = nil
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
      machine.define_singleton_method(:run_frame) do |frame, args = [], kwargs = {}, passed_block = frame.block|
        frames << frame
        super(frame, args, kwargs, passed_block)
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

    def test_regexp_options
      ["", "i", "m", "x", "imx", "n", "e", "s", "u", "nix", "eim", "smx", "uimx", "nu", "un"].each do |options|
        [
          "/a b/#{options}",
          "[/a\#{\" b\"}/#{options}][0]",
          "part = ' b'; /a\#{part}/#{options}",
          "part = ' b'; /a\#{part}/#{options}o"
        ].each do |source|
          expected = eval("/a b/#{options}")
          actual = vm.run(compile_unit(source))
          assert_equal([expected.options, expected.encoding, expected.source.bytes, expected.source.encoding], [actual.options, actual.encoding, actual.source.bytes, actual.source.encoding], source)
          assert_equal(expected.match?("A b\n"), actual.match?("A b\n"), source)
          assert_predicate(actual, :frozen?)
        end
      end
    end

    def test_regexp_source_encodings
      [
        ["US-ASCII", '/\xFF/'],
        ["US-ASCII", '/\u00E9/'],
        ["ISO-8859-1", '/\xE9/'],
        ["ASCII-8BIT", '/\xFF/n'],
        ["UTF-8", '/\xC3\xA9/u'],
        ["UTF-8", '/\xA4\xA2/e'],
        ["UTF-8", '/\x82\xA0/s'],
        ["US-ASCII", 'part = "a"; /#{part}/'],
        ["ASCII-8BIT", 'part = "a"; /#{part}/'],
        ["ISO-8859-1", 'part = "a"; /#{part}/'],
        ["US-ASCII", 'part = "a"; /\xFF#{part}/n'],
        ["UTF-8", 'part = "a"; /\xA4\xA2#{part}/e'],
        ["UTF-8", 'part = "a"; /\x82\xA0#{part}/s'],
        ["ASCII-8BIT", 'part = "\u00E9"; /#{part}/u'],
        ["UTF-8", 'part = "\xA4\xA2".force_encoding("EUC-JP"); /#{part}/e'],
        ["UTF-8", 'part = "\x82\xA0".force_encoding("Windows-31J"); /#{part}/s'],
        ["ASCII-8BIT", '[/a#{"\u00E9"}/u][0]'],
        ["US-ASCII", '[/a#{"\xFF"}/n][0]'],
        ["UTF-8", 'part = "\u00E9"; /#{part}/e'],
        ["UTF-8", 'part = "\u00E9"; /#{part}/s'],
        ["UTF-8", 'part = "\xE9".force_encoding("ISO-8859-1"); /#{part}/u']
      ].each do |encoding, body|
        source = "# encoding: #{encoding}\n# frozen_string_literal: false\n#{body}"
        expected = eval(source)
        actual = vm.run(compile_unit(source))
        assert_equal([expected.options, expected.encoding, expected.source.bytes, expected.source.encoding], [actual.options, actual.encoding, actual.source.bytes, actual.source.encoding], source)
        assert_predicate(actual, :frozen?)
      end
    end

    def test_regexp_noencoding_rejects_nonbinary_interpolation
      source = 'part = "\u00E9"; /#{part}/n'
      assert_raise(RegexpError) { eval(source) }
      assert_run_raises(RegexpError, source)
    end

    def test_once_regexp_encoding_options
      assert_run([1, true, Encoding::EUC_JP, Regexp::FIXEDENCODING], <<~'RUBY')
        count = 0
        regexps = 2.times.map { /a#{count += 1}/eo }
        [count, regexps[0].equal?(regexps[1]), regexps[0].encoding, regexps[0].options]
      RUBY
    end

    def test_match_last_line_regexp_options
      [
        '$_ = "\xFF".b; if /\xFF/n; true; else; false; end',
        '$_ = "\xA4\xA2".force_encoding("EUC-JP"); if /\xA4\xA2/e; true; else; false; end',
        '$_ = "\x82\xA0".force_encoding("Windows-31J"); if /\x82\xA0/s; true; else; false; end',
        'part = "a"; $_ = "\xA4\xA2a".force_encoding("EUC-JP"); if /\xA4\xA2#{part}/e; true; else; false; end'
      ].each { |source| assert_run(true, source) }
    end

    def test_once_regexp
      [
        'count = 0; values = 3.times.map { /#{count += 1}/o }; [count, values.map { |r| r.source }, values[0].equal?(values[1]), values[0].frozen?]',
        'count = 0; 2.times { /#{count += 1}/ }; count',
        'count = 0; 2.times { /#{/#{count += 1}/o.source}/o }; count',
        'count = 0; 2.times { /#{begin; count += 1; raise "handled"; rescue; "ok"; end}/o }; count',
        '$_ = "a"; pattern = /#{($_ = "b"; "b")}/o; [$_, pattern.source]',
        '$_ = "a"; /#{$_}/o.source',
        '/(a)/ =~ "a"; pattern = /#{(/(b)/ =~ "b"; "b")}/o; [$1, pattern.source]',
        '/(a)/ =~ "a"; /#{($1 || "none")}/o.source',
        'count = 0; values = [/#{count += 1}/o, /#{count += 1}/o]; [count, values[0].equal?(values[1])]',
        'class CompileOnceReceiver; def pattern(value); /#{value}/o; end; end; [CompileOnceReceiver.new.pattern("a").source, CompileOnceReceiver.new.pattern("b").source]',
        'closures = 2.times.map { proc { |value| /#{value}/o } }; [closures[0].call("a").source, closures[1].call("b").source]',
        'count = 0; 2.times { /#{if true; count += 1; "a"; else; "b"; end}/o }; count',
        'count = 0; values = 2.times.map { /#{count += 1} a/imxo }; [count, values[0].options]',
        'def compile_once_local; /#{captured = 1}/o; captured; end; 2.times.map { compile_once_local }'
      ].each { |source| capture_warnings { assert_run(eval(source), source) } }
    end

    def test_once_regexp_retry_and_reentry
      [
        'count = 0; results = []; 3.times { begin; results << /#{count += 1; raise "failed" if count == 1; "ok"}/o.source; rescue RuntimeError; results << :failed; end }; [count, results]',
        'count = 0; results = []; 3.times { begin; results << /#{(count += 1) == 1 ? "[" : "ok"}/o.source; rescue RegexpError; results << :failed; end }; [count, results]',
        'def compile_once_recursive(n); /#{n == 0 ? "inner" : compile_once_recursive(n - 1).source + "outer"}/o; end; [compile_once_recursive(1).source, compile_once_recursive(0).source]',
        'def compile_once_return; /#{return :left}/o; end; 2.times.map { compile_once_return }',
        'count = 0; results = 2.times.map { count += 1; /#{next :left}/o }; [count, results]',
        'count = 0; result = while (count += 1) < 3; /#{break :left}/o; end; [count, result]',
        'count = 0; result = []; while count < 2; count += 1; /#{next}/o; result << :unreachable; end; [count, result]'
      ].each { |source| capture_warnings { assert_run(eval(source), source) } }
    end

    def test_once_match_last_line
      [
        [1, '$_ = "a"; count = 0; while /#{count += 1; "a"}/o; $_ = "b"; end; count'],
        [1, '$_ = "a"; if /#{($_ = "b"; "b")}/o; 1; else; 2; end'],
        [1, '$_ = "a"; if /#{$_}/o; 1; else; 2; end'],
        ["b", '$_ = "ab"; if /a(#{"b"})/o; $1; end'],
        [[1, ["a", "a"]], 'count = 0; matches = []; ["a", "b", "a"].each { |line| $_ = line; if /#{count += 1; "a"}/o; matches << $&; end }; [count, matches]']
      ].each { |expected, source| assert_run(expected, source) }
    ensure
      TOPLEVEL_BINDING.eval("$_ = nil")
    end

    def test_once_threads_share_initialization
      scope = Module.new
      entered = Queue.new
      release = Queue.new
      calls = Queue.new
      scope.define_singleton_method(:piece) { calls << true; entered << true; release.pop; "pattern" }
      graph = compile_unit('/#{piece}/o').graphs[0]
      threads = []
      threads << Thread.new { vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)) }
      entered.pop
      threads << Thread.new { vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)) }
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
      Thread.pass while threads.last.status == "run" && Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
      assert_equal("sleep", threads.last.status)
      assert_equal(1, calls.size)
      2.times { release << true }
      threads.each { |thread| assert_not_nil(thread.join(5)) }
      assert_same(threads[0].value, threads[1].value)
    ensure
      2.times { release << true } if release
      threads&.each { |thread| thread.kill; thread.join(5) }
    end

    def test_once_retries_after_thread_cancellation
      scope = Module.new
      entered = Queue.new
      release = Queue.new
      scope.define_singleton_method(:piece) { entered << true; release.pop; "pattern" }
      graph = compile_unit('/#{piece}/o').graphs[0]
      threads = []
      threads << Thread.new { vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)) }
      entered.pop
      threads << Thread.new { vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)) }
      threads.first.kill
      assert_not_nil(threads.first.join(5))
      release << true
      assert_not_nil(threads.last.join(5))
      assert_equal("pattern", threads.last.value.source)
      assert_same(threads.last.value, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
    ensure
      2.times { release << true } if release
      threads&.each { |thread| thread.kill; thread.join(5) }
    end

    def test_once_site_lifetime
      unit = compile_unit('count = 0; 2.times { /#{count += 1}/o }; count')
      assert_equal(1, vm.run(unit))
      GC.start
      assert_equal(0, vm.run(unit))
      assert_equal(1, Compile::VM.new.run(unit))
      assert_equal(1, vm.run(compile_unit('count = 0; 2.times { /#{count += 1}/o }; count')))
    end

    def test_once_ir
      unit = Prism.compile('part = "a"; /#{part}/o', freeze: true).value
      graph = unit.graphs[0]
      insns = graph.blocks.flat_map(&:insns)
      once = insns.find { |insn| insn.kind == :once }
      site, region = once.data
      assert_equal(0, site.id)
      assert_predicate(site, :frozen?)
      assert_predicate(once.data, :frozen?)
      assert_equal(:once, region.kind)
      assert_same(graph.regions[0], region.parent)
      assert_include(region.entry.insns.map(&:kind), :load_lvar)
      assert_equal(:once_return, region.entry.insns.last.kind)
      assert_same(region, region.entry.insns.last.data)
      assert_equal(0, insns.find { |insn| insn.kind == :new_regexp }.data.flags & Prism::RegularExpressionFlags::ONCE)
      assert_include(unit.disasm, "once @site0, r1")
      assert_include(unit.disasm, "once_return r1(")
    end

    def test_once_caches_false_and_nil
      [false, nil].each do |value|
        region = Object.new
        state = Compile::VM::OnceState.new
        count = 0
        2.times do
          result = state.run(region) { count += 1; Compile::VM::ExecutionResult.new(nil, value, region) }
          assert_equal(value, result.value)
        end
        assert_equal(1, count)
      end
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

    def test_match_required
      [
        [nil, "1 => 1"],
        [nil, "1.5 => 1.5"],
        [nil, "1 => Integer"],
        [nil, "1 => 1 | 2"],
        [nil, "2 => 1 | 2"],
        [nil, "nil => nil"],
        [1, "1 => a; a"],
        [1, "1 => _; _"],
        [nil, "nil => a; a"],
        [false, "a = 1; false => a; a"],
        [1, "1 => Integer => a; a"],
        [nil, "a = 1; 1 => ^a"],
        [2, "1 => Integer; 2"],
        [nil, "proc { 1 => Integer }.call"],
        [nil, "-> { 1 => Integer }.call"],
        [1, "a = 0; proc { 1 => a }.call; a"],
        [1, "proc { 1 => a; a }.call"],
        [[true, 1], "matched = (1 in a); [matched, a]"],
        [1, "case 1; in a; a; end"],
        [1, "case 1; in a if false; 2; else; a; end"]
      ].each { |expected, source| assert_run(expected, source) }
      assert_run_raises(NoMatchingPatternError, "1 => 2", "1: 2 === 1 does not return true")
      assert_run_raises(NoMatchingPatternError, "1.5 => 2.5", "1.5: 2.5 === 1.5 does not return true")
      assert_run_raises(NoMatchingPatternError, "1 => 2 | 3", "1: 3 === 1 does not return true")
      assert_run_raises(NoMatchingPatternError, "a = 2; 1 => ^a", "1: 2 === 1 does not return true")
    end

    def test_match_required_evaluation
      scope = Module.new
      events = []
      value = Object.new
      pattern = Object.new
      matched = true
      pattern.define_singleton_method(:===) { |candidate| events << [:match, candidate]; matched && :truthy }
      scope.const_set(:Value, value)
      scope.const_set(:Pattern, pattern)
      scope.const_set(:Events, events)
      source = "(Events << :value; Value) => ^((Events << :pattern; Pattern)) => captured; Events << :after; captured"
      graph = compile_unit(source).graphs[0]
      frame = -> { Compile::VM::Frame.new(graph, scope, [scope, Object].freeze) }
      assert_same(value, vm.run_frame(frame.call))
      assert_equal([:value, :pattern, [:match, value], :after], events)
      events.clear
      matched = false
      failed_frame = frame.call
      assert_raise(NoMatchingPatternError) { vm.run_frame(failed_frame) }
      assert_equal([:value, :pattern, [:match, value]], events)
      captured = graph.locals.find { |local| local.name == :captured }
      assert_nil(failed_frame.locals[captured.id])
    end

    def test_match_required_method
      assert_run([nil, 2], <<~RUBY)
        class CompileTestMatchRequired
          def tail(value)
            value => Integer
          end

          def capture(value)
            2 => value
            value
          end
        end
        object = CompileTestMatchRequired.new
        [object.tail(1), object.capture(1)]
      RUBY
    end

    def test_capture_pattern
      [
        [[true, 1], "matched = (1 in Integer => a); [matched, a]"],
        [[false, nil], "matched = (1 in String => a); [matched, a]"],
        [[false, 2], "a = 2; matched = (1 in String => a); [matched, a]"],
        [[true, nil], "matched = (nil in nil => a); [matched, a]"],
        [[true, 1, 1], "matched = (1 in (Integer => a) => b); [matched, a, b]"],
        [[false, 2, 3], "a = 2; b = 3; matched = (1 in (String => a) => b); [matched, a, b]"],
        [[true, 1], "matched = (1 in (String | Integer) => a); [matched, a]"],
        [1, "a = 0; proc { 1 in Integer => a }.call; a"],
        [2, "for i in [1, 2]; i in Integer => a; end; a"],
        [[true, 1, [:value, :pattern]], "events = []; matched = ((events << :value; 1) in ^((events << :pattern; Integer)) => a); [matched, a, events]"],
        [[true, 2], "class CompileTestCapturePattern; def value(x); matched = (x in Integer => a); [matched, a]; end; end; CompileTestCapturePattern.new.value(2)"]
      ].each { |expected, source| assert_run(expected, source) }
    end

    def test_capture_pattern_case_equality
      scope = Module.new
      value = Object.new
      calls = []
      pattern = Object.new
      pattern.define_singleton_method(:===) { |candidate| calls << candidate; :matched }
      scope.const_set(:Value, value)
      scope.const_set(:Pattern, pattern)
      graph = compile_unit("Value in Pattern => a; a").graphs[0]
      assert_same(value, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      assert_equal([value], calls)
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

    def test_index_and_write
      [
        [[3, [3]], "a = [1]; result = (a[0] &&= 3); [result, a]"],
        [[nil, [nil]], "a = Array.new(1); result = (a[0] &&= raise('rhs ran')); [result, a]"],
        [[false, [false]], "a = Array.new(1, false); result = (a[0] &&= raise('rhs ran')); [result, a]"],
        [[3, [3]], "a = [0]; result = (a[0] &&= 3); [result, a]"],
        [[nil, [nil]], "a = [1]; result = (a[0] &&= nil); [result, a]"],
        [[false, [false]], "a = [1]; result = (a[0] &&= false); [result, a]"],
        [[3, { a: 3 }], "a = { a: 1 }; result = (a[:a] &&= 3); [result, a]"],
        [[3, [3]], "a = [1]; result = (a[0] &&= (if true; 3; else; 4; end)); [result, a]"],
        [[3, [3]], "a = [1]; result = (a[0] &&= proc { 3 }.call); [result, a]"],
        [[3, [3, 2]], "a = [1, 2]; indices = [0]; result = (a[*indices] &&= 3); [result, a]"]
      ].each { |expected, source| assert_run(expected, source) }
    end

    def test_index_and_write_evaluation
      scope = Module.new
      events = []
      receiver = Object.new
      indices = Object.new
      result = Object.new
      current = true
      fail_at = nil
      indices.define_singleton_method(:to_a) do
        events << :convert
        raise 'convert failed' if fail_at == :convert
        [1, 2]
      end
      receiver.define_singleton_method(:[]) do |*args|
        events << [:getter, args]
        raise 'getter failed' if fail_at == :getter
        current
      end
      receiver.define_singleton_method(:[]=) do |*args|
        events << [:setter, args]
        raise 'setter failed' if fail_at == :setter
        :ignored
      end
      rhs = proc do
        raise 'rhs failed' if fail_at == :rhs
        result
      end
      scope.const_set(:Receiver, receiver)
      scope.const_set(:Indices, indices)
      scope.const_set(:Events, events)
      scope.const_set(:Rhs, rhs)
      source = "(Events << :receiver; Receiver)[*(Events << :index; Indices)] &&= (Events << :rhs; Rhs.call)"
      graph = compile_unit(source).graphs[0]
      frame = -> { Compile::VM::Frame.new(graph, scope, [scope, Object].freeze) }
      assert_same(result, vm.run_frame(frame.call))
      expected = [:receiver, :index, :convert, [:getter, [1, 2]], :rhs, [:setter, [1, 2, result]]]
      assert_equal(expected, events)
      [nil, false].each do |value|
        events.clear
        current = value
        assert_equal(value, vm.run_frame(frame.call))
        assert_equal(expected.take(4), events)
      end
      current = true
      { convert: 3, getter: 4, rhs: 5, setter: 6 }.each do |stage, length|
        events.clear
        fail_at = stage
        assert_raise_with_message(RuntimeError, "#{stage} failed") { vm.run_frame(frame.call) }
        assert_equal(expected.take(length), events)
      end
      fail_at = nil
      [nil, false].each do |value|
        events.clear
        result = value
        assert_equal(value, vm.run_frame(frame.call))
        assert_equal([:receiver, :index, :convert, [:getter, [1, 2]], :rhs, [:setter, [1, 2, value]]], events)
      end
      events.clear
      result = Object.new
      graph = compile_unit("Receiver[] &&= (Events << :rhs; Rhs.call)").graphs[0]
      assert_same(result, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      assert_equal([[:getter, []], :rhs, [:setter, [result]]], events)
    end

    def test_index_or_write
      [
        [[3, [3]], "a = []; result = (a[0] ||= 3); [result, a]"],
        [[3, [3]], "a = Array.new(1, false); result = (a[0] ||= 3); [result, a]"],
        [[1, [1]], "a = [1]; result = (a[0] ||= raise('rhs ran')); [result, a]"],
        [[0, [0]], "a = [0]; result = (a[0] ||= raise('rhs ran')); [result, a]"],
        [[nil, { a: nil }], "a = {}; result = (a[:a] ||= nil); [result, a]"],
        [[false, { a: false }], "a = {}; result = (a[:a] ||= false); [result, a]"],
        [[3, { a: 3 }], "a = {}; result = (a[:a] ||= 3); [result, a]"],
        [[3, [3]], "a = []; result = (a[0] ||= (if true; 3; else; 4; end)); [result, a]"],
        [[3, [3]], "a = []; result = (a[0] ||= proc { 3 }.call); [result, a]"],
        [[3, [3]], "a = []; indices = [0]; result = (a[*indices] ||= 3); [result, a]"]
      ].each { |expected, source| assert_run(expected, source) }
    end

    def test_index_or_write_evaluation
      scope = Module.new
      events = []
      receiver = Object.new
      indices = Object.new
      result = Object.new
      current = nil
      fail_at = nil
      indices.define_singleton_method(:to_a) do
        events << :convert
        raise 'convert failed' if fail_at == :convert
        [1, 2]
      end
      receiver.define_singleton_method(:[]) do |*args|
        events << [:getter, args]
        raise 'getter failed' if fail_at == :getter
        current
      end
      receiver.define_singleton_method(:[]=) do |*args|
        events << [:setter, args]
        raise 'setter failed' if fail_at == :setter
        :ignored
      end
      rhs = proc do
        raise 'rhs failed' if fail_at == :rhs
        result
      end
      scope.const_set(:Receiver, receiver)
      scope.const_set(:Indices, indices)
      scope.const_set(:Events, events)
      scope.const_set(:Rhs, rhs)
      source = "(Events << :receiver; Receiver)[*(Events << :index; Indices)] ||= (Events << :rhs; Rhs.call)"
      graph = compile_unit(source).graphs[0]
      frame = -> { Compile::VM::Frame.new(graph, scope, [scope, Object].freeze) }
      expected = [:receiver, :index, :convert, [:getter, [1, 2]], :rhs, [:setter, [1, 2, result]]]
      [nil, false].each do |value|
        events.clear
        current = value
        assert_same(result, vm.run_frame(frame.call))
        assert_equal(expected, events)
      end
      [true, 0, Object.new].each do |value|
        events.clear
        current = value
        assert_same(value, vm.run_frame(frame.call))
        assert_equal(expected.take(4), events)
      end
      current = nil
      { convert: 3, getter: 4, rhs: 5, setter: 6 }.each do |stage, length|
        events.clear
        fail_at = stage
        assert_raise_with_message(RuntimeError, "#{stage} failed") { vm.run_frame(frame.call) }
        assert_equal(expected.take(length), events)
      end
      fail_at = nil
      [nil, false].each do |value|
        events.clear
        result = value
        assert_equal(value, vm.run_frame(frame.call))
        assert_equal([:receiver, :index, :convert, [:getter, [1, 2]], :rhs, [:setter, [1, 2, value]]], events)
      end
      events.clear
      result = Object.new
      graph = compile_unit("Receiver[] ||= (Events << :rhs; Rhs.call)").graphs[0]
      assert_same(result, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      assert_equal([[:getter, []], :rhs, [:setter, [result]]], events)
    end

    def test_index_operator_write
      [
        [[4, [4, 2]], "a = [1, 2]; result = (a[0] += 3); [result, a]"],
        [[6, { a: 6 }], "a = { a: 2 }; result = (a[:a] *= 3); [result, a]"],
        [[8, [8]], "a = [2]; result = (a[0] **= 3); [result, a]"],
        [["ab", ["ab"]], "a = ['a']; result = (a[0] <<= 'b'); [result, a]"],
        [[4, [4]], "a = [1]; result = (a[0] += (if true; 3; else; 4; end)); [result, a]"],
        [[3, [3]], "a = [1]; result = (a[0] += proc { 2 }.call); [result, a]"],
        [[3, [3], 1], "i = 0; a = [1]; result = (a[(i += 1; 0)] += 2); [result, a, i]"],
        [[3, [3, 2]], "a = [1, 2]; indices = [0]; result = (a[*indices] += 2); [result, a]"]
      ].each { |expected, source| assert_run(expected, source) }
    end

    def test_index_operator_write_evaluation
      scope = Module.new
      events = []
      result = Object.new
      operand = Object.new
      receiver = Object.new
      indices = Object.new
      fail_at = nil
      indices.define_singleton_method(:to_a) do
        events << :convert
        raise 'convert failed' if fail_at == :convert
        [1, 2]
      end
      indices.define_singleton_method(:to_ary) { raise 'to_ary called' }
      receiver.define_singleton_method(:[]) do |*args|
        events << [:getter, args]
        raise 'getter failed' if fail_at == :getter
        operand
      end
      operand.define_singleton_method(:+) do |value|
        events << [:operator, value]
        raise 'operator failed' if fail_at == :operator
        result
      end
      receiver.define_singleton_method(:[]=) do |*args|
        events << [:setter, args]
        raise 'setter failed' if fail_at == :setter
        :ignored
      end
      rhs = proc do
        raise 'rhs failed' if fail_at == :rhs
        2
      end
      scope.const_set(:Receiver, receiver)
      scope.const_set(:Indices, indices)
      scope.const_set(:Events, events)
      scope.const_set(:Rhs, rhs)
      source = "(Events << :receiver; Receiver)[*(Events << :index; Indices)] += (Events << :rhs; Rhs.call)"
      graph = compile_unit(source).graphs[0]
      frame = -> { Compile::VM::Frame.new(graph, scope, [scope, Object].freeze) }
      assert_same(result, vm.run_frame(frame.call))
      expected = [:receiver, :index, :convert, [:getter, [1, 2]], :rhs, [:operator, 2], [:setter, [1, 2, result]]]
      assert_equal(expected, events)
      { convert: 3, getter: 4, rhs: 5, operator: 6, setter: 7 }.each do |stage, length|
        events.clear
        fail_at = stage
        assert_raise_with_message(RuntimeError, "#{stage} failed") { vm.run_frame(frame.call) }
        assert_equal(expected.take(length), events)
      end
      events.clear
      fail_at = nil
      graph = compile_unit("Receiver[] += 2").graphs[0]
      assert_same(result, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      assert_equal([[:getter, []], [:operator, 2], [:setter, [result]]], events)
    end

    def test_index_operator_write_preserves_indices
      scope = Module.new
      indices = [1, 2]
      reads = []
      writes = []
      receiver = Object.new
      receiver.define_singleton_method(:[]) { |*args| reads << args; indices << 3; 1 }
      receiver.define_singleton_method(:[]=) { |*args| writes << args; :ignored }
      scope.const_set(:Receiver, receiver)
      scope.const_set(:Indices, indices)
      graph = compile_unit("Receiver[*Indices] += (Indices << 4; 2)").graphs[0]
      assert_equal(3, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      assert_equal([[1, 2]], reads)
      assert_equal([[1, 2, 3]], writes)
      assert_equal([1, 2, 3, 4], indices)
      graph = compile_unit("class Updater; def self.update(receiver, *); result = (receiver[*] += 2); [result, [*]]; end; end; Updater.update(Receiver, 1, 2)").graphs[0]
      assert_equal([3, [1, 2]], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
    end

    def test_call_and_write
      [
        [[3, 3], "o = Struct.new(:value).new(1); result = (o.value &&= 3); [result, o.value]"],
        [[nil, nil], "o = Struct.new(:value).new(nil); result = (o.value &&= raise('rhs ran')); [result, o.value]"],
        [[false, false], "o = Struct.new(:value).new(false); result = (o.value &&= raise('rhs ran')); [result, o.value]"],
        [[3, 3], "o = Struct.new(:value).new(0); result = (o.value &&= 3); [result, o.value]"],
        [[nil, nil], "o = Struct.new(:value).new(1); result = (o.value &&= nil); [result, o.value]"],
        [[false, false], "o = Struct.new(:value).new(1); result = (o.value &&= false); [result, o.value]"],
        [[3, 3], "o = Struct.new(:value).new(1); result = (o.value &&= (if true; 3; else; 4; end)); [result, o.value]"],
        [[3, 3], "o = Struct.new(:value).new(1); result = (o.value &&= proc { 3 }.call); [result, o.value]"]
      ].each { |expected, source| assert_run(expected, source) }
    end

    def test_call_and_write_effect_context
      assert_run([1, 2], "o = Struct.new(:value).new(true); o.value &&= [1, 2]; o.value")
      assert_run(false, "o = Struct.new(:value).new(false); o.value &&= raise('rhs ran'); o.value")
      assert_run(7, "nil&.value &&= raise('rhs ran'); 7")
      assert_run([1, 2], "o = Struct.new(:value).new(true); o&.value &&= [1, 2]; o.value")

      graph = compile_unit("receiver.value &&= rhs; 7").graphs[0]
      assert(graph.blocks.all? { |block| block.params.empty? })
    end

    def test_call_and_write_evaluation
      scope = Module.new
      events = []
      receiver = Object.new
      result = Object.new
      current = true
      fail_at = nil
      receiver.define_singleton_method(:value) do
        events << :getter
        raise 'getter failed' if fail_at == :getter
        current
      end
      receiver.define_singleton_method(:value=) do |value|
        events << [:setter, value]
        raise 'setter failed' if fail_at == :setter
        :ignored
      end
      rhs = proc do
        raise 'rhs failed' if fail_at == :rhs
        result
      end
      scope.const_set(:Receiver, receiver)
      scope.const_set(:Events, events)
      scope.const_set(:Rhs, rhs)
      graph = compile_unit("(Events << :receiver; Receiver).value &&= (Events << :rhs; Rhs.call)").graphs[0]
      frame = -> { Compile::VM::Frame.new(graph, scope, [scope, Object].freeze) }
      assert_same(result, vm.run_frame(frame.call))
      expected = [:receiver, :getter, :rhs, [:setter, result]]
      assert_equal(expected, events)
      events.clear
      discarded = compile_unit("(Events << :receiver; Receiver).value &&= (Events << :rhs; Rhs.call); nil").graphs[0]
      assert_nil(vm.run_frame(Compile::VM::Frame.new(discarded, scope, [scope, Object].freeze)))
      assert_equal(expected, events)
      [nil, false].each do |value|
        events.clear
        current = value
        assert_equal(value, vm.run_frame(frame.call))
        assert_equal([:receiver, :getter], events)
      end
      current = true
      { getter: 2, rhs: 3, setter: 4 }.each do |stage, length|
        events.clear
        fail_at = stage
        assert_raise_with_message(RuntimeError, "#{stage} failed") { vm.run_frame(frame.call) }
        assert_equal(expected.take(length), events)
      end
    end

    def test_call_and_write_safe_navigation
      assert_run(nil, "nil&.value &&= raise('rhs ran')")
      assert_run([nil, 1], "calls = 0; result = ((calls += 1; nil)&.value &&= raise('rhs ran')); [result, calls]")
      assert_run([3, 3], "o = Struct.new(:value).new(1); result = (o&.value &&= 3); [result, o.value]")
      assert_run(false, "o = Struct.new(:value).new(false); o&.value &&= raise('rhs ran')")
      assert_run_raises(NoMethodError, "false&.value &&= raise('rhs ran')")
      assert_run(1, "if nil&.value &&= 2; 2; else; 1; end")
    end

    def test_call_or_write
      [
        [[3, 3], "o = Struct.new(:value).new(nil); result = (o.value ||= 3); [result, o.value]"],
        [[3, 3], "o = Struct.new(:value).new(false); result = (o.value ||= 3); [result, o.value]"],
        [[1, 1], "o = Struct.new(:value).new(1); result = (o.value ||= raise('rhs ran')); [result, o.value]"],
        [[0, 0], "o = Struct.new(:value).new(0); result = (o.value ||= raise('rhs ran')); [result, o.value]"],
        [[nil, nil], "o = Struct.new(:value).new(nil); result = (o.value ||= nil); [result, o.value]"],
        [[false, false], "o = Struct.new(:value).new(nil); result = (o.value ||= false); [result, o.value]"],
        [[3, 3], "o = Struct.new(:value).new(nil); result = (o.value ||= (if true; 3; else; 4; end)); [result, o.value]"],
        [[3, 3], "o = Struct.new(:value).new(nil); result = (o.value ||= proc { 3 }.call); [result, o.value]"]
      ].each { |expected, source| assert_run(expected, source) }
    end

    def test_call_or_write_effect_context
      assert_run([1, 2], "o = Struct.new(:value).new(nil); o.value ||= [1, 2]; o.value")
      assert_run([1, 2], "o = Struct.new(:value).new(false); o&.value ||= [1, 2]; o.value")
      assert_run(1, "o = Struct.new(:value).new(1); o.value ||= raise('rhs ran'); o.value")
      assert_run(7, "nil&.value ||= raise('rhs ran'); 7")

      ["receiver.value ||= rhs; 7", "receiver&.value ||= rhs; 7"].each do |source|
        graph = compile_unit(source).graphs[0]
        assert(graph.blocks.all? { |block| block.params.empty? }, source)
      end
    end

    def test_call_or_write_evaluation
      scope = Module.new
      events = []
      receiver = Object.new
      result = Object.new
      current = nil
      fail_at = nil
      receiver.define_singleton_method(:value) do
        events << :getter
        raise 'getter failed' if fail_at == :getter
        current
      end
      receiver.define_singleton_method(:value=) do |value|
        events << [:setter, value]
        raise 'setter failed' if fail_at == :setter
        :ignored
      end
      rhs = proc do
        raise 'rhs failed' if fail_at == :rhs
        result
      end
      scope.const_set(:Receiver, receiver)
      scope.const_set(:Events, events)
      scope.const_set(:Rhs, rhs)
      graph = compile_unit("(Events << :receiver; Receiver).value ||= (Events << :rhs; Rhs.call)").graphs[0]
      frame = -> { Compile::VM::Frame.new(graph, scope, [scope, Object].freeze) }
      discarded = compile_unit("(Events << :receiver; Receiver).value ||= (Events << :rhs; Rhs.call); nil").graphs[0]
      expected = [:receiver, :getter, :rhs, [:setter, result]]
      [nil, false].each do |value|
        events.clear
        current = value
        assert_same(result, vm.run_frame(frame.call))
        assert_equal(expected, events)
        events.clear
        assert_nil(vm.run_frame(Compile::VM::Frame.new(discarded, scope, [scope, Object].freeze)))
        assert_equal(expected, events)
      end
      [true, 0, Object.new].each do |value|
        events.clear
        current = value
        assert_same(value, vm.run_frame(frame.call))
        assert_equal([:receiver, :getter], events)
        events.clear
        assert_nil(vm.run_frame(Compile::VM::Frame.new(discarded, scope, [scope, Object].freeze)))
        assert_equal([:receiver, :getter], events)
      end
      current = nil
      { getter: 2, rhs: 3, setter: 4 }.each do |stage, length|
        events.clear
        fail_at = stage
        assert_raise_with_message(RuntimeError, "#{stage} failed") { vm.run_frame(frame.call) }
        assert_equal(expected.take(length), events)
      end
      fail_at = nil
      [nil, false].each do |value|
        events.clear
        result = value
        assert_equal(value, vm.run_frame(frame.call))
        assert_equal([:receiver, :getter, :rhs, [:setter, value]], events)
      end
    end

    def test_call_or_write_safe_navigation
      assert_run(nil, "nil&.value ||= raise('rhs ran')")
      assert_run([nil, 1], "calls = 0; result = ((calls += 1; nil)&.value ||= raise('rhs ran')); [result, calls]")
      assert_run([3, 3], "o = Struct.new(:value).new(nil); result = (o&.value ||= 3); [result, o.value]")
      assert_run(1, "o = Struct.new(:value).new(1); o&.value ||= raise('rhs ran')")
      assert_run_raises(NoMethodError, "false&.value ||= raise('rhs ran')")
      assert_run(1, "if nil&.value ||= 2; 2; else; 1; end")
    end

    def test_call_operator_write
      [
        [[3, 3], "o = Struct.new(:value).new(1); result = (o.value += 2); [result, o.value]"],
        [[6, 6], "o = Struct.new(:value).new(2); result = (o.value *= 3); [result, o.value]"],
        [[8, 8], "o = Struct.new(:value).new(2); result = (o.value **= 3); [result, o.value]"],
        [["ab", "ab"], "o = Struct.new(:value).new('a'); result = (o.value <<= 'b'); [result, o.value]"],
        [[4, 4], "o = Struct.new(:value).new(1); result = (o.value += (if true; 3; else; 4; end)); [result, o.value]"],
        [[3, 3], "o = Struct.new(:value).new(1); result = (o.value += proc { 2 }.call); [result, o.value]"]
      ].each { |expected, source| assert_run(expected, source) }
    end

    def test_call_operator_write_evaluation
      scope = Module.new
      events = []
      result = Object.new
      operand = Object.new
      receiver = Object.new
      fail_at = nil
      receiver.define_singleton_method(:value) do
        events << :getter
        raise 'getter failed' if fail_at == :getter
        operand
      end
      operand.define_singleton_method(:+) do |value|
        events << [:operator, value]
        raise 'operator failed' if fail_at == :operator
        result
      end
      receiver.define_singleton_method(:value=) do |value|
        events << [:setter, value]
        raise 'setter failed' if fail_at == :setter
        :ignored
      end
      scope.const_set(:Receiver, receiver)
      scope.const_set(:Events, events)
      graph = compile_unit("(Events << :receiver; Receiver).value += (Events << :rhs; 2)").graphs[0]
      frame = -> { Compile::VM::Frame.new(graph, scope, [scope, Object].freeze) }
      assert_same(result, vm.run_frame(frame.call))
      assert_equal([:receiver, :getter, :rhs, [:operator, 2], [:setter, result]], events)
      events.clear
      discarded = compile_unit("(Events << :receiver; Receiver)&.value += (Events << :rhs; 2); nil").graphs[0]
      assert_nil(vm.run_frame(Compile::VM::Frame.new(discarded, scope, [scope, Object].freeze)))
      assert_equal([:receiver, :getter, :rhs, [:operator, 2], [:setter, result]], events)
      { getter: [:receiver, :getter], operator: [:receiver, :getter, :rhs, [:operator, 2]],
        setter: [:receiver, :getter, :rhs, [:operator, 2], [:setter, result]] }.each do |stage, expected|
        events.clear
        fail_at = stage
        assert_raise_with_message(RuntimeError, "#{stage} failed") { vm.run_frame(frame.call) }
        assert_equal(expected, events)
      end
    end

    def test_call_operator_write_effect_context
      assert_run(3, "o = Struct.new(:value).new(1); o.value += 2; o.value")
      assert_run([1, 2], "o = Struct.new(:value).new([1]); o&.value += [2]; o.value")
      assert_run(7, "nil&.value += raise('rhs ran'); 7")
      assert_run_raises(NoMethodError, "false&.value += raise('rhs ran'); 7")

      graph = compile_unit("receiver&.value += rhs; 7").graphs[0]
      assert(graph.blocks.all? { |block| block.params.empty? })
    end

    def test_call_operator_write_safe_navigation
      assert_run(nil, "nil&.value += raise('rhs ran')")
      assert_run([nil, 1], "calls = 0; result = ((calls += 1; nil)&.value += raise('rhs ran')); [result, calls]")
      assert_run([3, 3], "o = Struct.new(:value).new(1); result = (o&.value += 2); [result, o.value]")
      assert_run_raises(NoMethodError, "false&.value += raise('rhs ran')")
      assert_run(1, "if nil&.value += 2; 2; else; 1; end")
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

    def test_call_effect_context
      assert_run([:receiver, :argument, :block], "events = []; (events << :receiver)&.fetch((events << :argument; 99)) { events << :block; break }; events")
      assert_run([1, 2], "o = Struct.new(:value).new; o&.value = [1, 2]; o.value")
      assert_run([], "events = []; nil&.missing(events << :argument) { events << :block }; events")

      ["receiver.call; 7", "receiver&.call; 7", "receiver&.value = 1; 7"].each do |source|
        graph = compile_unit(source).graphs[0]
        assert(graph.blocks.all? { |block| block.params.empty? }, source)
      end
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

    def test_hash_pattern
      [
        "{} in {}",
        "{a: 1} in {}",
        "1 in {}",
        "{a: 1, b: 2} in {a: 1}",
        "value = nil; {a: value} in {a: nil}",
        "{} in {a: nil}",
        "{a: 1} in {a: 2}",
        "{a: 1, b: 2} => {a:, b:}; [a, b]",
        "{a: 1, b: 2} => {a: Integer => value}; value",
        "{a: [0, 1]} => {a: [*, value, 1, *]}; value",
        "[{a: {b: 1}}] => [{a: {b:}}]; b",
        "{a: 1} => Hash[a:] => value; [a, value]",
        "{a: 1} in String[a: 1]",
        "{a: 1} in {a: 2} | {a: 1}",
        "{a: 1, b: 2} => {a:, **rest}; [a, rest]",
        "{a: 1} => {a:, **rest}; [a, rest]",
        "{a: 1} => {**rest}; rest",
        "{} => {**rest}; rest",
        "{a: 1} in {**}",
        "{a: 1, b: 2} in {a: 1, **}",
        "{a: 1} in {a: 1, **nil}",
        "{a: 1, b: 2} in {a: 1, **nil}",
        "{} in {**nil}",
        "{a: 1} in {**nil}",
        "a = 1; {a: 1} in {a: ^a}",
        '{"a b": 1} => {"a b": value}; value',
        "value = {a: 1, b: 2}; value => {a:, **rest}; [value, rest]",
        "a = :before; case {a: 1}; in {a:, b:}; :no; else; a; end",
        "a = :before; case {a: 1, b: 2}; in {a:, b: 3}; :no; else; a; end",
        "case {a: 1}; in {b:}; :no; in {a:}; a; end",
        "case {a: 1}; in {a:} if false; :no; in {a:}; a; end",
        "case {a: 1}; in {b:}; :no; else; :other; end"
      ].each { |source| assert_run(eval(source), source) }
    end

    def test_hash_pattern_failure
      [
        "1 => {}",
        "{a: 1} => {}",
        "{} => {a:}",
        "{a: 1} => {a: 2}",
        "{a: 1} => String[a: 1]",
        "{a: 1, b: 2} => {a: 1, **nil}",
        "{a: 1} => {**nil}",
        "[{a: 1}] => [{b:}]",
        "{a: {b: 1}} => {a: {c:}}",
        "{a: 1} => {b:, **rest}",
        "case {a: 1}; in {b:}; end",
        "case {a: 1}; in {a:} if false; end",
        "{a: 1} => {a: 2} | {b: 1}",
        "case {a: 1}; in {b:}; in {c:}; end"
      ].each do |source|
        expected = assert_raise(NoMatchingPatternError, NoMatchingPatternKeyError) { eval(source) }
        scope = Module.new
        graph = compile_unit(source).graphs[0]
        actual = assert_raise(expected.class) do
          vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze))
        end
        assert_equal(expected.message, actual.message, source)
        if NoMatchingPatternKeyError === expected
          assert_equal(expected.key, actual.key, source)
          assert_equal(expected.matchee, actual.matchee, source)
        end
      end
    end

    def test_hash_pattern_deconstruction
      scope = Module.new
      requests = []
      result = {a: 1, b: 2}
      value = Object.new
      value.define_singleton_method(:deconstruct_keys) { |keys| requests << keys&.dup; keys&.clear; result }
      scope.const_set(:Value, value)
      [
        ["Value in {a: 1}", true, [:a]],
        ["Value in {}", false, nil],
        ["Value in {**}", true, []],
        ["Value in {a: 1, **}", true, [:a]],
        ["Value in {a: 1, **nil}", false, nil],
        ["Value => {a:, **rest}; [a, rest]", [1, {b: 2}], nil],
        ["Value => {**rest}; rest", result, nil],
        ["Value in String[a: 1]", false, :none]
      ].each do |source, expected, keys|
        graph = compile_unit(source).graphs[0]
        2.times do
          requests.clear
          assert_equal(expected, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
          assert_equal(keys == :none ? [] : [keys], requests)
          assert_equal({a: 1, b: 2}, result)
        end
      end

      result = []
      graph = compile_unit("Value in {a: 1}").graphs[0]
      assert_raise_with_message(TypeError, "deconstruct_keys must return Hash") do
        vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze))
      end
    end

    def test_hash_pattern_evaluation
      scope = Module.new
      events = []
      hash_class = Class.new(Hash) do
        define_method(:deconstruct_keys) { |keys| events << [:deconstruct_keys, keys]; self }
        define_method(:dup) { events << :dup; super() }
        define_method(:key?) { |key| events << [:key?, key]; super(key) }
        define_method(:[]) { |key| events << [:read, key]; super(key) }
        define_method(:delete) { |key| events << [:delete, key]; super(key) }
        define_method(:empty?) { events << :empty?; super() }
      end
      value = hash_class.new.merge!(a: 1, b: 2, c: 3)
      pattern = Module.new
      pattern.define_singleton_method(:===) { |item| events << [:match, item]; true }
      scope.const_set(:Value, value)
      scope.const_set(:Pattern, pattern)
      [
        "Value in {a: Pattern, b: Pattern}",
        "Value in {a: Pattern, missing: Pattern}",
        "Value in {a: Pattern, b: Pattern, **rest}",
        "Value in {a: Pattern, **nil}",
        "Value in {}",
        "Value in {**}"
      ].each do |source|
        events.clear
        expected = scope.module_eval(source)
        native_events = events.dup
        events.clear
        graph = compile_unit(source).graphs[0]
        assert_equal(expected, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
        assert_equal(native_events, events, source)
        assert_equal({a: 1, b: 2, c: 3}, value)
      end
    end

    def test_hash_pattern_disasm
      [
        ["1 => {}", "raise_pattern_deconstruct_keys"],
        ["{a: 1} => {}", "raise_pattern_empty"],
        ["{} => {a:}", "raise_pattern_key"],
        ["{a: 1} => {**nil}", "raise_pattern_rest_empty"]
      ].each do |source, instruction|
        unit = compile_unit(source)
        assert_include(unit.disasm, " = deconstruct_hash(")
        assert_include(unit.disasm, "#{instruction}(")
      end
    end

    def test_find_pattern
      [
        "[] in [*, 1, *]",
        "[1] in [*, 1, *]",
        "[0, 1, 2, 3] in [*, 1, 2, *]",
        "[1, 0, 2] in [*, 1, 2, *]",
        "1 in [*, 1, *]",
        "[1, 2] in String[*, 1, *]",
        "[1, 2] in Array[*, Integer, 2, *]",
        "[0, 1, 2, 3] => [*left, 1, 2, *right]; [left, right]",
        "[1, 2] => [*left, 1, 2, *right]; [left, right]",
        "[0, 1, 1, 2, 3] => [*left, 1, 2, *right]; [left, right]",
        "[0, 1, 2, 1, 2] => [*left, 1, 2, *right]; [left, right]",
        "[0, [1], 2] => [*, [value], *right]; [value, right]",
        "[[0, 1]] => [[*left, 1, *right]]; [left, right]",
        "[0, 1] => Array[*, 1, *] => value; value",
        "[1, 2] in [*, 3, *] | [*, 2, *]",
        "a = 2; [1, 2, 3] in [*, ^a, *]",
        "[1] => [*, 1, *]",
        "case [1, 2]; in [*, 3, *]; :no; in [*, 2, *]; :yes; end",
        "case [1, 2]; in [*, 1, *] if false; :no; in [*, 2, *]; :yes; end",
        "case [1, 2]; in [*, 3, *]; :no; else; :other; end",
        "case [1, 2]; in [*, value, 3, *]; :no; else; value; end"
      ].each { |source| assert_run(eval(source), source) }
    end

    def test_find_pattern_failure
      [
        "1 => [*, 1, *]",
        "[] => [*, 1, *]",
        "[1] => [*, 1, 2, *]",
        "[1, 2] => [*, 3, *]",
        "[[1, 2]] => [[*, 3, *]]",
        "[1, 2] => String[*, 1, *]",
        "case [1, 2]; in [*, 3, *]; end",
        "case [1, 2]; in [*, 1, *] if false; end",
        "[1, 2] => [*, 0, *] | [*, 3, *]",
        "case [1, 2]; in [*, 0, *]; in [*, 3, *]; end"
      ].each do |source|
        error = assert_raise(NoMatchingPatternError) { eval(source) }
        assert_run_raises(NoMatchingPatternError, source, error.message)
      end
    end

    def test_find_pattern_deconstruction
      scope = Module.new
      events = []
      result = [0, 1, 2, 3]
      value = Object.new
      value.define_singleton_method(:deconstruct) { events << :deconstruct; result }
      scope.const_set(:Value, value)
      source = "Value => [*left, 1, 2, *right]; [left, right]"
      graph = compile_unit(source).graphs[0]
      assert_equal([[0], [3]], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      assert_equal([:deconstruct], events)

      result = nil
      assert_raise_with_message(TypeError, "deconstruct must return Array") do
        vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze))
      end
    end

    def test_find_pattern_evaluation
      scope = Module.new
      events = []
      array_class = Class.new(Array) do
        define_method(:length) { events << :length; super() }
        define_method(:[]) { |*args| events << [:read, *args]; super(*args) }
      end
      value = array_class.new([1, 0, 1, 2, 3])
      mutate = false
      first = Module.new
      first.define_singleton_method(:===) do |item|
        events << [:first, item]
        value.shift if mutate
        item == 1
      end
      second = Module.new
      second.define_singleton_method(:===) { |item| events << [:second, item]; item == 2 }
      scope.const_set(:Value, value)
      scope.const_set(:First, first)
      scope.const_set(:Second, second)
      source = "Value in [*left, First, Second, *right]"
      graph = compile_unit(source).graphs[0]
      [false, true].each do |mutating|
        mutate = mutating
        value.replace([1, 0, 1, 2, 3])
        events.clear
        expected = scope.module_eval(source)
        native_events = events.dup
        value.replace([1, 0, 1, 2, 3])
        events.clear
        assert_equal(expected, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
        assert_equal(native_events, events)
      end
    end

    def test_find_pattern_disasm
      unit = compile_unit("[1, 2] => [*, 3, *]")
      assert_include(unit.disasm, "raise_pattern_find(")
      assert_include(unit.disasm, " = deconstruct_array(")
      assert_equal(1, unit.graphs[0].blocks.count { |block| !block.params.empty? })
    end

    def test_array_pattern
      [
        [true, "[] in []"],
        [false, "[1] in []"],
        [false, "1 in []"],
        [false, "[1] in [a, b]"],
        [true, "[1, 2] in [Integer, 2]"],
        [false, "[1, 2] in [Integer, 3]"],
        [[1, 2], "[1, 2] => [a, b]; [a, b]"],
        [[1, [2, 3], 4], "[1, 2, 3, 4] => [a, *b, c]; [a, b, c]"],
        [[1, [], 2], "[1, 2] => [a, *b, c]; [a, b, c]"],
        [[1, 2], "[1, 2] => [*a]; a"],
        [true, "[1, 2] in [*]"],
        [1, "[1, 2] => [a,]; a"],
        [[1, 3], "[1, 2, 3] => [a, *, b]; [a, b]"],
        [[1, 2], "[[1], 2] => [[a], b]; [a, b]"],
        [[1, 2], "[1, 2] => Array[Integer, Integer] => a; a"],
        [false, "[1] in String[Integer]"],
        [true, "[2] in [1] | [2]"],
        [2, "a = 2; [2] => [^a]; a"],
        [nil, "[1] => [Integer]"],
        [2, "case [2]; in [1]; 1; in [a] if a == 2; a; else; 3; end"],
        [1, "case [1, 2]; in [a, 3]; 0; else; a; end"]
      ].each { |expected, source| assert_run(expected, source) }
    end

    def test_array_pattern_failure
      [
        "1 => []",
        "[1] => []",
        "[1] => [a, b]",
        "[] => [a, *b]",
        "[1, 2] => [3, 4]",
        "[[1]] => [[2]]",
        "[[1]] => [[a, b]]",
        "[1] => [[]]",
        "[1] => String[Integer]",
        "case [1]; in [2]; end",
        "case [1]; in [1] if false; end",
        "case [1]; in [2]; in [3]; end"
      ].each do |source|
        native_error = assert_raise(NoMatchingPatternError) { eval(source) }
        assert_run_raises(NoMatchingPatternError, source, native_error.message)
      end
    end

    def test_array_pattern_deconstruction
      scope = Module.new
      events = []
      value = Object.new
      result = [1, 2]
      value.define_singleton_method(:deconstruct) { events << :deconstruct; result }
      scope.const_set(:Value, value)
      [
        ["Value in [1, 2]", 1],
        ["case Value; in [0, *]; 0; in [a, b]; [a, b]; end", 2],
        ["Value in [0, *] | [1, 2]", 2],
        ["case Value; in [a, b] if false; 0; in [a, b]; [a, b]; end", 2],
        ["[Value, Value] in [[1, 2], [1, 2]]", 2],
        ["Value in String[1, 2]", 0]
      ].each do |source, ndeconstructs|
        events.clear
        expected = scope.module_eval(source)
        events.clear
        graph = compile_unit(source).graphs[0]
        assert_equal(expected, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
        assert_equal([:deconstruct] * ndeconstructs, events)
      end

      result = 1
      ["Value in [*]", "Value => [*]", "case Value; in [*]; 1; else; 2; end"].each do |source|
        graph = compile_unit(source).graphs[0]
        assert_raise_with_message(TypeError, "deconstruct must return Array") do
          vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze))
        end
      end
    end

    def test_array_pattern_missing_deconstruction
      scope = Module.new
      events = []
      value = Object.new
      value.define_singleton_method(:respond_to?) do |name|
        events << name
        false
      end
      value.define_singleton_method(:to_ary) { events << :to_ary; [1] }
      value.define_singleton_method(:to_a) { events << :to_a; [1] }
      scope.const_set(:Value, value)
      source = "case Value; in [1]; 1; in [*]; 2; else; 3; end"
      graph = compile_unit(source).graphs[0]
      2.times do
        events.clear
        assert_equal(3, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
        assert_equal([:deconstruct, :deconstruct], events)
      end
    end

    def test_array_pattern_element_evaluation
      scope = Module.new
      events = []
      array_class = Class.new(Array) do
        define_method(:length) { events << :length; super() }
        define_method(:[]) { |*args| events << [:read, args]; super(*args) }
      end
      array = array_class.new([1, 2, 3, 4])
      pattern = Object.new
      pattern.define_singleton_method(:===) { |value| events << [:match, value]; array << 5; true }
      scope.const_set(:Value, array)
      scope.const_set(:Pattern, pattern)
      [
        "Value => [Pattern, *rest, last]; [rest, last]",
        "Value in [Pattern, *, Integer]",
        "Value in [Pattern, Integer, Integer, Integer]"
      ].each do |source|
        array.replace([1, 2, 3, 4])
        events.clear
        expected = scope.module_eval(source)
        native_events = events.dup
        array.replace([1, 2, 3, 4])
        events.clear
        graph = compile_unit(source).graphs[0]
        assert_equal(expected, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
        assert_equal(native_events, events)
      end
    end

    def test_array_pattern_control_flow
      [
        "[[1], [2]].map { |value| case value; in [a]; next a + 1; end }",
        "while true; case [1, 2]; in [a, b]; break a + b; end; end",
        "attempts = 0; while attempts < 2; attempts += 1; case [attempts]; in [1]; redo; in [a]; break a; end; end",
        "begin; [1] => [2]; rescue NoMatchingPatternError => error; error.message; end",
        "[1].map { |value| begin; [value] => [2]; rescue NoMatchingPatternError; next value + 1; end }"
      ].each { |source| assert_run(eval(source), source) }
    end

    def test_pattern_recoverable_failure_effects
      scope = Module.new
      events = []
      matched = true
      inspect_raises = false
      element = Object.new
      element.define_singleton_method(:inspect) { events << :element_inspect; "element" }
      value = Object.new
      value.define_singleton_method(:deconstruct) { events << :deconstruct; [element] }
      value.define_singleton_method(:inspect) { events << :value_inspect; "value" }
      absent = Object.new
      absent.define_singleton_method(:inspect) { events << :absent_inspect; "absent" }
      first = Module.new
      first.define_singleton_method(:===) { |_| events << :first; false }
      first.define_singleton_method(:inspect) do
        events << :first_inspect
        raise "inspect failed" if inspect_raises
        "first"
      end
      second = Module.new
      second.define_singleton_method(:===) { |_| events << :second; matched }
      second.define_singleton_method(:inspect) { events << :second_inspect; "second" }
      scope.const_set(:Value, value)
      scope.const_set(:Absent, absent)
      scope.const_set(:First, first)
      scope.const_set(:Second, second)

      sources = [
        "Value => [First] | [Second]",
        "case Value; in [First] | [Second]; :matched; end",
        "case Value; in [First] | [Second] if false; :matched; end",
        "Value in [First] | [Second]",
        "case Value; in [First]; :first; in [Second]; :second; else; :other; end",
        "Value => [] | [Second]",
        "Value => [First] | []",
        "Value => [First, First, *] | [Second]",
        "Value => [First, *] | [Second]",
        "Absent => [] | Second",
        "Absent => [] | []",
        "Absent => [] | [] | Second",
        "[Value] => [[First]] | [[Second]]"
      ]
      [true, false].each do |result|
        matched = result
        sources.each do |source|
          events.clear
          expected = begin
            scope.module_eval(source)
          rescue NoMatchingPatternError => error
            [error.class, error.message]
          end
          native_events = events.dup
          events.clear
          graph = compile_unit(source).graphs[0]
          actual = begin
            vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze))
          rescue NoMatchingPatternError => error
            [error.class, error.message]
          end
          assert_equal(expected, actual, source)
          assert_equal(native_events.reject { |event| event == :deconstruct || event.to_s.end_with?("_inspect") }, events.reject { |event| event == :deconstruct || event.to_s.end_with?("_inspect") }, source)
        end
      end

      matched = true
      inspect_raises = true
      source = sources.first
      events.clear
      assert_raise_with_message(RuntimeError, "inspect failed") { scope.module_eval(source) }
      events.clear
      graph = compile_unit(source).graphs[0]
      # Unlike CRuby, recoverable failures do not format diagnostics or call inspect.
      assert_nil(vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      assert_equal([:deconstruct, :first, :deconstruct, :second], events)
    end

    def test_pattern_block_parameters
      [
        "1 in 1",
        "[1] in [1]",
        "[1] in [2] | [1]",
        "1 in (2 | 1) => value",
        "case 1; in 2; false; in 1 if true; true; else; false; end",
        "case 1; in 1 unless false; true; end"
      ].each do |source|
        graph = compile_unit(source).graphs[0]
        assert_not_include(graph.blocks.flat_map(&:insns).map(&:kind), :load_nil, source)
        # Only the expression's result join needs a parameter.
        assert_equal(1, graph.blocks.sum { |block| block.params.length }, source)
        assert_run(eval(source), source)
      end

      graph = compile_unit("1 => (2 | 1) => value").graphs[0]
      assert_equal(0, graph.blocks.sum { |block| block.params.length })
      assert_not_include(graph.blocks.flat_map(&:insns).map(&:kind), :load_nil)
    end

    def test_pattern_terminal_failures
      [
        ["1 => []", :raise_pattern_deconstruct, 2],
        ["[1] => []", :raise_pattern_length, 4],
        ["[] => [a, *b]", :raise_pattern_min_length, 4],
        ["[1] => [2]", :raise_pattern_mismatch, 3]
      ].each do |source, kind, noperands|
        graph = compile_unit(source).graphs[0]
        instructions = graph.blocks.flat_map(&:insns)
        assert_not_include(instructions.map(&:kind), :format_string, source)
        failure = instructions.find { |insn| insn.kind == kind }
        assert_equal(noperands, failure.opnds.length, source)
        graph.blocks.each do |block|
          assert_operator(block.params.length, :<=, 1, source)
          block.insns.each_with_index do |insn, index|
            assert_equal(block.insns.length - 1, index, source) if insn.kind.to_s.start_with?("raise_pattern_")
          end
        end
      end
      instructions = compile_unit("[1] => [2] | [1]").graphs[0].blocks.flat_map(&:insns)
      assert_not_include(instructions.map(&:kind), :format_string)
    end

    def test_array_pattern_disasm
      unit = compile_unit("[1, 2] => [a, *b]")
      assert_include(unit.disasm, " = deconstruct_array(")
      assert_include(unit.disasm, "raise_pattern_min_length(")
      assert_include(unit.disasm, "raise_pattern_deconstruct(")
    end

    def test_raise_pattern_instructions
      [
        [:raise_pattern_deconstruct, [1, 1], "1: 1 does not respond to #deconstruct"],
        [:raise_pattern_deconstruct_keys, [1, 1], "1: 1 does not respond to #deconstruct_keys"],
        [:raise_pattern_empty, [[{a: 1}], {a: 1}], "[{a: 1}]: {a: 1} is not empty"],
        [:raise_pattern_rest_empty, [{a: 1, b: 2}, {b: 2}], "{a: 1, b: 2}: rest of {b: 2} is not empty"],
        [:raise_pattern_length, [[[1]], [1], 1, 2], "[[1]]: [1] length mismatch (given 1, expected 2)"],
        [:raise_pattern_min_length, [[], [], 0, 1], "[]: [] length mismatch (given 0, expected 1+)"],
        [:raise_pattern_mismatch, [[1], 1, 2], "[1]: 2 === 1 does not return true"]
      ].each do |kind, operands, message|
        insns = operands.each_with_index.map { |value, index| Compile::Insn.new(:load_object, 0, [index], value) }
        insns << Compile::Insn.new(kind, 0, operands.each_index.to_a, nil)
        assert_raise_with_message(NoMatchingPatternError, message) do
          run_instructions(insns, [nil], operands.length)
        end
      end
    end

    def test_raise_pattern_key_instruction
      root = [{a: 1}]
      matchee = root.first
      insns = [
        Compile::Insn.new(:load_object, 0, [0], root),
        Compile::Insn.new(:load_object, 0, [1], matchee),
        Compile::Insn.new(:load_object, 0, [2], :missing),
        Compile::Insn.new(:raise_pattern_key, 0, [0, 1, 2], nil)
      ]
      error = assert_raise_with_message(NoMatchingPatternKeyError, "[{a: 1}]: key not found: :missing") do
        run_instructions(insns, [nil], 3)
      end
      assert_same(matchee, error.matchee)
      assert_equal(:missing, error.key)
    end

    def test_case_match
      [
        [:one, "case 1; in 1; :one; else; :other; end"],
        [:float, "case 1.5; in 1; :integer; in 1.5; :float; else; :other; end"],
        [:negative, "case -1.5; in -1.5; :negative; end"],
        [:equal, "case 1; in 1.0; :equal; end"],
        [:other, "case 3; in 1; :one; in 2; :two; else; :other; end"],
        [nil, "case 3; in 1; :one; else; end"],
        [nil, "case 1; in 1; end"],
        [nil, "case 1; in 1; in 1; 2; else; 3; end"],
        [3, "1 + (case 1; in 1; 2; else; 3; end)"],
        [3, "case 1; in 1; case 2.5; in 2.5; 3; else; 4; end; else; 5; end"],
        [2, "case (if true; 1; else; 2; end); in 1; if false; 3; else; 2; end; else; 4; end"],
        [2, "case 2; in 1 | 2; 2; else; 3; end"],
        [1, "case 1; in Integer => a; a; else; 2; end"],
        [2, "a = 2; case 2; in ^a; a; else; 3; end"],
        [[1, 2], "out = []; for value in [1, 2]; out << (case value; in 1; 1; in 2; 2; end); end; out"]
      ].each { |expected, source| assert_run(expected, source) }
    end

    def test_case_match_effect_context
      [
        "case 1; in 1; [1, 2]; end; 7",
        "case 1; in 2; [1, 2]; in 1; [3, 4]; end; 7",
        "case 3; in 1; [1, 2]; else; [3, 4]; end; 7",
        "case 1; in 1 if true; [1, 2]; else; [3, 4]; end; 7",
        "case 1; in 1; else; end; 7"
      ].each do |source|
        unit = compile_unit(source)
        assert_equal(7, vm.run(unit), source)
        graph = unit.graphs[0]
        assert(graph.blocks.all? { |block| block.params.empty? }, source)
        assert_not_include(graph.blocks.flat_map(&:insns).map(&:kind), :new_array_static, source)
      end

      assert_run(1, "case 1; in Integer => a; [2, 3]; end; a")
      assert_run([:value, :guard, :body], "events = []; case (events << :value; 1); in 2; events << :skipped; in 1 if (events << :guard; true); events << :body; else; events << :else; end; events")
      assert_run_raises(NoMatchingPatternError, "case 1; in 2; end; 7")
      assert_run_raises(NoMatchingPatternError, "case 1; in 2; in 3; end; 7")
      assert_run_raises(NoMatchingPatternError, "case 1; in 1 if false; end; 7")
    end

    def test_case_match_guards
      [
        [2, "case 1; in 1 if true; 2; else; 3; end"],
        [3, "case 1; in 1 if false; 2; else; 3; end"],
        [2, "case 1; in 1 unless false; 2; else; 3; end"],
        [3, "case 1; in 1 unless true; 2; else; 3; end"],
        [2, "case 1; in 1 if 0; 2; else; 3; end"],
        [2, "case 1; in 1 if false; 3; in 1 if true; 2; else; 4; end"],
        [1, "case 1; in Integer => a if false; 2; else; a; end"],
        [2, "case 1; in 1 if (false ? false : true); 2; else; 3; end"]
      ].each { |expected, source| assert_run(expected, source) }
      assert_run([1, [:value, :guard]], "events = []; result = case (events << :value; 1); in 2 if (events << :skipped; true); 2; in 1 if (events << :guard; true); 1; in 1 if (events << :later; true); 3; else; 4; end; [result, events]")
    end

    def test_case_match_failure
      assert_run_raises(NoMatchingPatternError, "case 1; in 2; end", "1: 2 === 1 does not return true")
      assert_run_raises(NoMatchingPatternError, "case 1.5; in 2.5; end", "1.5: 2.5 === 1.5 does not return true")
      assert_run_raises(NoMatchingPatternError, "case nil; in 1; end", "nil: 1 === nil does not return true")
      assert_run_raises(NoMatchingPatternError, "case 1; in 2; in 3; end", "1")
      assert_run_raises(NoMatchingPatternError, "case 'subject'; in 1; in 2; end", "subject")
      assert_run_raises(NoMatchingPatternError, "case 1; in 1 if false; end", "1: guard clause does not return true")
      assert_run_raises(NoMatchingPatternError, "case 1; in 1 unless true; end", "1: guard clause does not return true")
      assert_run_raises(NoMatchingPatternError, "case 1; in 2 | 3; end", "1: 3 === 1 does not return true")
    end

    def test_case_match_evaluation
      scope = Module.new
      events = []
      value = Object.new
      pattern = Object.new
      matched = false
      value.define_singleton_method(:inspect) { events << :value_inspect; "subject" }
      value.define_singleton_method(:to_s) { events << :value_string; "subject_string" }
      pattern.define_singleton_method(:inspect) { events << :pattern_inspect; "pattern" }
      pattern.define_singleton_method(:===) { |candidate| events << [:match, candidate]; matched && :truthy }
      scope.const_set(:Value, value)
      scope.const_set(:Pattern, pattern)
      [
        "case Value; in Pattern; :matched; end",
        "case Value; in Pattern; 1; in Pattern; 2; end"
      ].each do |source|
        events.clear
        native_error = assert_raise(NoMatchingPatternError) { scope.module_eval(source) }
        native_events = events.dup
        native_message = native_error.message
        native_message_events = events.dup
        events.clear
        graph = compile_unit(source).graphs[0]
        error = assert_raise(NoMatchingPatternError) { vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)) }
        assert_equal(native_events, events)
        assert_equal(native_message, error.message)
        assert_equal(native_message_events, events)
      end
      matched = true
      events.clear
      graph = compile_unit("case Value; in Pattern; :matched; end").graphs[0]
      assert_equal(:matched, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      assert_equal([[:match, value]], events)
    end

    def test_case_match_return
      assert_run([1, 2, 3], <<~RUBY)
        class CompileTestCaseMatchReturn
          def value(input)
            case input
            in 1
              return 1
            in 2.5
              return 2
            else
              return 3
            end
          end
        end
        object = CompileTestCaseMatchReturn.new
        [object.value(1), object.value(2.5), object.value(4)]
      RUBY
    end

    def test_case_match_disasm
      [
        ["case 1; in 2; :matched; end", :raise_pattern_mismatch, 3],
        ["case 1; in 2; in 3; end", :raise_pattern_nomatch, 1],
        ["case 1; in 1 if false; end", :raise_pattern_guard, 1]
      ].each do |source, kind, noperands|
        unit = Prism.compile(source, freeze: true).value
        assert_include(unit.disasm, " = match(")
        assert_include(unit.disasm, "#{kind}(")
        instruction = unit.graphs[0].blocks.flat_map(&:insns).find { |insn| insn.kind == kind }
        assert_nil(instruction.data)
        assert_equal(noperands, instruction.opnds.length)
      end
    end

    def test_case
      [
        [2, "case 2; when 1; 1; when 2; 2; else; 3; end"],
        [1, "case 2; when 1, 2, 3; 1; else; 2; end"],
        [3, "case 4; when 1, 2; 1; when 3; 2; else; 3; end"],
        [nil, "case 4; when 1; 1; end"],
        [nil, "case 1; when 1; end"],
        [nil, "case 4; when 1; 1; else; end"],
        [1, "case nil; when nil; 1; else; 2; end"],
        [1, "case false; when false; 1; else; 2; end"],
        [1, "case 2; when Integer; 1; else; 2; end"],
        [1, "case 2; when 1..3; 1; else; 2; end"],
        [1, 'case "abc"; when /b/; 1; else; 2; end'],
        [2, "case; when nil, false; 1; when 0; 2; else; 3; end"],
        [3, "case; when false; 1; when nil; 2; else; 3; end"],
        [nil, "case; when false; 1; end"],
        [nil, "case; when true; end"],
        [3, "case 1; when 1; case 2; when 2; 3; end; end"],
        [3, "1 + (case 2; when 2; 2; else; 0; end)"],
        [2, "case (if true; 2; else; 3; end); when (if false; 1; else; 2; end); 2; end"],
        [3, "a = 0; while a < 3; case a; when 0, 1; a += 1; else; a += 1; end; end; a"]
      ].each do |expected, source|
        assert_run(expected, source)
      end
    end

    def test_case_effect_context
      [
        "case 1; when 1; [1, 2]; end; 7",
        "case 2; when 1; [1, 2]; when 2; [3, 4]; end; 7",
        "case 3; when 1; [1, 2]; else; [3, 4]; end; 7",
        "case 3; when 1; [1, 2]; end; 7",
        "case 1; when 1; else; end; 7",
        "case; when false; [1, 2]; when true; [3, 4]; end; 7"
      ].each do |source|
        unit = compile_unit(source)
        assert_equal(7, vm.run(unit), source)
        graph = unit.graphs[0]
        assert(graph.blocks.all? { |block| block.params.empty? }, source)
        assert_not_include(graph.blocks.flat_map(&:insns).map(&:kind), :new_array_static, source)
      end
    end

    def test_case_when_splats
      [
        [1, 'case 2; when *[1, 2, 3]; 1; else; 0; end'],
        [0, 'case 4; when *[1, 2, 3]; 1; else; 0; end'],
        [1, 'case 2; when 0, *[1, 2], (raise "skipped"); 1; else; 0; end'],
        [1, 'case 2; when *[], *[0, 1], 2; 1; else; 0; end'],
        [1, 'case 2; when *[String, Integer]; 1; else; 0; end'],
        [1, 'case 2; when *[1..3]; 1; else; 0; end'],
        [1, 'case [1, 2]; when *[[1, 2]]; 1; else; 0; end'],
        [1, 'case nil; when *[nil]; 1; else; 0; end'],
        [0, 'case nil; when *nil; 1; else; 0; end'],
        [1, 'case false; when *false; 1; else; 0; end'],
        [1, 'case 2; when *2; 1; else; 0; end'],
        [nil, 'case 2; when *[3]; 1; end'],
        [0, 'case; when *[]; 1; else; 0; end'],
        [0, 'case; when *[false, nil]; 1; else; 0; end'],
        [0, 'case; when *nil; 1; else; 0; end'],
        [0, 'case; when *false; 1; else; 0; end'],
        [1, 'case; when *[nil, false, 0]; 1; else; 0; end'],
        [1, 'case; when *[false], nil, *[true], (raise "skipped"); 1; else; 0; end'],
        [:array_was_evaluated, 'case "ab"; when *[/a(b)/, (raise "skipped")]; $1; end rescue :array_was_evaluated'],
        ['b', 'case "ab"; when *[/a(b)/]; $1; end']
      ].each { |expected, source| assert_run(expected, source) }
    end

    def test_case_when_splat_evaluation_order
      assert_run([:predicate, :array, :first, :second, :body], <<~RUBY)
        events = []
        first = Object.new
        first.define_singleton_method(:===) { |value| events << :first; false }
        second = Object.new
        second.define_singleton_method(:===) { |value| events << :second; :truthy }
        third = Object.new
        third.define_singleton_method(:===) { |value| raise "skipped" }
        case (events << :predicate; 2)
        when *(events << :array; [first, second, third]), (raise "skipped")
          events << :body
        else
          events << :else
        end
        events
      RUBY
      assert_run([:array, :to_a, :body], <<~RUBY)
        events = []
        conditions = Object.new
        conditions.define_singleton_method(:to_a) { events << :to_a; [1, 2] }
        conditions.define_singleton_method(:to_ary) { raise "to_ary must not be called" }
        case 2
        when *(events << :array; conditions)
          events << :body
        end
        events
      RUBY
      assert_run([:first, :second, :body], <<~RUBY)
        events = []
        case
        when *(events << :first; [false, nil]), *(events << :second; [true]), (raise "skipped")
          events << :body
        end
        events
      RUBY
    end

    def test_case_evaluation_order
      assert_run([:predicate, :first, :second, :body], <<~RUBY)
        events = []
        case (events << :predicate; 2)
        when (events << :first; 1), (events << :second; 2), (events << :skipped; 3)
          events << :body
        when (events << :later; 2)
          events << :later_body
        else
          events << :else
        end
        events
      RUBY

      assert_run([:first, :second, :body], <<~RUBY)
        events = []
        case
        when (events << :first; false), (events << :second; 0), (events << :skipped; true)
          events << :body
        else
          events << :else
        end
        events
      RUBY
    end

    def test_case_custom_match
      assert_run([:matched, [2]], <<~RUBY)
        class CompileTestCaseMatcher
          def initialize(events)
            @events = events
          end

          def ===(value)
            @events << value
            :truthy
          end
        end
        events = []
        matcher = CompileTestCaseMatcher.new(events)
        result = case 2
        when matcher
          :matched
        else
          :unmatched
        end
        [result, events]
      RUBY
    end

    def test_case_return
      assert_run([1, 2, 3], <<~RUBY)
        class CompileTestCaseReturn
          def value(input)
            case input
            when 1
              return 1
            when 2
              return 2
            else
              return 3
            end
          end
        end
        object = CompileTestCaseReturn.new
        [object.value(1), object.value(2), object.value(4)]
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

    def test_constant_read_effect_context
      assert_run(7, "String; 7")
      scope = Module.new
      graph = compile_unit("Missing; 7").graphs[0]
      frame = -> { Compile::VM::Frame.new(graph, scope, [scope, Object].freeze) }
      assert_raise(NameError) { vm.run_frame(frame.call) }
      names = []
      scope.define_singleton_method(:const_missing) { |name| names << name; 1 }
      assert_equal(7, vm.run_frame(frame.call))
      assert_equal([:Missing], names)
    end

    def test_constant_path_effect_context
      assert_run(7, "::String; Float::INFINITY; 7")
      assert_run_raises(NameError, "String::CompileTestMissing; 7")
      assert_run_raises(TypeError, "1.itself::Value; 7")
      assert_run([:receiver, :Missing], <<~RUBY)
        events = []
        receiver = Module.new
        receiver.define_singleton_method(:const_missing) { |name| events << name; 1 }
        (events << :receiver; receiver)::Missing
        events
      RUBY
    end

    def test_const_set_recv_rel
      assert_run_raises(TypeError, "1.itself::CompileTestNotModule = 1")
    end

    def test_constant_and_write_effect_context
      scope = Module.new
      scope.const_set(:Value, true)
      graph = compile_unit("Value &&= [1, 2]; Value").graphs[0]
      assert(graph.blocks.all? { |block| block.params.empty? })
      ignore_warnings do
        assert_equal([1, 2], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      end
      [nil, false].each do |value|
        ignore_warnings { scope.const_set(:Value, value) }
        graph = compile_unit("Value &&= raise('rhs ran'); Value").graphs[0]
        assert_equal(value, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      end
      graph = compile_unit("Missing &&= 1; 7").graphs[0]
      assert_raise(NameError) { vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)) }
    end

    def test_constant_or_write_effect_context
      scope = Module.new
      graph = compile_unit("Value ||= [1, 2]; Value").graphs[0]
      assert(graph.blocks.all? { |block| block.params.empty? })
      assert_equal([1, 2], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      [nil, false].each do |value|
        ignore_warnings do
          scope.const_set(:Value, value)
          assert_equal([1, 2], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
        end
      end
      graph = compile_unit("Value ||= raise('rhs ran'); Value").graphs[0]
      assert_equal([1, 2], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
    end

    def test_constant_path_and_write_effect_context
      ["self::Value", "::CompileTestPathAndEffect"].each do |target|
        scope = Module.new
        owner, name = target.start_with?("::") ? [Object, :CompileTestPathAndEffect] : [scope, :Value]
        owner.const_set(name, true)
        graph = compile_unit("#{target} &&= [1, 2]; #{target}").graphs[0]
        assert(graph.blocks.all? { |block| block.params.empty? })
        ignore_warnings do
          assert_equal([1, 2], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
        end
        [nil, false].each do |value|
          ignore_warnings { owner.const_set(name, value) }
          graph = compile_unit("#{target} &&= raise('rhs ran'); #{target}").graphs[0]
          assert_equal(value, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
        end
        owner.send(:remove_const, name)
        graph = compile_unit("#{target} &&= 1; 7").graphs[0]
        assert_raise(NameError) { vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)) }
      ensure
        owner.send(:remove_const, name) if owner&.const_defined?(name, false)
      end
    end

    def test_constant_path_or_write_effect_context
      ["self::Value", "::CompileTestPathOrEffect"].each do |target|
        scope = Module.new
        owner, name = target.start_with?("::") ? [Object, :CompileTestPathOrEffect] : [scope, :Value]
        graph = compile_unit("#{target} ||= [1, 2]; #{target}").graphs[0]
        assert(graph.blocks.all? { |block| block.params.empty? })
        assert_equal([1, 2], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
        [nil, false].each do |value|
          ignore_warnings do
            owner.const_set(name, value)
            assert_equal([1, 2], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
          end
        end
        graph = compile_unit("#{target} ||= raise('rhs ran'); #{target}").graphs[0]
        assert_equal([1, 2], vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      ensure
        owner.send(:remove_const, name) if owner&.const_defined?(name, false)
      end
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
      assert_equal([:trace_class, :trace_line, :load_object, :trace_end, :return_value], unit.graphs[1].blocks[0].insns.map(&:kind))
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

    def test_define_class_effect_context
      source = "class CompileTestClassEffect; VALUE = 3; [1, 2]; end; CompileTestClassEffect::VALUE"
      unit = compile_unit(source)
      assert_equal(3, vm.run(unit))
      assert_not_include(unit.graphs[1].blocks.flat_map(&:insns).map(&:kind), :new_array_static)
      instructions = unit.graphs[1].blocks.flat_map(&:insns)
      assert_not_include(instructions.map(&:kind), :load_nil)
      assert_equal(:return, instructions.last.kind)
      assert_empty(instructions.last.opnds)
      assert_match(/\breturn$/, unit.disasm)
      assert_run([1, 2], "class CompileTestClassValue; [1, 2]; end")
      assert_run(3, "class CompileTestClassBodyEffect; @value = 3; def self.value; @value; end; self.value; end; CompileTestClassBodyEffect.value")
      assert_run(7, "class CompileTestClassEmptyEffect; end; 7")
      assert_run_raises(RuntimeError, "class CompileTestClassRaisesEffect; raise 'body'; end; 7", "body")
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

    def test_alias_global_variable
      assert_run(nil, "$compile_alias_source = 1; alias $compile_alias_target $compile_alias_source")
      assert_run([2, 2], "$compile_alias_target = 2; [$compile_alias_source, $compile_alias_target]")
      assert_run([3, 3], "$compile_alias_source = 3; [$compile_alias_source, $compile_alias_target]")
      assert_run([1, 4, 4], "$compile_alias_a = 1; $compile_alias_c = 3; alias $compile_alias_b $compile_alias_a; alias $compile_alias_b $compile_alias_c; $compile_alias_b = 4; [$compile_alias_a, $compile_alias_b, $compile_alias_c]")
      assert_run(2, "proc { alias $compile_alias_block $compile_alias_source }.call; $compile_alias_block = 2; $compile_alias_source")
      assert_same($stdout, vm.run(compile_unit("alias $compile_alias_stdout $stdout; $compile_alias_stdout")))
    end

    def test_alias_global_variable_undefined
      warnings = capture_warnings do
        assert_run(nil, "alias $compile_alias_undefined_target $compile_alias_undefined_source")
      end
      assert_empty(warnings)
      assert_nil(eval("defined?($compile_alias_undefined_source)", TOPLEVEL_BINDING))
      assert_nil(eval("defined?($compile_alias_undefined_target)", TOPLEVEL_BINDING))
    end

    def test_alias_global_variable_back_reference
      assert_run("abc", "alias $compile_alias_match $&; /abc/ =~ 'abc'; $compile_alias_match")
      assert_run("before", "alias $compile_alias_pre $`; /abc/ =~ 'beforeabcafter'; $compile_alias_pre")
      assert_run("after", "alias $compile_alias_post $'; /abc/ =~ 'beforeabcafter'; $compile_alias_post")
      assert_run([true, true], "alias $compile_alias_matchdata $~; md = /abc/.match('abc'); $compile_alias_matchdata = md; [md.equal?($~), md.equal?($compile_alias_matchdata)]")
      assert_run(nil, "alias $compile_alias_clear_match $~; /abc/ =~ 'abc'; $compile_alias_clear_match = nil; $~")
      assert_run_raises(NameError, "alias $compile_alias_readonly $&; $compile_alias_readonly = 1")
    end

    def test_alias_global_variable_metadata
      unit = Prism.compile("alias $compile_alias_metadata $compile_alias_original", freeze: true).value
      insns = unit.graphs[0].blocks.flat_map(&:insns)
      insn = insns.find { |candidate| candidate.kind == :alias_gvar }
      names = insn.opnds.map { |id| insns.find { |candidate| candidate.kind == :load_object && candidate.opnds[0] == id }.data }
      assert_equal([:$compile_alias_metadata, :$compile_alias_original], names)
      assert_include(unit.disasm, "alias_gvar")
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
      assert_run([1, 2], "class CompileTestCVar; @@b = [1, 2]; @@b; end")
      assert_run([3, 4], "class CompileTestCVar; @@b = [3, 4]; end")

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

    def test_cvar_read_effect_context
      assert_run(7, "class CompileTestCVarReadEffect; @@a = 1; @@a; 7; end")
      assert_run_raises(NameError, "class CompileTestCVarReadEffect; @@missing; 7; end", "uninitialized class variable @@missing in CompileTestCVarReadEffect")
      assert_run_raises(RuntimeError, "@@compile_test_top; 7", "class variable access from toplevel")
    end

    def test_cvar_and_write_and_operator_write
      assert_run(3, "class CompileTestCVarAnd; @@a = 1; @@a &&= 3; @@a; end")
      assert_run(false, "class CompileTestCVarAnd; @@b = false; @@b &&= 3; @@b; end")
      assert_run(4, "class CompileTestCVarAnd; @@c = 1; @@c += 3; @@c; end")

      assert_run_raises(NameError, "class CompileTestCVarAnd; @@missing &&= 1; end", "uninitialized class variable @@missing in CompileTestCVarAnd")
      assert_run_raises(NameError, "class CompileTestCVarAnd; @@missing += 1; end", "uninitialized class variable @@missing in CompileTestCVarAnd")
    end

    def test_cvar_and_write_effect_context
      source = "class CompileTestCVarAndEffect; @@a = true; @@a &&= [1, 2]; @@a; end"
      unit = compile_unit(source)
      assert_equal([1, 2], vm.run(unit))
      assert(unit.graphs[1].blocks.all? { |block| block.params.empty? })
      assert_run(false, "class CompileTestCVarAndEffect; @@b = false; @@b &&= raise('rhs ran'); @@b; end")
      assert_run(nil, "class CompileTestCVarAndEffect; @@c = nil; @@c &&= raise('rhs ran'); @@c; end")
      assert_run([1, 2], "class CompileTestCVarAndEffect; @@d = true; @@d &&= [1, 2]; end")
      assert_run_raises(NameError, "class CompileTestCVarAndEffect; @@missing &&= 1; 7; end", "uninitialized class variable @@missing in CompileTestCVarAndEffect")
    end

    def test_cvar_or_write_effect_context
      source = "class CompileTestCVarOrEffect; @@a ||= [1, 2]; @@a; end"
      unit = compile_unit(source)
      assert_equal([1, 2], vm.run(unit))
      assert(unit.graphs[1].blocks.all? { |block| block.params.empty? })
      assert_run([1, 2], "class CompileTestCVarOrEffect; @@b = nil; @@b ||= [1, 2]; @@b; end")
      assert_run([1, 2], "class CompileTestCVarOrEffect; @@c = false; @@c ||= [1, 2]; @@c; end")
      assert_run(1, "class CompileTestCVarOrEffect; @@d = 1; @@d ||= raise('rhs ran'); @@d; end")
      assert_run([1, 2], "class CompileTestCVarOrEffect; @@e ||= [1, 2]; end")
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
      ignore_warnings { assert_run(nil, "$compile_test_and_new &&= 5") }
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
      vm.run(compile_unit("class CompileTestReturn; def none; return; 1; end; def one; return 1; 2; end; def many; return 1, 2; end; def array; return [1]; end; nil; end"))
      source = "CompileTestReturn.new"

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
      vm.run(compile_unit("class CompileTestDefArity; def a(b) = b; end"))
      source = "CompileTestDefArity.new"
      assert_run_raises(ArgumentError, "#{source}.a", "wrong number of arguments (given 0, expected 1)")
      assert_run_raises(ArgumentError, "#{source}.a(1, 2)", "wrong number of arguments (given 2, expected 1)")
    end

    def test_define_method_rest_parameter
      vm.run(compile_unit("class CompileTestDefRest; def a(*args) = args; end"))
      source = "CompileTestDefRest.new"
      assert_run([], "#{source}.a")
      assert_run([1, 2, 3], "#{source}.a(1, 2, 3)")
      assert_run([[1, 2]], "#{source}.a([1, 2])")
      vm.run(compile_unit("class CompileTestDefRequiredRest; def a(first, *rest) = [first, rest]; end"))
      source = "CompileTestDefRequiredRest.new"
      assert_run([1, []], "#{source}.a(1)")
      assert_run([1, [2, 3]], "#{source}.a(1, 2, 3)")
      assert_run_raises(ArgumentError, "#{source}.a", "wrong number of arguments (given 0, expected 1+)")
      assert_run([[1, 2], [1]], "class CompileTestDefRestFresh; def a(*args); args << 2; end; end; input = [1]; [CompileTestDefRestFresh.new.a(input[0]), input]")
      assert_run([1, 2], "class CompileTestDefRestCapture; def a(*args); proc { args << 2 }.call; args; end; end; CompileTestDefRestCapture.new.a(1)")
    end

    def test_define_method_anonymous_rest_parameter
      vm.run(compile_unit("class CompileTestDefAnonymousRest; def a(*) = 1; end"))
      source = "CompileTestDefAnonymousRest.new"
      assert_run(1, "#{source}.a")
      assert_run(1, "#{source}.a(2, 3)")
      vm.run(compile_unit("class CompileTestDefRequiredAnonymousRest; def a(first, *) = first; end"))
      source = "CompileTestDefRequiredAnonymousRest.new"
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
      vm.run(compile_unit("class CompileTestDefBasic < BasicObject; def a(b) = b; end"))
      source = "CompileTestDefBasic.new"
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

    def test_flip_flop
      [
        [[2, 3, 4], "(1..6).select { |i| if (i == 2)..(i == 4); true; else; false; end }"],
        [[2], "(1..6).select { |i| if (i == 2)..(i == 2); true; else; false; end }"],
        [[2, 3, 4, 5, 6], "(1..6).select { |i| if (i == 2)...(i == 2); true; else; false; end }"],
        [[1, 2, 1, 2], "[1, 2, 3, 1, 2, 3].select { |i| if (i == 1)..(i == 2); true; else; false; end }"],
        [[2, 3, 4], "out = []; for i in [1, 2, 3, 4, 5]; if (i == 2)..(i == 4); out << i; end; end; out"],
        [[2, 3, 4], "(1..4).select { |i| if (i == 2)..; true; else; false; end }"],
        [[], "(1..4).select { |i| if ..(i == 2); true; else; false; end }"],
        [["start", "middle", "stop"], "['skip', 'start', 'middle', 'stop', 'after'].select { |text| $_ = text; if /start/../stop/; true; else; false; end }"]
      ].each { |expected, source| assert_run(expected, source) }
    end

    def test_flip_flop_evaluation_order
      { ".." => [[:left, 1], [:left, 2], [:right, 2], [:right, 3], [:left, 4]],
        "..." => [[:left, 1], [:left, 2], [:right, 3], [:left, 4]] }.each do |operator, events|
        source = "events = []; p = proc { |i| if (events << [:left, i]; i == 2)#{operator}(events << [:right, i]; i == 3); true; else; false; end }; result = [1, 2, 3, 4].map { |i| p.call(i) }; [result, events]"
        assert_run([[false, true, true, false], events], source)
      end
    end

    def test_flip_flop_scope
      assert_run([true, true, false], <<~RUBY)
        class CompileTestFlipFactory
          def make
            proc { |x| if x..false; true; else; false; end }
          end
        end
        factory = CompileTestFlipFactory.new
        a = factory.make
        b = factory.make
        [a.call(true), a.call(false), b.call(false)]
      RUBY
      assert_run([true, true], "factory = proc { proc { |x| if x..false; true; else; false; end } }; a = factory.call; b = factory.call; [a.call(true), b.call(false)]")
      assert_run(false, "class CompileTestFlipRecursive; def value(start); if start..false; start ? value(false) : true; else; false; end; end; end; CompileTestFlipRecursive.new.value(true)")
      assert_run([[true, false], [true, true]], "p = proc { |a, b| x = if a..false; true; else; false; end; y = if b..false; true; else; false; end; [x, y] }; [p.call(true, false), p.call(false, true)]")
    end

    def test_flip_flop_integer_bounds
      previous_line = $.
      assert_run([2, 3, 4], "out = []; [1, 2, 3, 4, 5].each { |i| $. = i; if 2..4; out << i; end }; out")
    ensure
      $. = previous_line
    end

    def test_flip_flop_state_after_exception
      scope = Module.new
      checker = Object.new
      fail_check = true
      checker.define_singleton_method(:check) { raise 'end failed' if fail_check; false }
      scope.const_set(:Checker, checker)
      graph = compile_unit("proc { |x| if x..Checker.check; true; else; false; end }").graphs[0]
      block = vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze))
      assert_raise_with_message(RuntimeError, "end failed") { block.call(true) }
      fail_check = false
      assert_equal(true, block.call(false))
    end

    def test_flip_flop_metadata
      unit = Prism.compile("proc { if true..false; 1; end }; proc { if true...false; 1; end }", freeze: true).value
      assert_equal([2, 0, 0], unit.graphs.map(&:nflip_flops))
      unit.graphs.each { |graph| assert_empty(graph.locals) }
      frame = Compile::VM::Frame.new(unit.graphs[0], self, [Object])
      assert_equal([false, false], frame.flip_flops)
      assert_include(unit.disasm, "flip_flops=2")
      assert_include(unit.disasm, "load_flip_flop 0")
      assert_include(unit.disasm, "load_flip_flop 1")
      assert_include(unit.disasm, "store_flip_flop")
    end

    def test_source_file
      assert_run("", "__FILE__")
      ["example.rb", "path/with spaces/example.rb", "例.rb"].each do |filepath|
        unit = Prism.compile("__FILE__", filepath: filepath, raise_error: :plain).value
        assert_equal(filepath, vm.run(unit))
        assert_include(unit.disasm, filepath.inspect)
      end
      unit = Prism.compile("proc { __FILE__ }.call", filepath: "block.rb", raise_error: :plain).value
      assert_equal("block.rb", vm.run(unit))
      unit = Prism.compile("class CompileTestSourceFile; def value; __FILE__; end; end; CompileTestSourceFile.new.value", filepath: "method.rb", raise_error: :plain).value
      assert_equal("method.rb", vm.run(unit))
      unit = Prism.compile("[__FILE__, (__FILE__ in __FILE__)]", filepath: "pattern.rb", raise_error: :plain).value
      assert_equal(["pattern.rb", true], vm.run(unit))
    end

    def test_source_file_from_file
      Tempfile.create(["compile_source_file", ".rb"]) do |file|
        file.write("__FILE__")
        file.flush
        assert_equal(file.path, vm.run(Prism.compile_file(file.path, raise_error: :plain).value))
      end
    end

    def test_compile_options
      assert_raise(ArgumentError) { Prism.compile("1", bogus: true) }
      assert_raise(TypeError) { Prism.compile(nil) }

      unit = Prism.compile("1", line: 10).value
      trace_line = unit.graphs[0].blocks.flat_map(&:insns).find { |insn| insn.kind == :trace_line }
      assert_equal 10, trace_line.data
    end

    def test_begin
      [
        [nil, "begin; end"],
        [2, "begin; 1; 2; end"],
        [3, "1 + begin; 2; end"],
        [2, "begin; begin; 2; end; end"],
        [3, "begin; if true; 3; else; 4; end; end"],
        [3, "begin; a = 3; end; a"],
        [[1, 2], "events = []; begin; events << 1; events << 2; end; events"]
      ].each { |expected, source| assert_run(expected, source) }

      unit = compile_unit("begin; if true; 1; else; 2; end; end")
      graph = unit.graphs[0]
      assert_equal(1, graph.regions.length)
      graph.blocks.each { |block| assert_same(graph.regions[0], block.region) }
    end

    def test_begin_rescue
      [
        [1, "begin; 1; rescue; 2; end"],
        [2, "begin; raise 'failure'; rescue; 2; end"],
        [nil, "begin; raise 'failure'; rescue; end"],
        [2, "begin; raise ArgumentError; rescue ArgumentError; 2; end"],
        [3, "begin; raise TypeError; rescue ArgumentError; 2; rescue TypeError; 3; end"],
        [3, "begin; raise TypeError; rescue ArgumentError, TypeError; 3; end"],
        [3, "classes = [ArgumentError, TypeError]; begin; raise TypeError; rescue *classes; 3; end"],
        [3, "begin; raise TypeError; rescue *[], TypeError; 3; end"],
        [3, "begin; raise Exception; rescue Exception; 3; end"],
        ["failure", "begin; raise 'failure'; rescue => e; e.message; end"],
        ["failure", "begin; raise 'failure'; rescue => @rescue_error; @rescue_error.message; end"],
        [2, "a = 1; begin; a = 2; raise 'failure'; rescue; a; end"],
        [3, "1 + begin; raise 'failure'; rescue; 2; end"],
        [3, "begin; raise 'failure'; rescue; if true; 3; else; 4; end; end"],
        [3, "begin; if true; raise 'failure'; end; rescue; 3; end"],
        [3, "begin; begin; raise ArgumentError; rescue TypeError; 2; end; rescue ArgumentError; 3; end"],
        [3, "begin; begin; raise ArgumentError; rescue ArgumentError; raise TypeError; end; rescue TypeError; 3; end"],
        [[2, 2], "a = []; i = 0; while i < 2; a << (begin; raise 'failure'; rescue; 2; end); i += 1; end; a"],
        [[2, 2], "[1, 2].map { begin; raise 'failure'; rescue; 2; end }"],
        [2, "f = -> { begin; raise 'failure'; rescue; return 2; end; 3 }; f.call"]
      ].each { |expected, source| assert_run(expected, source) }
    end

    def test_begin_rescue_reference_targets
      assert_run(nil, "begin; rescue => target.error; end")
      assert_run(1, "begin; 1; rescue => target[missing_index]; end")
      assert_run("failure", <<~RUBY)
        target = []
        def target.error=(error); self << error; end
        begin
          raise "failure"
        rescue => target.error
          target[0].message
        end
      RUBY
      assert_run("failure", 'target = {}; begin; raise "failure"; rescue => target[:error]; target[:error].message; end')
      assert_run("failure", 'namespace = Module.new; begin; raise "failure"; rescue => namespace::Error; namespace::Error.message; end')
      assert_run(:rescued, 'target = nil; begin; raise; rescue => target&.error; :rescued; end')
    end

    def test_begin_rescue_reference_evaluation_order
      assert_run([[:body, :match, :receiver, :rescue], "failure"], <<~RUBY)
        events = []
        target = []
        def target.error=(error); self << error; end
        receiver = -> { events << :receiver; target }
        matcher = Module.new
        matcher.define_singleton_method(:===) { |error| events << :match; true }
        begin
          events << :body
          raise "failure"
        rescue matcher => receiver.call.error
          events << :rescue
        end
        [events, target[0].message]
      RUBY
      assert_run([[:receiver, :index, :rescue], "failure"], <<~RUBY)
        events = []
        target = {}
        receiver = -> { events << :receiver; target }
        index = -> { events << :index; :error }
        begin
          raise "failure"
        rescue => receiver.call[index.call]
          events << :rescue
        end
        [events, target[:error].message]
      RUBY
      assert_run(:outer, <<~RUBY)
        target = Object.new
        def target.error=(error); raise TypeError; end
        begin
          begin
            raise "failure"
          rescue => target.error
            :inner
          end
        rescue TypeError
          :outer
        end
      RUBY
    end

    def test_begin_rescue_else
      [
        [3, "begin; 1; rescue; 2; else; 3; end"],
        [nil, "begin; 1; rescue; 2; else; end"],
        [2, "begin; raise 'failure'; rescue; 2; else; 3; end"],
        [3, "begin; begin; 1; rescue; 2; else; raise 'failure'; end; rescue; 3; end"],
        [[:body, :else], "events = []; begin; events << :body; rescue; events << :rescue; else; events << :else; end; events"],
        [[:rescue], "events = []; begin; raise 'failure'; rescue; events << :rescue; else; events << :else; end; events"]
      ].each { |expected, source| assert_run(expected, source) }
      assert_run_raises(RuntimeError, "begin; 1; rescue; 2; else; raise 'else'; end", "else")
    end

    def test_begin_rescue_exception_context
      [
        "begin; raise 'outer'; rescue => e; [$!.equal?(e), $!.message]; end",
        "begin; raise 'outer'; rescue; a = $!; begin; raise 'inner'; rescue; b = $!.message; end; [b, $!.equal?(a)]; end",
        "begin; raise 'outer'; rescue; a = $!; begin; 1; rescue; 2; else; b = $!.equal?(a); end; b; end",
        "before = $!; begin; raise 'failure'; rescue; 1; end; $!.equal?(before)",
        "begin; begin; raise 'failure'; rescue; raise; end; rescue => e; [e.message, e.cause]; end",
        "begin; begin; raise 'original'; rescue; raise 'replacement'; end; rescue => e; [e.message, e.cause.message]; end",
        "begin; raise 'outer'; rescue => e; f = -> { $!.equal?(e) }; f.call; end"
      ].each { |source| assert_run(eval(source), source) }
    end

    def test_begin_rescue_failure
      assert_run_raises(ArgumentError, "begin; raise ArgumentError, 'unhandled'; rescue TypeError; 1; end", "unhandled")
      assert_run_raises(Exception, "begin; raise Exception, 'unhandled'; rescue; 1; end", "unhandled")
      assert_run_raises(TypeError, "begin; raise 'failure'; rescue 1; 2; end", "class or module required for rescue clause")
      assert_run_raises(TypeError, "begin; raise 'failure'; rescue *[1]; 2; end", "class or module required for rescue clause")
      assert_run_raises(RuntimeError, "begin; raise 'first'; rescue; raise 'second'; end", "second")
    end

    def test_begin_rescue_backreferences
      [
        "begin; /(a)/ =~ 'a'; rescue; end; $1",
        "/(a)/ =~ 'a'; begin; $1; rescue; end",
        "begin; /(a)/ =~ 'a'; raise 'failure'; rescue; $1; end",
        "begin; raise 'failure'; rescue; /(a)/ =~ 'a'; end; $1",
        "begin; /(a)/ =~ 'a'; rescue; else; $1; end",
        "begin; raise 'outer'; rescue; /(a)/ =~ 'a'; begin; /(b)/ =~ 'b'; raise 'inner'; rescue; $1; end; end",
        "begin; /(a)/ =~ 'a'; begin; /(b)/ =~ 'b'; raise 'inner'; rescue TypeError; end; rescue; $1; end"
      ].each { |source| assert_run(eval(source), source) }
    end

    def test_begin_rescue_matching
      scope = Module.new
      events = []
      matcher = Module.new
      matcher.define_singleton_method(:===) { |exception| events << exception.message; :matched }
      scope.const_set(:Matcher, matcher)
      source = "begin; raise 'failure'; rescue (Events << :first; TypeError), Matcher, (Events << :skipped; RuntimeError); :handled; end"
      scope.const_set(:Events, events)
      expected = scope.module_eval(source)
      native_events = events.dup
      events.clear
      graph = compile_unit(source).graphs[0]
      assert_equal(expected, vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze)))
      assert_equal(native_events, events)

      scope.const_set(:StandardError, Exception)
      graph = compile_unit("begin; raise Exception, 'unhandled'; rescue; :handled; end").graphs[0]
      assert_raise_with_message(Exception, "unhandled") do
        vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze))
      end
    end

    def test_begin_rescue_method_return
      assert_run([1, 2], <<~RUBY)
        class CompileTestRescueReturn
          def from_body
            begin
              return 1
            rescue
              3
            end
          end

          def from_handler
            raise 'failure'
          rescue
            return 2
          end
        end
        object = CompileTestRescueReturn.new
        [object.from_body, object.from_handler]
      RUBY
    end

    def test_begin_rescue_regions
      unit = Prism.compile("begin; raise 'failure'; rescue => e; e.message; else; :success; end", freeze: true).value
      graph = unit.graphs[0]
      region = graph.regions.find { |candidate| candidate.kind == :rescue }
      assert_same(graph.regions[0], region.parent)
      assert_same(region, region.entry.region)
      assert_same(region.parent, region.handler.region.parent)
      assert_equal(:default, region.handler.region.kind)
      assert_equal(1, region.handler.params.length)
      assert_predicate(graph.regions, :frozen?)
      graph.regions.each { |candidate| assert_predicate(candidate, :frozen?) }
      assert_include(unit.disasm, "rescue_match(")
      assert_include(unit.disasm, "trace_rescue")
      assert_include(unit.disasm, "reraise")
      assert_equal("failure", vm.run(unit))
    end

    def test_ensure
      [
        [1, "begin; 1; ensure; 2; end"],
        [nil, "begin; ensure; end"],
        [false, "begin; false; ensure; end"],
        [[1, [:body, :ensure]], "events = []; value = begin; events << :body; 1; ensure; events << :ensure; end; [value, events]"],
        [[2, [:rescue, :ensure]], "events = []; value = begin; raise 'failure'; rescue; events << :rescue; 2; ensure; events << :ensure; end; [value, events]"],
        [[3, [:else, :ensure]], "events = []; value = begin; 1; rescue; 2; else; events << :else; 3; ensure; events << :ensure; end; [value, events]"],
        [[2, 1], "attempts = 0; cleanups = 0; begin; attempts += 1; raise if attempts == 1; rescue; retry; ensure; cleanups += 1; end; [attempts, cleanups]"],
        [[:inner, :outer], "events = []; begin; begin; raise; ensure; events << :inner; end; rescue; ensure; events << :outer; end; events"],
        [[1, [:cleanup]], "events = []; value = -> { begin; return 1; ensure; events << :cleanup; end }.call; [value, events]"],
        [[1, [:cleanup]], "object = Object.new; def object.work(events); begin; return 1; ensure; events << :cleanup; end; end; events = []; [object.work(events), events]"],
        [[2, 2, 1], "attempts = 0; inner = 0; outer = 0; begin; begin; attempts += 1; raise if attempts == 1; ensure; inner += 1; end; rescue; retry; ensure; outer += 1; end; [attempts, inner, outer]"],
        [[:cleanup, 9], "events = []; value = catch(:done) { begin; throw :done, 9; ensure; events << :cleanup; end }; events << value"],
        [2, "i = 0; while i < 2; begin; break 7; ensure; i += 1; next; end; end; i"],
        [2, "-> { begin; return 1; ensure; return 2; end }.call"],
        [2, "-> { begin; raise; ensure; return 2; end }.call"],
        [[7, [1]], "events = []; value = while true; begin; break 7; ensure; events << 1; end; end; [value, events]"],
        [[7, [1]], "events = []; value = [1].each { begin; break 7; ensure; events << 1; end }; [value, events]"],
        [[1, 2], "events = []; i = 0; while i < 2; begin; i += 1; next; ensure; events << i; end; end; events"],
        [2, "i = 0; begin; while i < 2; i += 1; end; ensure; i += 0; end; i"],
        [2, "i = 0; while i < 2; begin; i += 1; redo if i == 1; ensure; end; end; i"],
        [9, "while true; begin; raise; ensure; break 9; end; end"],
        [["body", "body"], "seen = nil; begin; begin; raise 'body'; ensure; seen = $!.message; end; rescue => e; [seen, e.message]; end"],
        [["cleanup", "body"], "begin; begin; raise 'body'; ensure; raise 'cleanup'; end; rescue => e; [e.message, e.cause.message]; end"],
        [:caught, "begin; begin; 1; rescue; :wrong; ensure; raise; end; rescue; :caught; end"],
        [["a", "a"], "result = nil; /a/ =~ 'a'; begin; 1; ensure; result = $&; end; [result, $&]"],
        [1, 'count = 0; 2.times { begin; /#{count += 1}/o; ensure; end }; count'],
        [1, 'count = 0; 2.times { /#{begin; count += 1; ensure; end}/o }; count']
      ].each { |expected, source| assert_run(expected, source) }
      assert_run_raises(RuntimeError, "begin; raise 'body'; ensure; 1; end", "body")
    end

    def test_ensure_regions
      unit = Prism.compile("begin; 1; ensure; 2; end", freeze: true).value
      graph = unit.graphs[0]
      region = graph.regions.find { |candidate| candidate.kind == :ensure }
      assert_same(graph.regions[0], region.parent)
      assert_same(region, region.entry.region)
      assert_same(region.parent, region.handler.region.parent)
      assert_equal([], region.handler.params)
      terminator = region.handler.insns.last
      assert_equal(:ensure_return, terminator.kind)
      assert_same(region, terminator.data)
      assert_include(unit.disasm, "ensure_return r#{region.id}")
      assert_equal(1, vm.run(unit))
    end

    def test_rescue_modifier
      [
        [1, "1 rescue 2"],
        [nil, "nil rescue 2"],
        [false, "false rescue 2"],
        [2, "raise('failure') rescue 2"],
        [2, "raise(ArgumentError) rescue 2"],
        [2, "missing_modifier_method() rescue 2"],
        [3, "1 + (raise('failure') rescue 2)"],
        [2, "value = (raise('failure') rescue 2); value"],
        [2, "raise('first') rescue raise('second') rescue 2"],
        [3, "(if true; raise 'failure'; else; 2; end) rescue 3"],
        [3, "raise('failure') rescue (if true; 3; else; 4; end)"],
        [[:expression], "events = []; (events << :expression; 1) rescue events << :fallback; events"],
        [[:expression, :fallback], "events = []; (events << :expression; raise 'failure') rescue events << :fallback; events"],
        [2, "f = -> { raise('failure') rescue (return 2); 3 }; f.call"]
      ].each { |expected, source| assert_run(expected, source) }
    end

    def test_rescue_modifier_failure
      assert_run_raises(Exception, "raise(Exception, 'unhandled') rescue 2", "unhandled")
      assert_run_raises(RuntimeError, "raise('first') rescue raise('second')", "second")
      assert_run_raises(RuntimeError, "raise('first') rescue raise", "first")
    end

    def test_rescue_modifier_context
      [
        "raise('failure') rescue $!.message",
        "before = $!; (raise('failure') rescue 2); $!.equal?(before)",
        "begin; raise 'outer'; rescue; before = $!; inner = (raise('inner') rescue $!.message); [inner, $!.equal?(before)]; end",
        "begin; raise('first') rescue raise('second'); rescue => e; [e.message, e.cause.message]; end",
        "(raise('failure') rescue (/(a)/ =~ 'a')); $1",
        "(/(a)/ =~ 'a'; raise 'failure') rescue $1"
      ].each { |source| assert_run(eval(source), source) }
    end

    def test_rescue_modifier_retry
      [
        "attempts = 0; (attempts += 1; raise if attempts < 2; attempts) rescue retry",
        "attempts = 0; events = []; before = $!; (events << $!.equal?(before); attempts += 1; raise if attempts < 2) rescue retry; events",
        "attempts = 0; begin; attempts += 1; raise if attempts < 2; rescue; (raise('inner') rescue 3); retry; end; attempts",
        "attempts = 0; (attempts += 1; raise if attempts < 2; attempts) rescue (begin; raise 'inner'; rescue; 3; end; retry)"
      ].each { |source| assert_run(eval(source), source) }
    end

    def test_rescue_modifier_regions
      unit = Prism.compile("raise('failure') rescue 2", freeze: true).value
      graph = unit.graphs[0]
      region = graph.regions.find { |candidate| candidate.kind == :rescue }
      assert_same(region, region.entry.region)
      assert_same(region.parent, region.handler.region.parent)
      assert_equal(1, region.handler.params.length)
      assert_include(unit.disasm, "rescue_match(")
      assert_include(unit.disasm, "trace_rescue")
      assert_include(unit.disasm, "reraise")
      assert_equal(2, vm.run(unit))
    end

    def test_retry
      [
        "attempts = 0; begin; attempts += 1; raise 'failure' if attempts < 3; attempts; rescue; retry; end",
        "attempts = 0; begin; attempts += 1; raise TypeError if attempts < 2; rescue ArgumentError; 0; rescue TypeError; retry; end; attempts",
        "attempts = 0; events = []; begin; attempts += 1; events << :body; raise if attempts < 2; rescue; events << :rescue; retry; else; events << :else; end; events",
        "attempts = 0; begin; attempts += 1; raise if attempts < 2; 3; rescue; retry if attempts < 2; 4; end",
        "attempts = 0; begin; attempts += 1; raise if attempts < 2; rescue; begin; raise 'inner'; rescue; 3; end; retry; end; attempts",
        "attempts = 0; begin; attempts += 1; raise if attempts < 2; rescue; begin; retry; rescue TypeError; 3; end; end; attempts",
        "outer = 0; inner = 0; begin; outer += 1; raise if outer < 2; rescue; begin; inner += 1; raise if inner < 2; rescue; retry; end; retry; end; [outer, inner]"
      ].each { |source| assert_run(eval(source), source) }
    end

    def test_retry_exception_context
      [
        "attempts = 0; events = []; before = $!; begin; events << $!.equal?(before); attempts += 1; raise 'failure' if attempts < 2; rescue; events << $!.message; retry; end; events << $!.equal?(before); events",
        "begin; raise 'outer'; rescue; before = $!; attempts = 0; events = []; begin; events << $!.equal?(before); attempts += 1; raise 'inner' if attempts < 2; rescue; events << $!.message; retry; end; events << $!.equal?(before); events; end",
        "attempts = 0; begin; attempts += 1; if attempts < 2; raise 'first'; else; raise 'last'; end; rescue => e; retry if attempts < 2; [e.message, e.cause]; end"
      ].each { |source| assert_run(eval(source), source) }
    end

    def test_retry_backreferences
      source = "attempts = 0; events = []; /(a)/ =~ 'a'; begin; events << $1; attempts += 1; raise if attempts < 2; rescue; /(b)/ =~ 'b'; retry; end; events"
      assert_run(eval(source), source)
    end

    def test_retry_method_parameters
      assert_run([2, [:default]], <<~RUBY)
        class CompileTestRetryParameters
          def run(events, value = (events << :default; 0))
            value += 1
            raise 'failure' if value < 2
            value
          rescue
            retry
          end
        end
        events = []
        result = CompileTestRetryParameters.new.run(events)
        [result, events]
      RUBY
    end

    def test_retry_regions
      unit = compile_unit("attempts = 0; begin; attempts += 1; raise if attempts < 2; rescue; retry; end; attempts")
      graph = unit.graphs[0]
      region = graph.regions.find { |candidate| candidate.kind == :rescue }
      retry_branch = graph.blocks.select { |block| block.region.equal?(region.handler.region) }.flat_map(&:insns).find do |insn|
        insn.kind == :branch && insn.data.equal?(region.entry)
      end
      assert_not_nil(retry_branch)
      assert_empty(retry_branch.opnds)
      assert_equal(2, vm.run(unit))
    end

    def test_shareable_constant_literals
      [:literal, :experimental_copy, :experimental_everything].each do |mode|
        [
          '"value"',
          '["value", { key: [1, nil, true, false, 1.5, 1r, 1i] }]',
          '{}', '[]', '/value/i', '__LINE__', '__ENCODING__',
          '"value#{1}"', ':"value#{1}"'
        ].each do |expression|
          source = "# shareable_constant_value: #{mode}\nValue = #{expression}; [Value, Value.frozen?, Ractor.shareable?(Value)]"
          assert_shareable_constant(source)
        end
      end
    end

    def test_shareable_constant_dynamic_values
      [:experimental_copy, :experimental_everything].each do |mode|
        [
          'value', '[value]', '{ key: value }', '[*value]', '{ **value }'
        ].each do |expression|
          value = expression.include?("**") ? '{ key: +"value" }' : '[+"value"]'
          source = "value = #{value}\n# shareable_constant_value: #{mode}\nValue = #{expression}; [Value, Value.equal?(value), value.frozen?, value.values_at(0).first&.frozen?, Ractor.shareable?(Value)]"
          # Both Array and Hash implement values_at, keeping the source common.
          assert_shareable_constant(source)
        end
      end
      assert_shareable_constant("value = Ractor.make_shareable([+'value']);\n# shareable_constant_value: literal\nValue = [value]; [Value, Value[0].equal?(value), Ractor.shareable?(Value)]")
    end

    def test_shareable_constant_literal_rejection
      [
        "value", "[value, (events << :later; 1)]", "{ value => (events << :later; 1) }",
        "{ key: value }", "[*value]", "{ **value }"
      ].each do |expression|
        input = expression.include?("**") ? '{ key: +"value" }' : '[+"value"]'
        assert_shareable_constant(<<~RUBY)
          events = []
          value = #{input}
          # shareable_constant_value: literal
          begin
            Value = #{expression}
          rescue Ractor::IsolationError => error
            [error.message, events, value.frozen?, self.const_defined?(:Value, false)]
          end
        RUBY
      end
    end

    def test_shareable_constant_writes
      [:literal, :experimental_copy, :experimental_everything].each do |mode|
        ["Value", "Holder::Value", "holder::Value"].each do |target|
          ["=", "||=", "&&=", "+="].each do |operator|
            seed = operator == "&&=" || operator == "+=" ? "#{target} = 1" : ""
            assert_shareable_constant(<<~RUBY)
              module Holder; end
              holder = Holder
              #{seed}
              # shareable_constant_value: #{mode}
              #{target} #{operator} 2
              [#{target}, Ractor.shareable?(#{target})]
            RUBY
          end
        end
      end
    end

    def test_shareable_constant_short_circuit
      [:literal, :experimental_copy, :experimental_everything].each do |mode|
        ["Value", "Holder::Value"].each do |target|
          assert_shareable_constant(<<~RUBY, [1, false])
            module Holder; end
            #{target} = 1
            value = +"value"
            # shareable_constant_value: #{mode}
            #{target} ||= value
            [#{target}, value.frozen?]
          RUBY
          assert_shareable_constant(<<~RUBY, [false, false])
            module Holder; end
            #{target} = false
            value = +"value"
            # shareable_constant_value: #{mode}
            #{target} &&= value
            [#{target}, value.frozen?]
          RUBY
        end
      end
    end

    def test_shareable_constant_paths
      ["Holder::Value", "holder::Value", "Holder::Nested::Value"].each do |target|
        assert_shareable_constant(<<~RUBY)
          module Holder; module Nested; end; end
          holder = Holder
          value = +"value"
          # shareable_constant_value: literal
          begin
            #{target} = value
          rescue Ractor::IsolationError => error
            error.message
          end
        RUBY
      end
    end

    def test_shareable_constant_operator_rhs
      [:literal, :experimental_copy, :experimental_everything].each do |mode|
        assert_shareable_constant(<<~RUBY)
          Value = +"first"
          # shareable_constant_value: #{mode}
          Value += "second"
          [Value, Value.frozen?, Ractor.shareable?(Value)]
        RUBY
      end
    end

    def test_shareable_constant_receiver_evaluation
      [:literal, :experimental_copy, :experimental_everything].each do |mode|
        assert_shareable_constant(<<~RUBY)
          events = []
          holder = Module.new
          # shareable_constant_value: #{mode}
          (events << :receiver; holder)::Value = (events << :value; "value".freeze)
          [events, holder::Value, Ractor.shareable?(holder::Value)]
        RUBY
      end
      assert_shareable_constant(<<~RUBY)
        events = []
        holder = Module.new
        # shareable_constant_value: literal
        begin
          (events << :receiver; holder)::Value = (events << :value; +"value")
        rescue Ractor::IsolationError => error
          [events, error.message, holder.const_defined?(:Value, false)]
        end
      RUBY
    end

    def test_shareable_constant_literal_identity
      unit = compile_unit("# shareable_constant_value: literal\nValue = ['value', { key: 1 }]")
      graph = unit.graphs[0]
      first_scope = Module.new
      second_scope = Module.new
      first = vm.run_frame(Compile::VM::Frame.new(graph, first_scope, [first_scope, Object].freeze))
      second = vm.run_frame(Compile::VM::Frame.new(graph, second_scope, [second_scope, Object].freeze))
      assert_same(first, second)
      assert_predicate(first, :frozen?)
      assert_predicate(first[0], :frozen?)
      assert_predicate(first[1], :frozen?)
    end

    def test_shareable_constant_disasm
      [
        [:literal, :ensure_shareable],
        [:experimental_copy, :make_shareable_copy],
        [:experimental_everything, :make_shareable]
      ].each do |mode, kind|
        unit = Prism.compile("value = +'value';\n# shareable_constant_value: #{mode}\nValue = value", freeze: true).value
        assert_include(unit.disasm, " = #{kind}(")
        insn = unit.graphs[0].blocks.flat_map(&:insns).find { |candidate| candidate.kind == kind }
        assert_equal(2, insn.opnds.length)
        assert_equal(mode == :literal ? "Value" : nil, insn.data)
      end
    end

    def test_compile_regions
      unit = compile_unit("def region_example(x); if x; [1].map { 2 }; else; 3; end; end")
      assert_operator(unit.graphs.length, :>, 1)
      unit.graphs.each do |graph|
        assert_equal(1, graph.regions.length)
        region = graph.regions[0]
        assert_equal(0, region.id)
        assert_equal(:default, region.kind)
        assert_nil(region.parent)
        assert_nil(region.handler)
        assert_same(graph.blocks[0], region.entry)
        graph.blocks.each { |block| assert_same(region, block.region) }
      end
      assert_include(unit.disasm, "r0 (default, entry=bb0):")
      assert_include(unit.disasm, "[region=r0]")
    end

    def test_compile_freeze
      result = Prism.compile("class CompileTestFreeze; def a(b) = b; end; CompileTestFreeze.new.a('c')", freeze: true)
      assert_predicate result, :frozen?

      unit = result.value
      assert_predicate unit, :frozen?
      assert_predicate unit.graphs, :frozen?

      unit.graphs.each do |graph|
        assert_predicate graph, :frozen?
        assert_predicate graph.regions, :frozen?
        graph.regions.each { |region| assert_predicate region, :frozen? }
        assert_predicate graph.blocks, :frozen?
        assert_predicate graph.signature, :frozen?
        assert_predicate graph.signature.requireds, :frozen?
        assert_predicate graph.signature.posts, :frozen?
        assert_predicate graph.signature.required_keywords, :frozen?
        assert_predicate graph.signature.optional_keywords, :frozen?
        assert_predicate graph.signature.optional_keyword_specifieds, :frozen?
        assert_predicate graph.signature.optionals, :frozen?
        assert_predicate graph.signature.optional_specifieds, :frozen?
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

    def assert_shareable_constant(source, expected = :native)
      capture_warnings do
        expected = Module.new.module_eval(source) if expected == :native
        scope = Module.new
        graph = compile_unit(source).graphs[0]
        actual = vm.run_frame(Compile::VM::Frame.new(graph, scope, [scope, Object].freeze))
        assert_equal(expected, actual, source)
      end
    end

    def run_instructions(insns, args, nvalues)
      blocks = []
      region = Compile::Region.new(0, :default, nil, blocks, 0, nil)
      block = Compile::Block.new(0, insns, [0], region)
      blocks << block
      signature = Compile::Signature.new([0], [], [], nil, [], {}, {}, {}, nil, nil, false, false, false)
      graph = Compile::Graph.new(0, :block, nil, nil, blocks, [region], [], nvalues, 0, signature)
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
