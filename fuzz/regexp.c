#include <yarp.h>

void
harness (const char *input, size_t size) {
    yp_string_list_t *capture_list = yp_string_list_alloc ();
    assert (capture_list);
    yp_string_list_init (capture_list);
    yp_regexp_named_capture_group_names ((const char *)input, size,
                                         capture_list);
    yp_string_list_free (capture_list);
    free (capture_list);
}
