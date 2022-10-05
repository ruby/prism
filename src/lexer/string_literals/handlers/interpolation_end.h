#ifndef YARP_STRING_LITERALS_HANDLERS_INTERPOLATION_END_H
#define YARP_STRING_LITERALS_HANDLERS_INTERPOLATION_END_H

#include "lexer/string_literals/action.h"
#include "lexer/string_literals/interpolation.h"
#include "parser.h"
#include <stddef.h>

yp_string_literal_extend_action_t
yp_string_literal_extend_interpolation_end(yp_parser_t *parser, interpolation_t *interpolation);

#endif // YARP_STRING_LITERALS_HANDLERS_INTERPOLATION_END_H
