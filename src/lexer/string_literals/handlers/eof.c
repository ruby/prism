#include "lexer/string_literals/handlers/eof.h"
#include "lexer/string_literals/handlers/emit_captured.h"
#include "lexer/string_literals/handlers/try.h"

yp_string_literal_extend_action_t
yp_string_literal_extend_eof(yp_parser_t *parser) {
  if (parser->current.end >= parser->end) {
    // EOF reached, emit what has been captured so far (if any)
    try_handler(yp_string_literal_emit_captured(parser));

    // Nothing has been captured, emit EOF
    parser->current.type = YP_TOKEN_EOF;
    // TODO: pop current literal
    return EXTEND_ACTION_EMIT_TOKEN;
  }

  return EXTEND_ACTION_NONE;
}
