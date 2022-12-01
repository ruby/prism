#include "regexp.h"

// These are all of the potential types of tokens in the regular expression AST.
typedef enum {
  YP_REGEXP_TOKEN_EOF,
  YP_REGEXP_TOKEN_DOT,
  YP_REGEXP_TOKEN_STAR,
  YP_REGEXP_TOKEN_PLUS,
  YP_REGEXP_TOKEN_QMARK,
  YP_REGEXP_TOKEN_PIPE,
  YP_REGEXP_TOKEN_LBRACE,
  YP_REGEXP_TOKEN_RBRACE,
  YP_REGEXP_TOKEN_LPAREN,
  YP_REGEXP_TOKEN_RPAREN,
  YP_REGEXP_TOKEN_LBRACKET,
  YP_REGEXP_TOKEN_RBRACKET,
  YP_REGEXP_TOKEN_DASH,
  YP_REGEXP_TOKEN_COMMA,
  YP_REGEXP_TOKEN_CARET,
  YP_REGEXP_TOKEN_DOLLAR,
  YP_REGEXP_TOKEN_COLON,
  YP_REGEXP_TOKEN_BACKSLASH,
  YP_REGEXP_TOKEN_CHAR,
  YP_REGEXP_TOKEN_INVALID
} yp_regexp_token_type_t;

// This is a token in the regular expression AST.
typedef struct {
  yp_regexp_token_type_t type;
  const char *start;
  const char *end;
} yp_regexp_token_t;

// This is the parser that is going to handle parsing regular expressions.
typedef struct {
  const char *start;
  const char *end;
  yp_encoding_t encoding;
  yp_regexp_token_t previous;
  yp_regexp_token_t current;
  yp_string_list_t *named_captures;
} yp_regexp_parser_t;

// This initializes a new parser with the given source.
static void
yp_regexp_parser_init(yp_regexp_parser_t *parser, const char *start, const char *end, yp_encoding_t *encoding, yp_string_list_t *named_captures) {
  *parser = (yp_regexp_parser_t) {
    .start = start,
    .end = end,
    .encoding = *encoding,
    .previous = { .type = YP_REGEXP_TOKEN_EOF, .start = start, .end = start },
    .current = { .type = YP_REGEXP_TOKEN_EOF, .start = start, .end = start },
    .named_captures = named_captures
  };
}

// This appends a new string to the list of named captures.
static void
yp_regexp_parser_named_capture(yp_regexp_parser_t *parser, const char *start, const char *end) {
  yp_string_t string;
  yp_string_shared_init(&string, start, end);
  yp_string_list_append(parser->named_captures, &string);
  yp_string_free(&string);
}

// This advances the parser to the next token.
static void
yp_regexp_lex_token(yp_regexp_parser_t *parser) {
  parser->previous = parser->current;

  if (parser->current.end >= parser->end) {
    parser->current.type = YP_REGEXP_TOKEN_EOF;
    return;
  }

  switch (*parser->current.end++) {
    case '.':  parser->current.type = YP_REGEXP_TOKEN_DOT;       return;
    case '*':  parser->current.type = YP_REGEXP_TOKEN_STAR;      return;
    case '+':  parser->current.type = YP_REGEXP_TOKEN_PLUS;      return;
    case '?':  parser->current.type = YP_REGEXP_TOKEN_QMARK;     return;
    case '|':  parser->current.type = YP_REGEXP_TOKEN_PIPE;      return;
    case '{':  parser->current.type = YP_REGEXP_TOKEN_LBRACE;    return;
    case '}':  parser->current.type = YP_REGEXP_TOKEN_RBRACE;    return;
    case '(':  parser->current.type = YP_REGEXP_TOKEN_LPAREN;    return;
    case ')':  parser->current.type = YP_REGEXP_TOKEN_RPAREN;    return;
    case '[':  parser->current.type = YP_REGEXP_TOKEN_LBRACKET;  return;
    case ']':  parser->current.type = YP_REGEXP_TOKEN_RBRACKET;  return;
    case '-':  parser->current.type = YP_REGEXP_TOKEN_DASH;      return;
    case ',':  parser->current.type = YP_REGEXP_TOKEN_COMMA;     return;
    case '^':  parser->current.type = YP_REGEXP_TOKEN_CARET;     return;
    case '$':  parser->current.type = YP_REGEXP_TOKEN_DOLLAR;    return;
    case ':':  parser->current.type = YP_REGEXP_TOKEN_COLON;     return;
    case '\\': parser->current.type = YP_REGEXP_TOKEN_BACKSLASH; return;
    default: {
      size_t size = parser->encoding.char_size(parser->current.end - 1);
      if (size == 0) {
        parser->current.type = YP_REGEXP_TOKEN_INVALID;
        return;
      }

      parser->current.end += size - 1;
      parser->current.type = YP_REGEXP_TOKEN_CHAR;
      return;
    }
  }
}

