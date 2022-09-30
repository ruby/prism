#ifndef YARP_TOKEN_H
#define YARP_TOKEN_H

#include "token_type.h"
#include <stdlib.h>

// This struct represents a token in the Ruby source. We use it to track both
// type and location information.
typedef struct {
  yp_token_type_t type;
  const char *start;
  const char *end;
} yp_token_t;

typedef struct {
  yp_token_t *tokens;
  size_t size;
  size_t capacity;
} yp_token_list_t;

// Allocate a new yp_token_list_t.
yp_token_list_t *
yp_token_list_alloc();

// Append a token to the given list.
void
yp_token_list_append(yp_token_list_t *token_list, yp_token_t *token);

// Free the memory associated with the token list and the token list itself.
void
yp_token_list_dealloc(yp_token_list_t *token_list);

#endif // YARP_TOKEN_H
