#include "prism/extension.h"

#ifdef _WIN32
#include <ruby/win32.h>
#endif

#include <errno.h>

// NOTE: this file should contain only bindings. All non-trivial logic should be
// in libprism so it can be shared its the various callers.

VALUE rb_cPrism;
VALUE rb_cPrismNode;
VALUE rb_cPrismSource;
VALUE rb_cPrismToken;
VALUE rb_cPrismLocation;

VALUE rb_cPrismComment;
VALUE rb_cPrismInlineComment;
VALUE rb_cPrismEmbDocComment;
VALUE rb_cPrismMagicComment;
VALUE rb_cPrismParseError;
VALUE rb_cPrismParseWarning;
VALUE rb_cPrismResult;
VALUE rb_cPrismParseResult;
VALUE rb_cPrismLexResult;
VALUE rb_cPrismParseLexResult;
VALUE rb_cPrismStringQuery;
VALUE rb_cPrismScope;
VALUE rb_cPrismCurrentVersionError;

VALUE rb_cPrismDebugEncoding;

VALUE rb_cPrismCompileLocal;
VALUE rb_cPrismCompileInsn;
VALUE rb_cPrismCompileBlock;
VALUE rb_cPrismCompileGraph;
VALUE rb_cPrismCompileUnit;

ID rb_id_option_attach_comments;
ID rb_id_option_command_line;
ID rb_id_option_encoding;
ID rb_id_option_filepath;
ID rb_id_option_freeze;
ID rb_id_option_frozen_string_literal;
ID rb_id_option_line;
ID rb_id_option_main_script;
ID rb_id_option_partial_script;
ID rb_id_option_raise_error;
ID rb_id_option_scopes;
ID rb_id_option_version;

ID rb_id_source_for;

ID rb_id_forwarding_positionals;
ID rb_id_forwarding_keywords;
ID rb_id_forwarding_block;
ID rb_id_forwarding_all;

ID rb_id_raise_error_plain;
ID rb_id_raise_error_style;
ID rb_id_raise_error_color;

/******************************************************************************/
/* Result struct for working with functions that may need to raise errors.    */
/******************************************************************************/

typedef struct {
    enum {
        RESULT_OK,
        RESULT_ERR
    } type;
    VALUE value;
} result_t;

static result_t
result_ok(VALUE value) {
    return (result_t) { .type = RESULT_OK, .value = value };
}

static result_t
result_err(VALUE value) {
    return (result_t) { .type = RESULT_ERR, .value = value };
}

static VALUE
result_get(result_t result) {
    if (result.type == RESULT_OK) {
        return result.value;
    } else {
        rb_exc_raise(result.value);
    }
}

/******************************************************************************/
/* IO of Ruby code                                                            */
/******************************************************************************/

/**
 * Check if the given VALUE is a string. If it's not a string, then raise a
 * TypeError. Otherwise return the VALUE as a C string.
 */
static const char *
check_string(VALUE value) {
    // Check if the value is a string. If it's not, then raise a type error.
    if (!RB_TYPE_P(value, T_STRING)) {
        rb_raise(rb_eTypeError, "wrong argument type %" PRIsVALUE " (expected String)", rb_obj_class(value));
    }

    // Otherwise, return the value as a C string.
    return RSTRING_PTR(value);
}

/******************************************************************************/
/* Building C options from Ruby options                                       */
/******************************************************************************/

/**
 * Build the scopes associated with the provided Ruby keyword value.
 */
static void
build_options_scopes(pm_options_t *options, VALUE scopes) {
    // Check if the value is an array. If it's not, then raise a type error.
    if (!RB_TYPE_P(scopes, T_ARRAY)) {
        rb_raise(rb_eTypeError, "wrong argument type %"PRIsVALUE" (expected Array)", rb_obj_class(scopes));
    }

    // Initialize the scopes array.
    size_t scopes_count = RARRAY_LEN(scopes);
    if (!pm_options_scopes_init(options, scopes_count)) {
        rb_raise(rb_eNoMemError, "failed to allocate memory");
    }

    // Iterate over the scopes and add them to the options.
    for (size_t scope_index = 0; scope_index < scopes_count; scope_index++) {
        VALUE scope = rb_ary_entry(scopes, scope_index);

        // The scope can be either an array or it can be a Prism::Scope object.
        // Parse out the correct values here from either.
        VALUE locals;
        uint8_t forwarding = PM_OPTIONS_SCOPE_FORWARDING_NONE;

        if (RB_TYPE_P(scope, T_ARRAY)) {
            locals = scope;
        } else if (rb_obj_is_kind_of(scope, rb_cPrismScope)) {
            locals = rb_ivar_get(scope, rb_intern("@locals"));
            if (!RB_TYPE_P(locals, T_ARRAY)) {
                rb_raise(rb_eTypeError, "wrong argument type %"PRIsVALUE" (expected Array)", rb_obj_class(locals));
            }

            VALUE names = rb_ivar_get(scope, rb_intern("@forwarding"));
            if (!RB_TYPE_P(names, T_ARRAY)) {
                rb_raise(rb_eTypeError, "wrong argument type %"PRIsVALUE" (expected Array)", rb_obj_class(names));
            }

            size_t names_count = RARRAY_LEN(names);
            for (size_t name_index = 0; name_index < names_count; name_index++) {
                VALUE name = rb_ary_entry(names, name_index);

                // Check that the name is a symbol. If it's not, then raise
                // a type error.
                if (!RB_TYPE_P(name, T_SYMBOL)) {
                    rb_raise(rb_eTypeError, "wrong argument type %"PRIsVALUE" (expected Symbol)", rb_obj_class(name));
                }

                ID id = SYM2ID(name);
                if (id == rb_id_forwarding_positionals) {
                    forwarding |= PM_OPTIONS_SCOPE_FORWARDING_POSITIONALS;
                } else if (id == rb_id_forwarding_keywords) {
                    forwarding |= PM_OPTIONS_SCOPE_FORWARDING_KEYWORDS;
                } else if (id == rb_id_forwarding_block) {
                    forwarding |= PM_OPTIONS_SCOPE_FORWARDING_BLOCK;
                } else if (id == rb_id_forwarding_all) {
                    forwarding |= PM_OPTIONS_SCOPE_FORWARDING_ALL;
                } else {
                    rb_raise(rb_eArgError, "invalid forwarding value: %" PRIsVALUE, name);
                }
            }
        } else {
            rb_raise(rb_eTypeError, "wrong argument type %"PRIsVALUE" (expected Array or Prism::Scope)", rb_obj_class(scope));
        }

        // Initialize the scope array.
        size_t locals_count = RARRAY_LEN(locals);
        pm_options_scope_t *options_scope = pm_options_scope_mut(options, scope_index);
        pm_options_scope_init(options_scope, locals_count);

        // Iterate over the locals and add them to the scope.
        for (size_t local_index = 0; local_index < locals_count; local_index++) {
            VALUE local = rb_ary_entry(locals, local_index);

            // Check that the local is a symbol. If it's not, then raise a
            // type error.
            if (!RB_TYPE_P(local, T_SYMBOL)) {
                rb_raise(rb_eTypeError, "wrong argument type %"PRIsVALUE" (expected Symbol)", rb_obj_class(local));
            }

            // Add the local to the scope.
            pm_string_t *scope_local = pm_options_scope_local_mut(options_scope, local_index);
            const char *name = rb_id2name(SYM2ID(local));
            pm_string_init(scope_local, (const uint8_t *) name, strlen(name));
        }

        // Now set the forwarding options.
        pm_options_scope_forwarding_set(options_scope, forwarding);
    }
}

/**
 * Set the version option to the syntax version of the currently running Ruby,
 * or to the closest version prism supports if it does not know that one.
 */
static void
options_version_set_nearest(pm_options_t *options) {
    if (!pm_options_version_set(options, ruby_version, 3)) {
        // Prism doesn't know this specific version. Is it lower?
        if (ruby_version[0] < '3' || (ruby_version[0] == '3' && ruby_version[2] < '3')) {
            pm_options_version_set_lowest(options);
        } else {
            // Must be higher.
            pm_options_version_set_highest(options);
        }
    }
}

/**
 * An iterator function that is called for each key-value in the keywords hash.
 */