// Optionally accept a token and consume it if it exists.
static void
yp_regexp_accept_token(yp_regexp_parser_t *parser, yp_regexp_token_type_t type) {
  if (parser->current.type == type) {
    yp_regexp_lex_token(parser);
  }
}

// Expect a token to be present and consume it.
static yp_regexp_parse_result_t
yp_regexp_expect_token(yp_regexp_parser_t *parser, yp_regexp_token_type_t type) {
  if (parser->current.type == type) {
    yp_regexp_lex_token(parser);
    return YP_REGEXP_PARSE_RESULT_OK;
  }
  return YP_REGEXP_PARSE_RESULT_ERROR;
}

// This represents a point in time for the parser. It's used to backtrack in
// case that becomes necessary.
typedef struct {
  yp_regexp_token_t previous;
  yp_regexp_token_t current;
} yp_regexp_parser_savepoint_t;

// Initialize a new savepoint from the parser.
static void
yp_regexp_parser_savepoint_init(yp_regexp_parser_savepoint_t *savepoint, yp_regexp_parser_t *parser) {
  *savepoint = (yp_regexp_parser_savepoint_t) {
    .previous = parser->previous,
    .current = parser->current
  };
}

// Restore the parser to a previous savepoint.
static void
yp_regexp_parser_savepoint_restore(yp_regexp_parser_savepoint_t *savepoint, yp_regexp_parser_t *parser) {
  parser->previous = savepoint->previous;
  parser->current = savepoint->current;
}

// Returns true if the current token is a decimal digit character.
static bool
yp_regexp_is_char_digit(yp_regexp_parser_t *parser) {
  const char *value = parser->current.start;
  return (value + 1 == parser->current.end) && (*value >= '0') && (*value <= '9');
}

