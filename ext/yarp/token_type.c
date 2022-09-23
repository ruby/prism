#include "token_type.h"
#include <string.h>

const char *
token_type_to_str(yp_token_type_t token_type) {
  switch (token_type) {
    case YP_TOKEN_EOF:
      return "EOF";
    case YP_TOKEN_INVALID:
      return "INVALID";
    case YP_TOKEN_AMPERSAND:
      return "AMPERSAND";
    case YP_TOKEN_AMPERSAND_AMPERSAND:
      return "AMPERSAND_AMPERSAND";
    case YP_TOKEN_AMPERSAND_AMPERSAND_EQUAL:
      return "AMPERSAND_AMPERSAND_EQUAL";
    case YP_TOKEN_AMPERSAND_EQUAL:
      return "AMPERSAND_EQUAL";
    case YP_TOKEN_BACK_REFERENCE:
      return "BACK_REFERENCE";
    case YP_TOKEN_BACKTICK:
      return "BACKTICK";
    case YP_TOKEN_BANG:
      return "BANG";
    case YP_TOKEN_BANG_AT:
      return "BANG_AT";
    case YP_TOKEN_BANG_EQUAL:
      return "BANG_EQUAL";
    case YP_TOKEN_BANG_TILDE:
      return "BANG_TILDE";
    case YP_TOKEN_BRACE_LEFT:
      return "BRACE_LEFT";
    case YP_TOKEN_BRACE_RIGHT:
      return "BRACE_RIGHT";
    case YP_TOKEN_BRACKET_LEFT:
      return "BRACKET_LEFT";
    case YP_TOKEN_BRACKET_LEFT_RIGHT:
      return "BRACKET_LEFT_RIGHT";
    case YP_TOKEN_BRACKET_RIGHT:
      return "BRACKET_RIGHT";
    case YP_TOKEN_CARET:
      return "CARET";
    case YP_TOKEN_CARET_EQUAL:
      return "CARET_EQUAL";
    case YP_TOKEN_CHARACTER_LITERAL:
      return "CHARACTER_LITERAL";
    case YP_TOKEN_CLASS_VARIABLE:
      return "CLASS_VARIABLE";
    case YP_TOKEN_COLON:
      return "COLON";
    case YP_TOKEN_COLON_COLON:
      return "COLON_COLON";
    case YP_TOKEN_COMMA:
      return "COMMA";
    case YP_TOKEN_COMMENT:
      return "COMMENT";
    case YP_TOKEN_CONSTANT:
      return "CONSTANT";
    case YP_TOKEN_DOT:
      return "DOT";
    case YP_TOKEN_DOT_DOT:
      return "DOT_DOT";
    case YP_TOKEN_DOT_DOT_DOT:
      return "DOT_DOT_DOT";
    case YP_TOKEN_EMBDOC_BEGIN:
      return "EMBDOC_BEGIN";
    case YP_TOKEN_EMBDOC_END:
      return "EMBDOC_END";
    case YP_TOKEN_EMBDOC_LINE:
      return "EMBDOC_LINE";
    case YP_TOKEN_EMBEXPR_BEGIN:
      return "EMBEXPR_BEGIN";
    case YP_TOKEN_EMBEXPR_END:
      return "EMBEXPR_END";
    case YP_TOKEN_EQUAL:
      return "EQUAL";
    case YP_TOKEN_EQUAL_EQUAL:
      return "EQUAL_EQUAL";
    case YP_TOKEN_EQUAL_EQUAL_EQUAL:
      return "EQUAL_EQUAL_EQUAL";
    case YP_TOKEN_EQUAL_GREATER:
      return "EQUAL_GREATER";
    case YP_TOKEN_EQUAL_TILDE:
      return "EQUAL_TILDE";
    case YP_TOKEN_FLOAT:
      return "FLOAT";
    case YP_TOKEN_GREATER:
      return "GREATER";
    case YP_TOKEN_GREATER_EQUAL:
      return "GREATER_EQUAL";
    case YP_TOKEN_GREATER_GREATER:
      return "GREATER_GREATER";
    case YP_TOKEN_GREATER_GREATER_EQUAL:
      return "GREATER_GREATER_EQUAL";
    case YP_TOKEN_GLOBAL_VARIABLE:
      return "GLOBAL_VARIABLE";
    case YP_TOKEN_IDENTIFIER:
      return "IDENTIFIER";
    case YP_TOKEN_IMAGINARY_NUMBER:
      return "IMAGINARY_NUMBER";
    case YP_TOKEN_INSTANCE_VARIABLE:
      return "INSTANCE_VARIABLE";
    case YP_TOKEN_INTEGER:
      return "INTEGER";
    case YP_TOKEN_KEYWORD___ENCODING__:
      return "KEYWORD___ENCODING__";
    case YP_TOKEN_KEYWORD___LINE__:
      return "KEYWORD___LINE__";
    case YP_TOKEN_KEYWORD___FILE__:
      return "KEYWORD___FILE__";
    case YP_TOKEN_KEYWORD_ALIAS:
      return "KEYWORD_ALIAS";
    case YP_TOKEN_KEYWORD_AND:
      return "KEYWORD_AND";
    case YP_TOKEN_KEYWORD_BEGIN:
      return "KEYWORD_BEGIN";
    case YP_TOKEN_KEYWORD_BEGIN_UPCASE:
      return "KEYWORD_BEGIN_UPCASE";
    case YP_TOKEN_KEYWORD_BREAK:
      return "KEYWORD_BREAK";
    case YP_TOKEN_KEYWORD_CASE:
      return "KEYWORD_CASE";
    case YP_TOKEN_KEYWORD_CLASS:
      return "KEYWORD_CLASS";
    case YP_TOKEN_KEYWORD_DEF:
      return "KEYWORD_DEF";
    case YP_TOKEN_KEYWORD_DEFINED:
      return "KEYWORD_DEFINED";
    case YP_TOKEN_KEYWORD_DO:
      return "KEYWORD_DO";
    case YP_TOKEN_KEYWORD_ELSE:
      return "KEYWORD_ELSE";
    case YP_TOKEN_KEYWORD_ELSIF:
      return "KEYWORD_ELSIF";
    case YP_TOKEN_KEYWORD_END:
      return "KEYWORD_END";
    case YP_TOKEN_KEYWORD_END_UPCASE:
      return "KEYWORD_END_UPCASE";
    case YP_TOKEN_KEYWORD_ENSURE:
      return "KEYWORD_ENSURE";
    case YP_TOKEN_KEYWORD_FALSE:
      return "KEYWORD_FALSE";
    case YP_TOKEN_KEYWORD_FOR:
      return "KEYWORD_FOR";
    case YP_TOKEN_KEYWORD_IF:
      return "KEYWORD_IF";
    case YP_TOKEN_KEYWORD_IN:
      return "KEYWORD_IN";
    case YP_TOKEN_KEYWORD_MODULE:
      return "KEYWORD_MODULE";
    case YP_TOKEN_KEYWORD_NEXT:
      return "KEYWORD_NEXT";
    case YP_TOKEN_KEYWORD_NIL:
      return "KEYWORD_NIL";
    case YP_TOKEN_KEYWORD_NOT:
      return "KEYWORD_NOT";
    case YP_TOKEN_KEYWORD_OR:
      return "KEYWORD_OR";
    case YP_TOKEN_KEYWORD_REDO:
      return "KEYWORD_REDO";
    case YP_TOKEN_KEYWORD_RESCUE:
      return "KEYWORD_RESCUE";
    case YP_TOKEN_KEYWORD_RETRY:
      return "KEYWORD_RETRY";
    case YP_TOKEN_KEYWORD_RETURN:
      return "KEYWORD_RETURN";
    case YP_TOKEN_KEYWORD_SELF:
      return "KEYWORD_SELF";
    case YP_TOKEN_KEYWORD_SUPER:
      return "KEYWORD_SUPER";
    case YP_TOKEN_KEYWORD_THEN:
      return "KEYWORD_THEN";
    case YP_TOKEN_KEYWORD_TRUE:
      return "KEYWORD_TRUE";
    case YP_TOKEN_KEYWORD_UNDEF:
      return "KEYWORD_UNDEF";
    case YP_TOKEN_KEYWORD_UNLESS:
      return "KEYWORD_UNLESS";
    case YP_TOKEN_KEYWORD_UNTIL:
      return "KEYWORD_UNTIL";
    case YP_TOKEN_KEYWORD_WHEN:
      return "KEYWORD_WHEN";
    case YP_TOKEN_KEYWORD_WHILE:
      return "KEYWORD_WHILE";
    case YP_TOKEN_KEYWORD_YIELD:
      return "KEYWORD_YIELD";
    case YP_TOKEN_LABEL:
      return "LABEL";
    case YP_TOKEN_LAMBDA_BEGIN:
      return "LAMBDA_BEGIN";
    case YP_TOKEN_LESS:
      return "LESS";
    case YP_TOKEN_LESS_EQUAL:
      return "LESS_EQUAL";
    case YP_TOKEN_LESS_EQUAL_GREATER:
      return "LESS_EQUAL_GREATER";
    case YP_TOKEN_LESS_LESS:
      return "LESS_LESS";
    case YP_TOKEN_LESS_LESS_EQUAL:
      return "LESS_LESS_EQUAL";
    case YP_TOKEN_MINUS:
      return "MINUS";
    case YP_TOKEN_MINUS_AT:
      return "MINUS_AT";
    case YP_TOKEN_MINUS_EQUAL:
      return "MINUS_EQUAL";
    case YP_TOKEN_MINUS_GREATER:
      return "MINUS_GREATER";
    case YP_TOKEN_NEWLINE:
      return "NEWLINE";
    case YP_TOKEN_NTH_REFERENCE:
      return "NTH_REFERENCE";
    case YP_TOKEN_PARENTHESIS_LEFT:
      return "PARENTHESIS_LEFT";
    case YP_TOKEN_PARENTHESIS_RIGHT:
      return "PARENTHESIS_RIGHT";
    case YP_TOKEN_PERCENT:
      return "PERCENT";
    case YP_TOKEN_PERCENT_EQUAL:
      return "PERCENT_EQUAL";
    case YP_TOKEN_PERCENT_LOWER_I:
      return "PERCENT_LOWER_I";
    case YP_TOKEN_PERCENT_LOWER_W:
      return "PERCENT_LOWER_W";
    case YP_TOKEN_PERCENT_LOWER_X:
      return "PERCENT_LOWER_X";
    case YP_TOKEN_PERCENT_UPPER_I:
      return "PERCENT_UPPER_I";
    case YP_TOKEN_PERCENT_UPPER_W:
      return "PERCENT_UPPER_W";
    case YP_TOKEN_PIPE:
      return "PIPE";
    case YP_TOKEN_PIPE_EQUAL:
      return "PIPE_EQUAL";
    case YP_TOKEN_PIPE_PIPE:
      return "PIPE_PIPE";
    case YP_TOKEN_PIPE_PIPE_EQUAL:
      return "PIPE_PIPE_EQUAL";
    case YP_TOKEN_PLUS:
      return "PLUS";
    case YP_TOKEN_PLUS_AT:
      return "PLUS_AT";
    case YP_TOKEN_PLUS_EQUAL:
      return "PLUS_EQUAL";
    case YP_TOKEN_QUESTION_MARK:
      return "QUESTION_MARK";
    case YP_TOKEN_RATIONAL_NUMBER:
      return "RATIONAL_NUMBER";
    case YP_TOKEN_REGEXP_BEGIN:
      return "REGEXP_BEGIN";
    case YP_TOKEN_REGEXP_END:
      return "REGEXP_END";
    case YP_TOKEN_SEMICOLON:
      return "SEMICOLON";
    case YP_TOKEN_SLASH:
      return "SLASH";
    case YP_TOKEN_SLASH_EQUAL:
      return "SLASH_EQUAL";
    case YP_TOKEN_STAR:
      return "STAR";
    case YP_TOKEN_STAR_EQUAL:
      return "STAR_EQUAL";
    case YP_TOKEN_STAR_STAR:
      return "STAR_STAR";
    case YP_TOKEN_STAR_STAR_EQUAL:
      return "STAR_STAR_EQUAL";
    case YP_TOKEN_STRING_BEGIN:
      return "STRING_BEGIN";
    case YP_TOKEN_STRING_CONTENT:
      return "STRING_CONTENT";
    case YP_TOKEN_STRING_END:
      return "STRING_END";
    case YP_TOKEN_SYMBOL_BEGIN:
      return "SYMBOL_BEGIN";
    case YP_TOKEN_TILDE:
      return "TILDE";
    case YP_TOKEN_TILDE_AT:
      return "TILDE_AT";
    case YP_TOKEN_WORDS_SEP:
      return "WORDS_SEP";
    case YP_TOKEN_MAXIMUM:
      return "MAXIMUM";
  }
}

