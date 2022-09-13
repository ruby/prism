#include <ruby.h>
#include "yarp.h"

// By default, the lexer won't attempt to recover from lexer errors at all. This
// function provides that implementation.
static yp_token_type_t
unrecoverable(yp_parser_t *parser) {
  return YP_TOKEN_EOF;
}

static VALUE
token_inspect(yp_parser_t *parser) {
  yp_token_t token = parser->current;
  VALUE parts = rb_ary_new();

  // First, we're going to push on the location information.
  VALUE location = rb_ary_new();
  rb_ary_push(location, LONG2FIX(token.start - parser->start));
  rb_ary_push(location, LONG2FIX(token.end - parser->start));
  rb_ary_push(parts, location);

  // Next, we're going to push on a symbol that represents the type of token.
  switch (token.type) {
    // We're going to special-case the invalid token here since that doesn't
    // actually exist in Ripper. This is going to give us a little more
    // information when our tests fail.
    case YP_TOKEN_INVALID:
      rb_ary_push(parts, ID2SYM(rb_intern("INVALID")));
      // fprintf(stderr, "Invalid token: %.*s\n", (int) (token.end - token.start), token.start);
      break;

#define CASE(type) case YP_TOKEN_##type: rb_ary_push(parts, ID2SYM(rb_intern(#type))); break;

    CASE(AMPERSAND)
    CASE(AMPERSAND_AMPERSAND)
    CASE(AMPERSAND_AMPERSAND_EQUAL)
    CASE(AMPERSAND_EQUAL)
    CASE(BACK_REFERENCE)
    CASE(BACKTICK)
    CASE(BANG)
    CASE(BANG_AT)
    CASE(BANG_EQUAL)
    CASE(BANG_TILDE)
    CASE(BRACE_LEFT)
    CASE(BRACE_RIGHT)
    CASE(BRACKET_LEFT)
    CASE(BRACKET_LEFT_RIGHT)
    CASE(BRACKET_RIGHT)
    CASE(CARET)
    CASE(CARET_EQUAL)
    CASE(CHARACTER_LITERAL)
    CASE(CLASS_VARIABLE)
    CASE(COLON)
    CASE(COLON_COLON)
    CASE(COMMA)
    CASE(COMMENT)
    CASE(CONSTANT)
    CASE(DOT)
    CASE(DOT_DOT)
    CASE(DOT_DOT_DOT)
    CASE(EMBDOC_BEGIN)
    CASE(EMBDOC_END)
    CASE(EMBDOC_LINE)
    CASE(EMBEXPR_BEGIN)
    CASE(EMBEXPR_END)
    CASE(EQUAL)
    CASE(EQUAL_EQUAL)
    CASE(EQUAL_EQUAL_EQUAL)
    CASE(EQUAL_GREATER)
    CASE(EQUAL_TILDE)
    CASE(FLOAT)
    CASE(GREATER)
    CASE(GREATER_EQUAL)
    CASE(GREATER_GREATER)
    CASE(GREATER_GREATER_EQUAL)
    CASE(GLOBAL_VARIABLE)
    CASE(IDENTIFIER)
    CASE(IMAGINARY_NUMBER)
    CASE(INTEGER)
    CASE(INSTANCE_VARIABLE)
    CASE(KEYWORD___ENCODING__)
    CASE(KEYWORD___LINE__)
    CASE(KEYWORD___FILE__)
    CASE(KEYWORD_ALIAS)
    CASE(KEYWORD_AND)
    CASE(KEYWORD_BEGIN)
    CASE(KEYWORD_BEGIN_UPCASE)
    CASE(KEYWORD_BREAK)
    CASE(KEYWORD_CASE)
    CASE(KEYWORD_CLASS)
    CASE(KEYWORD_DEF)
    CASE(KEYWORD_DEFINED)
    CASE(KEYWORD_DO)
    CASE(KEYWORD_ELSE)
    CASE(KEYWORD_ELSIF)
    CASE(KEYWORD_END)
    CASE(KEYWORD_END_UPCASE)
    CASE(KEYWORD_ENSURE)
    CASE(KEYWORD_FALSE)
    CASE(KEYWORD_FOR)
    CASE(KEYWORD_IF)
    CASE(KEYWORD_IN)
    CASE(KEYWORD_MODULE)
    CASE(KEYWORD_NEXT)
    CASE(KEYWORD_NIL)
    CASE(KEYWORD_NOT)
    CASE(KEYWORD_OR)
    CASE(KEYWORD_REDO)
    CASE(KEYWORD_RESCUE)
    CASE(KEYWORD_RETRY)
    CASE(KEYWORD_RETURN)
    CASE(KEYWORD_SELF)
    CASE(KEYWORD_SUPER)
    CASE(KEYWORD_THEN)
    CASE(KEYWORD_TRUE)
    CASE(KEYWORD_UNDEF)
    CASE(KEYWORD_UNLESS)
    CASE(KEYWORD_UNTIL)
    CASE(KEYWORD_WHEN)
    CASE(KEYWORD_WHILE)
    CASE(KEYWORD_YIELD)
    CASE(LABEL)
    CASE(LAMBDA_BEGIN)
    CASE(LESS)
    CASE(LESS_EQUAL)
    CASE(LESS_EQUAL_GREATER)
    CASE(LESS_LESS)
    CASE(LESS_LESS_EQUAL)
    CASE(MINUS)
    CASE(MINUS_AT)
    CASE(MINUS_EQUAL)
    CASE(MINUS_GREATER)
    CASE(NEWLINE)
    CASE(NTH_REFERENCE)
    CASE(PARENTHESIS_LEFT)
    CASE(PARENTHESIS_RIGHT)
    CASE(PERCENT)
    CASE(PERCENT_EQUAL)
    CASE(PERCENT_LOWER_I)
    CASE(PERCENT_LOWER_W)
    CASE(PERCENT_LOWER_X)
    CASE(PERCENT_UPPER_I)
    CASE(PERCENT_UPPER_W)
    CASE(PIPE)
    CASE(PIPE_EQUAL)
    CASE(PIPE_PIPE)
    CASE(PIPE_PIPE_EQUAL)
    CASE(PLUS)
    CASE(PLUS_AT)
    CASE(PLUS_EQUAL)
    CASE(QUESTION_MARK)
    CASE(RATIONAL_NUMBER)
    CASE(REGEXP_BEGIN)
    CASE(REGEXP_END)
    CASE(SEMICOLON)
    CASE(SLASH)
    CASE(SLASH_EQUAL)
    CASE(STAR)
    CASE(STAR_EQUAL)
    CASE(STAR_STAR)
    CASE(STAR_STAR_EQUAL)
    CASE(STRING_BEGIN)
    CASE(STRING_CONTENT)
    CASE(STRING_END)
    CASE(SYMBOL_BEGIN)
    CASE(TILDE)
    CASE(TILDE_AT)
    CASE(WORDS_SEP)

#undef CASE

    default:
      rb_bug("Unknown token type: %d", token.type);
  }

  rb_ary_push(parts, rb_str_new(token.start, token.end - token.start));
  return parts;
}

