#include <yarp.h>

void
harness(const char *input, size_t size) {
    yp_buffer_t buffer;
    yp_buffer_init(&buffer);
    yp_parse_serialize(input, size, &buffer, NULL);
    yp_buffer_free(&buffer);
}