static int
build_options_i(VALUE key, VALUE value, VALUE argument) {
    pm_options_t *options = (pm_options_t *) argument;
    ID key_id = SYM2ID(key);

    if (key_id == rb_id_option_filepath) {
        if (!NIL_P(value)) pm_options_filepath_set(options, check_string(value));
    } else if (key_id == rb_id_option_encoding) {
        if (!NIL_P(value)) {
            if (value == Qfalse) {
                pm_options_encoding_locked_set(options, true);
            } else {
                pm_options_encoding_set(options, rb_enc_name(rb_to_encoding(value)));
            }
        }
    } else if (key_id == rb_id_option_line) {
        if (!NIL_P(value)) pm_options_line_set(options, NUM2INT(value));
    } else if (key_id == rb_id_option_frozen_string_literal) {
        if (!NIL_P(value)) pm_options_frozen_string_literal_set(options, RTEST(value));
    } else if (key_id == rb_id_option_version) {
        if (!NIL_P(value)) {
            const char *version = check_string(value);

            if (RSTRING_LEN(value) == 7 && strncmp(version, "current", 7) == 0) {
                if (!pm_options_version_set(options, ruby_version, 3)) {
                    rb_exc_raise(rb_exc_new_cstr(rb_cPrismCurrentVersionError, ruby_version));
                }
            } else if (RSTRING_LEN(value) == 7 && strncmp(version, "nearest", 7) == 0) {
                options_version_set_nearest(options);
            } else if (!pm_options_version_set(options, version, RSTRING_LEN(value))) {
                rb_raise(rb_eArgError, "invalid version: %" PRIsVALUE, value);
            }
        }
    } else if (key_id == rb_id_option_scopes) {
        if (!NIL_P(value)) build_options_scopes(options, value);
    } else if (key_id == rb_id_option_command_line) {
        if (!NIL_P(value)) {
            const char *string = check_string(value);
            uint8_t command_line = 0;

            for (size_t index = 0; index < strlen(string); index++) {
                switch (string[index]) {
                    case 'a': command_line |= PM_OPTIONS_COMMAND_LINE_A; break;
                    case 'e': command_line |= PM_OPTIONS_COMMAND_LINE_E; break;
                    case 'l': command_line |= PM_OPTIONS_COMMAND_LINE_L; break;
                    case 'n': command_line |= PM_OPTIONS_COMMAND_LINE_N; break;
                    case 'p': command_line |= PM_OPTIONS_COMMAND_LINE_P; break;
                    case 'x': command_line |= PM_OPTIONS_COMMAND_LINE_X; break;
                    default: rb_raise(rb_eArgError, "invalid command line flag: '%c'", string[index]); break;
                }
            }

            pm_options_command_line_set(options, command_line);
        }
    } else if (key_id == rb_id_option_main_script) {
        if (!NIL_P(value)) pm_options_main_script_set(options, RTEST(value));
    } else if (key_id == rb_id_option_partial_script) {
        if (!NIL_P(value)) pm_options_partial_script_set(options, RTEST(value));
    } else if (key_id == rb_id_option_freeze) {
        if (!NIL_P(value)) pm_options_freeze_set(options, RTEST(value));
    } else if (key_id == rb_id_option_attach_comments) {
        if (!NIL_P(value)) pm_options_attach_comments_set(options, RTEST(value));
    } else if (key_id == rb_id_option_raise_error) {
        if (!NIL_P(value)) {
            if (value == Qtrue) {
                /* When given true, color when $stderr is a terminal (unless
                 * NO_COLOR is set), bold styling when NO_COLOR is set, plain
                 * otherwise.
                 *
                 * rb_stderr_tty_p is not available to extensions, so instead
                 * we call the tty? method on $stderr, guarding against it
                 * having been replaced by an object that does not respond to
                 * tty?. */
                if (rb_respond_to(rb_stderr, rb_intern_const("tty?")) && RTEST(rb_funcall(rb_stderr, rb_intern_const("tty?"), 0))) {
                    const char *no_color = getenv("NO_COLOR");
                    if (no_color == NULL || no_color[0] == '\0') {
                        pm_options_raise_error_set(options, (uint8_t) PM_ERRORS_FORMAT_COLOR);
                    } else {
                        pm_options_raise_error_set(options, (uint8_t) PM_ERRORS_FORMAT_STYLE);
                    }
                } else {
                    pm_options_raise_error_set(options, (uint8_t) PM_ERRORS_FORMAT_PLAIN);
                }
            } else {
                if (!SYMBOL_P(value)) {
                    rb_raise(rb_eTypeError, "wrong argument type %"PRIsVALUE" (expected Symbol)", rb_obj_class(value));
                }

                ID value_id = SYM2ID(value);
                if (value_id == rb_id_raise_error_plain) {
                    pm_options_raise_error_set(options, (uint8_t) PM_ERRORS_FORMAT_PLAIN);
                } else if (value_id == rb_id_raise_error_style) {
                    pm_options_raise_error_set(options, (uint8_t) PM_ERRORS_FORMAT_STYLE);
                } else if (value_id == rb_id_raise_error_color) {
                    pm_options_raise_error_set(options, (uint8_t) PM_ERRORS_FORMAT_COLOR);
                } else {
                    rb_raise(rb_eArgError, "invalid raise_error value: %" PRIsVALUE, value);
                }
            }
        }
    } else {
        rb_raise(rb_eArgError, "unknown keyword: %" PRIsVALUE, key);
    }

    return ST_CONTINUE;
}

/**
 * We need a struct here to pass through rb_protect and it has to be a single
 * value. Because the sizeof(VALUE) == sizeof(void *), we're going to pass this
 * through as an opaque pointer and cast it on both sides.
 */
struct build_options_data {
    pm_options_t *options;
    VALUE keywords;
};

/**
 * Build the set of options from the given keywords. Note that this can raise a
 * Ruby error if the options are not valid.
 */
static VALUE
build_options(VALUE argument) {
    struct build_options_data *data = (struct build_options_data *) argument;
    rb_hash_foreach(data->keywords, build_options_i, (VALUE) data->options);
    return Qnil;
}

/**
 * Extract the options from the given keyword arguments.
 */
static void
extract_options(pm_options_t *options, VALUE filepath, VALUE keywords) {
    pm_options_line_set(options, 1); /* default */
    options_version_set_nearest(options); /* default */

    if (!NIL_P(keywords)) {
        struct build_options_data data = { .options = options, .keywords = keywords };
        struct build_options_data *argument = &data;

        int state = 0;
        rb_protect(build_options, (VALUE) argument, &state);

        if (state != 0) {
            pm_options_free(options);
            rb_jump_tag(state);
        }
    }

    if (!NIL_P(filepath)) {
        if (!RB_TYPE_P(filepath, T_STRING)) {
            pm_options_free(options);
            rb_raise(rb_eTypeError, "wrong argument type %"PRIsVALUE" (expected String)", rb_obj_class(filepath));
        }

        pm_options_filepath_set(options, RSTRING_PTR(filepath));
    }
}

/**
 * Read options for methods that look like (source, **options).
 */
static VALUE
string_options(int argc, VALUE *argv, pm_options_t *options) {
    VALUE string;
    VALUE keywords;
    rb_scan_args(argc, argv, "1:", &string, &keywords);

    if (!RB_TYPE_P(string, T_STRING)) {
        pm_options_free(options);
        rb_raise(rb_eTypeError, "wrong argument type %"PRIsVALUE" (expected String)", rb_obj_class(string));
    }

    extract_options(options, Qnil, keywords);
    return string;
}

/**
 * Read options for methods that look like (filepath, **options).
 */
static pm_source_t *
file_options(int argc, VALUE *argv, pm_options_t *options, VALUE *encoded_filepath) {
    VALUE filepath;
    VALUE keywords;
    rb_scan_args(argc, argv, "1:", &filepath, &keywords);

    int state = 0;
    filepath = rb_protect(rb_get_path, filepath, &state);
    if (state != 0) {
        pm_options_free(options);
        rb_jump_tag(state);
    }

    *encoded_filepath = rb_str_encode_ospath(filepath);
    extract_options(options, *encoded_filepath, keywords);

    const char *source = (const char *) pm_string_source(pm_options_filepath(options));
    pm_source_init_result_t result;
    pm_source_t *pm_src = pm_source_file_new(source, &result);

    switch (result) {
        case PM_SOURCE_INIT_SUCCESS:
            break;
        case PM_SOURCE_INIT_ERROR_GENERIC: {
            pm_options_free(options);

#ifdef _WIN32
            int e = rb_w32_map_errno(GetLastError());
#else
            int e = errno;
#endif

            rb_syserr_fail(e, source);
            break;
        }
        case PM_SOURCE_INIT_ERROR_DIRECTORY:
            pm_options_free(options);
            rb_syserr_fail(EISDIR, source);
            break;
        default:
            pm_options_free(options);
            rb_raise(rb_eRuntimeError, "Unknown error (%d) initializing file: %s", result, source);
            break;
    }

    return pm_src;
}

/**
 * Check if the given parser has any errors and the raise option was set. If
 * both are true, format them and return the formatted error wrapped in a
 * result.
 */
static result_t
check_raise_error_option(pm_parser_t *parser, const pm_options_t *options, rb_encoding *path_encoding) {
    if (pm_parser_errors_size(parser) == 0) return result_ok(Qnil);

    uint8_t raise_error = pm_options_raise_error(options);
    if (raise_error == 0) return result_ok(Qnil);

    pm_buffer_t *buffer = pm_buffer_new();
    if (buffer == NULL) {
        return result_err(rb_exc_new_cstr(rb_eNoMemError, "failed to allocate memory"));
    }

    pm_error_level_t error_level = pm_errors_format(parser, buffer, (pm_errors_format_type_t) raise_error);

    /* Copy the message out of the buffer and free it before building any
     * other Ruby objects so that the buffer cannot be leaked if building the
     * objects raises. */
    rb_encoding *message_encoding = (error_level == PM_ERROR_LEVEL_LOAD) ? rb_locale_encoding() : rb_enc_find(pm_parser_encoding_name(parser));
    VALUE message = rb_enc_str_new(pm_buffer_value(buffer), (long) pm_buffer_length(buffer), message_encoding);
    pm_buffer_free(buffer);

    VALUE error = Qnil;
    switch (error_level) {
        case PM_ERROR_LEVEL_SYNTAX: {
            error = rb_exc_new_str(rb_eSyntaxError, message);

            rb_encoding *path_encoding_normal = path_encoding == NULL ? rb_utf8_encoding() : path_encoding;
            VALUE path = rb_enc_str_new((const char *) pm_string_source(pm_options_filepath(options)), pm_string_length(pm_options_filepath(options)), path_encoding_normal);
            rb_ivar_set(error, rb_intern_const("@path"), path);
            break;
        }
        case PM_ERROR_LEVEL_ARGUMENT: {
            error = rb_exc_new_str(rb_eArgError, message);
            break;
        }
        case PM_ERROR_LEVEL_LOAD: {
            error = rb_exc_new_str(rb_eLoadError, message);
            rb_ivar_set(error, rb_intern_const("@path"), Qnil);
            break;
        }
        case PM_ERROR_LEVEL_STACK: {
            error = rb_exc_new_str(rb_eSysStackError, message);
            break;
        }
    }

    return result_err(error);
}

#ifndef PRISM_EXCLUDE_SERIALIZATION

/******************************************************************************/
/* Serializing the AST                                                        */
/******************************************************************************/

/**
 * Dump the AST corresponding to the given input to a string.
 */
static result_t
dump_input(const uint8_t *input, size_t input_length, const pm_options_t *options, rb_encoding *path_encoding) {
    pm_arena_t *arena = pm_arena_new();
    pm_parser_t *parser = pm_parser_new(arena, input, input_length, options);
    pm_node_t *node = pm_parse(parser);

    result_t result = check_raise_error_option(parser, options, path_encoding);
    if (result.type == RESULT_OK) {
        pm_buffer_t *buffer = pm_buffer_new();
        if (buffer) {
            pm_serialize(parser, node, buffer);
            result = result_ok(rb_str_new(pm_buffer_value(buffer), pm_buffer_length(buffer)));
            pm_buffer_free(buffer);

            if (pm_options_freeze(options)) rb_obj_freeze(result.value);
        } else {
            result = result_err(rb_exc_new_cstr(rb_eNoMemError, "failed to allocate memory"));
        }
    }

    pm_parser_free(parser);
    pm_arena_free(arena);

    return result;
}

/**
 * :markup: markdown
 * call-seq:
 *   dump(source, **options) -> String
 *
 * Dump the AST corresponding to the given string to a string. For supported
 * options, see Prism.parse.
 */
static VALUE
dump(int argc, VALUE *argv, VALUE self) {
    pm_options_t *options = pm_options_new();
    VALUE string = string_options(argc, argv, options);

    const uint8_t *source = (const uint8_t *) RSTRING_PTR(string);
    size_t length = RSTRING_LEN(string);

#ifdef PRISM_BUILD_DEBUG
    char* dup = xmalloc(length);
    memcpy(dup, source, length);
    source = (const uint8_t *) dup;
#endif

    result_t result = dump_input(source, length, options, NULL);

#ifdef PRISM_BUILD_DEBUG
#ifdef xfree_sized
    xfree_sized(dup, length);
#else
    xfree(dup);
#endif
#endif

    pm_options_free(options);
    return result_get(result);
}

