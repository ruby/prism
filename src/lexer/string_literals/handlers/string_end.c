#include "string_end.h"
#include "emit_captured.h"
#include "try.h"

yp_string_literal_extend_action_t
yp_string_literal_extend_string_end(yp_parser_t *parser, char starts_with, char ends_with, size_t *ends_with_nesting) {
  if (parser->current.end < parser->end) {
    char c = *parser->current.end;
    if (c == ends_with) {
      if (*ends_with_nesting == 0) {
        // match, actual string end
        try_handler(yp_string_literal_emit_captured(parser));

        parser->current.type = YP_TOKEN_STRING_END;
        parser->current.end++;

        return EXTEND_ACTION_EMIT_TOKEN;
      } else {
        // just a part of the string content like
        // %Q{ {} }
        //      ^
        *ends_with_nesting -= 1;
      }
    } else if (c == starts_with) {
      // also track occurrence of `starts_with` byte to handle cases like
      // %Q{ {} }
      //     ^^
      *ends_with_nesting += 1;
    }
  }

  return EXTEND_ACTION_NONE;
}
