#include "yarp.h"

/******************************************************************************/
/* Basic character checks                                                     */
/******************************************************************************/

static inline bool
is_binary_number_char(const char *c) {
  return *c == '0' || *c == '1';
}

static inline bool
is_octal_number_char(const char *c) {
  return *c >= '0' && *c <= '7';
}

static inline bool
is_decimal_number_char(const char *c) {
  return *c >= '0' && *c <= '9';
}

static inline bool
is_hexadecimal_number_char(const char *c) {
  return (*c >= '0' && *c <= '9') || (*c >= 'a' && *c <= 'f') || (*c >= 'A' && *c <= 'F');
}

static inline bool
is_identifier_start_char(const char *c) {
  return (*c >= 'a' && *c <= 'z') || (*c >= 'A' && *c <= 'Z') || (*c == '_');
}

static inline bool
is_identifier_char(const char *c) {
  return is_identifier_start_char(c) || is_decimal_number_char(c);
}

static inline bool
is_non_newline_whitespace_char(const char *c) {
  return *c == ' ' || *c == '\t' || *c == '\f' || *c == '\r' || *c == '\v';
}

static inline bool
is_whitespace_char(const char *c) {
  return is_non_newline_whitespace_char(c) || *c == '\n';
}

/******************************************************************************/
/* Lexer check helpers                                                        */
/******************************************************************************/

// If the character to be read matches the given value, then returns true and
// advanced the current pointer.
static inline bool
match(yp_parser_t *parser, char value) {
  if (parser->current.end < parser->end && *parser->current.end == value) {
    parser->current.end++;
    return true;
  }
  return false;
}

// Returns the matching character that should be used to terminate a list
// beginning with the given character.
static char
terminator(const char start) {
  switch (start) {
    case '(':
      return ')';
    case '[':
      return ']';
    case '{':
      return '}';
    case '<':
      return '>';
    default:
      return start;
  }
}

/******************************************************************************/
/* Lex mode manipulations                                                     */
/******************************************************************************/

// Push a new lex state onto the stack. If we're still within the pre-allocated
// space of the lex state stack, then we'll just use a new slot. Otherwise we'll
// allocate a new pointer and use that.
static void
push_lex_mode(yp_parser_t *parser, yp_lex_mode_t lex_mode) {
  lex_mode.prev = parser->lex_modes.current;
  parser->lex_modes.index++;

  if (parser->lex_modes.index > YP_LEX_STACK_SIZE - 1) {
    parser->lex_modes.current = (yp_lex_mode_t *) malloc(sizeof(yp_lex_mode_t));
  } else {
    parser->lex_modes.stack[parser->lex_modes.index] = lex_mode;
    parser->lex_modes.current = &parser->lex_modes.stack[parser->lex_modes.index];
  }
}

// Pop the current lex state off the stack. If we're within the pre-allocated
// space of the lex state stack, then we'll just decrement the index. Otherwise
// we'll free the current pointer and use the previous pointer.
static void
pop_lex_mode(yp_parser_t *parser) {
  if (parser->lex_modes.index == 0) {
    parser->lex_modes.current->mode = YP_LEX_DEFAULT;
  } else if (parser->lex_modes.index < YP_LEX_STACK_SIZE) {
    parser->lex_modes.index--;
    parser->lex_modes.current = &parser->lex_modes.stack[parser->lex_modes.index];
  } else {
    parser->lex_modes.index--;
    yp_lex_mode_t *prev = parser->lex_modes.current->prev;
    free(parser->lex_modes.current);
    parser->lex_modes.current = prev;
  }
}

/******************************************************************************/
/* Specific token lexers                                                      */
/******************************************************************************/

static yp_token_type_t
lex_optional_float_suffix(yp_parser_t *parser) {
  yp_token_type_t type = YP_TOKEN_INTEGER;

  // Here we're going to attempt to parse the optional decimal portion of a
  // float. If it's not there, then it's okay and we'll just continue on.
  if (*parser->current.end == '.') {
    if ((parser->current.end + 1 < parser->end) && is_decimal_number_char(parser->current.end + 1)) {
      parser->current.end += 2;
      while (is_decimal_number_char(parser->current.end)) {
        parser->current.end++;
        match(parser, '_');
      }

      type = YP_TOKEN_FLOAT;
    } else {
      // If we had a . and then something else, then it's not a float suffix on
      // a number it's a method call or something else.
      return type;
    }
  }

  // Here we're going to attempt to parse the optional exponent portion of a
  // float. If it's not there, it's okay and we'll just continue on.
  if (match(parser, 'e') || match(parser, 'E')) {
    (void) (match(parser, '+') || match(parser, '-'));

    if (is_decimal_number_char(parser->current.end)) {
      parser->current.end++;
      while (is_decimal_number_char(parser->current.end)) {
        parser->current.end++;
        match(parser, '_');
      }

      type = YP_TOKEN_FLOAT;
    } else {
      return YP_TOKEN_INVALID;
    }
  }

  return type;
}

static yp_token_type_t
lex_numeric_prefix(yp_parser_t *parser) {
  yp_token_type_t type = YP_TOKEN_INTEGER;

  if (parser->current.end[-1] == '0') {
    switch (*parser->current.end) {
      // 0d1111 is a decimal number
      case 'd':
      case 'D':
        if (!is_decimal_number_char(++parser->current.end)) return YP_TOKEN_INVALID;
        while (is_decimal_number_char(parser->current.end)) {
          parser->current.end++;
          match(parser, '_');
        }
        break;

      // 0b1111 is a binary number
      case 'b':
      case 'B':
        if (!is_binary_number_char(++parser->current.end)) return YP_TOKEN_INVALID;
        while (is_binary_number_char(parser->current.end)) {
          parser->current.end++;
          match(parser, '_');
        }
        break;

      // 0o1111 is an octal number
      case 'o':
      case 'O':
        if (!is_octal_number_char(++parser->current.end)) return YP_TOKEN_INVALID;
        // fall through

      // 01111 is an octal number
      case '0':
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
        while (is_octal_number_char(parser->current.end)) {
          parser->current.end++;
          match(parser, '_');
        }
        break;

      // 0x1111 is a hexadecimal number
      case 'x':
      case 'X':
        if (!is_hexadecimal_number_char(++parser->current.end)) return YP_TOKEN_INVALID;
        while (is_hexadecimal_number_char(parser->current.end)) {
          parser->current.end++;
          match(parser, '_');
        }
        break;

      // 0.xxx is a float
      case '.': {
        type = lex_optional_float_suffix(parser);
        break;
      }

      // 0exxx is a float
      case 'e':
      case 'E': {
        type = lex_optional_float_suffix(parser);
        break;
      }
    }
  } else {
    // If it didn't start with a 0, then we'll lex as far as we can into a
    // decimal number.
    while (is_decimal_number_char(parser->current.end)) {
      parser->current.end++;
      match(parser, '_');
    }

    // Afterward, we'll lex as far as we can into an optional float suffix.
    type = lex_optional_float_suffix(parser);
  }

  // If the last character that we consumed was an underscore, then this is
  // actually an invalid integer value, and we should return an invalid token.
  if (parser->current.end[-1] == '_') return YP_TOKEN_INVALID;
  return type;
}

static yp_token_type_t
lex_numeric(yp_parser_t *parser) {
  yp_token_type_t type = lex_numeric_prefix(parser);

  if (type != YP_TOKEN_INVALID) {
    if (match(parser, 'r')) type = YP_TOKEN_RATIONAL_NUMBER;
    if (match(parser, 'i')) type = YP_TOKEN_IMAGINARY_NUMBER;
  }

  return type;
}

