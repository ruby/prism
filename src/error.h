#ifndef YARP_ERROR_H
#define YARP_ERROR_H

#include <stdlib.h>
#include <string.h>
#include "ast.h"
#include "util/yp_string.h"

// This struct represents an error found during parsing.
typedef struct yp_error {
  yp_string_t message;
  yp_location_t location;
  struct yp_error *next;
} yp_error_t;

// The struct manages a list of errors.
typedef struct {
  yp_error_t *head;
  yp_error_t *tail;
} yp_error_list_t;

// Allocate a new list of errors.
yp_error_list_t *
yp_error_list_alloc(void);

// Initializes a list of errors.
void
yp_error_list_init(yp_error_list_t *error_list);

// Append an error to the given list of errors.
void
yp_error_list_append(yp_error_list_t *error_list, const char *message, uint64_t position);

// Deallocate the internal state of the given error list.
void
yp_error_list_free(yp_error_list_t *error_list);

#endif
