#include <stddef.h>
#include <stdint.h>

void harness(const uint8_t *input, size_t size);

int
LLVMFuzzerTestOneInput(const char *data, size_t size) {
    harness((const uint8_t *) data, size);
    return 0;
}
