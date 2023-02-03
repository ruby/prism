#ifndef YARP_DIAGNOSTIC_H
#define YARP_DIAGNOSTIC_H

#include <stdlib.h>
#include <string.h>

#include "ast.h"
#include "util/yp_list.h"
#include "util/yp_string.h"

// This struct represents a diagnostic found during parsing.
typedef struct {
  yp_list_node_t node;
  uint32_t start;
  uint32_t end;
  yp_string_t message;
} yp_diagnostic_t;

// Append a diagnostic to the given list of diagnostics.
void
yp_diagnostic_list_append(yp_list_t *list, const char *message, uint32_t position);

// Deallocate the internal state of the given diagnostic list.
void
yp_diagnostic_list_free(yp_list_t *list);

#endif
