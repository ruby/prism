#include "lexer/string_literals/handlers/line_continuation.h"
#include "lexer/string_literals/handlers/emit_captured.h"
#include "lexer/string_literals/handlers/try.h"

yp_string_literal_extend_action_t
yp_string_literal_extend_line_continuation(yp_parser_t *parser) {
  if (*parser->current.end == '\\' && parser->current.end + 1 < parser->end && *parser->current.end == '\n') {
    try_handler(yp_string_literal_emit_captured(parser));

    parser->current.type = YP_TOKEN_STRING_CONTENT;
    parser->current.end += 2;
    return EXTEND_ACTION_EMIT_TOKEN;
  }

  return EXTEND_ACTION_NONE;
}