// Range quantifiers are a special class of quantifiers that look like
// 
// * {digit}
// * {digit,}
// * {digit,digit}
// * {,digit}
//
// Unfortunately, if there are any spaces in between, then this just becomes a
// regular character match expression and we have to backtrack. So when this
// function first starts running, we'll create a "save" point and then attempt
// to parse the quantifier. If it fails, we'll restore the save point and
// return.
//
// The properly track everything, we're going to build a little state machine.
// It looks something like the following:
//
//                  ┌───────┐                 ┌─────────┐ ────────────┐
// ──── lbrace ───> │ start │ ──── digit ───> │ minimum │             │
//                  └───────┘                 └─────────┘ <─── digit ─┘
//                      │                       │    │
//   ┌───────┐          │                       │  rbrace
//   │ comma │ <───── comma  ┌──── comma ───────┘    │
//   └───────┘               V                       V
//      │             ┌─────────┐               ┌─────────┐
//      └── digit ──> │ maximum │ ── rbrace ──> │| final |│
//                    └─────────┘               └─────────┘
//                    │         ^
//                    └─ digit ─┘
//
// Note that by the time we've hit this function, the lbrace has already been
// consumed so we're in the start state.
static yp_regexp_parse_result_t
yp_regexp_parse_range_quantifier(yp_regexp_parser_t *parser) {
  yp_regexp_parser_savepoint_t savepoint;
  yp_regexp_parser_savepoint_init(&savepoint, parser);

  enum {
    YP_REGEXP_RANGE_QUANTIFIER_STATE_START,
    YP_REGEXP_RANGE_QUANTIFIER_STATE_MINIMUM,
    YP_REGEXP_RANGE_QUANTIFIER_STATE_MAXIMUM,
    YP_REGEXP_RANGE_QUANTIFIER_STATE_COMMA
  } state = YP_REGEXP_RANGE_QUANTIFIER_STATE_START;

  while (1) {
    switch (state) {
      case YP_REGEXP_RANGE_QUANTIFIER_STATE_START:
        switch (parser->current.type) {
          case YP_REGEXP_TOKEN_CHAR:
            if (yp_regexp_is_char_digit(parser)) {
              state = YP_REGEXP_RANGE_QUANTIFIER_STATE_MINIMUM;
              break;
            } else {
              yp_regexp_parser_savepoint_restore(&savepoint, parser);
              return YP_REGEXP_PARSE_RESULT_OK;
            }
          case YP_REGEXP_TOKEN_COMMA:
            state = YP_REGEXP_RANGE_QUANTIFIER_STATE_COMMA;
            break;
          default:
            yp_regexp_parser_savepoint_restore(&savepoint, parser);
            return YP_REGEXP_PARSE_RESULT_OK;
        }
        break;
      case YP_REGEXP_RANGE_QUANTIFIER_STATE_MINIMUM:
        switch (parser->current.type) {
          case YP_REGEXP_TOKEN_CHAR:
            if (yp_regexp_is_char_digit(parser)) {
              break;
            } else {
              yp_regexp_parser_savepoint_restore(&savepoint, parser);
              return YP_REGEXP_PARSE_RESULT_OK;
            }
          case YP_REGEXP_TOKEN_COMMA:
            state = YP_REGEXP_RANGE_QUANTIFIER_STATE_MAXIMUM;
            break;
          case YP_REGEXP_TOKEN_RBRACE:
            return YP_REGEXP_PARSE_RESULT_OK;
          default:
            yp_regexp_parser_savepoint_restore(&savepoint, parser);
            return YP_REGEXP_PARSE_RESULT_OK;
        }
        break;
      case YP_REGEXP_RANGE_QUANTIFIER_STATE_COMMA:
        if ((parser->current.type == YP_REGEXP_TOKEN_CHAR) && yp_regexp_is_char_digit(parser)) {
          state = YP_REGEXP_RANGE_QUANTIFIER_STATE_MAXIMUM;
          break;
        } else {
          yp_regexp_parser_savepoint_restore(&savepoint, parser);
          return YP_REGEXP_PARSE_RESULT_OK;
        }
      case YP_REGEXP_RANGE_QUANTIFIER_STATE_MAXIMUM:
        switch (parser->current.type) {
          case YP_REGEXP_TOKEN_CHAR:
            if (yp_regexp_is_char_digit(parser)) {
              break;
            } else {
              yp_regexp_parser_savepoint_restore(&savepoint, parser);
              return YP_REGEXP_PARSE_RESULT_OK;
            }
          case YP_REGEXP_TOKEN_RBRACE:
            return YP_REGEXP_PARSE_RESULT_OK;
          default:
            yp_regexp_parser_savepoint_restore(&savepoint, parser);
            return YP_REGEXP_PARSE_RESULT_OK;
        }
        break;
    }
  }

  return YP_REGEXP_PARSE_RESULT_OK;
}

