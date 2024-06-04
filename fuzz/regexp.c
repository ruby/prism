#include <prism.h>

void
regexp_name_callback(const pm_string_t *name, void *data) {
    // Do nothing
}

void
harness(const uint8_t *input, size_t size) {
    pm_parser_t parser;
    pm_parser_init(&parser, input, size, NULL);

    pm_regexp_parse(&parser, input, size, regexp_name_callback, NULL);

    pm_parser_free(&parser);
}
