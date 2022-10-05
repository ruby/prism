#include "string.h"

// Constructs a shared string that is based on initial input.
yp_string_t *
yp_string_shared_create(const char *start, const char *end) {
  yp_string_t *string = malloc(sizeof(yp_string_t));

  *string = (yp_string_t) {
    .type = YP_STRING_SHARED,
    .as.shared = {
      .start = start,
      .end = end
    }
  };

  return string;
}

// Constructs an owned string that is responsible for freeing allocated memory.
yp_string_t *
yp_string_owned_create(char *source, size_t length) {
  yp_string_t *string = malloc(sizeof(yp_string_t));

  *string = (yp_string_t) {
    .type = YP_STRING_OWNED,
    .as.owned = {
      .source = source,
      .length = length
    }
  };

  return string;
}

// Returns the length associated with the string.
__attribute__ ((__visibility__("default"))) extern size_t
yp_string_length(const yp_string_t *string) {
  if (string->type == YP_STRING_SHARED) {
    return string->as.shared.end - string->as.shared.start;
  } else {
    return string->as.owned.length;
  }
}

// Returns the start pointer associated with the string.
__attribute__ ((__visibility__("default"))) extern const char *
yp_string_source(const yp_string_t *string) {
  if (string->type == YP_STRING_SHARED) {
    return string->as.shared.start;
  } else {
    return string->as.owned.source;
  }
}

// Destructor of a string, de-allocates internal state of the string
// if needed (i.e. if the string is owned).
void
yp_string_destroy(yp_string_t *string) {
  if (string->type == YP_STRING_OWNED) {
    free(string->as.owned.source);
  }
}
