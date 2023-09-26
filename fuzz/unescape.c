#include <prism.h>

static void
unescape(const uint8_t *input, size_t size, pm_unescape_type_t type) {
    pm_parser_t parser;
    pm_parser_init(&parser, input, size, "unescape.c");

    pm_string_t string = PM_EMPTY_STRING;
    pm_unescape_manipulate_string(&parser, &string, type);

    pm_parser_free(&parser);
    pm_string_free(&string);
}

void
harness(const uint8_t *input, size_t size) {
    unescape(input, size, PM_UNESCAPE_ALL);
    unescape(input, size, PM_UNESCAPE_MINIMAL);
    unescape(input, size, PM_UNESCAPE_NONE);
}
