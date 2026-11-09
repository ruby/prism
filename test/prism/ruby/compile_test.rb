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
        [1, "@@a = 1; @@a"],
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
        assert_equal(expected, Prism::Compile.run_unit(Prism.compile(source)))
      end
    end

    PRIVATE_CONSTANT = 1
    private_constant :PRIVATE_CONSTANT

    def test_const_get_recv_rel
      assert_raise(NameError) { Prism::Compile.run_unit(Prism.compile("String::Integer")) }
      assert_raise(NameError) { Prism::Compile.run_unit(Prism.compile("Prism::CompileTest::PRIVATE_CONSTANT")) }
      assert_raise(TypeError) { Prism::Compile.run_unit(Prism.compile("Float::INFINITY::Foo")) }
      assert_raise(NameError) { Prism::Compile.run_unit(Prism.compile("::String::Integer")) }
      assert_raise(NameError) { Prism::Compile.run_unit(Prism.compile("::Prism::CompileTest::PRIVATE_CONSTANT")) }
      assert_raise(NameError) { Prism::Compile.run_unit(Prism.compile("String.itself::Integer")) }
      assert_raise(NameError) { Prism::Compile.run_unit(Prism.compile("Prism::CompileTest.itself::PRIVATE_CONSTANT")) }
      assert_raise(TypeError) { Prism::Compile.run_unit(Prism.compile("1.itself::Foo")) }
    end
  end
end
