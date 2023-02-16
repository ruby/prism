#include "yarp.h"

#define STRINGIZE0(expr) #expr
#define STRINGIZE(expr) STRINGIZE0(expr)
#define YP_VERSION_MACRO STRINGIZE(YP_VERSION_MAJOR) "." STRINGIZE(YP_VERSION_MINOR) "." STRINGIZE(YP_VERSION_PATCH)

char* yp_version(void) {
  return YP_VERSION_MACRO;
}

/******************************************************************************/
/* Node initializers                                                          */
/******************************************************************************/

// Allocate the space for a new yp_node_t. Currently we're not using the
// parser argument, but it's there to allow for the future possibility of
// pre-allocating larger memory pools and then pulling from those here.
static inline yp_node_t *
yp_node_alloc(yp_parser_t *parser) {
  return (yp_node_t *) malloc(sizeof(yp_node_t));
}

// Initiailize a list of nodes.
static inline void
yp_node_list_init(yp_node_list_t *node_list) {
  *node_list = (yp_node_list_t) { .nodes = NULL, .size = 0, .capacity = 0 };
}

// Append a new node onto the end of the node list.
static void
yp_node_list_append2(yp_node_list_t *list, yp_node_t *node) {
  if (list->size == list->capacity) {
    list->capacity = list->capacity == 0 ? 4 : list->capacity * 2;
    list->nodes = realloc(list->nodes, list->capacity * sizeof(yp_node_t *));
  }
  list->nodes[list->size++] = node;
}

// Allocate and initialize a new alias node.
static yp_node_t *
yp_alias_node_create(yp_parser_t *parser, const yp_token_t *keyword, yp_node_t *new_name, yp_node_t *old_name) {
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_ALIAS_NODE,
    .location = {
      .start = keyword->start,
      .end = old_name->location.end
    },
    .as.alias_node = {
      .keyword = *keyword,
      .new_name = new_name,
      .old_name = old_name
    }
  };

  return node;
}

// Allocate and initialize a new and node.
static yp_node_t *
yp_and_node_create(yp_parser_t *parser, yp_node_t *left, const yp_token_t *operator, yp_node_t *right) {
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_AND_NODE,
    .location = {
      .start = left->location.start,
      .end = right->location.end
    },
    .as.and_node = {
      .left = left,
      .operator = *operator,
      .right = right
    }
  };

  return node;
}

// Allocate an initialize a new arguments node.
static yp_node_t *
yp_arguments_node_create(yp_parser_t *parser) {
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_ARGUMENTS_NODE,
    .location = {
      .start = parser->start,
      .end = parser->start
    }
  };

  yp_node_list_init(&node->as.arguments_node.arguments);
  return node;
}

// Return the size of the given arguments node.
static inline size_t
yp_arguments_node_size(yp_node_t *node) {
  return node->as.arguments_node.arguments.size;
}

// Append an argument to an arguments node.
static void
yp_arguments_node_append(yp_node_t *arguments, yp_node_t *argument) {
  if (yp_arguments_node_size(arguments) == 0) {
    arguments->location.start = argument->location.start;
  }
  arguments->location.end = argument->location.end;
  yp_node_list_append2(&arguments->as.arguments_node.arguments, argument);
}

// Allocate and initialize a new ArrayNode node.
static yp_node_t *
yp_array_node_create(yp_parser_t *parser, const yp_token_t *opening, const yp_token_t *closing) {
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_ARRAY_NODE,
    .location = {
      .start = opening->start,
      .end = closing->end
    },
    .as.array_node = {
      .opening = *opening,
      .closing = *closing
    }
  };

  yp_node_list_init(&node->as.array_node.elements);
  return node;
}

// Return the size of the given array node.
static inline size_t
yp_array_node_size(yp_node_t *node) {
  return node->as.array_node.elements.size;
}

// Append an argument to an array node.
static inline void
yp_array_node_append(yp_node_t *node, yp_node_t *element) {
  yp_node_list_append2(&node->as.array_node.elements, element);
}

// Set the closing token and end location of an array node.
static inline void
yp_array_node_close_set(yp_node_t *node, const yp_token_t *closing) {
  node->location.end = closing->end;
  node->as.array_node.closing = *closing;
}

// Allocate and initialize a new assoc node.
static yp_node_t *
yp_assoc_node_create(yp_parser_t *parser, yp_node_t *key, const yp_token_t *operator, yp_node_t *value) {
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_ASSOC_NODE,
    .location = {
      .start = key->location.start,
      .end = value->location.end
    },
    .as.assoc_node = {
      .key = key,
      .operator = *operator,
      .value = value
    }
  };

  return node;
}

// Allocate and initialize a new assoc splat node.
static yp_node_t *
yp_assoc_splat_node_create(yp_parser_t *parser, yp_node_t *value, const yp_token_t *operator) {
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_ASSOC_SPLAT_NODE,
    .location = {
      .start = operator->start,
      .end = value->location.end
    },
    .as.assoc_splat_node = {
      .value = value,
      .operator_loc = {
        .start = operator->start,
        .end = operator->end
      }
    }
  };

  return node;
}

// Allocate and initialize new a begin node.
static yp_node_t *
yp_begin_node_create(yp_parser_t *parser, const yp_token_t *begin_keyword, yp_node_t *statements) {
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_BEGIN_NODE,
    .location = {
      .start = begin_keyword->start,
      .end = statements->location.end
    },
    .as.begin_node = {
      .begin_keyword = *begin_keyword,
      .statements = statements,
      .end_keyword = { .type = YP_TOKEN_NOT_PROVIDED, .start = parser->start, .end = parser->start }
    }
  };

  return node;
}

// Set the rescue clause and end location of a begin node.
static inline void
yp_begin_node_rescue_clause_set(yp_node_t *node, yp_node_t *rescue_clause) {
  node->location.end = rescue_clause->location.end;
  node->as.begin_node.rescue_clause = rescue_clause;
}

// Set the else clause and end location of a begin node.
static inline void
yp_begin_node_else_clause_set(yp_node_t *node, yp_node_t *else_clause) {
  node->location.end = else_clause->location.end;
  node->as.begin_node.else_clause = else_clause;
}

// Set the ensure clause and end location of a begin node.
static inline void
yp_begin_node_ensure_clause_set(yp_node_t *node, yp_node_t *ensure_clause) {
  node->location.end = ensure_clause->location.end;
  node->as.begin_node.ensure_clause = ensure_clause;
}

// Set the end keyword and end location of a begin node.
static inline void
yp_begin_node_end_keyword_set(yp_node_t *node, const yp_token_t *end_keyword) {
  node->location.end = end_keyword->end;
  node->as.begin_node.end_keyword = *end_keyword;
}

// Allocate and initialize a new BlockParameterNode node.
static yp_node_t *
yp_block_parameter_node_create(yp_parser_t *parser, const yp_token_t *name, const yp_token_t *operator) {
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_BLOCK_PARAMETER_NODE,
    .location = {
      .start = operator->start,
      .end = (name->type == YP_TOKEN_NOT_PROVIDED ? operator->end : name->end)
    },
    .as.block_parameter_node = {
      .name = *name,
      .operator_loc = {
        .start = operator->start,
        .end = operator->end
      }
    }
  };

  return node;
}

// Allocate and initialize a new BreakNode node.
static yp_node_t *
yp_break_node_create(yp_parser_t *parser, const yp_token_t *keyword, yp_node_t *arguments) {
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_BREAK_NODE,
    .location = {
      .start = keyword->start,
      .end = (arguments == NULL ? keyword->end : arguments->location.end)
    },
    .as.break_node = {
      .keyword = *keyword,
      .arguments = arguments
    }
  };

  return node;
}

// Allocate and initialize a new FalseNode node.
static yp_node_t *
yp_false_node_create(yp_parser_t *parser, const yp_token_t *token) {
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_FALSE_NODE,
    .location = {
      .start = token->start,
      .end = token->end
    }
  };

  return node;
}

// Allocate and initialize a new FloatNode node.
static yp_node_t *
yp_float_node_create(yp_parser_t *parser, const yp_token_t *token) {
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_FLOAT_NODE,
    .location = {
      .start = token->start,
      .end = token->end
    }
  };

  return node;
}

// Allocate and initialize a new ForwardingArgumentsNode node.
static yp_node_t *
yp_forwarding_arguments_node_create(yp_parser_t *parser, const yp_token_t *token) {
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_FORWARDING_ARGUMENTS_NODE,
    .location = {
      .start = token->start,
      .end = token->end
    }
  };

  return node;
}

// Allocate and initialize a new IntegerNode node.
static yp_node_t *
yp_integer_node_create(yp_parser_t *parser, const yp_token_t *token) {
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_INTEGER_NODE,
    .location = {
      .start = token->start,
      .end = token->end
    }
  };

  return node;
}

// Allocate and initialize a new RationalNode node.
static yp_node_t *
yp_rational_node_create(yp_parser_t *parser, const yp_token_t *token) {
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_RATIONAL_NODE,
    .location = {
      .start = token->start,
      .end = token->end
    }
  };

  return node;
}

// Allocate and initialize a new RedoNode node.
static yp_node_t *
yp_redo_node_create(yp_parser_t *parser, const yp_token_t *token) {
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_REDO_NODE,
    .location = {
      .start = token->start,
      .end = token->end
    }
  };

  return node;
}

// Allocate and initialize a new SelfNode node.
static yp_node_t *
yp_self_node_create(yp_parser_t *parser, const yp_token_t *token) {
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_SELF_NODE,
    .location = {
      .start = token->start,
      .end = token->end
    }
  };

  return node;
}

// Allocate and initialize a new TrueNode node.
static yp_node_t *
yp_true_node_create(yp_parser_t *parser, const yp_token_t *token) {
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_TRUE_NODE,
    .location = {
      .start = token->start,
      .end = token->end
    }
  };

  return node;
}

/******************************************************************************/
/* Debugging                                                                  */
/******************************************************************************/

__attribute__((unused)) static const char *
debug_context(yp_context_t context) {
  switch (context) {
    case YP_CONTEXT_BEGIN: return "BEGIN";
    case YP_CONTEXT_CLASS: return "CLASS";
    case YP_CONTEXT_DEF: return "DEF";
    case YP_CONTEXT_ENSURE: return "ENSURE";
    case YP_CONTEXT_ELSE: return "ELSE";
    case YP_CONTEXT_ELSIF: return "ELSIF";
    case YP_CONTEXT_EMBEXPR: return "EMBEXPR";
    case YP_CONTEXT_BLOCK_BRACES: return "BLOCK_BRACES";
    case YP_CONTEXT_FOR: return "FOR";
    case YP_CONTEXT_IF: return "IF";
    case YP_CONTEXT_MAIN: return "MAIN";
    case YP_CONTEXT_MODULE: return "MODULE";
    case YP_CONTEXT_PARENS: return "PARENS";
    case YP_CONTEXT_POSTEXE: return "POSTEXE";
    case YP_CONTEXT_PREEXE: return "PREEXE";
    case YP_CONTEXT_RESCUE: return "RESCUE";
    case YP_CONTEXT_RESCUE_ELSE: return "RESCUE ELSE";
    case YP_CONTEXT_SCLASS: return "SCLASS";
    case YP_CONTEXT_UNLESS: return "UNLESS";
    case YP_CONTEXT_UNTIL: return "UNTIL";
    case YP_CONTEXT_WHILE: return "WHILE";
  }
  return NULL;
}

__attribute__((unused)) static void
debug_contexts(yp_parser_t *parser) {
  yp_context_node_t *context_node = parser->current_context;
  fprintf(stderr, "CONTEXTS: ");

  if (context_node != NULL) {
    while (context_node != NULL) {
      fprintf(stderr, "%s", debug_context(context_node->context));
      context_node = context_node->prev;
      if (context_node != NULL) {
        fprintf(stderr, " <- ");
      }
    }
  } else {
    fprintf(stderr, "NONE");
  }

  fprintf(stderr, "\n");
}

__attribute__((unused)) static void
debug_node(const char *message, yp_parser_t *parser, yp_node_t *node) {
  yp_buffer_t buffer;
  yp_buffer_init(&buffer);
  yp_prettyprint(parser, node, &buffer);

  fprintf(stderr, "%s\n%.*s\n", message, (int) buffer.length, buffer.value);
  yp_buffer_free(&buffer);
}

__attribute__((unused)) static void
debug_lex_mode(yp_parser_t *parser) {
  yp_lex_mode_t *lex_mode = parser->lex_modes.current;

  switch (lex_mode->mode) {
    case YP_LEX_DEFAULT: fprintf(stderr, "lexing in DEFAULT mode\n"); return;
    case YP_LEX_EMBDOC: fprintf(stderr, "lexing in EMBDOC mode\n"); return;
    case YP_LEX_EMBEXPR: fprintf(stderr, "lexing in EMBEXPR mode\n"); return;
    case YP_LEX_EMBVAR: fprintf(stderr, "lexing in EMBVAR mode\n"); return;
    case YP_LEX_HEREDOC: fprintf(stderr, "lexing in HEREDOC mode\n"); return;
    case YP_LEX_LIST: fprintf(stderr, "lexing in LIST mode (terminator=%c, interpolation=%d)\n", lex_mode->as.list.terminator, lex_mode->as.list.interpolation); return;
    case YP_LEX_REGEXP: fprintf(stderr, "lexing in REGEXP mode (terminator=%c)\n", lex_mode->as.regexp.terminator); return;
    case YP_LEX_STRING: fprintf(stderr, "lexing in STRING mode (terminator=%c, interpolation=%d)\n", lex_mode->as.string.terminator, lex_mode->as.string.interpolation); return;
    case YP_LEX_SYMBOL: fprintf(stderr, "lexing in SYMBOL mode\n"); return;
  }
}