static yp_token_type_t
lex_global_variable(yp_parser_t *parser) {
  switch (*parser->current.end) {
    case '~':  // $~: match-data
    case '*':  // $*: argv
    case '$':  // $$: pid
    case '?':  // $?: last status
    case '!':  // $!: error string
    case '@':  // $@: error position
    case '/':  // $/: input record separator
    case '\\': // $\: output record separator
    case ';':  // $;: field separator
    case ',':  // $,: output field separator
    case '.':  // $.: last read line number
    case '=':  // $=: ignorecase
    case ':':  // $:: load path
    case '<':  // $<: reading filename
    case '>':  // $>: default output handle
    case '\"': // $": already loaded files
      parser->current.end++;
      return YP_TOKEN_GLOBAL_VARIABLE;

    case '&':  // $&: last match
    case '`':  // $`: string before last match
    case '\'': // $': string after last match
    case '+':  // $+: string matches last paren.
      parser->current.end++;
      return YP_TOKEN_BACK_REFERENCE;

    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
      do {
        parser->current.end++;
      } while (is_decimal_number_char(parser->current.end));
      return YP_TOKEN_NTH_REFERENCE;

    default:
      if (is_identifier_char(parser->current.end)) {
        do {
          parser->current.end++;
        } while (is_identifier_char(parser->current.end));
        return YP_TOKEN_GLOBAL_VARIABLE;
      }

      // If we get here, then we have a $ followed by something that isn't
      // recognized as a global variable.
      return YP_TOKEN_INVALID;
  }
}

static yp_token_type_t
lex_identifier(yp_parser_t *parser) {
  // Lex as far as we can into the current identifier.
  while (is_identifier_char(parser->current.end)) {
    parser->current.end++;
  }

  off_t width = parser->current.end - parser->current.start;

#define KEYWORD(value, token)                                                                                          \
  if (width == sizeof(value) - 1 && strncmp(parser->current.start, value, sizeof(value) - 1) == 0)                     \
    return YP_TOKEN_KEYWORD_##token;

  if ((parser->current.end + 1 < parser->end) && (parser->current.end[1] != '=') &&
      (match(parser, '!') || match(parser, '?'))) {
    width++;
    if (parser->previous.type != YP_TOKEN_DOT) {
      KEYWORD("defined?", DEFINED)
    }
    return YP_TOKEN_IDENTIFIER;
  }

  if (parser->previous.type != YP_TOKEN_DOT) {
    KEYWORD("__ENCODING__", __ENCODING__)
    KEYWORD("__LINE__", __LINE__)
    KEYWORD("__FILE__", __FILE__)
    KEYWORD("alias", ALIAS)
    KEYWORD("and", AND)
    KEYWORD("begin", BEGIN)
    KEYWORD("BEGIN", BEGIN_UPCASE)
    KEYWORD("break", BREAK)
    KEYWORD("case", CASE)
    KEYWORD("class", CLASS)
    KEYWORD("def", DEF)
    KEYWORD("do", DO)
    KEYWORD("else", ELSE)
    KEYWORD("elsif", ELSIF)
    KEYWORD("end", END)
    KEYWORD("END", END_UPCASE)
    KEYWORD("ensure", ENSURE)
    KEYWORD("false", FALSE)
    KEYWORD("for", FOR)
    KEYWORD("if", IF)
    KEYWORD("in", IN)
    KEYWORD("module", MODULE)
    KEYWORD("next", NEXT)
    KEYWORD("nil", NIL)
    KEYWORD("not", NOT)
    KEYWORD("or", OR)
    KEYWORD("redo", REDO)
    KEYWORD("rescue", RESCUE)
    KEYWORD("retry", RETRY)
    KEYWORD("return", RETURN)
    KEYWORD("self", SELF)
    KEYWORD("super", SUPER)
    KEYWORD("then", THEN)
    KEYWORD("true", TRUE)
    KEYWORD("undef", UNDEF)
    KEYWORD("unless", UNLESS)
    KEYWORD("until", UNTIL)
    KEYWORD("when", WHEN)
    KEYWORD("while", WHILE)
    KEYWORD("yield", YIELD)
  }

#undef KEYWORD

  char start = parser->current.start[0];
  return start >= 'A' && start <= 'Z' ? YP_TOKEN_CONSTANT : YP_TOKEN_IDENTIFIER;
}

