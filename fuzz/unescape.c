#include <yarp.h>

static void
unescape(const char *input, size_t size, yp_unescape_type_t type) {
    yp_parser_t parser;
    yp_parser_init(&parser, input, size, "unescape.c");

    yp_string_t string = YP_EMPTY_STRING;
    yp_list_t error_list = YP_LIST_EMPTY;
    yp_unescape_manipulate_string(&parser, input, size, &string, type, &error_list);

    yp_parser_free(&parser);
    yp_string_free(&string);
    yp_list_free(&error_list);
}

void
harness(const char *input, size_t size) {
    unescape(input, size, YP_UNESCAPE_ALL);
    unescape(input, size, YP_UNESCAPE_MINIMAL);
    unescape(input, size, YP_UNESCAPE_NONE);
}