__attribute__((unused)) static void
debug_state(yp_parser_t *parser) {
  fprintf(stderr, "STATE: ");
  bool first = true;

  if (parser->lex_state == YP_LEX_STATE_NONE) {
    fprintf(stderr, "NONE\n");
    return;
  }

#define CHECK_STATE(state) \
  if (parser->lex_state & state) { \
    if (!first) fprintf(stderr, "|"); \
    fprintf(stderr, "%s", #state); \
    first = false; \
  }

  CHECK_STATE(YP_LEX_STATE_BEG)
  CHECK_STATE(YP_LEX_STATE_END)
  CHECK_STATE(YP_LEX_STATE_ENDARG)
  CHECK_STATE(YP_LEX_STATE_ENDFN)
  CHECK_STATE(YP_LEX_STATE_ARG)
  CHECK_STATE(YP_LEX_STATE_CMDARG)
  CHECK_STATE(YP_LEX_STATE_MID)
  CHECK_STATE(YP_LEX_STATE_FNAME)
  CHECK_STATE(YP_LEX_STATE_DOT)
  CHECK_STATE(YP_LEX_STATE_CLASS)
  CHECK_STATE(YP_LEX_STATE_LABEL)
  CHECK_STATE(YP_LEX_STATE_LABELED)
  CHECK_STATE(YP_LEX_STATE_FITEM)

#undef CHECK_STATE

  fprintf(stderr, "\n");
}

__attribute__((unused)) static void
debug_token(yp_token_t * token) {
  fprintf(stderr, "%s: \"%.*s\"\n", yp_token_type_to_str(token->type), (int) (token->end - token->start), token->start);
}

__attribute__((unused)) static void
debug_scope(yp_parser_t *parser) {
  fprintf(stderr, "SCOPE:\n");

  yp_token_list_t token_list = parser->current_scope->as.scope.locals;
  for (size_t index = 0; index < token_list.size; index++) {
    debug_token(&token_list.tokens[index]);
  }

  fprintf(stderr, "\n");
}

/******************************************************************************/
/* Basic character checks                                                     */
/******************************************************************************/

static inline bool
char_is_binary_number(const char c) {
  return c == '0' || c == '1';
}

static inline bool
char_is_octal_number(const char c) {
  return c >= '0' && c <= '7';
}

static inline bool
char_is_decimal_number(const char c) {
  return c >= '0' && c <= '9';
}

static inline bool
char_is_hexadecimal_number(const char c) {
  return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}

static inline size_t
char_is_identifier_start(yp_parser_t *parser, const char *c) {
  return (*c == '_') ? 1 : parser->encoding.alpha_char(c);
}

static inline size_t
char_is_identifier(yp_parser_t *parser, const char *c) {
  size_t width;

  if ((width = parser->encoding.alnum_char(c))) {
    return width;
  } else if (*c == '_') {
    return 1;
  } else {
    return 0;
  }
}

static inline bool
char_is_non_newline_whitespace(const char c) {
  return c == ' ' || c == '\t' || c == '\f' || c == '\r' || c == '\v';
}

static inline bool
char_is_whitespace(const char c) {
  return char_is_non_newline_whitespace(c) || c == '\n';
}

// This is a lookup table for whether or not an ASCII character is printable.
static const bool ascii_printable_chars[] = {
  0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0
};

static inline bool
char_is_ascii_printable(const char c) {
  return ascii_printable_chars[(unsigned char) c];
}

static inline bool
token_type_is_operator(yp_token_type_t type) {
  switch (type) {
    case YP_TOKEN_AMPERSAND:
    case YP_TOKEN_BACKTICK:
    case YP_TOKEN_BANG_EQUAL:
    case YP_TOKEN_BANG_TILDE:
    case YP_TOKEN_BANG:
    case YP_TOKEN_BRACKET_LEFT_RIGHT_EQUAL:
    case YP_TOKEN_BRACKET_LEFT_RIGHT:
    case YP_TOKEN_CARET:
    case YP_TOKEN_EQUAL_EQUAL_EQUAL:
    case YP_TOKEN_EQUAL_EQUAL:
    case YP_TOKEN_EQUAL_TILDE:
    case YP_TOKEN_GREATER_EQUAL:
    case YP_TOKEN_GREATER_GREATER:
    case YP_TOKEN_GREATER:
    case YP_TOKEN_LESS_EQUAL_GREATER:
    case YP_TOKEN_LESS_EQUAL:
    case YP_TOKEN_LESS_LESS:
    case YP_TOKEN_LESS:
    case YP_TOKEN_MINUS_AT:
    case YP_TOKEN_MINUS:
    case YP_TOKEN_PERCENT:
    case YP_TOKEN_PIPE:
    case YP_TOKEN_PLUS_AT:
    case YP_TOKEN_PLUS:
    case YP_TOKEN_SLASH:
    case YP_TOKEN_STAR_STAR:
    case YP_TOKEN_STAR:
    case YP_TOKEN_TILDE:
      return true;
    default:
      return false;
  }
}

static inline bool
token_type_is_keyword(yp_token_type_t type) {
  switch (type) {
    case YP_TOKEN_KEYWORD___LINE__:
    case YP_TOKEN_KEYWORD___FILE__:
    case YP_TOKEN_KEYWORD_ALIAS:
    case YP_TOKEN_KEYWORD_AND:
    case YP_TOKEN_KEYWORD_BEGIN:
    case YP_TOKEN_KEYWORD_BEGIN_UPCASE:
    case YP_TOKEN_KEYWORD_BREAK:
    case YP_TOKEN_KEYWORD_CASE:
    case YP_TOKEN_KEYWORD_CLASS:
    case YP_TOKEN_KEYWORD_DEF:
    case YP_TOKEN_KEYWORD_DEFINED:
    case YP_TOKEN_KEYWORD_DO:
    case YP_TOKEN_KEYWORD_DO_LOOP:
    case YP_TOKEN_KEYWORD_ELSE:
    case YP_TOKEN_KEYWORD_ELSIF:
    case YP_TOKEN_KEYWORD_END:
    case YP_TOKEN_KEYWORD_END_UPCASE:
    case YP_TOKEN_KEYWORD_ENSURE:
    case YP_TOKEN_KEYWORD_FALSE:
    case YP_TOKEN_KEYWORD_FOR:
    case YP_TOKEN_KEYWORD_IF:
    case YP_TOKEN_KEYWORD_IN:
    case YP_TOKEN_KEYWORD_MODULE:
    case YP_TOKEN_KEYWORD_NEXT:
    case YP_TOKEN_KEYWORD_NIL:
    case YP_TOKEN_KEYWORD_NOT:
    case YP_TOKEN_KEYWORD_OR:
    case YP_TOKEN_KEYWORD_REDO:
    case YP_TOKEN_KEYWORD_RESCUE:
    case YP_TOKEN_KEYWORD_RETRY:
    case YP_TOKEN_KEYWORD_RETURN:
    case YP_TOKEN_KEYWORD_SELF:
    case YP_TOKEN_KEYWORD_SUPER:
    case YP_TOKEN_KEYWORD_THEN:
    case YP_TOKEN_KEYWORD_TRUE:
    case YP_TOKEN_KEYWORD_UNDEF:
    case YP_TOKEN_KEYWORD_UNLESS:
    case YP_TOKEN_KEYWORD_UNTIL:
    case YP_TOKEN_KEYWORD_WHEN:
    case YP_TOKEN_KEYWORD_WHILE:
    case YP_TOKEN_KEYWORD_YIELD:
      return true;
    default:
      return false;
  }
}

/******************************************************************************/
/* Lexer check helpers                                                        */
/******************************************************************************/

// If the character to be read matches the given value, then returns true and
// advanced the current pointer.
static inline bool
match(yp_parser_t *parser, char value) {
  if (parser->current.end < parser->end && *parser->current.end == value) {
    parser->current.end++;
    return true;
  }
  return false;
}

// Returns the matching character that should be used to terminate a list
// beginning with the given character.
static char
terminator(const char start) {
  switch (start) {
    case '(':
      return ')';
    case '[':
      return ']';
    case '{':
      return '}';
    case '<':
      return '>';
    default:
      return start;
  }
}

/******************************************************************************/
/* Lex mode manipulations                                                     */
/******************************************************************************/

// Push a new lex state onto the stack. If we're still within the pre-allocated
// space of the lex state stack, then we'll just use a new slot. Otherwise we'll
// allocate a new pointer and use that.
static void
lex_mode_push(yp_parser_t *parser, yp_lex_mode_t lex_mode) {
  lex_mode.prev = parser->lex_modes.current;
  parser->lex_modes.index++;

  if (parser->lex_modes.index > YP_LEX_STACK_SIZE - 1) {
    parser->lex_modes.current = (yp_lex_mode_t *) malloc(sizeof(yp_lex_mode_t));
  } else {
    parser->lex_modes.stack[parser->lex_modes.index] = lex_mode;
    parser->lex_modes.current = &parser->lex_modes.stack[parser->lex_modes.index];
  }
}

// Pop the current lex state off the stack. If we're within the pre-allocated
// space of the lex state stack, then we'll just decrement the index. Otherwise
// we'll free the current pointer and use the previous pointer.
static void
lex_mode_pop(yp_parser_t *parser) {
  if (parser->lex_modes.index == 0) {
    parser->lex_modes.current->mode = YP_LEX_DEFAULT;
  } else if (parser->lex_modes.index < YP_LEX_STACK_SIZE) {
    parser->lex_modes.index--;
    parser->lex_modes.current = &parser->lex_modes.stack[parser->lex_modes.index];
  } else {
    parser->lex_modes.index--;
    yp_lex_mode_t *prev = parser->lex_modes.current->prev;
    free(parser->lex_modes.current);
    parser->lex_modes.current = prev;
  }
}

// This is the equivalent of IS_lex_state is CRuby.
static inline bool
lex_state_p(yp_parser_t *parser, yp_lex_state_t state) {
  return parser->lex_state & state;
}

// This is the equivalent of IS_lex_state_all_for in CRuby.
static inline bool
lex_states_p(yp_parser_t *parser, yp_lex_state_t states) {
  return (parser->lex_state & states) == states;
}

static inline bool
lex_state_beg_p(yp_parser_t *parser) {
  return lex_state_p(parser, YP_LEX_STATE_BEG_ANY) || lex_states_p(parser, YP_LEX_STATE_ARG | YP_LEX_STATE_LABELED);
}

static inline bool
lex_state_end_p(yp_parser_t *parser) {
  return lex_state_p(parser, YP_LEX_STATE_END_ANY);
}

// This is the equivalent of IS_AFTER_OPERATOR in CRuby.
static inline bool
lex_state_operator_p(yp_parser_t *parser) {
  return lex_state_p(parser, YP_LEX_STATE_FNAME | YP_LEX_STATE_DOT);
}

// Set the state of the lexer. This is defined as a function to be able to put a breakpoint in it.
static inline void
lex_state_set(yp_parser_t *parser, yp_lex_state_t state) {
  parser->lex_state = state;
}

/******************************************************************************/
/* Specific token lexers                                                      */
/******************************************************************************/

static yp_token_type_t
lex_optional_float_suffix(yp_parser_t *parser) {
  yp_token_type_t type = YP_TOKEN_INTEGER;

  // Here we're going to attempt to parse the optional decimal portion of a
  // float. If it's not there, then it's okay and we'll just continue on.
  if (*parser->current.end == '.') {
    if ((parser->current.end + 1 < parser->end) && char_is_decimal_number(parser->current.end[1])) {
      parser->current.end += 2;
      while (char_is_decimal_number(*parser->current.end)) {
        parser->current.end++;
        match(parser, '_');
      }

      type = YP_TOKEN_FLOAT;
    } else {
      // If we had a . and then something else, then it's not a float suffix on
      // a number it's a method call or something else.
      return type;
    }
  }

  // Here we're going to attempt to parse the optional exponent portion of a
  // float. If it's not there, it's okay and we'll just continue on.
  if (match(parser, 'e') || match(parser, 'E')) {
    (void) (match(parser, '+') || match(parser, '-'));

    if (char_is_decimal_number(*parser->current.end)) {
      parser->current.end++;
      while (char_is_decimal_number(*parser->current.end)) {
        parser->current.end++;
        match(parser, '_');
      }

      type = YP_TOKEN_FLOAT;
    } else {
      return YP_TOKEN_INVALID;
    }
  }

  return type;
}

static yp_token_type_t
lex_numeric_prefix(yp_parser_t *parser) {
  yp_token_type_t type = YP_TOKEN_INTEGER;

  if (parser->current.end[-1] == '0') {
    switch (*parser->current.end) {
      // 0d1111 is a decimal number
      case 'd':
      case 'D':
        if (!char_is_decimal_number(*++parser->current.end)) return YP_TOKEN_INVALID;
        while (char_is_decimal_number(*parser->current.end)) {
          parser->current.end++;
          match(parser, '_');
        }
        break;

      // 0b1111 is a binary number
      case 'b':
      case 'B':
        if (!char_is_binary_number(*++parser->current.end)) return YP_TOKEN_INVALID;
        while (char_is_binary_number(*parser->current.end)) {
          parser->current.end++;
          match(parser, '_');
        }
        break;

      // 0o1111 is an octal number
      case 'o':
      case 'O':
        if (!char_is_octal_number(*++parser->current.end)) return YP_TOKEN_INVALID;
        // fall through

      // 01111 is an octal number
      case '_':
      case '0':
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
        match(parser, '_');
        while (char_is_octal_number(*parser->current.end)) {
          parser->current.end++;
          match(parser, '_');
        }
        break;

      // 0x1111 is a hexadecimal number
      case 'x':
      case 'X':
        if (!char_is_hexadecimal_number(*++parser->current.end)) return YP_TOKEN_INVALID;
        while (char_is_hexadecimal_number(*parser->current.end)) {
          parser->current.end++;
          match(parser, '_');
        }
        break;

      // 0.xxx is a float
      case '.': {
        type = lex_optional_float_suffix(parser);
        break;
      }

      // 0exxx is a float
      case 'e':
      case 'E': {
        type = lex_optional_float_suffix(parser);
        break;
      }
    }
  } else {
    // If it didn't start with a 0, then we'll lex as far as we can into a
    // decimal number.
    match(parser, '_');
    while (char_is_decimal_number(*parser->current.end)) {
      parser->current.end++;
      match(parser, '_');
    }

    // Afterward, we'll lex as far as we can into an optional float suffix.
    type = lex_optional_float_suffix(parser);
  }

  // If the last character that we consumed was an underscore, then this is
  // actually an invalid integer value, and we should return an invalid token.
  if (parser->current.end[-1] == '_') return YP_TOKEN_INVALID;
  return type;
}

static yp_token_type_t
lex_numeric(yp_parser_t *parser) {
  yp_token_type_t type = lex_numeric_prefix(parser);

  if (type != YP_TOKEN_INVALID) {
    if (match(parser, 'r')) type = YP_TOKEN_RATIONAL_NUMBER;
    if (match(parser, 'i')) type = YP_TOKEN_IMAGINARY_NUMBER;
  }

  return type;
}

static yp_token_type_t
lex_global_variable(yp_parser_t *parser) {
  switch (*parser->current.end) {
    case '~':  // $~: match-data
    case '*':  // $*: argv
    case '$':  // $$: pid
    case '?':  // $?: last status
    case '!':  // $!: error string
    case '@':  // $@: error position
    case '/':  // $/: input record separator
    case '\\': // $\: output record separator
    case ';':  // $;: field separator
    case ',':  // $,: output field separator
    case '.':  // $.: last read line number
    case '=':  // $=: ignorecase
    case ':':  // $:: load path
    case '<':  // $<: reading filename
    case '>':  // $>: default output handle
    case '\"': // $": already loaded files
      parser->current.end++;
      return YP_TOKEN_GLOBAL_VARIABLE;

    case '&':  // $&: last match
    case '`':  // $`: string before last match
    case '\'': // $': string after last match
    case '+':  // $+: string matches last paren.
      parser->current.end++;
      return YP_TOKEN_BACK_REFERENCE;

    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
      do {
        parser->current.end++;
      } while (char_is_decimal_number(*parser->current.end));
      return YP_TOKEN_NTH_REFERENCE;

    default:
      if (char_is_identifier(parser, parser->current.end)) {
        do {
          parser->current.end++;
        } while (char_is_identifier(parser, parser->current.end));
        return YP_TOKEN_GLOBAL_VARIABLE;
      }

      // If we get here, then we have a $ followed by something that isn't
      // recognized as a global variable.
      return YP_TOKEN_INVALID;
  }
}

// This function checks if the current token matches a keyword. If it does, it
// returns true. Otherwise, it returns false. The arguments are as follows:
//
// * `value` - the literal string that we're checking for
// * `width` - the length of the token
// * `state` - the state that we should transition to if the token matches
//
static bool
lex_keyword(yp_parser_t *parser, const char *value, yp_lex_state_t state, bool modifier_allowed) {
  if (strncmp(parser->current.start, value, strlen(value)) == 0) {
    if (parser->lex_state & YP_LEX_STATE_FNAME) {
      lex_state_set(parser, YP_LEX_STATE_ENDFN);
    } else {
      lex_state_set(parser, state);
      if (state == YP_LEX_STATE_BEG) {
        parser->command_start = true;
      }

      if (!(parser->lex_state & (YP_LEX_STATE_BEG | YP_LEX_STATE_LABELED | YP_LEX_STATE_CLASS)) && modifier_allowed) {
        lex_state_set(parser, YP_LEX_STATE_BEG | YP_LEX_STATE_LABEL);
      }
    }

    return true;
  }

  return false;
}

static yp_token_type_t
lex_identifier(yp_parser_t *parser) {
  // Lex as far as we can into the current identifier.
  size_t width;
  while ((width = char_is_identifier(parser, parser->current.end))) {
    parser->current.end += width;
  }

  // Now cache the length of the identifier so that we can quickly compare it
  // against known keywords.
  width = parser->current.end - parser->current.start;

  if (parser->current.end < parser->end) {
    // If we're in a position where we can accept a = at the end of an
    // identifier, then we'll optionally accept it.
    if ((parser->previous.type == YP_TOKEN_KEYWORD_DEF || parser->previous.type == YP_TOKEN_DOT) && match(parser, '=')) {
      return YP_TOKEN_IDENTIFIER;
    }

    // Else we'll attempt to extend the identifier by a ! or ?. Then we'll check
    // if we're returning the defined? keyword or just an identifier.
    if ((parser->current.end[1] != '=') && (match(parser, '!') || match(parser, '?'))) {
      width++;

      if (parser->lex_state != YP_LEX_STATE_DOT) {
        if (width == 8 && lex_keyword(parser, "defined?", YP_LEX_STATE_ARG, false)) {
          return YP_TOKEN_KEYWORD_DEFINED;
        }
      }

      return YP_TOKEN_IDENTIFIER;
    }
  }

  if (parser->lex_state != YP_LEX_STATE_DOT) {
    switch (width) {
      case 2:
        if (lex_keyword(parser, "do", YP_LEX_STATE_BEG, false)) {
          if (yp_state_stack_p(&parser->do_loop_stack)) {
            return YP_TOKEN_KEYWORD_DO_LOOP;
          }
          return YP_TOKEN_KEYWORD_DO;
        }

        if (lex_keyword(parser, "if", YP_LEX_STATE_BEG, true)) return YP_TOKEN_KEYWORD_IF;
        if (lex_keyword(parser, "in", YP_LEX_STATE_BEG, false)) return YP_TOKEN_KEYWORD_IN;
        if (lex_keyword(parser, "or", YP_LEX_STATE_BEG, false)) return YP_TOKEN_KEYWORD_OR;
        break;
      case 3:
        if (lex_keyword(parser, "and", YP_LEX_STATE_BEG, false)) return YP_TOKEN_KEYWORD_AND;
        if (lex_keyword(parser, "def", YP_LEX_STATE_FNAME, false)) return YP_TOKEN_KEYWORD_DEF;
        if (lex_keyword(parser, "end", YP_LEX_STATE_END, false)) return YP_TOKEN_KEYWORD_END;
        if (lex_keyword(parser, "END", YP_LEX_STATE_END, false)) return YP_TOKEN_KEYWORD_END_UPCASE;
        if (lex_keyword(parser, "for", YP_LEX_STATE_BEG, false)) return YP_TOKEN_KEYWORD_FOR;
        if (lex_keyword(parser, "nil", YP_LEX_STATE_END, false)) return YP_TOKEN_KEYWORD_NIL;
        if (lex_keyword(parser, "not", YP_LEX_STATE_ARG, false)) return YP_TOKEN_KEYWORD_NOT;
        break;
      case 4:
        if (lex_keyword(parser, "case", YP_LEX_STATE_BEG, false)) return YP_TOKEN_KEYWORD_CASE;
        if (lex_keyword(parser, "else", YP_LEX_STATE_BEG, false)) return YP_TOKEN_KEYWORD_ELSE;
        if (lex_keyword(parser, "next", YP_LEX_STATE_MID, false)) return YP_TOKEN_KEYWORD_NEXT;
        if (lex_keyword(parser, "redo", YP_LEX_STATE_END, false)) return YP_TOKEN_KEYWORD_REDO;
        if (lex_keyword(parser, "self", YP_LEX_STATE_END, false)) return YP_TOKEN_KEYWORD_SELF;
        if (lex_keyword(parser, "then", YP_LEX_STATE_BEG, false)) return YP_TOKEN_KEYWORD_THEN;
        if (lex_keyword(parser, "true", YP_LEX_STATE_END, false)) return YP_TOKEN_KEYWORD_TRUE;
        if (lex_keyword(parser, "when", YP_LEX_STATE_NONE, false)) return YP_TOKEN_KEYWORD_WHEN;
        break;
      case 5:
        if (lex_keyword(parser, "alias", YP_LEX_STATE_FNAME | YP_LEX_STATE_FITEM, false)) {
          return YP_TOKEN_KEYWORD_ALIAS;
        }
        if (lex_keyword(parser, "begin", YP_LEX_STATE_BEG, false)) return YP_TOKEN_KEYWORD_BEGIN;
        if (lex_keyword(parser, "BEGIN", YP_LEX_STATE_END, false)) return YP_TOKEN_KEYWORD_BEGIN_UPCASE;
        if (lex_keyword(parser, "break", YP_LEX_STATE_MID, false)) return YP_TOKEN_KEYWORD_BREAK;
        if (lex_keyword(parser, "class", YP_LEX_STATE_CLASS, false)) return YP_TOKEN_KEYWORD_CLASS;
        if (lex_keyword(parser, "elsif", YP_LEX_STATE_END, false)) return YP_TOKEN_KEYWORD_ELSIF;
        if (lex_keyword(parser, "false", YP_LEX_STATE_END, false)) return YP_TOKEN_KEYWORD_FALSE;
        if (lex_keyword(parser, "retry", YP_LEX_STATE_END, false)) return YP_TOKEN_KEYWORD_RETRY;
        if (lex_keyword(parser, "super", YP_LEX_STATE_ARG, false)) return YP_TOKEN_KEYWORD_SUPER;
        if (lex_keyword(parser, "undef", YP_LEX_STATE_FNAME | YP_LEX_STATE_FITEM, false)) return YP_TOKEN_KEYWORD_UNDEF;
        if (lex_keyword(parser, "until", YP_LEX_STATE_BEG, true)) return YP_TOKEN_KEYWORD_UNTIL;
        if (lex_keyword(parser, "while", YP_LEX_STATE_BEG, true)) return YP_TOKEN_KEYWORD_WHILE;
        if (lex_keyword(parser, "yield", YP_LEX_STATE_ARG, false)) return YP_TOKEN_KEYWORD_YIELD;
        break;
      case 6:
        if (lex_keyword(parser, "ensure", YP_LEX_STATE_BEG, false)) return YP_TOKEN_KEYWORD_ENSURE;
        if (lex_keyword(parser, "module", YP_LEX_STATE_BEG, false)) return YP_TOKEN_KEYWORD_MODULE;
        if (lex_keyword(parser, "rescue", YP_LEX_STATE_MID, true)) return YP_TOKEN_KEYWORD_RESCUE;
        if (lex_keyword(parser, "return", YP_LEX_STATE_MID, false)) return YP_TOKEN_KEYWORD_RETURN;
        if (lex_keyword(parser, "unless", YP_LEX_STATE_BEG, true)) return YP_TOKEN_KEYWORD_UNLESS;
        break;
      case 8:
        if (lex_keyword(parser, "__LINE__", YP_LEX_STATE_END, false)) return YP_TOKEN_KEYWORD___LINE__;
        if (lex_keyword(parser, "__FILE__", YP_LEX_STATE_END, false)) return YP_TOKEN_KEYWORD___FILE__;
        break;
      case 12:
        if (lex_keyword(parser, "__ENCODING__", YP_LEX_STATE_END, false)) return YP_TOKEN_KEYWORD___ENCODING__;
        break;
    }
  }
  char start = parser->current.start[0];
  return start >= 'A' && start <= 'Z' ? YP_TOKEN_CONSTANT : YP_TOKEN_IDENTIFIER;
}

// Returns true if the current token that the parser is considering is at the
// beginning of a line or the beginning of the source.
static bool
current_token_starts_line(yp_parser_t *parser) {
  return (parser->current.start == parser->start) || (parser->current.start[-1] == '\n');
}

// When we hit a # while lexing something like a string, we need to potentially
// handle interpolation. This function performs that check. It returns a token
// type representing what it found. Those cases are:
//
// * YP_TOKEN_NOT_PROVIDED - No interpolation was found at this point. The
//     caller should keep lexing.
// * YP_TOKEN_STRING_CONTENT - No interpolation was found at this point. The
//     caller should return this token type.
// * YP_TOKEN_EMBEXPR_BEGIN - An embedded expression was found. The caller
//     should return this token type.
// * YP_TOKEN_EMBVAR - An embedded variable was found. The caller should return
//     this token type.
//
static yp_token_type_t
lex_interpolation(yp_parser_t *parser, const char *pound) {
  // If there is no content following this #, then we're at the end of
  // the string and we can safely return string content.
  if (pound + 1 >= parser->end) {
    parser->current.end = pound;
    lex_state_set(parser, YP_LEX_STATE_BEG);
    return YP_TOKEN_STRING_CONTENT;
  }

  // Now we'll check against the character the follows the #. If it constitutes
  // valid interplation, we'll handle that, otherwise we'll return
  // YP_TOKEN_NOT_PROVIDED.
  switch (pound[1]) {
    case '@': {
      // In this case we may have hit an embedded instance or class variable.
      if (pound + 2 >= parser->end) {
        parser->current.end = pound + 1;
        lex_state_set(parser, YP_LEX_STATE_BEG);
        return YP_TOKEN_STRING_CONTENT;
      }

      // If we're looking at a @ and there's another @, then we'll skip past the
      // second @.
      const char *variable = pound + 2;
      if (*variable == '@' && pound + 3 < parser->end) variable++;

      if (char_is_identifier_start(parser, variable)) {
        // At this point we're sure that we've either hit an embedded instance
        // or class variable. In this case we'll first need to check if we've
        // already consumed content.
        if (pound > parser->current.end) {
          parser->current.end = pound;
          lex_state_set(parser, YP_LEX_STATE_BEG);
          return YP_TOKEN_STRING_CONTENT;
        }

        // Otherwise we need to return the embedded variable token
        // and then switch to the embedded variable lex mode.
        lex_mode_push(parser, (yp_lex_mode_t) { .mode = YP_LEX_EMBVAR });
        parser->current.end = pound + 1;
        lex_state_set(parser, YP_LEX_STATE_BEG);
        return YP_TOKEN_EMBVAR;
      }

      // If we didn't get an valid interpolation, then this is just regular
      // string content. This is like if we get "#@-". In this case the caller
      // should keep lexing.
      parser->current.end = variable;
      return YP_TOKEN_NOT_PROVIDED;
    }
    case '$':
      // In this case we've hit an embedded global variable. First check to see
      // if we've already consumed content. If we have, then we need to return
      // that content as string content first.
      if (pound > parser->current.end) {
        parser->current.end = pound;
        lex_state_set(parser, YP_LEX_STATE_BEG);
        return YP_TOKEN_STRING_CONTENT;
      }

      // Otherwise, we need to return the embedded variable token and switch to
      // the embedded variable lex mode.
      lex_mode_push(parser, (yp_lex_mode_t) { .mode = YP_LEX_EMBVAR });
      parser->current.end = pound + 1;
      lex_state_set(parser, YP_LEX_STATE_BEG);
      return YP_TOKEN_EMBVAR;
    case '{':
      // In this case it's the start of an embedded expression. If we have
      // already consumed content, then we need to return that content as string
      // content first.
      if (pound > parser->current.end) {
        parser->current.end = pound;
        lex_state_set(parser, YP_LEX_STATE_BEG);
        return YP_TOKEN_STRING_CONTENT;
      }

      // Otherwise we'll skip past the #{ and begin lexing the embedded
      // expression.
      lex_mode_push(parser, (yp_lex_mode_t) { .mode = YP_LEX_EMBEXPR });
      parser->current.end = pound + 2;
      parser->command_start = true;
      yp_state_stack_push(&parser->do_loop_stack, false);
      return YP_TOKEN_EMBEXPR_BEGIN;
    default:
      // In this case we've hit a # that doesn't constitute interpolation. We'll
      // mark that by returning the not provided token type. This tells the
      // consumer to keep lexing forward.
      parser->current.end = pound + 1;
      return YP_TOKEN_NOT_PROVIDED;
  }
}

// This function is responsible for lexing either a character literal or the ?
// operator. The supported character literals are described below.
//
// \a             bell, ASCII 07h (BEL)
// \b             backspace, ASCII 08h (BS)
// \t             horizontal tab, ASCII 09h (TAB)
// \n             newline (line feed), ASCII 0Ah (LF)
// \v             vertical tab, ASCII 0Bh (VT)
// \f             form feed, ASCII 0Ch (FF)
// \r             carriage return, ASCII 0Dh (CR)
// \e             escape, ASCII 1Bh (ESC)
// \s             space, ASCII 20h (SPC)
// \\             backslash
// \nnn           octal bit pattern, where nnn is 1-3 octal digits ([0-7])
// \xnn           hexadecimal bit pattern, where nn is 1-2 hexadecimal digits ([0-9a-fA-F])
// \unnnn         Unicode character, where nnnn is exactly 4 hexadecimal digits ([0-9a-fA-F])
// \u{nnnn ...}   Unicode character(s), where each nnnn is 1-6 hexadecimal digits ([0-9a-fA-F])
// \cx or \C-x    control character, where x is an ASCII printable character
// \M-x           meta character, where x is an ASCII printable character
// \M-\C-x        meta control character, where x is an ASCII printable character
// \M-\cx         same as above
// \c\M-x         same as above
// \c? or \C-?    delete, ASCII 7Fh (DEL)
//
static yp_token_type_t
lex_question_mark(yp_parser_t *parser) {
  lex_state_set(parser, YP_LEX_STATE_END);

  switch (*parser->current.end) {
    case '\n':
    case ' ':
      // TODO: this is wrong. We need to track the state for the lexer on
      // whether or not the ? operator is allowed here. For now, we're depending
      // on space characters.
      return YP_TOKEN_QUESTION_MARK;
    case '\t':
    case '\v':
    case '\f':
    case '\r':
      parser->current.end++;
      return YP_TOKEN_CHARACTER_LITERAL;
    case '\\':
      parser->current.end++;
      if (parser->current.end >= parser->end) {
        return YP_TOKEN_CHARACTER_LITERAL;
      }

      switch (*parser->current.end) {
        case 'a':
        case 'b':
        case 't':
        case 'n':
        case 'v':
        case 'f':
        case 'r':
        case 'e':
        case 's':
        case '\\':
          parser->current.end++;
          return YP_TOKEN_CHARACTER_LITERAL;
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
          // \nnn           octal bit pattern, where nnn is 1-3 octal digits ([0-7])
          parser->current.end++;
          if (parser->current.end < parser->end && char_is_octal_number(*parser->current.end)) parser->current.end++;
          if (parser->current.end < parser->end && char_is_octal_number(*parser->current.end)) parser->current.end++;
          return YP_TOKEN_CHARACTER_LITERAL;
        case 'x':
          // \xnn           hexadecimal bit pattern, where nn is 1-2 hexadecimal digits ([0-9a-fA-F])
          parser->current.end++;
          if (parser->current.end < parser->end && char_is_hexadecimal_number(*parser->current.end)) parser->current.end++;
          if (parser->current.end < parser->end && char_is_hexadecimal_number(*parser->current.end)) parser->current.end++;
          return YP_TOKEN_CHARACTER_LITERAL;
        case 'u':
          // \unnnn         Unicode character, where nnnn is exactly 4 hexadecimal digits ([0-9a-fA-F])
          // \u{nnnn ...}   Unicode character(s), where each nnnn is 1-6 hexadecimal digits ([0-9a-fA-F])
          parser->current.end++;
          if (match(parser, '{')) {
            while (parser->current.end < parser->end && char_is_whitespace(*parser->current.end)) parser->current.end++;
            while (!match(parser, '}')) {
              while (parser->current.end < parser->end && char_is_hexadecimal_number(*parser->current.end)) parser->current.end++;
              while (parser->current.end < parser->end && char_is_whitespace(*parser->current.end)) parser->current.end++;
            }
          } else {
            for (size_t index = 0; index < 4; index++) {
              if (char_is_hexadecimal_number(*parser->current.end)) parser->current.end++;
              else break;
            }
          }
          return YP_TOKEN_CHARACTER_LITERAL;
        case 'c':
          // \cx            control character, where x is an ASCII printable character
          // \c\M-x         same as above
          // \c?            delete, ASCII 7Fh (DEL)
          parser->current.end++;

          if (parser->current.end < parser->end) {
            if (char_is_ascii_printable(*parser->current.end)) {
              parser->current.end++;
            } else if (match(parser, '\\') && match(parser, 'M') && match(parser, '-') && ((parser->current.end < parser->end) && char_is_ascii_printable(*parser->current.end))) {
              parser->current.end++;
            }
          }

          return YP_TOKEN_CHARACTER_LITERAL;
        case 'C':
          // \C-x           control character, where x is an ASCII printable character
          // \C-?           delete, ASCII 7Fh (DEL)
          parser->current.end++;
          if (match(parser, '-') && char_is_ascii_printable(*parser->current.end)) {
            parser->current.end++;
          }
          return YP_TOKEN_CHARACTER_LITERAL;
        case 'M':
          // \M-x           meta character, where x is an ASCII printable character
          // \M-\C-x        meta control character, where x is an ASCII printable character
          // \M-\cx         same as above
          parser->current.end++;
          if (match(parser, '-')) {
            if (match(parser, '\\')) {
              if (match(parser, 'C') && match(parser, '-') && ((parser->current.end < parser->end) && char_is_ascii_printable(*parser->current.end))) {
                parser->current.end++;
              } else if (match(parser, 'c') && ((parser->current.end < parser->end) && char_is_ascii_printable(*parser->current.end))) {
                parser->current.end++;
              }
            } else if (char_is_ascii_printable(*parser->current.end)) {
              parser->current.end++;
            }
          }
          return YP_TOKEN_CHARACTER_LITERAL;
        default:
          return YP_TOKEN_CHARACTER_LITERAL;
      }
    default:
      parser->current.end++;
      return YP_TOKEN_CHARACTER_LITERAL;
  }
}

// Lex a variable that starts with an @ sign (either an instance or class
// variable).
static yp_token_type_t
lex_at_variable(yp_parser_t *parser) {
  yp_token_type_t type = match(parser, '@') ? YP_TOKEN_CLASS_VARIABLE : YP_TOKEN_INSTANCE_VARIABLE;
  size_t width;

  if ((width = char_is_identifier_start(parser, parser->current.end))) {
    parser->current.end += width;

    while ((width = char_is_identifier(parser, parser->current.end))) {
      parser->current.end += width;
    }

    // If we're lexing an embedded variable, then we need to pop back
    // into the parent lex context.
    if (parser->lex_modes.current->mode == YP_LEX_EMBVAR) {
      lex_mode_pop(parser);
    }

    return type;
  }

  return YP_TOKEN_INVALID;
}

static bool
current_scope_has_local(yp_parser_t * parser, yp_token_t * token) {
  return yp_token_list_includes(&parser->current_scope->as.scope.locals, token);
}

// This is the overall lexer function. It is responsible for advancing both
// parser->current.start and parser->current.end such that they point to the
// beginning and end of the next token. It should return the type of token that
// was found.
static yp_token_type_t
lex_token_type(yp_parser_t *parser) {
  // This value mirrors cmd_state from CRuby.
  bool previous_command_start = parser->command_start;
  parser->command_start = false;

  switch (parser->lex_modes.current->mode) {
    case YP_LEX_DEFAULT:
    case YP_LEX_EMBEXPR:
    case YP_LEX_EMBVAR: {
      // If we have the special next_start pointer set, then we're going to jump
      // to that location and start lexing from there.
      if (parser->next_start != NULL) {
        parser->current.end = parser->next_start;
        parser->next_start = NULL;
      }

      // This value mirrors space_seen from CRuby. It tracks whether or not
      // space has been eaten before the start of the next token.
      bool space_seen = false;

      // First, we're going to skip past any whitespace at the front of the next
      // token.
      bool chomping = true;
      while (chomping) {
        switch (*parser->current.end) {
          case ' ':
          case '\t':
          case '\f':
          case '\v':
            parser->current.end++;
            space_seen = true;
            break;
          case '\r':
            if (parser->current.end[1] == '\n') {
              chomping = false;
            } else {
              parser->current.end++;
              space_seen = true;
            }
            break;
          case '\\':
            if (parser->current.end[1] == '\n') {
              parser->current.end += 2;
              space_seen = true;
            } else if (char_is_non_newline_whitespace(*parser->current.end)) {
              parser->current.end += 2;
            } else {
              chomping = false;
            }
            break;
          default:
            chomping = false;
            break;
        }
      }

      // Next, we'll set to start of this token to be the current end.
      parser->current.start = parser->current.end;

      // Finally, we'll check the current character to determine the next token.
      switch (*parser->current.end++) {
        case '\0':   // NUL or end of script
        case '\004': // ^D
        case '\032': // ^Z
          parser->current.end--;
          return YP_TOKEN_EOF;

        case '#': // comments
          while (*parser->current.end != '\n' && *parser->current.end != '\0') {
            parser->current.end++;
          }
          (void) match(parser, '\n');
          return YP_TOKEN_COMMENT;

        case '\r': {
          // The only way to get here is if this is immediately followed by a
          // newline.
          (void) match(parser, '\n');

          // fallthrough
        }

        case '\n':
          lex_state_set(parser, YP_LEX_STATE_BEG);
          parser->command_start = true;

          // If the special resume flag is set, then we need to jump ahead.
          if (parser->heredoc_end != NULL) {
            assert(parser->heredoc_end <= parser->end);
            parser->next_start = parser->heredoc_end;
            parser->heredoc_end = NULL;
          }

          return YP_TOKEN_NEWLINE;

        // ,
        case ',':
          lex_state_set(parser, YP_LEX_STATE_BEG | YP_LEX_STATE_LABEL);
          return YP_TOKEN_COMMA;

        // (
        case '(':
          lex_state_set(parser, YP_LEX_STATE_BEG | YP_LEX_STATE_LABEL);
          yp_state_stack_push(&parser->do_loop_stack, false);
          return YP_TOKEN_PARENTHESIS_LEFT;

        // )
        case ')':
          lex_state_set(parser, YP_LEX_STATE_ENDFN);
          yp_state_stack_pop(&parser->do_loop_stack);
          return YP_TOKEN_PARENTHESIS_RIGHT;

        // ;
        case ';':
          lex_state_set(parser, YP_LEX_STATE_BEG);
          parser->command_start = true;
          return YP_TOKEN_SEMICOLON;

        // [ []
        case '[':
          if (lex_state_operator_p(parser)) {
            if (match(parser, ']')) {
              lex_state_set(parser, YP_LEX_STATE_ARG);
              return match(parser, '=') ? YP_TOKEN_BRACKET_LEFT_RIGHT_EQUAL : YP_TOKEN_BRACKET_LEFT_RIGHT;
            }

            lex_state_set(parser, YP_LEX_STATE_ARG | YP_LEX_STATE_LABEL);
            return YP_TOKEN_BRACKET_LEFT;
          }

          lex_state_set(parser, YP_LEX_STATE_BEG | YP_LEX_STATE_LABEL);
          yp_state_stack_push(&parser->do_loop_stack, false);
          return YP_TOKEN_BRACKET_LEFT;

        // ]
        case ']':
          lex_state_set(parser, YP_LEX_STATE_END);
          yp_state_stack_pop(&parser->do_loop_stack);
          return YP_TOKEN_BRACKET_RIGHT;

        // {
        case '{':
          if (parser->previous.type == YP_TOKEN_MINUS_GREATER) {
            // This { begins a lambda
            return YP_TOKEN_LAMBDA_BEGIN;
          } else if (lex_state_p(parser, YP_LEX_STATE_LABELED)) {
            // This { begins a hash literal
            lex_state_set(parser, YP_LEX_STATE_BEG | YP_LEX_STATE_LABEL);
          } else if (lex_state_p(parser, YP_LEX_STATE_ARG_ANY | YP_LEX_STATE_END | YP_LEX_STATE_ENDFN)) {
            // This { begins a block
            parser->command_start = true;
            lex_state_set(parser, YP_LEX_STATE_BEG);
          } else if (lex_state_p(parser, YP_LEX_STATE_ENDARG)) {
            // This { begins a block on a command
            parser->command_start = true;
            lex_state_set(parser, YP_LEX_STATE_BEG);
          } else {
            // This { begins a block
            parser->command_start = true;
            lex_state_set(parser, YP_LEX_STATE_BEG);
          }

          yp_state_stack_push(&parser->do_loop_stack, false);
          return YP_TOKEN_BRACE_LEFT;

        // }
        case '}':
          yp_state_stack_pop(&parser->do_loop_stack);

          if (parser->lex_modes.current->mode == YP_LEX_EMBEXPR) {
            lex_mode_pop(parser);
            return YP_TOKEN_EMBEXPR_END;
          }

          lex_state_set(parser, YP_LEX_STATE_END);
          return YP_TOKEN_BRACE_RIGHT;

        // * ** **= *=
        case '*':
          if (match(parser, '*')) {
            if (match(parser, '=')) {
              return YP_TOKEN_STAR_STAR_EQUAL;
            }
            if (lex_state_operator_p(parser)) {
              lex_state_set(parser, YP_LEX_STATE_ARG);
            } else {
              lex_state_set(parser, YP_LEX_STATE_BEG);
            }
            return YP_TOKEN_STAR_STAR;
          }

          if (lex_state_operator_p(parser)) {
            lex_state_set(parser, YP_LEX_STATE_ARG);
          } else {
            lex_state_set(parser, YP_LEX_STATE_BEG);
          }
          return match(parser, '=') ? YP_TOKEN_STAR_EQUAL : YP_TOKEN_STAR;

        // ! != !~ !@
        case '!':
          if (lex_state_operator_p(parser)) {
            lex_state_set(parser, YP_LEX_STATE_ARG);
            if (match(parser, '@')) return YP_TOKEN_BANG_AT;
          } else {
            lex_state_set(parser, YP_LEX_STATE_BEG);
          }

          if (match(parser, '=')) return YP_TOKEN_BANG_EQUAL;
          if (match(parser, '~')) return YP_TOKEN_BANG_TILDE;
          return YP_TOKEN_BANG;

        // = => =~ == === =begin
        case '=':
          if (current_token_starts_line(parser)) {
            if (strncmp(parser->current.end, "begin\n", 6) == 0) {
              parser->current.end += 6;
              lex_mode_push(parser, (yp_lex_mode_t) { .mode = YP_LEX_EMBDOC });
              return YP_TOKEN_EMBDOC_BEGIN;
            }

            if (strncmp(parser->current.end, "begin\r\n", 7) == 0) {
              parser->current.end += 7;
              lex_mode_push(parser, (yp_lex_mode_t) { .mode = YP_LEX_EMBDOC });
              return YP_TOKEN_EMBDOC_BEGIN;
            }
          }

          if (lex_state_operator_p(parser)) {
            lex_state_set(parser, YP_LEX_STATE_ARG);
          } else {
            lex_state_set(parser, YP_LEX_STATE_BEG);
          }

          if (match(parser, '>')) {
            return YP_TOKEN_EQUAL_GREATER;
          }

          if (match(parser, '~')) return YP_TOKEN_EQUAL_TILDE;
          if (match(parser, '=')) return match(parser, '=') ? YP_TOKEN_EQUAL_EQUAL_EQUAL : YP_TOKEN_EQUAL_EQUAL;
          return YP_TOKEN_EQUAL;

        // < << <<= <= <=>
        case '<':
          if (match(parser, '<')) {
            if (
              !lex_state_p(parser, YP_LEX_STATE_DOT | YP_LEX_STATE_CLASS) &&
              !lex_state_end_p(parser) &&
              (!lex_state_p(parser, YP_LEX_STATE_ARG_ANY) || lex_state_p(parser, YP_LEX_STATE_LABELED) || space_seen)
            ) {
              const char *end = parser->current.end;

              (void) (match(parser, '-') || match(parser, '~'));
              const char *ident_start = parser->current.end;

              size_t width = char_is_identifier(parser, parser->current.end);
              if (width == 0) {
                parser->current.end = end;
              } else {
                while ((width = char_is_identifier(parser, parser->current.end))) {
                  parser->current.end += width;
                }

                lex_mode_push(parser, (yp_lex_mode_t) {
                  .mode = YP_LEX_HEREDOC,
                  .as.heredoc = {
                    .ident_start = ident_start,
                    .ident_length = parser->current.end - ident_start,
                    .next_start = parser->current.end
                  }
                });

                if (parser->heredoc_end == NULL) {
                  const char *body_start = (const char *) memchr(parser->current.end, '\n', parser->end - parser->current.end);

                  if (body_start == NULL) {
                    // If there is no newline after the heredoc identifier, then
                    // this is not a valid heredoc declaration.
                    return YP_TOKEN_INVALID;
                  }

                  parser->next_start = body_start + 1;
                } else {
                  parser->next_start = parser->heredoc_end;
                }

                return YP_TOKEN_HEREDOC_START;
              }
            }

            if (match(parser, '=')) {
              lex_state_set(parser, YP_LEX_STATE_BEG);
              return YP_TOKEN_LESS_LESS_EQUAL;
            }

            if (lex_state_operator_p(parser)) {
              lex_state_set(parser, YP_LEX_STATE_ARG);
            } else {
              if (lex_state_p(parser, YP_LEX_STATE_CLASS)) parser->command_start = true;
              lex_state_set(parser, YP_LEX_STATE_BEG);
            }

            return YP_TOKEN_LESS_LESS;
          }

          if (lex_state_operator_p(parser)) {
            lex_state_set(parser, YP_LEX_STATE_ARG);
          } else {
            if (lex_state_p(parser, YP_LEX_STATE_CLASS)) parser->command_start = true;
            lex_state_set(parser, YP_LEX_STATE_BEG);
          }

          if (match(parser, '=')) {
            if (match(parser, '>')) return YP_TOKEN_LESS_EQUAL_GREATER;
            return YP_TOKEN_LESS_EQUAL;
          }

          return YP_TOKEN_LESS;

        // > >> >>= >=
        case '>':
          if (match(parser, '>')) {
            if (lex_state_operator_p(parser)) {
              lex_state_set(parser, YP_LEX_STATE_ARG);
            } else {
              lex_state_set(parser, YP_LEX_STATE_BEG);
            }
            return match(parser, '=') ? YP_TOKEN_GREATER_GREATER_EQUAL : YP_TOKEN_GREATER_GREATER;
          }

          if (lex_state_operator_p(parser)) {
            lex_state_set(parser, YP_LEX_STATE_ARG);
          } else {
            lex_state_set(parser, YP_LEX_STATE_BEG);
          }

          return match(parser, '=') ? YP_TOKEN_GREATER_EQUAL : YP_TOKEN_GREATER;

        // double-quoted string literal
        case '"': {
          yp_lex_mode_t lex_mode = {
            .mode = YP_LEX_STRING,
            .as.string.terminator = '"',
            .as.string.interpolation = true
          };

          lex_mode_push(parser, lex_mode);
          return YP_TOKEN_STRING_BEGIN;
        }

        // xstring literal
        case '`': {
          if (!lex_state_operator_p(parser)) {
            yp_lex_mode_t lex_mode = {
              .mode = YP_LEX_STRING,
              .as.string.terminator = '`',
              .as.string.interpolation = true
            };

            lex_mode_push(parser, lex_mode);
          } else {
            lex_state_set(parser, YP_LEX_STATE_ENDFN);
          }
          return YP_TOKEN_BACKTICK;
        }

        // single-quoted string literal
        case '\'': {
          yp_lex_mode_t lex_mode = {
            .mode = YP_LEX_STRING,
            .as.string.terminator = '\'',
            .as.string.interpolation = false
          };

          lex_mode_push(parser, lex_mode);
          return YP_TOKEN_STRING_BEGIN;
        }

        // ? character literal
        case '?':
          return lex_question_mark(parser);

        // & && &&= &=
        case '&':
          if (match(parser, '&')) {
            if (match(parser, '=')) {
              return YP_TOKEN_AMPERSAND_AMPERSAND_EQUAL;
            }

            lex_state_set(parser, YP_LEX_STATE_BEG);
            return YP_TOKEN_AMPERSAND_AMPERSAND;
          }

          if (match(parser, '.')) {
            return YP_TOKEN_AMPERSAND_DOT;
          }

          if (match(parser, '=')) {
            return YP_TOKEN_AMPERSAND_EQUAL;
          }

          if (lex_state_operator_p(parser)) {
            lex_state_set(parser, YP_LEX_STATE_ARG);
          } else {
            lex_state_set(parser, YP_LEX_STATE_BEG);
          }

          return YP_TOKEN_AMPERSAND;

        // | || ||= |=
        case '|':
          if (match(parser, '|')) {
            if (match(parser, '=')) {
              lex_state_set(parser, YP_LEX_STATE_BEG);
              return YP_TOKEN_PIPE_PIPE_EQUAL;
            }

            if (lex_state_p(parser, YP_LEX_STATE_BEG)) {
              parser->current.end--;
              return YP_TOKEN_PIPE;
            }

            lex_state_set(parser, YP_LEX_STATE_BEG);
            return YP_TOKEN_PIPE_PIPE;
          }

          if (match(parser, '=')) {
            lex_state_set(parser, YP_LEX_STATE_BEG);
            return YP_TOKEN_PIPE_EQUAL;
          }

          if (lex_state_operator_p(parser)) {
            lex_state_set(parser, YP_LEX_STATE_ARG);
          } else {
            lex_state_set(parser, YP_LEX_STATE_BEG | YP_LEX_STATE_LABEL);
          }

          return YP_TOKEN_PIPE;

        // + += +@
        case '+':
          if (lex_state_operator_p(parser)) {
            lex_state_set(parser, YP_LEX_STATE_ARG);
            if (match(parser, '@')) return YP_TOKEN_PLUS_AT;

            return YP_TOKEN_PLUS;
          }

          if (match(parser, '=')) {
            lex_state_set(parser, YP_LEX_STATE_BEG);
            return YP_TOKEN_PLUS_EQUAL;
          }

          if (lex_state_beg_p(parser)) {
            lex_state_set(parser, YP_LEX_STATE_BEG);

            if (parser->current.end < parser->end && char_is_decimal_number(*parser->current.end)) {
              return lex_numeric(parser);
            }

            return YP_TOKEN_PLUS;
          }

          lex_state_set(parser, YP_LEX_STATE_BEG);
          return YP_TOKEN_PLUS;

        // - -= -@
        case '-':
          if (lex_state_operator_p(parser)) {
            lex_state_set(parser, YP_LEX_STATE_ARG);
            if (match(parser, '@')) return YP_TOKEN_MINUS_AT;

            return YP_TOKEN_MINUS;
          }

          if (match(parser, '=')) {
            lex_state_set(parser, YP_LEX_STATE_BEG);
            return YP_TOKEN_MINUS_EQUAL;
          }

          if (match(parser, '>')) {
            lex_state_set(parser, YP_LEX_STATE_ENDFN);
            return YP_TOKEN_MINUS_GREATER;
          }

          lex_state_set(parser, YP_LEX_STATE_BEG);
          return YP_TOKEN_MINUS;

        // . .. ...
        case '.':
          if (match(parser, '.')) {
            lex_state_set(parser, YP_LEX_STATE_BEG);
            return match(parser, '.') ? YP_TOKEN_DOT_DOT_DOT : YP_TOKEN_DOT_DOT;
          }

          lex_state_set(parser, YP_LEX_STATE_DOT);
          return YP_TOKEN_DOT;

        // integer
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9': {
          yp_token_type_t type = lex_numeric(parser);
          lex_state_set(parser, YP_LEX_STATE_END);
          return type;
        }

        // :: symbol
        case ':':
          if (match(parser, ':')) {
            lex_state_set(parser, YP_LEX_STATE_DOT);
            return YP_TOKEN_COLON_COLON;
          }

          if (lex_state_end_p(parser) || char_is_whitespace(*parser->current.end) || (*parser->current.end == '#')) {
            lex_state_set(parser, YP_LEX_STATE_BEG);
            return YP_TOKEN_COLON;
          }

          if ((*parser->current.end == '"') || (*parser->current.end == '\'')) {
            yp_lex_mode_t lex_mode = {
              .mode = YP_LEX_STRING,
              .as.string.terminator = *parser->current.end,
              .as.string.interpolation = *parser->current.end == '"'
            };

            lex_mode_push(parser, lex_mode);
            parser->current.end++;
          } else {
            lex_mode_push(parser, (yp_lex_mode_t) { .mode = YP_LEX_SYMBOL });
          }

          lex_state_set(parser, YP_LEX_STATE_FNAME);
          return YP_TOKEN_SYMBOL_BEGIN;

        // / /=
        case '/':
          if (lex_state_beg_p(parser)) {
            lex_mode_push(parser, (yp_lex_mode_t) { .mode = YP_LEX_REGEXP, .as.regexp.terminator = '/' });
            return YP_TOKEN_REGEXP_BEGIN;
          }

          if (match(parser, '=')) {
            lex_state_set(parser, YP_LEX_STATE_BEG);
            return YP_TOKEN_SLASH_EQUAL;
          }

          if (lex_state_p(parser, YP_LEX_STATE_ARG) && space_seen && !char_is_non_newline_whitespace(*parser->current.end)) {
            yp_diagnostic_list_append(&parser->warning_list, "ambiguity between regexp and two divisions: wrap regexp in parentheses or add a space after `/' operator", parser->current.start - parser->start);
            lex_mode_push(parser, (yp_lex_mode_t) { .mode = YP_LEX_REGEXP, .as.regexp.terminator = '/' });
            return YP_TOKEN_REGEXP_BEGIN;
          }

          if (lex_state_operator_p(parser)) {
            lex_state_set(parser, YP_LEX_STATE_ARG);
          } else {
            lex_state_set(parser, YP_LEX_STATE_BEG);
          }

          return YP_TOKEN_SLASH;

        // ^ ^=
        case '^':
          if (lex_state_operator_p(parser)) {
            lex_state_set(parser, YP_LEX_STATE_ARG);
          } else {
            lex_state_set(parser, YP_LEX_STATE_BEG);
          }
          return match(parser, '=') ? YP_TOKEN_CARET_EQUAL : YP_TOKEN_CARET;

        // ~ ~@
        case '~':
          if ((parser->previous.type == YP_TOKEN_KEYWORD_DEF || parser->previous.type == YP_TOKEN_DOT) &&
              match(parser, '@'))
            return YP_TOKEN_TILDE_AT;
          return YP_TOKEN_TILDE;

        // % %= %i %I %q %Q %w %W
        case '%': {
          // In a BEG state, if you encounter a % then you must be starting
          // something. In this case if there is no subsequent character then
          // we have an invalid token.
          if (lex_state_beg_p(parser) && (parser->current.end >= parser->end)) {
            yp_diagnostic_list_append(&parser->error_list, "unexpected end of input", parser->current.start - parser->start);
            return YP_TOKEN_INVALID;
          }

          if (lex_state_beg_p(parser) || (lex_state_p(parser, YP_LEX_STATE_FITEM) && (*parser->current.end == 's'))) {
            if (!parser->encoding.alnum_char(parser->current.end)) {
              lex_mode_push(parser, (yp_lex_mode_t) {
                .mode = YP_LEX_STRING,
                .as.string.terminator = terminator(*parser->current.end++),
                .as.string.interpolation = true
              });

              return YP_TOKEN_STRING_BEGIN;
            }

            switch (*parser->current.end) {
              case 'i': {
                parser->current.end++;
                yp_lex_mode_t lex_mode = {
                  .mode = YP_LEX_LIST,
                  .as.list.terminator = terminator(*parser->current.end++),
                  .as.list.interpolation = false
                };

                lex_mode_push(parser, lex_mode);
                return YP_TOKEN_PERCENT_LOWER_I;
              }
              case 'I': {
                parser->current.end++;
                yp_lex_mode_t lex_mode = {
                  .mode = YP_LEX_LIST,
                  .as.list.terminator = terminator(*parser->current.end++),
                  .as.list.interpolation = true
                };

                lex_mode_push(parser, lex_mode);
                return YP_TOKEN_PERCENT_UPPER_I;
              }
              case 'r': {
                parser->current.end++;
                yp_lex_mode_t lex_mode = {
                  .mode = YP_LEX_REGEXP,
                  .as.regexp.terminator = terminator(*parser->current.end++)
                };

                lex_mode_push(parser, lex_mode);
                return YP_TOKEN_REGEXP_BEGIN;
              }
              case 'q': {
                parser->current.end++;
                yp_lex_mode_t lex_mode = {
                  .mode = YP_LEX_STRING,
                  .as.string.terminator = terminator(*parser->current.end++),
                  .as.string.interpolation = false
                };

                lex_mode_push(parser, lex_mode);
                return YP_TOKEN_STRING_BEGIN;
              }
              case 'Q': {
                parser->current.end++;
                yp_lex_mode_t lex_mode = {
                  .mode = YP_LEX_STRING,
                  .as.string.terminator = terminator(*parser->current.end++),
                  .as.string.interpolation = true
                };

                lex_mode_push(parser, lex_mode);
                return YP_TOKEN_STRING_BEGIN;
              }
              case 's': {
                parser->current.end++;
                yp_lex_mode_t lex_mode = {
                  .mode = YP_LEX_STRING,
                  .as.string.terminator = terminator(*parser->current.end++),
                  .as.string.interpolation = false
                };

                lex_mode_push(parser, lex_mode);
                return YP_TOKEN_SYMBOL_BEGIN;
              }
              case 'w': {
                parser->current.end++;
                yp_lex_mode_t lex_mode = {
                  .mode = YP_LEX_LIST,
                  .as.list.terminator = terminator(*parser->current.end++),
                  .as.list.interpolation = false
                };

                lex_mode_push(parser, lex_mode);
                return YP_TOKEN_PERCENT_LOWER_W;
              }
              case 'W': {
                parser->current.end++;
                yp_lex_mode_t lex_mode = {
                  .mode = YP_LEX_LIST,
                  .as.list.terminator = terminator(*parser->current.end++),
                  .as.list.interpolation = true
                };

                lex_mode_push(parser, lex_mode);
                return YP_TOKEN_PERCENT_UPPER_W;
              }
              case 'x': {
                parser->current.end++;
                yp_lex_mode_t lex_mode = {
                  .mode = YP_LEX_STRING,
                  .as.string.terminator = terminator(*parser->current.end++),
                  .as.string.interpolation = true
                };

                lex_mode_push(parser, lex_mode);
                return YP_TOKEN_PERCENT_LOWER_X;
              }
              default:
                yp_diagnostic_list_append(&parser->error_list, "invalid %% token", parser->current.start - parser->start);
                return YP_TOKEN_INVALID;
            }
          }

          if (match(parser, '=')) {
            parser->lex_state = YP_LEX_STATE_BEG;
            return YP_TOKEN_PERCENT_EQUAL;
          }

          parser->lex_state = lex_state_operator_p(parser) ? YP_LEX_STATE_ARG : YP_LEX_STATE_BEG;
          return YP_TOKEN_PERCENT;
        }

        // global variable
        case '$': {
          yp_token_type_t type = lex_global_variable(parser);

          // If we're lexing an embedded variable, then we need to pop back into
          // the parent lex context.
          if (parser->lex_modes.current->mode == YP_LEX_EMBVAR) {
            lex_mode_pop(parser);
          }

          lex_state_set(parser, YP_LEX_STATE_END);
          return type;
        }

        // instance variable, class variable
        case '@':
          lex_state_set(parser, parser->lex_state & YP_LEX_STATE_FNAME ? YP_LEX_STATE_ENDFN : YP_LEX_STATE_END);
          return lex_at_variable(parser);

        default: {
          // If this isn't the beginning of an identifier, then it's an invalid
          // token as we've exhausted all of the other options.
          size_t width = char_is_identifier_start(parser, parser->current.start);
          if (!width) return YP_TOKEN_INVALID;

          parser->current.end = parser->current.start + width;
          yp_token_type_t type = lex_identifier(parser);

          // If we've hit a __END__ and it was at the start of the line or the
          // start of the file and it is followed by either a \n or a \r\n, then
          // this is the last token of the file.
          if (
            ((parser->current.end - parser->current.start) == 7) &&
            current_token_starts_line(parser) &&
            (strncmp(parser->current.start, "__END__", 7) == 0) &&
            (*parser->current.end == '\n' || (*parser->current.end == '\r' && parser->current.end[1] == '\n'))
          ) {
            parser->current.end = parser->end;
            return YP_TOKEN___END__;
          }

          yp_lex_state_t last_state = parser->lex_state;

          // If we're lexing in a place that allows labels and we've hit a
          // colon, then we can return a label token.
          if ((parser->current.end[0] == ':') && (parser->current.end[1] != ':')) {
            parser->current.end++;
            lex_state_set(parser, YP_LEX_STATE_ARG | YP_LEX_STATE_LABELED);
            return YP_TOKEN_LABEL;
          }

          if (type == YP_TOKEN_IDENTIFIER || type == YP_TOKEN_CONSTANT) {
            if (lex_state_p(parser, YP_LEX_STATE_BEG_ANY | YP_LEX_STATE_ARG_ANY | YP_LEX_STATE_DOT)) {
              if (previous_command_start) {
                lex_state_set(parser, YP_LEX_STATE_CMDARG);
              } else {
                lex_state_set(parser, YP_LEX_STATE_ARG);
              }
            } else if (lex_state_operator_p(parser)) {
              lex_state_set(parser, YP_LEX_STATE_ENDFN);
            } else {
              lex_state_set(parser, YP_LEX_STATE_END);
            }
          }

          if (
            !(last_state & (YP_LEX_STATE_DOT|YP_LEX_STATE_FNAME)) &&
            (type == YP_TOKEN_IDENTIFIER) &&
            current_scope_has_local(parser, &parser->current)
          ) {
            lex_state_set(parser, YP_LEX_STATE_END|YP_LEX_STATE_LABEL);
          }

          return type;
        }
      }
    }
    case YP_LEX_EMBDOC: {
      parser->current.start = parser->current.end;

      // If we've hit the end of the embedded documentation then we'll return that token here.
      if (strncmp(parser->current.end, "=end\n", 5) == 0) {
        parser->current.end += 5;
        lex_mode_pop(parser);
        return YP_TOKEN_EMBDOC_END;
      }

      if (strncmp(parser->current.end, "=end\r\n", 6) == 0) {
        parser->current.end += 6;
        lex_mode_pop(parser);
        return YP_TOKEN_EMBDOC_END;
      }

      // Otherwise, we'll parse until the end of the line and return a line of
      // embedded documentation.
      while ((parser->current.end < parser->end) && (*parser->current.end++ != '\n'));

      // If we've still got content, then we'll return a line of embedded
      // documentation.
      if (parser->current.end < parser->end)
        return YP_TOKEN_EMBDOC_LINE;

      return YP_TOKEN_EOF;
    }
    case YP_LEX_LIST: {
      // First we'll set the beginning of the token.
      parser->current.start = parser->current.end;

      // If there's any whitespace at the start of the list, then we're going to
      // trim it off the beginning and create a new token.
      size_t whitespace;
      if ((whitespace = strspn(parser->current.end, " \t\f\r\v\n")) > 0) {
        parser->current.end += whitespace;
        return YP_TOKEN_WORDS_SEP;
      }

      // These are the places where we need to split up the content of the list.
      // We'll use strpbrk to find the first of these characters.
      char breakpoints[] = " \\ \t\f\r\v\n\0";
      breakpoints[0] = parser->lex_modes.current->as.list.terminator;

      // If interpolation is allowed, then we're going to check for the #
      // character. Otherwise we'll only look for escapes and the terminator.
      if (parser->lex_modes.current->as.list.interpolation) {
        breakpoints[8] = '#';
      }

      char *breakpoint = strpbrk(parser->current.end, breakpoints);
      while (breakpoint != NULL) {
        switch (*breakpoint) {
          case '\\':
            // If we hit escapes, then we need to treat the next token
            // literally. In this case we'll skip past the next character and
            // find the next breakpoint.
            breakpoint = strpbrk(breakpoint + 2, breakpoints);
            break;
          case ' ':
          case '\t':
          case '\f':
          case '\r':
          case '\v':
          case '\n':
            // If we've hit whitespace, then we must have received content by
            // now, so we can return an element of the list.
            parser->current.end = breakpoint;
            return YP_TOKEN_STRING_CONTENT;
          case '#': {
            yp_token_type_t type = lex_interpolation(parser, breakpoint);
            if (type != YP_TOKEN_NOT_PROVIDED) return type;

            // If we haven't returned at this point then we had something
            // that looked like an interpolated class or instance variable
            // like "#@" but wasn't actually. In this case we'll just skip
            // to the next breakpoint.
            breakpoint = strpbrk(parser->current.end, breakpoints);
            break;
          }
          default:
            // In this case we've hit the terminator. If we've hit the
            // terminator and we've already skipped past content, then we can
            // return a list node.
            if (breakpoint > parser->current.end) {
              parser->current.end = breakpoint;
              return YP_TOKEN_STRING_CONTENT;
            }

            // Otherwise, switch back to the default state and return the end of
            // the list.
            parser->current.end = breakpoint + 1;
            lex_mode_pop(parser);

            lex_state_set(parser, YP_LEX_STATE_END);
            return YP_TOKEN_STRING_END;
        }
      }

      // If we were unable to find a breakpoint, then this token hits the end of
      // the file.
      return YP_TOKEN_EOF;
    }
    case YP_LEX_REGEXP: {
      // First, we'll set to start of this token to be the current end.
      parser->current.start = parser->current.end;

      // These are the places where we need to split up the content of the
      // regular expression. We'll use strpbrk to find the first of these
      // characters.
      char breakpoints[] = " \\#";
      breakpoints[0] = parser->lex_modes.current->as.string.terminator;

      char *breakpoint = strpbrk(parser->current.end, breakpoints);

      while (breakpoint != NULL) {
        switch (*breakpoint) {
          case '\\':
            // If we hit escapes, then we need to treat the next token
            // literally. In this case we'll skip past the next character and
            // find the next breakpoint.
            breakpoint = strpbrk(breakpoint + 2, breakpoints);
            break;
          case '#': {
            yp_token_type_t type = lex_interpolation(parser, breakpoint);
            if (type != YP_TOKEN_NOT_PROVIDED) return type;

            // If we haven't returned at this point then we had something
            // that looked like an interpolated class or instance variable
            // like "#@" but wasn't actually. In this case we'll just skip
            // to the next breakpoint.
            breakpoint = strpbrk(parser->current.end, breakpoints);
            break;
          }
          default: {
            assert(*breakpoint == parser->lex_modes.current->as.regexp.terminator);

            // Here we've hit the terminator. If we have already consumed
            // content then we need to return that content as string content
            // first.
            if (breakpoint > parser->current.end) {
              parser->current.end = breakpoint;
              return YP_TOKEN_STRING_CONTENT;
            }

            // Since we've hit the terminator of the regular expression, we now
            // need to parse the options.
            bool options = true;
            parser->current.end = breakpoint + 1;

            while (options) {
              switch (*parser->current.end) {
                case 'e':
                case 'i':
                case 'm':
                case 'n':
                case 'o':
                case 's':
                case 'u':
                case 'x':
                  parser->current.end++;
                  break;
                default:
                  options = false;
                  break;
              }
            }

            lex_mode_pop(parser);
            lex_state_set(parser, YP_LEX_STATE_END);
            return YP_TOKEN_REGEXP_END;
          }
        }
      }

      // At this point, the breakpoint is NULL which means we were unable to
      // find anything before the end of the file.
      return YP_TOKEN_EOF;
    }
    case YP_LEX_STRING: {
      // First, we'll set to start of this token to be the current end.
      parser->current.start = parser->current.end;

      // These are the places where we need to split up the content of the
      // string. We'll use strpbrk to find the first of these characters.
      char breakpoints[] = " \\\0";
      breakpoints[0] = parser->lex_modes.current->as.string.terminator;

      // If interpolation is allowed, then we're going to check for the #
      // character. Otherwise we'll only look for escapes and the terminator.
      if (parser->lex_modes.current->as.string.interpolation) {
        breakpoints[2] = '#';
      }

      char *breakpoint = strpbrk(parser->current.end, breakpoints);

      while (breakpoint != NULL) {
        // Note that we have to check the terminator here first because we could
        // potentially be parsing a % string that has a # character as the
        // terminator.
        if (*breakpoint == parser->lex_modes.current->as.string.terminator) {
          // Here we've hit the terminator. If we have already consumed content
          // then we need to return that content as string content first.
          if (breakpoint > parser->current.end) {
            parser->current.end = breakpoint;
            return YP_TOKEN_STRING_CONTENT;
          }

          // Otherwise we need to switch back to the parent lex mode and
          // return the end of the string.
          parser->current.end = breakpoint + 1;
          lex_mode_pop(parser);

          lex_state_set(parser, YP_LEX_STATE_END);
          return YP_TOKEN_STRING_END;
        }

        if (*breakpoint == '\\') {
          // If we hit escapes, then we need to treat the next token literally.
          // In this case we'll skip past the next character and find the next
          // breakpoint.
          breakpoint = strpbrk(breakpoint + 2, breakpoints);
        } else {
          assert(*breakpoint == '#');

          yp_token_type_t type = lex_interpolation(parser, breakpoint);
          if (type != YP_TOKEN_NOT_PROVIDED) return type;

          // If we haven't returned at this point then we had something that
          // looked like an interpolated class or instance variable like "#@"
          // but wasn't actually. In this case we'll just skip to the next
          // breakpoint.
          breakpoint = strpbrk(parser->current.end, breakpoints);
        }
      }

      // If we've hit the end of the string, then this is an unterminated
      // string. In that case we'll return the EOF token.
      parser->current.end = parser->end;
      return YP_TOKEN_EOF;
    }
    case YP_LEX_HEREDOC: {
      // First, we'll set to start of this token.
      if (parser->next_start == NULL) {
        parser->current.start = parser->current.end;
      } else {
        parser->current.start = parser->next_start;
        parser->current.end = parser->next_start;
        parser->next_start = NULL;
      }

      // Now let's grab the information about the identifier off of the current
      // lex mode.
      const char *ident_start = parser->lex_modes.current->as.heredoc.ident_start;
      uint32_t ident_length = parser->lex_modes.current->as.heredoc.ident_length;

      // If we are immediately following a newline and we have hit the
      // terminator, then we need to return the ending of the heredoc.
      if ((parser->current.start[-1] == '\n') && (strncmp(parser->current.start, ident_start, ident_length) == 0)) {
        bool matched = false;

        if (parser->current.start[ident_length] == '\n') {
          parser->current.end = parser->current.start + ident_length + 1;
          matched = true;
        } else if ((parser->current.start[ident_length] == '\r') && (parser->current.start[ident_length + 1] == '\n')) {
          parser->current.end = parser->current.start + ident_length + 2;
          matched = true;
        }

        if (matched) {
          parser->next_start = parser->lex_modes.current->as.heredoc.next_start;
          parser->heredoc_end = parser->current.end;

          lex_mode_pop(parser);
          return YP_TOKEN_HEREDOC_END;
        }
      }

      // Otherwise we'll be parsing string content. These are the places where
      // we need to split up the content of the heredoc. We'll use strpbrk to
      // find the first of these characters.
      char breakpoints[] = "\n\\#";
      char *breakpoint = strpbrk(parser->current.end, breakpoints);

      while (breakpoint != NULL) {
        switch (*breakpoint) {
          case '\n':
            // If we have hit a newline that is followed by a valid terminator,
            // then we need to return the content of the heredoc here as string
            // content. Then, the next time a token is lexed, it will match
            // again and return the end of the heredoc.
            if (
              (breakpoint + 1 + ident_length < parser->end) &&
              (strncmp(breakpoint + 1, ident_start, ident_length) == 0)
            ) {
              // Heredoc terminators must be followed by a newline to be valid.
              if (breakpoint[1 + ident_length] == '\n') {
                parser->current.end = breakpoint + 1;
                return YP_TOKEN_STRING_CONTENT;
              }

              // They can also be followed by a carriage return and then a
              // newline. Be sure here that we don't accidentally read off the
              // end.
              if (
                (breakpoint + 1 + ident_length + 1 < parser->end) &&
                (breakpoint[1 + ident_length] == '\r') &&
                (breakpoint[1 + ident_length + 1] == '\n')
              ) {
                parser->current.end = breakpoint + 2;
                return YP_TOKEN_STRING_CONTENT;
              }
            }

            // Otherwise we hit a newline and it wasn't followed by a
            // terminator, so we can continue parsing.
            breakpoint = strpbrk(breakpoint + 1, breakpoints);
            break;
          case '\\':
            // If we hit escapes, then we need to treat the next token
            // literally. In this case we'll skip past the next character and
            // find the next breakpoint.
            breakpoint = strpbrk(breakpoint + 2, breakpoints);
            break;
          case '#': {
            yp_token_type_t type = lex_interpolation(parser, breakpoint);
            if (type != YP_TOKEN_NOT_PROVIDED) return type;

            // If we haven't returned at this point then we had something
            // that looked like an interpolated class or instance variable
            // like "#@" but wasn't actually. In this case we'll just skip
            // to the next breakpoint.
            breakpoint = strpbrk(parser->current.end, breakpoints);
            break;
          }
        }
      }

      // If we've hit the end of the string, then this is an unterminated
      // heredoc. In that case we'll return the EOF token.
      parser->current.end = parser->end;
      return YP_TOKEN_EOF;
    }
    case YP_LEX_SYMBOL: {
      // First, we'll set to start of this token to be the current end.
      parser->current.start = parser->current.end;

      // If we get here then we have the start of a symbol with no content. In
      // that case return an invalid token.
      if (parser->current.end >= parser->end) {
        return YP_TOKEN_INVALID;
      }

      lex_state_set(parser, YP_LEX_STATE_ENDFN);
      lex_mode_pop(parser);

      // Now, look at the next character to see what kind of symbol we can find.
      switch (*parser->current.end++) {
        case '&':
          return YP_TOKEN_AMPERSAND;
        case '`':
          return YP_TOKEN_BACKTICK;
        case '!':
          if (match(parser, '@')) return YP_TOKEN_BANG_AT;
          if (match(parser, '~')) return YP_TOKEN_BANG_TILDE;
          return YP_TOKEN_BANG;
        case '[':
          if (match(parser, ']')) {
            if (match(parser, '=')) return YP_TOKEN_BRACKET_LEFT_RIGHT_EQUAL;
            return YP_TOKEN_BRACKET_LEFT_RIGHT;
          }
          return YP_TOKEN_INVALID;
        case '^':
          return YP_TOKEN_CARET;
        case '=':
          if (match(parser, '=')) {
            if (match(parser, '=')) return YP_TOKEN_EQUAL_EQUAL_EQUAL;
            return YP_TOKEN_EQUAL_EQUAL;
          }
          if (match(parser, '~')) return YP_TOKEN_EQUAL_TILDE;
          return YP_TOKEN_INVALID;
        case '>':
          if (match(parser, '=')) return YP_TOKEN_GREATER_EQUAL;
          if (match(parser, '>')) return YP_TOKEN_GREATER_GREATER;
          return YP_TOKEN_GREATER;
        case '<':
          if (match(parser, '=')) {
            if (match(parser, '>')) return YP_TOKEN_LESS_EQUAL_GREATER;
            return YP_TOKEN_LESS_EQUAL;
          }
          if (match(parser, '<')) return YP_TOKEN_LESS_LESS;
          return YP_TOKEN_LESS;
        case '-':
          return match(parser, '@') ? YP_TOKEN_MINUS_AT : YP_TOKEN_MINUS;
        case '%':
          return YP_TOKEN_PERCENT;
        case '|':
          return YP_TOKEN_PIPE;
        case '+':
          return match(parser, '@') ? YP_TOKEN_PLUS_AT : YP_TOKEN_PLUS;
        case '/':
          return YP_TOKEN_SLASH;
        case '*':
          return match(parser, '*') ? YP_TOKEN_STAR_STAR : YP_TOKEN_STAR;
        case '~':
          return match(parser, '@') ? YP_TOKEN_TILDE_AT : YP_TOKEN_TILDE;
        case '@': {
          yp_token_type_t type = lex_at_variable(parser);
          lex_state_set(parser, YP_LEX_STATE_ENDFN);
          return type;
        }
        case '$': {
          yp_token_type_t type = lex_global_variable(parser);
          lex_state_set(parser, YP_LEX_STATE_END);
          return type;
        }
        default: {
          // If this isn't the beginning of an identifier, then it's an invalid
          // token as we've exhausted all of the other options.
          size_t width = char_is_identifier_start(parser, parser->current.start);
          if (!width) return YP_TOKEN_INVALID;

          parser->current.end = parser->current.start + width;
          yp_token_type_t type = lex_identifier(parser);
          lex_state_set(parser, YP_LEX_STATE_ENDFN);

          return match(parser, '=') ? YP_TOKEN_IDENTIFIER : type;
        }
      }

      // If we got here, then we have a symbol followed by something we don't
      // understand. In that case we'll just return an invalid token.
      return YP_TOKEN_INVALID;
    }
  }

  // We shouldn't be able to get here at all, but some compilers can't figure
  // that out, so just returning a value here to make them happy.
  return YP_TOKEN_INVALID;
}

