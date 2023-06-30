#include <yarp.h>

void
harness (const char *input, size_t size) {
    yp_buffer_t *buffer = malloc (sizeof (yp_buffer_t));
    yp_buffer_init (buffer);
    yp_parse_serialize ((const char *)input, size, buffer);
    yp_buffer_free (buffer);
    free (buffer);
}
