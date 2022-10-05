#ifndef YARP_STRING_LITERALS_HANDLERS_ESCAPE_H
#define YARP_STRING_LITERALS_HANDLERS_ESCAPE_H

#include "lexer/string_literals/action.h"
#include "parser.h"
#include <stddef.h>

yp_string_literal_extend_action_t
yp_string_literal_extend_escape(yp_parser_t *parser);

#endif // YARP_STRING_LITERALS_HANDLERS_ESCAPE_H
