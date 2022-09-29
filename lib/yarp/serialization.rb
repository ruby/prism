# frozen_string_literal: true

module YARP
  def self.load(source, serialized)
    Serialization.load(source, serialized)
  end

  ##############################################################################
  # BEGIN TEMPLATE                                                             #
  ##############################################################################

  module Serialization
    class << self
      def load(source, serialized)
        require "stringio"

        io = StringIO.new(serialized)
        io.set_encoding(Encoding::BINARY)

        io.read(4) => "YARP"
        io.read(3).unpack("C3") => [0, 1, 0]

        load_node(source, io)
      end

      private

      def load_token(source, io)
        number, start_offset, end_offset = io.read(17).unpack("CQQ")
        type =
          case number
          when 0 then :EOF
          when 1 then :INVALID
          when 2 then :AMPERSAND
          when 3 then :AMPERSAND_AMPERSAND
          when 4 then :AMPERSAND_AMPERSAND_EQUAL
          when 5 then :AMPERSAND_EQUAL
          when 6 then :BACK_REFERENCE
          when 7 then :BACKTICK
          when 8 then :BANG
          when 9 then :BANG_AT
          when 10 then :BANG_EQUAL
          when 11 then :BANG_TILDE
          when 12 then :BRACE_LEFT
          when 13 then :BRACE_RIGHT
          when 14 then :BRACKET_LEFT
          when 15 then :BRACKET_LEFT_RIGHT
          when 16 then :BRACKET_RIGHT
          when 17 then :CARET
          when 18 then :CARET_EQUAL
          when 19 then :CHARACTER_LITERAL
          when 20 then :CLASS_VARIABLE
          when 21 then :COLON
          when 22 then :COLON_COLON
          when 23 then :COMMA
          when 24 then :COMMENT
          when 25 then :CONSTANT
          when 26 then :DOT
          when 27 then :DOT_DOT
          when 28 then :DOT_DOT_DOT
          when 29 then :EMBDOC_BEGIN
          when 30 then :EMBDOC_END
          when 31 then :EMBDOC_LINE
          when 32 then :EMBEXPR_BEGIN
          when 33 then :EMBEXPR_END
          when 34 then :EQUAL
          when 35 then :EQUAL_EQUAL
          when 36 then :EQUAL_EQUAL_EQUAL
          when 37 then :EQUAL_GREATER
          when 38 then :EQUAL_TILDE
          when 39 then :FLOAT
          when 40 then :GREATER
          when 41 then :GREATER_EQUAL
          when 42 then :GREATER_GREATER
          when 43 then :GREATER_GREATER_EQUAL
          when 44 then :GLOBAL_VARIABLE
          when 45 then :IDENTIFIER
          when 46 then :IMAGINARY_NUMBER
          when 47 then :INSTANCE_VARIABLE
          when 48 then :INTEGER
          when 49 then :KEYWORD___ENCODING__
          when 50 then :KEYWORD___LINE__
          when 51 then :KEYWORD___FILE__
          when 52 then :KEYWORD_ALIAS
          when 53 then :KEYWORD_AND
          when 54 then :KEYWORD_BEGIN
          when 55 then :KEYWORD_BEGIN_UPCASE
          when 56 then :KEYWORD_BREAK
          when 57 then :KEYWORD_CASE
          when 58 then :KEYWORD_CLASS
          when 59 then :KEYWORD_DEF
          when 60 then :KEYWORD_DEFINED
          when 61 then :KEYWORD_DO
          when 62 then :KEYWORD_ELSE
          when 63 then :KEYWORD_ELSIF
          when 64 then :KEYWORD_END
          when 65 then :KEYWORD_END_UPCASE
          when 66 then :KEYWORD_ENSURE
          when 67 then :KEYWORD_FALSE
          when 68 then :KEYWORD_FOR
          when 69 then :KEYWORD_IF
          when 70 then :KEYWORD_IN
          when 71 then :KEYWORD_MODULE
          when 72 then :KEYWORD_NEXT
          when 73 then :KEYWORD_NIL
          when 74 then :KEYWORD_NOT
          when 75 then :KEYWORD_OR
          when 76 then :KEYWORD_REDO
          when 77 then :KEYWORD_RESCUE
          when 78 then :KEYWORD_RETRY
          when 79 then :KEYWORD_RETURN
          when 80 then :KEYWORD_SELF
          when 81 then :KEYWORD_SUPER
          when 82 then :KEYWORD_THEN
          when 83 then :KEYWORD_TRUE
          when 84 then :KEYWORD_UNDEF
          when 85 then :KEYWORD_UNLESS
          when 86 then :KEYWORD_UNTIL
          when 87 then :KEYWORD_WHEN
          when 88 then :KEYWORD_WHILE
          when 89 then :KEYWORD_YIELD
          when 90 then :LABEL
          when 91 then :LAMBDA_BEGIN
          when 92 then :LESS
          when 93 then :LESS_EQUAL
          when 94 then :LESS_EQUAL_GREATER
          when 95 then :LESS_LESS
          when 96 then :LESS_LESS_EQUAL
          when 97 then :MINUS
          when 98 then :MINUS_AT
          when 99 then :MINUS_EQUAL
          when 100 then :MINUS_GREATER
          when 101 then :NEWLINE
          when 102 then :NTH_REFERENCE
          when 103 then :PARENTHESIS_LEFT
          when 104 then :PARENTHESIS_RIGHT
          when 105 then :PERCENT
          when 106 then :PERCENT_EQUAL
          when 107 then :PERCENT_LOWER_I
          when 108 then :PERCENT_LOWER_W
          when 109 then :PERCENT_LOWER_X
          when 110 then :PERCENT_UPPER_I
          when 111 then :PERCENT_UPPER_W
          when 112 then :PIPE
          when 113 then :PIPE_EQUAL
          when 114 then :PIPE_PIPE
          when 115 then :PIPE_PIPE_EQUAL
          when 116 then :PLUS
          when 117 then :PLUS_AT
          when 118 then :PLUS_EQUAL
          when 119 then :QUESTION_MARK
          when 120 then :RATIONAL_NUMBER
          when 121 then :REGEXP_BEGIN
          when 122 then :REGEXP_END
          when 123 then :SEMICOLON
          when 124 then :SLASH
          when 125 then :SLASH_EQUAL
          when 126 then :STAR
          when 127 then :STAR_EQUAL
          when 128 then :STAR_STAR
          when 129 then :STAR_STAR_EQUAL
          when 130 then :STRING_BEGIN
          when 131 then :STRING_CONTENT
          when 132 then :STRING_END
          when 133 then :SYMBOL_BEGIN
          when 134 then :TILDE
          when 135 then :TILDE_AT
          when 136 then :WORDS_SEP
          end

        location = YARP::Location.new(start_offset, end_offset)
        YARP::Token.new(type, source[start_offset...end_offset], location)
      end

      def load_node(source, io)
        type, _length, start_offset, end_offset = io.read(25).unpack("CQQQ")
        location = YARP::Location.new(start_offset, end_offset)

        case type
        when 0 then YARP::Assignment.new(load_node(source, io), load_token(source, io), load_node(source, io), location)
        when 1 then YARP::Binary.new(load_node(source, io), load_token(source, io), load_node(source, io), location)
        when 2 then YARP::CharacterLiteral.new(load_token(source, io), location)
        when 3 then YARP::ClassVariableRead.new(load_token(source, io), location)
        when 4 then YARP::ClassVariableWrite.new(load_token(source, io), load_token(source, io), load_node(source, io), location)
        when 5 then YARP::FalseNode.new(load_token(source, io), location)
        when 6 then YARP::FloatLiteral.new(load_token(source, io), location)
        when 7 then YARP::GlobalVariableRead.new(load_token(source, io), location)
        when 8 then YARP::GlobalVariableWrite.new(load_token(source, io), load_token(source, io), load_node(source, io), location)
        when 9 then YARP::Identifier.new(load_token(source, io), location)
        when 10 then YARP::IfNode.new(load_token(source, io), load_node(source, io), load_node(source, io), location)
        when 11 then YARP::ImaginaryLiteral.new(load_token(source, io), location)
        when 12 then YARP::InstanceVariableRead.new(load_token(source, io), location)
        when 13 then YARP::InstanceVariableWrite.new(load_token(source, io), load_token(source, io), load_node(source, io), location)
        when 14 then YARP::IntegerLiteral.new(load_token(source, io), location)
        when 15 then YARP::NilNode.new(load_token(source, io), location)
        when 16 then YARP::OperatorAssignment.new(load_node(source, io), load_token(source, io), load_node(source, io), location)
        when 17 then YARP::Program.new(load_node(source, io), location)
        when 18 then YARP::Range.new(load_node(source, io), load_token(source, io), load_node(source, io), location)
        when 19 then YARP::RationalLiteral.new(load_token(source, io), location)
        when 20 then YARP::Redo.new(load_token(source, io), location)
        when 21 then YARP::Retry.new(load_token(source, io), location)
        when 22 then YARP::SelfNode.new(load_token(source, io), location)
        when 23 then YARP::Statements.new(io.read(8).unpack1("Q").times.map { load_node(source, io) }, location)
        when 24 then YARP::Ternary.new(load_node(source, io), load_token(source, io), load_node(source, io), load_token(source, io), load_node(source, io), location)
        when 25 then YARP::TrueNode.new(load_token(source, io), location)
        when 26 then YARP::UnlessModifier.new(load_node(source, io), load_token(source, io), load_node(source, io), location)
        when 27 then YARP::UntilModifier.new(load_node(source, io), load_token(source, io), load_node(source, io), location)
        when 28 then YARP::VariableReference.new(load_token(source, io), location)
        when 29 then YARP::WhileModifier.new(load_node(source, io), load_token(source, io), load_node(source, io), location)
        end
      end
    end
  end

  ##############################################################################
  # END TEMPLATE                                                               #
  ##############################################################################
end
