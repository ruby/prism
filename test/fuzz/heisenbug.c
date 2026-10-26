#include <assert.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

void
harness(const uint8_t *input, size_t size);

int
LLVMFuzzerTestOneInput(const char *input, size_t size) {
    char *mutation_buffer = malloc(size + 1);
    assert(mutation_buffer);
    memcpy(mutation_buffer, input, size);

    // try all possible trailing bytes to see if it triggers
    // the bug
    for (unsigned int i = 0; i < UINT8_MAX; i++) {
        mutation_buffer[size] = (char) i;
        harness((const uint8_t *) mutation_buffer, size);
    }

    free(mutation_buffer);
    return 0;
}
