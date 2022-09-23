#ifndef YARP_TOKEN_H
#define YARP_TOKEN_H

#include "gen_token_type.h"

// This struct represents a token in the Ruby source. We use it to track both
// type and location information.
typedef struct {
  yp_token_type_t type;
  const char *start;
  const char *end;
} yp_token_t;

#endif // YARP_TOKEN_H
