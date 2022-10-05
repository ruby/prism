#ifndef YARP_STRING_LITERALS_ARRAY_H
#define YARP_STRING_LITERALS_ARRAY_H

#include "lexer/string_literals/interpolation.h"
#include <stddef.h>

typedef struct {
  interpolation_t interpolation;
  char starts_with;
  char ends_with;
  size_t ends_with_nesting;
} yp_string_literal_array_t;

#endif // YARP_STRING_LITERALS_ARRAY_H