/**
 * :markup: markdown
 * call-seq:
 *   dump_file(filepath, **options) -> String
 *
 * Dump the AST corresponding to the given file to a string. For supported
 * options, see Prism.parse.
 */
static VALUE
dump_file(int argc, VALUE *argv, VALUE self) {
    pm_options_t *options = pm_options_new();

    VALUE encoded_filepath;
    pm_source_t *src = file_options(argc, argv, options, &encoded_filepath);

    result_t result = dump_input(pm_source_source(src), pm_source_length(src), options, rb_enc_get(encoded_filepath));
    pm_source_free(src);
    pm_options_free(options);

    return result_get(result);
}

#endif

/******************************************************************************/
/* Extracting values for the parse result                                     */
/******************************************************************************/

/**
 * The same as rb_class_new_instance, but accepts an additional boolean to
 * indicate whether or not the resulting class instance should be frozen.
 */
static inline VALUE
rb_class_new_instance_freeze(int argc, const VALUE *argv, VALUE klass, bool freeze) {
    VALUE value = rb_class_new_instance(argc, argv, klass);
    if (freeze) rb_obj_freeze(value);
    return value;
}

/**
 * Create a new Location instance from the given parser and bounds.
 */
static inline VALUE
parser_location(VALUE source, bool freeze, uint32_t start, uint32_t length) {
    VALUE argv[] = { source, LONG2FIX(start), LONG2FIX(length) };
    return rb_class_new_instance_freeze(3, argv, rb_cPrismLocation, freeze);
}

/**
 * Create a new Location instance from the given parser and location.
 */
#define PARSER_LOCATION(source, freeze, location) \
    parser_location(source, freeze, location.start, location.length)

/**
 * Build a new Comment instance from the given parser and comment.
 */
static inline VALUE
parser_comment(VALUE source, bool freeze, const pm_comment_t *comment) {
    VALUE argv[] = { PARSER_LOCATION(source, freeze, pm_comment_location(comment)) };
    VALUE type = (pm_comment_type(comment) == PM_COMMENT_EMBDOC) ? rb_cPrismEmbDocComment : rb_cPrismInlineComment;
    return rb_class_new_instance_freeze(1, argv, type, freeze);
}

/**
 * Extract the comments out of the parser into the given array, which was
 * created before the source so that the source could hold it. The caller may
 * have already resized it to the number of comments, so each comment is stored
 * at its index rather than pushed.
 */
static void
parser_comments(const pm_parser_t *parser, VALUE comments, VALUE source, bool freeze) {
    long index = 0;
    for (const pm_comment_t *comment = pm_parser_comments_first(parser); comment != NULL; comment = pm_comment_next(comment)) {
        rb_ary_store(comments, index++, parser_comment(source, freeze, comment));
    }

    if (freeze) rb_obj_freeze(comments);
}

/**
 * Build a new MagicComment instance from the given parser and magic comment.
 */
static inline VALUE
parser_magic_comment(VALUE source, bool freeze, const pm_magic_comment_t *magic_comment) {
    pm_location_t key = pm_magic_comment_key(magic_comment);
    pm_location_t value = pm_magic_comment_value(magic_comment);

    VALUE key_loc = parser_location(source, freeze, key.start, key.length);
    VALUE value_loc = parser_location(source, freeze, value.start, value.length);

    VALUE argv[] = { key_loc, value_loc };
    return rb_class_new_instance_freeze(2, argv, rb_cPrismMagicComment, freeze);
}

/**
 * Extract the magic comments out of the parser into an array.
 */
static VALUE
parser_magic_comments(const pm_parser_t *parser, VALUE source, bool freeze) {
    VALUE magic_comments = rb_ary_new_capa(pm_parser_magic_comments_size(parser));

    for (const pm_magic_comment_t *magic_comment = pm_parser_magic_comments_first(parser); magic_comment != NULL; magic_comment = pm_magic_comment_next(magic_comment)) {
        rb_ary_push(magic_comments, parser_magic_comment(source, freeze, magic_comment));
    }

    if (freeze) rb_obj_freeze(magic_comments);
    return magic_comments;
}

/**
 * Extract out the data location from the parser into a Location instance if one
 * exists.
 */
static VALUE
parser_data_loc(const pm_parser_t *parser, VALUE source, bool freeze) {
    const pm_location_t *data_loc = pm_parser_data_loc(parser);

    if (data_loc->length == 0) {
        return Qnil;
    } else {
        return parser_location(source, freeze, data_loc->start, data_loc->length);
    }
}

/**
 * Build a new ParseError instance from the given error.
 */
static VALUE
parser_error(const pm_diagnostic_t *diagnostic, rb_encoding *encoding, VALUE source, bool freeze) {
    VALUE type = ID2SYM(rb_intern(pm_diagnostic_type(diagnostic)));
    VALUE message = rb_obj_freeze(rb_enc_str_new_cstr(pm_diagnostic_message(diagnostic), encoding));
    VALUE location = PARSER_LOCATION(source, freeze, pm_diagnostic_location(diagnostic));

    pm_error_level_t error_level = pm_diagnostic_error_level(diagnostic);
    VALUE level = Qnil;

    switch (error_level) {
        case PM_ERROR_LEVEL_SYNTAX:
            level = ID2SYM(rb_intern("syntax"));
            break;
        case PM_ERROR_LEVEL_ARGUMENT:
            level = ID2SYM(rb_intern("argument"));
            break;
        case PM_ERROR_LEVEL_LOAD:
            level = ID2SYM(rb_intern("load"));
            break;
        case PM_ERROR_LEVEL_STACK:
            level = ID2SYM(rb_intern("stack"));
            break;
        default:
            rb_raise(rb_eRuntimeError, "Unknown level: %" PRIu8, error_level);
    }

    VALUE argv[] = { type, message, location, level };
    return rb_class_new_instance_freeze(4, argv, rb_cPrismParseError, freeze);
}

/**
 * Extract the errors out of the parser into an array.
 */
static VALUE
parser_errors(const pm_parser_t *parser, rb_encoding *encoding, VALUE source, bool freeze) {
    VALUE errors = rb_ary_new_capa(pm_parser_errors_size(parser));

    for (const pm_diagnostic_t *error = pm_parser_errors_first(parser); error != NULL; error = pm_diagnostic_next(error)) {
        rb_ary_push(errors, parser_error(error, encoding, source, freeze));
    }

    if (freeze) rb_obj_freeze(errors);
    return errors;
}

/**
 * Build a new ParseWarning instance from the given warning.
 */
static VALUE
parser_warning(const pm_diagnostic_t *diagnostic, rb_encoding *encoding, VALUE source, bool freeze) {
    VALUE type = ID2SYM(rb_intern(pm_diagnostic_type(diagnostic)));
    VALUE message = rb_obj_freeze(rb_enc_str_new_cstr(pm_diagnostic_message(diagnostic), encoding));
    VALUE location = PARSER_LOCATION(source, freeze, pm_diagnostic_location(diagnostic));

    pm_warning_level_t warning_level = pm_diagnostic_warning_level(diagnostic);
    VALUE level = Qnil;

    switch (warning_level) {
        case PM_WARNING_LEVEL_DEFAULT:
            level = ID2SYM(rb_intern("default"));
            break;
        case PM_WARNING_LEVEL_VERBOSE:
            level = ID2SYM(rb_intern("verbose"));
            break;
        default:
            rb_raise(rb_eRuntimeError, "Unknown level: %" PRIu8, warning_level);
    }

    VALUE argv[] = { type, message, location, level };
    return rb_class_new_instance_freeze(4, argv, rb_cPrismParseWarning, freeze);
}

/**
 * Extract the warnings out of the parser into an array.
 */
static VALUE
parser_warnings(const pm_parser_t *parser, rb_encoding *encoding, VALUE source, bool freeze) {
    VALUE warnings = rb_ary_new_capa(pm_parser_warnings_size(parser));

    for (const pm_diagnostic_t *warning = pm_parser_warnings_first(parser); warning != NULL; warning = pm_diagnostic_next(warning)) {
        rb_ary_push(warnings, parser_warning(warning, encoding, source, freeze));
    }

    if (freeze) rb_obj_freeze(warnings);
    return warnings;
}

/**
 * Create the arrays that hold the comments attached to each node, sized for the
 * parser's comment attachments. They stay empty unless the attach_comments
 * option was set.
 */
static void
parser_attachments_new(const pm_parser_t *parser, VALUE *attachments, VALUE *ranges) {
    uint32_t ranges_size = pm_parser_comment_ranges_size(parser);
    *attachments = rb_ary_new_capa(ranges_size == 0 ? 0 : (long) pm_parser_comments_size(parser));
    *ranges = rb_ary_new_capa(ranges_size == 0 ? 0 : (long) ranges_size + 1);
}

/**
 * Fill in the comments attached to each node. The attachments are the Comment
 * objects in the order of the parser's comment attachments, which groups them
 * by node in order of node id. The ranges are indexed by node id: for each node
 * that owns comments, the index at which its comments begin is stored at its
 * node id and the index at which they end is stored at the following node id.
 */
static void
parser_attachments(const pm_parser_t *parser, VALUE comments, VALUE attachments, VALUE ranges, bool freeze) {
    uint32_t ranges_size = pm_parser_comment_ranges_size(parser);

    if (ranges_size > 0) {
        long size = RARRAY_LEN(comments);

        for (long index = 0; index < size; index++) {
            rb_ary_store(attachments, index, RARRAY_AREF(comments, pm_parser_comment_attachment(parser, (uint32_t) index)));
        }

        for (uint32_t node_id = 0; node_id < ranges_size; node_id++) {
            pm_comment_range_t range = pm_parser_comment_range(parser, node_id);

            if (range.length > 0) {
                rb_ary_store(ranges, (long) node_id, LONG2FIX(range.index));
                rb_ary_store(ranges, (long) node_id + 1, LONG2FIX(range.index + range.length));
            }
        }
    }

    if (freeze) {
        rb_obj_freeze(attachments);
        rb_obj_freeze(ranges);
    }
}

/**
 * Create a new parse result from the given parser, value, encoding, and source.
 */
static VALUE
parse_result_create(VALUE class, const pm_parser_t *parser, VALUE value, rb_encoding *encoding, VALUE source, bool freeze) {
    VALUE result_argv[] = {
        value,
        parser_magic_comments(parser, source, freeze),
        parser_data_loc(parser, source, freeze),
        parser_errors(parser, encoding, source, freeze),
        parser_warnings(parser, encoding, source, freeze),
        pm_parser_continuable(parser) ? Qtrue : Qfalse,
        source
    };

    return rb_class_new_instance_freeze(7, result_argv, class, freeze);
}

