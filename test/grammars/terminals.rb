# frozen_string_literal: true

module Prism
  module Grammars
    module Terminals
      TRIVIA = %i[
        COMMENT
        EMBDOC_BEGIN
        EMBDOC_LINE
        EMBDOC_END
        IGNORED_NEWLINE
        __END__
      ].freeze

      TERMINALS = {
        AMPERSAND: "'&'",
        AMPERSAND_AMPERSAND: "tANDOP",
        AMPERSAND_AMPERSAND_EQUAL: "tOP_ASGN",
        AMPERSAND_DOT: "tANDDOT",
        AMPERSAND_EQUAL: "tOP_ASGN",
        BACKTICK: "'`'",
        BACK_REFERENCE: "tBACK_REF",
        BANG: "'!'",
        BANG_EQUAL: "tNEQ",
        BANG_TILDE: "tNMATCH",
        BRACE_LEFT: "'{'",
        BRACE_LEFT_ARGUMENT: "tLBRACE_ARG",
        BRACE_LEFT_HASH: "tLBRACE",
        BRACE_RIGHT: "'}'",
        BRACKET_LEFT: "'['",
        BRACKET_LEFT_ARRAY: "tLBRACK",
        BRACKET_LEFT_RIGHT: "tAREF",
        BRACKET_LEFT_RIGHT_EQUAL: "tASET",
        BRACKET_RIGHT: "']'",
        CARET: "'^'",
        CARET_EQUAL: "tOP_ASGN",
        CHARACTER_LITERAL: "tCHAR",
        CLASS_VARIABLE: "tCVAR",
        COLON: "':'",
        COLON_COLON: "tCOLON2",
        COMMA: "','",
        CONSTANT: "tCONSTANT",
        DOT: "'.'",
        DOT_DOT: "tDOT2",
        DOT_DOT_DOT: "tDOT3",
        EMBEXPR_BEGIN: "tSTRING_DBEG",
        EMBEXPR_END: "tSTRING_DEND",
        EMBVAR: "tSTRING_DVAR",
        EOF: "END_OF_INPUT",
        EQUAL: "'='",
        EQUAL_EQUAL: "tEQ",
        EQUAL_EQUAL_EQUAL: "tEQQ",
        EQUAL_GREATER: "tASSOC",
        EQUAL_TILDE: "tMATCH",
        FLOAT: "tFLOAT",
        FLOAT_IMAGINARY: "tIMAGINARY",
        FLOAT_RATIONAL: "tRATIONAL",
        FLOAT_RATIONAL_IMAGINARY: "tIMAGINARY",
        GLOBAL_VARIABLE: "tGVAR",
        GREATER: "'>'",
        GREATER_EQUAL: "tGEQ",
        GREATER_GREATER: "tRSHFT",
        GREATER_GREATER_EQUAL: "tOP_ASGN",
        HEREDOC_END: "tSTRING_END",
        HEREDOC_START: "tSTRING_BEG",
        IDENTIFIER: "tIDENTIFIER",
        INSTANCE_VARIABLE: "tIVAR",
        INTEGER: "tINTEGER",
        INTEGER_IMAGINARY: "tIMAGINARY",
        INTEGER_RATIONAL: "tRATIONAL",
        INTEGER_RATIONAL_IMAGINARY: "tIMAGINARY",
        KEYWORD_ALIAS: "keyword_alias",
        KEYWORD_AND: "keyword_and",
        KEYWORD_BEGIN: "keyword_begin",
        KEYWORD_BEGIN_UPCASE: "keyword_BEGIN",
        KEYWORD_BREAK: "keyword_break",
        KEYWORD_CASE: "keyword_case",
        KEYWORD_CLASS: "keyword_class",
        KEYWORD_DEF: "keyword_def",
        KEYWORD_DEFINED: "keyword_defined",
        KEYWORD_DO: "keyword_do",
        KEYWORD_DO_BLOCK: "keyword_do_block",
        KEYWORD_DO_LAMBDA: "keyword_do_LAMBDA",
        KEYWORD_DO_LOOP: "keyword_do_cond",
        KEYWORD_ELSE: "keyword_else",
        KEYWORD_ELSIF: "keyword_elsif",
        KEYWORD_END: "keyword_end",
        KEYWORD_END_UPCASE: "keyword_END",
        KEYWORD_ENSURE: "keyword_ensure",
        KEYWORD_FALSE: "keyword_false",
        KEYWORD_FOR: "keyword_for",
        KEYWORD_IF: "keyword_if",
        KEYWORD_IF_MODIFIER: "modifier_if",
        KEYWORD_IN: "keyword_in",
        KEYWORD_MODULE: "keyword_module",
        KEYWORD_NEXT: "keyword_next",
        KEYWORD_NIL: "keyword_nil",
        KEYWORD_NOT: "keyword_not",
        KEYWORD_OR: "keyword_or",
        KEYWORD_REDO: "keyword_redo",
        KEYWORD_RESCUE: "keyword_rescue",
        KEYWORD_RESCUE_MODIFIER: "modifier_rescue",
        KEYWORD_RETRY: "keyword_retry",
        KEYWORD_RETURN: "keyword_return",
        KEYWORD_SELF: "keyword_self",
        KEYWORD_SUPER: "keyword_super",
        KEYWORD_THEN: "keyword_then",
        KEYWORD_TRUE: "keyword_true",
        KEYWORD_UNDEF: "keyword_undef",
        KEYWORD_UNLESS: "keyword_unless",
        KEYWORD_UNLESS_MODIFIER: "modifier_unless",
        KEYWORD_UNTIL: "keyword_until",
        KEYWORD_UNTIL_MODIFIER: "modifier_until",
        KEYWORD_WHEN: "keyword_when",
        KEYWORD_WHILE: "keyword_while",
        KEYWORD_WHILE_MODIFIER: "modifier_while",
        KEYWORD_YIELD: "keyword_yield",
        KEYWORD___ENCODING__: "keyword__ENCODING__",
        KEYWORD___FILE__: "keyword__FILE__",
        KEYWORD___LINE__: "keyword__LINE__",
        LABEL: "tLABEL",
        LABEL_END: "tLABEL_END",
        LAMBDA_BEGIN: "tLAMBEG",
        LESS: "'<'",
        LESS_EQUAL: "tLEQ",
        LESS_EQUAL_GREATER: "tCMP",
        LESS_LESS: "tLSHFT",
        LESS_LESS_EQUAL: "tOP_ASGN",
        METHOD_NAME: "tFID",
        MINUS: "'-'",
        MINUS_EQUAL: "tOP_ASGN",
        MINUS_GREATER: "tLAMBDA",
        NEWLINE: "'\\n'",
        NEWLINE_TERMINATOR: "'\\n'",
        NUMBERED_REFERENCE: "tNTH_REF",
        PARENTHESIS_LEFT: "'('",
        PARENTHESIS_LEFT_GROUPING: "tLPAREN",
        PARENTHESIS_LEFT_PARENTHESES: "tLPAREN_ARG",
        PARENTHESIS_RIGHT: "')'",
        PERCENT: "'%'",
        PERCENT_EQUAL: "tOP_ASGN",
        PERCENT_LOWER_I: "tQSYMBOLS_BEG",
        PERCENT_LOWER_W: "tQWORDS_BEG",
        PERCENT_LOWER_X: "tXSTRING_BEG",
        PERCENT_UPPER_I: "tSYMBOLS_BEG",
        PERCENT_UPPER_W: "tWORDS_BEG",
        PIPE: "'|'",
        PIPE_EQUAL: "tOP_ASGN",
        PIPE_PIPE: "tOROP",
        PIPE_PIPE_EQUAL: "tOP_ASGN",
        PLUS: "'+'",
        PLUS_EQUAL: "tOP_ASGN",
        QUESTION_MARK: "'?'",
        REGEXP_BEGIN: "tREGEXP_BEG",
        REGEXP_END: "tREGEXP_END",
        SEMICOLON: "';'",
        SLASH: "'/'",
        SLASH_EQUAL: "tOP_ASGN",
        STAR: "'*'",
        STAR_EQUAL: "tOP_ASGN",
        STAR_STAR: "tPOW",
        STAR_STAR_EQUAL: "tOP_ASGN",
        STRING_BEGIN: "tSTRING_BEG",
        STRING_CONTENT: "tSTRING_CONTENT",
        STRING_END: "tSTRING_END",
        SYMBOL_BEGIN: "tSYMBEG",
        TILDE: "'~'",
        UAMPERSAND: "tAMPER",
        UCOLON_COLON: "tCOLON3",
        UDOT_DOT: "tBDOT2",
        UDOT_DOT_DOT: "tBDOT3",
        UMINUS: "tUMINUS",
        UMINUS_NUM: "tUMINUS_NUM",
        UPLUS: "tUPLUS",
        USTAR: "tSTAR",
        USTAR_STAR: "tDSTAR",
        WORDS_SEP: "' '",
        WORDS_SEP_IMPLICIT: "' '",
        XSTRING_BEGIN: "tXSTRING_BEG"
      }.freeze

      class Error < StandardError
        def initialize(token)
          super("unmapped token #{token.type} #{token.value.inspect} at byte #{token.location.start_offset}")
        end
      end

      def self.translate(tokens)
        terminals = []
        list_literal = false

        tokens.each do |token|
          type = token.type

          # Skip trivial tokens such as whitespace and comments that are not
          # represented in the grammar.
          next if TRIVIA.include?(type)

          # Convert HEREDOC_START to XSTRING_BEGIN if it represents an xstring
          # heredoc.
          type = :XSTRING_BEGIN if type == :HEREDOC_START && token.value.b.match?(/\A<<[-~]?`/)

          # Prism splits a word when the lexer jumps over a heredoc body.
          # The grammar expects one content terminal per non-interpolated word.
          list_literal = true if type == :PERCENT_LOWER_W || type == :PERCENT_LOWER_I
          list_literal = false if type == :STRING_END
          next if list_literal && type == :STRING_CONTENT && terminals.last == "tSTRING_CONTENT"

          # Append the terminal corresponding to the token type, raising an
          # error if it is unmapped.
          terminals << TERMINALS.fetch(type) { raise Error, token }
        end

        terminals
      end
    end
  end
end
