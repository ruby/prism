#include "string.h"
#include <stdlib.h>

yp_string_t
new_string_shared(const char *start, const char *end) {
  return (yp_string_t) { .type = STRING_SHARED, .as.shared = { .start = start, .end = end } };
}

yp_string_t
new_string_owned(char *ptr, size_t length) {
  return (yp_string_t) { .type = STRING_OWNED, .as.owned = { .ptr = ptr, .length = length } };
}

bool
is_string_shared(const yp_string_t *string) {
  return string->type == STRING_SHARED;
}

bool
is_string_owned(const yp_string_t *string) {
  return string->type == STRING_OWNED;
}

size_t
string_length(const yp_string_t *string) {
  if (string->type == STRING_SHARED) {
    return string->as.shared.end - string->as.shared.start;
  } else {
    return string->as.owned.length;
  }
}

const char *
string_ptr(const yp_string_t *string) {
  if (string->type == STRING_SHARED) {
    return string->as.shared.start;
  } else {
    return string->as.owned.ptr;
  }
}

void
string_drop(yp_string_t *string) {
  if (string->type == STRING_OWNED) {
    free(string->as.owned.ptr);
  }
}
