#ifndef YARP_STRING_LITERALS_ARRAY_EXTEND_H
#define YARP_STRING_LITERALS_ARRAY_EXTEND_H

#include "lexer/string_literals/action.h"
#include "lexer/string_literals/array.h"
#include "parser.h"

yp_string_literal_extend_action_t
yp_string_literal_array_extend(yp_string_literal_array_t *literal, yp_parser_t *parser);

#endif // YARP_STRING_LITERALS_ARRAY_EXTEND_H