// quantifier : star-quantifier
//            | plus-quantifier
//            | optional-quantifier
//            | range-quantifier
//            | <empty>
//            ;
static yp_regexp_parse_result_t
yp_regexp_parse_quantifier(yp_regexp_parser_t *parser) {
  switch (parser->current.type) {
    case YP_REGEXP_TOKEN_STAR:
    case YP_REGEXP_TOKEN_PLUS:
    case YP_REGEXP_TOKEN_QMARK:
      yp_regexp_lex_token(parser);
      return YP_REGEXP_PARSE_RESULT_OK;
    case YP_REGEXP_TOKEN_LBRACE:
      yp_regexp_lex_token(parser);
      return yp_regexp_parse_range_quantifier(parser);
    default:
      // In this case there is no quantifier.
      return YP_REGEXP_PARSE_RESULT_OK;
  }
}

// match-posix-class : LBRACKET LBRACKET CARET? COLON CHAR+ COLON RBRACKET RBRACKET
//                   ;
static yp_regexp_parse_result_t
yp_regexp_parse_posix_class(yp_regexp_parser_t *parser) {
  yp_regexp_accept_token(parser, YP_REGEXP_TOKEN_CARET);

  if (yp_regexp_expect_token(parser, YP_REGEXP_TOKEN_COLON) == YP_REGEXP_PARSE_RESULT_ERROR) {
    return YP_REGEXP_PARSE_RESULT_ERROR;
  }

  while (parser->current.type == YP_REGEXP_TOKEN_CHAR) {
    yp_regexp_lex_token(parser);
  }

  if (
    (yp_regexp_expect_token(parser, YP_REGEXP_TOKEN_COLON) == YP_REGEXP_PARSE_RESULT_ERROR) ||
    (yp_regexp_expect_token(parser, YP_REGEXP_TOKEN_RBRACKET) == YP_REGEXP_PARSE_RESULT_ERROR) ||
    (yp_regexp_expect_token(parser, YP_REGEXP_TOKEN_RBRACKET) == YP_REGEXP_PARSE_RESULT_ERROR)
  ) {
    return YP_REGEXP_PARSE_RESULT_ERROR;
  }

  return YP_REGEXP_PARSE_RESULT_OK;
}

// match-char-set : LBRACKET CARET? (match-range | match-char)* RBRACKET
//                ;
static yp_regexp_parse_result_t
yp_regexp_parse_character_set(yp_regexp_parser_t *parser) {
  yp_regexp_accept_token(parser, YP_REGEXP_TOKEN_CARET);

  while (parser->current.type != YP_REGEXP_TOKEN_RBRACKET && parser->current.type != YP_REGEXP_TOKEN_EOF) {
    yp_regexp_lex_token(parser);
  }

  if (yp_regexp_expect_token(parser, YP_REGEXP_TOKEN_RBRACKET) == YP_REGEXP_PARSE_RESULT_ERROR) {
    return YP_REGEXP_PARSE_RESULT_ERROR;
  }

  return YP_REGEXP_PARSE_RESULT_OK;
}

// A left bracket can either mean a POSIX class or a character set.
static yp_regexp_parse_result_t
yp_regexp_parse_lbracket(yp_regexp_parser_t *parser) {
  if (parser->current.type == YP_REGEXP_TOKEN_LBRACKET) {
    yp_regexp_lex_token(parser);
    return yp_regexp_parse_posix_class(parser);
  }
  return yp_regexp_parse_character_set(parser);
}

// Forward declaration here since parsing groups needs to go back up the grammar
// to parse expressions within them.
static yp_regexp_parse_result_t
yp_regexp_parse_expression(yp_regexp_parser_t *parser);

// This advances the current token to the next instance of the given character.
static yp_regexp_parse_result_t
yp_regexp_find_char(yp_regexp_parser_t *parser, char value) {
  const char *end = (const char *) memchr(parser->current.end, value, parser->end - parser->current.end);
  if (end == NULL) {
    return YP_REGEXP_PARSE_RESULT_ERROR;
  }

  parser->current.end = end + 1;
  return YP_REGEXP_PARSE_RESULT_OK;
}

