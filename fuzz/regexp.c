#include <prism.h>

void
regexp_name_callback(const pm_string_t *name, void *data) {
    // Do nothing
}

void
regexp_error_callback(const uint8_t *start, const uint8_t *end, const char *message, void *data) {
    // Do nothing
}

void
harness(const uint8_t *input, size_t size) {
    pm_arena_t arena = { 0 };
    pm_parser_t parser;
    pm_parser_init(&arena, &parser, input, size, NULL);

    pm_regexp_parse(&parser, input, size, false, regexp_name_callback, NULL, regexp_error_callback, NULL);

    pm_parser_free(&parser);
    pm_arena_free(&arena);
}
