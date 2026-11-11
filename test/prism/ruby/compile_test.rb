# frozen_string_literal: true
# typed: ignore

require_relative "../test_helper"

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
        assert_equal(expected, Prism::Compile.run_unit(compile_unit(source)))
      end
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
      assert_raise(NameError) { Prism::Compile.run_unit(compile_unit("String::Integer")) }
      assert_raise(NameError) { Prism::Compile.run_unit(compile_unit("Prism::CompileTest::PRIVATE_CONSTANT")) }
      assert_raise(TypeError) { Prism::Compile.run_unit(compile_unit("Float::INFINITY::Foo")) }
      assert_raise(NameError) { Prism::Compile.run_unit(compile_unit("::String::Integer")) }
      assert_raise(NameError) { Prism::Compile.run_unit(compile_unit("::Prism::CompileTest::PRIVATE_CONSTANT")) }
      assert_raise(NameError) { Prism::Compile.run_unit(compile_unit("String.itself::Integer")) }
      assert_raise(NameError) { Prism::Compile.run_unit(compile_unit("Prism::CompileTest.itself::PRIVATE_CONSTANT")) }
      assert_raise(TypeError) { Prism::Compile.run_unit(compile_unit("1.itself::Foo")) }
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
              assert_raise(NameError) { Compile.run_graph(graph, scope, [scope, Object].freeze) }
              refute owner.const_defined?(name, false)
            else
              writes = operator == "&&=" ? !!initial : initial == :undefined || !initial
              expected = [writes ? 2 : initial, writes ? 1 : 0]
              capture_warnings do
                assert_equal(expected, Compile.run_graph(graph, scope, [scope, Object].freeze), source)
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
          assert_equal([5, 1], Compile.run_graph(graph, scope, [scope, Object].freeze))
        end
        assert_equal(5, owner.const_get(name, false))
        owner.send(:remove_const, name)
        assert_raise(NameError) { Compile.run_graph(graph, scope, [scope, Object].freeze) }
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
          assert_equal([operator == "+=" ? 4 : 3, [1, 2]], Compile.run_graph(graph, scope, [scope, Object].freeze))
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
      assert_equal(1, Compile.run_graph(graph, scope, [scope, Object].freeze))
      refute scope.const_defined?(:A, false)

      outer = Module.new { const_set(:A, 3) }
      inner = Module.new
      assert_equal(3, Compile.run_graph(graph, inner, [inner, outer, Object].freeze))
      refute inner.const_defined?(:A, false)

      scope = Module.new { const_set(:A, 4); private_constant :A }
      assert_equal(4, Compile.run_graph(graph, scope, [scope, Object].freeze))
      graph = compile_unit("self::A ||= 2").graphs[0]
      capture_warnings { assert_equal(2, Compile.run_graph(graph, scope, [scope, Object].freeze)) }
      ["&&=", "+="].each do |operator|
        graph = compile_unit("self::A #{operator} 2").graphs[0]
        assert_raise(NameError) { Compile.run_graph(graph, scope, [scope, Object].freeze) }
      end

      ["&&=", "||=", "+="].each do |operator|
        assert_run_raises(TypeError, "1.itself::A #{operator} 2")
      end
    end

    def test_constant_or_write_does_not_call_const_missing
      scope = Module.new
      def scope.const_missing(name) = raise("const_missing called")
      graph = compile_unit("self::A ||= 2").graphs[0]
      assert_equal(2, Compile.run_graph(graph, scope, [scope, Object].freeze))
      graph = compile_unit("B ||= 3").graphs[0]
      assert_equal(3, Compile.run_graph(graph, scope, [scope, Object].freeze))
    end

    def test_constant_compound_write_const_missing
      scope = Module.new
      def scope.const_missing(name) = 4
      ["A &&= 2", "self::B += 3"].zip([2, 7]) do |source, expected|
        graph = compile_unit(source).graphs[0]
        assert_equal(expected, Compile.run_graph(graph, scope, [scope, Object].freeze))
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
        assert_equal(3, Compile.run_graph(graph, scope, [scope, Object].freeze))
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
      assert_equal(1, Prism::Compile.run_graph(graph, klass, [klass.singleton_class, klass, Object].freeze))

      error = assert_raise(RuntimeError) { Prism::Compile.run_graph(graph, klass, [klass.singleton_class, Object].freeze) }
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

      Prism::Compile.run_unit(compile_unit("$compile_test_or_silent ||= 1"))
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
      assert_equal 3, Compile.run_unit(result.value)
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

      value = Compile.run_unit(unit)
      assert_equal "c", value
      refute_predicate value, :frozen?
    end

    def test_compile_file
      Tempfile.create(["test_compile_file", ".rb"]) do |file|
        file.write("1 + 2")
        file.flush

        assert_equal 3, Compile.run_unit(Prism.compile_file(file.path).value)
        assert_equal 3, Compile.run_unit(Prism.compile_file(Pathname.new(file.path)).value)
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

    def compile_unit(source)
      Prism.compile(source, raise_error: :plain).value
    end

    def assert_run(expected, source)
      assert_equal(expected, Prism::Compile.run_unit(compile_unit(source)))
    end

    def assert_run_raises(error, source, message = nil)
      if message
        assert_raise_with_message(error, message) { Prism::Compile.run_unit(compile_unit(source)) }
      else
        assert_raise(error) { Prism::Compile.run_unit(compile_unit(source)) }
      end
    end
  end
end