/******************************************************************************/
/* Encoding-related functions                                                 */
/******************************************************************************/

static yp_encoding_t yp_encoding_ascii = {
  .alnum_char = yp_encoding_ascii_alnum_char,
  .alpha_char = yp_encoding_ascii_alpha_char
};

static yp_encoding_t yp_encoding_iso_8859_9 = {
  .alnum_char = yp_encoding_iso_8859_9_alnum_char,
  .alpha_char = yp_encoding_iso_8859_9_alpha_char
};

static yp_encoding_t yp_encoding_utf_8 = {
  .alnum_char = yp_encoding_utf_8_alnum_char,
  .alpha_char = yp_encoding_utf_8_alpha_char
};

// Here we're going to check if this is a "magic" comment, and perform whatever
// actions are necessary for it here.
static void
parser_lex_magic_comments(yp_parser_t *parser) {
  const char *start = parser->current.start + 1;
  while (char_is_non_newline_whitespace(*start) && start < parser->end) {
    start++;
  }

  if (strncmp(start, "-*-", 3) == 0) {
    start += 3;
    while (char_is_non_newline_whitespace(*start) && start < parser->end) {
      start++;
    }
  }

  // There is a lot TODO here to make it more accurately reflect encoding
  // parsing, but for now this gets us closer.
  if (strncmp(start, "encoding:", 9) == 0) {
    start += 9;
    while (char_is_non_newline_whitespace(*start) && start < parser->end) {
      start++;
    }

    const char *end = start;
    while (!char_is_whitespace(*end) && end < parser->end) {
      end++;
    }
    size_t width = end - start;

    // First, we're going to loop through each of the encodings that we handle
    // explicitly. If we found one that we understand, we'll use that value.
#define ENCODING(value, prebuilt) \
    if (width == sizeof(value) - 1 && strncasecmp(start, value, sizeof(value) - 1) == 0) { \
      parser->encoding = prebuilt; \
      return; \
    }

    ENCODING("ascii", yp_encoding_ascii);
    ENCODING("iso-8859-9", yp_encoding_iso_8859_9);
    ENCODING("utf-8", yp_encoding_utf_8);
    ENCODING("binary", yp_encoding_ascii);
    ENCODING("us-ascii", yp_encoding_ascii);

#undef ENCODING

    // Otherwise, we're going to call out to a user-defined callback. If they
    // return an encoding struct that we can use, then we'll use that here.
    yp_encoding_t *encoding = parser->encoding_decode_callback(start, width);
    if (encoding != NULL) {
      parser->encoding = *encoding;
      return;
    }

    // If nothing was returned by this point, then we've got an issue because we
    // didn't understand the encoding that the user was trying to use. In this
    // case we'll keep using the default encoding but add an error to the
    // parser to indicate an unsuccessful parse.
    yp_diagnostic_list_append(&parser->error_list, "Could not understand the encoding specified in the magic comment.", start - parser->start);
  }
}