// These are the states of the options that are configurable on the regular
// expression (or from within a group).
typedef enum {
  YP_REGEXP_OPTION_STATE_INVALID,
  YP_REGEXP_OPTION_STATE_TOGGLEABLE,
  YP_REGEXP_OPTION_STATE_ADDABLE
} yp_regexp_option_state_t;

// This is the set of options that are configurable on the regular expression.
typedef yp_regexp_option_state_t yp_regexp_options_t[128];

// Initialize a new set of options to their default values.
static void
yp_regexp_options_init(yp_regexp_options_t *options) {
  memset(options, YP_REGEXP_OPTION_STATE_INVALID, sizeof(yp_regexp_option_state_t) * 128);
  (*options)['i'] = YP_REGEXP_OPTION_STATE_TOGGLEABLE;
  (*options)['m'] = YP_REGEXP_OPTION_STATE_TOGGLEABLE;
  (*options)['x'] = YP_REGEXP_OPTION_STATE_TOGGLEABLE;
  (*options)['d'] = YP_REGEXP_OPTION_STATE_ADDABLE;
  (*options)['a'] = YP_REGEXP_OPTION_STATE_ADDABLE;
  (*options)['u'] = YP_REGEXP_OPTION_STATE_ADDABLE;
}

// Attempt to add the given option to the set of options. Returns true if it was
// added, false if it was already present.
static bool
yp_regexp_options_add(yp_regexp_options_t *options, unsigned char option) {
  switch ((*options)[option]) {
    case YP_REGEXP_OPTION_STATE_INVALID:
      return false;
    case YP_REGEXP_OPTION_STATE_TOGGLEABLE:
    case YP_REGEXP_OPTION_STATE_ADDABLE:
      (*options)[option] = YP_REGEXP_OPTION_STATE_INVALID;
      return true;
  }
}

// Attempt to remove the given option from the set of options. Returns true if
// it was removed, false if it was already absent.
static bool
yp_regexp_options_remove(yp_regexp_options_t *options, unsigned char option) {
  switch ((*options)[option]) {
    case YP_REGEXP_OPTION_STATE_INVALID:
    case YP_REGEXP_OPTION_STATE_ADDABLE:
      return false;
    case YP_REGEXP_OPTION_STATE_TOGGLEABLE:
      (*options)[option] = YP_REGEXP_OPTION_STATE_INVALID;
      return true;
  }
}