/******************************************************************************/
/* Lexing Ruby code                                                           */
/******************************************************************************/

/**
 * This struct gets stored in the parser and passed in to the lex callback any
 * time a new token is found. We use it to store the necessary information to
 * initialize a Token instance.
 */
typedef struct {
    VALUE source;
    VALUE tokens;
    rb_encoding *encoding;
    bool freeze;
} parse_lex_data_t;

/**
 * This is passed as a callback to the parser. It gets called every time a new
 * token is found. Once found, we initialize a new instance of Token and push it
 * onto the tokens array.
 */
static void
parse_lex_token(pm_parser_t *parser, pm_token_t *token, void *data) {
    parse_lex_data_t *parse_lex_data = (parse_lex_data_t *) data;

    VALUE value = pm_token_new(parser, token, parse_lex_data->encoding, parse_lex_data->source, parse_lex_data->freeze);
    rb_ary_push(parse_lex_data->tokens, value);
}

/**
 * This is called whenever the encoding changes based on the magic comment at
 * the top of the file. We use it to update the encoding that we are using to
 * create tokens.
 */
static void
parse_lex_encoding_changed_callback(pm_parser_t *parser) {
    parse_lex_data_t *parse_lex_data = (parse_lex_data_t *) pm_parser_lex_callback_data(parser);
    parse_lex_data->encoding = rb_enc_find(pm_parser_encoding_name(parser));

    // Since the encoding changed, we need to go back and change the encoding of
    // the tokens that were already lexed. This is only going to end up being
    // one or two tokens, since the encoding can only change at the top of the
    // file.
    VALUE tokens = parse_lex_data->tokens;
    VALUE next_tokens = rb_ary_new();

    for (long index = 0; index < RARRAY_LEN(tokens); index++) {
        VALUE token = rb_ary_entry(tokens, index);
        VALUE value = rb_ivar_get(token, rb_intern("@value"));
        VALUE next_value = rb_str_dup(value);

        rb_enc_associate(next_value, parse_lex_data->encoding);
        if (parse_lex_data->freeze) rb_obj_freeze(next_value);

        VALUE next_token_argv[] = {
            parse_lex_data->source,
            rb_ivar_get(token, rb_intern("@type")),
            next_value,
            rb_ivar_get(token, rb_intern("@location")),
            rb_ivar_get(token, rb_intern("@state")),
        };

        VALUE next_token = rb_class_new_instance(5, next_token_argv, rb_cPrismToken);

        if (parse_lex_data->freeze) {
            rb_obj_freeze(next_token);
        }

        rb_ary_push(next_tokens, next_token);
    }

    rb_ary_replace(parse_lex_data->tokens, next_tokens);
}

/**
 * Parse the given input and return a ParseResult containing just the tokens or
 * the nodes and tokens.
 */
static result_t
parse_lex_input(const uint8_t *input, size_t input_length, const pm_options_t *options, rb_encoding *path_encoding, bool return_nodes) {
    pm_arena_t *arena = pm_arena_new();
    pm_parser_t *parser = pm_parser_new(arena, input, input_length, options);
    pm_parser_encoding_changed_callback_set(parser, parse_lex_encoding_changed_callback);

    VALUE source_string = rb_str_new((const char *) input, input_length);
    VALUE offsets = rb_ary_new_capa(pm_parser_line_offsets(parser)->size);
    VALUE comments = rb_ary_new();
    VALUE attachments = rb_ary_new();
    VALUE ranges = rb_ary_new();
    VALUE source = rb_funcall(rb_cPrismSource, rb_id_source_for, 6, source_string, LONG2NUM(pm_parser_start_line(parser)), offsets, comments, attachments, ranges);

    parse_lex_data_t parse_lex_data = {
        .source = source,
        .tokens = rb_ary_new(),
        .encoding = rb_enc_find(pm_parser_encoding_name(parser)),
        .freeze = pm_options_freeze(options),
    };

    parse_lex_data_t *data = &parse_lex_data;
    pm_parser_lex_callback_set(parser, parse_lex_token, data);

    pm_node_t *node = pm_parse(parser);

    result_t result = check_raise_error_option(parser, options, path_encoding);
    if (result.type == RESULT_OK) {
        /* Update the Source object with the correct encoding, line offsets,
         * and source hash, which are only available after pm_parse()
         * completes. */
        rb_encoding *encoding = rb_enc_find(pm_parser_encoding_name(parser));
        rb_enc_associate(source_string, encoding);

        const pm_line_offset_list_t *line_offsets = pm_parser_line_offsets(parser);
        for (size_t index = 0; index < line_offsets->size; index++) {
            rb_ary_store(offsets, (long) index, ULONG2NUM(line_offsets->offsets[index]));
        }

        rb_funcall(source, rb_intern("replace_checksum"), 1, ULL2NUM(pm_parser_checksum(parser)));

        if (pm_options_freeze(options)) {
            rb_obj_freeze(source_string);
            rb_obj_freeze(offsets);
            rb_obj_freeze(source);
            rb_obj_freeze(parse_lex_data.tokens);
        }

        /* The comment lists were created along with the source before parsing,
         * so they are grown to their final sizes now that those are known. */
        uint32_t ranges_size = pm_parser_comment_ranges_size(parser);
        rb_ary_resize(comments, (long) pm_parser_comments_size(parser));

        if (ranges_size > 0) {
            rb_ary_resize(attachments, (long) pm_parser_comments_size(parser));
            rb_ary_resize(ranges, (long) ranges_size + 1);
        }

        parser_comments(parser, comments, source, pm_options_freeze(options));
        parser_attachments(parser, comments, attachments, ranges, pm_options_freeze(options));

        if (return_nodes) {
            VALUE value = rb_ary_new_capa(2);
            rb_ary_push(value, pm_ast_new(parser, node, parse_lex_data.encoding, source, pm_options_freeze(options)));
            rb_ary_push(value, parse_lex_data.tokens);
            if (pm_options_freeze(options)) rb_obj_freeze(value);
            result = result_ok(parse_result_create(rb_cPrismParseLexResult, parser, value, parse_lex_data.encoding, source, pm_options_freeze(options)));
        } else {
            result = result_ok(parse_result_create(rb_cPrismLexResult, parser, parse_lex_data.tokens, parse_lex_data.encoding, source, pm_options_freeze(options)));
        }
    }

    pm_parser_free(parser);
    pm_arena_free(arena);

    return result;
}

/**
 * :markup: markdown
 * call-seq:
 *   lex(source, **options) -> LexResult
 *
 * Return a LexResult instance that contains an array of Token instances
 * corresponding to the given string. For supported options, see Prism.parse.
 */
static VALUE
lex(int argc, VALUE *argv, VALUE self) {
    pm_options_t *options = pm_options_new();
    VALUE string = string_options(argc, argv, options);

    result_t result = parse_lex_input((const uint8_t *) RSTRING_PTR(string), RSTRING_LEN(string), options, NULL, false);
    pm_options_free(options);

    return result_get(result);
}

/**
 * :markup: markdown
 * call-seq:
 *   lex_file(filepath, **options) -> LexResult
 *
 * Return a LexResult instance that contains an array of Token instances
 * corresponding to the given file. For supported options, see Prism.parse.
 */
static VALUE
lex_file(int argc, VALUE *argv, VALUE self) {
    pm_options_t *options = pm_options_new();

    VALUE encoded_filepath;
    pm_source_t *src = file_options(argc, argv, options, &encoded_filepath);

    result_t result = parse_lex_input(pm_source_source(src), pm_source_length(src), options, rb_enc_get(encoded_filepath), false);
    pm_source_free(src);
    pm_options_free(options);

    return result_get(result);
}

/******************************************************************************/
/* Parsing Ruby code                                                          */
/******************************************************************************/

/**
 * Parse the given input and return a ParseResult instance.
 */
static result_t
parse_input(const uint8_t *input, size_t input_length, const pm_options_t *options, rb_encoding *path_encoding) {
    pm_arena_t *arena = pm_arena_new();
    pm_parser_t *parser = pm_parser_new(arena, input, input_length, options);

    pm_node_t *node = pm_parse(parser);

    result_t result = check_raise_error_option(parser, options, path_encoding);
    if (result.type == RESULT_OK) {
        rb_encoding *encoding = rb_enc_find(pm_parser_encoding_name(parser));

        bool freeze = pm_options_freeze(options);
        VALUE comments = rb_ary_new_capa(pm_parser_comments_size(parser));
        VALUE attachments, ranges;
        parser_attachments_new(parser, &attachments, &ranges);

        VALUE source = pm_source_new(parser, encoding, comments, attachments, ranges, freeze);
        parser_comments(parser, comments, source, freeze);
        parser_attachments(parser, comments, attachments, ranges, freeze);

        VALUE value = pm_ast_new(parser, node, encoding, source, freeze);
        result = result_ok(parse_result_create(rb_cPrismParseResult, parser, value, encoding, source, freeze));
    }

    pm_parser_free(parser);
    pm_arena_free(arena);

    return result;
}