/******************************************************************************/
/* Parse functions                                                            */
/******************************************************************************/

// When we are parsing string-like content, we need to unescape the content to
// provide to the consumers of the parser. This function accepts a range of
// characters from the source and unescapes into the provided string.
static yp_node_t *
yp_node_string_node_create_and_unescape(yp_parser_t *parser, const yp_token_t *opening, const yp_token_t *content, const yp_token_t *closing, yp_unescape_type_t unescape_type) {
  yp_node_t *node = yp_node_string_node_create(parser, opening, content, closing);
  yp_unescape(content->start, content->end - content->start, &node->as.string_node.unescaped, unescape_type, &parser->error_list);
  return node;
}

// Return a new comment node of the specified type.
static inline yp_comment_t *
parser_comment(yp_parser_t *parser, yp_comment_type_t type) {
  yp_comment_t *comment = (yp_comment_t *) malloc(sizeof(yp_comment_t));
  *comment = (yp_comment_t) {
    .type = type,
    .start = parser->current.start - parser->start,
    .end = parser->current.end - parser->start
  };

  return comment;
}

// Returns true if the current token is of the specified type.
static inline bool
match_type_p(yp_parser_t *parser, yp_token_type_t type) {
  return parser->current.type == type;
}

// Returns true if the current token is of any of the specified types.
static bool
match_any_type_p(yp_parser_t *parser, size_t count, ...) {
  va_list types;
  va_start(types, count);

  for (size_t index = 0; index < count; index++) {
    if (match_type_p(parser, va_arg(types, yp_token_type_t))) {
      va_end(types);
      return true;
    }
  }

  va_end(types);
  return false;
}

// Optionally call out to the lex callback if one is provided.
static inline void
parser_lex_callback(yp_parser_t *parser) {
  parser->lex_callback->callback(parser->lex_callback->data, parser, &parser->current);
}

// Called when the parser requires a new token. The parser maintains a moving
// window of two tokens at a time: parser.previous and parser.current. This
// function will move the current token into the previous token and then
// lex a new token into the current token.
//
// The raw lex_token_type function is responsible for returning the next token
// type that it finds. This function is responsible for taking that output and
// skipping past any tokens that should not be present in the final tree. This
// includes any kind of comments or invalid tokens.
static void
parser_lex(yp_parser_t *parser) {
  assert(parser->current.end <= parser->end);

  parser->previous = parser->current;
  parser->current.type = lex_token_type(parser);
  if (parser->lex_callback) parser_lex_callback(parser);

  while (match_any_type_p(parser, 4, YP_TOKEN_COMMENT, YP_TOKEN___END__, YP_TOKEN_EMBDOC_BEGIN, YP_TOKEN_INVALID)) {
    switch (parser->current.type) {
      case YP_TOKEN_COMMENT: {
        // If we found a comment while lexing, then we're going to add it to the
        // list of comments in the file and keep lexing.
        yp_comment_t *comment = parser_comment(parser, YP_COMMENT_INLINE);
        yp_list_append(&parser->comment_list, (yp_list_node_t *) comment);

        parser_lex_magic_comments(parser);
        parser->current.type = lex_token_type(parser);
        if (parser->lex_callback) parser_lex_callback(parser);

        break;
      }
      case YP_TOKEN___END__: {
        yp_comment_t *comment = parser_comment(parser, YP_COMMENT___END__);
        yp_list_append(&parser->comment_list, (yp_list_node_t *) comment);

        parser->current.type = lex_token_type(parser);
        if (parser->lex_callback) parser_lex_callback(parser);

        break;
      }
      case YP_TOKEN_EMBDOC_BEGIN: {
        yp_comment_t *comment = parser_comment(parser, YP_COMMENT_EMBDOC);

        // If we found an embedded document, then we need to lex until we find
        // the end of the embedded document.
        do {
          parser->current.type = lex_token_type(parser);
          if (parser->lex_callback) parser_lex_callback(parser);
        } while (!match_any_type_p(parser, 2, YP_TOKEN_EMBDOC_END, YP_TOKEN_EOF));

        comment->end = parser->current.end - parser->start;
        yp_list_append(&parser->comment_list, (yp_list_node_t *) comment);

        if (match_type_p(parser, YP_TOKEN_EOF)) {
          yp_diagnostic_list_append(&parser->error_list, "Unterminated embdoc", parser->current.start - parser->start);
        } else {
          parser->current.type = lex_token_type(parser);
          if (parser->lex_callback) parser_lex_callback(parser);
        }
        break;
      }
      case YP_TOKEN_INVALID: {
        // If we found an invalid token, then we're going to add an error to the
        // parser and keep lexing.
        yp_diagnostic_list_append(&parser->error_list, "Invalid token", parser->current.start - parser->start);
        parser->current.type = lex_token_type(parser);
        if (parser->lex_callback) parser_lex_callback(parser);
        break;
      }
      default:
        break;
    }
  }
}

static bool
context_terminator(yp_context_t context, yp_token_t *token) {
  switch (context) {
    case YP_CONTEXT_MAIN:
      return token->type == YP_TOKEN_EOF;
    case YP_CONTEXT_PREEXE:
    case YP_CONTEXT_POSTEXE:
      return token->type == YP_TOKEN_BRACE_RIGHT;
    case YP_CONTEXT_MODULE:
    case YP_CONTEXT_CLASS:
    case YP_CONTEXT_DEF:
    case YP_CONTEXT_WHILE:
    case YP_CONTEXT_UNTIL:
    case YP_CONTEXT_ELSE:
    case YP_CONTEXT_SCLASS:
    case YP_CONTEXT_FOR:
    case YP_CONTEXT_ENSURE:
      return token->type == YP_TOKEN_KEYWORD_END;
    case YP_CONTEXT_IF:
    case YP_CONTEXT_UNLESS:
    case YP_CONTEXT_ELSIF:
      return token->type == YP_TOKEN_KEYWORD_ELSE || token->type == YP_TOKEN_KEYWORD_ELSIF || token->type == YP_TOKEN_KEYWORD_END;
    case YP_CONTEXT_EMBEXPR:
      return token->type == YP_TOKEN_EMBEXPR_END;
    case YP_CONTEXT_BLOCK_BRACES:
      return token->type == YP_TOKEN_BRACE_RIGHT;
    case YP_CONTEXT_PARENS:
      return token->type == YP_TOKEN_PARENTHESIS_RIGHT;
    case YP_CONTEXT_BEGIN:
    case YP_CONTEXT_RESCUE:
      return token->type == YP_TOKEN_KEYWORD_ENSURE || token->type == YP_TOKEN_KEYWORD_RESCUE || token->type == YP_TOKEN_KEYWORD_ELSE || token->type == YP_TOKEN_KEYWORD_END;
    case YP_CONTEXT_RESCUE_ELSE:
      return token->type == YP_TOKEN_KEYWORD_ENSURE || token->type == YP_TOKEN_KEYWORD_END;
  }

  return false;
}

static bool
context_recoverable(yp_parser_t *parser, yp_token_t *token) {
  yp_context_node_t *context_node = parser->current_context;

  while (context_node != NULL) {
    if (context_terminator(context_node->context, token)) return true;
    context_node = context_node->prev;
  }

  return false;
}

static void
context_push(yp_parser_t *parser, yp_context_t context) {
  yp_context_node_t *context_node = (yp_context_node_t *) malloc(sizeof(yp_context_node_t));
  *context_node = (yp_context_node_t) { .context = context, .prev = NULL };

  if (parser->current_context == NULL) {
    parser->current_context = context_node;
  } else {
    context_node->prev = parser->current_context;
    parser->current_context = context_node;
  }
}

static void
context_pop(yp_parser_t *parser) {
  if (parser->current_context->prev == NULL) {
    free(parser->current_context);
    parser->current_context = NULL;
  } else {
    yp_context_node_t *prev = parser->current_context->prev;
    free(parser->current_context);
    parser->current_context = prev;
  }
}

// These are the various precedence rules. Because we are using a Pratt parser,
// they are named binding power to represent the manner in which nodes are bound
// together in the stack.
typedef enum {
  BINDING_POWER_UNSET = 0,       // used to indicate this token cannot be used as an infix operator
  BINDING_POWER_NONE = 1,
  BINDING_POWER_BRACES,          // braces
  BINDING_POWER_MODIFIER,        // if unless until while
  BINDING_POWER_COMPOSITION,     // and or
  BINDING_POWER_NOT,             // not
  BINDING_POWER_DEFINED,         // defined?
  BINDING_POWER_ASSIGNMENT,      // = += -= *= /= %= &= |= ^= &&= ||= <<= >>= **=
  BINDING_POWER_TERNARY,         // ?:
  BINDING_POWER_MODIFIER_RESCUE, // rescue
  BINDING_POWER_RANGE,           // .. ...
  BINDING_POWER_LOGICAL_OR,      // ||
  BINDING_POWER_LOGICAL_AND,     // &&
  BINDING_POWER_EQUALITY,        // <=> == === != =~ !~
  BINDING_POWER_COMPARISON,      // > >= < <=
  BINDING_POWER_BITWISE_OR,      // | ^
  BINDING_POWER_BITWISE_AND,     // &
  BINDING_POWER_SHIFT,           // << >>
  BINDING_POWER_TERM,            // + -
  BINDING_POWER_FACTOR,          // * / %
  BINDING_POWER_UMINUS,          // unary minus
  BINDING_POWER_EXPONENT,        // **
  BINDING_POWER_UNARY,           // ! ~ +
  BINDING_POWER_INDEX,           // [] []=
  BINDING_POWER_CALL,            // :: .
} binding_power_t;

// This struct represents a set of binding powers used for a given token. They
// are combined in this way to make it easier to represent associativity.
typedef struct {
  binding_power_t left;
  binding_power_t right;
} binding_powers_t;

#define LEFT_ASSOCIATIVE(precedence)                                                                                   \
  { precedence, precedence + 1 }
#define RIGHT_ASSOCIATIVE(precedence)                                                                                  \
  { precedence, precedence }

