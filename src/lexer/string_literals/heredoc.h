#ifndef YARP_STRING_LITERALS_HEREDOC_H
#define YARP_STRING_LITERALS_HEREDOC_H

#include "lexer/string_literals/interpolation.h"
#include <stddef.h>

typedef struct {
  interpolation_t interpolation;
  const char *heredoc_id_ended_at;
  const char *heredoc_ended_at;
  bool squiggly;
} yp_string_literal_heredoc_t;

#endif // YARP_STRING_LITERALS_HEREDOC_H
