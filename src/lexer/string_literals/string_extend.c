#include "lexer/string_literals/handlers/eof.h"
#include "lexer/string_literals/handlers/escape.h"
#include "lexer/string_literals/handlers/escaped_start_or_end.h"
#include "lexer/string_literals/handlers/interpolation.h"
#include "lexer/string_literals/handlers/interpolation_end.h"
#include "lexer/string_literals/handlers/line_continuation.h"
#include "lexer/string_literals/handlers/string_end.h"
#include "lexer/string_literals/handlers/try.h"
#include "lexer/string_literals/string_extend.h"
#include "parser.h"

yp_string_literal_extend_action_t
yp_string_literal_string_extend(yp_string_literal_string_t *literal, yp_parser_t *parser) {
  if (literal->interpolation.supported) {
    try_handler(yp_string_literal_extend_interpolation_end(parser, &(literal->interpolation)));
  }

  while (1) {
    try_handler(yp_string_literal_extend_eof(parser));

    if (literal->interpolation.supported) {
      try_handler(yp_string_literal_extend_line_continuation(parser));
    }

    if (literal->interpolation.supported) {
      try_handler(yp_string_literal_extend_escape(parser));
    } else {
      try_handler(yp_string_literal_extend_escaped_start_or_end(parser, literal->starts_with, literal->ends_with));
    }

    try_handler(yp_string_literal_extend_interpolation(parser, &(literal->interpolation)));

    try_handler(yp_string_literal_extend_string_end(parser, literal->starts_with, literal->ends_with,
                                                    &(literal->ends_with_nesting)));

    parser->current.end++;
  }
}