// Groups can have quite a few different patterns for syntax. They basically
// just wrap a set of expressions, but they can potentially have options after a
// question mark. If there _isn't_ a question mark, then it's just a set of
// expressions. If there _is_, then here are the options:
//
// * (?#...)                       - inline comments
// * (?:subexp)                    - non-capturing group
// * (?=subexp)                    - positive lookahead
// * (?!subexp)                    - negative lookahead
// * (?>subexp)                    - atomic group
// * (?~subexp)                    - absence operator
// * (?<=subexp)                   - positive lookbehind
// * (?<!subexp)                   - negative lookbehind
// * (?<name>subexp)               - named capturing group
// * (?'name'subexp)               - named capturing group
// * (?(cond)yes-subexp)           - conditional expression
// * (?(cond)yes-subexp|no-subexp) - conditional expression
// * (?imxdau-imx)                 - turn on and off configuration
// * (?imxdau-imx:subexp)          - turn on and off configuration for an expression
//
static yp_regexp_parse_result_t
yp_regexp_parse_group(yp_regexp_parser_t *parser) {
  // First, parse any options for the group.
  if (parser->current.type == YP_REGEXP_TOKEN_CHAR && *parser->current.start == '?') {
    yp_regexp_lex_token(parser);

    if (parser->current.type != YP_REGEXP_TOKEN_CHAR) {
      return YP_REGEXP_PARSE_RESULT_ERROR;
    }

    yp_regexp_options_t options;
    yp_regexp_options_init(&options);

    switch (*parser->current.start) {
      case '#': { // inline comments
        return yp_regexp_find_char(parser, ')');
      }
      case ':': // non-capturing group
      case '=': // positive lookahead
      case '!': // negative lookahead
      case '>': // atomic group
      case '~': // absence operator
        break;
      case '<':
        if (parser->current.start + 1 >= parser->end) {
          return YP_REGEXP_PARSE_RESULT_ERROR;
        }

        switch (parser->current.start[1]) {
          case '=': // positive lookbehind
          case '!': // negative lookbehind
            parser->current.end++;
            break;
          default: // named capture group
            if (yp_regexp_find_char(parser, '>') == YP_REGEXP_PARSE_RESULT_ERROR) {
              return YP_REGEXP_PARSE_RESULT_ERROR;
            }

            yp_regexp_parser_named_capture(parser, parser->current.start + 1, parser->current.end - 2);
            break;
        }
        break;
      case '\'': // named capture group
        if (yp_regexp_find_char(parser, '\'') == YP_REGEXP_PARSE_RESULT_ERROR) {
          return YP_REGEXP_PARSE_RESULT_ERROR;
        }

        yp_regexp_parser_named_capture(parser, parser->current.start + 1, parser->current.end - 2);
        break;
      case '(': // conditional expression
        if (yp_regexp_find_char(parser, ')') == YP_REGEXP_PARSE_RESULT_ERROR) {
          return YP_REGEXP_PARSE_RESULT_ERROR;
        }
        break;
      case 'i': case 'm': case 'x': case 'd': case 'a': case 'u': // options
        while (parser->current.end < parser->end && *parser->current.end != '-' && *parser->current.end != ':' && *parser->current.end != ')') {
          if (!yp_regexp_options_add(&options, *parser->current.end)) {
            return YP_REGEXP_PARSE_RESULT_ERROR;
          }
          parser->current.end++;
        }

        if (parser->current.end >= parser->end) {
          return YP_REGEXP_PARSE_RESULT_ERROR;
        }

        if (*parser->current.end == '-') {
          // in this case, fall through to the next switch case
        } else {
          // otherwise, we're done parsing options
          break;
        }
      case '-':
        while (parser->current.end < parser->end && *parser->current.end != ':' && *parser->current.end != ')') {
          if (!yp_regexp_options_remove(&options, *parser->current.end)) {
            return YP_REGEXP_PARSE_RESULT_ERROR;
          }
          parser->current.end++;
        }

        if (parser->current.end >= parser->end) {
          return YP_REGEXP_PARSE_RESULT_ERROR;
        }
        break;
      default:
        return YP_REGEXP_PARSE_RESULT_ERROR;
    }
  }

  // Now, parse the expressions within this group.
  while (parser->current.type != YP_REGEXP_TOKEN_RPAREN && parser->current.type != YP_REGEXP_TOKEN_EOF) {
    if (yp_regexp_parse_expression(parser) == YP_REGEXP_PARSE_RESULT_ERROR) {
      return YP_REGEXP_PARSE_RESULT_ERROR;
    }
    yp_regexp_accept_token(parser, YP_REGEXP_TOKEN_PIPE);
  }

  // Finally, make sure we have a closing parenthesis.
  return yp_regexp_expect_token(parser, YP_REGEXP_TOKEN_RPAREN);
}

