#include "yarp/util/yp_string.h"

// Initialize a shared string that is based on initial input.
void
yp_string_shared_init(yp_string_t *string, const char *start, const char *end) {
    *string = (yp_string_t) {
        .type = YP_STRING_SHARED,
        .as.shared = {
            .start = start,
            .end = end
        }
    };
}

// Initialize an owned string that is responsible for freeing allocated memory.
void
yp_string_owned_init(yp_string_t *string, char *source, size_t length) {
    *string = (yp_string_t) {
        .type = YP_STRING_OWNED,
        .as.owned = {
            .source = source,
            .length = length
        }
    };
}

// Initialize a constant string that doesn't own its memory source.
void
yp_string_constant_init(yp_string_t *string, const char *source, size_t length) {
    *string = (yp_string_t) {
        .type = YP_STRING_CONSTANT,
        .as.constant = {
            .source = source,
            .length = length
        }
    };
}

// Returns the length associated with the string.
YP_EXPORTED_FUNCTION size_t
yp_string_length(const yp_string_t *string) {
    if (string->type == YP_STRING_SHARED) {
        return (size_t) (string->as.shared.end - string->as.shared.start);
    } else {
        return string->as.owned.length;
    }
}

// Returns the start pointer associated with the string.
YP_EXPORTED_FUNCTION const char *
yp_string_source(const yp_string_t *string) {
    if (string->type == YP_STRING_SHARED) {
        return string->as.shared.start;
    } else {
        return string->as.owned.source;
    }
}

// Free the associated memory of the given string.
YP_EXPORTED_FUNCTION void
yp_string_free(yp_string_t *string) {
    if (string->type == YP_STRING_OWNED) {
        free(string->as.owned.source);
    }
}
