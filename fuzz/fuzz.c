#include <stddef.h>
#include <stdint.h>

void harness (const char *input, size_t size);

int
LLVMFuzzerTestOneInput (const uint8_t *data, size_t size) {
    harness ((const char *)data, size);
    return 0;
}