// This is the overall lexer function. It is responsible for advancing both
// parser->current.start and parser->current.end such that they point to the
// beginning and end of the next token. It should return the type of token that
// was found.
static yp_token_type_t
lex_token_type(yp_parser_t *parser) {
  switch (parser->lex_modes.current->mode) {
    case YP_LEX_DEFAULT:
    case YP_LEX_EMBEXPR: {
      // First, we're going to skip past any whitespace at the front of the next
      // token.
      while (is_non_newline_whitespace_char(parser->current.end)) {
        parser->current.end++;
      }

      // Next, we'll set to start of this token to be the current end.
      parser->current.start = parser->current.end;

      // Finally, we'll check the current character to determine the next token.
      switch (*parser->current.end++) {
        case '\0':   // NUL or end of script
        case '\004': // ^D
        case '\032': // ^Z
          return YP_TOKEN_EOF;

        case '#': // comments
          while (*parser->current.end != '\n' && *parser->current.end != '\0') {
            parser->current.end++;
          }
          (void) match(parser, '\n');
          return YP_TOKEN_COMMENT;

        case '\n': {
          parser->lineno++;
          return YP_TOKEN_NEWLINE;
        }

        // , ( ) ;
        case ',':
          return YP_TOKEN_COMMA;
        case '(':
          return YP_TOKEN_PARENTHESIS_LEFT;
        case ')':
          return YP_TOKEN_PARENTHESIS_RIGHT;
        case ';':
          return YP_TOKEN_SEMICOLON;

        // [ []
        case '[':
          if (parser->previous.type == YP_TOKEN_DOT && match(parser, ']')) {
            return YP_TOKEN_BRACKET_LEFT_RIGHT;
          }
          return YP_TOKEN_BRACKET_LEFT;

        // ]
        case ']':
          return YP_TOKEN_BRACKET_RIGHT;

        // {
        case '{':
          if (parser->previous.type == YP_TOKEN_MINUS_GREATER) return YP_TOKEN_LAMBDA_BEGIN;
          return YP_TOKEN_BRACE_LEFT;

        // }
        case '}':
          if (parser->lex_modes.current->mode == YP_LEX_EMBEXPR) {
            pop_lex_mode(parser);
            return YP_TOKEN_EMBEXPR_END;
          }
          return YP_TOKEN_BRACE_RIGHT;

        // * ** **= *=
        case '*':
          if (match(parser, '*')) return match(parser, '=') ? YP_TOKEN_STAR_STAR_EQUAL : YP_TOKEN_STAR_STAR;
          return match(parser, '=') ? YP_TOKEN_STAR_EQUAL : YP_TOKEN_STAR;

        // ! != !~ !@
        case '!':
          if (match(parser, '=')) return YP_TOKEN_BANG_EQUAL;
          if (match(parser, '~')) return YP_TOKEN_BANG_TILDE;
          if ((parser->previous.type == YP_TOKEN_KEYWORD_DEF || parser->previous.type == YP_TOKEN_DOT) &&
              match(parser, '@'))
            return YP_TOKEN_BANG_AT;
          return YP_TOKEN_BANG;

        // = => =~ == === =begin
        case '=':
          if (parser->current.end[-2] == '\n' && (strncmp(parser->current.end, "begin\n", 6) == 0)) {
            parser->current.end += 6;
            push_lex_mode(parser, (yp_lex_mode_t) { .mode = YP_LEX_EMBDOC, .term = '\0', .interp = false });
            return YP_TOKEN_EMBDOC_BEGIN;
          }

          if (match(parser, '>')) return YP_TOKEN_EQUAL_GREATER;
          if (match(parser, '~')) return YP_TOKEN_EQUAL_TILDE;
          if (match(parser, '=')) return match(parser, '=') ? YP_TOKEN_EQUAL_EQUAL_EQUAL : YP_TOKEN_EQUAL_EQUAL;
          return YP_TOKEN_EQUAL;

        // < << <<= <= <=>
        case '<':
          if (match(parser, '<')) {
            if (match(parser, '=')) return YP_TOKEN_LESS_LESS_EQUAL;

            // We don't yet handle heredocs.
            if (match(parser, '-') || match(parser, '~')) return YP_TOKEN_EOF;

            return YP_TOKEN_LESS_LESS;
          }
          if (match(parser, '=')) return match(parser, '>') ? YP_TOKEN_LESS_EQUAL_GREATER : YP_TOKEN_LESS_EQUAL;
          return YP_TOKEN_LESS;

        // > >> >>= >=
        case '>':
          if (match(parser, '>')) return match(parser, '=') ? YP_TOKEN_GREATER_GREATER_EQUAL : YP_TOKEN_GREATER_GREATER;
          return match(parser, '=') ? YP_TOKEN_GREATER_EQUAL : YP_TOKEN_GREATER;

        // double-quoted string literal
        case '"':
          push_lex_mode(parser, (yp_lex_mode_t) { .mode = YP_LEX_STRING, .term = '"', .interp = true });
          return YP_TOKEN_STRING_BEGIN;

        // xstring literal
        case '`':
          push_lex_mode(parser, (yp_lex_mode_t) { .mode = YP_LEX_STRING, .term = '`', .interp = true });
          return YP_TOKEN_BACKTICK;

        // single-quoted string literal
        case '\'':
          push_lex_mode(parser, (yp_lex_mode_t) { .mode = YP_LEX_STRING, .term = '\'', .interp = false });
          return YP_TOKEN_STRING_BEGIN;

        // ? character literal
        case '?':
          if (is_identifier_char(parser->current.end)) {
            parser->current.end++;
            return YP_TOKEN_CHARACTER_LITERAL;
          }
          return YP_TOKEN_QUESTION_MARK;

        // & && &&= &=
        case '&':
          if (match(parser, '&'))
            return match(parser, '=') ? YP_TOKEN_AMPERSAND_AMPERSAND_EQUAL : YP_TOKEN_AMPERSAND_AMPERSAND;
          return match(parser, '=') ? YP_TOKEN_AMPERSAND_EQUAL : YP_TOKEN_AMPERSAND;

        // | || ||= |=
        case '|':
          if (match(parser, '|')) return match(parser, '=') ? YP_TOKEN_PIPE_PIPE_EQUAL : YP_TOKEN_PIPE_PIPE;
          return match(parser, '=') ? YP_TOKEN_PIPE_EQUAL : YP_TOKEN_PIPE;

        // + += +@
        case '+':
          if (match(parser, '=')) return YP_TOKEN_PLUS_EQUAL;
          if ((parser->previous.type == YP_TOKEN_KEYWORD_DEF || parser->previous.type == YP_TOKEN_DOT) &&
              match(parser, '@'))
            return YP_TOKEN_PLUS_AT;
          return YP_TOKEN_PLUS;

        // - -= -@
        case '-':
          if (match(parser, '>')) return YP_TOKEN_MINUS_GREATER;
          if (match(parser, '=')) return YP_TOKEN_MINUS_EQUAL;
          if ((parser->previous.type == YP_TOKEN_KEYWORD_DEF || parser->previous.type == YP_TOKEN_DOT) &&
              match(parser, '@'))
            return YP_TOKEN_MINUS_AT;
          return YP_TOKEN_MINUS;

        // . .. ...
        case '.':
          if (!match(parser, '.')) return YP_TOKEN_DOT;
          return match(parser, '.') ? YP_TOKEN_DOT_DOT_DOT : YP_TOKEN_DOT_DOT;

        // integer
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
          return lex_numeric(parser);

        // :: symbol
        case ':':
          if (match(parser, ':')) return YP_TOKEN_COLON_COLON;
          if (is_identifier_char(parser->current.end)) {
            push_lex_mode(parser, (yp_lex_mode_t) { .mode = YP_LEX_SYMBOL, .term = '\0' });
            return YP_TOKEN_SYMBOL_BEGIN;
          }
          return YP_TOKEN_COLON;

        // / /=
        case '/':
          if (match(parser, '=')) return YP_TOKEN_SLASH_EQUAL;
          if (*parser->current.end == ' ') return YP_TOKEN_SLASH;

          push_lex_mode(parser, (yp_lex_mode_t) { .mode = YP_LEX_REGEXP, .term = '/' });
          return YP_TOKEN_REGEXP_BEGIN;

        // ^ ^=
        case '^':
          return match(parser, '=') ? YP_TOKEN_CARET_EQUAL : YP_TOKEN_CARET;

        // ~ ~@
        case '~':
          if ((parser->previous.type == YP_TOKEN_KEYWORD_DEF || parser->previous.type == YP_TOKEN_DOT) &&
              match(parser, '@'))
            return YP_TOKEN_TILDE_AT;
          return YP_TOKEN_TILDE;

        // TODO
        case '\\':
          return YP_TOKEN_INVALID;

        // % %= %i %I %q %Q %w %W
        case '%':
          switch (*parser->current.end) {
            case '=':
              parser->current.end++;
              return YP_TOKEN_PERCENT_EQUAL;
            case 'i':
              parser->current.end++;
              push_lex_mode(
                parser,
                (yp_lex_mode_t) { .mode = YP_LEX_LIST, .term = terminator(*parser->current.end++), .interp = false });
              return YP_TOKEN_PERCENT_LOWER_I;
            case 'I':
              parser->current.end++;
              push_lex_mode(
                parser,
                (yp_lex_mode_t) { .mode = YP_LEX_LIST, .term = terminator(*parser->current.end++), .interp = true });
              return YP_TOKEN_PERCENT_UPPER_I;
            case 'r':
              parser->current.end++;
              push_lex_mode(
                parser,
                (yp_lex_mode_t) { .mode = YP_LEX_REGEXP, .term = terminator(*parser->current.end++), .interp = true });
              return YP_TOKEN_REGEXP_BEGIN;
            case 'q':
              parser->current.end++;
              push_lex_mode(
                parser,
                (yp_lex_mode_t) { .mode = YP_LEX_STRING, .term = terminator(*parser->current.end++), .interp = false });
              return YP_TOKEN_STRING_BEGIN;
            case 'Q':
              parser->current.end++;
              push_lex_mode(
                parser,
                (yp_lex_mode_t) { .mode = YP_LEX_STRING, .term = terminator(*parser->current.end++), .interp = true });
              return YP_TOKEN_STRING_BEGIN;
            case 'w':
              parser->current.end++;
              push_lex_mode(
                parser,
                (yp_lex_mode_t) { .mode = YP_LEX_LIST, .term = terminator(*parser->current.end++), .interp = false });
              return YP_TOKEN_PERCENT_LOWER_W;
            case 'W':
              parser->current.end++;
              push_lex_mode(
                parser,
                (yp_lex_mode_t) { .mode = YP_LEX_LIST, .term = terminator(*parser->current.end++), .interp = true });
              return YP_TOKEN_PERCENT_UPPER_W;
            case 'x':
              parser->current.end++;
              push_lex_mode(
                parser,
                (yp_lex_mode_t) { .mode = YP_LEX_STRING, .term = terminator(*parser->current.end++), .interp = true });
              return YP_TOKEN_PERCENT_LOWER_X;
            default:
              return YP_TOKEN_PERCENT;
          }

        // global variable
        case '$':
          return lex_global_variable(parser);

        // instance variable, class variable
        case '@': {
          yp_token_type_t type = match(parser, '@') ? YP_TOKEN_CLASS_VARIABLE : YP_TOKEN_INSTANCE_VARIABLE;

          if (is_identifier_start_char(parser->current.end)) {
            do {
              parser->current.end++;
            } while (is_identifier_char(parser->current.end));
            return type;
          }

          return YP_TOKEN_INVALID;
        }

        default: {
          // If this isn't the beginning of an identifier, then it's an invalid
          // token as we've exhausted all of the other options.
          if (!is_identifier_start_char(parser->current.start)) {
            return YP_TOKEN_INVALID;
          }

          yp_token_type_t type = lex_identifier(parser);

          // If we're lexing in a place that allows labels and we've hit a
          // colon, then we can return a label token.
          if ((parser->current.end[0] == ':') && (parser->current.end[1] != ':')) {
            parser->current.end++;
            return YP_TOKEN_LABEL;
          }

          return type;
        }
      }
    }
    case YP_LEX_EMBDOC: {
      parser->current.start = parser->current.end;

      // If we've hit the end of the embedded documentation then we'll return that token here.
      if (strncmp(parser->current.end, "=end\n", 5) == 0) {
        parser->current.end += 5;
        pop_lex_mode(parser);
        return YP_TOKEN_EMBDOC_END;
      }

      // Otherwise, we'll parse until the end of the line and return a line of
      // embedded documentation.
      while ((parser->current.end < parser->end) && (*parser->current.end++ != '\n'))
        ;

      // If we've still got content, then we'll return a line of embedded
      // documentation.
      if (parser->current.end < parser->end) {
        parser->lineno++;
        return YP_TOKEN_EMBDOC_LINE;
      }

      // Otherwise, fall back to error recovery.
      return parser->error_handler->unterminated_embdoc(parser);
    }
    case YP_LEX_LIST: {
      // If there's any whitespace at the start of the list, then we're going to
      // trim it off the beginning and create a new token.
      if (is_whitespace_char(parser->current.end)) {
        parser->current.start = parser->current.end;

        do {
          if (*parser->current.end == '\n') parser->lineno++;
          parser->current.end++;
        } while (is_whitespace_char(parser->current.end));

        return YP_TOKEN_WORDS_SEP;
      }

      // Next, we'll set to start of this token to be the current end.
      parser->current.start = parser->current.end;

      // Lex as far as we can into the word.
      while (parser->current.end < parser->end) {
        // If we've hit whitespace, then we must have received content by now,
        // so we can return an element of the list.
        if (is_whitespace_char(parser->current.end)) {
          return YP_TOKEN_STRING_CONTENT;
        }

        if (*parser->current.end == parser->lex_modes.current->term) {
          // If we've hit the terminator and we've already skipped past content,
          // then we can return a list node.
          if (parser->current.start < parser->current.end) {
            return YP_TOKEN_STRING_CONTENT;
          }

          // Otherwise, switch back to the default state and return the end of
          // the list.
          parser->current.end++;
          pop_lex_mode(parser);
          return YP_TOKEN_STRING_END;
        }

        // Otherwise, just skip past the content as it's part of an element of
        // the list.
        parser->current.end++;
      }

      // Otherwise, fall back to error recovery.
      return parser->error_handler->unterminated_list(parser);
    }
    case YP_LEX_REGEXP: {
      // First, we'll set to start of this token to be the current end.
      parser->current.start = parser->current.end;

      // If we've hit the end of the string, then we can return to the default
      // state of the lexer and return a string ending token.
      if (match(parser, parser->lex_modes.current->term)) {
        // Since we've hit the terminator of the regular expression, we now need
        // to parse the options.
        bool options = true;
        while (options) {
          switch (*parser->current.end) {
            case 'e':
            case 'i':
            case 'm':
            case 'n':
            case 's':
            case 'u':
            case 'x':
              parser->current.end++;
              break;
            default:
              options = false;
              break;
          }
        }

        pop_lex_mode(parser);
        return YP_TOKEN_REGEXP_END;
      }

      // Otherwise, we'll lex as far as we can into the regular expression. If
      // we hit the end of the regular expression, then we'll return everything
      // up to that point.
      while (parser->current.end < parser->end) {
        // If we hit the terminator, then return this element of the string.
        if (*parser->current.end == parser->lex_modes.current->term) {
          return YP_TOKEN_STRING_CONTENT;
        }

        // If we hit a newline, make sure to do the required bookkeeping.
        if (*parser->current.end == '\n') parser->lineno++;

        // If we've hit a #, then check if it's used as the beginning of either
        // an embedded variable or an embedded expression.
        if (*parser->current.end == '#') {
          switch (parser->current.end[1]) {
            case '{':
              // In this case it's the start of an embedded expression.

              // If we have already consumed content, then we need to return
              // that content as string content first.
              if (parser->current.end > parser->current.start) {
                return YP_TOKEN_STRING_CONTENT;
              }

              parser->current.end += 2;
              push_lex_mode(parser, (yp_lex_mode_t) { .mode = YP_LEX_EMBEXPR });
              return YP_TOKEN_EMBEXPR_BEGIN;
          }
        }

        parser->current.end++;
      }

      // Otherwise, fall back to error recovery.
      return parser->error_handler->unterminated_regexp(parser);
    }
    case YP_LEX_STRING: {
      // First, we'll set to start of this token to be the current end.
      parser->current.start = parser->current.end;

      // If we've hit the end of the string, then we can return to the default
      // state of the lexer and return a string ending token.
      if (match(parser, parser->lex_modes.current->term)) {
        pop_lex_mode(parser);
        return YP_TOKEN_STRING_END;
      }

      // Otherwise, we'll lex as far as we can into the string. If we hit the
      // end of the string, then we'll return everything up to that point.
      while (parser->current.end < parser->end) {
        // If we hit the terminator, then return this element of the string.
        if (*parser->current.end == parser->lex_modes.current->term) {
          return YP_TOKEN_STRING_CONTENT;
        }

        // If we hit a newline, make sure to do the required bookkeeping.
        if (*parser->current.end == '\n') parser->lineno++;

        // If our current lex state allows interpolation and we've hit a #, then
        // check if it's used as the beginning of either an embedded variable or
        // an embedded expression.
        if (parser->lex_modes.current->interp && *parser->current.end == '#') {
          switch (parser->current.end[1]) {
            case '@':
              // In this case it could be an embedded instance or class
              // variable.
              break;
            case '$':
              // In this case it could be an embedded global variable.
              break;
            case '{':
              // In this case it's the start of an embedded expression.

              // If we have already consumed content, then we need to return
              // that content as string content first.
              if (parser->current.end > parser->current.start) {
                return YP_TOKEN_STRING_CONTENT;
              }

              parser->current.end += 2;
              push_lex_mode(parser, (yp_lex_mode_t) { .mode = YP_LEX_EMBEXPR });
              return YP_TOKEN_EMBEXPR_BEGIN;
          }
        }

        parser->current.end++;
      }

      // Otherwise, fall back to error recovery.
      return parser->error_handler->unterminated_string(parser);
    }
    case YP_LEX_SYMBOL: {
      // First, we'll set to start of this token to be the current end.
      parser->current.start = parser->current.end;

      // Lex as far as we can into the symbol.
      if (parser->current.end < parser->end && is_identifier_start_char(parser->current.end++)) {
        pop_lex_mode(parser);

        yp_token_type_t type = lex_identifier(parser);
        return match(parser, '=') ? YP_TOKEN_IDENTIFIER : type;
      }

      // If we get here then we have the start of a symbol with no content. In
      // that case return an invalid token.
      return YP_TOKEN_INVALID;
    }
  }

  // We shouldn't be able to get here at all, but some compilers can't figure
  // that out, so just returning a value here to make them happy.
  return YP_TOKEN_INVALID;
}

