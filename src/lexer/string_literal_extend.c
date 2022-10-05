#include "lexer/string_literal_extend.h"
#include "lexer/string_literals/array_extend.h"
#include "lexer/string_literals/heredoc_extend.h"
#include "lexer/string_literals/regexp_extend.h"
#include "lexer/string_literals/string_extend.h"
#include "lexer/string_literals/symbol_extend.h"

yp_string_literal_extend_action_t
yp_string_literal_extend(yp_string_literal_t *string_literal, yp_parser_t *parser) {
  switch (string_literal->type) {
    case LITERAL_STRING:
      return yp_string_literal_string_extend(&(string_literal->as.string), parser);
    case LITERAL_SYMBOL:
      return yp_string_literal_symbol_extend(&(string_literal->as.symbol), parser);
    case LITERAL_REGEXP:
      return yp_string_literal_regexp_extend(&(string_literal->as.regexp), parser);
    case LITERAL_ARRAY:
      return yp_string_literal_array_extend(&(string_literal->as.array), parser);
    case LITERAL_HEREDOC:
      return yp_string_literal_heredoc_extend(&(string_literal->as.heredoc), parser);
  }

  return EXTEND_ACTION_NONE;
}
