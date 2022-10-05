#include "lexer/string_literals/handlers/escape.h"

yp_string_literal_extend_action_t
yp_string_literal_extend_escape(yp_parser_t *parser) {
  // FIXME: these must be an actual logic of escape sequence handling
  return EXTEND_ACTION_NONE;
}
