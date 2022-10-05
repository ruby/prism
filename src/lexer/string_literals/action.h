#ifndef YARP_STRING_LITERALS_ACTTION_H
#define YARP_STRING_LITERALS_ACTTION_H

#include "ast.h"
#include "parser.h"

typedef enum {
  EXTEND_ACTION_NONE,
  EXTEND_ACTION_EMIT_TOKEN,
  EXTEND_ACTION_READ_INTERPOLATED_CONTENT,
} yp_string_literal_extend_action_t;

#endif // YARP_STRING_LITERALS_ACTTION_H
