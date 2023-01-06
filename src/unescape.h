#ifndef YARP_UNESCAPE_H
#define YARP_UNESCAPE_H

#include <assert.h>
#include <stdbool.h>
#include <string.h>

#include "util/yp_string.h"
#include "ast.h"

// The type of unescape we are performing.
typedef enum {
  // When we're creating a string inside of a list literal like %w, we shouldn't
  // escape anything.
  YP_UNESCAPE_NONE,

  // When we're unescaping a single-quoted string, we only need to unescape
  // single quotes and backslashes.
  YP_UNESCAPE_MINIMAL,

  // When we're unescaping a double-quoted string, we need to unescape all
  // escapes.
  YP_UNESCAPE_ALL
} yp_unescape_type_t;

// Unescape the contents of the given token into the given string using the
// given unescape mode.
void
yp_unescape(const yp_token_t *content, yp_string_t *string, yp_unescape_type_t unescape_type);

#endif