static VALUE
each_token(VALUE self, VALUE rb_filepath) {
  char *filepath = StringValueCStr(rb_filepath);

  // Open the file for reading
  int fd = open(filepath, O_RDONLY);
  if (fd == -1) {
    perror("open");
    return Qnil;
  }

  // Stat the file to get the file size
  struct stat sb;
  if (fstat(fd, &sb) == -1) {
    close(fd);
    perror("fstat");
    return Qnil;
  }

  // mmap the file descriptor to virtually get the contents
  off_t size = sb.st_size;
  const char *source = mmap(NULL, size, PROT_READ, MAP_PRIVATE, fd, 0);

  close(fd);
  if (source == MAP_FAILED) {
    perror("mmap");
    return Qnil;
  }

  yp_error_handler_t default_error_handler = {
    .unterminated_embdoc = unrecoverable,
    .unterminated_list = unrecoverable,
    .unterminated_regexp = unrecoverable,
    .unterminated_string = unrecoverable
  };

  // Instantiate the parser struct with all of the necessary information
  yp_parser_t parser;
  yp_parser_init(&parser, source, size, &default_error_handler);

  // Create an array and populate it with the tokens from the filepath
  for (yp_lex_token(&parser); parser.current.type != YP_TOKEN_EOF; yp_lex_token(&parser)) {
    rb_yield(token_inspect(&parser));
  }

  // Clean up and free
  munmap((void *) source, size);
  return Qnil;
}

void
Init_yarp(void) {
  VALUE rb_cYARP = rb_define_module("YARP");
  rb_define_singleton_method(rb_cYARP, "each_token", each_token, 1);
}