/******************************************************************************/
/* Parse functions                                                            */
/******************************************************************************/

// These are the various precedence rules. Because we are using a Pratt parser,
// they are named binding power to represent the manner in which nodes are bound
// together in the stack.
typedef enum {
  BINDING_POWER_NONE = 1,
  BINDING_POWER_BRACES,          // braces
  BINDING_POWER_MODIFIER,        // if unless until while
  BINDING_POWER_COMPOSITION,     // and or
  BINDING_POWER_NOT,             // not
  BINDING_POWER_DEFINED,         // defined?
  BINDING_POWER_ASSIGNMENT,      // = += -= *= /= %= &= |= ^= &&= ||= <<= >>= **=
  BINDING_POWER_MODIFIER_RESCUE, // rescue
  BINDING_POWER_TERNARY,         // ?:
  BINDING_POWER_RANGE,           // .. ...
  BINDING_POWER_LOGICAL_OR,      // ||
  BINDING_POWER_LOGICAL_AND,     // &&
  BINDING_POWER_EQUALITY,        // <=> == === != =~ !~
  BINDING_POWER_COMPARISON,      // > >= < <=
  BINDING_POWER_BITWISE_OR,      // | ^
  BINDING_POWER_BITWISE_AND,     // &
  BINDING_POWER_SHIFT,           // << >>
  BINDING_POWER_TERM,            // + -
  BINDING_POWER_FACTOR,          // * / %
  BINDING_POWER_UMINUS,          // unary minus
  BINDING_POWER_EXPONENT,        // **
  BINDING_POWER_UNARY,           // ! ~ +
  BINDING_POWER_INDEX,           // [] []=
} binding_power_t;

// This struct represents a set of binding powers used for a given token. They
// are combined in this way to make it easier to represent associativity.
typedef struct {
  binding_power_t left;
  binding_power_t right;
} binding_powers_t;

#define LEFT_ASSOCIATIVE(precedence)                                                                                   \
  { precedence, precedence + 1 }
#define RIGHT_ASSOCIATIVE(precedence)                                                                                  \
  { precedence, precedence }

