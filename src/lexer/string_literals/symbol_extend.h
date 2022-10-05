#ifndef YARP_STRING_LITERALS_SYMBOL_EXTEND_H
#define YARP_STRING_LITERALS_SYMBOL_EXTEND_H

#include "lexer/string_literals/action.h"
#include "parser.h"

yp_string_literal_extend_action_t
yp_string_literal_symbol_extend(yp_string_literal_symbol_t *literal, yp_parser_t *parser);

#endif // YARP_STRING_LITERALS_SYMBOL_EXTEND_H
