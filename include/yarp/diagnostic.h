#ifndef YARP_DIAGNOSTIC_H
#define YARP_DIAGNOSTIC_H

#include "yarp/defines.h"
#include "yarp/util/yp_list.h"

#include <stdbool.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <stdio.h>

#include "yarp/util/yp_list.h"
#include "parser.h"

// This struct represents a diagnostic found during parsing.
typedef struct {
    yp_list_node_t node;
    const char *start;
    const char *end;
    const char *message;
    const char *line;
    const char *line_start;
    size_t lineno;
} yp_diagnostic_t;

bool yp_vdiagnostic_list_append(yp_parser_t *parser, const char *start, const char *end, const char *message, ...);

// Append a diagnostic to the given list of diagnostics.
bool yp_diagnostic_list_append(yp_list_t *list, const char *start, const char *end, const char *message);

// Deallocate the internal state of the given diagnostic list.
void yp_diagnostic_list_free(yp_list_t *list);

#endif