binding_powers_t binding_powers[YP_TOKEN_MAXIMUM] = {
  // ::
  [YP_TOKEN_COLON_COLON] = LEFT_ASSOCIATIVE(BINDING_POWER_NONE),

  // {}
  [YP_TOKEN_BRACE_LEFT] = LEFT_ASSOCIATIVE(BINDING_POWER_BRACES),

  // if unless until while
  [YP_TOKEN_KEYWORD_IF] = LEFT_ASSOCIATIVE(BINDING_POWER_MODIFIER),
  [YP_TOKEN_KEYWORD_UNLESS] = LEFT_ASSOCIATIVE(BINDING_POWER_MODIFIER),
  [YP_TOKEN_KEYWORD_UNTIL] = LEFT_ASSOCIATIVE(BINDING_POWER_MODIFIER),
  [YP_TOKEN_KEYWORD_WHILE] = LEFT_ASSOCIATIVE(BINDING_POWER_MODIFIER),

  // and or
  [YP_TOKEN_KEYWORD_AND] = LEFT_ASSOCIATIVE(BINDING_POWER_COMPOSITION),
  [YP_TOKEN_KEYWORD_OR] = LEFT_ASSOCIATIVE(BINDING_POWER_COMPOSITION),

  // not
  [YP_TOKEN_KEYWORD_NOT] = RIGHT_ASSOCIATIVE(BINDING_POWER_NOT),

  // defined?
  [YP_TOKEN_KEYWORD_DEFINED] = RIGHT_ASSOCIATIVE(BINDING_POWER_DEFINED),

  // &&= &= ^= = >>= <<= -= %= |= += /= *= **=
  [YP_TOKEN_AMPERSAND_AMPERSAND_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_AMPERSAND_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_CARET_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_GREATER_GREATER_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_LESS_LESS_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_MINUS_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_PERCENT_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_PIPE_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_PIPE_PIPE_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_PLUS_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_SLASH_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_STAR_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_STAR_STAR_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),

  // ?:
  [YP_TOKEN_QUESTION_MARK] = RIGHT_ASSOCIATIVE(BINDING_POWER_TERNARY),

  // .. ...
  [YP_TOKEN_DOT_DOT] = LEFT_ASSOCIATIVE(BINDING_POWER_RANGE),
  [YP_TOKEN_DOT_DOT_DOT] = LEFT_ASSOCIATIVE(BINDING_POWER_RANGE),

  // ||
  [YP_TOKEN_PIPE_PIPE] = LEFT_ASSOCIATIVE(BINDING_POWER_LOGICAL_OR),

  // &&
  [YP_TOKEN_AMPERSAND_AMPERSAND] = LEFT_ASSOCIATIVE(BINDING_POWER_LOGICAL_AND),

  // != !~ == === =~ <=>
  [YP_TOKEN_BANG_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_EQUALITY),
  [YP_TOKEN_BANG_TILDE] = RIGHT_ASSOCIATIVE(BINDING_POWER_EQUALITY),
  [YP_TOKEN_EQUAL_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_EQUALITY),
  [YP_TOKEN_EQUAL_EQUAL_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_EQUALITY),
  [YP_TOKEN_EQUAL_TILDE] = RIGHT_ASSOCIATIVE(BINDING_POWER_EQUALITY),
  [YP_TOKEN_LESS_EQUAL_GREATER] = RIGHT_ASSOCIATIVE(BINDING_POWER_EQUALITY),

  // > >= < <=
  [YP_TOKEN_GREATER] = RIGHT_ASSOCIATIVE(BINDING_POWER_COMPARISON),
  [YP_TOKEN_GREATER_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_COMPARISON),
  [YP_TOKEN_LESS] = RIGHT_ASSOCIATIVE(BINDING_POWER_COMPARISON),
  [YP_TOKEN_LESS_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_COMPARISON),

  // ^ |
  [YP_TOKEN_CARET] = RIGHT_ASSOCIATIVE(BINDING_POWER_BITWISE_OR),
  [YP_TOKEN_PIPE] = RIGHT_ASSOCIATIVE(BINDING_POWER_BITWISE_OR),

  // &
  [YP_TOKEN_AMPERSAND] = RIGHT_ASSOCIATIVE(BINDING_POWER_BITWISE_AND),

  // >> <<
  [YP_TOKEN_GREATER_GREATER] = RIGHT_ASSOCIATIVE(BINDING_POWER_SHIFT),
  [YP_TOKEN_LESS_LESS] = RIGHT_ASSOCIATIVE(BINDING_POWER_SHIFT),

  // - +
  [YP_TOKEN_MINUS] = LEFT_ASSOCIATIVE(BINDING_POWER_TERM),
  [YP_TOKEN_PLUS] = LEFT_ASSOCIATIVE(BINDING_POWER_TERM),

  // % / *
  [YP_TOKEN_PERCENT] = LEFT_ASSOCIATIVE(BINDING_POWER_FACTOR),
  [YP_TOKEN_SLASH] = LEFT_ASSOCIATIVE(BINDING_POWER_FACTOR),
  [YP_TOKEN_STAR] = LEFT_ASSOCIATIVE(BINDING_POWER_FACTOR),

  // **
  [YP_TOKEN_STAR_STAR] = RIGHT_ASSOCIATIVE(BINDING_POWER_EXPONENT),

  // ! ~
  [YP_TOKEN_BANG] = RIGHT_ASSOCIATIVE(BINDING_POWER_UNARY),
  [YP_TOKEN_TILDE] = RIGHT_ASSOCIATIVE(BINDING_POWER_UNARY),

  // []
  [YP_TOKEN_BRACKET_LEFT_RIGHT] = LEFT_ASSOCIATIVE(BINDING_POWER_INDEX),
};

#undef LEFT_ASSOCIATIVE
#undef RIGHT_ASSOCIATIVE

static bool
accept(yp_parser_t *parser, yp_token_type_t type) {
  if (parser->current.type == type) {
    yp_lex_token(parser);
    return true;
  }
  return false;
}

static bool
accept_any(yp_parser_t *parser, size_t count, ...) {
  va_list types;
  va_start(types, count);

  for (size_t index = 0; index < count; index++) {
    if (parser->current.type == va_arg(types, yp_token_type_t)) {
      yp_lex_token(parser);
      va_end(types);
      return true;
    }
  }

  va_end(types);
  return false;
}

// This function indicates that the parser expects a token in a specific
// position. For example, if you're parsing a BEGIN block, you know that a { is
// expected immediately after the keyword. In that case you would call this
// function to indicate that that token should be found.
//
// If we didn't find the token that we were expecting, then we're going to add
// an error to the parser's list of errors (to indicate that the tree is not
// valid) and create an artificial token instead. This allows us to recover from
// the fact that the token isn't present and continue parsing.
static void
expect(yp_parser_t *parser, yp_token_type_t type, const char *message) {
  if (accept(parser, type)) return;

  yp_error_list_append(&parser->error_list, message, parser->previous.end - parser->start);

  parser->previous = (yp_token_t) {
    .type = YP_TOKEN_MISSING,
    .start = parser->previous.end,
    .end = parser->previous.end
  };
}

static yp_node_t *
parse_expression(yp_parser_t *parser, binding_power_t binding_power);

static yp_node_t *
parse_statements(yp_parser_t *parser, yp_token_type_t terminator) {
  yp_node_t *statements = yp_node_statements_create(parser);
  bool parsing = true;

  while (parsing && parser->current.type != terminator) {
    yp_node_t *node = parse_expression(parser, BINDING_POWER_NONE);
    yp_node_list_append(parser, statements, &statements->as.statements.body, node);
    if (!accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON)) parsing = false;
  }

  return statements;
}

// Parse a list of arguments to a keyword like `break`.
void
parse_arguments(yp_parser_t *parser, yp_node_t *arguments) {
  if (!accept(parser, YP_TOKEN_PARENTHESIS_RIGHT)) {
    while (true) {
      yp_node_t *expression = parse_expression(parser, BINDING_POWER_NONE);
      yp_node_list_append(parser, arguments, &arguments->as.arguments_node.arguments, expression);

      if (accept(parser, YP_TOKEN_PARENTHESIS_RIGHT)) break;
      expect(parser, YP_TOKEN_COMMA, "Expected an ',' to delimit arguments.");
    }
  }
}

