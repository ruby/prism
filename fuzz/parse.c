#include <prism.h>

void
harness(const uint8_t *input, size_t size) {
    pm_buffer_t buffer;
    pm_buffer_init(&buffer);
    pm_serialize_parse(&buffer, input, size, NULL);
    pm_buffer_free(&buffer);
}
