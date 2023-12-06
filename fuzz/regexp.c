#include <prism.h>

void
harness(const uint8_t *input, size_t size) {
    pm_string_list_t capture_list = { 0 };
    pm_regexp_named_capture_group_names(input, size, &capture_list, false, PM_ENCODING_UTF_8_ENTRY);
    pm_string_list_free(&capture_list);
}
