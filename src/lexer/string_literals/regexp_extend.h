#ifndef YARP_STRING_LITERALS_REGEXP_EXTEND_H
#define YARP_STRING_LITERALS_REGEXP_EXTEND_H

#include "lexer/string_literals/action.h"
#include "lexer/string_literals/regexp.h"
#include "parser.h"

yp_string_literal_extend_action_t
yp_string_literal_regexp_extend(yp_string_literal_regexp_t *literal, yp_parser_t *parser);

#endif // YARP_STRING_LITERALS_REGEXP_EXTEND_H