binding_powers_t binding_powers[YP_TOKEN_MAXIMUM] = {
  // {}
  [YP_TOKEN_BRACE_LEFT] = LEFT_ASSOCIATIVE(BINDING_POWER_BRACES),

  // if unless until while
  [YP_TOKEN_KEYWORD_IF] = LEFT_ASSOCIATIVE(BINDING_POWER_MODIFIER),
  [YP_TOKEN_KEYWORD_UNLESS] = LEFT_ASSOCIATIVE(BINDING_POWER_MODIFIER),
  [YP_TOKEN_KEYWORD_UNTIL] = LEFT_ASSOCIATIVE(BINDING_POWER_MODIFIER),
  [YP_TOKEN_KEYWORD_WHILE] = LEFT_ASSOCIATIVE(BINDING_POWER_MODIFIER),

  // and or
  [YP_TOKEN_KEYWORD_AND] = LEFT_ASSOCIATIVE(BINDING_POWER_COMPOSITION),
  [YP_TOKEN_KEYWORD_OR] = LEFT_ASSOCIATIVE(BINDING_POWER_COMPOSITION),

  // &&= &= ^= = >>= <<= -= %= |= += /= *= **=
  [YP_TOKEN_AMPERSAND_AMPERSAND_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_AMPERSAND_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_CARET_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_GREATER_GREATER_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_LESS_LESS_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_MINUS_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_PERCENT_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_PIPE_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_PIPE_PIPE_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_PLUS_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_SLASH_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_STAR_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),
  [YP_TOKEN_STAR_STAR_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_ASSIGNMENT),

  // ?:
  [YP_TOKEN_QUESTION_MARK] = RIGHT_ASSOCIATIVE(BINDING_POWER_TERNARY),

  // rescue
  [YP_TOKEN_KEYWORD_RESCUE] = LEFT_ASSOCIATIVE(BINDING_POWER_MODIFIER_RESCUE),

  // .. ...
  [YP_TOKEN_DOT_DOT] = LEFT_ASSOCIATIVE(BINDING_POWER_RANGE),
  [YP_TOKEN_DOT_DOT_DOT] = LEFT_ASSOCIATIVE(BINDING_POWER_RANGE),

  // ||
  [YP_TOKEN_PIPE_PIPE] = LEFT_ASSOCIATIVE(BINDING_POWER_LOGICAL_OR),

  // &&
  [YP_TOKEN_AMPERSAND_AMPERSAND] = LEFT_ASSOCIATIVE(BINDING_POWER_LOGICAL_AND),

  // != !~ == === =~ <=>
  [YP_TOKEN_BANG_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_EQUALITY),
  [YP_TOKEN_BANG_TILDE] = RIGHT_ASSOCIATIVE(BINDING_POWER_EQUALITY),
  [YP_TOKEN_EQUAL_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_EQUALITY),
  [YP_TOKEN_EQUAL_EQUAL_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_EQUALITY),
  [YP_TOKEN_EQUAL_TILDE] = RIGHT_ASSOCIATIVE(BINDING_POWER_EQUALITY),
  [YP_TOKEN_LESS_EQUAL_GREATER] = RIGHT_ASSOCIATIVE(BINDING_POWER_EQUALITY),

  // > >= < <=
  [YP_TOKEN_GREATER] = RIGHT_ASSOCIATIVE(BINDING_POWER_COMPARISON),
  [YP_TOKEN_GREATER_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_COMPARISON),
  [YP_TOKEN_LESS] = RIGHT_ASSOCIATIVE(BINDING_POWER_COMPARISON),
  [YP_TOKEN_LESS_EQUAL] = RIGHT_ASSOCIATIVE(BINDING_POWER_COMPARISON),

  // ^ |
  [YP_TOKEN_CARET] = RIGHT_ASSOCIATIVE(BINDING_POWER_BITWISE_OR),
  [YP_TOKEN_PIPE] = RIGHT_ASSOCIATIVE(BINDING_POWER_BITWISE_OR),

  // &
  [YP_TOKEN_AMPERSAND] = RIGHT_ASSOCIATIVE(BINDING_POWER_BITWISE_AND),

  // >> <<
  [YP_TOKEN_GREATER_GREATER] = RIGHT_ASSOCIATIVE(BINDING_POWER_SHIFT),
  [YP_TOKEN_LESS_LESS] = RIGHT_ASSOCIATIVE(BINDING_POWER_SHIFT),

  // - +
  [YP_TOKEN_MINUS] = LEFT_ASSOCIATIVE(BINDING_POWER_TERM),
  [YP_TOKEN_PLUS] = LEFT_ASSOCIATIVE(BINDING_POWER_TERM),

  // % / *
  [YP_TOKEN_PERCENT] = LEFT_ASSOCIATIVE(BINDING_POWER_FACTOR),
  [YP_TOKEN_SLASH] = LEFT_ASSOCIATIVE(BINDING_POWER_FACTOR),
  [YP_TOKEN_STAR] = LEFT_ASSOCIATIVE(BINDING_POWER_FACTOR),

  // **
  [YP_TOKEN_STAR_STAR] = RIGHT_ASSOCIATIVE(BINDING_POWER_EXPONENT),

  // ! ~
  [YP_TOKEN_BANG] = RIGHT_ASSOCIATIVE(BINDING_POWER_UNARY),
  [YP_TOKEN_TILDE] = RIGHT_ASSOCIATIVE(BINDING_POWER_UNARY),

  // []
  [YP_TOKEN_BRACKET_LEFT_RIGHT] = LEFT_ASSOCIATIVE(BINDING_POWER_INDEX),
  [YP_TOKEN_BRACKET_LEFT] = LEFT_ASSOCIATIVE(BINDING_POWER_INDEX),

  // :: . &.
  [YP_TOKEN_COLON_COLON] = RIGHT_ASSOCIATIVE(BINDING_POWER_CALL),
  [YP_TOKEN_DOT] = RIGHT_ASSOCIATIVE(BINDING_POWER_CALL),
  [YP_TOKEN_AMPERSAND_DOT] = RIGHT_ASSOCIATIVE(BINDING_POWER_CALL)
};

#undef LEFT_ASSOCIATIVE
#undef RIGHT_ASSOCIATIVE

// If the current token is of the specified type, lex forward by one token and
// return true. Otherwise, return false. For example:
//
//     if (accept(parser, YP_TOKEN_COLON)) { ... }
//
static bool
accept(yp_parser_t *parser, yp_token_type_t type) {
  if (match_type_p(parser, type)) {
    parser_lex(parser);
    return true;
  }
  return false;
}

// If the current token is of any of the specified types, lex forward by one
// token and return true. Otherwise, return false. For example:
//
//     if (accept_any(parser, 2, YP_TOKEN_COLON, YP_TOKEN_SEMICOLON)) { ... }
//
static bool
accept_any(yp_parser_t *parser, size_t count, ...) {
  va_list types;
  va_start(types, count);

  for (size_t index = 0; index < count; index++) {
    if (match_type_p(parser, va_arg(types, yp_token_type_t))) {
      parser_lex(parser);
      va_end(types);
      return true;
    }
  }

  va_end(types);
  return false;
}

// This function indicates that the parser expects a token in a specific
// position. For example, if you're parsing a BEGIN block, you know that a { is
// expected immediately after the keyword. In that case you would call this
// function to indicate that that token should be found.
//
// If we didn't find the token that we were expecting, then we're going to add
// an error to the parser's list of errors (to indicate that the tree is not
// valid) and create an artificial token instead. This allows us to recover from
// the fact that the token isn't present and continue parsing.
static void
expect(yp_parser_t *parser, yp_token_type_t type, const char *message) {
  if (accept(parser, type)) return;

  yp_diagnostic_list_append(&parser->error_list, message, parser->previous.end - parser->start);

  parser->previous =
    (yp_token_t) { .type = YP_TOKEN_MISSING, .start = parser->previous.end, .end = parser->previous.end };
}

static void
expect_any(yp_parser_t *parser, const char*message, int count, ...) {
  va_list types;
  va_start(types, count);

  for (size_t index = 0; index < count; index++) {
    if (accept(parser, va_arg(types, yp_token_type_t))) {
      va_end(types);
      return;
    }
  }

  va_end(types);

  yp_diagnostic_list_append(&parser->error_list, message, parser->previous.end - parser->start);
  parser->previous =
    (yp_token_t) { .type = YP_TOKEN_MISSING, .start = parser->previous.end, .end = parser->previous.end };
}

// In a lot of places in the tree you can have tokens that are not provided but
// that do not cause an error. For example, in a method call without
// parentheses. In these cases we set the token to the "not provided" type. For
// example:
//
//     yp_token_t token;
//     not_provided(&token, parser->previous.end);
//
static inline yp_token_t
not_provided(yp_parser_t *parser) {
  return (yp_token_t) { .type = YP_TOKEN_NOT_PROVIDED, .start = parser->start, .end = parser->start };
}

static yp_node_t *
parse_expression(yp_parser_t *parser, binding_power_t binding_power, const char *message);

// Parse a list of targets for assignment. This is used in the case of a for
// loop or a multi-assignment. For example, in the following code:
//
//     for foo, bar in baz
//         ^^^^^^^^
//
// The targets are `foo` and `bar`. This function will either return a single
// target node or a multi-target node.
static yp_node_t *
parse_targets(yp_parser_t *parser, binding_power_t binding_power, const char *message) {
  yp_node_t *first_target = parse_expression(parser, binding_power, message);

  if (!match_type_p(parser, YP_TOKEN_COMMA)) {
    return first_target;
  }

  yp_node_t *multi_target = yp_node_multi_target_node_create(parser);
  yp_node_t *target;

  yp_node_list_append(parser, multi_target, &multi_target->as.multi_target_node.targets, first_target);

  while (accept(parser, YP_TOKEN_COMMA)) {
    target = parse_expression(parser, binding_power, message);
    yp_node_list_append(parser, multi_target, &multi_target->as.multi_target_node.targets, target);
  }

  return multi_target;
}

// Parse a list of statements separated by newlines or semicolons.
static yp_node_t *
parse_statements(yp_parser_t *parser, yp_context_t context) {
  context_push(parser, context);
  yp_node_t *statements = yp_node_statements_create(parser);

  while (!context_terminator(context, &parser->current)) {
    // Ignore semicolon without statements before them
    if (accept(parser, YP_TOKEN_SEMICOLON) || accept(parser, YP_TOKEN_NEWLINE)) {
      continue;
    }

    yp_node_t *node = parse_expression(parser, BINDING_POWER_NONE, "Expected to be able to parse an expression.");
    yp_node_list_append(parser, statements, &statements->as.statements.body, node);

    // If we're recovering from a syntax error, then we need to stop parsing the
    // statements now.
    if (parser->recovering) {
      // If this is the level of context where the recovery has happened, then
      // we can mark the parser as done recovering.
      if (context_terminator(context, &parser->current)) parser->recovering = false;
      break;
    }

    if (!accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON)) break;
  }

  context_pop(parser);
  return statements;
}

// parse hash assocs either in method keyword arguments
// or in hash literals.
static bool
parse_assoc(yp_parser_t *parser, yp_node_t *hash) {
  while (accept(parser, YP_TOKEN_NEWLINE));

  if (hash->as.hash_node.elements.size != 0) {
    expect(parser, YP_TOKEN_COMMA, "expected a comma between hash entries.");
  }

  while (accept(parser, YP_TOKEN_NEWLINE));
  yp_node_t *element;

  switch (parser->current.type) {
    case YP_TOKEN_STAR_STAR: {
      parser_lex(parser);
      yp_token_t operator = parser->previous;
      yp_node_t *value = parse_expression(parser, BINDING_POWER_NONE, "Expected an expression after ** in hash.");

      element = yp_assoc_splat_node_create(parser, value, &operator);
      break;
    }
    case YP_TOKEN_LABEL: {
      parser_lex(parser);
      yp_token_t label = {
        .type = YP_TOKEN_LABEL,
        .start = parser->previous.start,
        .end = parser->previous.end - 1
      };

      yp_token_t opening = not_provided(parser);
      yp_token_t closing = {
        .type = YP_TOKEN_LABEL_END,
        .start = label.end,
        .end = label.end + 1
      };

      yp_node_t *key = yp_node_symbol_node_create(parser, &opening, &label, &closing);
      yp_token_t operator = not_provided(parser);

      yp_node_t *value = parse_expression(parser, BINDING_POWER_NONE, "Expected an expression after the label in hash.");
      element = yp_assoc_node_create(parser, key, &operator, value);
      break;
    }
    default: {
      yp_node_t *key = parse_expression(parser, BINDING_POWER_NONE, "Expected a key in the hash literal.");
      if (key->type == YP_NODE_MISSING_NODE) {
        yp_node_destroy(parser, key);
        return false;
      }

      expect(parser, YP_TOKEN_EQUAL_GREATER, "expected a => between the key and the value in the hash.");
      yp_token_t operator = parser->previous;
      yp_node_t *value = parse_expression(parser, BINDING_POWER_NONE, "Expected a value in the hash literal.");

      element = yp_assoc_node_create(parser, key, &operator, value);
      break;
    }
  }

  yp_node_list_append(parser, hash, &hash->as.hash_node.elements, element);
  return true;
}

// Parse an individual argument.
static yp_node_t *
parse_argument(yp_parser_t *parser, yp_node_t *arguments) {
  if (accept(parser, YP_TOKEN_DOT_DOT_DOT)) {
    if (!current_scope_has_local(parser, &parser->previous)) {
      yp_diagnostic_list_append(&parser->error_list, "unexpected ... when parent method is not forwarding.", parser->previous.start - parser->start);
    }
    return yp_forwarding_arguments_node_create(parser, &parser->previous);
  }

  if (accept(parser, YP_TOKEN_STAR)) {
    yp_token_t previous = parser->previous;

    if (match_any_type_p(parser, 2, YP_TOKEN_PARENTHESIS_RIGHT, YP_TOKEN_COMMA)) {
      if (!current_scope_has_local(parser, &parser->previous)) {
        yp_diagnostic_list_append(&parser->error_list, "unexpected * when parent method is not forwarding.", parser->previous.start - parser->start);
      }
      return yp_node_star_node_create(parser, &previous, NULL);
    }
    yp_node_t *expression = parse_expression(parser, BINDING_POWER_DEFINED, "Expected an expression after '*' in argument.");
    return yp_node_star_node_create(parser, &parser->previous, expression);
  }

  return parse_expression(parser, BINDING_POWER_NONE, "Expected to be able to parse an argument.");
}

// Parse a list of arguments.
static void
parse_arguments(yp_parser_t *parser, yp_node_t *arguments, yp_token_type_t terminator) {
  while (!match_any_type_p(parser, 4, terminator, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON, YP_TOKEN_EOF)) {
    if (yp_arguments_node_size(arguments) > 0) {
      expect(parser, YP_TOKEN_COMMA, "Expected a ',' to delimit arguments.");
    }

    yp_node_t *argument;

    // start of kwargs
    if (parser->current.type == YP_TOKEN_LABEL) {
      yp_token_t opening = not_provided(parser);
      yp_token_t closing = not_provided(parser);

      argument = yp_node_hash_node_create(parser, &opening, &closing);

      while (!match_any_type_p(parser, 4, terminator, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON, YP_TOKEN_EOF)) {
        if (!parse_assoc(parser, argument)) {
          break;
        }
      }
    } else {
      argument = parse_argument(parser, arguments);

      if (accept(parser, YP_TOKEN_EQUAL_GREATER)) {
        // finish parsing the one we are part way through
        yp_token_t operator = parser->previous;
        yp_node_t *value = parse_expression(parser, BINDING_POWER_NONE, "Expected a value in the hash literal.");
        argument = yp_assoc_node_create(parser, argument, &operator, value);

        // Then parse more if we have a comma
        if (accept(parser, YP_TOKEN_COMMA)) {
          yp_token_t opening = not_provided(parser);
          yp_token_t closing = not_provided(parser);

          argument = yp_node_hash_node_create(parser, &opening, &closing);

          while (!match_any_type_p(parser, 4, terminator, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON, YP_TOKEN_EOF)) {
            if (!parse_assoc(parser, argument)) {
              break;
            }
          }
        }
      }
    }

    yp_arguments_node_append(arguments, argument);
    if (argument->type == YP_NODE_MISSING_NODE) break;
  }
}

// This is a special out parameter to the parse_arguments_list function that
// includes opening and closing parentheses in addition to the arguments since
// it's so common.
typedef struct {
  yp_token_t opening;
  yp_node_t *arguments;
  yp_token_t closing;
} yp_arguments_t;

// Parse a list of parameters on a method definition.
static yp_node_t *
parse_parameters(yp_parser_t *parser, bool uses_parentheses) {
  yp_node_t *params = yp_node_parameters_node_create(parser, NULL, NULL, NULL);
  bool parsing = true;

  while (parsing) {
    switch (parser->current.type) {
      case YP_TOKEN_AMPERSAND: {
        parser_lex(parser);

        yp_token_t operator = parser->previous;
        yp_token_t name;

        if (accept(parser, YP_TOKEN_IDENTIFIER)) {
          name = parser->previous;
          yp_token_list_append(&parser->current_scope->as.scope.locals, &name);
        } else {
          name = not_provided(parser);
        }

        yp_node_t *param = yp_block_parameter_node_create(parser, &name, &operator);
        params->as.parameters_node.block = param;

        if (!accept(parser, YP_TOKEN_COMMA)) parsing = false;
        break;
      }
      case YP_TOKEN_DOT_DOT_DOT: {
        parser_lex(parser);

        yp_token_list_append(&parser->current_scope->as.scope.locals, &parser->previous);
        yp_node_t *param = yp_node_forwarding_parameter_node_create(parser, &parser->previous);
        params->as.parameters_node.keyword_rest = param;

        if (!accept(parser, YP_TOKEN_COMMA)) parsing = false;
        break;
      }
      case YP_TOKEN_IDENTIFIER: {
        parser_lex(parser);

        yp_token_t name = parser->previous;
        yp_token_list_append(&parser->current_scope->as.scope.locals, &name);

        if (accept(parser, YP_TOKEN_EQUAL)) {
          yp_token_t operator = parser->previous;
          yp_node_t *value = parse_expression(parser, BINDING_POWER_NONE, "Expected to find a default value for the parameter.");

          yp_node_t *param = yp_node_optional_parameter_node_create(parser, &name, &operator, value);
          yp_node_list_append(parser, params, &params->as.parameters_node.optionals, param);

          // If parsing the value of the parameter resulted in error recovery,
          // then we can put a missing node in its place and stop parsing the
          // parameters entirely now.
          if (parser->recovering) return params;
        } else {
          yp_node_t *param = yp_node_required_parameter_node_create(parser, &name);
          yp_node_list_append(parser, params, &params->as.parameters_node.requireds, param);
        }

        if (!accept(parser, YP_TOKEN_COMMA)) parsing = false;
        break;
      }
      case YP_TOKEN_LABEL: {
        parser_lex(parser);

        yp_token_t name = parser->previous;
        yp_token_t local = name;
        local.end -= 1;
        yp_token_list_append(&parser->current_scope->as.scope.locals, &local);

        switch (parser->current.type) {
          case YP_TOKEN_COMMA:
          case YP_TOKEN_PARENTHESIS_RIGHT:
          case YP_TOKEN_PIPE: {
            yp_node_t *param = yp_node_keyword_parameter_node_create(parser, &name, NULL);
            yp_node_list_append(parser, params, &params->as.parameters_node.keywords, param);
            break;
          }
          case YP_TOKEN_NEWLINE: {
            if (!uses_parentheses) {
              yp_node_t *param = yp_node_keyword_parameter_node_create(parser, &name, NULL);
              yp_node_list_append(parser, params, &params->as.parameters_node.keywords, param);
              break;
            } else {
              accept(parser, YP_TOKEN_NEWLINE);
            }
          }
          default: {
            yp_node_t *value = parse_expression(parser, BINDING_POWER_NONE, "Expected to find a default value for the keyword parameter.");

            yp_node_t *param = yp_node_keyword_parameter_node_create(parser, &name, value);
            yp_node_list_append(parser, params, &params->as.parameters_node.optionals, param);

            // If parsing the value of the parameter resulted in error recovery,
            // then we can put a missing node in its place and stop parsing the
            // parameters entirely now.
            if (parser->recovering) return params;
          }
        }

        if (!accept(parser, YP_TOKEN_COMMA)) parsing = false;
        break;
      }
      case YP_TOKEN_STAR: {
        parser_lex(parser);

        yp_token_t operator = parser->previous;
        yp_token_t name;

        if (accept(parser, YP_TOKEN_IDENTIFIER)) {
          name = parser->previous;
          yp_token_list_append(&parser->current_scope->as.scope.locals, &name);
        } else {
          yp_token_list_append(&parser->current_scope->as.scope.locals, &operator);
          name = not_provided(parser);
        }

        yp_node_t *param = yp_node_rest_parameter_node_create(parser, &operator, &name);
        params->as.parameters_node.rest = param;
        if (!accept(parser, YP_TOKEN_COMMA)) parsing = false;
        break;
      }
      case YP_TOKEN_STAR_STAR: {
        parser_lex(parser);

        yp_node_t *param;

        if (accept(parser, YP_TOKEN_KEYWORD_NIL)) {
          param = yp_node_no_keywords_parameter_node_create(parser, &parser->previous);
        } else {
          yp_token_t operator = parser->previous;
          yp_token_t name;

          if (accept(parser, YP_TOKEN_IDENTIFIER)) {
            name = parser->previous;
            yp_token_list_append(&parser->current_scope->as.scope.locals, &name);
          } else {
            name = not_provided(parser);
          }

          param = yp_node_keyword_rest_parameter_node_create(parser, &operator, &name);
        }

        params->as.parameters_node.keyword_rest = param;
        if (!accept(parser, YP_TOKEN_COMMA)) parsing = false;
        break;
      }
      default: {
        parsing = false;
        break;
      }
    }
  }

  return params;
}

// Parse a list of arguments and their surrounding parentheses if they are
// present.
static void
parse_arguments_list(yp_parser_t *parser, yp_arguments_t *arguments) {
  switch (parser->current.type) {
    case YP_TOKEN_EOF:
    case YP_TOKEN_BRACE_RIGHT:
    case YP_TOKEN_BRACKET_RIGHT:
    case YP_TOKEN_COLON:
    case YP_TOKEN_COMMA:
    case YP_TOKEN_EMBEXPR_END:
    case YP_TOKEN_EQUAL_GREATER:
    case YP_TOKEN_KEYWORD_DO:
    case YP_TOKEN_KEYWORD_END:
    case YP_TOKEN_KEYWORD_IN:
    case YP_TOKEN_NEWLINE:
    case YP_TOKEN_PARENTHESIS_RIGHT:
    case YP_TOKEN_SEMICOLON: {
      // The reason we need this short-circuit is because we're using the
      // binding powers table to tell us if the subsequent token could
      // potentially be an argument. If there _is_ a binding power for one of
      // these tokens, then we should remove it from this list and let it be
      // handled by the default case below.
      assert(binding_powers[parser->current.type].left == BINDING_POWER_UNSET);

      arguments->opening = not_provided(parser);
      arguments->closing = not_provided(parser);
      arguments->arguments = NULL;

      break;
    }
    case YP_TOKEN_PARENTHESIS_LEFT: {
      parser_lex(parser);
      arguments->opening = parser->previous;

      if (accept(parser, YP_TOKEN_PARENTHESIS_RIGHT)) {
        arguments->arguments = NULL;
        arguments->closing = parser->previous;
      } else {
        arguments->arguments = yp_node_arguments_node_create(parser);
        parse_arguments(parser, arguments->arguments, YP_TOKEN_PARENTHESIS_RIGHT);
        expect(parser, YP_TOKEN_PARENTHESIS_RIGHT, "Expected a ')' to close the argument list.");
        arguments->closing = parser->previous;
      }
      break;
    }
    default: {
      arguments->opening = not_provided(parser);
      arguments->closing = not_provided(parser);

      if (binding_powers[parser->current.type].left == BINDING_POWER_UNSET) {
        // If we get here, then the subsequent token cannot be used as an infix
        // operator. In this case we assume the subsequent token is part of an
        // argument to this method call.
        arguments->arguments = yp_node_arguments_node_create(parser);
        parse_arguments(parser, arguments->arguments, YP_TOKEN_EOF);
      } else {
        arguments->arguments = NULL;
      }

      break;
    }
  }

  if (accept(parser, YP_TOKEN_BRACE_LEFT)) {
    not_provided(parser);
    not_provided(parser);

    yp_token_t opening = parser->previous;

    accept(parser, YP_TOKEN_NEWLINE);

    yp_node_t *block_arguments = NULL;
    if (accept(parser, YP_TOKEN_PIPE)) {
      block_arguments = parse_parameters(parser, false);
      expect(parser, YP_TOKEN_PIPE, "expected block arguements to end with '|'.");
    }

    accept(parser, YP_TOKEN_NEWLINE);
    arguments->arguments =  yp_node_arguments_node_create(parser);

    yp_node_t *statements = NULL;
    if (parser->current.type != YP_TOKEN_BRACE_RIGHT) {
      statements = parse_statements(parser, YP_CONTEXT_BLOCK_BRACES);
    }

    expect(parser, YP_TOKEN_BRACE_RIGHT, "expected block beginning with '{' to end with '}'.");

    yp_node_t *block = yp_node_block_node_create(parser, &opening, block_arguments, statements, &parser->previous);
    yp_node_list_append(parser, arguments->arguments, &arguments->arguments->as.arguments_node.arguments, block);
  }
}

