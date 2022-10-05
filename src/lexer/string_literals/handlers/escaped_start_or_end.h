#ifndef YARP_STRING_LITERALS_HANDLERS_ESCAPED_START_OR_END_H
#define YARP_STRING_LITERALS_HANDLERS_ESCAPED_START_OR_END_H

#include "lexer/string_literals/action.h"
#include "parser.h"
#include <stddef.h>

yp_string_literal_extend_action_t
yp_string_literal_extend_escaped_start_or_end(yp_parser_t *parser, char starts_with, char ends_with);

#endif // YARP_STRING_LITERALS_HANDLERS_ESCAPED_START_OR_END_H
