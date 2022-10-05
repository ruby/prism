#include "escaped_start_or_end.h"
#include "emit_captured.h"
#include "try.h"

yp_string_literal_extend_action_t
yp_string_literal_extend_escaped_start_or_end(yp_parser_t *parser, char starts_with, char ends_with) {
  if (parser->current.end < parser->end && *parser->current.end == '\\') {
    if (parser->current.end + 1 < parser->end) {
      char escaped_char = *(parser->current.end + 1);
      if (escaped_char == starts_with || escaped_char == ends_with) {
        try_handler(yp_string_literal_emit_captured(parser));

        parser->current.end += 2;
        parser->current.type = YP_TOKEN_STRING_CONTENT;
        // TODO: store escaped char directly somewhere

        return EXTEND_ACTION_EMIT_TOKEN;
      }
    }
  }

  return EXTEND_ACTION_NONE;
}
