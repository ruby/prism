# frozen_string_literal: true

require_relative "test_helper"
require "strscan"

module Prism
  class CommentsTest < TestCase
    def test_AliasMethod_1
      source = <<~'RUBY'
        alias a #0
          #1
          #2
          b #3
      RUBY

      assert_comments(source, [
        ".statements.body[0].new_name.comments.trailing_comment",
        ".statements.body[0].comments.gap_comments[0]",
        ".statements.body[0].comments.gap_comments[1]",
        ".statements.body[0].old_name.comments.trailing_comment",
      ])
    end

    def test_AliasMethod_2
      assert_comments("alias a b #0", [".statements.body[0].old_name.comments.trailing_comment"])
    end

    def test_AliasMethod_3
      source = <<~'RUBY'
        alias a #0
          b #1
      RUBY

      assert_comments(source, [
        ".statements.body[0].new_name.comments.trailing_comment",
        ".statements.body[0].old_name.comments.trailing_comment",
      ])
    end

    def test_AlternationPattern_1
      assert_comments("1 => 2 | 3 #0", [".statements.body[0].pattern.right.comments.trailing_comment"])
    end

    def test_AlternationPattern_2
      source = <<~'RUBY'
        1 => 2 | #0
          3 #1
      RUBY

      assert_comments(source, [
        ".statements.body[0].pattern.comments.operator_comment",
        ".statements.body[0].pattern.right.comments.trailing_comment",
      ])
    end

    def test_AlternationPattern_3
      source = <<~'RUBY'
        1 => 2 | #0
          #1
          #2
          3 #3
      RUBY

      assert_comments(source, [
        ".statements.body[0].pattern.comments.operator_comment",
        ".statements.body[0].pattern.comments.gap_comments[0]",
        ".statements.body[0].pattern.comments.gap_comments[1]",
        ".statements.body[0].pattern.right.comments.trailing_comment",
      ])
    end

    def test_MatchRequired_1
      assert_comments("1 => 2 #0", [".statements.body[0].pattern.comments.trailing_comment"])
    end

    def test_MatchRequired_2
      source = <<~'RUBY'
        1 => #0
          2 #1
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.operator_comment",
        ".statements.body[0].pattern.comments.trailing_comment",
      ])
    end

    def test_MatchRequired_3
      source = <<~'RUBY'
        1 => #0
          #1
          #2
          2 #3
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.operator_comment",
        ".statements.body[0].comments.gap_comments[0]",
        ".statements.body[0].comments.gap_comments[1]",
        ".statements.body[0].pattern.comments.trailing_comment",
      ])
    end

    def test_MatchPredicate_1
      assert_comments("1 in 2 #0", [".statements.body[0].pattern.comments.trailing_comment"])
    end

    def test_MatchPredicate_2
      source = <<~'RUBY'
        1 in #0
          2 #1
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.operator_comment",
        ".statements.body[0].pattern.comments.trailing_comment",
      ])
    end

    def test_MatchPredicate_3
      source = <<~'RUBY'
        1 in #0
          #1
          #2
          2 #3
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.operator_comment",
        ".statements.body[0].comments.gap_comments[0]",
        ".statements.body[0].comments.gap_comments[1]",
        ".statements.body[0].pattern.comments.trailing_comment",
      ])
    end

    def test_And_1
      source = <<~'RUBY'
        1 #0
        #1
        #2
        and #3
        #4
        #5
        2 #6
      RUBY

      assert_comments(source, [
        ".statements.body[0].left.comments.trailing_comment",
        ".statements.body[0].comments.left_gap_comments[0]",
        ".statements.body[0].comments.left_gap_comments[1]",
        ".statements.body[0].comments.operator_comment",
        ".statements.body[0].comments.right_gap_comments[0]",
        ".statements.body[0].comments.right_gap_comments[1]",
        ".statements.body[0].right.comments.trailing_comment",
      ])
    end

    def test_And_2
      source = <<~'RUBY'
        1 && #0
          #1
          #2
          2 #3
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.operator_comment",
        ".statements.body[0].comments.gap_comments[0]",
        ".statements.body[0].comments.gap_comments[1]",
        ".statements.body[0].right.comments.trailing_comment",
      ])
    end

    def test_Or_1
      source = <<~'RUBY'
        1 #0
        #1
        #2
        or #3
        #4
        #5
        2 #6
      RUBY

      assert_comments(source, [
        ".statements.body[0].left.comments.trailing_comment",
        ".statements.body[0].comments.left_gap_comments[0]",
        ".statements.body[0].comments.left_gap_comments[1]",
        ".statements.body[0].comments.operator_comment",
        ".statements.body[0].comments.right_gap_comments[0]",
        ".statements.body[0].comments.right_gap_comments[1]",
        ".statements.body[0].right.comments.trailing_comment",
      ])
    end

    def test_Or_2
      source = <<~'RUBY'
        1 || #0
          #1
          #2
          2 #3
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.operator_comment",
        ".statements.body[0].comments.gap_comments[0]",
        ".statements.body[0].comments.gap_comments[1]",
        ".statements.body[0].right.comments.trailing_comment",
      ])
    end

    def test_BackReferenceRead_1
      assert_comments("$' #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_BlockArgument_1
      source = <<~'RUBY'
        a(
          & #0
            #1
            b #2
        )
      RUBY

      assert_comments(source, [
        ".statements.body[0].block.comments.operator_comment",
        ".statements.body[0].block.comments.gap_comments[0]",
        ".statements.body[0].block.expression.comments.trailing_comment",
      ])
    end

    def test_Case_1
      source = <<~'RUBY'
        case 1
        when 2
          3 #0
        end #1
      RUBY

      assert_comments(source, [
        ".statements.body[0].conditions[0].statements.body[0].comments.trailing_comment",
        ".statements.body[0].comments.end_comment",
      ])
    end

    def test_Case_2
      source = <<~'RUBY'
        case 1
        when 2
          #0
        end
      RUBY

      assert_comments(source, [".statements.body[0].conditions[0].comments.body_comments[0]"])
    end

    def test_Case_3
      source = <<~'RUBY'
        case 1
        when 2
          #0
          3 #1
          #2
        when 4
          #3
        end
      RUBY

      assert_comments(source, [
        ".statements.body[0].conditions[0].comments.body_comments[0]",
        ".statements.body[0].conditions[0].statements.body[0].comments.trailing_comment",
        ".statements.body[0].conditions[0].comments.body_comments[1]",
        ".statements.body[0].conditions[1].comments.body_comments[0]",
      ])
    end

    def test_When_1
      source = <<~'RUBY'
        case 1
        when #0
          #1
          2
          3
        end
      RUBY

      assert_comments(source, [
        ".statements.body[0].conditions[0].comments.body_comments[0]",
        ".statements.body[0].conditions[0].comments.body_comments[1]",
      ])
    end

    def test_When_2
      source = <<~'RUBY'
        case 1
        when #0
          2, #1
          #2
          3
          #3
          4
        end
      RUBY

      assert_comments(source, [
        ".statements.body[0].conditions[0].comments.body_comments[0]",
        ".statements.body[0].conditions[0].conditions[0].comments.trailing_comment",
        ".statements.body[0].conditions[0].comments.body_comments[1]",
        ".statements.body[0].conditions[0].comments.body_comments[2]",
      ])
    end

    def test_CaseMatch_1
      source = <<~'RUBY'
        case 1
        in 2
          3 #0
        end #1
      RUBY

      assert_comments(source, [
        ".statements.body[0].conditions[0].statements.body[0].comments.trailing_comment",
        ".statements.body[0].comments.end_comment",
      ])
    end

    def test_CaseMatch_2
      source = <<~'RUBY'
        case 1
        in 2
          #0
        end
      RUBY

      assert_comments(source, [".statements.body[0].conditions[0].comments.body_comments[0]"])
    end

    def test_CaseMatch_3
      source = <<~'RUBY'
        case 1
        in 2
          #0
          3 #1
          #2
        in 4
          #3
        end
      RUBY

      assert_comments(source, [
        ".statements.body[0].conditions[0].comments.body_comments[0]",
        ".statements.body[0].conditions[0].statements.body[0].comments.trailing_comment",
        ".statements.body[0].conditions[0].comments.body_comments[1]",
        ".statements.body[0].conditions[1].comments.body_comments[0]",
      ])
    end

    def test_Arguments_1
      assert_comments("break 1 #0", [".statements.body[0].arguments.arguments[0].comments.trailing_comment"])
    end

    def test_Break_1
      assert_comments("break #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_ConstantRead_1
      source = <<~'RUBY'
        class Foo #0
          #1
          1 #2
        end #3
      RUBY

      assert_comments(source, [
        ".statements.body[0].constant_path.comments.trailing_comment",
        ".statements.body[0].comments.body_comments[0]",
        ".statements.body[0].body.body[0].comments.trailing_comment",
        ".statements.body[0].comments.end_comment",
      ])
    end

    def test_ConstantRead_2
      source = <<~'RUBY'
        class Foo < Bar #0
          #1
        end
      RUBY

      assert_comments(source, [
        ".statements.body[0].superclass.comments.trailing_comment",
        ".statements.body[0].comments.body_comments[0]",
      ])
    end

    def test_Class_1
      source = <<~'RUBY'
        class #0
          Foo
          #1
        end
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.opening_comment",
        ".statements.body[0].comments.body_comments[0]",
      ])
    end

    def test_Self_1
      source = <<~'RUBY'
        class << self #0
          #1
        end #2
      RUBY

      assert_comments(source, [
        ".statements.body[0].expression.comments.trailing_comment",
        ".statements.body[0].comments.body_comments[0]",
        ".statements.body[0].comments.end_comment",
      ])
    end

    def test_SingletonClass_1
      source = <<~'RUBY'
        class << #0
          self
          #1
        end
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.opening_comment",
        ".statements.body[0].comments.body_comments[0]",
      ])
    end

    def test_ConstantRead_3
      source = <<~'RUBY'
        module Foo #0
        end
      RUBY

      assert_comments(source, [".statements.body[0].constant_path.comments.trailing_comment"])
    end

    def test_Module_1
      source = <<~'RUBY'
        module Foo
          #0
          1 #1
        end #2
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.body_comments[0]",
        ".statements.body[0].body.body[0].comments.trailing_comment",
        ".statements.body[0].comments.end_comment",
      ])
    end

    def test_Module_2
      source = <<~'RUBY'
        module Foo
          #0
        end
      RUBY

      assert_comments(source, [".statements.body[0].comments.body_comments[0]"])
    end

    def test_Module_3
      source = <<~'RUBY'
        module #0
          Foo
        end
      RUBY

      assert_comments(source, [".statements.body[0].comments.opening_comment"])
    end

    def test_Module_4
      source = <<~'RUBY'
        module #0
          Foo
          #1
          1
        end
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.opening_comment",
        ".statements.body[0].comments.body_comments[0]",
      ])
    end

    def test_ConstantPath_1
      source = <<~'RUBY'
        module Foo::Bar #0
          #1
        end
      RUBY

      assert_comments(source, [
        ".statements.body[0].constant_path.comments.trailing_comment",
        ".statements.body[0].comments.body_comments[0]",
      ])
    end

    def test_ConstantPath_2
      source = <<~'RUBY'
        module Foo:: #0
          Bar
          #1
        end
      RUBY

      assert_comments(source, [
        ".statements.body[0].constant_path.comments.operator_comment",
        ".statements.body[0].comments.body_comments[0]",
      ])
    end

    def test_Arguments_2
      assert_comments("next 1 #0", [".statements.body[0].arguments.arguments[0].comments.trailing_comment"])
    end

    def test_Next_1
      assert_comments("next #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_CapturePattern_1
      source = <<~'RUBY'
        1 in 2 => #0
          a
      RUBY

      assert_comments(source, [".statements.body[0].pattern.comments.operator_comment"])
    end

    def test_CapturePattern_2
      source = <<~'RUBY'
        1 in 2 => #0
          #1
          #2
          a
      RUBY

      assert_comments(source, [
        ".statements.body[0].pattern.comments.operator_comment",
        ".statements.body[0].pattern.comments.gap_comments[0]",
        ".statements.body[0].pattern.comments.gap_comments[1]",
      ])
    end

    def test_ClassVariableRead_1
      assert_comments("@@a #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_ClassVariableTarget_1
      source = <<~'RUBY'
        @@a, #0
        @@b = 1, 2
      RUBY

      assert_comments(source, [".statements.body[0].lefts[0].comments.trailing_comment"])
    end

    def test_ClassVariableWrite_1
      assert_comments("@@a = 1 #0", [".statements.body[0].value.comments.trailing_comment"])
    end

    def test_ClassVariableWrite_2
      source = <<~'RUBY'
        @@a = #0
          #1
          1 #2
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.operator_comment",
        ".statements.body[0].comments.gap_comments[0]",
        ".statements.body[0].value.comments.trailing_comment",
      ])
    end

    def test_ClassVariableAndWrite_1
      assert_comments("@@a &&= 1 #0", [".statements.body[0].value.comments.trailing_comment"])
    end

    def test_ClassVariableAndWrite_2
      source = <<~'RUBY'
        @@a &&= #0
          1 #1
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.operator_comment",
        ".statements.body[0].value.comments.trailing_comment",
      ])
    end

    def test_ClassVariableOperatorWrite_1
      assert_comments("@@a += 1 #0", [".statements.body[0].value.comments.trailing_comment"])
    end

    def test_ClassVariableOperatorWrite_2
      source = <<~'RUBY'
        @@a += #0
          1 #1
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.operator_comment",
        ".statements.body[0].value.comments.trailing_comment",
      ])
    end

    def test_ClassVariableOrWrite_1
      assert_comments("@@a ||= 1 #0", [".statements.body[0].value.comments.trailing_comment"])
    end

    def test_ConstantRead_4
      assert_comments("A #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_ConstantTarget_1
      source = <<~'RUBY'
        A, #0
        B = 1, 2
      RUBY

      assert_comments(source, [".statements.body[0].lefts[0].comments.trailing_comment"])
    end

    def test_ConstantPath_3
      assert_comments("A::B #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_ConstantPath_4
      source = <<~'RUBY'
        A:: #0
          B
      RUBY

      assert_comments(source, [".statements.body[0].comments.operator_comment"])
    end

    def test_ConstantPath_5
      assert_comments("::Foo #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_ConstantPath_6
      source = <<~'RUBY'
        :: #0
          Foo
      RUBY

      assert_comments(source, [".statements.body[0].comments.operator_comment"])
    end

    def test_ConstantPathTarget_1
      source = <<~'RUBY'
        A::B, #0
        c = 1, 2
      RUBY

      assert_comments(source, [".statements.body[0].lefts[0].comments.trailing_comment"])
    end

    def test_ConstantWrite_1
      assert_comments("A = 1 #0", [".statements.body[0].value.comments.trailing_comment"])
    end

    def test_ConstantWrite_2
      source = <<~'RUBY'
        A = #0
          #1
          1 #2
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.operator_comment",
        ".statements.body[0].comments.gap_comments[0]",
        ".statements.body[0].value.comments.trailing_comment",
      ])
    end

    def test_ConstantAndWrite_1
      assert_comments("A &&= 1 #0", [".statements.body[0].value.comments.trailing_comment"])
    end

    def test_ConstantOperatorWrite_1
      assert_comments("A += 1 #0", [".statements.body[0].value.comments.trailing_comment"])
    end

    def test_ConstantOrWrite_1
      assert_comments("A ||= 1 #0", [".statements.body[0].value.comments.trailing_comment"])
    end

    def test_ConstantPathWrite_1
      assert_comments("A::B = 1 #0", [".statements.body[0].value.comments.trailing_comment"])
    end

    def test_ConstantPathWrite_2
      source = <<~'RUBY'
        A::B = #0
          #1
          1 #2
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.operator_comment",
        ".statements.body[0].comments.gap_comments[0]",
        ".statements.body[0].value.comments.trailing_comment",
      ])
    end

    def test_ConstantPathAndWrite_1
      assert_comments("A::B &&= 1 #0", [".statements.body[0].value.comments.trailing_comment"])
    end

    def test_ConstantPathOperatorWrite_1
      assert_comments("A::B += 1 #0", [".statements.body[0].value.comments.trailing_comment"])
    end

    def test_ConstantPathOrWrite_1
      assert_comments("A::B ||= 1 #0", [".statements.body[0].value.comments.trailing_comment"])
    end

    def test_False_1
      assert_comments("false #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_Float_1
      assert_comments("1.0 #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_GlobalVariableRead_1
      assert_comments("$a #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_Arguments_3
      source = <<~'RUBY'
        def a(...)
          b(... #0
          )
        end
      RUBY

      assert_comments(source, [".statements.body[0].body.body[0].arguments.arguments[0].comments.trailing_comment"])
    end

    def test_ForwardingParameter_1
      source = <<~'RUBY'
        def a(... #0
        )
        end
      RUBY

      assert_comments(source, [".statements.body[0].parameters.keyword_rest.comments.trailing_comment"])
    end

    def test_GlobalVariableTarget_1
      source = <<~'RUBY'
        $a, #0
        $b = 1, 2
      RUBY

      assert_comments(source, [".statements.body[0].lefts[0].comments.trailing_comment"])
    end

    def test_GlobalVariableWrite_1
      assert_comments("$a = 1 #0", [".statements.body[0].value.comments.trailing_comment"])
    end

    def test_GlobalVariableWrite_2
      source = <<~'RUBY'
        $a = #0
          #1
          1 #2
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.operator_comment",
        ".statements.body[0].comments.gap_comments[0]",
        ".statements.body[0].value.comments.trailing_comment",
      ])
    end

    def test_GlobalVariableAndWrite_1
      assert_comments("$a &&= 1 #0", [".statements.body[0].value.comments.trailing_comment"])
    end

    def test_GlobalVariableOperatorWrite_1
      assert_comments("$a += 1 #0", [".statements.body[0].value.comments.trailing_comment"])
    end

    def test_GlobalVariableOrWrite_1
      assert_comments("$a ||= 1 #0", [".statements.body[0].value.comments.trailing_comment"])
    end

    def test_InstanceVariableRead_1
      assert_comments("@a #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_InstanceVariableTarget_1
      source = <<~'RUBY'
        @a, #0
        @b = 1, 2
      RUBY

      assert_comments(source, [".statements.body[0].lefts[0].comments.trailing_comment"])
    end

    def test_InstanceVariableWrite_1
      assert_comments("@a = 1 #0", [".statements.body[0].value.comments.trailing_comment"])
    end

    def test_InstanceVariableWrite_2
      source = <<~'RUBY'
        @a = #0
          #1
          1 #2
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.operator_comment",
        ".statements.body[0].comments.gap_comments[0]",
        ".statements.body[0].value.comments.trailing_comment",
      ])
    end

    def test_InstanceVariableAndWrite_1
      assert_comments("@a &&= 1 #0", [".statements.body[0].value.comments.trailing_comment"])
    end

    def test_InstanceVariableOperatorWrite_1
      assert_comments("@a += 1 #0", [".statements.body[0].value.comments.trailing_comment"])
    end

    def test_InstanceVariableOrWrite_1
      assert_comments("@a ||= 1 #0", [".statements.body[0].value.comments.trailing_comment"])
    end

    def test_EmbeddedStatements_1
      source = <<~'RUBY'
        "foo #{ #0
          1
        } bar"
      RUBY

      assert_comments(source, [".statements.body[0].parts[1].comments.opening_comment"])
    end

    def test_InterpolatedString_1
      source = <<~'RUBY'
        "foo #{
          #0
          1
        } bar"
      RUBY

      assert_comments(source, [".statements.body[0].parts[1].comments.body_comments[0]"])
    end

    def test_InterpolatedString_2
      assert_comments("\"foo \#{1} bar\" #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_InterpolatedString_3
      source = <<~'RUBY'
        "foo #{
          1 #0
        } bar" #1
      RUBY

      assert_comments(source, [
        ".statements.body[0].parts[1].statements.body[0].comments.trailing_comment",
        ".statements.body[0].comments.trailing_comment",
      ])
    end

    def test_InterpolatedString_4
      source = <<~'RUBY'
        "#{1} #{2 #0
        }" #1
      RUBY

      assert_comments(source, [
        ".statements.body[0].parts[2].statements.body[0].comments.trailing_comment",
        ".statements.body[0].comments.trailing_comment",
      ])
    end

    def test_InterpolatedRegularExpression_1
      assert_comments("/foo \#{1} bar/ #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_InterpolatedSymbol_1
      assert_comments(":\"foo \#{1} bar\" #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_InterpolatedXString_1
      assert_comments("`foo \#{1} bar` #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_Call_1
      source = <<~'RUBY'
        a { it #0
        }
      RUBY

      assert_comments(source, [".statements.body[0].block.body.body[0].comments.trailing_comment"])
    end

    def test_KeywordRestParameter_1
      source = <<~'RUBY'
        def a(** #0
          b
        )
        end
      RUBY

      assert_comments(source, [".statements.body[0].parameters.keyword_rest.comments.operator_comment"])
    end

    def test_KeywordRestParameter_2
      source = <<~'RUBY'
        def a(** #0
        )
        end
      RUBY

      assert_comments(source, [".statements.body[0].parameters.keyword_rest.comments.trailing_comment"])
    end

    def test_LocalVariableWrite_1
      source = <<~'RUBY'
        a = 1
        a #0
      RUBY

      assert_comments(source, [".statements.body[1].comments.trailing_comment"])
    end

    def test_LocalVariableTarget_1
      source = <<~'RUBY'
        a, #0
        b = 1, 2
      RUBY

      assert_comments(source, [".statements.body[0].lefts[0].comments.trailing_comment"])
    end

    def test_LocalVariableWrite_2
      assert_comments("a = 1 #0", [".statements.body[0].value.comments.trailing_comment"])
    end

    def test_LocalVariableWrite_3
      source = <<~'RUBY'
        a = #0
          #1
          1 #2
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.operator_comment",
        ".statements.body[0].comments.gap_comments[0]",
        ".statements.body[0].value.comments.trailing_comment",
      ])
    end

    def test_LocalVariableWrite_4
      source = <<~'RUBY'
        a = 1
        a &&= 2 #0
      RUBY

      assert_comments(source, [".statements.body[1].value.comments.trailing_comment"])
    end

    def test_LocalVariableWrite_5
      source = <<~'RUBY'
        a = 1
        a += 2 #0
      RUBY

      assert_comments(source, [".statements.body[1].value.comments.trailing_comment"])
    end

    def test_LocalVariableWrite_6
      source = <<~'RUBY'
        a = 1
        a ||= 2 #0
      RUBY

      assert_comments(source, [".statements.body[1].value.comments.trailing_comment"])
    end

    def test_Nil_1
      assert_comments("nil #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_NumberedReferenceRead_1
      assert_comments("$1 #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_MatchLastLine_1
      source = <<~'RUBY'
        if /foo/ #0
        end
      RUBY

      assert_comments(source, [".statements.body[0].predicate.comments.trailing_comment"])
    end

    def test_BlockParameter_1
      source = <<~'RUBY'
        def a(& #0
          b
        )
        end
      RUBY

      assert_comments(source, [".statements.body[0].parameters.block.comments.operator_comment"])
    end

    def test_BlockParameter_2
      source = <<~'RUBY'
        def a(& #0
        )
        end
      RUBY

      assert_comments(source, [".statements.body[0].parameters.block.comments.trailing_comment"])
    end

    def test_NoBlockParameter_1
      source = <<~'RUBY'
        def a(&nil #0
        )
        end
      RUBY

      assert_comments(source, [".statements.body[0].parameters.block.comments.trailing_comment"])
    end

    def test_NoKeywordsParameter_1
      source = <<~'RUBY'
        def a(**nil #0
        )
        end
      RUBY

      assert_comments(source, [".statements.body[0].parameters.keyword_rest.comments.trailing_comment"])
    end

    def test_Defined_1
      source = <<~'RUBY'
        defined? #0
          a
      RUBY

      assert_comments(source, [".statements.body[0].comments.operator_comment"])
    end

    def test_Defined_2
      source = <<~'RUBY'
        defined? #0
          #1
          a #2
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.operator_comment",
        ".statements.body[0].comments.gap_comments[0]",
        ".statements.body[0].value.comments.trailing_comment",
      ])
    end

    def test_Defined_3
      source = <<~'RUBY'
        defined?( #0
          a
        )
      RUBY

      assert_comments(source, [".statements.body[0].comments.opening_comment"])
    end

    def test_Defined_4
      source = <<~'RUBY'
        defined?( #0
          #1
          a #2
        )
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.opening_comment",
        ".statements.body[0].comments.opening_gap_comments[0]",
        ".statements.body[0].value.comments.trailing_comment",
      ])
    end

    def test_Call_2
      source = <<~'RUBY'
        defined?(
          a #0
          #1
        )
      RUBY

      assert_comments(source, [
        ".statements.body[0].value.comments.trailing_comment",
        ".statements.body[0].comments.closing_gap_comments[0]",
      ])
    end

    def test_Parentheses_1
      assert_comments("(1) #0", [".statements.body[0].comments.end_comment"])
    end

    def test_Parentheses_2
      source = <<~'RUBY'
        ( #0
          1
        )
      RUBY

      assert_comments(source, [".statements.body[0].comments.opening_comment"])
    end

    def test_Parentheses_3
      source = <<~'RUBY'
        (
          #0
          1 #1
        ) #2
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.body_comments[0]",
        ".statements.body[0].body.body[0].comments.trailing_comment",
        ".statements.body[0].comments.end_comment",
      ])
    end

    def test_PinnedExpression_1
      source = <<~'RUBY'
        1 in ^( #0
          a
        )
      RUBY

      assert_comments(source, [".statements.body[0].pattern.comments.opening_comment"])
    end

    def test_PinnedExpression_2
      source = <<~'RUBY'
        1 in ^( #0
          #1
          a #2
          #3
        )
      RUBY

      assert_comments(source, [
        ".statements.body[0].pattern.comments.opening_comment",
        ".statements.body[0].pattern.comments.opening_gap_comments[0]",
        ".statements.body[0].pattern.expression.comments.trailing_comment",
        ".statements.body[0].pattern.comments.closing_gap_comments[0]",
      ])
    end

    def test_PinnedVariable_1
      source = <<~'RUBY'
        1 in ^ #0
          @a
      RUBY

      assert_comments(source, [".statements.body[0].pattern.comments.operator_comment"])
    end

    def test_PinnedVariable_2
      source = <<~'RUBY'
        a = 1
        1 in ^ #0
          #1
          a
      RUBY

      assert_comments(source, [
        ".statements.body[1].pattern.comments.operator_comment",
        ".statements.body[1].pattern.comments.gap_comments[0]",
      ])
    end

    def test_ArrayPattern_1
      source = <<~'RUBY'
        1 in [
          #0
          2,
          *b,
          #1
          3
        ]
      RUBY

      assert_comments(source, [
        ".statements.body[0].pattern.comments.inner_comments[0]",
        ".statements.body[0].pattern.comments.inner_comments[1]",
      ])
    end

    def test_ArrayPattern_2
      source = <<~'RUBY'
        1 in [
          #0
          2
        ]
      RUBY

      assert_comments(source, [".statements.body[0].pattern.comments.inner_comments[0]"])
    end

    def test_FindPattern_1
      source = <<~'RUBY'
        1 in [
          *a,
          #0
          2, #1
          *b
        ]
      RUBY

      assert_comments(source, [
        ".statements.body[0].pattern.comments.inner_comments[0]",
        ".statements.body[0].pattern.requireds[0].comments.trailing_comment",
      ])
    end

    def test_FindPattern_2
      source = <<~'RUBY'
        1 in [
          *a,
          2,
          #0
          *b
        ]
      RUBY

      assert_comments(source, [".statements.body[0].pattern.comments.inner_comments[0]"])
    end

    def test_FindPattern_3
      source = <<~'RUBY'
        1 in Foo[ #0
          *a,
          2,
          *b
        ]
      RUBY

      assert_comments(source, [".statements.body[0].pattern.comments.opening_comment"])
    end

    def test_HashPattern_1
      source = <<~'RUBY'
        1 in {
          #0
          a: 2,
          #1
          **b
        }
      RUBY

      assert_comments(source, [
        ".statements.body[0].pattern.comments.inner_comments[0]",
        ".statements.body[0].pattern.comments.inner_comments[1]",
      ])
    end

    def test_HashPattern_2
      source = <<~'RUBY'
        1 in { #0
          a: 2
        } #1
      RUBY

      assert_comments(source, [
        ".statements.body[0].pattern.comments.opening_comment",
        ".statements.body[0].pattern.comments.closing_comment",
      ])
    end

    def test_Imaginary_1
      assert_comments("1i #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_Range_1
      assert_comments("1..2 #0", [".statements.body[0].right.comments.trailing_comment"])
    end

    def test_Range_2
      assert_comments("1.. #0", [".statements.body[0].comments.operator_comment"])
    end

    def test_Range_3
      assert_comments("..2 #0", [".statements.body[0].right.comments.trailing_comment"])
    end

    def test_Range_4
      source = <<~'RUBY'
        1 .. #0
          #1
          2 #2
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.operator_comment",
        ".statements.body[0].comments.gap_comments[0]",
        ".statements.body[0].right.comments.trailing_comment",
      ])
    end

    def test_Rational_1
      assert_comments("1r #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_Call_3
      source = <<~'RUBY'
        loop do
          redo #0
        end
      RUBY

      assert_comments(source, [".statements.body[0].block.body.body[0].comments.trailing_comment"])
    end

    def test_PostExecution_1
      source = <<~'RUBY'
        END { #0
          1
        }
      RUBY

      assert_comments(source, [".statements.body[0].comments.opening_comment"])
    end

    def test_PostExecution_2
      assert_comments("END { 1 } #0", [".statements.body[0].comments.end_comment"])
    end

    def test_PostExecution_3
      source = <<~'RUBY'
        END {
          #0
          1 #1
        } #2
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.body_comments[0]",
        ".statements.body[0].statements.body[0].comments.trailing_comment",
        ".statements.body[0].comments.end_comment",
      ])
    end

    def test_PreExecution_1
      assert_comments("BEGIN { 1 } #0", [".statements.body[0].comments.end_comment"])
    end

    def test_PreExecution_2
      source = <<~'RUBY'
        BEGIN {
          #0
          1 #1
        } #2
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.body_comments[0]",
        ".statements.body[0].statements.body[0].comments.trailing_comment",
        ".statements.body[0].comments.end_comment",
      ])
    end

    def test_RegularExpression_1
      assert_comments("/foo/ #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_RegularExpression_2
      source = <<~'RUBY'
        /foo
        bar/ #0
      RUBY

      assert_comments(source, [".statements.body[0].comments.trailing_comment"])
    end

    def test_RequiredKeywordParameter_1
      source = <<~'RUBY'
        def a(b: #0
        )
        end
      RUBY

      assert_comments(source, [".statements.body[0].parameters.keywords[0].comments.trailing_comment"])
    end

    def test_OptionalKeywordParameter_1
      source = <<~'RUBY'
        def a(b: #0
          1
        )
        end
      RUBY

      assert_comments(source, [".statements.body[0].parameters.keywords[0].comments.operator_comment"])
    end

    def test_OptionalKeywordParameter_2
      source = <<~'RUBY'
        def a(b: #0
          #1
          1 #2
        )
        end
      RUBY

      assert_comments(source, [
        ".statements.body[0].parameters.keywords[0].comments.operator_comment",
        ".statements.body[0].parameters.keywords[0].comments.gap_comments[0]",
        ".statements.body[0].parameters.keywords[0].value.comments.trailing_comment",
      ])
    end

    def test_Parameters_1
      source = <<~'RUBY'
        def a(b #0
        )
        end
      RUBY

      assert_comments(source, [".statements.body[0].parameters.requireds[0].comments.trailing_comment"])
    end

    def test_OptionalParameter_1
      source = <<~'RUBY'
        def a(b = #0
          1
        )
        end
      RUBY

      assert_comments(source, [".statements.body[0].parameters.optionals[0].comments.operator_comment"])
    end

    def test_OptionalParameter_2
      source = <<~'RUBY'
        def a(b = #0
          #1
          1 #2
        )
        end
      RUBY

      assert_comments(source, [
        ".statements.body[0].parameters.optionals[0].comments.operator_comment",
        ".statements.body[0].parameters.optionals[0].comments.gap_comments[0]",
        ".statements.body[0].parameters.optionals[0].value.comments.trailing_comment",
      ])
    end

    def test_RestParameter_1
      source = <<~'RUBY'
        def a(* #0
          b
        )
        end
      RUBY

      assert_comments(source, [".statements.body[0].parameters.rest.comments.operator_comment"])
    end

    def test_RestParameter_2
      source = <<~'RUBY'
        def a(* #0
        )
        end
      RUBY

      assert_comments(source, [".statements.body[0].parameters.rest.comments.trailing_comment"])
    end

    def test_Begin_1
      source = <<~'RUBY'
        begin
        rescue
          retry #0
        end
      RUBY

      assert_comments(source, [".statements.body[0].rescue_clause.statements.body[0].comments.trailing_comment"])
    end

    def test_RescueModifier_1
      assert_comments("1 rescue 2 #0", [".statements.body[0].rescue_expression.comments.trailing_comment"])
    end

    def test_RescueModifier_2
      source = <<~'RUBY'
        1 rescue #0
          #1
          #2
          2 #3
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.operator_comment",
        ".statements.body[0].comments.gap_comments[0]",
        ".statements.body[0].comments.gap_comments[1]",
        ".statements.body[0].rescue_expression.comments.trailing_comment",
      ])
    end

    def test_RegularExpression_3
      source = <<~'RUBY'
        /foo
        bar/ #0
      RUBY

      assert_comments(source, [".statements.body[0].comments.trailing_comment"])
    end

    def test_Arguments_4
      source = <<~'RUBY'
        a(
          * #0
            #1
            b #2
        )
      RUBY

      assert_comments(source, [
        ".statements.body[0].arguments.arguments[0].comments.operator_comment",
        ".statements.body[0].arguments.arguments[0].comments.gap_comments[0]",
        ".statements.body[0].arguments.arguments[0].expression.comments.trailing_comment",
      ])
    end

    def test_Self_2
      assert_comments("self #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_SourceEncoding_1
      assert_comments("__ENCODING__ #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_SourceFile_1
      assert_comments("__FILE__ #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_SourceLine_1
      assert_comments("__LINE__ #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_String_1
      assert_comments("\"foo\" #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_String_2
      source = <<~'RUBY'
        <<~HEREDOC #0
          foo
        HEREDOC
      RUBY

      assert_comments(source, [".statements.body[0].comments.trailing_comment"])
    end

    def test_True_1
      assert_comments("true #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_XString_1
      assert_comments("`foo` #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_XString_2
      source = <<~'RUBY'
        <<~`HEREDOC` #0
          foo
        HEREDOC
      RUBY

      assert_comments(source, [".statements.body[0].comments.trailing_comment"])
    end

    def test_Def_1
      source = <<~'RUBY'
        def foo #0
          #1
          1
        end #2
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.opening_comment",
        ".statements.body[0].comments.body_comments[0]",
        ".statements.body[0].comments.end_comment",
      ])
    end

    def test_Parameters_2
      source = <<~'RUBY'
        def foo(a #0
        )
          #1
        end
      RUBY

      assert_comments(source, [
        ".statements.body[0].parameters.requireds[0].comments.trailing_comment",
        ".statements.body[0].comments.body_comments[0]",
      ])
    end

    def test_Def_2
      source = <<~'RUBY'
        def foo = #0
          1
      RUBY

      assert_comments(source, [".statements.body[0].comments.operator_comment"])
    end

    def test_True_2
      source = <<~'RUBY'
        if true #0
          #1
          1
        end #2
      RUBY

      assert_comments(source, [
        ".statements.body[0].predicate.comments.trailing_comment",
        ".statements.body[0].comments.body_comments[0]",
        ".statements.body[0].comments.end_comment",
      ])
    end

    def test_True_3
      source = <<~'RUBY'
        unless true #0
          #1
          1
        end #2
      RUBY

      assert_comments(source, [
        ".statements.body[0].predicate.comments.trailing_comment",
        ".statements.body[0].comments.body_comments[0]",
        ".statements.body[0].comments.end_comment",
      ])
    end

    def test_True_4
      source = <<~'RUBY'
        while true #0
          #1
          1
        end #2
      RUBY

      assert_comments(source, [
        ".statements.body[0].predicate.comments.trailing_comment",
        ".statements.body[0].comments.body_comments[0]",
        ".statements.body[0].comments.end_comment",
      ])
    end

    def test_True_5
      source = <<~'RUBY'
        until true #0
          #1
          1
        end #2
      RUBY

      assert_comments(source, [
        ".statements.body[0].predicate.comments.trailing_comment",
        ".statements.body[0].comments.body_comments[0]",
        ".statements.body[0].comments.end_comment",
      ])
    end

    def test_Call_4
      source = <<~'RUBY'
        for i in list #0
          #1
          1
        end #2
      RUBY

      assert_comments(source, [
        ".statements.body[0].collection.comments.trailing_comment",
        ".statements.body[0].comments.body_comments[0]",
        ".statements.body[0].comments.end_comment",
      ])
    end

    def test_Arguments_5
      assert_comments("return 1 #0", [".statements.body[0].arguments.arguments[0].comments.trailing_comment"])
    end

    def test_Call_5
      source = <<~'RUBY'
        foo. #0
          bar
      RUBY

      assert_comments(source, [".statements.body[0].comments.operator_comment"])
    end

    def test_Call_6
      assert_comments("foo.bar #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_Return_1
      assert_comments("return #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_Yield_1
      assert_comments("yield #0", [".statements.body[0].comments.trailing_comment"])
    end

    def test_Lambda_1
      source = <<~'RUBY'
        -> { #0
          #1
          1
        } #2
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.opening_comment",
        ".statements.body[0].comments.body_comments[0]",
        ".statements.body[0].comments.end_comment",
      ])
    end

    def test_Hash_1
      source = <<~'RUBY'
        {
          #0
          a: 1
        } #1
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.inner_comments[0]",
        ".statements.body[0].comments.closing_comment",
      ])
    end

    def test_MultiWrite_1
      source = <<~'RUBY'
        a,
        *b,
        c = #0
          1
      RUBY

      assert_comments(source, [".statements.body[0].comments.operator_comment"])
    end

    def test_Hash_2
      source = <<~'RUBY'
        { a => #0
          #1
          b #2
        }
      RUBY

      assert_comments(source, [
        ".statements.body[0].elements[0].comments.operator_comment",
        ".statements.body[0].elements[0].comments.gap_comments[0]",
        ".statements.body[0].elements[0].value.comments.trailing_comment",
      ])
    end

    def test_Hash_3
      source = <<~'RUBY'
        { ** #0
          #1
          a }
      RUBY

      assert_comments(source, [
        ".statements.body[0].elements[0].comments.operator_comment",
        ".statements.body[0].elements[0].comments.gap_comments[0]",
      ])
    end

    def test_Begin_2
      source = <<~'RUBY'
        begin #0
          #1
          1
        rescue #2
          #3
          2
        ensure #4
          #5
          3
        end #6
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.opening_comment",
        ".statements.body[0].comments.body_comments[0]",
        ".statements.body[0].rescue_clause.comments.opening_comment",
        ".statements.body[0].rescue_clause.comments.body_comments[0]",
        ".statements.body[0].ensure_clause.comments.opening_comment",
        ".statements.body[0].ensure_clause.comments.body_comments[0]",
        ".statements.body[0].comments.end_comment",
      ])
    end

    def test_Block_1
      source = <<~'RUBY'
        foo { #0
          #1
          1
        } #2
      RUBY

      assert_comments(source, [
        ".statements.body[0].block.comments.opening_comment",
        ".statements.body[0].block.comments.body_comments[0]",
        ".statements.body[0].block.comments.end_comment",
      ])
    end

    def test_Block_2
      source = <<~'RUBY'
        foo do #0
          #1
          1
        end #2
      RUBY

      assert_comments(source, [
        ".statements.body[0].block.comments.opening_comment",
        ".statements.body[0].block.comments.body_comments[0]",
        ".statements.body[0].block.comments.end_comment",
      ])
    end

    def test_Array_1
      source = <<~'RUBY'
        [1, #0
        2]
      RUBY

      assert_comments(source, [".statements.body[0].elements[0].comments.trailing_comment"])
    end

    def test_ArrayPattern_3
      source = <<~'RUBY'
        foo in [1, #0
        2]
      RUBY

      assert_comments(source, [".statements.body[0].pattern.requireds[0].comments.trailing_comment"])
    end

    def test_BlockParameters_1
      source = <<~'RUBY'
        foo { | #0
          a, b
        | #1
        }
      RUBY

      assert_comments(source, [
        ".statements.body[0].block.parameters.comments.opening_comment",
        ".statements.body[0].block.parameters.comments.closing_comment",
      ])
    end

    def test_BlockParameters_2
      source = <<~'RUBY'
        foo { |;
        #0
        #1
        a
        | }
      RUBY

      assert_comments(source, [
        ".statements.body[0].block.parameters.comments.inner_comments[0]",
        ".statements.body[0].block.parameters.comments.inner_comments[1]",
      ])
    end

    def test_OptionalParameter_3
      source = <<~'RUBY'
        foo { |a = #0
          1, b| }
      RUBY

      assert_comments(source, [".statements.body[0].block.parameters.parameters.optionals[0].comments.operator_comment"])
    end

    def test_Block_3
      source = <<~'RUBY'
        foo.bar do
          baz
        end #0
      RUBY

      assert_comments(source, [".statements.body[0].block.comments.end_comment"])
    end

    def test_Def_3
      source = <<~'RUBY'
        def foo(#0
          a
        ) = #1
          bar
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.lparen_comment",
        ".statements.body[0].comments.operator_comment",
      ])
    end

    def test_Def_4
      source = <<~'RUBY'
        def #0
        #1
        foo
        end
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.opening_comment",
        ".statements.body[0].comments.keyword_gap_comments[0]",
      ])
    end

    def test_LocalVariableTarget_2
      source = <<~'RUBY'
        foo in [*a, #0
        b, *c]
      RUBY

      assert_comments(source, [".statements.body[0].pattern.left.expression.comments.trailing_comment"])
    end

    def test_Hash_4
      source = <<~'RUBY'
        { a: #0
          1 }
      RUBY

      assert_comments(source, [".statements.body[0].elements[0].comments.operator_comment"])
    end

    def test_MatchPredicate_4
      source = <<~'RUBY'
        foo in {a: 1, #0
        b: 2}
      RUBY

      assert_comments(source, [".statements.body[0].pattern.elements[0].value.comments.trailing_comment"])
    end

    def test_Yield_2
      source = <<~'RUBY'
        yield(#0
          foo
        ) #1
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.lparen_comment",
        ".statements.body[0].comments.rparen_comment",
      ])
    end

    def test_Super_1
      source = <<~'RUBY'
        super(#0
          foo
        ) #1
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.lparen_comment",
        ".statements.body[0].comments.rparen_comment",
      ])
    end

    def test_CallOperatorWrite_1
      source = <<~'RUBY'
        foo.bar += #0
          1
      RUBY

      assert_comments(source, [".statements.body[0].comments.operator_comment"])
    end

    def test_CallOperatorWrite_2
      source = <<~'RUBY'
        foo. #0
          # comment
          bar += #1
          1
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.call_operator_comment",
        ".statements.body[0].comments.operator_comment",
      ])
    end

    def test_Case_4
      source = <<~'RUBY'
        case #0
          foo
          #1
        when bar
          baz
        end
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.opening_comment",
        ".statements.body[0].comments.predicate_gap_comments[0]",
      ])
    end

    def test_Call_7
      source = <<~'RUBY'
        foo
          # receiver gap
          . #0
          # message gap
          bar
      RUBY

      assert_comments(source, [".statements.body[0].comments.operator_comment"])
    end

    def test_Class_2
      source = <<~'RUBY'
        class #0
          # keyword gap
          Foo < #1
          # inheritance gap
          Bar
        end
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.opening_comment",
        ".statements.body[0].comments.inheritance_operator_comment",
      ])
    end

    def test_For_1
      source = <<~'RUBY'
        for a in b do #0
          c
        end
      RUBY

      assert_comments(source, [".statements.body[0].comments.do_comment"])
    end

    def test_For_2
      source = <<~'RUBY'
        for a in #0
          b
          c
        end
      RUBY

      assert_comments(source, [".statements.body[0].comments.in_comment"])
    end

    def test_FindPattern_4
      source = <<~'RUBY'
        foo in [#0
          *a,
          b,
          *c
          #1
        ]
      RUBY

      assert_comments(source, [
        ".statements.body[0].pattern.comments.opening_comment",
        ".statements.body[0].pattern.comments.post_right_gap_comments[0]",
      ])
    end

    def test_HashPattern_3
      source = <<~'RUBY'
        foo in {a:, **b
          #0
        } #1
      RUBY

      assert_comments(source, [
        ".statements.body[0].pattern.comments.post_rest_gap_comments[0]",
        ".statements.body[0].pattern.comments.closing_comment",
      ])
    end

    def test_CallAndWrite_1
      source = <<~'RUBY'
        foo. #0
          #1
          bar &&= #2
          #3
          1
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.call_operator_comment",
        ".statements.body[0].comments.call_gap_comments[0]",
        ".statements.body[0].comments.operator_comment",
        ".statements.body[0].comments.operator_gap_comments[0]",
      ])
    end

    def test_For_3
      source = <<~'RUBY'
        for #0
        a in b
          c
        end
      RUBY

      assert_comments(source, [".statements.body[0].comments.for_comment"])
    end

    def test_Call_8
      source = <<~'RUBY'
        foo
          #0
          . #1
          #2
          bar
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.receiver_gap_comments[0]",
        ".statements.body[0].comments.operator_comment",
        ".statements.body[0].comments.message_gap_comments[0]",
      ])
    end

    def test_FindPattern_5
      source = <<~'RUBY'
        foo in [
          #0
          *a, b, *c
        ] #1
      RUBY

      assert_comments(source, [
        ".statements.body[0].pattern.comments.pre_left_gap_comments[0]",
        ".statements.body[0].pattern.comments.closing_comment",
      ])
    end

    def test_Class_3
      source = <<~'RUBY'
        class #0
          #1
          Foo < #2
          #3
          Bar
        end
      RUBY

      assert_comments(source, [
        ".statements.body[0].comments.opening_comment",
        ".statements.body[0].comments.keyword_gap_comments[0]",
        ".statements.body[0].comments.inheritance_operator_comment",
        ".statements.body[0].comments.inheritance_gap_comments[0]",
      ])
    end

    private

    def assert_comments(source, paths)
      result = Prism.parse(source, partial_script: true, attach_comments: true)
      assert(!result.failure?, "Parse error: #{result.errors.first&.message}")

      root = result.value

      paths.each_with_index do |path, index|
        scanner = StringScanner.new(path)
        node = root

        until scanner.eos?
          case
          when scanner.scan(/\.(\w+)/)
            node = node.public_send(scanner[1])
          when scanner.scan(/\[(\d+)\]/)
            node = node[Integer(scanner[1])]
          else
            flunk("Unexpected path: #{path.inspect}")
          end
        end

        assert_equal("##{index}", node&.slice, "at #{path}")
      end
    end
  end
end
