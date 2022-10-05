#include "lexer/string_literal.h"
#include "util/stack.h"

// constructors
yp_string_literal_t
yp_string_literal_new_string(interpolation_t interpolation, char starts_with, char ends_with) {
  return (yp_string_literal_t) {
    .type = LITERAL_STRING,
    .as.string = {
        .interpolation = interpolation,
        .starts_with = starts_with,
        .ends_with = ends_with,
        .ends_with_nesting = 0,
    },
  };
}
yp_string_literal_t
yp_string_literal_new_symbol(interpolation_t interpolation) {
  return (yp_string_literal_t) {
        .type = LITERAL_SYMBOL,
        .as.symbol = {
            .interpolation = interpolation,
        },
    };
}
yp_string_literal_t
yp_string_literal_new_regexp(interpolation_t interpolation, char starts_with, char ends_with) {
  return (yp_string_literal_t) {
        .type = LITERAL_REGEXP,
        .as.regexp = {
            .interpolation = interpolation,
            .starts_with = starts_with,
            .ends_with = ends_with,
            .ends_with_nesting = 0,
        },
    };
}
yp_string_literal_t
yp_string_literal_new_array(interpolation_t interpolation, char starts_with, char ends_with) {
  return (yp_string_literal_t) {
        .type = LITERAL_ARRAY,
        .as.array = {
            .interpolation = interpolation,
            .starts_with = starts_with,
            .ends_with = ends_with,
            .ends_with_nesting = 0,
        },
    };
}
yp_string_literal_t
yp_string_literal_new_heredoc(interpolation_t interpolation, const char *heredoc_id_ended_at, bool squiggly) {
  return (yp_string_literal_t) {
        .type = LITERAL_HEREDOC,
        .as.heredoc = {
            .interpolation = interpolation,
            .heredoc_id_ended_at = heredoc_id_ended_at,
            .heredoc_ended_at = 0,
            .squiggly = squiggly,
        },
    };
}

// stack
STACK_IMPL(yp_string_literal_stack_t, yp_string_literal_t, yp_string_literal_stack_create,
           yp_string_literal_stack_destroy, yp_string_literal_stack_push, yp_string_literal_stack_pop,
           yp_string_literal_stack_last, yp_string_literal_stack_size);
