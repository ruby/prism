#include "extension.h"

VALUE rb_cYARP;
VALUE rb_cYARPToken;
VALUE rb_cYARPLocation;

VALUE rb_cYARPComment;
VALUE rb_cYARPParseError;
VALUE rb_cYARPParseWarning;
VALUE rb_cYARPParseResult;

// Represents a source of Ruby code. It can either be coming from a file or a
// string. If it's a file, it's going to mmap the contents of the file. If it's
// a string it's going to just point to the contents of the string.
typedef struct {
    const char *source;
    size_t size;
} source_t;

// Read the file indicated by the filepath parameter into source and load its
// contents and size into the given source_t.
//
// We want to use demand paging as much as possible in order to avoid having to
// read the entire file into memory (which could be detrimental to performance
// for large files). This means that if we're on windows we'll use
// `MapViewOfFileEx`, on POSIX systems that have access to `mmap` we'll use
// `mmap`, and on other POSIX systems we'll use `read`.
static int
source_file_load(source_t *source, VALUE ruby_filepath) {
    const char *filepath = StringValueCStr(ruby_filepath);

#ifdef _WIN32
    // Open the file for reading.
    HANDLE file = CreateFile(filepath, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (file == INVALID_HANDLE_VALUE) {
        perror("CreateFile failed");
        return 1;
    }

    // Get the file size.
    DWORD file_size = GetFileSize(file, NULL);
    if (file_size == INVALID_FILE_SIZE) {
        CloseHandle(file);
        perror("GetFileSize failed");
        return 1;
    }

    // If the file is empty, then we don't need to do anything else, we'll set
    // the source to a constant empty string and return.
    if (!file_size) {
        CloseHandle(file);
        source->size = 0;
        source->source = "";
        return 0;
    }

    // Create a mapping of the file.
    HANDLE mapping = CreateFileMapping(file, NULL, PAGE_READONLY, 0, 0, NULL);
    if (mapping == NULL) {
        CloseHandle(file);
        perror("CreateFileMapping failed");
        return 1;
    }

    // Map the file into memory.
    source->source = (const char *) MapViewOfFile(mapping, FILE_MAP_READ, 0, 0, 0);
    CloseHandle(mapping);
    CloseHandle(file);

    if (source->source == NULL) {
        perror("MapViewOfFileEx failed");
        return 1;
    }

    // Set the size of the source.
    source->size = (size_t) file_size;
#else
    // Open the file for reading.
    int fd = open(filepath, O_RDONLY);
    if (fd == -1) {
        perror("open failed");
        return 1;
    }

    // Get the file size.
    struct stat sb;
    if (fstat(fd, &sb) == -1) {
        close(fd);
        perror("fstat failed");
        return 1;
    }

    // If the file is empty, then we don't need to do anything else, we'll set
    // the source to a constant empty string and return.
    source->size = sb.st_size;
    if (!source->size) {
        source->source = "";
        return 0;
    }

#ifdef HAVE_MMAP
    // Map the file into memory.
    void *memory = mmap(NULL, source->size, PROT_READ, MAP_PRIVATE, fd, 0);
    if (memory == MAP_FAILED) {
        perror("mmap failed");
        return 1;
    }

    // Close the file now that we've mapped it into memory.
    source->source = memory;
    close(fd);
#else
    // Allocate a buffer to read the file into.
    void *memory = malloc(source->size);
    if (memory == NULL) {
        close(fd);
        return 1;
    }

    // Read the file into the buffer.
    ssize_t read_size = read(fd, memory, source->size);
    close(fd);

    // If the read failed or we didn't read the entire file, then we need to
    // free the buffer and return an error.
    if (read_size < 0 || (size_t) read_size != source->size) {
        perror("read failed");
        free(memory);
        return 1;
    }

    source->source = memory;
#endif
#endif

    // Return success.
    return 0;
}

// Load the contents and size of the given string into the given source_t.
static void
source_string_load(source_t *source, VALUE string) {
    *source = (source_t) {
        .source = RSTRING_PTR(string),
        .size = RSTRING_LEN(string),
    };
}

// Free any resources associated with the given source_t. This is the corollary
// function to source_file_load. It will unmap the file if it was mapped, or
// free the memory if it was allocated.
static void
source_file_unload(source_t *source) {
    void *memory = (void *) source->source;

#if defined(_WIN32)
    UnmapViewOfFile(memory);
#elif defined(HAVE_MMAP)
    if (source->size) munmap(memory, source->size);
#else
    if (source->size) free(memory);
#endif
}

// Dump the AST corresponding to the given source to a string.
static VALUE
dump_source(source_t *source, const char *filepath) {
    yp_parser_t parser;
    yp_parser_init(&parser, source->source, source->size, filepath);

    yp_node_t *node = yp_parse(&parser);

    yp_buffer_t buffer;
    if (!yp_buffer_init(&buffer)) rb_raise(rb_eNoMemError, "failed to allocate memory");

    yp_serialize(&parser, node, &buffer);
    VALUE dumped = rb_str_new(buffer.value, buffer.length);

    yp_node_destroy(&parser, node);
    yp_buffer_free(&buffer);
    yp_parser_free(&parser);

    return dumped;
}

// Dump the AST corresponding to the given string to a string.
static VALUE
dump(VALUE self, VALUE string, VALUE filepath) {
    source_t source;
    source_string_load(&source, string);
    char *str = NULL;

    if (filepath != Qnil) {
        str = StringValueCStr(filepath);
    }

    return dump_source(&source, str);
}

// Dump the AST corresponding to the given file to a string.
static VALUE
dump_file(VALUE self, VALUE filepath) {
    source_t source;
    if (source_file_load(&source, filepath) != 0) return Qnil;

    VALUE value = dump_source(&source, StringValueCStr(filepath));
    source_file_unload(&source);
    return value;
}

// Extract the comments out of the parser into an array.
static VALUE
parser_comments(yp_parser_t *parser) {
    VALUE comments = rb_ary_new();
    yp_comment_t *comment;

    for (comment = (yp_comment_t *) parser->comment_list.head; comment != NULL; comment = (yp_comment_t *) comment->node.next) {
        VALUE location_argv[] = { LONG2FIX(comment->start - parser->start), LONG2FIX(comment->end - parser->start) };
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

    return comments;
}

// Extract the errors out of the parser into an array.
static VALUE
parser_errors(yp_parser_t *parser, rb_encoding *encoding) {
    VALUE errors = rb_ary_new();
    yp_diagnostic_t *error;

    for (error = (yp_diagnostic_t *) parser->error_list.head; error != NULL; error = (yp_diagnostic_t *) error->node.next) {
        VALUE location_argv[] = {
            LONG2FIX(error->start - parser->start),
            LONG2FIX(error->end - parser->start)
        };

        VALUE error_argv[] = {
            rb_enc_str_new_cstr(error->message, encoding),
            rb_class_new_instance(2, location_argv, rb_cYARPLocation)
        };

        rb_ary_push(errors, rb_class_new_instance(2, error_argv, rb_cYARPParseError));
    }

    return errors;
}

// Extract the warnings out of the parser into an array.
static VALUE
parser_warnings(yp_parser_t *parser, rb_encoding *encoding) {
    VALUE warnings = rb_ary_new();
    yp_diagnostic_t *warning;

    for (warning = (yp_diagnostic_t *) parser->warning_list.head; warning != NULL; warning = (yp_diagnostic_t *) warning->node.next) {
        VALUE location_argv[] = {
            LONG2FIX(warning->start - parser->start),
            LONG2FIX(warning->end - parser->start)
        };

        VALUE warning_argv[] = {
            rb_enc_str_new_cstr(warning->message, encoding),
            rb_class_new_instance(2, location_argv, rb_cYARPLocation)
        };

        rb_ary_push(warnings, rb_class_new_instance(2, warning_argv, rb_cYARPParseWarning));
    }

    return warnings;
}

typedef struct {
    VALUE tokens;
    rb_encoding *encoding;
} lex_data_t;

static void
lex_token(void *data, yp_parser_t *parser, yp_token_t *token) {
    lex_data_t *lex_data = (lex_data_t *) parser->lex_callback->data;

    VALUE yields = rb_ary_new_capa(2);
    rb_ary_push(yields, yp_token_new(parser, token, lex_data->encoding));
    rb_ary_push(yields, INT2FIX(parser->lex_state));

    rb_ary_push(lex_data->tokens, yields);
}

static void
lex_encoding_changed_callback(yp_parser_t *parser) {
    lex_data_t *lex_data = (lex_data_t *) parser->lex_callback->data;
    lex_data->encoding = rb_enc_find(parser->encoding.name);
}

// Return an array of tokens corresponding to the given source.
static VALUE
lex_source(source_t *source, char *filepath) {
    yp_parser_t parser;
    yp_parser_init(&parser, source->source, source->size, filepath);
    yp_parser_register_encoding_changed_callback(&parser, lex_encoding_changed_callback);

    lex_data_t lex_data = {
        .tokens = rb_ary_new(),
        .encoding = rb_utf8_encoding()
    };

    void *data = (void *) &lex_data;
    yp_lex_callback_t lex_callback = (yp_lex_callback_t) {
        .data = data,
        .callback = lex_token,
    };

    parser.lex_callback = &lex_callback;
    yp_node_t *node = yp_parse(&parser);

    VALUE result_argv[] = {
        lex_data.tokens,
        parser_comments(&parser),
        parser_errors(&parser, lex_data.encoding),
        parser_warnings(&parser, lex_data.encoding)
    };

    VALUE result = rb_class_new_instance(4, result_argv, rb_cYARPParseResult);

    yp_node_destroy(&parser, node);
    yp_parser_free(&parser);

    return result;
}

// Return an array of tokens corresponding to the given string.
static VALUE
lex(VALUE self, VALUE string, VALUE filepath) {
    source_t source;
    source_string_load(&source, string);
    char *filepath_char = NULL;
    if (filepath) {
        filepath_char = StringValueCStr(filepath);
    }
    return lex_source(&source, filepath_char);
}

// Return an array of tokens corresponding to the given file.
static VALUE
lex_file(VALUE self, VALUE filepath) {
    source_t source;
    if (source_file_load(&source, filepath) != 0) return Qnil;

    VALUE value = lex_source(&source, StringValueCStr(filepath));
    source_file_unload(&source);
    return value;
}

static VALUE
parse_source(source_t *source, char *filepath) {
    yp_parser_t parser;
    yp_parser_init(&parser, source->source, source->size, filepath);

    yp_node_t *node = yp_parse(&parser);
    rb_encoding *encoding = rb_enc_find(parser.encoding.name);

    VALUE result_argv[] = {
        yp_ast_new(&parser, node, encoding),
        parser_comments(&parser),
        parser_errors(&parser, encoding),
        parser_warnings(&parser, encoding)
    };

    VALUE result = rb_class_new_instance(4, result_argv, rb_cYARPParseResult);

    yp_node_destroy(&parser, node);
    yp_parser_free(&parser);

    return result;
}

// Parse the source given by the string parameter and return the Ruby object
// associated with the parse result.
//
// If YARP_DEBUG_MODE_BUILD is defined, then the entire input source string is
// going to be duplicated and used instead of the original string. This is to
// make it easier to debug reading off the end of the string since the boundary
// is more consistently defined.
static VALUE
parse(VALUE self, VALUE string, VALUE filepath) {
    source_t source;
    source_string_load(&source, string);

#ifdef YARP_DEBUG_MODE_BUILD
    char* dup = malloc(source.size);
    memcpy(dup, source.source, source.size);
    source.source = dup;
#endif

    VALUE value = parse_source(&source, NIL_P(filepath) ? NULL : StringValueCStr(filepath));

#ifdef YARP_DEBUG_MODE_BUILD
    free(dup);
#endif

    return value;
}

static VALUE
parse_file(VALUE self, VALUE rb_filepath) {
    source_t source;
    if (source_file_load(&source, rb_filepath) != 0) {
        return Qnil;
    }

    VALUE value = parse_source(&source, StringValueCStr(rb_filepath));
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
    VALUE result;

    yp_list_t error_list;
    yp_list_init(&error_list);

    yp_unescape_manipulate_string(RSTRING_PTR(source), RSTRING_LEN(source), &string, unescape_type, &error_list);
    if (yp_list_empty_p(&error_list)) {
        result = rb_str_new(yp_string_source(&string), yp_string_length(&string));
    } else {
        result = Qnil;
    }

    yp_string_free(&string);
    yp_list_free(&error_list);

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

// This function returns a hash of information about the given source string's
// memory usage.
static VALUE
memsize(VALUE self, VALUE string) {
    yp_parser_t parser;
    size_t length = RSTRING_LEN(string);
    yp_parser_init(&parser, RSTRING_PTR(string), length, NULL);

    yp_node_t *node = yp_parse(&parser);
    yp_memsize_t memsize;
    yp_node_memsize(node, &memsize);

    yp_node_destroy(&parser, node);
    yp_parser_free(&parser);

    VALUE result = rb_hash_new();
    rb_hash_aset(result, ID2SYM(rb_intern("length")), INT2FIX(length));
    rb_hash_aset(result, ID2SYM(rb_intern("memsize")), INT2FIX(memsize.memsize));
    rb_hash_aset(result, ID2SYM(rb_intern("node_count")), INT2FIX(memsize.node_count));
    return result;
}

static VALUE
compile(VALUE self, VALUE string) {
    yp_parser_t parser;
    size_t length = RSTRING_LEN(string);
    yp_parser_init(&parser, RSTRING_PTR(string), length, NULL);

    yp_node_t *node = yp_parse(&parser);
    VALUE result = yp_compile(node);

    yp_node_destroy(&parser, node);
    yp_parser_free(&parser);

    return result;
}

static VALUE
profile_file(VALUE self, VALUE filepath) {
    source_t source;
    if (source_file_load(&source, filepath) != 0) return Qnil;

    yp_parser_t parser;
    yp_parser_init(&parser, source.source, source.size, StringValueCStr(filepath));

    yp_node_t *node = yp_parse(&parser);
    yp_node_destroy(&parser, node);
    yp_parser_free(&parser);

    return Qnil;
}

// The function takes a source string and returns a Ruby array containing the
// offsets of every newline in the string. (It also includes a 0 at the
// beginning to indicate the position of the first line.)
//
// It accepts a string as its only argument and returns an array of integers.
static VALUE
newlines(VALUE self, VALUE string) {
    yp_parser_t parser;
    size_t length = RSTRING_LEN(string);
    yp_parser_init(&parser, RSTRING_PTR(string), length, NULL);

    yp_node_t *node = yp_parse(&parser);
    yp_node_destroy(&parser, node);

    VALUE result = rb_ary_new_capa(parser.newline_list.size);
    for (size_t index = 0; index < parser.newline_list.size; index++) {
        rb_ary_push(result, INT2FIX(parser.newline_list.offsets[index]));
    }

    yp_parser_free(&parser);
    return result;
}

RUBY_FUNC_EXPORTED void
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
    rb_cYARPParseWarning = rb_define_class_under(rb_cYARP, "ParseWarning", rb_cObject);
    rb_cYARPParseResult = rb_define_class_under(rb_cYARP, "ParseResult", rb_cObject);

    rb_define_const(rb_cYARP, "VERSION", rb_sprintf("%d.%d.%d", YP_VERSION_MAJOR, YP_VERSION_MINOR, YP_VERSION_PATCH));

    rb_define_singleton_method(rb_cYARP, "dump", dump, 2);
    rb_define_singleton_method(rb_cYARP, "dump_file", dump_file, 1);

    rb_define_singleton_method(rb_cYARP, "lex", lex, 2);
    rb_define_singleton_method(rb_cYARP, "lex_file", lex_file, 1);

    rb_define_singleton_method(rb_cYARP, "_parse", parse, 2);
    rb_define_singleton_method(rb_cYARP, "parse_file", parse_file, 1);

    rb_define_singleton_method(rb_cYARP, "named_captures", named_captures, 1);

    rb_define_singleton_method(rb_cYARP, "unescape_none", unescape_none, 1);
    rb_define_singleton_method(rb_cYARP, "unescape_minimal", unescape_minimal, 1);
    rb_define_singleton_method(rb_cYARP, "unescape_all", unescape_all, 1);

    rb_define_singleton_method(rb_cYARP, "memsize", memsize, 1);

    rb_define_singleton_method(rb_cYARP, "compile", compile, 1);

    rb_define_singleton_method(rb_cYARP, "profile_file", profile_file, 1);

    rb_define_singleton_method(rb_cYARP, "newlines", newlines, 1);

    Init_yarp_pack();
}