static inline yp_node_t *
parse_conditional(yp_parser_t *parser, yp_context_t context) {
  yp_token_t keyword = parser->previous;

  yp_node_t *predicate = parse_expression(parser, BINDING_POWER_NONE, "Expected to find a predicate for the conditional.");
  accept_any(parser, 3, YP_TOKEN_KEYWORD_THEN, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

  yp_node_t *statements = parse_statements(parser, context);
  accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

  yp_token_t end_keyword = not_provided(parser);

  yp_node_t *parent;
  switch (context) {
    case YP_CONTEXT_IF:
      parent = yp_node_if_node_create(parser, &keyword, predicate, statements, NULL, &end_keyword);
      break;
    case YP_CONTEXT_UNLESS:
      parent = yp_node_unless_node_create(parser, &keyword, predicate, statements, NULL, &end_keyword);
      break;
    default:
      // Should not be able to reach here.
      parent = NULL;
      break;
  }

  yp_node_t *current = parent;

  // Parse any number of elsif clauses. This will form a linked list of if
  // nodes pointing to each other from the top.
  while (accept(parser, YP_TOKEN_KEYWORD_ELSIF)) {
    yp_token_t elsif_keyword = parser->previous;

    yp_node_t *predicate = parse_expression(parser, BINDING_POWER_NONE, "Expected to find a predicate for the elsif clause.");
    accept_any(parser, 3, YP_TOKEN_KEYWORD_THEN, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

    yp_node_t *statements = parse_statements(parser, YP_CONTEXT_ELSIF);
    accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

    yp_node_t *elsif = yp_node_if_node_create(parser, &elsif_keyword, predicate, statements, NULL, &end_keyword);
    current->as.if_node.consequent = elsif;
    current = elsif;
  }

  switch (parser->current.type) {
    case YP_TOKEN_KEYWORD_ELSE: {
      parser_lex(parser);
      yp_token_t else_keyword = parser->previous;
      yp_node_t *else_statements = parse_statements(parser, YP_CONTEXT_ELSE);

      accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);
      expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close `else` clause.");

      yp_node_t *else_node = yp_node_else_node_create(parser, &else_keyword, else_statements, &parser->previous);
      current->as.if_node.consequent = else_node;
      parent->as.if_node.end_keyword = parser->previous;
      break;
    }
    case YP_TOKEN_KEYWORD_END: {
      parser_lex(parser);
      parent->as.if_node.end_keyword = parser->previous;
      break;
    }
    default:
      expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close `if` statement.");
      parent->as.if_node.end_keyword = parser->previous;
      break;
  }

  return parent;
}

static yp_node_t *
parse_symbol(yp_parser_t *parser, int mode, yp_lex_state_t next_state) {
  yp_token_t opening = parser->previous;

  if (mode == YP_LEX_SYMBOL) {
    if (next_state != YP_LEX_STATE_NONE) parser->lex_state = next_state;

    yp_token_t symbol = parser->current;
    parser_lex(parser);

    yp_token_t closing = not_provided(parser);
    return yp_node_symbol_node_create(parser, &opening, &symbol, &closing);
  }

  // If we're not in YP_LEX_SYMBOL, then we should be in YP_LEX_STRING, because
  // the lexer determined this was a dynamic symbol node.
  assert(mode == YP_LEX_STRING);

  if (parser->lex_modes.current->as.string.interpolation) {
    yp_node_t *interpolated = yp_node_interpolated_symbol_node_create(parser, &opening, &opening);

    while (!match_any_type_p(parser, 2, YP_TOKEN_STRING_END, YP_TOKEN_EOF)) {
      switch (parser->current.type) {
        case YP_TOKEN_STRING_CONTENT: {
          parser_lex(parser);

          yp_token_t opening = not_provided(parser);;
          yp_token_t closing = not_provided(parser);;
          yp_node_t *part = yp_node_string_node_create_and_unescape(parser, &opening, &parser->previous, &closing, YP_UNESCAPE_ALL);

          yp_node_list_append(parser, interpolated, &interpolated->as.interpolated_symbol_node.parts, part);
          break;
        }
        case YP_TOKEN_EMBEXPR_BEGIN: {
          parser_lex(parser);

          yp_token_t opening = parser->previous;
          yp_node_t *statements = parse_statements(parser, YP_CONTEXT_EMBEXPR);
          expect(parser, YP_TOKEN_EMBEXPR_END, "Expected a closing delimiter for an embedded expression.");

          yp_node_t *part = yp_node_string_interpolated_node_create(parser, &opening, statements, &parser->previous);
          yp_node_list_append(parser, interpolated, &interpolated->as.interpolated_symbol_node.parts, part);
          break;
        }
        default:
          fprintf(stderr, "Could not understand token type %s in an interpolated symbol\n", yp_token_type_to_str(parser->previous.type));
          return NULL;
      }
    }

    if (next_state != YP_LEX_STATE_NONE) parser->lex_state = next_state;
    expect(parser, YP_TOKEN_STRING_END, "Expected a closing delimiter for an interpolated symbol.");

    interpolated->as.interpolated_symbol_node.closing = parser->previous;
    return interpolated;
  }

  yp_token_t content;
  if (accept(parser, YP_TOKEN_STRING_CONTENT)) {
    content = parser->previous;
  } else {
    content = (yp_token_t) { .type = YP_TOKEN_STRING_CONTENT, .start = parser->previous.end, .end = parser->previous.end };
  }

  if (next_state != YP_LEX_STATE_NONE) parser->lex_state = next_state;
  expect(parser, YP_TOKEN_STRING_END, "Expected a closing delimiter for a dynamic symbol.");

  return yp_node_symbol_node_create(parser, &opening, &content, &parser->previous);
}

// Parse an argument to undef which can either be a bare word, a
// symbol, or an interpolated symbol.
static inline yp_node_t *
parse_undef_argument(yp_parser_t *parser) {
  switch (parser->current.type) {
    case YP_TOKEN_IDENTIFIER: {
      parser_lex(parser);

      yp_token_t opening = not_provided(parser);
      yp_token_t closing = not_provided(parser);

      return yp_node_symbol_node_create(parser, &opening, &parser->previous, &closing);
    }
    case YP_TOKEN_SYMBOL_BEGIN: {
      int mode = parser->lex_modes.current->mode;
      parser_lex(parser);
      return parse_symbol(parser, mode, YP_LEX_STATE_NONE);
    }
    default:
      yp_diagnostic_list_append(&parser->error_list, "Expected a bare word or symbol argument.", parser->current.start - parser->start);

      return yp_node_missing_node_create(parser, &(yp_location_t) {
        .start = parser->current.start,
        .end = parser->current.end,
      });
  }
}

// Parse an argument to alias which can either be a bare word, a symbol, an
// interpolated symbol or a global variable. If this is the first argument, then
// we need to set the lex state to YP_LEX_STATE_FNAME | YP_LEX_STATE_FITEM
// between the first and second arguments.
static inline yp_node_t *
parse_alias_argument(yp_parser_t *parser, bool first) {
  switch (parser->current.type) {
    case YP_TOKEN_IDENTIFIER: {
      if (first) {
        parser->lex_state = YP_LEX_STATE_FNAME | YP_LEX_STATE_FITEM;
      }

      parser_lex(parser);
      yp_token_t opening = not_provided(parser);
      yp_token_t closing = not_provided(parser);

      return yp_node_symbol_node_create(parser, &opening, &parser->previous, &closing);
    }
    case YP_TOKEN_SYMBOL_BEGIN: {
      int mode = parser->lex_modes.current->mode;
      parser_lex(parser);

      return parse_symbol(parser, mode, first ? YP_LEX_STATE_FNAME | YP_LEX_STATE_FITEM : YP_LEX_STATE_NONE);
    }
    case YP_TOKEN_BACK_REFERENCE:
    case YP_TOKEN_NTH_REFERENCE:
    case YP_TOKEN_GLOBAL_VARIABLE: {
      if (first) {
        parser->lex_state = YP_LEX_STATE_FNAME | YP_LEX_STATE_FITEM;
      }

      parser_lex(parser);
      return yp_node_global_variable_read_create(parser, &parser->previous);
    }
    default:
      yp_diagnostic_list_append(&parser->error_list, "Expected a bare word, symbol or global variable argument.", parser->current.start - parser->start);

      return yp_node_missing_node_create(parser, &(yp_location_t) {
        .start = parser->current.start,
        .end = parser->current.end
      });
  }
}

// Parse a node that is part of a string. If the subsequent tokens cannot be
// parsed as a string part, then NULL is returned.
static yp_node_t *
parse_string_part(yp_parser_t *parser) {
  switch (parser->previous.type) {
    // Here the lexer has returned to us plain string content. In this case
    // we'll create a string node that has no opening or closing and return that
    // as the part. These kinds of parts look like:
    //
    //     "aaa #{bbb} #@ccc ddd"
    //      ^^^^      ^     ^^^^
    case YP_TOKEN_STRING_CONTENT: {
      yp_token_t opening = not_provided(parser);
      yp_token_t closing = not_provided(parser);

      return yp_node_string_node_create_and_unescape(parser, &opening, &parser->previous, &closing, YP_UNESCAPE_ALL);
    }
    // Here the lexer has returned the beginning of an embedded expression. In
    // that case we'll parse the inner statements and return that as the part.
    // These kinds of parts look like:
    //
    //     "aaa #{bbb} #@ccc ddd"
    //          ^^^^^^
    case YP_TOKEN_EMBEXPR_BEGIN: {
      yp_token_t opening = parser->previous;
      yp_node_t *statements = parse_statements(parser, YP_CONTEXT_EMBEXPR);

      expect(parser, YP_TOKEN_EMBEXPR_END, "Expected a closing delimiter for an embedded expression.");
      yp_token_t closing = parser->previous;

      return yp_node_string_interpolated_node_create(parser, &opening, statements, &closing);
    }
    // Here the lexer has returned the beginning of an embedded variable. In
    // that case we'll parse the variable and create an appropriate node for it
    // and then return that node. These kinds of parts look like:
    //
    //     "aaa #{bbb} #@ccc ddd"
    //                 ^^^^^
    case YP_TOKEN_EMBVAR: {
      parser_lex(parser);

      switch (parser->previous.type) {
        // In this case a global variable is being interpolated. We'll create
        // a global variable read node.
        case YP_TOKEN_BACK_REFERENCE:
        case YP_TOKEN_GLOBAL_VARIABLE:
        case YP_TOKEN_NTH_REFERENCE:
          return yp_node_global_variable_read_create(parser, &parser->previous);
        // In this case an instance variable is being interpolated. We'll
        // create an instance variable read node.
        case YP_TOKEN_INSTANCE_VARIABLE:
          return yp_node_instance_variable_read_create(parser, &parser->previous);
        // In this case a class variable is being interpolated. We'll create a
        // class variable read node.
        case YP_TOKEN_CLASS_VARIABLE:
          return yp_node_class_variable_read_create(parser, &parser->previous);
        default:
          assert(false && "Unexpected token type for an interpolated variable.");
      }
    }
    default:
      yp_diagnostic_list_append(&parser->error_list, "Could not understand string part", parser->previous.start - parser->start);
      return NULL;
  }
}

// If the current string has any interpolation, return false. Otherwise, parse
// the content of the string and return true.
static bool
parse_string_without_interpolation(yp_parser_t *parser, yp_token_type_t end_type, yp_token_t *content) {
  // When we get here, we don't know if this string is going to have
  // interpolation or not, even though it is allowed. Still, we want to be
  // able to return a string node without interpolation if we can since it'll
  // be faster.

  if (match_type_p(parser, end_type)) {
    // If we get here, then we have an end immediately after a start. In
    // that case we'll create an empty content token and return an
    // uninterpolated string.
    *content = (yp_token_t) {
      .type = YP_TOKEN_STRING_CONTENT,
      .start = parser->previous.end,
      .end = parser->previous.end
    };

    parser_lex(parser);
    return true;
  }

  if (match_type_p(parser, YP_TOKEN_STRING_CONTENT)) {
    // In this case we've hit string content so we know the string at least
    // has something in it. We'll need to check if the following token is the
    // end (in which case we can return a plain string) or if it's not then it
    // has interpolation.
    *content = parser->current;

    parser_lex(parser);
    if (accept(parser, end_type)) {
      return true;
    }

    // If we get here, then we have interpolation so we'll need to create
    // a string node with interpolation.
    return false;
  }

  // If we hit anything else, then we're going to create a string with
  // interpolation.
  parser_lex(parser);
  return false;
}

// Parse all the nodes that are part of a string. This function should be
// called immediately after parse_string_without_interpolation.
static void
parse_interpolated_string_parts(yp_parser_t *parser, yp_token_type_t end_type, yp_node_t *node, yp_node_list_t *parts) {
  bool advancing = false;
  while (!match_any_type_p(parser, 2, end_type, YP_TOKEN_EOF)) {
    if (advancing) parser_lex(parser);
    advancing = true;

    yp_node_t *part;
    if ((part = parse_string_part(parser)) != NULL) {
      yp_node_list_append(parser, node, parts, part);
    }
  }
}

// Parse an identifier into either a local variable read or a call.
static yp_node_t *
parse_vcall(yp_parser_t *parser) {
  if (
    (parser->current.type != YP_TOKEN_PARENTHESIS_LEFT) &&
    (parser->previous.end[-1] != '!') &&
    (parser->previous.end[-1] != '?') &&
    yp_token_list_includes(&parser->current_scope->as.scope.locals, &parser->previous)
  ) {
    return yp_node_local_variable_read_create(parser, &parser->previous);
  }

  yp_token_t message = parser->previous;
  yp_token_t operator = not_provided(parser);
  yp_token_t opening = not_provided(parser);
  yp_token_t closing = not_provided(parser);

  yp_node_t *node = yp_node_call_node_create(parser, NULL, &operator, &message, &opening, NULL, &closing);
  yp_string_shared_init(&node->as.call_node.name, message.start, message.end);

  return node;
}

static yp_node_t *
parse_identifier(yp_parser_t *parser) {
  yp_node_t *node = parse_vcall(parser);

  if (node->type == YP_NODE_CALL_NODE) {
    yp_arguments_t arguments;
    parse_arguments_list(parser, &arguments);

    node->as.call_node.lparen = arguments.opening;
    node->as.call_node.rparen = arguments.closing;
    node->as.call_node.arguments = arguments.arguments;

    if (arguments.closing.type == YP_TOKEN_NOT_PROVIDED) {
      node->location.end = node->as.call_node.message.end;
    } else {
      node->location.end = arguments.closing.end;
    }
  }

  return node;
}

static inline yp_token_t
parse_method_definition_name(yp_parser_t *parser) {
  if (
    token_type_is_operator(parser->current.type) ||
    token_type_is_keyword(parser->current.type) ||
    parser->current.type == YP_TOKEN_IDENTIFIER
  ) {
    parser_lex(parser);
    return parser->previous;
  }
  return not_provided(parser);
}

// Parse an expression that begins with the previous node that we just lexed.
static inline yp_node_t *
parse_expression_prefix(yp_parser_t *parser) {
  yp_lex_mode_t lex_mode = *parser->lex_modes.current;

  switch (parser->current.type) {
    case YP_TOKEN_BRACKET_LEFT: {
      parser_lex(parser);

      yp_token_t opening = parser->previous;
      yp_node_t *array = yp_array_node_create(parser, &opening, &opening);

      while (accept(parser, YP_TOKEN_NEWLINE));
      while (!match_any_type_p(parser, 2, YP_TOKEN_BRACKET_RIGHT, YP_TOKEN_EOF)) {
        if (yp_array_node_size(array) != 0) {
          expect(parser, YP_TOKEN_COMMA, "Expected a separator for the elements in an array.");
          while (accept(parser, YP_TOKEN_NEWLINE));
        }


        yp_node_t *element;

        if (accept(parser, YP_TOKEN_STAR)) {
          // [*splat]
          yp_node_t *expression = parse_expression(parser, BINDING_POWER_DEFINED, "Expected an expression after '*' in the array.");
          element = yp_node_star_node_create(parser, &parser->previous, expression);
        } else {
          element = parse_expression(parser, BINDING_POWER_DEFINED, "Expected an element for the array.");
        }

        yp_array_node_append(array, element);
      }

      expect(parser, YP_TOKEN_BRACKET_RIGHT, "Expected a closing bracket for the array.");
      yp_array_node_close_set(array, &parser->previous);

      return array;
    }
    case YP_TOKEN_PARENTHESIS_LEFT: {
      parser_lex(parser);

      yp_token_t opening = parser->previous;
      yp_node_t *parentheses;

      if (!match_any_type_p(parser, 2, YP_TOKEN_PARENTHESIS_RIGHT, YP_TOKEN_EOF)) {
        yp_node_t *statements = parse_statements(parser, YP_CONTEXT_PARENS);
        parentheses = yp_node_parentheses_node_create(parser, &opening, statements, &opening);
      } else {
        yp_node_t *statements = yp_node_statements_create(parser);
        parentheses = yp_node_parentheses_node_create(parser, &opening, statements, &opening);
      }

      expect(parser, YP_TOKEN_PARENTHESIS_RIGHT, "Expected a closing parenthesis.");
      parentheses->as.parentheses_node.closing = parser->previous;
      parentheses->location.end = parser->previous.end;
      return parentheses;
    }
    case YP_TOKEN_BRACE_LEFT: {
      parser_lex(parser);

      yp_token_t opening = parser->previous;
      yp_node_t *node = yp_node_hash_node_create(parser, &opening, &opening);

      while (accept(parser, YP_TOKEN_NEWLINE));
      while (!match_any_type_p(parser, 2, YP_TOKEN_BRACE_RIGHT, YP_TOKEN_EOF)) {
        if (!parse_assoc(parser, node)) {
          break;
        }
      }

      expect(parser, YP_TOKEN_BRACE_RIGHT, "Expected a closing delimiter for a hash literal.");
      node->as.hash_node.closing = parser->previous;
      return node;
    }
    case YP_TOKEN_CHARACTER_LITERAL: {
      parser_lex(parser);

      yp_token_t opening = parser->previous;
      opening.type = YP_TOKEN_STRING_BEGIN;
      opening.end = opening.start + 1;

      yp_token_t content = parser->previous;
      content.type = YP_TOKEN_STRING_CONTENT;
      content.start = content.start + 1;

      yp_token_t closing = not_provided(parser);

      return yp_node_string_node_create_and_unescape(parser, &opening, &content, &closing, YP_UNESCAPE_ALL);
    }
    case YP_TOKEN_CLASS_VARIABLE:
      parser_lex(parser);
      return yp_node_class_variable_read_create(parser, &parser->previous);
    case YP_TOKEN_CONSTANT: {
      parser_lex(parser);
      yp_token_t constant = parser->previous;

      // If a constant is immediately followed by parentheses, then this is in
      // fact a method call, not a constant read.
      if (match_type_p(parser, YP_TOKEN_PARENTHESIS_LEFT)) {
        yp_token_t call_operator = not_provided(parser);

        yp_arguments_t arguments;
        parse_arguments_list(parser, &arguments);

        yp_node_t *node = yp_node_call_node_create(parser, NULL, &call_operator, &constant, &arguments.opening, arguments.arguments, &arguments.closing);
        yp_string_shared_init(&node->as.call_node.name, constant.start, constant.end);

        return node;
      } else {
        return yp_node_constant_read_create(parser, &parser->previous);
      }
    }
    case YP_TOKEN_COLON_COLON: {
      parser_lex(parser);

      yp_token_t delimiter = parser->previous;
      expect(parser, YP_TOKEN_CONSTANT, "Expected a constant after ::.");

      yp_node_t *constant = yp_node_constant_read_create(parser, &parser->previous);
      return yp_node_constant_path_node_create(parser, NULL, &delimiter, constant);
    }
    case YP_TOKEN_FLOAT:
      parser_lex(parser);
      return yp_float_node_create(parser, &parser->previous);
    case YP_TOKEN_GLOBAL_VARIABLE:
      parser_lex(parser);
      return yp_node_global_variable_read_create(parser, &parser->previous);
    case YP_TOKEN_IDENTIFIER:
      parser_lex(parser);
      return parse_identifier(parser);
    case YP_TOKEN_HEREDOC_START: {
      parser_lex(parser);
      yp_node_t *node = yp_node_heredoc_node_create(parser, &parser->previous, &parser->previous, 0);

      while (!match_any_type_p(parser, 2, YP_TOKEN_HEREDOC_END, YP_TOKEN_EOF)) {
        parser_lex(parser);

        yp_node_t *part;
        if ((part = parse_string_part(parser)) != NULL) {
          yp_node_list_append(parser, node, &node->as.heredoc_node.parts, part);
        }
      }

      expect(parser, YP_TOKEN_HEREDOC_END, "Expected a closing delimiter for heredoc.");
      node->as.heredoc_node.closing = parser->previous;

      return node;
    }
    case YP_TOKEN_IMAGINARY_NUMBER:
      parser_lex(parser);
      return yp_node_imaginary_literal_create(parser, &parser->previous);
    case YP_TOKEN_INSTANCE_VARIABLE:
      parser_lex(parser);
      return yp_node_instance_variable_read_create(parser, &parser->previous);
    case YP_TOKEN_INTEGER:
      parser_lex(parser);
      return yp_integer_node_create(parser, &parser->previous);
    case YP_TOKEN_KEYWORD___ENCODING__:
      parser_lex(parser);
      return yp_node_source_encoding_node_create(parser, &parser->previous);
    case YP_TOKEN_KEYWORD___FILE__:
      parser_lex(parser);
      return yp_node_source_file_node_create(parser, &parser->previous);
    case YP_TOKEN_KEYWORD___LINE__:
      parser_lex(parser);
      return yp_node_source_line_node_create(parser, &parser->previous);
    case YP_TOKEN_KEYWORD_ALIAS: {
      parser_lex(parser);
      yp_token_t keyword = parser->previous;

      yp_node_t *left = parse_alias_argument(parser, true);
      yp_node_t *right = parse_alias_argument(parser, false);

      switch (left->type) {
        case YP_NODE_SYMBOL_NODE:
        case YP_NODE_INTERPOLATED_SYMBOL_NODE: {
          if (right->type != YP_NODE_SYMBOL_NODE && right->type != YP_NODE_INTERPOLATED_SYMBOL_NODE) {
            yp_diagnostic_list_append(&parser->error_list, "Expected a bare word or symbol argument.", parser->previous.start - parser->start);
          }
          break;
        }
        case YP_NODE_GLOBAL_VARIABLE_READ: {
          if (right->type == YP_NODE_GLOBAL_VARIABLE_READ) {
            if (right->as.global_variable_read.name.type == YP_TOKEN_NTH_REFERENCE) {
              yp_diagnostic_list_append(&parser->error_list, "Can't make alias for number variables.", parser->previous.start - parser->start);
            }
          } else {
            yp_diagnostic_list_append(&parser->error_list, "Expected a global variable.", parser->previous.start - parser->start);
          }
          break;
        }
        default:
          break;
      }

      return yp_alias_node_create(parser, &keyword, left, right);
    }
    case YP_TOKEN_KEYWORD_BEGIN: {
      parser_lex(parser);

      yp_token_t begin_keyword = parser->previous;
      accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

      yp_node_t *begin_statements = parse_statements(parser, YP_CONTEXT_BEGIN);
      accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

      yp_node_t *begin_node = yp_begin_node_create(parser, &begin_keyword, begin_statements);
      yp_node_t *current = NULL;

      // Parse any number of rescue clauses. This will form a linked list of if
      // nodes pointing to each other from the top.
      while (accept(parser, YP_TOKEN_KEYWORD_RESCUE)) {
        yp_token_t rescue_keyword = parser->previous;

        yp_token_t exception_variable = not_provided(parser);
        yp_token_t equal_greater = not_provided(parser);
        yp_node_t *statements = yp_node_statements_create(parser);
        yp_node_t *rescue = yp_node_rescue_node_create(parser, &rescue_keyword, &equal_greater, &exception_variable, statements, NULL);

        while (match_type_p(parser, YP_TOKEN_CONSTANT)) {
          yp_node_t *expression = parse_expression(parser, BINDING_POWER_NONE, "Expected to find a class.");
          yp_node_list_append(parser, rescue, &rescue->as.rescue_node.exception_classes, expression);

          if (accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_EQUAL_GREATER)) break;
          expect(parser, YP_TOKEN_COMMA, "Expected an ',' to delimit exception classes.");
        }

        if (parser->previous.type == YP_TOKEN_EQUAL_GREATER) {
          rescue->as.rescue_node.equal_greater = parser->previous;

          expect(parser, YP_TOKEN_IDENTIFIER, "Expected variable name after `=>` in rescue statement");
          rescue->as.rescue_node.exception_variable = parser->previous;
        }

        accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

        rescue->as.rescue_node.statements = parse_statements(parser, YP_CONTEXT_RESCUE);
        accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

        if (current == NULL) {
          yp_begin_node_rescue_clause_set(begin_node, rescue);
        } else {
          current->as.rescue_node.consequent = rescue;
        }
        current = rescue;
      }

      if (accept(parser, YP_TOKEN_KEYWORD_ELSE)) {
        yp_token_t else_keyword = parser->previous;
        accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

        yp_node_t *else_statements = parse_statements(parser, YP_CONTEXT_RESCUE_ELSE);
        accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

        yp_node_t *else_clause = yp_node_else_node_create(parser, &else_keyword, else_statements, &parser->previous);
        yp_begin_node_else_clause_set(begin_node, else_clause);
      }

      if (accept(parser, YP_TOKEN_KEYWORD_ENSURE)) {
        yp_token_t ensure_keyword = parser->previous;
        accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

        yp_node_t *ensure_statements = parse_statements(parser, YP_CONTEXT_ENSURE);
        accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

        expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close `ensure` statement.");

        yp_node_t *ensure_clause = yp_node_ensure_node_create(
          parser,
          &ensure_keyword,
          ensure_statements,
          &parser->previous
        );

        yp_begin_node_ensure_clause_set(begin_node, ensure_clause);
      } else {
        expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close `begin` statement.");
        yp_begin_node_end_keyword_set(begin_node, &parser->previous);
      }

      return begin_node;
    }
    case YP_TOKEN_KEYWORD_BEGIN_UPCASE: {
      parser_lex(parser);

      yp_token_t keyword = parser->previous;
      expect(parser, YP_TOKEN_BRACE_LEFT, "Expected '{' after 'BEGIN'.");
      yp_token_t opening = parser->previous;

      yp_node_t *statements = parse_statements(parser, YP_CONTEXT_PREEXE);
      expect(parser, YP_TOKEN_BRACE_RIGHT, "Expected '}' after 'BEGIN' statements.");
      yp_token_t closing = parser->previous;

      return yp_node_pre_execution_node_create(parser, &keyword, &opening, statements, &closing);
    }
    case YP_TOKEN_KEYWORD_BREAK:
    case YP_TOKEN_KEYWORD_NEXT:
    case YP_TOKEN_KEYWORD_RETURN: {
      parser_lex(parser);

      yp_token_t keyword = parser->previous;
      yp_node_t *arguments = NULL;

      if (!accept_any(parser, 3, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON, YP_TOKEN_EOF)) {
        arguments = yp_arguments_node_create(parser);

        while (!match_type_p(parser, YP_TOKEN_EOF)) {
          yp_node_t *expression = parse_expression(parser, BINDING_POWER_NONE, "Expected to be able to parse an argument.");
          yp_arguments_node_append(arguments, expression);

          // If parsing the argument resulted in error recovery, then we can
          // stop parsing the arguments entirely now.
          if (expression->type == YP_NODE_MISSING_NODE || parser->recovering) break;
          if (accept_any(parser, 3, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON, YP_TOKEN_EOF)) break;

          expect(parser, YP_TOKEN_COMMA, "Expected an ',' to delimit arguments.");
          accept(parser, YP_TOKEN_NEWLINE);
        }
      }

      switch (keyword.type) {
        case YP_TOKEN_KEYWORD_BREAK:
          return yp_break_node_create(parser, &keyword, arguments);
        case YP_TOKEN_KEYWORD_NEXT:
          return yp_node_next_node_create(parser, &keyword, arguments);
        case YP_TOKEN_KEYWORD_RETURN:
          return yp_node_return_node_create(parser, &keyword, arguments);
        default:
          assert(false && "unreachable");
      }
    }
    case YP_TOKEN_KEYWORD_SUPER:
    case YP_TOKEN_KEYWORD_YIELD: {
      parser_lex(parser);

      yp_token_t keyword = parser->previous;
      yp_arguments_t arguments;
      parse_arguments_list(parser, &arguments);

      switch (keyword.type) {
        case YP_TOKEN_KEYWORD_SUPER:
          if (arguments.opening.type == YP_TOKEN_NOT_PROVIDED && arguments.arguments == NULL) {
            return yp_node_forwarding_super_node_create(parser, &keyword);
          } else {
            return yp_node_super_node_create(parser, &keyword, &arguments.opening, arguments.arguments, &arguments.closing);
          }
        case YP_TOKEN_KEYWORD_YIELD:
          return yp_node_yield_node_create(parser, &keyword, &arguments.opening, arguments.arguments, &arguments.closing);
        default:
          // Cannot hit here.
          return NULL;
      }
    }
    case YP_TOKEN_KEYWORD_CLASS: {
      parser_lex(parser);
      yp_token_t class_keyword = parser->previous;

      if (accept(parser, YP_TOKEN_LESS_LESS)) {
        yp_token_t operator = parser->previous;
        yp_node_t *expression = parse_expression(parser, BINDING_POWER_CALL, "Expected to find an expression after `<<`.");

        accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

        yp_node_t *scope = yp_node_scope_create(parser);
        yp_node_t *parent_scope = parser->current_scope;
        parser->current_scope = scope;

        yp_node_t *statements = parse_statements(parser, YP_CONTEXT_SCLASS);
        expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close `class` statement.");

        parser->current_scope = parent_scope;
        return yp_node_s_class_node_create(parser, scope, &class_keyword, &operator, expression, statements, &parser->previous);
      }

      yp_node_t *name = parse_expression(parser, BINDING_POWER_CALL, "Expected to find a class name after `class`.");
      yp_token_t inheritance_operator;
      yp_node_t *superclass;

      if (match_type_p(parser, YP_TOKEN_LESS)) {
        inheritance_operator = parser->current;
        lex_state_set(parser, YP_LEX_STATE_BEG);
        parser->command_start = true;
        parser_lex(parser);
        superclass = parse_expression(parser, BINDING_POWER_NONE, "Expected to find a superclass after `<`.");
      } else {
        inheritance_operator = not_provided(parser);
        superclass = NULL;
      }

      yp_node_t *scope = yp_node_scope_create(parser);
      yp_node_t *parent_scope = parser->current_scope;
      parser->current_scope = scope;

      yp_node_t *statements = parse_statements(parser, YP_CONTEXT_CLASS);
      expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close `class` statement.");

      parser->current_scope = parent_scope;
      return yp_node_class_node_create(parser, scope, &class_keyword, name, &inheritance_operator, superclass, statements, &parser->previous);
    }
    case YP_TOKEN_KEYWORD_DEF: {
      yp_token_t def_keyword = parser->current;

      yp_node_t *receiver = NULL;
      yp_token_t operator = not_provided(parser);
      yp_token_t name = not_provided(parser);

      parser_lex(parser);

      if (token_type_is_operator(parser->current.type)) {
        lex_state_set(parser, YP_LEX_STATE_ENDFN);
        parser_lex(parser);
        name = parser->previous;
      } else {
        switch (parser->current.type) {
          case YP_TOKEN_IDENTIFIER: {
            parser_lex(parser);
            receiver = parse_vcall(parser);

            if ((parser->current.type == YP_TOKEN_DOT) || (parser->current.type == YP_TOKEN_COLON_COLON)) {
              lex_state_set(parser, YP_LEX_STATE_FNAME);

              parser_lex(parser);
              operator = parser->previous;

              name = parse_method_definition_name(parser);
              if (name.type == YP_TOKEN_MISSING) {
                yp_diagnostic_list_append(&parser->error_list, "Expected a method name after receiver.", parser->previous.end - parser->start);
              }
            } else {
              yp_node_destroy(parser, receiver);
              receiver = NULL;
              name = parser->previous;
            }
            break;
          }
          case YP_TOKEN_CONSTANT:
          case YP_TOKEN_INSTANCE_VARIABLE:
          case YP_TOKEN_CLASS_VARIABLE:
          case YP_TOKEN_GLOBAL_VARIABLE:
          case YP_TOKEN_KEYWORD_NIL:
          case YP_TOKEN_KEYWORD_SELF:
          case YP_TOKEN_KEYWORD_TRUE:
          case YP_TOKEN_KEYWORD_FALSE:
          case YP_TOKEN_KEYWORD___FILE__:
          case YP_TOKEN_KEYWORD___LINE__:
          case YP_TOKEN_KEYWORD___ENCODING__: {
            parser_lex(parser);
            yp_token_t identifier = parser->previous;

            if ((parser->current.type == YP_TOKEN_DOT) || (parser->current.type == YP_TOKEN_COLON_COLON)) {
              lex_state_set(parser, YP_LEX_STATE_FNAME);

              parser_lex(parser);
              operator = parser->previous;

              switch (identifier.type) {
                case YP_TOKEN_CONSTANT:
                  receiver = yp_node_constant_read_create(parser, &identifier);
                  break;
                case YP_TOKEN_INSTANCE_VARIABLE:
                  receiver = yp_node_instance_variable_read_create(parser, &identifier);
                  break;
                case YP_TOKEN_CLASS_VARIABLE:
                  receiver = yp_node_class_variable_read_create(parser, &identifier);
                  break;
                case YP_TOKEN_GLOBAL_VARIABLE:
                  receiver = yp_node_global_variable_read_create(parser, &identifier);
                  break;
                case YP_TOKEN_KEYWORD_NIL:
                  receiver = yp_node_nil_node_create(parser, &identifier);
                  break;
                case YP_TOKEN_KEYWORD_SELF:
                  receiver = yp_self_node_create(parser, &identifier);
                  break;
                case YP_TOKEN_KEYWORD_TRUE:
                  receiver = yp_true_node_create(parser, &identifier);
                  break;
                case YP_TOKEN_KEYWORD_FALSE:
                  receiver = yp_false_node_create(parser, &identifier);
                  break;
                case YP_TOKEN_KEYWORD___FILE__:
                  receiver = yp_node_source_file_node_create(parser, &identifier);
                  break;
                case YP_TOKEN_KEYWORD___LINE__:
                  receiver = yp_node_source_line_node_create(parser, &identifier);
                  break;
                case YP_TOKEN_KEYWORD___ENCODING__:
                  receiver = yp_node_source_encoding_node_create(parser, &identifier);
                  break;
                default:
                  break;
              }

              name = parse_method_definition_name(parser);
              if (name.type == YP_TOKEN_MISSING) {
                yp_diagnostic_list_append(&parser->error_list, "Expected a method name after receiver.", parser->previous.end - parser->start);
              }
            } else {
              name = identifier;
            }
            break;
          }
          case YP_TOKEN_PARENTHESIS_LEFT: {
            parser_lex(parser);
            yp_token_t lparen = parser->previous;
            yp_node_t *expression = parse_expression(parser, BINDING_POWER_NONE, "Expected to be able to parse receiver.");

            expect(parser, YP_TOKEN_PARENTHESIS_RIGHT, "Expected closing ')' for receiver.");
            yp_token_t rparen = parser->previous;

            lex_state_set(parser, YP_LEX_STATE_FNAME);
            expect_any(parser, "Expected '.' or '::' after receiver", 2, YP_TOKEN_DOT, YP_TOKEN_COLON_COLON);
            operator = parser->previous;

            receiver = yp_node_parentheses_node_create(parser, &lparen, expression, &rparen);

            expect(parser, YP_TOKEN_IDENTIFIER, "Expected a method name after receiver.");
            name = parser->previous;
            break;
          }
          default:
            name = parse_method_definition_name(parser);
            if (name.type == YP_TOKEN_MISSING) {
              yp_diagnostic_list_append(&parser->error_list, "Expected a method name after receiver.", parser->previous.end - parser->start);
            }
            break;
        }
      }

      yp_token_t lparen;
      yp_token_t rparen;

      if (accept(parser, YP_TOKEN_PARENTHESIS_LEFT)) {
        lparen = parser->previous;
      } else {
        lparen = not_provided(parser);
      }

      yp_node_t *parent_scope = parser->current_scope;
      yp_node_t *scope = yp_node_scope_create(parser);
      parser->current_scope = scope;
      yp_node_t *params = parse_parameters(parser, lparen.type == YP_TOKEN_PARENTHESIS_LEFT);

      if (lparen.type == YP_TOKEN_PARENTHESIS_LEFT) {
        expect(parser, YP_TOKEN_PARENTHESIS_RIGHT, "Expected ')' after left parenthesis.");
        rparen = parser->previous;
      } else {
        rparen = not_provided(parser);
      }

      yp_token_t equal;
      bool endless_definition = accept(parser, YP_TOKEN_EQUAL);

      if (endless_definition) {
        equal = parser->previous;
      } else {
        equal = not_provided(parser);
        accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);
      }

      yp_node_t *statements = parse_statements(parser, YP_CONTEXT_DEF);
      yp_token_t end_keyword;

      if (endless_definition) {
        end_keyword = not_provided(parser);
      } else {
        expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close `def` statement.");
        end_keyword = parser->previous;
      }

      parser->current_scope = parent_scope;
      return yp_node_def_node_create(parser, &def_keyword, receiver, &operator, &name, &lparen, params, &rparen, &equal, statements, &end_keyword, scope);
    }
    case YP_TOKEN_KEYWORD_DEFINED: {
      parser_lex(parser);
      yp_token_t keyword = parser->previous;
      yp_token_t lparen;

      if (accept(parser, YP_TOKEN_PARENTHESIS_LEFT)) {
        lparen = parser->previous;
      } else {
        lparen = not_provided(parser);
      }

      yp_node_t *expression = parse_expression(parser, BINDING_POWER_DEFINED, "Expected expression after `defined?`.");
      yp_token_t rparen;

      if (!parser->recovering && lparen.type == YP_TOKEN_PARENTHESIS_LEFT) {
        expect(parser, YP_TOKEN_PARENTHESIS_RIGHT, "Expected ')' after 'defined?' expression.");
        rparen = parser->previous;
      } else {
        rparen = not_provided(parser);
      }

      return yp_node_defined_node_create(
        parser,
        &lparen,
        expression,
        &rparen,
        &(yp_location_t) { .start = keyword.start, .end = keyword.end }
      );
    }
    case YP_TOKEN_KEYWORD_END_UPCASE: {
      parser_lex(parser);

      yp_token_t keyword = parser->previous;
      expect(parser, YP_TOKEN_BRACE_LEFT, "Expected '{' after 'END'.");
      yp_token_t opening = parser->previous;

      yp_node_t *statements = parse_statements(parser, YP_CONTEXT_POSTEXE);
      expect(parser, YP_TOKEN_BRACE_RIGHT, "Expected '}' after 'END' statements.");
      yp_token_t closing = parser->previous;

      return yp_node_post_execution_node_create(parser, &keyword, &opening, statements, &closing);
    }
    case YP_TOKEN_KEYWORD_FALSE:
      parser_lex(parser);
      return yp_false_node_create(parser, &parser->previous);
    case YP_TOKEN_KEYWORD_FOR: {
      parser_lex(parser);
      yp_token_t for_keyword = parser->previous;
      yp_node_t *index = parse_targets(parser, BINDING_POWER_INDEX, "Expected index after for.");

      expect(parser, YP_TOKEN_KEYWORD_IN, "Expected keyword in.");
      yp_token_t in_keyword = parser->previous;

      yp_state_stack_push(&parser->do_loop_stack, true);
      yp_node_t *collection = parse_expression(parser, BINDING_POWER_COMPOSITION, "Expected collection.");
      yp_state_stack_pop(&parser->do_loop_stack);

      yp_token_t do_keyword;
      if (accept(parser, YP_TOKEN_KEYWORD_DO_LOOP)) {
        do_keyword = parser->previous;
      } else {
        do_keyword = not_provided(parser);
      }

      yp_node_t *scope = yp_node_scope_create(parser);
      yp_node_t *parent_scope = parser->current_scope;
      parser->current_scope = scope;

      accept_any(parser, 2, YP_TOKEN_SEMICOLON, YP_TOKEN_NEWLINE);
      yp_node_t *statements = parse_statements(parser, YP_CONTEXT_FOR);
      parser->current_scope = parent_scope;

      expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close for loop.");
      yp_token_t end_keyword = parser->previous;

      return yp_node_for_node_create(parser, &for_keyword, index, &in_keyword, collection, &do_keyword, statements, &end_keyword);
    }
    case YP_TOKEN_KEYWORD_IF:
      parser_lex(parser);
      return parse_conditional(parser, YP_CONTEXT_IF);
    case YP_TOKEN_KEYWORD_UNDEF: {
      parser_lex(parser);
      yp_token_t keyword = parser->previous;
      yp_node_t *undef = yp_node_undef_node_create(parser, &keyword);

      yp_node_t *name = parse_undef_argument(parser);
      if (name->type == YP_NODE_MISSING_NODE) return undef;

      yp_node_list_append(parser, undef, &undef->as.undef_node.names, name);

      while (accept(parser, YP_TOKEN_COMMA)) {
        name = parse_undef_argument(parser);
        if (name->type == YP_NODE_MISSING_NODE) return undef;

        yp_node_list_append(parser, undef, &undef->as.undef_node.names, name);
      }

      return undef;
    }
    case YP_TOKEN_KEYWORD_NOT: {
      parser_lex(parser);
      yp_token_t operator_token = parser->previous;

      yp_token_t lparen;
      if (accept(parser, YP_TOKEN_PARENTHESIS_LEFT)) {
        lparen = parser->previous;
      } else {
        lparen = not_provided(parser);
      }

      yp_node_t *receiver = parse_expression(parser, BINDING_POWER_DEFINED, "Expected expression after `not`.");

      yp_token_t rparen;
      if (!parser->recovering && lparen.type == YP_TOKEN_PARENTHESIS_LEFT) {
        expect(parser, YP_TOKEN_PARENTHESIS_RIGHT, "Expected ')' after 'not' expression.");
        rparen = parser->previous;
      } else {
        rparen = not_provided(parser);
      }

      yp_token_t call_operator = not_provided(parser);
      yp_node_t *node = yp_node_call_node_create(parser, receiver, &call_operator, &operator_token, &lparen, NULL, &rparen);
      yp_string_constant_init(&node->as.call_node.name, "!", 1);

      return node;
    }
    case YP_TOKEN_KEYWORD_UNLESS:
      parser_lex(parser);
      return parse_conditional(parser, YP_CONTEXT_UNLESS);
    case YP_TOKEN_KEYWORD_MODULE: {
      parser_lex(parser);

      yp_token_t module_keyword = parser->previous;
      yp_node_t *name = parse_expression(parser, BINDING_POWER_NONE, "Expected to find a module name after `module`.");

      // If we can recover from a syntax error that occurred while parsing the
      // name of the module, then we'll handle that here.
      if (parser->recovering) {
        yp_node_t *scope = yp_node_scope_create(parser);
        yp_node_t *statements = yp_node_statements_create(parser);
        yp_token_t end_keyword = (yp_token_t) { .type = YP_TOKEN_MISSING, .start = parser->previous.end, .end = parser->previous.end };
        return yp_node_module_node_create(parser, scope, &module_keyword, name, statements, &end_keyword);
      }

      yp_node_t *scope = yp_node_scope_create(parser);
      yp_node_t *parent_scope = parser->current_scope;
      parser->current_scope = scope;

      yp_node_t *statements = parse_statements(parser, YP_CONTEXT_MODULE);
      parser->current_scope = parent_scope;

      expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close `module` statement.");
      return yp_node_module_node_create(parser, scope, &module_keyword, name, statements, &parser->previous);
    }
    case YP_TOKEN_KEYWORD_NIL:
      parser_lex(parser);
      return yp_node_nil_node_create(parser, &parser->previous);
    case YP_TOKEN_KEYWORD_REDO:
      parser_lex(parser);
      return yp_redo_node_create(parser, &parser->previous);
    case YP_TOKEN_KEYWORD_RETRY:
      parser_lex(parser);
      return yp_node_retry_node_create(parser, &parser->previous);
    case YP_TOKEN_KEYWORD_SELF:
      parser_lex(parser);
      return yp_self_node_create(parser, &parser->previous);
    case YP_TOKEN_KEYWORD_TRUE:
      parser_lex(parser);
      return yp_true_node_create(parser, &parser->previous);
    case YP_TOKEN_KEYWORD_UNTIL: {
      parser_lex(parser);

      yp_token_t keyword = parser->previous;
      yp_state_stack_push(&parser->do_loop_stack, true);

      yp_node_t *predicate = parse_expression(parser, BINDING_POWER_NONE, "Expected predicate expression after `until`.");
      yp_state_stack_pop(&parser->do_loop_stack);

      accept_any(parser, 3, YP_TOKEN_KEYWORD_DO_LOOP, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

      yp_node_t *statements = parse_statements(parser, YP_CONTEXT_UNTIL);
      accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

      expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close `until` statement.");
      return yp_node_until_node_create(parser, &keyword, predicate, statements);
    }
    case YP_TOKEN_KEYWORD_WHILE: {
      parser_lex(parser);

      yp_token_t keyword = parser->previous;
      yp_state_stack_push(&parser->do_loop_stack, true);

      yp_node_t *predicate = parse_expression(parser, BINDING_POWER_NONE, "Expected predicate expression after `while`.");
      yp_state_stack_pop(&parser->do_loop_stack);

      accept_any(parser, 3, YP_TOKEN_KEYWORD_DO_LOOP, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

      yp_node_t *statements = parse_statements(parser, YP_CONTEXT_WHILE);
      accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

      expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close `while` statement.");
      return yp_node_while_node_create(parser, &keyword, predicate, statements);
    }
    case YP_TOKEN_PERCENT_LOWER_I: {
      parser_lex(parser);
      yp_token_t opening = parser->previous;
      yp_node_t *array = yp_array_node_create(parser, &opening, &opening);

      while (!match_any_type_p(parser, 2, YP_TOKEN_STRING_END, YP_TOKEN_EOF)) {
        if (yp_array_node_size(array) == 0) {
          accept(parser, YP_TOKEN_WORDS_SEP);
        } else {
          expect(parser, YP_TOKEN_WORDS_SEP, "Expected a separator for the symbols in a `%i` list.");
        }
        expect(parser, YP_TOKEN_STRING_CONTENT, "Expected a symbol in a `%i` list.");

        yp_token_t opening = not_provided(parser);
        yp_token_t closing = not_provided(parser);

        yp_node_t *symbol = yp_node_symbol_node_create(parser, &opening, &parser->previous, &closing);
        yp_array_node_append(array, symbol);
      }

      expect(parser, YP_TOKEN_STRING_END, "Expected a closing delimiter for a `%i` list.");
      yp_array_node_close_set(array, &parser->previous);

      return array;
    }
    case YP_TOKEN_PERCENT_UPPER_I: {
      parser_lex(parser);
      yp_token_t opening = parser->previous;
      yp_node_t *array = yp_array_node_create(parser, &opening, &opening);

      while (!match_any_type_p(parser, 2, YP_TOKEN_STRING_END, YP_TOKEN_EOF)) {
        if (yp_array_node_size(array) == 0) {
          accept(parser, YP_TOKEN_WORDS_SEP);
        } else {
          expect(parser, YP_TOKEN_WORDS_SEP, "Expected a separator for the symbols in a `%I` list.");
        }

        yp_token_t dynamic_symbol_opening = not_provided(parser);
        yp_node_t *interpolated = yp_node_interpolated_symbol_node_create(parser, &dynamic_symbol_opening, &dynamic_symbol_opening);

        while (!match_any_type_p(parser, 3, YP_TOKEN_WORDS_SEP, YP_TOKEN_STRING_END, YP_TOKEN_EOF)) {
          switch (parser->current.type) {
            case YP_TOKEN_STRING_CONTENT: {
              parser_lex(parser);

              yp_token_t string_content_opening = not_provided(parser);
              yp_token_t string_content_closing = not_provided(parser);
              yp_node_t *symbol_node = yp_node_symbol_node_create(parser, &string_content_opening, &parser->previous, &string_content_closing);

              if (match_type_p(parser, YP_TOKEN_EMBEXPR_BEGIN) || interpolated->as.interpolated_symbol_node.parts.size > 0) {
                yp_node_list_append(parser, interpolated, &interpolated->as.interpolated_symbol_node.parts, symbol_node);
              } else {
                yp_array_node_append(array, symbol_node);
              }

              break;
            }
            case YP_TOKEN_EMBEXPR_BEGIN: {
              parser_lex(parser);
              yp_token_t embexpr_opening = parser->previous;
              yp_node_t *statements = parse_statements(parser, YP_CONTEXT_EMBEXPR);
              expect(parser, YP_TOKEN_EMBEXPR_END, "Expected a closing delimiter for an embedded expression.");
              yp_node_list_append(parser, interpolated, &interpolated->as.interpolated_symbol_node.parts, yp_node_string_interpolated_node_create(parser, &embexpr_opening, statements, &parser->previous));
              break;
            }
            default:
              fprintf(stderr, "Could not understand token type %s in an interpolated symbol list\n", yp_token_type_to_str(parser->previous.type));
              return NULL;
            }
        }

        if (interpolated->as.interpolated_symbol_node.parts.size > 0) {
          yp_array_node_append(array, interpolated);
        } else {
          yp_node_destroy(parser, interpolated);
        }
      }

      expect(parser, YP_TOKEN_STRING_END, "Expected a closing delimiter for a `%I` list.");
      yp_array_node_close_set(array, &parser->previous);

      return array;
    }
    case YP_TOKEN_PERCENT_LOWER_W: {
      parser_lex(parser);
      yp_token_t opening = parser->previous;
      yp_node_t *array = yp_array_node_create(parser, &opening, &opening);

      while (!match_any_type_p(parser, 2, YP_TOKEN_STRING_END, YP_TOKEN_EOF)) {
        if (yp_array_node_size(array) == 0) {
          accept(parser, YP_TOKEN_WORDS_SEP);
        } else {
          expect(parser, YP_TOKEN_WORDS_SEP, "Expected a separator for the strings in a `%w` list.");
        }
        expect(parser, YP_TOKEN_STRING_CONTENT, "Expected a string in a `%w` list.");

        yp_token_t opening = not_provided(parser);
        yp_token_t closing = not_provided(parser);
        yp_node_t *string = yp_node_string_node_create_and_unescape(parser, &opening, &parser->previous, &closing, YP_UNESCAPE_NONE);
        yp_array_node_append(array, string);
      }

      expect(parser, YP_TOKEN_STRING_END, "Expected a closing delimiter for a `%w` list.");
      yp_array_node_close_set(array, &parser->previous);

      return array;
    }
    case YP_TOKEN_PERCENT_UPPER_W: {
      parser_lex(parser);
      yp_token_t opening = parser->previous;
      yp_node_t *array = yp_array_node_create(parser, &opening, &opening);
      yp_node_t *current = NULL;

      while (!match_any_type_p(parser, 2, YP_TOKEN_STRING_END, YP_TOKEN_EOF)) {
        switch (parser->current.type) {
          case YP_TOKEN_WORDS_SEP: {
            if (current == NULL) {
              // If we hit a separator before we have any content, then we don't
              // need to do anything.
            } else {
              // If we hit a separator after we've hit content, then we need to
              // append that content to the list and reset the current node.
              yp_array_node_append(array, current);
              current = NULL;
            }

            parser_lex(parser);
            break;
          }
          case YP_TOKEN_STRING_CONTENT: {
            parser_lex(parser);

            if (current == NULL) {
              // If we hit content and the current node is NULL, then this is
              // the first string content we've seen. In that case we're going
              // to create a new string node and set that to the current.
              yp_token_t opening = not_provided(parser);
              yp_token_t closing = not_provided(parser);
              current = yp_node_string_node_create_and_unescape(parser, &opening, &parser->previous, &closing, YP_UNESCAPE_ALL);
            } else if (current->type == YP_NODE_INTERPOLATED_STRING_NODE) {
              // If we hit string content and the current node is an
              // interpolated string, then we need to append the string content
              // to the list of child nodes.
              yp_token_t opening = not_provided(parser);
              yp_token_t closing = not_provided(parser);
              yp_node_t *next_string = yp_node_string_node_create_and_unescape(parser, &opening, &parser->previous, &closing, YP_UNESCAPE_ALL);
              yp_node_list_append(parser, current, &current->as.interpolated_string_node.parts, next_string);
            }

            break;
          }
          case YP_TOKEN_EMBEXPR_BEGIN: {
            parser_lex(parser);

            if (current == NULL) {
              // If we hit an embedded expression and the current node is NULL,
              // then this is the start of a new string. We'll set the current
              // node to a new interpolated string.
              yp_token_t opening = not_provided(parser);
              yp_token_t closing = not_provided(parser);
              current = yp_node_interpolated_string_node_create(parser, &opening, &closing);
            } else if (current->type == YP_NODE_STRING_NODE) {
              // If we hit an embedded expression and the current node is a
              // string node, then we'll convert the current into an
              // interpolated string and add the string node to the list of
              // parts.
              yp_token_t opening = not_provided(parser);
              yp_token_t closing = not_provided(parser);
              yp_node_t *interpolated = yp_node_interpolated_string_node_create(parser, &opening, &closing);
              yp_node_list_append(parser, interpolated, &interpolated->as.interpolated_string_node.parts, current);
              current = interpolated;
            } else if (current->type == YP_NODE_INTERPOLATED_STRING_NODE) {
              // If we hit an embedded expression and the current node is an
              // interpolated string, then we'll just continue on.
            }

            yp_token_t embexpr_opening = parser->previous;
            yp_node_t *statements = parse_statements(parser, YP_CONTEXT_EMBEXPR);
            expect(parser, YP_TOKEN_EMBEXPR_END, "Expected a closing delimiter for an embedded expression.");

            yp_token_t embexpr_closing = parser->previous;
            yp_node_t *interpolated = yp_node_string_interpolated_node_create(parser, &embexpr_opening, statements, &embexpr_closing);
            yp_node_list_append(parser, current, &current->as.interpolated_string_node.parts, interpolated);
            break;
          }
          default:
            expect(parser, YP_TOKEN_STRING_CONTENT, "Expected a string in a `%W` list.");
            parser_lex(parser);
            break;
        }
      }

      // If we have a current node, then we need to append it to the list.
      if (current) {
        yp_array_node_append(array, current);
      }

      expect(parser, YP_TOKEN_STRING_END, "Expected a closing delimiter for a `%W` list.");
      yp_array_node_close_set(array, &parser->previous);

      return array;
    }
    case YP_TOKEN_RATIONAL_NUMBER:
      parser_lex(parser);
      return yp_rational_node_create(parser, &parser->previous);
    case YP_TOKEN_REGEXP_BEGIN: {
      parser_lex(parser);

      yp_token_t opening = parser->previous;
      yp_token_t content;
      if (parse_string_without_interpolation(parser, YP_TOKEN_REGEXP_END, &content)) {
        return yp_node_regular_expression_node_create(parser, &opening, &content, &parser->previous);
      }

      yp_node_t *node = yp_node_interpolated_regular_expression_node_create(parser, &opening, &opening);
      yp_node_list_t *parts = &node->as.interpolated_regular_expression_node.parts;

      parse_interpolated_string_parts(parser, YP_TOKEN_REGEXP_END, node, parts);
      expect(parser, YP_TOKEN_REGEXP_END, "Expected a closing delimiter for a regular expression.");

      node->as.interpolated_regular_expression_node.closing = parser->previous;
      return node;
    }
    case YP_TOKEN_BACKTICK:
    case YP_TOKEN_PERCENT_LOWER_X: {
      parser_lex(parser);

      yp_token_t opening = parser->previous;
      yp_token_t content;
      if (parse_string_without_interpolation(parser, YP_TOKEN_STRING_END, &content)) {
        return yp_node_x_string_node_create(parser, &opening, &content, &parser->previous);
      }

      yp_node_t *node = yp_node_interpolated_x_string_node_create(parser, &opening, &opening);
      yp_node_list_t *parts = &node->as.interpolated_x_string_node.parts;
      parse_interpolated_string_parts(parser, YP_TOKEN_STRING_END, node, parts);
      expect(parser, YP_TOKEN_STRING_END, "Expected a closing delimiter for an xstring.");
      node->as.interpolated_x_string_node.closing = parser->previous;
      return node;
    }
    case YP_TOKEN_BANG:
    case YP_TOKEN_TILDE: {
      parser_lex(parser);
      yp_token_t operator_token = parser->previous;

      yp_token_t lparen = not_provided(parser);
      yp_token_t rparen = not_provided(parser);
      yp_token_t call_operator = not_provided(parser);
      yp_node_t *receiver = parse_expression(parser, binding_powers[parser->previous.type].right, "Expected a receiver after unary operator.");

      yp_node_t *node = yp_node_call_node_create(parser, receiver, &call_operator, &operator_token, &lparen, NULL, &rparen);
      yp_string_shared_init(&node->as.call_node.name, operator_token.start, operator_token.end);
      return node;
    }
    case YP_TOKEN_MINUS: {
      parser_lex(parser);
      yp_token_t operator_token = parser->previous;

      yp_token_t lparen = not_provided(parser);
      yp_token_t rparen = not_provided(parser);
      yp_token_t call_operator = not_provided(parser);
      yp_node_t *receiver = parse_expression(parser, binding_powers[parser->previous.type].right, "Expected a receiver after unary -.");

      yp_node_t *node = yp_node_call_node_create(parser, receiver, &call_operator, &operator_token, &lparen, NULL, &rparen);
      yp_string_constant_init(&node->as.call_node.name, "-@", 2);
      return node;
    }
    case YP_TOKEN_PLUS: {
      parser_lex(parser);
      yp_token_t operator_token = parser->previous;

      yp_token_t lparen = not_provided(parser);
      yp_token_t rparen = not_provided(parser);
      yp_token_t call_operator = not_provided(parser);
      yp_node_t *receiver = parse_expression(parser, binding_powers[parser->previous.type].right, "Expected a receiver after unary +.");

      yp_node_t *node = yp_node_call_node_create(parser, receiver, &call_operator, &operator_token, &lparen, NULL, &rparen);
      yp_string_constant_init(&node->as.call_node.name, "+@", 2);
      return node;
    }
    case YP_TOKEN_STRING_BEGIN: {
      parser_lex(parser);
      yp_token_t opening = parser->previous;
      yp_node_t *node;
      yp_token_t content;

      if (!lex_mode.as.string.interpolation) {
        if (accept(parser, YP_TOKEN_STRING_CONTENT)) {
          content = parser->previous;
        } else {
          content = (yp_token_t) { .type = YP_TOKEN_STRING_CONTENT, .start = parser->previous.end, .end = parser->previous.end };
        }

        expect(parser, YP_TOKEN_STRING_END, "Expected a closing delimiter for a string literal.");
        node = yp_node_string_node_create_and_unescape(parser, &opening, &content, &parser->previous, YP_UNESCAPE_MINIMAL);
      } else if (parse_string_without_interpolation(parser, YP_TOKEN_STRING_END, &content)) {
        node = yp_node_string_node_create_and_unescape(parser, &opening, &content, &parser->previous, YP_UNESCAPE_ALL);
      } else {
        node = yp_node_interpolated_string_node_create(parser, &opening, &opening);

        yp_node_list_t *parts = &node->as.interpolated_string_node.parts;
        parse_interpolated_string_parts(parser, YP_TOKEN_STRING_END, node, parts);

        expect(parser, YP_TOKEN_STRING_END, "Expected a closing delimiter for an interpolated string.");
        node->as.interpolated_string_node.closing = parser->previous;
      }

      // If there's a string immediately following this string, then it's a
      // concatenatation. In this case we'll parse the next string and create a
      // node in the tree that concatenates the two strings.
      if (parser->current.type == YP_TOKEN_STRING_BEGIN) {
        return yp_node_string_concat_node_create(
          parser,
          node,
          parse_expression(parser, BINDING_POWER_CALL, "Expected string on the right side of concatenation.")
        );
      } else {
        return node;
      }
    }
    case YP_TOKEN_SYMBOL_BEGIN:
      parser_lex(parser);
      return parse_symbol(parser, lex_mode.mode, YP_LEX_STATE_NONE);
    default:
      if (context_recoverable(parser, &parser->current)) {
        parser->recovering = true;
      }

      return yp_node_missing_node_create(parser, &(yp_location_t) {
        .start = parser->previous.start,
        .end = parser->previous.end,
      });
  }
}

static inline yp_node_t *
parse_expression_infix(yp_parser_t *parser, yp_node_t *node, binding_power_t binding_power) {
  yp_token_t token = parser->previous;

  switch (token.type) {
    case YP_TOKEN_EQUAL: {
      switch (node->type) {
        case YP_NODE_CLASS_VARIABLE_READ: {
          yp_node_t *value = parse_expression(parser, binding_power, "Expected a value for the class variable after =.");
          yp_node_t *read = node;

          yp_node_t *result = yp_node_class_variable_write_create(parser, &node->as.class_variable_read.name, &token, value);
          yp_node_destroy(parser, read);
          return result;
        }
        case YP_NODE_CONSTANT_PATH_NODE:
        case YP_NODE_CONSTANT_READ: {
          yp_node_t *value = parse_expression(parser, binding_power, "Expected a value for the constant after =.");
          return yp_node_constant_path_write_node_create(parser, node, &token, value);
        }
        case YP_NODE_GLOBAL_VARIABLE_READ: {
          yp_node_t *value = parse_expression(parser, binding_power, "Expected a value for the global variable after =.");
          yp_node_t *read = node;

          yp_node_t *result = yp_node_global_variable_write_create(parser, &node->as.global_variable_read.name, &token, value);
          yp_node_destroy(parser, read);
          return result;
        }
        case YP_NODE_LOCAL_VARIABLE_READ: {
          yp_node_t *value = parse_expression(parser, binding_power, "Expected a value for the local variable after =.");
          yp_node_t *read = node;

          yp_token_t name = node->as.local_variable_read.name;
          yp_token_list_append(&parser->current_scope->as.scope.locals, &name);
          yp_node_t *result = yp_node_local_variable_write_create(parser, &name, &token, value);
          yp_node_destroy(parser, read);
          return result;
        }
        case YP_NODE_INSTANCE_VARIABLE_READ: {
          yp_node_t *value = parse_expression(parser, binding_power, "Expected a value for the instance variable after =.");
          yp_node_t *read = node;

          yp_node_t *result = yp_node_instance_variable_write_create(parser, &node->as.instance_variable_read.name, &token, value);
          yp_node_destroy(parser, read);
          return result;
        }
        case YP_NODE_CALL_NODE: {
          if (node->as.call_node.lparen.type == YP_TOKEN_NOT_PROVIDED && node->as.call_node.arguments == NULL) {
            // If we have no arguments to the call node and we have an equals
            // sign then this is either a method call or a local variable write.
            if (node->as.call_node.receiver == NULL) {
              // When we get here, we have a local varaible write, because it
              // was previously marked as a method call but now we have an =.
              // This looks like:
              //
              //     foo = 1
              //
              // When it was parsed in the prefix position, foo was seen as a
              // method call with no receiver and no arguments. Now we have an
              // =, so we know it's a local variable write.
              yp_node_t *value = parse_expression(parser, binding_power, "Expected a value for the local variable after =.");
              yp_node_t *read = node;

              yp_token_t name = node->as.call_node.message;
              yp_token_list_append(&parser->current_scope->as.scope.locals, &name);

              yp_node_t *result = yp_node_local_variable_write_create(parser, &name, &token, value);
              yp_node_destroy(parser, read);
              return result;
            }

            // When we get here, we have a method call, because it was
            // previously marked as a method call but now we have an =. This
            // looks like:
            //
            //     foo.bar = 1
            //
            // When it was parsed in the prefix position, foo.bar was seen as a
            // method call with no arguments. Now we have an =, so we know it's
            // a method call with an argument.
            yp_token_t lparen = not_provided(parser);
            yp_token_t rparen = not_provided(parser);

            yp_node_t *value = parse_expression(parser, binding_power, "Expected a value for the call after =.");
            yp_node_t *arguments = yp_arguments_node_create(parser);
            yp_arguments_node_append(arguments, value);

            yp_node_t *next_node = yp_node_call_node_create(
              parser,
              node->as.call_node.receiver,
              &node->as.call_node.call_operator,
              &token,
              &lparen,
              arguments,
              &rparen
            );

            int length = node->as.call_node.message.end - node->as.call_node.message.start;
            yp_string_t *name = &next_node->as.call_node.name;
            yp_string_owned_init(name, malloc(length + 1), length + 1);
            sprintf(name->as.owned.source, "%.*s=", length, node->as.call_node.message.start);

            return next_node;
          }

          // If there are arguments on the call node, then it can't be a method
          // call ending with = or a local variable write, so it must be a
          // syntax error. In this case we'll fall through to our default
          // handling.
        }
        default:
          // In this case we have an = sign, but we don't know what it's for. We
          // need to treat it as an error. For now, we'll mark it as an error
          // and just skip right past it.
          yp_diagnostic_list_append(&parser->error_list, "Unexpected `='.", parser->previous.start - parser->start);
          return node;
      }
    }
    case YP_TOKEN_AMPERSAND_AMPERSAND_EQUAL: {
      yp_node_t *value = parse_expression(parser, binding_power, "Expected a value after &&=");
      return yp_node_operator_and_assignment_node_create(parser, node, &token, value);
    }
    case YP_TOKEN_PIPE_PIPE_EQUAL: {
      yp_node_t *value = parse_expression(parser, binding_power, "Expected a value after ||=");
      return yp_node_operator_or_assignment_node_create(parser, node, &token, value);
    }
    case YP_TOKEN_AMPERSAND_EQUAL:
    case YP_TOKEN_CARET_EQUAL:
    case YP_TOKEN_GREATER_GREATER_EQUAL:
    case YP_TOKEN_LESS_LESS_EQUAL:
    case YP_TOKEN_MINUS_EQUAL:
    case YP_TOKEN_PERCENT_EQUAL:
    case YP_TOKEN_PIPE_EQUAL:
    case YP_TOKEN_PLUS_EQUAL:
    case YP_TOKEN_SLASH_EQUAL:
    case YP_TOKEN_STAR_EQUAL:
    case YP_TOKEN_STAR_STAR_EQUAL: {
      yp_node_t *value = parse_expression(parser, binding_power, "Expected a value after the operator.");
      return yp_node_operator_assignment_node_create(parser, node, &token, value);
    }
    case YP_TOKEN_AMPERSAND_AMPERSAND:
    case YP_TOKEN_KEYWORD_AND: {
      yp_node_t *right = parse_expression(parser, binding_power, "Expected a value after the operator.");
      return yp_and_node_create(parser, node, &token, right);
    }
    case YP_TOKEN_KEYWORD_OR:
    case YP_TOKEN_PIPE_PIPE: {
      yp_node_t *right = parse_expression(parser, binding_power, "Expected a value after the operator.");
      return yp_node_or_node_create(parser, node, &token, right);
    }
    case YP_TOKEN_EQUAL_TILDE: {
      // If the receiver of this =~ is a regular expression node, then we need
      // to introduce local variables for it based on its named capture groups.
      if (node->type == YP_NODE_REGULAR_EXPRESSION_NODE) {
        yp_string_list_t named_captures;
        yp_string_list_init(&named_captures);

        yp_token_t *content = &node->as.regular_expression_node.content;
        assert(yp_regexp_named_capture_group_names(content->start, content->end - content->start, &named_captures));

        yp_token_list_t *locals = &parser->current_scope->as.scope.locals;
        for (size_t index = 0; index < named_captures.length; index++) {
          yp_string_t *name = &named_captures.strings[index];
          assert(name->type == YP_STRING_SHARED);

          yp_token_list_append(locals, &(yp_token_t) {
            .type = YP_TOKEN_IDENTIFIER,
            .start = name->as.shared.start,
            .end = name->as.shared.end
          });
        }

        yp_string_list_free(&named_captures);
      }

      // Here we're going to fall through to our other operators because this
      // will become a call node.
    }
    case YP_TOKEN_BANG_EQUAL:
    case YP_TOKEN_BANG_TILDE:
    case YP_TOKEN_EQUAL_EQUAL:
    case YP_TOKEN_EQUAL_EQUAL_EQUAL:
    case YP_TOKEN_LESS_EQUAL_GREATER:
    case YP_TOKEN_GREATER:
    case YP_TOKEN_GREATER_EQUAL:
    case YP_TOKEN_LESS:
    case YP_TOKEN_LESS_EQUAL:
    case YP_TOKEN_CARET:
    case YP_TOKEN_PIPE:
    case YP_TOKEN_AMPERSAND:
    case YP_TOKEN_GREATER_GREATER:
    case YP_TOKEN_LESS_LESS:
    case YP_TOKEN_MINUS:
    case YP_TOKEN_PLUS:
    case YP_TOKEN_PERCENT:
    case YP_TOKEN_SLASH:
    case YP_TOKEN_STAR:
    case YP_TOKEN_STAR_STAR: {
      while (accept(parser, YP_TOKEN_NEWLINE));

      yp_token_t call_operator = not_provided(parser);
      yp_token_t lparen = not_provided(parser);
      yp_token_t rparen = not_provided(parser);
      yp_node_t *arguments = yp_arguments_node_create(parser);

      yp_node_t *argument = parse_expression(parser, binding_power, "Expected a value after the operator.");
      yp_arguments_node_append(arguments, argument);

      yp_node_t *next_node = yp_node_call_node_create(parser, node, &call_operator, &token, &lparen, arguments, &rparen);
      yp_string_shared_init(&next_node->as.call_node.name, token.start, token.end);
      return next_node;
    }
    case YP_TOKEN_AMPERSAND_DOT:
    case YP_TOKEN_DOT: {
      yp_token_t call_operator = parser->previous;

      // This if statement handles the foo.() syntax.
      if (accept(parser, YP_TOKEN_PARENTHESIS_LEFT)) {
        yp_token_t lparen = parser->previous;
        yp_token_t rparen;
        yp_token_t message = not_provided(parser);

        yp_node_t *arguments;
        if (accept(parser, YP_TOKEN_PARENTHESIS_RIGHT)) {
          rparen = parser->previous;
          arguments = NULL;
        } else {
          arguments = yp_arguments_node_create(parser);
          parse_arguments(parser, arguments, YP_TOKEN_PARENTHESIS_RIGHT);
          expect(parser, YP_TOKEN_PARENTHESIS_RIGHT, "Expected ')' after arguments.");
          rparen = parser->previous;
        }

        yp_node_t *next_node = yp_node_call_node_create(parser, node, &call_operator, &message, &lparen, arguments, &rparen);
        yp_string_constant_init(&next_node->as.call_node.name, "call", 4);
        return next_node;
      }

      expect(parser, YP_TOKEN_IDENTIFIER, "Expected a method name after '.'");
      yp_token_t message = parser->previous;

      yp_arguments_t arguments;
      parse_arguments_list(parser, &arguments);

      yp_node_t *next_node = yp_node_call_node_create(parser, node, &call_operator, &message, &arguments.opening, arguments.arguments, &arguments.closing);
      yp_string_shared_init(&next_node->as.call_node.name, message.start, message.end);
      return next_node;
    }
    case YP_TOKEN_DOT_DOT:
    case YP_TOKEN_DOT_DOT_DOT: {
      yp_node_t *right = parse_expression(parser, binding_power, "Expected a value after the operator.");
      return yp_node_range_node_create(parser, node, &token, right);
    }
    case YP_TOKEN_KEYWORD_IF: {
      yp_node_t *statements = yp_node_statements_create(parser);
      yp_node_list_append(parser, statements, &statements->as.statements.body, node);

      yp_node_t *predicate = parse_expression(parser, binding_power, "Expected a predicate after 'if'");
      yp_token_t end_keyword = not_provided(parser);

      return yp_node_if_node_create(parser, &token, predicate, statements, NULL, &end_keyword);
    }
    case YP_TOKEN_KEYWORD_UNLESS: {
      yp_node_t *statements = yp_node_statements_create(parser);
      yp_node_list_append(parser, statements, &statements->as.statements.body, node);

      yp_node_t *predicate = parse_expression(parser, binding_power, "Expected a predicate after 'unless'");
      yp_token_t end_keyword = not_provided(parser);

      return yp_node_unless_node_create(parser, &token, predicate, statements, NULL, &end_keyword);
    }
    case YP_TOKEN_KEYWORD_UNTIL: {
      yp_node_t *statements = yp_node_statements_create(parser);
      yp_node_list_append(parser, statements, &statements->as.statements.body, node);

      yp_node_t *predicate = parse_expression(parser, binding_power, "Expected a predicate after 'until'");
      return yp_node_until_node_create(parser, &token, predicate, statements);
    }
    case YP_TOKEN_KEYWORD_WHILE: {
      yp_node_t *statements = yp_node_statements_create(parser);
      yp_node_list_append(parser, statements, &statements->as.statements.body, node);

      yp_node_t *predicate = parse_expression(parser, binding_power, "Expected a predicate after 'while'");
      return yp_node_while_node_create(parser, &token, predicate, statements);
    }
    case YP_TOKEN_QUESTION_MARK: {
      yp_node_t *true_expression = parse_expression(parser, binding_power, "Expected a value after '?'");

      if (parser->recovering) {
        // If parsing the true expression of this ternary resulted in a syntax
        // error that we can recover from, then we're going to put missing nodes
        // and tokens into the remaining places. We want to be sure to do this
        // before the `expect` function call to make sure it doesn't
        // accidentally move past a ':' token that occurs after the syntax
        // error.
        yp_token_t colon = (yp_token_t) { .type = YP_TOKEN_MISSING, .start = parser->previous.end, .end = parser->previous.end };
        yp_node_t *false_expression = yp_node_missing_node_create(parser, &(yp_location_t) {
          .start = colon.start,
          .end = colon.end,
        });

        return yp_node_ternary_create(parser, node, &token, true_expression, &colon, false_expression);
      }

      expect(parser, YP_TOKEN_COLON, "Expected ':' after true expression in ternary operator.");

      yp_token_t colon = parser->previous;
      yp_node_t *false_expression = parse_expression(parser, binding_power, "Expected a value after ':'");

      return yp_node_ternary_create(parser, node, &token, true_expression, &colon, false_expression);
    }
    case YP_TOKEN_COLON_COLON: {
      yp_token_t delimiter = parser->previous;

      switch (parser->current.type) {
        case YP_TOKEN_CONSTANT: {
          yp_node_t *child = parse_expression(parser, binding_power, "Expected a value after '::'");
          return yp_node_constant_path_node_create(parser, node, &delimiter, child);
        }
        case YP_TOKEN_IDENTIFIER: {
          yp_node_t *call = parse_expression(parser, binding_power, "Expected a value after '::'");
          call->as.call_node.call_operator = delimiter;
          call->as.call_node.receiver = node;
          return call;
        }
        default: {
          uint32_t position = delimiter.end - parser->start;
          yp_diagnostic_list_append(&parser->error_list, "Expected identifier or constant after '::'", position);

          yp_node_t *child = yp_node_missing_node_create(parser, &(yp_location_t) {
            .start = delimiter.start,
            .end = delimiter.end,
          });

          return yp_node_constant_path_node_create(parser, node, &delimiter, child);
        }
      }
    }
    case YP_TOKEN_KEYWORD_RESCUE: {
      accept(parser, YP_TOKEN_NEWLINE);
      yp_node_t *value = parse_expression(parser, binding_power, "Expected a value after the rescue keyword.");

      return yp_node_rescue_modifier_node_create(parser, node, &token, value);
    }
    case YP_TOKEN_BRACKET_LEFT: {
      const char *start = parser->previous.start;

      yp_node_t *arguments = yp_arguments_node_create(parser);
      parse_arguments(parser, arguments, YP_TOKEN_BRACKET_RIGHT);
      expect(parser, YP_TOKEN_BRACKET_RIGHT, "Expected ']' to close the bracket expression.");

      yp_token_t call_operator = not_provided(parser);
      yp_token_t lparen = not_provided(parser);
      yp_token_t rparen = not_provided(parser);

      const char *name = "[]";

      if (accept(parser, YP_TOKEN_EQUAL)) {
        yp_node_t *argument = parse_expression(parser, binding_power, "Expected a value after the operator.");
        yp_arguments_node_append(arguments, argument);
        name = "[]=";
      }

      yp_token_t message = (yp_token_t) {
        .type = YP_TOKEN_BRACKET_LEFT_RIGHT,
        .start = start,
        .end = start
      };

      yp_node_t *call_node = yp_node_call_node_create(parser, node, &call_operator, &message, &lparen, arguments, &rparen);
      yp_string_constant_init(&call_node->as.call_node.name, name, strlen(name));
      return call_node;
    }
    default:
      return node;
  }
}

// Parse an expression at the given point of the parser using the given binding
// power to parse subsequent chains. If this function finds a syntax error, it
// will append the error message to the parser's error list.
//
// Consumers of this function should always check parser->recovering to
// determine if they need to perform additional cleanup.
static yp_node_t *
parse_expression(yp_parser_t *parser, binding_power_t binding_power, const char *message) {
  yp_token_t recovery = parser->previous;
  yp_node_t *node = parse_expression_prefix(parser);

  // If we found a syntax error, then the type of node returned by
  // parse_expression_prefix is going to be a missing node. In that case we need
  // to add the error message to the parser's error list.
  if (node->type == YP_NODE_MISSING_NODE) {
    yp_diagnostic_list_append(&parser->error_list, message, recovery.end - parser->start);
    return node;
  }

  // Otherwise we'll look and see if the next token can be parsed as an infix
  // operator. If it can, then we'll parse it using parse_expression_infix.
  binding_powers_t current_binding_powers;
  while (current_binding_powers = binding_powers[parser->current.type], binding_power <= current_binding_powers.left) {
    parser_lex(parser);
    node = parse_expression_infix(parser, node, current_binding_powers.right);
  }

  return node;
}

static yp_node_t *
parse_program(yp_parser_t *parser) {
  yp_node_t *scope = yp_node_scope_create(parser);
  parser->current_scope = scope;

  parser_lex(parser);

  return yp_node_program_create(parser, scope, parse_statements(parser, YP_CONTEXT_MAIN));
}

/******************************************************************************/
/* External functions                                                         */
/******************************************************************************/

// By default, the parser will not attempt to decode any more encodings than are
// already hard-coded into the parser. This function provides the default
// implementation so that the parser always has a valid function pointer.
static yp_encoding_t *
undecodeable(const char *name, size_t length) {
  return NULL;
}

// Initialize a parser with the given start and end pointers.
__attribute__((__visibility__("default"))) extern void
yp_parser_init(yp_parser_t *parser, const char *source, size_t size) {
  *parser = (yp_parser_t) {
    .lex_state = YP_LEX_STATE_BEG,
    .command_start = true,
    .lex_modes =
      {
        .index = 0,
        .stack = {{.mode = YP_LEX_DEFAULT}},
        .current = &parser->lex_modes.stack[0],
      },
    .start = source,
    .end = source + size,
    .current = { .start = source, .end = source },
    .next_start = NULL,
    .heredoc_end = NULL,
    .current_scope = NULL,
    .current_context = NULL,
    .recovering = false,
    .encoding = yp_encoding_utf_8,
    .encoding_decode_callback = undecodeable,
    .lex_callback = NULL
  };

  yp_state_stack_init(&parser->do_loop_stack);
  yp_list_init(&parser->warning_list);
  yp_list_init(&parser->error_list);
  yp_list_init(&parser->comment_list);
}

// Register a callback that will be called when YARP encounters a magic comment
// with an encoding referenced that it doesn't understand. The callback should
// return NULL if it also doesn't understand the encoding or it should return a
// pointer to a yp_encoding_t struct that contains the functions necessary to
// parse identifiers.
__attribute__((__visibility__("default"))) extern void
yp_parser_register_encoding_decode_callback(yp_parser_t *parser, yp_encoding_decode_callback_t callback) {
  parser->encoding_decode_callback = callback;
}

// Free any memory associated with the given parser.
__attribute__((__visibility__("default"))) extern void
yp_parser_free(yp_parser_t *parser) {
  yp_diagnostic_list_free(&parser->error_list);
  yp_list_free(&parser->comment_list);
}

// Get the next token type and set its value on the current pointer.
__attribute__((__visibility__("default"))) extern void
yp_lex_token(yp_parser_t *parser) {
  parser->previous = parser->current;
  parser->current.type = lex_token_type(parser);
}

// Parse the Ruby source associated with the given parser and return the tree.
__attribute__((__visibility__("default"))) extern yp_node_t *
yp_parse(yp_parser_t *parser) {
  return parse_program(parser);
}

__attribute__((__visibility__("default"))) extern void
yp_serialize(yp_parser_t *parser, yp_node_t *node, yp_buffer_t *buffer) {
  yp_buffer_append_str(buffer, "YARP", 4);
  yp_buffer_append_u8(buffer, YP_VERSION_MAJOR);
  yp_buffer_append_u8(buffer, YP_VERSION_MINOR);
  yp_buffer_append_u8(buffer, YP_VERSION_PATCH);

  yp_serialize_node(parser, node, buffer);
  yp_buffer_append_str(buffer, "\0", 1);
}

// Parse and serialize the AST represented by the given source to the given
// buffer.
__attribute__((__visibility__("default"))) extern void
yp_parse_serialize(const char *source, size_t size, yp_buffer_t *buffer) {
  yp_parser_t parser;
  yp_parser_init(&parser, source, size);

  yp_node_t *node = yp_parse(&parser);
  yp_serialize(&parser, node, buffer);

  yp_node_destroy(&parser, node);
  yp_parser_free(&parser);
}