static yp_node_t *
parse_expression(yp_parser_t *parser, binding_power_t binding_power) {
  // If this is the end of the file, then return immediately.
  if (parser->current.type == YP_TOKEN_EOF) {
    return NULL;
  }

  yp_lex_token(parser);
  yp_node_t *node;

  // Check the type of the token that we just lexed. If it's possible for this
  // token to be in the prefix position, we'll parse it as such. Otherwise we'll
  // return.
  switch (parser->previous.type) {
    case YP_TOKEN_CHARACTER_LITERAL:
      node = yp_node_character_literal_create(parser, &parser->previous);
      break;
    case YP_TOKEN_CLASS_VARIABLE:
      node = yp_node_class_variable_read_create(parser, &parser->previous);
      break;
    case YP_TOKEN_CONSTANT:
      node = yp_node_constant_read_create(parser, &parser->previous);
      break;
    case YP_TOKEN_FLOAT:
      node = yp_node_float_literal_create(parser, &parser->previous);
      break;
    case YP_TOKEN_GLOBAL_VARIABLE:
      node = yp_node_global_variable_read_create(parser, &parser->previous);
      break;
    case YP_TOKEN_IDENTIFIER:
      if (yp_token_list_includes(&parser->current_scope->as.scope.locals, &parser->previous)) {
        node = yp_node_local_variable_read_create(parser, &parser->previous);
      } else {
        yp_string_t *name = yp_string_alloc();
        yp_string_shared_init(name, parser->previous.start, parser->previous.end);

        node = yp_node_call_node_create(parser, NULL, &parser->previous, NULL, name);
      }
      break;
    case YP_TOKEN_IMAGINARY_NUMBER:
      node = yp_node_imaginary_literal_create(parser, &parser->previous);
      break;
    case YP_TOKEN_INSTANCE_VARIABLE:
      node = yp_node_instance_variable_read_create(parser, &parser->previous);
      break;
    case YP_TOKEN_INTEGER:
      node = yp_node_integer_literal_create(parser, &parser->previous);
      break;
    case YP_TOKEN_KEYWORD_BEGIN_UPCASE: {
      yp_token_t keyword = parser->previous;
      expect(parser, YP_TOKEN_BRACE_LEFT, "Expected '{' after 'BEGIN'.");
      yp_token_t opening = parser->previous;

      yp_node_t *statements = parse_statements(parser, YP_TOKEN_BRACE_RIGHT);
      expect(parser, YP_TOKEN_BRACE_RIGHT, "Expected '}' after 'BEGIN' statements.");
      yp_token_t closing = parser->previous;

      node = yp_node_pre_execution_node_create(parser, &keyword, &opening, statements, &closing);
      break;
    }
    case YP_TOKEN_KEYWORD_BREAK:
    case YP_TOKEN_KEYWORD_NEXT:
    case YP_TOKEN_KEYWORD_SUPER:
    case YP_TOKEN_KEYWORD_YIELD: {
      yp_token_t keyword = parser->previous;
      yp_token_t lparen = (yp_token_t) { .type = YP_TOKEN_NOT_PROVIDED };
      yp_node_t *arguments = NULL;
      yp_token_t rparen = (yp_token_t) { .type = YP_TOKEN_NOT_PROVIDED };

      if (accept(parser, YP_TOKEN_PARENTHESIS_LEFT)) {
        lparen = parser->previous;
        arguments = yp_node_arguments_node_create(parser);
        parse_arguments(parser, arguments);
        rparen = parser->previous;
      }

      switch (keyword.type) {
        case YP_TOKEN_KEYWORD_BREAK:
          node = yp_node_break_node_create(parser, &keyword, &lparen, arguments, &rparen);
          break;
        case YP_TOKEN_KEYWORD_NEXT:
          node = yp_node_next_node_create(parser, &keyword, &lparen, arguments, &rparen);
          break;
        case YP_TOKEN_KEYWORD_SUPER:
          if (arguments == NULL) {
            node = yp_node_forwarding_super_node_create(parser, &keyword);
          } else {
            node = yp_node_super_node_create(parser, &keyword, &lparen, arguments, &rparen);
          }
          break;
        case YP_TOKEN_KEYWORD_YIELD:
          node = yp_node_yield_node_create(parser, &keyword, &lparen, arguments, &rparen);
          break;
        default:
          // Cannot hit here.
          break;
      }

      break;
    }
    case YP_TOKEN_KEYWORD_CLASS: {
      yp_token_t class_keyword = parser->previous;
      yp_node_t *name = parse_expression(parser, BINDING_POWER_NONE);

      yp_node_t *scope = yp_node_scope_create(parser);
      yp_node_t *parent_scope = parser->current_scope;
      parser->current_scope = scope;

      yp_node_t *statements = parse_statements(parser, YP_TOKEN_KEYWORD_END);
      expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close `class` statement.");

      node = yp_node_class_node_create(parser, scope, &class_keyword, name, statements, &parser->previous);
      parser->current_scope = parent_scope;
      break;
    }
    case YP_TOKEN_KEYWORD_END_UPCASE: {
      yp_token_t keyword = parser->previous;
      expect(parser, YP_TOKEN_BRACE_LEFT, "Expected '{' after 'END'.");
      yp_token_t opening = parser->previous;

      yp_node_t *statements = parse_statements(parser, YP_TOKEN_BRACE_RIGHT);
      expect(parser, YP_TOKEN_BRACE_RIGHT, "Expected '}' after 'END' statements.");
      yp_token_t closing = parser->previous;

      node = yp_node_post_execution_node_create(parser, &keyword, &opening, statements, &closing);
      break;
    }
    case YP_TOKEN_KEYWORD_FALSE:
      node = yp_node_false_node_create(parser, &parser->previous);
      break;
    case YP_TOKEN_KEYWORD_IF: {
      yp_token_t keyword = parser->previous;

      yp_node_t *predicate = parse_expression(parser, BINDING_POWER_NONE);
      accept_any(parser, 3, YP_TOKEN_KEYWORD_THEN, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

      yp_node_t *statements = parse_statements(parser, YP_TOKEN_KEYWORD_END);
      accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

      expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close `if` statement.");

      node = yp_node_if_node_create(parser, &keyword, predicate, statements);
      break;
    }
    case YP_TOKEN_KEYWORD_MODULE: {
      yp_token_t module_keyword = parser->previous;
      yp_node_t *name = parse_expression(parser, BINDING_POWER_NONE);

      yp_node_t *scope = yp_node_scope_create(parser);
      yp_node_t *parent_scope = parser->current_scope;
      parser->current_scope = scope;

      yp_node_t *statements = parse_statements(parser, YP_TOKEN_KEYWORD_END);
      expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close `module` statement.");

      node = yp_node_module_node_create(parser, scope, &module_keyword, name, statements, &parser->previous);
      parser->current_scope = parent_scope;
      break;
    }
    case YP_TOKEN_KEYWORD_NIL:
      node = yp_node_nil_node_create(parser, &parser->previous);
      break;
    case YP_TOKEN_KEYWORD_REDO:
      node = yp_node_redo_node_create(parser, &parser->previous);
      break;
    case YP_TOKEN_KEYWORD_RETRY:
      node = yp_node_retry_node_create(parser, &parser->previous);
      break;
    case YP_TOKEN_KEYWORD_SELF:
      node = yp_node_self_node_create(parser, &parser->previous);
      break;
    case YP_TOKEN_KEYWORD_TRUE:
      node = yp_node_true_node_create(parser, &parser->previous);
      break;
    case YP_TOKEN_KEYWORD_UNLESS: {
      yp_token_t keyword = parser->previous;

      yp_node_t *predicate = parse_expression(parser, BINDING_POWER_NONE);
      accept_any(parser, 3, YP_TOKEN_KEYWORD_THEN, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

      yp_node_t *statements = parse_statements(parser, YP_TOKEN_KEYWORD_END);
      accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

      expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close `unless` statement.");

      node = yp_node_unless_node_create(parser, &keyword, predicate, statements);
      break;
    }
    case YP_TOKEN_KEYWORD_UNTIL: {
      yp_token_t keyword = parser->previous;

      yp_node_t *predicate = parse_expression(parser, BINDING_POWER_NONE);
      accept_any(parser, 3, YP_TOKEN_KEYWORD_THEN, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

      yp_node_t *statements = parse_statements(parser, YP_TOKEN_KEYWORD_END);
      accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

      expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close `until` statement.");

      node = yp_node_until_node_create(parser, &keyword, predicate, statements);
      break;
    }
    case YP_TOKEN_KEYWORD_WHILE: {
      yp_token_t keyword = parser->previous;

      yp_node_t *predicate = parse_expression(parser, BINDING_POWER_NONE);
      accept_any(parser, 3, YP_TOKEN_KEYWORD_THEN, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

      yp_node_t *statements = parse_statements(parser, YP_TOKEN_KEYWORD_END);
      accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

      expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close `while` statement.");

      node = yp_node_while_node_create(parser, &keyword, predicate, statements);
      break;
    }
    case YP_TOKEN_PERCENT_LOWER_I: {
      yp_token_t opening = parser->previous;
      yp_node_t *symbol_list = yp_node_symbol_list_node_create(parser, &opening, &opening);

      while (parser->current.type != YP_TOKEN_STRING_END) {
        if (symbol_list->as.symbol_list_node.symbols.size == 0) {
          accept(parser, YP_TOKEN_WORDS_SEP);
        } else {
          expect(parser, YP_TOKEN_WORDS_SEP, "Expected a separator for the symbols in a `%i` list.");
        }
        expect(parser, YP_TOKEN_STRING_CONTENT, "Expected a symbol in a `%i` list.");
        yp_node_list_append(parser, symbol_list, &symbol_list->as.symbol_list_node.symbols,
                            yp_node_symbol_node_create(parser, &parser->previous));
      }

      expect(parser, YP_TOKEN_STRING_END, "Expected a closing delimiter for a `%i` list.");
      symbol_list->as.symbol_list_node.closing = parser->previous;

      node = symbol_list;
      break;
    }
    case YP_TOKEN_PERCENT_LOWER_W: {
      yp_token_t opening = parser->previous;
      node = yp_node_string_list_node_create(parser, &opening, &opening);

      while (parser->current.type != YP_TOKEN_STRING_END) {
        if (node->as.string_list_node.strings.size == 0) {
          accept(parser, YP_TOKEN_WORDS_SEP);
        } else {
          expect(parser, YP_TOKEN_WORDS_SEP, "Expected a separator for the strings in a `%w` list.");
        }
        expect(parser, YP_TOKEN_STRING_CONTENT, "Expected a string in a `%w` list.");

        yp_token_t delimiter = (yp_token_t) { .type = YP_TOKEN_NOT_PROVIDED };
        yp_node_t *string = yp_node_string_node_create(parser, &delimiter, &delimiter);
        yp_node_t *string_content = yp_node_string_content_node_create(parser, &parser->previous);

        yp_node_list_append(parser, string, &string->as.string_node.parts, string_content);
        yp_node_list_append(parser, node, &node->as.string_list_node.strings, string);
      }

      expect(parser, YP_TOKEN_STRING_END, "Expected a closing delimiter for a `%w` list.");
      node->as.string_list_node.closing = parser->previous;
      break;
    }
    case YP_TOKEN_RATIONAL_NUMBER:
      node = yp_node_rational_literal_create(parser, &parser->previous);
      break;
    case YP_TOKEN_BANG:
    case YP_TOKEN_TILDE: {
      yp_token_t operator_token = parser->previous;
      yp_node_t *receiver = parse_expression(parser, binding_powers[parser->previous.type].right);

      yp_string_t *name = yp_string_alloc();
      yp_string_shared_init(name, operator_token.start, operator_token.end);

      node = yp_node_call_node_create(parser, receiver, &operator_token, NULL, name);
      break;
    }
    case YP_TOKEN_MINUS: {
      yp_token_t operator_token = parser->previous;
      yp_node_t *receiver = parse_expression(parser, binding_powers[parser->previous.type].right);

      yp_string_t *name = yp_string_alloc();
      yp_string_constant_init(name, "-@", 2);

      node = yp_node_call_node_create(parser, receiver, &operator_token, NULL, name);
      break;
    }
    case YP_TOKEN_PLUS: {
      yp_token_t operator_token = parser->previous;
      yp_node_t *receiver = parse_expression(parser, binding_powers[parser->previous.type].right);

      yp_string_t *name = yp_string_alloc();
      yp_string_constant_init(name, "+@", 2);

      node = yp_node_call_node_create(parser, receiver, &operator_token, NULL, name);
      break;
    }
    default:
      fprintf(stderr, "Could not understand token type %s in the prefix position\n",
              yp_token_type_to_str(parser->previous.type));
      return NULL;
  }

  // While the current token has a higher binding power than the one we've just
  // parsed, we'll continue parsing forward and replace the current node we're
  // working with.
  yp_token_t token;
  binding_powers_t token_binding_powers;

  while (token = parser->current, token_binding_powers = binding_powers[token.type],
         binding_power <= token_binding_powers.left) {
    yp_lex_token(parser);

    switch (token.type) {
      case YP_TOKEN_EQUAL: {
        switch (node->type) {
          case YP_NODE_CLASS_VARIABLE_READ: {
            yp_node_t *value = parse_expression(parser, token_binding_powers.right);
            yp_node_t *read = node;

            node = yp_node_class_variable_write_create(parser, &node->as.class_variable_read.name, &token, value);
            yp_node_destroy(parser, read);
            break;
          }
          case YP_NODE_GLOBAL_VARIABLE_READ: {
            yp_node_t *value = parse_expression(parser, token_binding_powers.right);
            yp_node_t *read = node;

            node = yp_node_global_variable_write_create(parser, &node->as.global_variable_read.name, &token, value);
            yp_node_destroy(parser, read);
            break;
          }
          case YP_NODE_LOCAL_VARIABLE_READ: {
            yp_node_t *value = parse_expression(parser, token_binding_powers.right);
            yp_node_t *read = node;

            yp_token_t name = node->as.local_variable_read.name;
            yp_token_list_append(&parser->current_scope->as.scope.locals, &name);

            node = yp_node_local_variable_write_create(parser, &name, &token, value);
            yp_node_destroy(parser, read);

            break;
          }
          case YP_NODE_INSTANCE_VARIABLE_READ: {
            yp_node_t *value = parse_expression(parser, token_binding_powers.right);
            yp_node_t *read = node;

            node = yp_node_instance_variable_write_create(parser, &node->as.instance_variable_read.name, &token, value);
            yp_node_destroy(parser, read);
            break;
          }
          case YP_NODE_CALL_NODE: {
            if (node->as.call_node.receiver == NULL && node->as.call_node.arguments == NULL) {
              yp_node_t *value = parse_expression(parser, token_binding_powers.right);
              yp_node_t *read = node;

              yp_token_t name = node->as.call_node.message;
              yp_token_list_append(&parser->current_scope->as.scope.locals, &name);

              node = yp_node_local_variable_write_create(parser, &name, &token, value);
              yp_node_destroy(parser, read);
              break;
            }
            // fallthrough
          }
          default: {
            yp_node_t *value = parse_expression(parser, token_binding_powers.right);
            yp_node_t *arguments = yp_node_arguments_node_create(parser);
            yp_node_list_append(parser, arguments, &arguments->as.arguments_node.arguments, value);

            int length = node->location.end - node->location.start;
            yp_string_t *name = yp_string_alloc();
            yp_string_owned_init(name, malloc(length + 1), length + 1);
            sprintf(name->as.owned.source, "%.*s=", length, parser->start + node->location.start);

            node = yp_node_call_node_create(parser, node, &token, arguments, name);
            break;
          }
        }
        break;
      }
      case YP_TOKEN_AMPERSAND_AMPERSAND_EQUAL: {
        yp_node_t *value = parse_expression(parser, token_binding_powers.right);
        node = yp_node_operator_and_assignment_node_create(parser, node, &token, value);
        break;
      }
      case YP_TOKEN_PIPE_PIPE_EQUAL: {
        yp_node_t *value = parse_expression(parser, token_binding_powers.right);
        node = yp_node_operator_or_assignment_node_create(parser, node, &token, value);
        break;
      }
      case YP_TOKEN_AMPERSAND_EQUAL:
      case YP_TOKEN_CARET_EQUAL:
      case YP_TOKEN_GREATER_GREATER_EQUAL:
      case YP_TOKEN_LESS_LESS_EQUAL:
      case YP_TOKEN_MINUS_EQUAL:
      case YP_TOKEN_PERCENT_EQUAL:
      case YP_TOKEN_PIPE_EQUAL:
      case YP_TOKEN_PLUS_EQUAL:
      case YP_TOKEN_SLASH_EQUAL:
      case YP_TOKEN_STAR_EQUAL:
      case YP_TOKEN_STAR_STAR_EQUAL: {
        yp_node_t *value = parse_expression(parser, token_binding_powers.right);
        node = yp_node_operator_assignment_node_create(parser, node, &token, value);
        break;
      }
      case YP_TOKEN_AMPERSAND_AMPERSAND:
      case YP_TOKEN_KEYWORD_AND: {
        yp_node_t *right = parse_expression(parser, token_binding_powers.right);
        node = yp_node_and_node_create(parser, node, &token, right);
        break;
      }
      case YP_TOKEN_KEYWORD_OR:
      case YP_TOKEN_PIPE_PIPE: {
        yp_node_t *right = parse_expression(parser, token_binding_powers.right);
        node = yp_node_or_node_create(parser, node, &token, right);
        break;
      }
      case YP_TOKEN_BANG_EQUAL:
      case YP_TOKEN_BANG_TILDE:
      case YP_TOKEN_EQUAL_EQUAL:
      case YP_TOKEN_EQUAL_EQUAL_EQUAL:
      case YP_TOKEN_EQUAL_TILDE:
      case YP_TOKEN_LESS_EQUAL_GREATER:
      case YP_TOKEN_GREATER:
      case YP_TOKEN_GREATER_EQUAL:
      case YP_TOKEN_LESS:
      case YP_TOKEN_LESS_EQUAL:
      case YP_TOKEN_CARET:
      case YP_TOKEN_PIPE:
      case YP_TOKEN_AMPERSAND:
      case YP_TOKEN_GREATER_GREATER:
      case YP_TOKEN_LESS_LESS:
      case YP_TOKEN_MINUS:
      case YP_TOKEN_PLUS:
      case YP_TOKEN_PERCENT:
      case YP_TOKEN_SLASH:
      case YP_TOKEN_STAR:
      case YP_TOKEN_STAR_STAR: {
        yp_node_t *arguments = yp_node_arguments_node_create(parser);
        yp_node_t *argument = parse_expression(parser, token_binding_powers.right);
        yp_node_list_append(parser, arguments, &arguments->as.arguments_node.arguments, argument);

        yp_string_t *name = yp_string_alloc();
        yp_string_shared_init(name, token.start, token.end);

        node = yp_node_call_node_create(parser, node, &token, arguments, name);
        break;
      }
      case YP_TOKEN_KEYWORD_IF: {
        yp_node_t *statements = yp_node_statements_create(parser);
        yp_node_list_append(parser, statements, &statements->as.statements.body, node);

        yp_node_t *predicate = parse_expression(parser, token_binding_powers.right);
        node = yp_node_if_node_create(parser, &token, predicate, statements);
        break;
      }
      case YP_TOKEN_KEYWORD_UNLESS: {
        yp_node_t *statements = yp_node_statements_create(parser);
        yp_node_list_append(parser, statements, &statements->as.statements.body, node);

        yp_node_t *predicate = parse_expression(parser, token_binding_powers.right);
        node = yp_node_unless_node_create(parser, &token, predicate, statements);
        break;
      }
      case YP_TOKEN_KEYWORD_UNTIL: {
        yp_node_t *statements = yp_node_statements_create(parser);
        yp_node_list_append(parser, statements, &statements->as.statements.body, node);

        yp_node_t *predicate = parse_expression(parser, token_binding_powers.right);
        node = yp_node_until_node_create(parser, &token, predicate, statements);
        break;
      }
      case YP_TOKEN_KEYWORD_WHILE: {
        yp_node_t *statements = yp_node_statements_create(parser);
        yp_node_list_append(parser, statements, &statements->as.statements.body, node);

        yp_node_t *predicate = parse_expression(parser, token_binding_powers.right);
        node = yp_node_while_node_create(parser, &token, predicate, statements);
        break;
      }
      case YP_TOKEN_QUESTION_MARK: {
        yp_node_t *true_expression = parse_expression(parser, token_binding_powers.right);
        expect(parser, YP_TOKEN_COLON, "Expected ':' after true expression in ternary operator.");

        yp_token_t colon = parser->previous;
        yp_node_t *false_expression = parse_expression(parser, token_binding_powers.right);

        node = yp_node_ternary_create(parser, node, &token, true_expression, &colon, false_expression);
        break;
      }
      case YP_TOKEN_COLON_COLON: {
        yp_token_t delimiter = parser->previous;

        switch (parser->current.type) {
          case YP_TOKEN_CONSTANT: {
            yp_node_t *child = parse_expression(parser, BINDING_POWER_NONE);
            node = yp_node_constant_path_node_create(parser, node, &delimiter, child);
            break;
          }
          case YP_TOKEN_IDENTIFIER: {
            yp_node_t *call = parse_expression(parser, BINDING_POWER_NONE);
            call->as.call_node.receiver = node;
            node = call;
            break;
          }
          default: {
            // TODO: return missing node here
            fprintf(stderr, "Expected identifier or constant after '::', got %s.\n", yp_token_type_to_str(parser->current.type));
          }
        }

        break;
      }
      default:
        return node;
    }
  }

  return node;
}

static yp_node_t *
parse_program(yp_parser_t *parser) {
  yp_lex_token(parser);

  yp_node_t *scope = yp_node_scope_create(parser);
  parser->current_scope = scope;

  return yp_node_program_create(parser, scope, parse_statements(parser, YP_TOKEN_EOF));
}

/******************************************************************************/
/* External functions                                                         */
/******************************************************************************/

// By default, the parser won't attempt to recover from syntax errors at all.
// This function provides that implementation.
static yp_token_type_t
unrecoverable(yp_parser_t *parser) {
  return YP_TOKEN_EOF;
}

// This is the default error handler, which does not actually attempt to recover
// from any errors.
yp_error_handler_t default_error_handler = {
  .unterminated_embdoc = unrecoverable,
  .unterminated_list = unrecoverable,
  .unterminated_regexp = unrecoverable,
  .unterminated_string = unrecoverable,
};

// Initialize a parser with the given start and end pointers.
__attribute__((__visibility__("default"))) extern void
yp_parser_init(yp_parser_t *parser, const char *source, off_t size) {
  *parser = (yp_parser_t) {
    .lex_modes =
      {
        .index = 0,
        .stack = {{.mode = YP_LEX_DEFAULT}},
        .current = &parser->lex_modes.stack[0],
      },
    .start = source,
    .end = source + size,
    .current = {.start = source, .end = source},
    .lineno = 1,
    .error_handler = &default_error_handler,
    .current_scope = NULL
  };

  yp_error_list_init(&parser->error_list);
}

// Free any memory associated with the given parser.
__attribute__((__visibility__("default"))) extern void
yp_parser_free(yp_parser_t *parser) {
  yp_error_list_free(&parser->error_list);
}

// Get the next token type and set its value on the current pointer.
__attribute__((__visibility__("default"))) extern void
yp_lex_token(yp_parser_t *parser) {
  parser->previous = parser->current;
  parser->current.type = lex_token_type(parser);
}

// Parse the Ruby source associated with the given parser and return the tree.
__attribute__((__visibility__("default"))) extern yp_node_t *
yp_parse(yp_parser_t *parser) {
  return parse_program(parser);
}

__attribute__((__visibility__("default"))) extern void
yp_serialize(yp_parser_t *parser, yp_node_t *node, yp_buffer_t *buffer) {
  yp_buffer_append_str(buffer, "YARP", 4);
  yp_buffer_append_u8(buffer, YP_VERSION_MAJOR);
  yp_buffer_append_u8(buffer, YP_VERSION_MINOR);
  yp_buffer_append_u8(buffer, YP_VERSION_PATCH);

  yp_serialize_node(parser, node, buffer);
  yp_buffer_append_str(buffer, "\0", 1);
}
