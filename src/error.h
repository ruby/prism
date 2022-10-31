#ifndef YARP_ERROR_H
#define YARP_ERROR_H

#include <stdlib.h>
#include <string.h>

#include "ast.h"
#include "util/yp_list.h"
#include "util/yp_string.h"

// This struct represents an error found during parsing.
typedef struct yp_error {
  yp_list_node_t node;
  yp_string_t message;
} yp_error_t;

// Append an error to the given list of errors.
void
yp_error_list_append(yp_list_t *list, const char *message, uint32_t position);

// Deallocate the internal state of the given error list.
void
yp_error_list_free(yp_list_t *list);

#endif