/**
 * :markup: markdown
 * call-seq:
 *   parse(source, **options) -> ParseResult
 *
 * Parse the given string and return a ParseResult instance. The options that
 * are supported are:
 *
 * * `attach_comments` - whether or not to attach each comment to the node that
 *       owns it. When set, the comments on the result are sorted by start
 *       offset. This should be a boolean or nil.
 * * `command_line` - either nil or a string of the various options that were
 *       set on the command line. Valid values are combinations of "a", "l",
 *       "n", "p", and "x".
 * * `encoding` - the encoding of the source being parsed. This should be an
 *       encoding or nil.
 * * `filepath` - the filepath of the source being parsed. This should be a
 *       string or nil.
 * * `freeze` - whether or not to deeply freeze the AST. This should be a
 *       boolean or nil.
 * * `frozen_string_literal` - whether or not the frozen string literal pragma
 *       has been set. This should be a boolean or nil.
 * * `line` - the line number that the parse starts on. This should be an
 *       integer or nil. Note that this is 1-indexed.
 * * `main_script` - a boolean indicating whether or not the source being parsed
 *       is the main script being run by the interpreter. This controls whether
 *       or not shebangs are parsed for additional flags and whether or not the
 *       parser will attempt to find a matching shebang if the first one does
 *       not contain the word "ruby".
 * * `partial_script` - when the file being parsed is considered a "partial"
 *       script, jumps will not be marked as errors if they are not contained
 *       within loops/blocks. This is used in the case that you're parsing a
 *       script that you know will be embedded inside another script later, but
 *       you do not have that context yet. For example, when parsing an ERB
 *       template that will be evaluated inside another script.
 * * `raise_error` - either nil, true, or a symbol indicating that an error
 *       should be raised if the source contains any errors. The message of
 *       the error will include the source of the lines that contain errors
 *       when possible, and the value of this option controls how those lines
 *       are formatted. Valid values are `:plain` (no formatting), `:style`
 *       (bold formatting), and `:color` (bold and color formatting). When
 *       `true` is given, the formatting is determined by whether or not
 *       `$stderr` is a terminal and whether or not the `NO_COLOR` environment
 *       variable is set, mirroring the behavior of CRuby itself. Syntax-level
 *       errors raise SyntaxError, argument-level errors raise ArgumentError,
 *       and load-level errors raise LoadError. Note that this option is
 *       honored by every API that accepts these options, including predicates
 *       like Prism.parse_success?, which will raise instead of returning a
 *       boolean when the source contains errors.
 * * `scopes` - the locals that are in scope surrounding the code that is being
 *       parsed. This should be an array of arrays of symbols or nil. Scopes are
 *       ordered from the outermost scope to the innermost one.
 * * `version` - the version of Ruby syntax that prism should used to parse Ruby
 *       code. By default prism parses with the syntax version nearest to the
 *       current Ruby that is running (which you can trigger with `nil` or
 *       `"nearest"`): the running version if prism supports it, otherwise the
 *       closest version that it does support. You may also restrict the syntax
 *       to a specific version of Ruby, e.g., with `"3.3.0"`. To parse with
 *       exactly the same syntax version that the current Ruby is running use
 *       `version: "current"`, which raises Prism::CurrentVersionError if prism
 *       does not support it. To parse with the latest version of Ruby syntax
 *       that prism supports, use `version: "latest"`. Raises ArgumentError if
 *       the version is not currently supported by Prism.
 */
static VALUE
parse(int argc, VALUE *argv, VALUE self) {
    pm_options_t *options = pm_options_new();
    VALUE string = string_options(argc, argv, options);

    const uint8_t *source = (const uint8_t *) RSTRING_PTR(string);
    size_t length = RSTRING_LEN(string);

#ifdef PRISM_BUILD_DEBUG
    char* dup = xmalloc(length);
    memcpy(dup, source, length);
    source = (const uint8_t *) dup;
#endif

    result_t result = parse_input(source, length, options, NULL);

#ifdef PRISM_BUILD_DEBUG
#ifdef xfree_sized
    xfree_sized(dup, length);
#else
    xfree(dup);
#endif
#endif

    pm_options_free(options);
    return result_get(result);
}

static ID
compile_insn_kind(PrismInsnKind kind) {
    switch (kind) {
        case kPrismInsnAliasMethod: return rb_intern_const("alias_method");
        case kPrismInsnBranch: return rb_intern_const("branch");
        case kPrismInsnBranchIf: return rb_intern_const("branch_if");
        case kPrismInsnCall: return rb_intern_const("call");
        case kPrismInsnCallToS: return rb_intern_const("call_to_s");
        case kPrismInsnCoerceHash: return rb_intern_const("coerce_hash");
        case kPrismInsnConvertToString: return rb_intern_const("convert_to_string");
        case kPrismInsnDefineClassAbs: return rb_intern_const("define_class_abs");
        case kPrismInsnDefineClassNestRel: return rb_intern_const("define_class_nest_rel");
        case kPrismInsnDefineClassRecvRel: return rb_intern_const("define_class_recv_rel");
        case kPrismInsnDefineMethod: return rb_intern_const("define_method");
        case kPrismInsnDefineSingletonClass: return rb_intern_const("define_singleton_class");
        case kPrismInsnDefinedCVar: return rb_intern_const("defined_cvar");
        case kPrismInsnDefinedGVar: return rb_intern_const("defined_gvar");
        case kPrismInsnExtractLastMatchGroup: return rb_intern_const("extract_last_match_group");
        case kPrismInsnExtractLastMatchMatch: return rb_intern_const("extract_last_match_match");
        case kPrismInsnExtractLastMatchParen: return rb_intern_const("extract_last_match_paren");
        case kPrismInsnExtractLastMatchPost: return rb_intern_const("extract_last_match_post");
        case kPrismInsnExtractLastMatchPre: return rb_intern_const("extract_last_match_pre");
        case kPrismInsnLoadConstAbs: return rb_intern_const("load_const_abs");
        case kPrismInsnLoadConstNestRel: return rb_intern_const("load_const_nest_rel");
        case kPrismInsnLoadConstRecvRel: return rb_intern_const("load_const_recv_rel");
        case kPrismInsnLoadCVar: return rb_intern_const("load_cvar");
        case kPrismInsnLoadGVar: return rb_intern_const("load_gvar");
        case kPrismInsnLoadIVar: return rb_intern_const("load_ivar");
        case kPrismInsnLoadLastMatch: return rb_intern_const("load_last_match");
        case kPrismInsnLoadLVar: return rb_intern_const("load_lvar");
        case kPrismInsnLoadObject: return rb_intern_const("load_object");
        case kPrismInsnLoadSelf: return rb_intern_const("load_self");
        case kPrismInsnMatch: return rb_intern_const("match");
        case kPrismInsnMergeHash: return rb_intern_const("merge_hash");
        case kPrismInsnNewArray: return rb_intern_const("new_array");
        case kPrismInsnNewArrayStatic: return rb_intern_const("new_array_static");
        case kPrismInsnNewHash: return rb_intern_const("new_hash");
        case kPrismInsnNewHashStatic: return rb_intern_const("new_hash_static");
        case kPrismInsnNewRangeExc: return rb_intern_const("new_range_exc");
        case kPrismInsnNewRangeInc: return rb_intern_const("new_range_inc");
        case kPrismInsnNewRegexp: return rb_intern_const("new_regexp");
        case kPrismInsnNewString: return rb_intern_const("new_string");
        case kPrismInsnNewSymbol: return rb_intern_const("new_symbol");
        case kPrismInsnReturn: return rb_intern_const("return");
        case kPrismInsnStoreConstAbs: return rb_intern_const("store_const_abs");
        case kPrismInsnStoreConstNestRel: return rb_intern_const("store_const_nest_rel");
        case kPrismInsnStoreConstRecvRel: return rb_intern_const("store_const_recv_rel");
        case kPrismInsnStoreCVar: return rb_intern_const("store_cvar");
        case kPrismInsnStoreGVar: return rb_intern_const("store_gvar");
        case kPrismInsnStoreIVar: return rb_intern_const("store_ivar");
        case kPrismInsnStoreLVar: return rb_intern_const("store_lvar");
        case kPrismInsnTraceCall: return rb_intern_const("trace_call");
        case kPrismInsnTraceClass: return rb_intern_const("trace_class");
        case kPrismInsnTraceEnd: return rb_intern_const("trace_end");
        case kPrismInsnTraceLine: return rb_intern_const("trace_line");
        case kPrismInsnTraceReturn: return rb_intern_const("trace_return");
        case kPrismInsnUndefMethod: return rb_intern_const("undef_method");
    }
}

static VALUE
compile_insn_data(VALUE vobjects_unit, VALUE vlocals_unit, VALUE vgraphs, VALUE vblocks, const pm_parser_t *parser, const PrismGraph *graph, const PrismInsn *insn, PrismInsnKind kind) {
    switch (kind) {
        case kPrismInsnBranch:
            return rb_ary_entry(vblocks, pm_insn_branch_block_id(insn));
        case kPrismInsnBranchIf: {
            VALUE then_block = rb_ary_entry(vblocks, pm_insn_branchif_then_block_id(insn));
            VALUE else_block = rb_ary_entry(vblocks, pm_insn_branchif_else_block_id(insn));
            VALUE then_nopnds = UINT2NUM(pm_insn_branchif_then_nopnds(insn));
            return rb_ary_new_from_args(3, then_block, else_block, then_nopnds);
        }
        case kPrismInsnCall:
        case kPrismInsnDefinedCVar:
        case kPrismInsnDefinedGVar:
        case kPrismInsnLoadCVar:
        case kPrismInsnLoadGVar:
        case kPrismInsnLoadIVar:
        case kPrismInsnStoreCVar:
        case kPrismInsnStoreGVar:
        case kPrismInsnStoreIVar: {
            const pm_constant_t *constant = pm_insn_name(parser, insn);
            return ID2SYM(rb_intern2((const char *) pm_constant_start(constant), pm_constant_length(constant)));
        }
        case kPrismInsnDefineClassAbs:
        case kPrismInsnDefineClassNestRel:
        case kPrismInsnDefineClassRecvRel:
        case kPrismInsnDefineMethod: {
            const pm_constant_t *constant = pm_insn_define_name(parser, insn);
            VALUE name = ID2SYM(rb_intern2((const char *) pm_constant_start(constant), pm_constant_length(constant)));
            VALUE graph = rb_ary_entry(vgraphs, pm_insn_define_graph_id(insn));
            return rb_ary_new_from_args(2, name, graph);
        }
        case kPrismInsnDefineSingletonClass:
            return rb_ary_entry(vgraphs, pm_insn_define_singleton_class_graph_id(insn));
        case kPrismInsnExtractLastMatchGroup:
            return UINT2NUM(pm_insn_extract_group_number(insn));
        case kPrismInsnLoadConstAbs:
        case kPrismInsnLoadConstNestRel:
        case kPrismInsnLoadConstRecvRel:
        case kPrismInsnStoreConstAbs:
        case kPrismInsnStoreConstNestRel:
        case kPrismInsnStoreConstRecvRel: {
            const PrismConstantPath *constant_path = pm_insn_constant_path(insn);
            uint32_t size = PrismConstantPath_size(constant_path);

            VALUE parts = rb_ary_new_capa(size);
            for (uint32_t idx = 0; idx < size; ++idx) {
                const pm_constant_t *constant = PrismConstantPath_constant(parser, constant_path, idx);
                rb_ary_push(parts, ID2SYM(rb_intern2((const char *) pm_constant_start(constant), pm_constant_length(constant))));
            }

            return parts;
        }
        case kPrismInsnLoadLVar:
        case kPrismInsnStoreLVar:
            return rb_ary_entry(vlocals_unit, pm_insn_local_id(insn));
        case kPrismInsnLoadObject:
        case kPrismInsnNewArrayStatic:
        case kPrismInsnNewHashStatic:
            return rb_ary_entry(vobjects_unit, pm_insn_object_id(insn));
        case kPrismInsnNewRegexp:
            return UINT2NUM(pm_insn_regexp_flags(insn));
        case kPrismInsnTraceLine:
            return INT2NUM(pm_insn_trace_lineno(insn));
        default:
            return Qnil;
    }
}

