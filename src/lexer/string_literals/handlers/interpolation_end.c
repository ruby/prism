#include "interpolation_end.h"

yp_string_literal_extend_action_t
yp_string_literal_extend_interpolation_end(yp_parser_t *parser, interpolation_t *interpolation) {
  if (interpolation->active) {
    if (parser->current.end < parser->end && *parser->current.end == '}' &&
        interpolation->curly_level == parser->curly_level) {
      // Close interpolation
      parser->current.type = YP_TOKEN_BRACE_RIGHT;
      parser->current.end++;
      interpolation->active = false;
      return EXTEND_ACTION_EMIT_TOKEN;
    } else {
      // Yield control to lexer to read interpolated tokens
      return EXTEND_ACTION_READ_INTERPOLATED_CONTENT;
    }
  }

  return EXTEND_ACTION_NONE;
}
