#ifndef YARP_DIAGNOSTIC_H
#define YARP_DIAGNOSTIC_H

#include "yarp/defines.h"
#include "yarp/util/yp_list.h"
#include "yarp/parser.h"

#include <stdbool.h>
#include <stdlib.h>

// This struct represents a diagnostic found during parsing.
typedef struct {
    yp_list_node_t node;
    const uint8_t *start;
    const uint8_t *end;
    const char *message;
} yp_diagnostic_t;

// Append a diagnostic to the given list of warning diagnostics.
bool yp_diagnostic_warning_list_append(yp_parser_t *parser, const uint8_t *start, const uint8_t *end, const char *message);

// Append a diagnostic to the given list of error diagnostics.
bool yp_diagnostic_error_list_append(yp_parser_t *parser, const uint8_t *start, const uint8_t *end, const char *message);

// Deallocate the internal state of the given diagnostic list.
void yp_diagnostic_list_free(yp_list_t *list);

#endif