static VALUE
compile(int argc, VALUE *argv, VALUE self) {
    pm_options_t *options = pm_options_new();
    VALUE string = string_options(argc, argv, options);

    const uint8_t *source = (const uint8_t *) RSTRING_PTR(string);
    size_t length = RSTRING_LEN(string);

    pm_arena_t *arena = pm_arena_new();
    pm_parser_t *parser = pm_parser_new(arena, source, length, options);
    pm_node_t *node = pm_parse(parser);

    PrismUnit *unit = pm_unit_new();
    pm_compile(parser, node, arena, unit);

    uint32_t nobjects_unit = pm_unit_nobjects(unit);
    VALUE vobjects_unit = rb_ary_new_capa(nobjects_unit);
    rb_encoding *encoding = rb_enc_find(pm_parser_encoding_name(parser));

    for (uint32_t object_id = 0; object_id < nobjects_unit; ++object_id) {
        const PrismObject *object = pm_unit_object(unit, object_id);
        VALUE vobject;

        switch (pm_object_kind(object)) {
            case kPrismObjectArray: {
                uint32_t size = pm_object_array_size(object);
                vobject = rb_ary_new_capa(size);
                for (uint32_t idx = 0; idx < size; ++idx) {
                    rb_ary_push(vobject, rb_ary_entry(vobjects_unit, pm_object_array_object_id(object, idx)));
                }
                break;
            }
            case kPrismObjectClass: {
                const pm_constant_t *constant = pm_object_class_name(parser, object);
                ID name = rb_intern3((const char *) pm_constant_start(constant), pm_constant_length(constant), encoding);
                vobject = rb_const_get(rb_cObject, name);
                break;
            }
            case kPrismObjectHash: {
                uint32_t size = pm_object_hash_size(object);

                VALUE vbulk = rb_ary_hidden_new(size * 2);
                for (uint32_t idx = 0; idx < size; ++idx) {
                    VALUE vpair[] = {
                        rb_ary_entry(vobjects_unit, pm_object_hash_key_object_id(object, idx)),
                        rb_ary_entry(vobjects_unit, pm_object_hash_value_object_id(object, idx))
                    };

                    rb_ary_cat(vbulk, vpair, 2);
                }

                vobject = rb_hash_new();
                rb_hash_bulk_insert(RARRAY_LEN(vbulk), RARRAY_CONST_PTR(vbulk), vobject);
                break;
            }
            case kPrismObjectRegexp: {
                const pm_string_t *string = pm_object_string(object);
                vobject = rb_reg_new((const char *) pm_string_source(string), pm_string_length(string), 0);
                break;
            }
            case kPrismObjectString: {
                const pm_string_t *string = pm_object_string(object);
                vobject = rb_enc_str_new((const char *) pm_string_source(string), pm_string_length(string), encoding);
                break;
            }
            case kPrismObjectSymbol: {
                const pm_string_t *string = pm_object_string(object);
                vobject = ID2SYM(rb_intern3((const char *) pm_string_source(string), pm_string_length(string), encoding));
                break;
            }
            case kPrismObjectEncoding: vobject = rb_enc_from_encoding(rb_enc_find(pm_object_encoding_name(object))); break;
            case kPrismObjectFalse: vobject = Qfalse; break;
            case kPrismObjectFloat: vobject = DBL2NUM(pm_object_float(object)); break;
            case kPrismObjectImaginary: vobject = rb_complex_raw(INT2FIX(0), rb_ary_entry(vobjects_unit, pm_object_imaginary_object_id(object))); break;
            case kPrismObjectInteger: vobject = pm_integer_new(pm_object_integer(object)); break;
            case kPrismObjectNil: vobject = Qnil; break;
            case kPrismObjectRational: vobject = rb_rational_new(pm_integer_new(pm_object_rational_numerator(object)), pm_integer_new(pm_object_rational_denominator(object))); break;
            case kPrismObjectTrue: vobject = Qtrue; break;
        }

        rb_ary_push(vobjects_unit, vobject);
    }

    uint32_t nlocals_unit = pm_unit_nlocals(unit);
    VALUE vlocals_unit = rb_ary_new_capa(nlocals_unit);

    for (uint32_t local_id = 0; local_id < nlocals_unit; ++local_id) {
        const PrismLocal *local = pm_unit_local(unit, local_id);
        const pm_constant_t *constant = pm_local_name(parser, local);
        VALUE vlocal_argv[] = { ID2SYM(rb_intern2((const char *) pm_constant_start(constant), pm_constant_length(constant))) };
        VALUE vlocal = rb_class_new_instance(1, vlocal_argv, rb_cPrismCompileLocal);
        rb_ary_push(vlocals_unit, vlocal);
    }

    uint32_t ngraphs = pm_unit_ngraphs(unit);
    VALUE vgraphs = rb_ary_new_capa(ngraphs);

    for (uint32_t graph_id = 0; graph_id < ngraphs; ++graph_id) {
        const PrismGraph *graph = pm_unit_graph(unit, graph_id);

        VALUE vgraph_kind;
        switch (pm_graph_kind(graph)) {
            case kPrismGraphClass: vgraph_kind = ID2SYM(rb_intern("class")); break;
            case kPrismGraphDef: vgraph_kind = ID2SYM(rb_intern("def")); break;
            case kPrismGraphProgram: vgraph_kind = ID2SYM(rb_intern("program")); break;
            case kPrismGraphSingletonClass: vgraph_kind = ID2SYM(rb_intern("singleton_class")); break;
        }

        VALUE vparent = Qnil;
        uint32_t parent_id = pm_graph_parent_id(graph);
        if (parent_id != UINT32_MAX) {
            vparent = rb_ary_entry(vgraphs, parent_id);
        }

        uint32_t nblocks = pm_graph_nblocks(graph);
        VALUE vblocks = rb_ary_new_capa(nblocks);
        for (uint32_t block_id = 0; block_id < nblocks; ++block_id) {
            const PrismBlock *block = pm_graph_block(graph, block_id);

            uint32_t ninsns = pm_block_ninsns(block);
            VALUE vinsns = rb_ary_new_capa(ninsns);

            uint32_t nparams = pm_block_nparams(block);
            VALUE vparams = rb_ary_new_capa(nparams);
            for (uint32_t param_idx = 0; param_idx < nparams; ++param_idx) {
                uint32_t param = pm_block_param(block, param_idx);
                rb_ary_push(vparams, UINT2NUM(param));
            }

            VALUE vblock_argv[] = { vinsns, vparams };
            VALUE vblock = rb_class_new_instance(2, vblock_argv, rb_cPrismCompileBlock);
            rb_ary_push(vblocks, vblock);
        }

        uint32_t nlocals = pm_graph_nlocals(graph);
        VALUE vlocals = rb_ary_new_capa(nlocals);
        for (uint32_t local_idx = 0; local_idx < nlocals; ++local_idx) {
            uint32_t local_id = pm_graph_local_id(graph, local_idx);
            rb_ary_push(vlocals, rb_ary_entry(vlocals_unit, local_id));
        }

        VALUE vgraph_argv[] = { vgraph_kind, vparent, vblocks, vlocals };
        VALUE vgraph = rb_class_new_instance(4, vgraph_argv, rb_cPrismCompileGraph);
        rb_ary_push(vgraphs, vgraph);
    }

    VALUE vunit_argv[] = { vgraphs };
    VALUE vunit = rb_class_new_instance(1, vunit_argv, rb_cPrismCompileUnit);

    for (uint32_t graph_id = 0; graph_id < ngraphs; ++graph_id) {
        const PrismGraph *graph = pm_unit_graph(unit, graph_id);

        VALUE vgraph = rb_ary_entry(vgraphs, graph_id);
        VALUE vblocks = rb_ivar_get(vgraph, rb_intern_const("@blocks"));

        for (uint32_t block_id = 0; block_id < pm_graph_nblocks(graph); ++block_id) {
            const PrismBlock *block = pm_graph_block(graph, block_id);

            VALUE vblock = rb_ary_entry(vblocks, block_id);
            VALUE vinsns = rb_ivar_get(vblock, rb_intern_const("@insns"));

            for (uint32_t insn_idx = 0; insn_idx < pm_block_ninsns(block); ++insn_idx) {
                const PrismInsn *insn = pm_block_insn(block, insn_idx);

                PrismInsnKind kind = pm_insn_kind(insn);
                VALUE vkind = ID2SYM(compile_insn_kind(kind));

                uint32_t nopnds = pm_insn_nopnds(insn);
                VALUE vopnds = rb_ary_new_capa(nopnds);
                for (uint32_t opnd_idx = 0; opnd_idx < nopnds; ++opnd_idx) {
                    uint32_t opnd = pm_insn_opnd(graph, insn, opnd_idx);
                    rb_ary_push(vopnds, UINT2NUM(opnd));
                }

                VALUE vdata = compile_insn_data(vobjects_unit, vlocals_unit, vgraphs, vblocks, parser, graph, insn, kind);

                uint32_t node_id = pm_insn_node_id(insn);
                VALUE vnode_id = UINT2NUM(node_id);

                VALUE vinsn_argv[] = { vkind, vnode_id, vopnds, vdata };
                VALUE vinsn = rb_class_new_instance(4, vinsn_argv, rb_cPrismCompileInsn);
                rb_ary_push(vinsns, vinsn);
            }
        }
    }

    pm_parser_free(parser);
    pm_arena_free(arena);
    pm_options_free(options);

    return vunit;
}

/**
 * :markup: markdown
 * call-seq:
 *   parse_file(filepath, **options) -> ParseResult
 *
 * Parse the given file and return a ParseResult instance. For supported
 * options, see Prism.parse.
 */
static VALUE
parse_file(int argc, VALUE *argv, VALUE self) {
    pm_options_t *options = pm_options_new();

    VALUE encoded_filepath;
    pm_source_t *src = file_options(argc, argv, options, &encoded_filepath);

    result_t result = parse_input(pm_source_source(src), pm_source_length(src), options, rb_enc_get(encoded_filepath));
    pm_source_free(src);
    pm_options_free(options);

    return result_get(result);
}

/**
 * Parse the given input and return nothing.
 */
static result_t
profile_input(const uint8_t *input, size_t input_length, const pm_options_t *options, rb_encoding *path_encoding) {
    pm_arena_t *arena = pm_arena_new();
    pm_parser_t *parser = pm_parser_new(arena, input, input_length, options);

    pm_parse(parser);

    result_t result = check_raise_error_option(parser, options, path_encoding);
    pm_parser_free(parser);
    pm_arena_free(arena);

    return result;
}

/**
 * :markup: markdown
 * call-seq:
 *   profile(source, **options) -> nil
 *
 * Parse the given string and return nothing. This method is meant to allow
 * profilers to avoid the overhead of reifying the AST to Ruby. For supported
 * options, see Prism.parse.
 */
