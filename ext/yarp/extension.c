#include "extension.h"

VALUE rb_cYARP;
VALUE rb_cYARPToken;
VALUE rb_cYARPLocation;

VALUE rb_cYARPComment;
VALUE rb_cYARPParseError;
VALUE rb_cYARPParseResult;

// Represents a source of Ruby code. It can either be coming from a file or a
// string. If it's a file, it's going to mmap the contents of the file. If it's
// a string it's going to just point to the contents of the string.
typedef struct {
  enum { SOURCE_FILE, SOURCE_STRING } type;
  const char *source;
  size_t size;
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
    .source = RSTRING_PTR(string),
    .size = RSTRING_LEN(string),
  };
}

// Free any resources associated with the given source_t.
void
source_file_unload(source_t *source) {
  munmap((void *) source->source, source->size);
}

// Dump the AST corresponding to the given source to a string.
static VALUE
dump_source(source_t *source) {
  yp_parser_t parser;
  yp_parser_init(&parser, source->source, source->size);

  yp_node_t *node = yp_parse(&parser);
  yp_buffer_t buffer;

  yp_buffer_init(&buffer);
  yp_serialize(&parser, node, &buffer);
  VALUE dumped = rb_str_new(buffer.value, buffer.length);

  yp_node_destroy(&parser, node);
  yp_buffer_free(&buffer);
  yp_parser_free(&parser);

  return dumped;
}

// Dump the AST corresponding to the given string to a string.
static VALUE
dump(VALUE self, VALUE string) {
  source_t source;
  source_string_load(&source, string);
  return dump_source(&source);
}

// Dump the AST corresponding to the given file to a string.
static VALUE
dump_file(VALUE self, VALUE filepath) {
  source_t source;
  if (source_file_load(&source, filepath) != 0) return Qnil;

  VALUE value = dump_source(&source);
  source_file_unload(&source);
  return value;
}

// Return an array of tokens corresponding to the given source.
static VALUE
lex_source(source_t *source) {
  yp_parser_t parser;
  yp_parser_init(&parser, source->source, source->size);

  VALUE ary = rb_ary_new();
  for (yp_lex_token(&parser); parser.current.type != YP_TOKEN_EOF; yp_lex_token(&parser)) {
    rb_ary_push(ary, yp_token_new(&parser, &parser.current));
  }

  yp_parser_free(&parser);
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
  VALUE comments = rb_ary_new();
  VALUE errors = rb_ary_new();

  for (yp_comment_t *comment = (yp_comment_t *) parser.comment_list.head; comment != NULL;
       comment = (yp_comment_t *) comment->node.next) {
    VALUE location_argv[] = { LONG2FIX(comment->node.start), LONG2FIX(comment->node.end) };
    VALUE type;

    switch (comment->type) {
      case YP_COMMENT_INLINE:
        type = ID2SYM(rb_intern("inline"));
        break;
      case YP_COMMENT_EMBDOC:
        type = ID2SYM(rb_intern("embdoc"));
        break;
      case YP_COMMENT___END__:
        type = ID2SYM(rb_intern("__END__"));
        break;
      default:
        type = ID2SYM(rb_intern("inline"));
        break;
    }

    VALUE comment_argv[] = { type, rb_class_new_instance(2, location_argv, rb_cYARPLocation) };
    rb_ary_push(comments, rb_class_new_instance(2, comment_argv, rb_cYARPComment));
  }

  for (yp_error_t *error = (yp_error_t *) parser.error_list.head; error != NULL;
       error = (yp_error_t *) error->node.next) {
    VALUE location_argv[] = { LONG2FIX(error->node.start), LONG2FIX(error->node.end) };

    VALUE error_argv[] = { rb_str_new(yp_string_source(&error->message), yp_string_length(&error->message)),
                           rb_class_new_instance(2, location_argv, rb_cYARPLocation) };

    rb_ary_push(errors, rb_class_new_instance(2, error_argv, rb_cYARPParseError));
  }

  VALUE result_argv[] = { yp_node_new(&parser, node), comments, errors };
  VALUE result = rb_class_new_instance(3, result_argv, rb_cYARPParseResult);

  yp_node_destroy(&parser, node);
  yp_parser_free(&parser);

  return result;
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

static VALUE
named_captures(VALUE self, VALUE rb_source) {
  yp_string_list_t string_list;
  yp_string_list_init(&string_list);

  if (!yp_regexp_named_capture_group_names(RSTRING_PTR(rb_source), RSTRING_LEN(rb_source), &string_list)) {
    yp_string_list_free(&string_list);
    return Qnil;
  }

  VALUE names = rb_ary_new();
  for (size_t index = 0; index < string_list.length; index++) {
    const yp_string_t *string = &string_list.strings[index];
    rb_ary_push(names, rb_str_new(yp_string_source(string), yp_string_length(string)));
  }

  yp_string_list_free(&string_list);
  return names;
}

static VALUE
unescape(VALUE source, yp_unescape_type_t unescape_type) {
  yp_string_t string;

  yp_unescape(RSTRING_PTR(source), RSTRING_LEN(source), &string, unescape_type);
  VALUE result = rb_str_new(yp_string_source(&string), yp_string_length(&string));
  yp_string_free(&string);

  return result;
}

static VALUE
unescape_none(VALUE self, VALUE source) {
  return unescape(source, YP_UNESCAPE_NONE);
}

static VALUE
unescape_minimal(VALUE self, VALUE source) {
  return unescape(source, YP_UNESCAPE_MINIMAL);
}

static VALUE
unescape_all(VALUE self, VALUE source) {
  return unescape(source, YP_UNESCAPE_ALL);
}

void
Init_yarp(void) {
  if (strcmp(yp_version(), EXPECTED_YARP_VERSION) != 0) {
    rb_raise(rb_eRuntimeError, "The YARP library version (%s) does not match the expected version (%s)", yp_version(),
             EXPECTED_YARP_VERSION);
  }

  rb_cYARP = rb_define_module("YARP");
  rb_cYARPToken = rb_define_class_under(rb_cYARP, "Token", rb_cObject);
  rb_cYARPLocation = rb_define_class_under(rb_cYARP, "Location", rb_cObject);

  rb_cYARPComment = rb_define_class_under(rb_cYARP, "Comment", rb_cObject);
  rb_cYARPParseError = rb_define_class_under(rb_cYARP, "ParseError", rb_cObject);
  rb_cYARPParseResult = rb_define_class_under(rb_cYARP, "ParseResult", rb_cObject);

  rb_define_const(rb_cYARP, "VERSION", rb_sprintf("%d.%d.%d", YP_VERSION_MAJOR, YP_VERSION_MINOR, YP_VERSION_PATCH));

  rb_define_singleton_method(rb_cYARP, "dump", dump, 1);
  rb_define_singleton_method(rb_cYARP, "dump_file", dump_file, 1);

  rb_define_singleton_method(rb_cYARP, "lex", lex, 1);
  rb_define_singleton_method(rb_cYARP, "lex_file", lex_file, 1);

  rb_define_singleton_method(rb_cYARP, "parse", parse, 1);
  rb_define_singleton_method(rb_cYARP, "parse_file", parse_file, 1);

  rb_define_singleton_method(rb_cYARP, "named_captures", named_captures, 1);

  rb_define_singleton_method(rb_cYARP, "unescape_none", unescape_none, 1);
  rb_define_singleton_method(rb_cYARP, "unescape_minimal", unescape_minimal, 1);
  rb_define_singleton_method(rb_cYARP, "unescape_all", unescape_all, 1);
}
