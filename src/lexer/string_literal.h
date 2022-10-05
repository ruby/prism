#ifndef YARP_LEXER_STRING_LITERAL_H
#define YARP_LEXER_STRING_LITERAL_H

#include "lexer/string_literals/array.h"
#include "lexer/string_literals/heredoc.h"
#include "lexer/string_literals/interpolation.h"
#include "lexer/string_literals/regexp.h"
#include "lexer/string_literals/string.h"
#include "lexer/string_literals/symbol.h"
#include "util/stack.h"
#include <stdbool.h>
#include <stddef.h>

typedef struct {
  enum {
    LITERAL_STRING,
    LITERAL_SYMBOL,
    LITERAL_REGEXP,
    LITERAL_ARRAY,
    LITERAL_HEREDOC,
  } type;

  union {
    yp_string_literal_string_t string;
    yp_string_literal_symbol_t symbol;
    yp_string_literal_regexp_t regexp;
    yp_string_literal_array_t array;
    yp_string_literal_heredoc_t heredoc;
  } as;
} yp_string_literal_t;

// constructors
yp_string_literal_t
yp_string_literal_new_string(interpolation_t interpolation, char starts_with, char ends_with);
yp_string_literal_t
yp_string_literal_new_symbol(interpolation_t interpolation);
yp_string_literal_t
yp_string_literal_new_regexp(interpolation_t interpolation, char starts_with, char ends_with);
yp_string_literal_t
yp_string_literal_new_array(interpolation_t interpolation, char starts_with, char ends_with);
yp_string_literal_t
yp_string_literal_new_heredoc(interpolation_t interpolation, const char *heredoc_id_ended_at, bool squiggly);

// stack
STACK_DECL(yp_string_literal_stack_t, yp_string_literal_t, yp_string_literal_stack_create,
           yp_string_literal_stack_destroy, yp_string_literal_stack_push, yp_string_literal_stack_pop,
           yp_string_literal_stack_last, yp_string_literal_stack_size);

#endif // YARP_LEXER_STRING_LITERAL_H