static VALUE
profile(int argc, VALUE *argv, VALUE self) {
    pm_options_t *options = pm_options_new();
    VALUE string = string_options(argc, argv, options);

    result_t result = profile_input((const uint8_t *) RSTRING_PTR(string), RSTRING_LEN(string), options, NULL);
    pm_options_free(options);
    result_get(result);

    return Qnil;
}

/**
 * :markup: markdown
 * call-seq:
 *   profile_file(filepath, **options) -> nil
 *
 * Parse the given file and return nothing. This method is meant to allow
 * profilers to avoid the overhead of reifying the AST to Ruby. For supported
 * options, see Prism.parse.
 */
static VALUE
profile_file(int argc, VALUE *argv, VALUE self) {
    pm_options_t *options = pm_options_new();

    VALUE encoded_filepath;
    pm_source_t *src = file_options(argc, argv, options, &encoded_filepath);

    result_t result = profile_input(pm_source_source(src), pm_source_length(src), options, rb_enc_get(encoded_filepath));
    pm_source_free(src);
    pm_options_free(options);
    result_get(result);

    return Qnil;
}

static int
parse_stream_eof(void *stream) {
    if (rb_funcall((VALUE) stream, rb_intern("eof?"), 0)) {
        return 1;
    }
    return 0;
}

/**
 * The largest number of bytes a single character can occupy in any encoding
 * that Ruby supports (CESU-8). `IO#gets(limit)` treats its argument as a soft
 * limit: to avoid splitting a multi-byte character it may return up to
 * `MAX_ENC_LEN - 1` more bytes than requested. Reserving `MAX_ENC_LEN` bytes of
 * headroom therefore leaves room for both that overshoot and the terminating
 * NUL byte.
 *
 * The value can be re-derived from the Ruby source tree with:
 *
 *   grep -Erh "max (enc|byte) length" enc | grep -Eo '[0-9]+' | sort | tail -n1
 */
#define MAX_ENC_LEN 6

/**
 * An implementation of fgets that is suitable for use with Ruby IO objects. As
 * required by pm_source_stream_fgets_t, this never writes more than `size`
 * bytes into `string` (including the terminating NUL byte).
 */
static char *
parse_stream_fgets(char *string, int size, void *stream) {
    RUBY_ASSERT(size > MAX_ENC_LEN);

    /*
     * Request fewer bytes than the buffer can hold. `gets` may return more
     * bytes than requested when the limit falls in the middle of a multi-byte
     * character, and the reserved headroom guarantees the result still fits.
     */
    VALUE line = rb_funcall((VALUE) stream, rb_intern("gets"), 1, INT2FIX(size - MAX_ENC_LEN));

    /*
     * A well-behaved stream returns a String, or nil at EOF. Coerce anything
     * else to nil so that we never treat a non-String as a byte buffer.
     */
    line = rb_check_string_type(line);
    if (NIL_P(line)) {
        return NULL;
    }

    const char *cstr = RSTRING_PTR(line);
    long length = RSTRING_LEN(line);

    /*
     * Defensively clamp the copy. A misbehaving `gets` may ignore the limit
     * entirely and return an arbitrarily long string; we must never write past
     * the caller's buffer. One byte is reserved for the NUL terminator.
     */
    if (length > (long) (size - 1)) {
        length = (long) (size - 1);
    }

    memcpy(string, cstr, (size_t) length);
    string[length] = '\0';

    return string;
}

#undef MAX_ENC_LEN

/**
 * :markup: markdown
 * call-seq:
 *   parse_stream(stream, **options) -> ParseResult
 *
 * Parse the given object that responds to `gets` and return a ParseResult
 * instance. The options that are supported are the same as Prism.parse.
 */
static VALUE
parse_stream(int argc, VALUE *argv, VALUE self) {
    VALUE stream;
    VALUE keywords;
    rb_scan_args(argc, argv, "1:", &stream, &keywords);

    pm_options_t *options = pm_options_new();
    extract_options(options, Qnil, keywords);

    pm_source_t *src = pm_source_stream_new((void *) stream, parse_stream_fgets, parse_stream_eof);
    pm_arena_t *arena = pm_arena_new();
    pm_parser_t *parser;

    pm_node_t *node = pm_parse_stream(&parser, arena, src, options);

    result_t result = check_raise_error_option(parser, options, NULL);
    if (result.type == RESULT_OK) {
        rb_encoding *encoding = rb_enc_find(pm_parser_encoding_name(parser));

        VALUE comments = rb_ary_new_capa(pm_parser_comments_size(parser));
        VALUE attachments, ranges;
        parser_attachments_new(parser, &attachments, &ranges);

        VALUE source = pm_source_new(parser, encoding, comments, attachments, ranges, pm_options_freeze(options));
        parser_comments(parser, comments, source, pm_options_freeze(options));
        parser_attachments(parser, comments, attachments, ranges, pm_options_freeze(options));

        VALUE value = pm_ast_new(parser, node, encoding, source, pm_options_freeze(options));

        result = result_ok(parse_result_create(rb_cPrismParseResult, parser, value, encoding, source, pm_options_freeze(options)));
    }

    pm_source_free(src);
    pm_parser_free(parser);
    pm_arena_free(arena);
    pm_options_free(options);

    return result_get(result);
}

/**
 * Parse the given input and return an array of Comment objects.
 */
static result_t
parse_input_comments(const uint8_t *input, size_t input_length, const pm_options_t *options, rb_encoding *path_encoding) {
    pm_arena_t *arena = pm_arena_new();
    pm_parser_t *parser = pm_parser_new(arena, input, input_length, options);

    pm_parse(parser);

    result_t result = check_raise_error_option(parser, options, path_encoding);
    if (result.type == RESULT_OK) {
        rb_encoding *encoding = rb_enc_find(pm_parser_encoding_name(parser));

        VALUE comments = rb_ary_new_capa(pm_parser_comments_size(parser));
        VALUE attachments, ranges;
        parser_attachments_new(parser, &attachments, &ranges);

        VALUE source = pm_source_new(parser, encoding, comments, attachments, ranges, pm_options_freeze(options));
        parser_comments(parser, comments, source, pm_options_freeze(options));
        parser_attachments(parser, comments, attachments, ranges, pm_options_freeze(options));

        result = result_ok(comments);
    }

    pm_parser_free(parser);
    pm_arena_free(arena);

    return result;
}

/**
 * :markup: markdown
 * call-seq:
 *   parse_comments(source, **options) -> Array
 *
 * Parse the given string and return an array of Comment objects. For supported
 * options, see Prism.parse.
 */
static VALUE
parse_comments(int argc, VALUE *argv, VALUE self) {
    pm_options_t *options = pm_options_new();
    VALUE string = string_options(argc, argv, options);

    result_t result = parse_input_comments((const uint8_t *) RSTRING_PTR(string), RSTRING_LEN(string), options, NULL);
    pm_options_free(options);

    return result_get(result);
}

/**
 * :markup: markdown
 * call-seq:
 *   parse_file_comments(filepath, **options) -> Array
 *
 * Parse the given file and return an array of Comment objects. For supported
 * options, see Prism.parse.
 */
static VALUE
parse_file_comments(int argc, VALUE *argv, VALUE self) {
    pm_options_t *options = pm_options_new();

    VALUE encoded_filepath;
    pm_source_t *src = file_options(argc, argv, options, &encoded_filepath);

    result_t result = parse_input_comments(pm_source_source(src), pm_source_length(src), options, rb_enc_get(encoded_filepath));
    pm_source_free(src);
    pm_options_free(options);

    return result_get(result);
}

/**
 * :markup: markdown
 * call-seq:
 *   parse_lex(source, **options) -> ParseLexResult
 *
 * Parse the given string and return a ParseLexResult instance that contains a
 * 2-element array, where the first element is the AST and the second element is
 * an array of Token instances.
 *
 * This API is only meant to be used in the case where you need both the AST and
 * the tokens. If you only need one or the other, use either Prism.parse or
 * Prism.lex.
 *
 * For supported options, see Prism.parse.
 */
static VALUE
parse_lex(int argc, VALUE *argv, VALUE self) {
    pm_options_t *options = pm_options_new();
    VALUE string = string_options(argc, argv, options);

    result_t result = parse_lex_input((const uint8_t *) RSTRING_PTR(string), RSTRING_LEN(string), options, NULL, true);
    pm_options_free(options);

    return result_get(result);
}

/**
 * :markup: markdown
 * call-seq:
 *   parse_lex_file(filepath, **options) -> ParseLexResult
 *
 * Parse the given file and return a ParseLexResult instance that contains a
 * 2-element array, where the first element is the AST and the second element is
 * an array of Token instances.
 *
 * This API is only meant to be used in the case where you need both the AST and
 * the tokens. If you only need one or the other, use either Prism.parse_file
 * or Prism.lex_file.
 *
 * For supported options, see Prism.parse.
 */
static VALUE
parse_lex_file(int argc, VALUE *argv, VALUE self) {
    pm_options_t *options = pm_options_new();

    VALUE encoded_filepath;
    pm_source_t *src = file_options(argc, argv, options, &encoded_filepath);

    result_t result = parse_lex_input(pm_source_source(src), pm_source_length(src), options, rb_enc_get(encoded_filepath), true);
    pm_source_free(src);
    pm_options_free(options);

    return result_get(result);
}

/**
 * Parse the given input and return true if it parses without errors.
 */
static result_t
parse_input_success_p(const uint8_t *input, size_t input_length, const pm_options_t *options, rb_encoding *path_encoding) {
    pm_arena_t *arena = pm_arena_new();
    pm_parser_t *parser = pm_parser_new(arena, input, input_length, options);
    pm_parse(parser);

    result_t result = check_raise_error_option(parser, options, path_encoding);
    if (result.type == RESULT_OK) {
        result = result_ok(pm_parser_errors_size(parser) == 0 ? Qtrue : Qfalse);
    }

    pm_parser_free(parser);
    pm_arena_free(arena);

    return result;
}

/**
 * :markup: markdown
 * call-seq:
 *   parse_success?(source, **options) -> bool
 *
 * Parse the given string and return true if it parses without errors. For
 * supported options, see Prism.parse.
 */
static VALUE
parse_success_p(int argc, VALUE *argv, VALUE self) {
    pm_options_t *options = pm_options_new();
    VALUE string = string_options(argc, argv, options);

    result_t result = parse_input_success_p((const uint8_t *) RSTRING_PTR(string), RSTRING_LEN(string), options, NULL);
    pm_options_free(options);

    return result_get(result);
}

/**
 * :markup: markdown
 * call-seq:
 *   parse_failure?(source, **options) -> bool
 *
 * Parse the given string and return true if it parses with errors. For
 * supported options, see Prism.parse.
 */
