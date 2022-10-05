#include "lexer/string_literals/handlers/emit_captured.h"

yp_string_literal_extend_action_t
yp_string_literal_emit_captured(yp_parser_t *parser) {
  if (parser->current.start != parser->current.end) {
    parser->current.type = YP_TOKEN_STRING_CONTENT;
    return EXTEND_ACTION_EMIT_TOKEN;
  }

  // Nothing has been captured
  return EXTEND_ACTION_NONE;
}