// item : anchor
//      | match-posix-class
//      | match-char-set
//      | match-char-class
//      | match-char-prop
//      | match-char
//      | match-any
//      | group
//      | quantified
//      ;
static yp_regexp_parse_result_t
yp_regexp_parse_item(yp_regexp_parser_t *parser) {
  switch (parser->current.type) {
    case YP_REGEXP_TOKEN_CARET:
    case YP_REGEXP_TOKEN_DOLLAR:
      yp_regexp_lex_token(parser);
      return YP_REGEXP_PARSE_RESULT_OK;
    case YP_REGEXP_TOKEN_CHAR:
    case YP_REGEXP_TOKEN_LBRACE:
    case YP_REGEXP_TOKEN_RBRACE:
    case YP_REGEXP_TOKEN_DOT:
      yp_regexp_lex_token(parser);
      return yp_regexp_parse_quantifier(parser);
    case YP_REGEXP_TOKEN_LBRACKET:
      yp_regexp_lex_token(parser);
      if (yp_regexp_parse_lbracket(parser) == YP_REGEXP_PARSE_RESULT_ERROR) {
        return YP_REGEXP_PARSE_RESULT_ERROR;
      }
      return yp_regexp_parse_quantifier(parser);
    case YP_REGEXP_TOKEN_BACKSLASH:
      yp_regexp_lex_token(parser);
      if (parser->current.type != YP_REGEXP_TOKEN_EOF) {
        yp_regexp_lex_token(parser);
      }
      return yp_regexp_parse_quantifier(parser);
    case YP_REGEXP_TOKEN_LPAREN:
      yp_regexp_lex_token(parser);
      if (yp_regexp_parse_group(parser) == YP_REGEXP_PARSE_RESULT_ERROR) {
        return YP_REGEXP_PARSE_RESULT_ERROR;
      }
      return yp_regexp_parse_quantifier(parser);
    default:
      return YP_REGEXP_PARSE_RESULT_ERROR;
  }
}

// expression : item+
//            ;
static yp_regexp_parse_result_t
yp_regexp_parse_expression(yp_regexp_parser_t *parser) {
  if (yp_regexp_parse_item(parser) == YP_REGEXP_PARSE_RESULT_ERROR) {
    return YP_REGEXP_PARSE_RESULT_ERROR;
  }

  while (
    parser->current.type != YP_REGEXP_TOKEN_EOF &&
    parser->current.type != YP_REGEXP_TOKEN_RPAREN &&
    parser->current.type != YP_REGEXP_TOKEN_PIPE
  ) {
    if (yp_regexp_parse_item(parser) == YP_REGEXP_PARSE_RESULT_ERROR) {
      return YP_REGEXP_PARSE_RESULT_ERROR;
    }
  }

  return YP_REGEXP_PARSE_RESULT_OK;
}

// pattern : EOF
//         | expression EOF
//         | expression PIPE pattern
//         ;
static yp_regexp_parse_result_t
yp_regexp_parse_pattern(yp_regexp_parser_t *parser) {
  yp_regexp_lex_token(parser);

  // Exit early if the pattern is empty.
  if (parser->current.type == YP_REGEXP_TOKEN_EOF) {
    return YP_REGEXP_PARSE_RESULT_OK;
  }

  // Parse the first expression in the pattern.
  yp_regexp_parse_expression(parser);

  // Check if we're continuing with a pipe or returning with an EOF.
  switch (parser->current.type) {
    case YP_REGEXP_TOKEN_EOF:
      return YP_REGEXP_PARSE_RESULT_OK;
    case YP_REGEXP_TOKEN_PIPE:
      yp_regexp_lex_token(parser);
      yp_regexp_parse_pattern(parser);
      return YP_REGEXP_PARSE_RESULT_OK;
    default:
      return YP_REGEXP_PARSE_RESULT_ERROR;
  }
}

// Parse a regular expression and extract the names of all of the named capture
// groups.
yp_regexp_parse_result_t
yp_regexp_named_capture_group_names(const char *source, size_t size, yp_encoding_t *encoding, yp_string_list_t *named_captures) {
  yp_regexp_parser_t parser;
  yp_regexp_parser_init(&parser, source, source + size, encoding, named_captures);
  return yp_regexp_parse_pattern(&parser);
}