static VALUE
parse_failure_p(int argc, VALUE *argv, VALUE self) {
    return RTEST(parse_success_p(argc, argv, self)) ? Qfalse : Qtrue;
}

/**
 * :markup: markdown
 * call-seq:
 *   parse_file_success?(filepath, **options) -> bool
 *
 * Parse the given file and return true if it parses without errors. For
 * supported options, see Prism.parse.
 */
static VALUE
parse_file_success_p(int argc, VALUE *argv, VALUE self) {
    pm_options_t *options = pm_options_new();

    VALUE encoded_filepath;
    pm_source_t *src = file_options(argc, argv, options, &encoded_filepath);

    result_t result = parse_input_success_p(pm_source_source(src), pm_source_length(src), options, rb_enc_get(encoded_filepath));
    pm_source_free(src);
    pm_options_free(options);

    return result_get(result);
}

/**
 * :markup: markdown
 * call-seq:
 *   parse_file_failure?(filepath, **options) -> bool
 *
 * Parse the given file and return true if it parses with errors. For
 * supported options, see Prism.parse.
 */
static VALUE
parse_file_failure_p(int argc, VALUE *argv, VALUE self) {
    return RTEST(parse_file_success_p(argc, argv, self)) ? Qfalse : Qtrue;
}

/******************************************************************************/
/* String query methods                                                       */
/******************************************************************************/

/**
 * Process the result of a call to a string query method and return an
 * appropriate value.
 */
static VALUE
string_query(pm_string_query_t result) {
    switch (result) {
        case PM_STRING_QUERY_ERROR:
            rb_raise(rb_eArgError, "Invalid or non ascii-compatible encoding");
            return Qfalse;
        case PM_STRING_QUERY_FALSE:
            return Qfalse;
        case PM_STRING_QUERY_TRUE:
            return Qtrue;
    }
    return Qfalse;
}

/**
 * :markup: markdown
 * call-seq:
 *   local?(string) -> bool
 *
 * Returns true if the string constitutes a valid local variable name. Note that
 * this means the names that can be set through Binding#local_variable_set, not
 * necessarily the ones that can be set through a local variable assignment.
 */
static VALUE
string_query_local_p(VALUE self, VALUE string) {
    const uint8_t *source = (const uint8_t *) check_string(string);
    return string_query(pm_string_query_local(source, RSTRING_LEN(string), rb_enc_get(string)->name));
}

/**
 * :markup: markdown
 * call-seq:
 *   constant?(string) -> bool
 *
 * Returns true if the string constitutes a valid constant name. Note that this
 * means the names that can be set through Module#const_set, not necessarily the
 * ones that can be set through a constant assignment.
 */
static VALUE
string_query_constant_p(VALUE self, VALUE string) {
    const uint8_t *source = (const uint8_t *) check_string(string);
    return string_query(pm_string_query_constant(source, RSTRING_LEN(string), rb_enc_get(string)->name));
}

/**
 * :markup: markdown
 * call-seq:
 *   method_name?(string) -> bool
 *
 * Returns true if the string constitutes a valid method name.
 */
static VALUE
string_query_method_name_p(VALUE self, VALUE string) {
    const uint8_t *source = (const uint8_t *) check_string(string);
    return string_query(pm_string_query_method_name(source, RSTRING_LEN(string), rb_enc_get(string)->name));
}

/**
 * :markup: markdown
 * call-seq:
 *   keyword?(string) -> bool
 *
 * Returns true if the string is a valid keyword, such as `if`, `defined?`, or
 * `__FILE__`.
 */
static VALUE
string_query_keyword_p(VALUE self, VALUE string) {
    const uint8_t *source = (const uint8_t *) check_string(string);
    return string_query(pm_string_query_keyword(source, RSTRING_LEN(string), rb_enc_get(string)->name));
}

/******************************************************************************/
/* Initialization of the extension                                            */
/******************************************************************************/

/**
 * The init function that Ruby calls when loading this extension.
 */
RUBY_FUNC_EXPORTED void
Init_prism(void) {
    /* Make sure that the prism library version matches the expected version.
     * Otherwise something was compiled incorrectly. */
    if (strcmp(pm_version(), EXPECTED_PRISM_VERSION) != 0) {
        rb_raise(
            rb_eRuntimeError,
            "The prism library version (%s) does not match the expected version (%s)",
            pm_version(),
            EXPECTED_PRISM_VERSION
        );
    }

#ifdef HAVE_RB_EXT_RACTOR_SAFE
    /* Mark this extension as Ractor-safe. */
    rb_ext_ractor_safe(true);
#endif

    rb_cPrism = rb_define_module("Prism");
    rb_cPrismNode = rb_define_class_under(rb_cPrism, "Node", rb_cObject);
    rb_cPrismSource = rb_define_class_under(rb_cPrism, "Source", rb_cObject);
    rb_cPrismToken = rb_define_class_under(rb_cPrism, "Token", rb_cObject);
    rb_cPrismLocation = rb_define_class_under(rb_cPrism, "Location", rb_cObject);
    rb_cPrismComment = rb_define_class_under(rb_cPrism, "Comment", rb_cObject);
    rb_cPrismInlineComment = rb_define_class_under(rb_cPrism, "InlineComment", rb_cPrismComment);
    rb_cPrismEmbDocComment = rb_define_class_under(rb_cPrism, "EmbDocComment", rb_cPrismComment);
    rb_cPrismMagicComment = rb_define_class_under(rb_cPrism, "MagicComment", rb_cObject);
    rb_cPrismParseError = rb_define_class_under(rb_cPrism, "ParseError", rb_cObject);
    rb_cPrismParseWarning = rb_define_class_under(rb_cPrism, "ParseWarning", rb_cObject);
    rb_cPrismResult = rb_define_class_under(rb_cPrism, "Result", rb_cObject);
    rb_cPrismParseResult = rb_define_class_under(rb_cPrism, "ParseResult", rb_cPrismResult);
    rb_cPrismLexResult = rb_define_class_under(rb_cPrism, "LexResult", rb_cPrismResult);
    rb_cPrismParseLexResult = rb_define_class_under(rb_cPrism, "ParseLexResult", rb_cPrismResult);
    rb_cPrismStringQuery = rb_define_class_under(rb_cPrism, "StringQuery", rb_cObject);
    rb_cPrismScope = rb_define_class_under(rb_cPrism, "Scope", rb_cObject);

    rb_cPrismCurrentVersionError = rb_const_get(rb_cPrism, rb_intern("CurrentVersionError"));

    VALUE rb_cPrismCompile = rb_define_module_under(rb_cPrism, "Compile");
    rb_cPrismCompileLocal = rb_define_class_under(rb_cPrismCompile, "Local", rb_cObject);
    rb_cPrismCompileInsn = rb_define_class_under(rb_cPrismCompile, "Insn", rb_cObject);
    rb_cPrismCompileBlock = rb_define_class_under(rb_cPrismCompile, "Block", rb_cObject);
    rb_cPrismCompileGraph = rb_define_class_under(rb_cPrismCompile, "Graph", rb_cObject);
    rb_cPrismCompileUnit = rb_define_class_under(rb_cPrismCompile, "Unit", rb_cObject);

    /* Intern all of the IDs eagerly that we support so that we do not have to
     * do it every time we parse. */
    rb_id_option_attach_comments = rb_intern_const("attach_comments");
    rb_id_option_command_line = rb_intern_const("command_line");
    rb_id_option_encoding = rb_intern_const("encoding");
    rb_id_option_filepath = rb_intern_const("filepath");
    rb_id_option_freeze = rb_intern_const("freeze");
    rb_id_option_frozen_string_literal = rb_intern_const("frozen_string_literal");
    rb_id_option_line = rb_intern_const("line");
    rb_id_option_main_script = rb_intern_const("main_script");
    rb_id_option_partial_script = rb_intern_const("partial_script");
    rb_id_option_raise_error = rb_intern_const("raise_error");
    rb_id_option_scopes = rb_intern_const("scopes");
    rb_id_option_version = rb_intern_const("version");

    rb_id_source_for = rb_intern("for");

    rb_id_forwarding_positionals = rb_intern("*");
    rb_id_forwarding_keywords = rb_intern("**");
    rb_id_forwarding_block = rb_intern("&");
    rb_id_forwarding_all = rb_intern("...");

    rb_id_raise_error_plain = rb_intern_const("plain");
    rb_id_raise_error_style = rb_intern_const("style");
    rb_id_raise_error_color = rb_intern_const("color");

    /**
     * The version of the prism library.
     */
    rb_define_const(rb_cPrism, "VERSION", rb_str_freeze(rb_str_new_cstr(EXPECTED_PRISM_VERSION)));

    rb_define_singleton_method(rb_cPrism, "lex", lex, -1);
    rb_define_singleton_method(rb_cPrism, "lex_file", lex_file, -1);
    rb_define_singleton_method(rb_cPrism, "parse", parse, -1);
    rb_define_singleton_method(rb_cPrism, "parse_file", parse_file, -1);
    rb_define_singleton_method(rb_cPrism, "profile", profile, -1);
    rb_define_singleton_method(rb_cPrism, "profile_file", profile_file, -1);
    rb_define_singleton_method(rb_cPrism, "parse_stream", parse_stream, -1);
    rb_define_singleton_method(rb_cPrism, "parse_comments", parse_comments, -1);
    rb_define_singleton_method(rb_cPrism, "parse_file_comments", parse_file_comments, -1);
    rb_define_singleton_method(rb_cPrism, "parse_lex", parse_lex, -1);
    rb_define_singleton_method(rb_cPrism, "parse_lex_file", parse_lex_file, -1);
    rb_define_singleton_method(rb_cPrism, "parse_success?", parse_success_p, -1);
    rb_define_singleton_method(rb_cPrism, "parse_failure?", parse_failure_p, -1);
    rb_define_singleton_method(rb_cPrism, "parse_file_success?", parse_file_success_p, -1);
    rb_define_singleton_method(rb_cPrism, "parse_file_failure?", parse_file_failure_p, -1);

    rb_define_singleton_method(rb_cPrism, "compile", compile, -1);

#ifndef PRISM_EXCLUDE_SERIALIZATION
    rb_define_singleton_method(rb_cPrism, "dump", dump, -1);
    rb_define_singleton_method(rb_cPrism, "dump_file", dump_file, -1);
#endif

    rb_define_singleton_method(rb_cPrismStringQuery, "local?", string_query_local_p, 1);
    rb_define_singleton_method(rb_cPrismStringQuery, "constant?", string_query_constant_p, 1);
    rb_define_singleton_method(rb_cPrismStringQuery, "method_name?", string_query_method_name_p, 1);
    rb_define_singleton_method(rb_cPrismStringQuery, "keyword?", string_query_keyword_p, 1);

    Init_prism_api_node();
}
