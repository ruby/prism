#include <yarp.h>

static void
unescape (const char *input, size_t size, yp_unescape_type_t type) {
    yp_string_t *str = malloc (sizeof (yp_string_t));
    assert (str);
    yp_list_t *error_list = malloc (sizeof (yp_list_t));
    assert (error_list);
    yp_parser_t *parser = malloc(sizeof (yp_parser_t));
    assert (parser);
    yp_parser_init(parser, input, size, "unescape.c");
    yp_list_init (error_list);
    yp_unescape_manipulate_string (parser, input, size, str, type, error_list);
    yp_parser_free(parser);
    free(parser);
    yp_list_free (error_list);
    free (error_list);
    yp_string_free (str);
    free (str);
}

void
harness (const char *input, size_t size) {
    unescape (input, size, YP_UNESCAPE_ALL);
    unescape (input, size, YP_UNESCAPE_MINIMAL);
    unescape (input, size, YP_UNESCAPE_NONE);
}
