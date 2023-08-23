#include <yarp.h>

static void
unescape(const char *input, size_t size, yp_unescape_type_t type) {
    yp_parser_t parser;
    yp_parser_init(&parser, input, size, "unescape.c");

    yp_string_t string = YP_EMPTY_STRING;
    yp_unescape_manipulate_string(&parser, &string, type);

    yp_parser_free(&parser);
    yp_string_free(&string);
}

void
harness(const char *input, size_t size) {
    unescape(input, size, YP_UNESCAPE_ALL);
    unescape(input, size, YP_UNESCAPE_MINIMAL);
    unescape(input, size, YP_UNESCAPE_NONE);
}
