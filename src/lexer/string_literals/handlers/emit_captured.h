#ifndef YARP_STRING_LITERALS_HANDLERS_EMIT_CAPTURED_H
#define YARP_STRING_LITERALS_HANDLERS_EMIT_CAPTURED_H

#include "lexer/string_literals/action.h"
#include "lexer/string_literals/interpolation.h"
#include "parser.h"

yp_string_literal_extend_action_t
yp_string_literal_emit_captured(yp_parser_t *parser);

#endif // YARP_STRING_LITERALS_HANDLERS_EMIT_CAPTURED_H
