#ifndef YARP_TOKEN_H
#define YARP_TOKEN_H

#include "gen_token_type.h"
#include "string.h"

// This struct represents a token in the Ruby source. We use it to track both
// type and location information.
typedef struct {
  yp_token_type_t type;
  const char *start;
  const char *end;
} yp_token_t;

// Creates a string based on token
yp_string_t
token_to_string(yp_token_t token);

#endif // YARP_TOKEN_H
