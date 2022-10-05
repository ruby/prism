#ifndef YARP_STRING_LITERALS_HANDLERS_STRING_END_H
#define YARP_STRING_LITERALS_HANDLERS_STRING_END_H

#include "lexer/string_literals/action.h"
#include "parser.h"
#include <stddef.h>

yp_string_literal_extend_action_t
yp_string_literal_extend_string_end(yp_parser_t *parser, char starts_with, char ends_with, size_t *ends_with_nesting);

#endif // YARP_STRING_LITERALS_HANDLERS_STRING_END_H
