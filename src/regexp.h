#ifndef YARP_REGEXP_H
#define YARP_REGEXP_H

#include <stdbool.h>
#include <stddef.h>
#include <string.h>
#include <parser.h>
#include <util/yp_string.h>
#include <util/yp_string_list.h>

// This defines the kinds of results that can be returned by the parse
// functions.
typedef enum {
  YP_REGEXP_PARSE_RESULT_OK,
  YP_REGEXP_PARSE_RESULT_ERROR
} yp_regexp_parse_result_t;

// Parse a regular expression and extract the names of all of the named capture
// groups.
yp_regexp_parse_result_t
yp_regexp_named_capture_group_names(const char *source, size_t size, yp_encoding_t *encoding, yp_string_list_t *named_captures);

#endif
