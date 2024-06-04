#include <prism.h>

void
regexp_name_callback(const pm_string_t *name, void *data) {
    // Do nothing
}

void
harness(const uint8_t *input, size_t size) {
    pm_regexp_parse(input, size, false, PM_ENCODING_UTF_8_ENTRY, regexp_name_callback, NULL);
}