yp_token_type_t
token_type_from_str(const char *s) {
  if (strcmp(s, "EOF") == 0) {
    return YP_TOKEN_EOF;
  }
  if (strcmp(s, "INVALID") == 0) {
    return YP_TOKEN_INVALID;
  }
  if (strcmp(s, "AMPERSAND") == 0) {
    return YP_TOKEN_AMPERSAND;
  }
  if (strcmp(s, "AMPERSAND_AMPERSAND") == 0) {
    return YP_TOKEN_AMPERSAND_AMPERSAND;
  }
  if (strcmp(s, "AMPERSAND_AMPERSAND_EQUAL") == 0) {
    return YP_TOKEN_AMPERSAND_AMPERSAND_EQUAL;
  }
  if (strcmp(s, "AMPERSAND_EQUAL") == 0) {
    return YP_TOKEN_AMPERSAND_EQUAL;
  }
  if (strcmp(s, "BACK_REFERENCE") == 0) {
    return YP_TOKEN_BACK_REFERENCE;
  }
  if (strcmp(s, "BACKTICK") == 0) {
    return YP_TOKEN_BACKTICK;
  }
  if (strcmp(s, "BANG") == 0) {
    return YP_TOKEN_BANG;
  }
  if (strcmp(s, "BANG_AT") == 0) {
    return YP_TOKEN_BANG_AT;
  }
  if (strcmp(s, "BANG_EQUAL") == 0) {
    return YP_TOKEN_BANG_EQUAL;
  }
  if (strcmp(s, "BANG_TILDE") == 0) {
    return YP_TOKEN_BANG_TILDE;
  }
  if (strcmp(s, "BRACE_LEFT") == 0) {
    return YP_TOKEN_BRACE_LEFT;
  }
  if (strcmp(s, "BRACE_RIGHT") == 0) {
    return YP_TOKEN_BRACE_RIGHT;
  }
  if (strcmp(s, "BRACKET_LEFT") == 0) {
    return YP_TOKEN_BRACKET_LEFT;
  }
  if (strcmp(s, "BRACKET_LEFT_RIGHT") == 0) {
    return YP_TOKEN_BRACKET_LEFT_RIGHT;
  }
  if (strcmp(s, "BRACKET_RIGHT") == 0) {
    return YP_TOKEN_BRACKET_RIGHT;
  }
  if (strcmp(s, "CARET") == 0) {
    return YP_TOKEN_CARET;
  }
  if (strcmp(s, "CARET_EQUAL") == 0) {
    return YP_TOKEN_CARET_EQUAL;
  }
  if (strcmp(s, "CHARACTER_LITERAL") == 0) {
    return YP_TOKEN_CHARACTER_LITERAL;
  }
  if (strcmp(s, "CLASS_VARIABLE") == 0) {
    return YP_TOKEN_CLASS_VARIABLE;
  }
  if (strcmp(s, "COLON") == 0) {
    return YP_TOKEN_COLON;
  }
  if (strcmp(s, "COLON_COLON") == 0) {
    return YP_TOKEN_COLON_COLON;
  }
  if (strcmp(s, "COMMA") == 0) {
    return YP_TOKEN_COMMA;
  }
  if (strcmp(s, "COMMENT") == 0) {
    return YP_TOKEN_COMMENT;
  }
  if (strcmp(s, "CONSTANT") == 0) {
    return YP_TOKEN_CONSTANT;
  }
  if (strcmp(s, "DOT") == 0) {
    return YP_TOKEN_DOT;
  }
  if (strcmp(s, "DOT_DOT") == 0) {
    return YP_TOKEN_DOT_DOT;
  }
  if (strcmp(s, "DOT_DOT_DOT") == 0) {
    return YP_TOKEN_DOT_DOT_DOT;
  }
  if (strcmp(s, "EMBDOC_BEGIN") == 0) {
    return YP_TOKEN_EMBDOC_BEGIN;
  }
  if (strcmp(s, "EMBDOC_END") == 0) {
    return YP_TOKEN_EMBDOC_END;
  }
  if (strcmp(s, "EMBDOC_LINE") == 0) {
    return YP_TOKEN_EMBDOC_LINE;
  }
  if (strcmp(s, "EMBEXPR_BEGIN") == 0) {
    return YP_TOKEN_EMBEXPR_BEGIN;
  }
  if (strcmp(s, "EMBEXPR_END") == 0) {
    return YP_TOKEN_EMBEXPR_END;
  }
  if (strcmp(s, "EQUAL") == 0) {
    return YP_TOKEN_EQUAL;
  }
  if (strcmp(s, "EQUAL_EQUAL") == 0) {
    return YP_TOKEN_EQUAL_EQUAL;
  }
  if (strcmp(s, "EQUAL_EQUAL_EQUAL") == 0) {
    return YP_TOKEN_EQUAL_EQUAL_EQUAL;
  }
  if (strcmp(s, "EQUAL_GREATER") == 0) {
    return YP_TOKEN_EQUAL_GREATER;
  }
  if (strcmp(s, "EQUAL_TILDE") == 0) {
    return YP_TOKEN_EQUAL_TILDE;
  }
  if (strcmp(s, "FLOAT") == 0) {
    return YP_TOKEN_FLOAT;
  }
  if (strcmp(s, "GREATER") == 0) {
    return YP_TOKEN_GREATER;
  }
  if (strcmp(s, "GREATER_EQUAL") == 0) {
    return YP_TOKEN_GREATER_EQUAL;
  }
  if (strcmp(s, "GREATER_GREATER") == 0) {
    return YP_TOKEN_GREATER_GREATER;
  }
  if (strcmp(s, "GREATER_GREATER_EQUAL") == 0) {
    return YP_TOKEN_GREATER_GREATER_EQUAL;
  }
  if (strcmp(s, "GLOBAL_VARIABLE") == 0) {
    return YP_TOKEN_GLOBAL_VARIABLE;
  }
  if (strcmp(s, "IDENTIFIER") == 0) {
    return YP_TOKEN_IDENTIFIER;
  }
  if (strcmp(s, "IMAGINARY_NUMBER") == 0) {
    return YP_TOKEN_IMAGINARY_NUMBER;
  }
  if (strcmp(s, "INSTANCE_VARIABLE") == 0) {
    return YP_TOKEN_INSTANCE_VARIABLE;
  }
  if (strcmp(s, "INTEGER") == 0) {
    return YP_TOKEN_INTEGER;
  }
  if (strcmp(s, "KEYWORD___ENCODING__") == 0) {
    return YP_TOKEN_KEYWORD___ENCODING__;
  }
  if (strcmp(s, "KEYWORD___LINE__") == 0) {
    return YP_TOKEN_KEYWORD___LINE__;
  }
  if (strcmp(s, "KEYWORD___FILE__") == 0) {
    return YP_TOKEN_KEYWORD___FILE__;
  }
  if (strcmp(s, "KEYWORD_ALIAS") == 0) {
    return YP_TOKEN_KEYWORD_ALIAS;
  }
  if (strcmp(s, "KEYWORD_AND") == 0) {
    return YP_TOKEN_KEYWORD_AND;
  }
  if (strcmp(s, "KEYWORD_BEGIN") == 0) {
    return YP_TOKEN_KEYWORD_BEGIN;
  }
  if (strcmp(s, "KEYWORD_BEGIN_UPCASE") == 0) {
    return YP_TOKEN_KEYWORD_BEGIN_UPCASE;
  }
  if (strcmp(s, "KEYWORD_BREAK") == 0) {
    return YP_TOKEN_KEYWORD_BREAK;
  }
  if (strcmp(s, "KEYWORD_CASE") == 0) {
    return YP_TOKEN_KEYWORD_CASE;
  }
  if (strcmp(s, "KEYWORD_CLASS") == 0) {
    return YP_TOKEN_KEYWORD_CLASS;
  }
  if (strcmp(s, "KEYWORD_DEF") == 0) {
    return YP_TOKEN_KEYWORD_DEF;
  }
  if (strcmp(s, "KEYWORD_DEFINED") == 0) {
    return YP_TOKEN_KEYWORD_DEFINED;
  }
  if (strcmp(s, "KEYWORD_DO") == 0) {
    return YP_TOKEN_KEYWORD_DO;
  }
  if (strcmp(s, "KEYWORD_ELSE") == 0) {
    return YP_TOKEN_KEYWORD_ELSE;
  }
  if (strcmp(s, "KEYWORD_ELSIF") == 0) {
    return YP_TOKEN_KEYWORD_ELSIF;
  }
  if (strcmp(s, "KEYWORD_END") == 0) {
    return YP_TOKEN_KEYWORD_END;
  }
  if (strcmp(s, "KEYWORD_END_UPCASE") == 0) {
    return YP_TOKEN_KEYWORD_END_UPCASE;
  }
  if (strcmp(s, "KEYWORD_ENSURE") == 0) {
    return YP_TOKEN_KEYWORD_ENSURE;
  }
  if (strcmp(s, "KEYWORD_FALSE") == 0) {
    return YP_TOKEN_KEYWORD_FALSE;
  }
  if (strcmp(s, "KEYWORD_FOR") == 0) {
    return YP_TOKEN_KEYWORD_FOR;
  }
  if (strcmp(s, "KEYWORD_IF") == 0) {
    return YP_TOKEN_KEYWORD_IF;
  }
  if (strcmp(s, "KEYWORD_IN") == 0) {
    return YP_TOKEN_KEYWORD_IN;
  }
  if (strcmp(s, "KEYWORD_MODULE") == 0) {
    return YP_TOKEN_KEYWORD_MODULE;
  }
  if (strcmp(s, "KEYWORD_NEXT") == 0) {
    return YP_TOKEN_KEYWORD_NEXT;
  }
  if (strcmp(s, "KEYWORD_NIL") == 0) {
    return YP_TOKEN_KEYWORD_NIL;
  }
  if (strcmp(s, "KEYWORD_NOT") == 0) {
    return YP_TOKEN_KEYWORD_NOT;
  }
  if (strcmp(s, "KEYWORD_OR") == 0) {
    return YP_TOKEN_KEYWORD_OR;
  }
  if (strcmp(s, "KEYWORD_REDO") == 0) {
    return YP_TOKEN_KEYWORD_REDO;
  }
  if (strcmp(s, "KEYWORD_RESCUE") == 0) {
    return YP_TOKEN_KEYWORD_RESCUE;
  }
  if (strcmp(s, "KEYWORD_RETRY") == 0) {
    return YP_TOKEN_KEYWORD_RETRY;
  }
  if (strcmp(s, "KEYWORD_RETURN") == 0) {
    return YP_TOKEN_KEYWORD_RETURN;
  }
  if (strcmp(s, "KEYWORD_SELF") == 0) {
    return YP_TOKEN_KEYWORD_SELF;
  }
  if (strcmp(s, "KEYWORD_SUPER") == 0) {
    return YP_TOKEN_KEYWORD_SUPER;
  }
  if (strcmp(s, "KEYWORD_THEN") == 0) {
    return YP_TOKEN_KEYWORD_THEN;
  }
  if (strcmp(s, "KEYWORD_TRUE") == 0) {
    return YP_TOKEN_KEYWORD_TRUE;
  }
  if (strcmp(s, "KEYWORD_UNDEF") == 0) {
    return YP_TOKEN_KEYWORD_UNDEF;
  }
  if (strcmp(s, "KEYWORD_UNLESS") == 0) {
    return YP_TOKEN_KEYWORD_UNLESS;
  }
  if (strcmp(s, "KEYWORD_UNTIL") == 0) {
    return YP_TOKEN_KEYWORD_UNTIL;
  }
  if (strcmp(s, "KEYWORD_WHEN") == 0) {
    return YP_TOKEN_KEYWORD_WHEN;
  }
  if (strcmp(s, "KEYWORD_WHILE") == 0) {
    return YP_TOKEN_KEYWORD_WHILE;
  }
  if (strcmp(s, "KEYWORD_YIELD") == 0) {
    return YP_TOKEN_KEYWORD_YIELD;
  }
  if (strcmp(s, "LABEL") == 0) {
    return YP_TOKEN_LABEL;
  }
  if (strcmp(s, "LAMBDA_BEGIN") == 0) {
    return YP_TOKEN_LAMBDA_BEGIN;
  }
  if (strcmp(s, "LESS") == 0) {
    return YP_TOKEN_LESS;
  }
  if (strcmp(s, "LESS_EQUAL") == 0) {
    return YP_TOKEN_LESS_EQUAL;
  }
  if (strcmp(s, "LESS_EQUAL_GREATER") == 0) {
    return YP_TOKEN_LESS_EQUAL_GREATER;
  }
  if (strcmp(s, "LESS_LESS") == 0) {
    return YP_TOKEN_LESS_LESS;
  }
  if (strcmp(s, "LESS_LESS_EQUAL") == 0) {
    return YP_TOKEN_LESS_LESS_EQUAL;
  }
  if (strcmp(s, "MINUS") == 0) {
    return YP_TOKEN_MINUS;
  }
  if (strcmp(s, "MINUS_AT") == 0) {
    return YP_TOKEN_MINUS_AT;
  }
  if (strcmp(s, "MINUS_EQUAL") == 0) {
    return YP_TOKEN_MINUS_EQUAL;
  }
  if (strcmp(s, "MINUS_GREATER") == 0) {
    return YP_TOKEN_MINUS_GREATER;
  }
  if (strcmp(s, "NEWLINE") == 0) {
    return YP_TOKEN_NEWLINE;
  }
  if (strcmp(s, "NTH_REFERENCE") == 0) {
    return YP_TOKEN_NTH_REFERENCE;
  }
  if (strcmp(s, "PARENTHESIS_LEFT") == 0) {
    return YP_TOKEN_PARENTHESIS_LEFT;
  }
  if (strcmp(s, "PARENTHESIS_RIGHT") == 0) {
    return YP_TOKEN_PARENTHESIS_RIGHT;
  }
  if (strcmp(s, "PERCENT") == 0) {
    return YP_TOKEN_PERCENT;
  }
  if (strcmp(s, "PERCENT_EQUAL") == 0) {
    return YP_TOKEN_PERCENT_EQUAL;
  }
  if (strcmp(s, "PERCENT_LOWER_I") == 0) {
    return YP_TOKEN_PERCENT_LOWER_I;
  }
  if (strcmp(s, "PERCENT_LOWER_W") == 0) {
    return YP_TOKEN_PERCENT_LOWER_W;
  }
  if (strcmp(s, "PERCENT_LOWER_X") == 0) {
    return YP_TOKEN_PERCENT_LOWER_X;
  }
  if (strcmp(s, "PERCENT_UPPER_I") == 0) {
    return YP_TOKEN_PERCENT_UPPER_I;
  }
  if (strcmp(s, "PERCENT_UPPER_W") == 0) {
    return YP_TOKEN_PERCENT_UPPER_W;
  }
  if (strcmp(s, "PIPE") == 0) {
    return YP_TOKEN_PIPE;
  }
  if (strcmp(s, "PIPE_EQUAL") == 0) {
    return YP_TOKEN_PIPE_EQUAL;
  }
  if (strcmp(s, "PIPE_PIPE") == 0) {
    return YP_TOKEN_PIPE_PIPE;
  }
  if (strcmp(s, "PIPE_PIPE_EQUAL") == 0) {
    return YP_TOKEN_PIPE_PIPE_EQUAL;
  }
  if (strcmp(s, "PLUS") == 0) {
    return YP_TOKEN_PLUS;
  }
  if (strcmp(s, "PLUS_AT") == 0) {
    return YP_TOKEN_PLUS_AT;
  }
  if (strcmp(s, "PLUS_EQUAL") == 0) {
    return YP_TOKEN_PLUS_EQUAL;
  }
  if (strcmp(s, "QUESTION_MARK") == 0) {
    return YP_TOKEN_QUESTION_MARK;
  }
  if (strcmp(s, "RATIONAL_NUMBER") == 0) {
    return YP_TOKEN_RATIONAL_NUMBER;
  }
  if (strcmp(s, "REGEXP_BEGIN") == 0) {
    return YP_TOKEN_REGEXP_BEGIN;
  }
  if (strcmp(s, "REGEXP_END") == 0) {
    return YP_TOKEN_REGEXP_END;
  }
  if (strcmp(s, "SEMICOLON") == 0) {
    return YP_TOKEN_SEMICOLON;
  }
  if (strcmp(s, "SLASH") == 0) {
    return YP_TOKEN_SLASH;
  }
  if (strcmp(s, "SLASH_EQUAL") == 0) {
    return YP_TOKEN_SLASH_EQUAL;
  }
  if (strcmp(s, "STAR") == 0) {
    return YP_TOKEN_STAR;
  }
  if (strcmp(s, "STAR_EQUAL") == 0) {
    return YP_TOKEN_STAR_EQUAL;
  }
  if (strcmp(s, "STAR_STAR") == 0) {
    return YP_TOKEN_STAR_STAR;
  }
  if (strcmp(s, "STAR_STAR_EQUAL") == 0) {
    return YP_TOKEN_STAR_STAR_EQUAL;
  }
  if (strcmp(s, "STRING_BEGIN") == 0) {
    return YP_TOKEN_STRING_BEGIN;
  }
  if (strcmp(s, "STRING_CONTENT") == 0) {
    return YP_TOKEN_STRING_CONTENT;
  }
  if (strcmp(s, "STRING_END") == 0) {
    return YP_TOKEN_STRING_END;
  }
  if (strcmp(s, "SYMBOL_BEGIN") == 0) {
    return YP_TOKEN_SYMBOL_BEGIN;
  }
  if (strcmp(s, "TILDE") == 0) {
    return YP_TOKEN_TILDE;
  }
  if (strcmp(s, "TILDE_AT") == 0) {
    return YP_TOKEN_TILDE_AT;
  }
  if (strcmp(s, "WORDS_SEP") == 0) {
    return YP_TOKEN_WORDS_SEP;
  }
  if (strcmp(s, "MAXIMUM") == 0) {
    return YP_TOKEN_MAXIMUM;
  }

  // Fallback
  return YP_TOKEN_INVALID;
}
