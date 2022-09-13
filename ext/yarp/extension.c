#include <ruby.h>
#include "yarp.h"

VALUE rb_cYARP;
VALUE rb_cYARPToken;

static VALUE
token_type(yp_token_t *token) {
  switch (token->type) {
    // We're going to special-case the invalid token here since that doesn't
    // actually exist in Ripper. This is going to give us a little more
    // information when our tests fail.
    case YP_TOKEN_INVALID:
      // fprintf(stderr, "Invalid token: %.*s\n", (int) (token.end - token.start), token.start);
      return ID2SYM(rb_intern("INVALID"));

#define CASE(type) case YP_TOKEN_##type: return ID2SYM(rb_intern(#type)); break;

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
      rb_bug("Unknown token type: %d", token->type);
      return Qnil;
  }
}

static VALUE
token_new(yp_parser_t *parser, yp_token_t *token) {
  VALUE argv[] = {
    token_type(token),
    rb_str_new(token->start, token->end - token->start),
    LONG2FIX(token->start - parser->start),
    LONG2FIX(token->end - parser->end)
  };

  return rb_class_new_instance(4, argv, rb_cYARPToken);
}

static VALUE
node_new(yp_parser_t *parser, yp_node_t *node) {
  return Qnil;
}

// Represents a source of Ruby code. It can either be coming from a file or a
// string. If it's a file, it's going to mmap the contents of the file. If it's
// a string it's going to just point to the contents of the string.
typedef struct {
  enum { SOURCE_FILE, SOURCE_STRING } type;
  const char *source;
  off_t size;
} source_t;

// Read the file indicated by the filepath parameter into source and load its
// contents and size into the given source_t.
int
source_file_load(source_t *source, VALUE filepath) {
  // Open the file for reading
  int fd = open(StringValueCStr(filepath), O_RDONLY);
  if (fd == -1) {
    perror("open");
    return 1;
  }

  // Stat the file to get the file size
  struct stat sb;
  if (fstat(fd, &sb) == -1) {
    close(fd);
    perror("fstat");
    return 1;
  }

  // mmap the file descriptor to virtually get the contents
  source->size = sb.st_size;
  source->source = mmap(NULL, source->size, PROT_READ, MAP_PRIVATE, fd, 0);

  close(fd);
  if (source == MAP_FAILED) {
    perror("mmap");
    return 1;
  }

  return 0;
}

// Load the contents and size of the given string into the given source_t.
void
source_string_load(source_t *source, VALUE string) {
  *source = (source_t) {
    .type = SOURCE_STRING,
    .source = StringValueCStr(string),
    .size = RSTRING_LEN(string)
  };
}

// Free any resources associated with the given source_t.
void
source_file_unload(source_t *source) {
  munmap((void *) source->source, source->size);
}

// Return an array of tokens corresponding to the given source.
static VALUE
lex_source(source_t *source) {
  yp_parser_t parser;
  yp_parser_init(&parser, source->source, source->size);

  VALUE ary = rb_ary_new();
  for (yp_lex_token(&parser); parser.current.type != YP_TOKEN_EOF; yp_lex_token(&parser)) {
    rb_ary_push(ary, token_new(&parser, &parser.current));
  }

  return ary;
}

// Return an array of tokens corresponding to the given string.
static VALUE
lex(VALUE self, VALUE string) {
  source_t source;
  source_string_load(&source, string);
  return lex_source(&source);
}

// Return an array of tokens corresponding to the given file.
static VALUE
lex_file(VALUE self, VALUE filepath) {
  source_t source;
  if (source_file_load(&source, filepath) != 0) return Qnil;

  VALUE value = lex_source(&source);
  source_file_unload(&source);
  return value;
}

static VALUE
parse_source(source_t *source) {
  yp_parser_t parser;
  yp_parser_init(&parser, source->source, source->size);

  yp_node_t *node = yp_parse(&parser);
  return node_new(&parser, node);
}

static VALUE
parse(VALUE self, VALUE string) {
  source_t source;
  source_string_load(&source, string);
  return parse_source(&source);
}

static VALUE
parse_file(VALUE self, VALUE rb_filepath) {
  source_t source;
  if (source_file_load(&source, rb_filepath) != 0) {
    return Qnil;
  }

  VALUE value = parse_source(&source);
  source_file_unload(&source);
  return value;
}

void
Init_yarp(void) {
  rb_cYARP = rb_define_module("YARP");
  rb_cYARPToken = rb_define_class_under(rb_cYARP, "Token", rb_cObject);

  rb_define_singleton_method(rb_cYARP, "lex", lex, 1);
  rb_define_singleton_method(rb_cYARP, "lex_file", lex_file, 1);

  rb_define_singleton_method(rb_cYARP, "parse", parse, 1);
  rb_define_singleton_method(rb_cYARP, "parse_file", parse_file, 1);
}
