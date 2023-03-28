#include "yarp.h"

#define YP_STRINGIZE0(expr) #expr
#define YP_STRINGIZE(expr) YP_STRINGIZE0(expr)
#define YP_VERSION_MACRO YP_STRINGIZE(YP_VERSION_MAJOR) "." YP_STRINGIZE(YP_VERSION_MINOR) "." YP_STRINGIZE(YP_VERSION_PATCH)

#define YP_TAB_WHITESPACE_SIZE 8

char* yp_version(void) {
  return YP_VERSION_MACRO;
}

/******************************************************************************/
/* Debugging                                                                  */
/******************************************************************************/

__attribute__((unused)) static const char *
debug_context(yp_context_t context) {
  switch (context) {
    case YP_CONTEXT_BEGIN: return "BEGIN";
    case YP_CONTEXT_CLASS: return "CLASS";
    case YP_CONTEXT_CASE_IN: return "CASE_IN";
    case YP_CONTEXT_CASE_WHEN: return "CASE_WHEN";
    case YP_CONTEXT_DEF: return "DEF";
    case YP_CONTEXT_DEF_PARAMS: return "DEF_PARAMS";
    case YP_CONTEXT_ENSURE: return "ENSURE";
    case YP_CONTEXT_ELSE: return "ELSE";
    case YP_CONTEXT_ELSIF: return "ELSIF";
    case YP_CONTEXT_EMBEXPR: return "EMBEXPR";
    case YP_CONTEXT_BLOCK_BRACES: return "BLOCK_BRACES";
    case YP_CONTEXT_BLOCK_KEYWORDS: return "BLOCK_KEYWORDS";
    case YP_CONTEXT_FOR: return "FOR";
    case YP_CONTEXT_IF: return "IF";
    case YP_CONTEXT_MAIN: return "MAIN";
    case YP_CONTEXT_MODULE: return "MODULE";
    case YP_CONTEXT_PARENS: return "PARENS";
    case YP_CONTEXT_POSTEXE: return "POSTEXE";
    case YP_CONTEXT_PREDICATE: return "PREDICATE";
    case YP_CONTEXT_PREEXE: return "PREEXE";
    case YP_CONTEXT_RESCUE: return "RESCUE";
    case YP_CONTEXT_RESCUE_ELSE: return "RESCUE_ELSE";
    case YP_CONTEXT_SCLASS: return "SCLASS";
    case YP_CONTEXT_UNLESS: return "UNLESS";
    case YP_CONTEXT_UNTIL: return "UNTIL";
    case YP_CONTEXT_WHILE: return "WHILE";
    case YP_CONTEXT_LAMBDA_BRACES: return "LAMBDA_BRACES";
    case YP_CONTEXT_LAMBDA_DO_END: return "LAMBDA_DO_END";
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
  bool first = true;

  while (lex_mode != NULL) {
    if (first) {
      first = false;
    } else {
      fprintf(stderr, " <- ");
    }

    switch (lex_mode->mode) {
      case YP_LEX_DEFAULT: fprintf(stderr, "DEFAULT"); break;
      case YP_LEX_EMBEXPR: fprintf(stderr, "EMBEXPR"); break;
      case YP_LEX_EMBVAR: fprintf(stderr, "EMBVAR"); break;
      case YP_LEX_HEREDOC: fprintf(stderr, "HEREDOC"); break;
      case YP_LEX_LIST: fprintf(stderr, "LIST (terminator=%c, interpolation=%d)", lex_mode->as.list.terminator, lex_mode->as.list.interpolation); break;
      case YP_LEX_REGEXP: fprintf(stderr, "REGEXP (terminator=%c)", lex_mode->as.regexp.terminator); break;
      case YP_LEX_STRING: fprintf(stderr, "STRING (terminator=%c, interpolation=%d)", lex_mode->as.string.terminator, lex_mode->as.string.interpolation); break;
    }

    lex_mode = lex_mode->prev;
  }

  fprintf(stderr, "\n");
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

  yp_token_list_t token_list = ((yp_scope_node_t *)parser->current_scope->node)->locals;
  for (size_t index = 0; index < token_list.size; index++) {
    debug_token(&token_list.tokens[index]);
  }

  fprintf(stderr, "\n");
}

/******************************************************************************/
/* Node-related functions                                                     */
/******************************************************************************/

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

#define YP_LOCATION_NULL_VALUE(parser) ((yp_location_t) { .start = parser->start, .end = parser->start })
#define YP_LOCATION_TOKEN_VALUE(token) ((yp_location_t) { .start = (token)->start, .end = (token)->end })
#define YP_LOCATION_NODE_VALUE(node) ((yp_location_t) { .start = (node)->location.start, .end = (node)->location.end })
#define YP_OPTIONAL_LOCATION_TOKEN_VALUE(token) ((token)->type == YP_TOKEN_NOT_PROVIDED ? (yp_location_t) { .start = NULL, .end = NULL } : YP_LOCATION_TOKEN_VALUE(token))
#define YP_TOKEN_NOT_PROVIDED_VALUE(parser) ((yp_token_t) { .type = YP_TOKEN_NOT_PROVIDED, .start = (parser)->start, .end = (parser)->start })
#define YP_NODE_DOWNCAST(node) ((yp_node_t *)node)
#define YP_NODE_UPCAST(node, type) ((type *)node)

// This is a special out parameter to the parse_arguments_list function that
// includes opening and closing parentheses in addition to the arguments since
// it's so common. It is handy to use when passing argument information to one
// of the call node creation functions.
typedef struct {
  yp_token_t opening;
  yp_node_t *arguments;
  yp_token_t closing;
  yp_node_t *block;
} yp_arguments_t;

// Initialize a stack-allocated yp_arguments_t struct to its default values and
// return it.
static inline yp_arguments_t
yp_arguments(yp_parser_t *parser) {
  return (yp_arguments_t) {
    .opening = YP_TOKEN_NOT_PROVIDED_VALUE(parser),
    .arguments = NULL,
    .closing = YP_TOKEN_NOT_PROVIDED_VALUE(parser),
    .block = NULL
  };
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

// Allocate the space for a new yp_node_t. Currently we're not using the
// parser argument, but it's there to allow for the future possibility of
// pre-allocating larger memory pools and then pulling from those here.
static inline yp_node_t *
yp_node_alloc(yp_parser_t *parser) {
  return (yp_node_t *) malloc(sizeof(yp_node_t));
}

/******************************************************************************/
/* Node creation functions                                                    */
/******************************************************************************/

#define YP_NODE_ALLOC(type) (type *)malloc(sizeof(type))

// Allocate and initialize a new StatementsNode node.
static yp_node_t *
yp_statements_node_create(yp_parser_t *parser);

// Append a new node to the given StatementsNode node's body.
static void
yp_statements_node_body_append(yp_node_t *node, yp_node_t *statement);

// Allocate and initialize a new node of the given type from the given token.
// This function is used for simple nodes that effectively wrap a token.
static inline yp_node_t *
yp_node_create_from_token(yp_parser_t *parser, yp_node_type_t type, const yp_token_t *token) {
  yp_node_t *node = yp_node_alloc(parser);
  *node = (yp_node_t) { .type = type, .location = YP_LOCATION_TOKEN_VALUE(token) };
  return node;
}
// Allocate and initialize a new alias node.
static yp_node_t *
yp_alias_node_create(yp_parser_t *parser, const yp_token_t *keyword, yp_node_t *new_name, yp_node_t *old_name) {
  assert(keyword->type == YP_TOKEN_KEYWORD_ALIAS);
  yp_alias_node_t *node = YP_NODE_ALLOC(yp_alias_node_t);

  *node = (yp_alias_node_t) {
    {
      .type = YP_NODE_ALIAS_NODE,
      .location = {
        .start = keyword->start,
        .end = old_name->location.end
      },
    },
    .new_name = new_name,
    .old_name = old_name,
    .keyword_loc = YP_LOCATION_TOKEN_VALUE(keyword)
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate a new AlternationPatternNode node.
static yp_node_t *
yp_alternation_pattern_node_create(yp_parser_t *parser, yp_node_t *left, yp_node_t *right, const yp_token_t *operator) {
  yp_alternation_pattern_node_t *node = YP_NODE_ALLOC(yp_alternation_pattern_node_t);

  *node = (yp_alternation_pattern_node_t) {
    {
      .type = YP_NODE_ALTERNATION_PATTERN_NODE,
      .location = {
        .start = left->location.start,
        .end = right->location.end
      },
    },
    .left = left,
    .right = right,
    .operator_loc = YP_LOCATION_TOKEN_VALUE(operator)
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new and node.
static yp_node_t *
yp_and_node_create(yp_parser_t *parser, yp_node_t *left, const yp_token_t *operator, yp_node_t *right) {
  yp_and_node_t *node = YP_NODE_ALLOC(yp_and_node_t);

  *node = (yp_and_node_t) {
    {
      .type = YP_NODE_AND_NODE,
      .location = {
        .start = left->location.start,
        .end = right->location.end
      },
    },
    .left = left,
    .operator = *operator,
    .right = right
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate an initialize a new arguments node.
static yp_node_t *
yp_arguments_node_create(yp_parser_t *parser) {
  yp_arguments_node_t *node = YP_NODE_ALLOC(yp_arguments_node_t);

  *node = (yp_arguments_node_t) {
    {
      .type = YP_NODE_ARGUMENTS_NODE,
      .location = YP_LOCATION_NULL_VALUE(parser)
    }
  };

  yp_node_list_init(&node->arguments);
  return YP_NODE_DOWNCAST(node);
}

// Return the size of the given arguments node.
static size_t
yp_arguments_node_size(yp_node_t *node) {
  assert(node->type == YP_NODE_ARGUMENTS_NODE);
  return YP_NODE_UPCAST(node, yp_arguments_node_t)->arguments.size;
}

// Append an argument to an arguments node.
static void
yp_arguments_node_arguments_append(yp_node_t *node, yp_node_t *argument) {
  assert(node->type == YP_NODE_ARGUMENTS_NODE);

  if (yp_arguments_node_size(node) == 0) {
    node->location.start = argument->location.start;
  }

  node->location.end = argument->location.end;
  yp_node_list_append2(&YP_NODE_UPCAST(node, yp_arguments_node_t)->arguments, argument);
}

// Allocate and initialize a new ArrayNode node.
static yp_node_t *
yp_array_node_create(yp_parser_t *parser, const yp_token_t *opening, const yp_token_t *closing) {
  yp_array_node_t *node = YP_NODE_ALLOC(yp_array_node_t);

  *node = (yp_array_node_t) {
    {
      .type = YP_NODE_ARRAY_NODE,
      .location = {
        .start = opening->start,
        .end = closing->end
      },
    },
    .opening = *opening,
    .closing = *closing
  };

  yp_node_list_init(&node->elements);
  return YP_NODE_DOWNCAST(node);
}

// Return the size of the given array node.
static size_t
yp_array_node_size(yp_node_t *node) {
  assert(node->type == YP_NODE_ARRAY_NODE);
  return YP_NODE_UPCAST(node, yp_array_node_t)->elements.size;
}

// Append an argument to an array node.
static void
yp_array_node_elements_append(yp_node_t *node, yp_node_t *element) {
  assert(node->type == YP_NODE_ARRAY_NODE);
  yp_node_list_append2(&YP_NODE_UPCAST(node, yp_array_node_t)->elements, element);
}

// Set the closing token and end location of an array node.
static void
yp_array_node_close_set(yp_node_t *node, const yp_token_t *closing) {
  assert(closing->type == YP_TOKEN_BRACKET_RIGHT || closing->type == YP_TOKEN_STRING_END || closing->type == YP_TOKEN_MISSING);
  node->location.end = closing->end;
  YP_NODE_UPCAST(node, yp_array_node_t)->closing = *closing;
}

// Allocate and initialize a new array pattern node. The node list given in the
// nodes parameter is guaranteed to have at least two nodes.
static yp_node_t *
yp_array_pattern_node_node_list_create(yp_parser_t *parser, yp_node_list_t *nodes) {
  yp_array_pattern_node_t *node = YP_NODE_ALLOC(yp_array_pattern_node_t);

  *node = (yp_array_pattern_node_t) {
    {
      .type = YP_NODE_ARRAY_PATTERN_NODE,
      .location = {
        .start = nodes->nodes[0]->location.start,
        .end = nodes->nodes[nodes->size - 1]->location.end
      },
    },
    .constant = NULL,
    .rest = NULL
  };

  // For now we're going to just copy over each pointer manually. This could be
  // much more efficient, as we could instead resize the node list.
  yp_node_list_init(&node->requireds);
  yp_node_list_init(&node->posts);

  bool found_rest = false;
  for (size_t index = 0; index < nodes->size; index++) {
    yp_node_t *child = nodes->nodes[index];

    if (child->type == YP_NODE_SPLAT_NODE) {
      node->rest = child;
      found_rest = true;
    } else if (found_rest) {
      yp_node_list_append2(&node->posts, child);
    } else {
      yp_node_list_append2(&node->requireds, child);
    }
  }

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new array pattern node from a single rest node.
static yp_node_t *
yp_array_pattern_node_rest_create(yp_parser_t *parser, yp_node_t *rest) {
  yp_array_pattern_node_t *node = YP_NODE_ALLOC(yp_array_pattern_node_t);

  *node = (yp_array_pattern_node_t) {
    {
      .type = YP_NODE_ARRAY_PATTERN_NODE,
      .location = rest->location,
    },
    .constant = NULL,
    .rest = rest
  };

  yp_node_list_init(&node->requireds);
  yp_node_list_init(&node->posts);

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new array pattern node from a constant and opening
// and closing tokens.
static yp_node_t *
yp_array_pattern_node_constant_create(yp_parser_t *parser, yp_node_t *constant, const yp_token_t *opening, const yp_token_t *closing) {
  yp_array_pattern_node_t *node = YP_NODE_ALLOC(yp_array_pattern_node_t);

  *node = (yp_array_pattern_node_t) {
    {
      .type = YP_NODE_ARRAY_PATTERN_NODE,
      .location = {
        .start = constant->location.start,
        .end = closing->end
      },
    },
    .constant = constant,
    .rest = NULL,
    .opening_loc = YP_LOCATION_TOKEN_VALUE(opening),
    .closing_loc = YP_LOCATION_TOKEN_VALUE(closing)
  };

  yp_node_list_init(&node->requireds);
  yp_node_list_init(&node->posts);

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new array pattern node from an opening and closing
// token.
static yp_node_t *
yp_array_pattern_node_empty_create(yp_parser_t *parser, const yp_token_t *opening, const yp_token_t *closing) {
  yp_array_pattern_node_t *node = YP_NODE_ALLOC(yp_array_pattern_node_t);

  *node = (yp_array_pattern_node_t) {
    {
      .type = YP_NODE_ARRAY_PATTERN_NODE,
      .location = {
        .start = opening->start,
        .end = closing->end
      },
    },
    .constant = NULL,
    .rest = NULL,
    .opening_loc = YP_LOCATION_TOKEN_VALUE(opening),
    .closing_loc = YP_LOCATION_TOKEN_VALUE(closing)
  };

  yp_node_list_init(&node->requireds);
  yp_node_list_init(&node->posts);

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new AsPatternNode node.
static yp_node_t *
yp_as_pattern_node_create(yp_parser_t *parser, yp_node_t *value, yp_node_t *target, const yp_token_t *operator) {
  yp_as_pattern_node_t *node = YP_NODE_ALLOC(yp_as_pattern_node_t);

  *node = (yp_as_pattern_node_t) {
    {
      .type = YP_NODE_AS_PATTERN_NODE,
      .location = {
        .start = value->location.start,
        .end = target->location.end
      },
    },
    .value = value,
    .target = target,
    .operator_loc = YP_LOCATION_TOKEN_VALUE(operator)
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new assoc node.
static yp_node_t *
yp_assoc_node_create(yp_parser_t *parser, yp_node_t *key, const yp_token_t *operator, yp_node_t *value) {
  yp_assoc_node_t *node = YP_NODE_ALLOC(yp_assoc_node_t);
  const char *end;

  if (value != NULL) {
    end = value->location.end;
  } else if (operator->type != YP_TOKEN_NOT_PROVIDED) {
    end = operator->end;
  } else {
    end = key->location.end;
  }

  *node = (yp_assoc_node_t) {
    {
      .type = YP_NODE_ASSOC_NODE,
      .location = {
        .start = key->location.start,
        .end = end
      },
    },
    .key = key,
    .operator = *operator,
    .value = value
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new assoc splat node.
static yp_node_t *
yp_assoc_splat_node_create(yp_parser_t *parser, yp_node_t *value, const yp_token_t *operator) {
  assert(operator->type == YP_TOKEN_USTAR_STAR);
  yp_assoc_splat_node_t *node = YP_NODE_ALLOC(yp_assoc_splat_node_t);

  *node = (yp_assoc_splat_node_t) {
    {
      .type = YP_NODE_ASSOC_SPLAT_NODE,
      .location = {
        .start = operator->start,
        .end = value == NULL ? operator->end : value->location.end
      },
    },
    .value = value,
    .operator_loc = YP_LOCATION_TOKEN_VALUE(operator)
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize new a begin node.
static yp_node_t *
yp_begin_node_create(yp_parser_t *parser, const yp_token_t *begin_keyword, yp_node_t *statements) {
  yp_begin_node_t *node = YP_NODE_ALLOC(yp_begin_node_t);

  *node = (yp_begin_node_t) {
    {
      .type = YP_NODE_BEGIN_NODE,
      .location = {
        .start = begin_keyword->start,
        .end = statements->location.end
      },
    },
    .begin_keyword = *begin_keyword,
    .statements = statements,
    .end_keyword = YP_TOKEN_NOT_PROVIDED_VALUE(parser)
  };

  return YP_NODE_DOWNCAST(node);
}

// Set the rescue clause and end location of a begin node.
static void
yp_begin_node_rescue_clause_set(yp_node_t *node, yp_node_t *rescue_clause) {
  assert(node->type == YP_NODE_BEGIN_NODE);
  assert(rescue_clause->type == YP_NODE_RESCUE_NODE);
  yp_begin_node_t *begin_node = YP_NODE_UPCAST(node, yp_begin_node_t);
  begin_node->base.location.end = rescue_clause->location.end;
  begin_node->rescue_clause = rescue_clause;
}

// Set the else clause and end location of a begin node.
static void
yp_begin_node_else_clause_set(yp_node_t *node, yp_node_t *else_clause) {
  assert(node->type == YP_NODE_BEGIN_NODE);
  assert(else_clause->type == YP_NODE_ELSE_NODE);
  yp_begin_node_t *begin_node = YP_NODE_UPCAST(node, yp_begin_node_t);
  begin_node->base.location.end = else_clause->location.end;
  begin_node->else_clause = else_clause;
}

// Set the ensure clause and end location of a begin node.
static void
yp_begin_node_ensure_clause_set(yp_node_t *node, yp_node_t *ensure_clause) {
  assert(node->type == YP_NODE_BEGIN_NODE);
  assert(ensure_clause->type == YP_NODE_ENSURE_NODE);
  yp_begin_node_t *begin_node = YP_NODE_UPCAST(node, yp_begin_node_t);
  begin_node->base.location.end = ensure_clause->location.end;
  begin_node->ensure_clause = ensure_clause;
}

// Set the end keyword and end location of a begin node.
static void
yp_begin_node_end_keyword_set(yp_node_t *node, const yp_token_t *end_keyword) {
  assert(node->type == YP_NODE_BEGIN_NODE);
  assert(end_keyword->type == YP_TOKEN_KEYWORD_END || end_keyword->type == YP_TOKEN_MISSING);
  yp_begin_node_t *begin_node = YP_NODE_UPCAST(node, yp_begin_node_t);
  begin_node->base.location.end = end_keyword->end;
  begin_node->end_keyword = *end_keyword;
}

// Allocate and initialize a new BlockArgumentNode node.
static yp_node_t *
yp_block_argument_node_create(yp_parser_t *parser, const yp_token_t *operator, yp_node_t *expression) {
  yp_block_argument_node_t *node = YP_NODE_ALLOC(yp_block_argument_node_t);

  *node = (yp_block_argument_node_t) {
    {
      .type = YP_NODE_BLOCK_ARGUMENT_NODE,
      .location = {
        .start = operator->start,
        .end = expression->location.end
      },
    },
    .expression = expression,
    .operator_loc = YP_LOCATION_TOKEN_VALUE(operator)
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new BlockNode node.
static yp_node_t *
yp_block_node_create(yp_parser_t *parser, yp_node_t *scope, const yp_token_t *opening, yp_node_t *parameters, yp_node_t *statements, const yp_token_t *closing) {
  yp_block_node_t *node = YP_NODE_ALLOC(yp_block_node_t);

  *node = (yp_block_node_t) {
    {
      .type = YP_NODE_BLOCK_NODE,
      .location = { .start = opening->start, .end = closing->end },
    },
    .scope = scope,
    .parameters = parameters,
    .statements = statements,
    .opening_loc = YP_LOCATION_TOKEN_VALUE(opening),
    .closing_loc = YP_LOCATION_TOKEN_VALUE(closing)
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new BlockParameterNode node.
static yp_node_t *
yp_block_parameter_node_create(yp_parser_t *parser, const yp_token_t *name, const yp_token_t *operator) {
  assert(operator->type == YP_TOKEN_NOT_PROVIDED || operator->type == YP_TOKEN_AMPERSAND);
  yp_block_parameter_node_t *node = YP_NODE_ALLOC(yp_block_parameter_node_t);

  *node = (yp_block_parameter_node_t) {
    {
      .type = YP_NODE_BLOCK_PARAMETER_NODE,
      .location = {
        .start = operator->start,
        .end = (name->type == YP_TOKEN_NOT_PROVIDED ? operator->end : name->end)
      },
    },
    .name = *name,
    .operator_loc = YP_LOCATION_TOKEN_VALUE(operator)
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new BlockParametersNode node.
static yp_node_t *
yp_block_parameters_node_create(yp_parser_t *parser, yp_node_t *parameters) {
  yp_block_parameters_node_t *node = YP_NODE_ALLOC(yp_block_parameters_node_t);

  *node = (yp_block_parameters_node_t) {
    {
      .type = YP_NODE_BLOCK_PARAMETERS_NODE,
      .location = parameters == NULL ? YP_LOCATION_NULL_VALUE(parser) : YP_LOCATION_NODE_VALUE(parameters),
    },
    .parameters = parameters
  };

  yp_token_list_init(&node->locals);
  return YP_NODE_DOWNCAST(node);
}

// Append a new block-local variable to a BlockParametersNode node.
static void
yp_block_parameters_node_append_local(yp_node_t *node, const yp_token_t *local) {
  assert(local->type == YP_TOKEN_IDENTIFIER);
  yp_block_parameters_node_t *params_node = YP_NODE_UPCAST(node, yp_block_parameters_node_t);
  yp_token_list_append(&params_node->locals, local);
  params_node->base.location.end = local->end;
}

// Allocate and initialize a new BreakNode node.
static yp_node_t *
yp_break_node_create(yp_parser_t *parser, const yp_token_t *keyword, yp_node_t *arguments) {
  assert(keyword->type == YP_TOKEN_KEYWORD_BREAK);
  yp_break_node_t *node = YP_NODE_ALLOC(yp_break_node_t);

  *node = (yp_break_node_t) {
    {
      .type = YP_NODE_BREAK_NODE,
      .location = {
        .start = keyword->start,
        .end = (arguments == NULL ? keyword->end : arguments->location.end)
      },
    },
    .arguments = arguments,
    .keyword_loc = YP_LOCATION_TOKEN_VALUE(keyword)
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new CallNode node. This sets everything to NULL or
// YP_TOKEN_NOT_PROVIDED as appropriate such that its values can be overridden
// in the various specializations of this function.
static yp_node_t *
yp_call_node_create(yp_parser_t *parser) {
  yp_call_node_t *node = YP_NODE_ALLOC(yp_call_node_t);

  *node = (yp_call_node_t) {
    {
      .type = YP_NODE_CALL_NODE,
      .location = YP_LOCATION_NULL_VALUE(parser),
    },
    .receiver = NULL,
    .call_operator = YP_TOKEN_NOT_PROVIDED_VALUE(parser),
    .message = YP_TOKEN_NOT_PROVIDED_VALUE(parser),
    .opening = YP_TOKEN_NOT_PROVIDED_VALUE(parser),
    .arguments = NULL,
    .closing = YP_TOKEN_NOT_PROVIDED_VALUE(parser),
    .block = NULL
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new CallNode node from an aref or an aset
// expression.
static yp_node_t *
yp_call_node_aref_create(yp_parser_t *parser, yp_node_t *receiver, yp_arguments_t *arguments) {
  yp_call_node_t *node = YP_NODE_UPCAST(yp_call_node_create(parser), yp_call_node_t);

  node->base.location.start = receiver->location.start;
  if (arguments->block != NULL) {
    node->base.location.end = arguments->block->location.end;
  } else {
    node->base.location.end = arguments->closing.end;
  }

  node->receiver = receiver;
  node->message = (yp_token_t) {
    .type = YP_TOKEN_BRACKET_LEFT_RIGHT,
    .start = arguments->opening.start,
    .end = arguments->opening.end
  };

  node->opening = arguments->opening;
  node->arguments = arguments->arguments;
  node->closing = arguments->closing;
  node->block = arguments->block;

  yp_string_constant_init(&node->name, "[]", 2);
  return YP_NODE_DOWNCAST(node);
}

#define YP_NODE_CAST(value) ((yp_node_t *)value)

// Allocate and initialize a new CallNode node from a binary expression.
static yp_node_t *
yp_call_node_binary_create(yp_parser_t *parser, yp_node_t *receiver, yp_token_t *operator, yp_node_t *argument) {
  yp_call_node_t *node = YP_NODE_UPCAST(yp_call_node_create(parser), yp_call_node_t);

  node->base.location.start = receiver->location.start;
  node->base.location.end = argument->location.end;

  node->receiver = receiver;
  node->message = *operator;

  yp_node_t *arguments = yp_arguments_node_create(parser);
  yp_arguments_node_arguments_append(arguments, argument);
  node->arguments = YP_NODE_CAST(arguments);

  yp_string_shared_init(&node->name, operator->start, operator->end);
  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new CallNode node from a call expression.
static yp_node_t *
yp_call_node_call_create(yp_parser_t *parser, yp_node_t *receiver, yp_token_t *operator, yp_token_t *message, yp_arguments_t *arguments) {
  yp_call_node_t *node = YP_NODE_UPCAST(yp_call_node_create(parser), yp_call_node_t);

  node->base.location.start = receiver->location.start;
  if (arguments->block != NULL) {
    node->base.location.end = arguments->block->location.end;
  } else if (arguments->closing.type != YP_TOKEN_NOT_PROVIDED) {
    node->base.location.end = arguments->closing.end;
  } else if (arguments->arguments != NULL) {
    node->base.location.end = arguments->arguments->location.end;
  } else {
    node->base.location.end = message->end;
  }

  node->receiver = receiver;
  node->call_operator = *operator;
  node->message = *message;
  node->opening = arguments->opening;
  node->arguments = arguments->arguments;
  node->closing = arguments->closing;
  node->block = arguments->block;

  yp_string_shared_init(&node->name, message->start, message->end);
  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new CallNode node from a call to a method name
// without a receiver that could not have been a local variable read.
static yp_node_t *
yp_call_node_fcall_create(yp_parser_t *parser, yp_token_t *message, yp_arguments_t *arguments) {
  yp_call_node_t *node = YP_NODE_UPCAST(yp_call_node_create(parser), yp_call_node_t);

  node->base.location.start = message->start;
  if (arguments->block != NULL) {
    node->base.location.end = arguments->block->location.end;
  } else {
    node->base.location.end = arguments->closing.end;
  }

  node->message = *message;
  node->opening = arguments->opening;
  node->arguments = arguments->arguments;
  node->closing = arguments->closing;
  node->block = arguments->block;

  yp_string_shared_init(&node->name, message->start, message->end);
  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new CallNode node from a not expression.
static yp_node_t *
yp_call_node_not_create(yp_parser_t *parser, yp_node_t *receiver, yp_token_t *message, yp_arguments_t *arguments) {
  yp_call_node_t *node = YP_NODE_UPCAST(yp_call_node_create(parser), yp_call_node_t);

  node->base.location.start = message->start;
  if (arguments->closing.type != YP_TOKEN_NOT_PROVIDED) {
    node->base.location.end = arguments->closing.end;
  } else {
    node->base.location.end = receiver->location.end;
  }

  node->receiver = receiver;
  node->message = *message;
  node->opening = arguments->opening;
  node->arguments = arguments->arguments;
  node->closing = arguments->closing;

  yp_string_constant_init(&node->name, "!", 1);
  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new CallNode node from a call shorthand expression.
static yp_node_t *
yp_call_node_shorthand_create(yp_parser_t *parser, yp_node_t *receiver, yp_token_t *operator, yp_arguments_t *arguments) {
  yp_call_node_t *node = YP_NODE_UPCAST(yp_call_node_create(parser), yp_call_node_t);

  node->base.location.start = receiver->location.start;
  if (arguments->block != NULL) {
    node->base.location.end = arguments->block->location.end;
  } else {
    node->base.location.end = arguments->closing.end;
  }

  node->receiver = receiver;
  node->call_operator = *operator;
  node->opening = arguments->opening;
  node->arguments = arguments->arguments;
  node->closing = arguments->closing;
  node->block = arguments->block;

  yp_string_constant_init(&node->name, "call", 4);
  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new CallNode node from a unary operator expression.
static yp_node_t *
yp_call_node_unary_create(yp_parser_t *parser, yp_token_t *operator, yp_node_t *receiver, const char *name) {
  yp_call_node_t *node = YP_NODE_UPCAST(yp_call_node_create(parser), yp_call_node_t);

  node->base.location.start = operator->start;
  node->base.location.end = receiver->location.end;

  node->receiver = receiver;
  node->message = *operator;

  yp_string_constant_init(&node->name, name, strnlen(name, 2));
  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new CallNode node from a call to a method name
// without a receiver that could also have been a local variable read.
static yp_node_t *
yp_call_node_vcall_create(yp_parser_t *parser, yp_token_t *message) {
  yp_call_node_t *node = YP_NODE_UPCAST(yp_call_node_create(parser), yp_call_node_t);

  node->base.location.start = message->start;
  node->base.location.end = message->end;

  node->message = *message;

  yp_string_shared_init(&node->name, message->start, message->end);
  return YP_NODE_DOWNCAST(node);
}

// Returns whether or not this call node is a "vcall" (a call to a method name
// without a receiver that could also have been a local variable read).
static bool
yp_call_node_vcall_p(yp_node_t *node) {
  yp_call_node_t *call_node = YP_NODE_UPCAST(node, yp_call_node_t);
  return (
    (call_node->opening.type == YP_TOKEN_NOT_PROVIDED) &&
    (call_node->arguments == NULL) &&
    (call_node->block == NULL) &&
    (call_node->receiver == NULL)
  );
}

// Allocate and initialize a new CaseNode node.
static yp_node_t *
yp_case_node_create(yp_parser_t *parser, const yp_token_t *case_keyword, yp_node_t *predicate, yp_node_t *consequent, const yp_token_t *end_keyword) {
  yp_case_node_t *node = YP_NODE_ALLOC(yp_case_node_t);

  *node = (yp_case_node_t) {
    {
      .type = YP_NODE_CASE_NODE,
      .location = {
        .start = case_keyword->start,
        .end = end_keyword->end
      },
    },
    .predicate = predicate,
    .consequent = consequent,
    .case_keyword_loc = YP_LOCATION_TOKEN_VALUE(case_keyword),
    .end_keyword_loc = YP_LOCATION_TOKEN_VALUE(end_keyword)
  };

  yp_node_list_init(&node->conditions);
  return YP_NODE_DOWNCAST(node);
}

// Append a new condition to a CaseNode node.
static void
yp_case_node_condition_append(yp_node_t *node, yp_node_t *condition) {
  assert(node->type == YP_NODE_CASE_NODE);
  assert(condition->type == YP_NODE_WHEN_NODE || condition->type == YP_NODE_IN_NODE);

  yp_node_list_append2(&YP_NODE_UPCAST(node, yp_case_node_t)->conditions, condition);
  node->location.end = condition->location.end;
}

// Set the consequent of a CaseNode node.
static void
yp_case_node_consequent_set(yp_node_t *node, yp_node_t *consequent) {
  assert(node->type == YP_NODE_CASE_NODE);

  YP_NODE_UPCAST(node, yp_case_node_t)->consequent = consequent;
  node->location.end = consequent->location.end;
}

// Set the end location for a CaseNode node.
static void
yp_case_node_end_keyword_loc_set(yp_node_t *node, const yp_token_t *end_keyword) {
  assert(node->type == YP_NODE_CASE_NODE);

  node->location.end = end_keyword->end;
  YP_NODE_UPCAST(node, yp_case_node_t)->end_keyword_loc = YP_LOCATION_TOKEN_VALUE(end_keyword);
}

// Allocate a new ClassNode node.
static yp_node_t *
yp_class_node_create(yp_parser_t *parser, yp_node_t *scope, const yp_token_t *class_keyword, yp_node_t *constant_path, const yp_token_t *inheritance_operator, yp_node_t *superclass, yp_node_t *statements, const yp_token_t *end_keyword) {
  yp_class_node_t *node = YP_NODE_ALLOC(yp_class_node_t);

  *node = (yp_class_node_t) {
    {
      .type = YP_NODE_CLASS_NODE,
      .location = { .start = class_keyword->start, .end = end_keyword->end },
    },
    .scope = scope,
    .class_keyword = *class_keyword,
    .constant_path = constant_path,
    .inheritance_operator = *inheritance_operator,
    .superclass = superclass,
    .statements = statements,
    .end_keyword = *end_keyword
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new ClassVariableReadNode node.
static yp_node_t *
yp_class_variable_read_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_CLASS_VARIABLE);
  return yp_node_create_from_token(parser, YP_NODE_CLASS_VARIABLE_READ_NODE, token);
}

// Initialize a new ClassVariableWriteNode node from a ClassVariableRead node.
static yp_node_t *
yp_class_variable_read_node_to_class_variable_write_node(yp_parser_t *parser, yp_node_t *node, yp_token_t *operator, yp_node_t *value) {
  yp_class_variable_write_node_t *write_node = YP_NODE_ALLOC(yp_class_variable_write_node_t);

  *write_node = (yp_class_variable_write_node_t) {
    {
      .type = YP_NODE_CLASS_VARIABLE_WRITE_NODE,
      .location = node->location,
    },
  };

  write_node->name_loc = YP_LOCATION_NODE_VALUE(node);
  write_node->operator_loc = YP_OPTIONAL_LOCATION_TOKEN_VALUE(operator);

  if (value != NULL) {
    write_node->base.location.end = value->location.end;
    write_node->value = value;
  }

  return YP_NODE_DOWNCAST(write_node);
}

// Allocate and initialize a new ConstantPathNode node.
static yp_node_t *
yp_constant_path_node_create(yp_parser_t *parser, yp_node_t *parent, const yp_token_t *delimiter, yp_node_t *child) {
  yp_constant_path_node_t *node = YP_NODE_ALLOC(yp_constant_path_node_t);

  *node = (yp_constant_path_node_t) {
    {
      .type = YP_NODE_CONSTANT_PATH_NODE,
      .location = {
        .start = parent == NULL ? delimiter->start : parent->location.start,
        .end = child->location.end
      },
    },
    .parent = parent,
    .child = child,
    .delimiter_loc = YP_LOCATION_TOKEN_VALUE(delimiter)
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate a new ConstantPathWriteNode node.
static yp_node_t *
yp_constant_path_write_node_create(yp_parser_t *parser, yp_node_t *target, const yp_token_t *operator, yp_node_t *value) {
  yp_constant_path_write_node_t *node = YP_NODE_ALLOC(yp_constant_path_write_node_t);

  *node = (yp_constant_path_write_node_t) {
    {
      .type = YP_NODE_CONSTANT_PATH_WRITE_NODE,
      .location = {
        .start = target->location.start,
        .end = (value == NULL ? target->location.end : value->location.end)
      },
    },
    .target = target,
    .operator = *operator,
    .value = value
  };

  return YP_NODE_DOWNCAST(node);
}


// Allocate and initialize a new ConstantReadNode node.
static yp_node_t *
yp_constant_read_node_create(yp_parser_t *parser, const yp_token_t *name) {
  assert(name->type == YP_TOKEN_CONSTANT || name->type == YP_TOKEN_MISSING);
  return yp_node_create_from_token(parser, YP_NODE_CONSTANT_READ_NODE, name);
}

// Allocate and initialize a new DefNode node.
static yp_node_t *
yp_def_node_create(
  yp_parser_t *parser,
  const yp_token_t *name,
  yp_node_t *receiver,
  yp_node_t *parameters,
  yp_node_t *statements,
  yp_node_t *scope,
  const yp_token_t *def_keyword,
  const yp_token_t *operator,
  const yp_token_t *lparen,
  const yp_token_t *rparen,
  const yp_token_t *equal,
  const yp_token_t *end_keyword
) {
  yp_def_node_t *node = YP_NODE_ALLOC(yp_def_node_t);
  const char *end;

  if (end_keyword->type == YP_TOKEN_NOT_PROVIDED) {
    end = statements->location.end;
  } else {
    end = end_keyword->end;
  }

  *node = (yp_def_node_t) {
    {
      .type = YP_NODE_DEF_NODE,
      .location = { .start = def_keyword->start, .end = end },
    },
    .name = *name,
    .receiver = receiver,
    .parameters = parameters,
    .statements = statements,
    .scope = scope,
    .def_keyword_loc = YP_LOCATION_TOKEN_VALUE(def_keyword),
    .operator_loc = YP_OPTIONAL_LOCATION_TOKEN_VALUE(operator),
    .lparen_loc = YP_OPTIONAL_LOCATION_TOKEN_VALUE(lparen),
    .rparen_loc = YP_OPTIONAL_LOCATION_TOKEN_VALUE(rparen),
    .equal_loc = YP_OPTIONAL_LOCATION_TOKEN_VALUE(equal),
    .end_keyword_loc = YP_OPTIONAL_LOCATION_TOKEN_VALUE(end_keyword)
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate a new DefinedNode node.
static yp_node_t *
yp_defined_node_create(yp_parser_t *parser, const yp_token_t *lparen, yp_node_t *value, const yp_token_t *rparen, const yp_location_t *keyword_loc) {
  yp_defined_node_t *node = YP_NODE_ALLOC(yp_defined_node_t);

  *node = (yp_defined_node_t) {
    {
      .type = YP_NODE_DEFINED_NODE,
      .location = {
        .start = keyword_loc->start,
        .end = (rparen->type == YP_TOKEN_NOT_PROVIDED ? value->location.end : rparen->end)
      },
    },
    .lparen = *lparen,
    .value = value,
    .rparen = *rparen,
    .keyword_loc = *keyword_loc
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new ElseNode node.
static yp_node_t *
yp_else_node_create(yp_parser_t *parser, const yp_token_t *else_keyword, yp_node_t *statements, const yp_token_t *end_keyword) {
  yp_else_node_t *node = YP_NODE_ALLOC(yp_else_node_t);

  *node = (yp_else_node_t) {
    {
      .type = YP_NODE_ELSE_NODE,
      .location = {
        .start = else_keyword->start,
        .end = end_keyword->type == YP_TOKEN_NOT_PROVIDED ? statements->location.end : end_keyword->end
      },
    },
    .else_keyword = *else_keyword,
    .statements = statements,
    .end_keyword = *end_keyword
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate a new EnsureNode node.
static yp_node_t *
yp_ensure_node_create(yp_parser_t *parser, const yp_token_t *ensure_keyword, yp_node_t *statements, const yp_token_t *end_keyword) {
  yp_ensure_node_t *node = YP_NODE_ALLOC(yp_ensure_node_t);

  *node = (yp_ensure_node_t) {
    {
      .type = YP_NODE_ENSURE_NODE,
      .location = {
        .start = ensure_keyword->start,
        .end = end_keyword->end
      },
    },
    .ensure_keyword = *ensure_keyword,
    .statements = statements,
    .end_keyword = *end_keyword
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new FalseNode node.
static yp_node_t *
yp_false_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_KEYWORD_FALSE);
  return yp_node_create_from_token(parser, YP_NODE_FALSE_NODE, token);
}

// Allocate and initialize a new find pattern node. The node list given in the
// nodes parameter is guaranteed to have at least two nodes.
static yp_node_t *
yp_find_pattern_node_create(yp_parser_t *parser, yp_node_list_t *nodes) {
  yp_find_pattern_node_t *node = YP_NODE_ALLOC(yp_find_pattern_node_t);

  *node = (yp_find_pattern_node_t) {
    {
      .type = YP_NODE_FIND_PATTERN_NODE,
      .location = {
        .start = nodes->nodes[0]->location.start,
        .end = nodes->nodes[nodes->size - 1]->location.end
      },
    },
    .constant = NULL,
    .left = nodes->nodes[0],
    .right = nodes->nodes[nodes->size - 1]
  };

  // For now we're going to just copy over each pointer manually. This could be
  // much more efficient, as we could instead resize the node list to only point
  // to 1...-1.
  yp_node_list_init(&node->requireds);
  for (size_t index = 1; index < nodes->size - 1; index++) {
    yp_node_list_append2(&node->requireds, nodes->nodes[index]);
  }

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new FloatNode node.
static yp_node_t *
yp_float_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_FLOAT);
  return yp_node_create_from_token(parser, YP_NODE_FLOAT_NODE, token);
}

// Allocate and initialize a new ForNode node.
static yp_node_t *
yp_for_node_create(
  yp_parser_t *parser,
  yp_node_t *index,
  yp_node_t *collection,
  yp_node_t *statements,
  const yp_token_t *for_keyword,
  const yp_token_t *in_keyword,
  const yp_token_t *do_keyword,
  const yp_token_t *end_keyword
) {
  yp_for_node_t *node = YP_NODE_ALLOC(yp_for_node_t);

  *node = (yp_for_node_t) {
    {
      .type = YP_NODE_FOR_NODE,
      .location = {
        .start = for_keyword->start,
        .end = end_keyword->end
      },
    },
    .index = index,
    .collection = collection,
    .statements = statements,
    .for_keyword_loc = YP_LOCATION_TOKEN_VALUE(for_keyword),
    .in_keyword_loc = YP_LOCATION_TOKEN_VALUE(in_keyword),
    .do_keyword_loc = YP_OPTIONAL_LOCATION_TOKEN_VALUE(do_keyword),
    .end_keyword_loc = YP_LOCATION_TOKEN_VALUE(end_keyword)
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new ForwardingArgumentsNode node.
static yp_node_t *
yp_forwarding_arguments_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_UDOT_DOT_DOT);
  return yp_node_create_from_token(parser, YP_NODE_FORWARDING_ARGUMENTS_NODE, token);
}

// Allocate and initialize a new ForwardingParameterNode node.
static yp_node_t *
yp_forwarding_parameter_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_UDOT_DOT_DOT);
  return yp_node_create_from_token(parser, YP_NODE_FORWARDING_PARAMETER_NODE, token);
}

// Allocate and initialize a new ForwardingSuper node.
static yp_node_t *
yp_forwarding_super_node_create(yp_parser_t *parser, const yp_token_t *token, yp_arguments_t *arguments) {
  assert(token->type == YP_TOKEN_KEYWORD_SUPER);
  yp_forwarding_super_node_t *node = YP_NODE_ALLOC(yp_forwarding_super_node_t);

  *node = (yp_forwarding_super_node_t) {
    {
      .type = YP_NODE_FORWARDING_SUPER_NODE,
      .location = {
        .start = token->start,
        .end = arguments->block != NULL ? arguments->block->location.end : token->end
      },
    },
    .block = arguments->block
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new hash pattern node from an opening and closing
// token.
static yp_node_t *
yp_hash_pattern_node_empty_create(yp_parser_t *parser, const yp_token_t *opening, const yp_token_t *closing) {
  yp_hash_pattern_node_t *node = YP_NODE_ALLOC(yp_hash_pattern_node_t);

  *node = (yp_hash_pattern_node_t) {
    {
      .type = YP_NODE_HASH_PATTERN_NODE,
      .location = {
        .start = opening->start,
        .end = closing->end
      },
    },
    .constant = NULL,
    .kwrest = NULL,
    .opening_loc = YP_LOCATION_TOKEN_VALUE(opening),
    .closing_loc = YP_LOCATION_TOKEN_VALUE(closing)
  };

  yp_node_list_init(&node->assocs);

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new hash pattern node.
static yp_node_t *
yp_hash_pattern_node_node_list_create(yp_parser_t *parser, yp_node_list_t *assocs) {
  yp_hash_pattern_node_t *node = YP_NODE_ALLOC(yp_hash_pattern_node_t);

  *node = (yp_hash_pattern_node_t) {
    {
      .type = YP_NODE_HASH_PATTERN_NODE,
      .location = {
        .start = assocs->nodes[0]->location.start,
        .end = assocs->nodes[assocs->size - 1]->location.end
      },
    },
    .constant = NULL,
    .kwrest = NULL
  };

  yp_node_list_init(&node->assocs);

  for (size_t index = 0; index < assocs->size; index++) {
    yp_node_t *assoc = assocs->nodes[index];
    yp_node_list_append2(&node->assocs, assoc);
  }

  return YP_NODE_DOWNCAST(node);
}

// Allocate a new GlobalVariableReadNode node.
static yp_node_t *
yp_global_variable_read_node_create(yp_parser_t *parser, const yp_token_t *name) {
  yp_global_variable_read_node_t *node = YP_NODE_ALLOC(yp_global_variable_read_node_t);

  *node = (yp_global_variable_read_node_t) {
    {
      .type = YP_NODE_GLOBAL_VARIABLE_READ_NODE,
      .location = YP_LOCATION_TOKEN_VALUE(name),
    },
    .name = *name
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate a new GlobalVariableWriteNode node.
static yp_node_t *
yp_global_variable_write_node_create(yp_parser_t *parser, const yp_token_t *name, const yp_token_t *operator, yp_node_t *value) {
  yp_global_variable_write_node_t *node = YP_NODE_ALLOC(yp_global_variable_write_node_t);

  *node = (yp_global_variable_write_node_t) {
    {
      .type = YP_NODE_GLOBAL_VARIABLE_WRITE_NODE,
      .location = {
        .start = name->start,
        .end = (value == NULL ? name->end : value->location.end)
      },
    },
    .name = *name,
    .operator = *operator,
    .value = value
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate a new HashNode node.
static yp_node_t *
yp_hash_node_create(yp_parser_t *parser, const yp_token_t *opening, const yp_token_t *closing) {
  yp_hash_node_t *node = YP_NODE_ALLOC(yp_hash_node_t);

  *node = (yp_hash_node_t) {
    {
      .type = YP_NODE_HASH_NODE,
      .location = {
        .start = (opening->type == YP_TOKEN_NOT_PROVIDED ? NULL : opening->start),
        .end = (closing->type == YP_TOKEN_NOT_PROVIDED ? NULL : closing->end)
      },
    },
    .opening = *opening,
    .closing = *closing
  };

  yp_node_list_init(&node->elements);
  return YP_NODE_DOWNCAST(node);
}

// Allocate a new HeredocNode node.
static yp_node_t *
yp_heredoc_node_create(yp_parser_t *parser, const yp_token_t *opening, const yp_token_t *closing, int dedent) {
  yp_heredoc_node_t *node = YP_NODE_ALLOC(yp_heredoc_node_t);

  *node = (yp_heredoc_node_t) {
    {
      .type = YP_NODE_HEREDOC_NODE,
      .location = {
        .start = opening->start,
        .end = closing->end
      },
    },
    .opening = *opening,
    .closing = *closing,
    .dedent = dedent
  };

  yp_node_list_init(&node->parts);
  return YP_NODE_DOWNCAST(node);
}

// Allocate a new IfNode node.
static yp_node_t *
yp_if_node_create(yp_parser_t *parser, const yp_token_t *if_keyword, yp_node_t *predicate, yp_node_t *statements, yp_node_t *consequent, const yp_token_t *end_keyword) {
  yp_if_node_t *node = YP_NODE_ALLOC(yp_if_node_t);

  const char *end;
  if (end_keyword->type != YP_TOKEN_NOT_PROVIDED) {
    end = end_keyword->end;
  } else if (consequent != NULL) {
    end = consequent->location.end;
  } else if (statements != NULL) {
    end = statements->location.end;
  } else {
    end = predicate->location.end;
  }

  *node = (yp_if_node_t) {
    {
      .type = YP_NODE_IF_NODE,
      .location = {
        .start = if_keyword->start,
        .end = end
      },
    },
    .if_keyword = *if_keyword,
    .predicate = predicate,
    .statements = statements,
    .consequent = consequent,
    .end_keyword = *end_keyword
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize an if node from a ternary expression.
static yp_node_t *
yp_if_node_ternary_create(yp_parser_t *parser, yp_node_t *predicate, const yp_token_t *question_mark, yp_node_t *true_expression, const yp_token_t *colon, yp_node_t *false_expression) {
  yp_node_t *if_statements = yp_statements_node_create(parser);
  yp_statements_node_body_append(if_statements, true_expression);

  yp_node_t *else_statements = yp_statements_node_create(parser);
  yp_statements_node_body_append(else_statements, false_expression);

  yp_token_t end_keyword = not_provided(parser);
  yp_node_t *else_node = yp_else_node_create(parser, colon, else_statements, &end_keyword);

  return yp_if_node_create(parser, question_mark, predicate, if_statements, else_node, &end_keyword);
}

// Allocate and initialize a new ImaginaryNode node.
static yp_node_t *
yp_imaginary_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_IMAGINARY_NUMBER);
  return yp_node_create_from_token(parser, YP_NODE_IMAGINARY_NODE, token);
}

// Allocate and initialize a new InNode node.
static yp_node_t *
yp_in_node_create(yp_parser_t *parser, yp_node_t *pattern, yp_node_t *statements, const yp_token_t *in_keyword, const yp_token_t *then_keyword) {
  yp_in_node_t *node = YP_NODE_ALLOC(yp_in_node_t);

  const char *end;
  if (then_keyword->type != YP_TOKEN_NOT_PROVIDED) {
    end = then_keyword->end;
  } else if (statements != NULL) {
    end = statements->location.end;
  } else {
    end = pattern->location.end;
  }

  *node = (yp_in_node_t) {
    {
      .type = YP_NODE_IN_NODE,
      .location = {
        .start = in_keyword->start,
        .end = end
      },
    },
    .pattern = pattern,
    .statements = statements,
    .in_loc = YP_LOCATION_TOKEN_VALUE(in_keyword),
    .then_loc = YP_OPTIONAL_LOCATION_TOKEN_VALUE(then_keyword)
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new InstanceVariableReadNode node.
static yp_node_t *
yp_instance_variable_read_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_INSTANCE_VARIABLE);
  return yp_node_create_from_token(parser, YP_NODE_INSTANCE_VARIABLE_READ_NODE, token);
}

// Initialize a new InstanceVariableWriteNode node from an InstanceVariableRead node.
static yp_node_t *
yp_instance_variable_write_node_create(yp_parser_t *parser, yp_node_t *node, yp_token_t *operator, yp_node_t *value) {
  assert(node->type == YP_NODE_INSTANCE_VARIABLE_READ_NODE);
  yp_instance_variable_write_node_t *write_node = YP_NODE_ALLOC(yp_instance_variable_write_node_t);
  *write_node = (yp_instance_variable_write_node_t) {
    {
      .location = node->location,
      .type = YP_NODE_INSTANCE_VARIABLE_WRITE_NODE
    },
    .name_loc = YP_LOCATION_NODE_VALUE(node),
    .operator_loc = YP_OPTIONAL_LOCATION_TOKEN_VALUE(operator),
  };

  if (value != NULL) {
    write_node->value = value;
    write_node->base.location.end = value->location.end;
  }

  return YP_NODE_DOWNCAST(write_node);
}

// Allocate and initialize a new IntegerNode node.
static yp_node_t *
yp_integer_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_INTEGER);
  return yp_node_create_from_token(parser, YP_NODE_INTEGER_NODE, token);
}

// Allocate a new InterpolatedRegularExpressionNode node.
static yp_node_t *
yp_interpolated_regular_expression_node_create(yp_parser_t *parser, const yp_token_t *opening, const yp_token_t *closing) {
  yp_interpolated_regular_expression_node_t *node = YP_NODE_ALLOC(yp_interpolated_regular_expression_node_t);

  *node = (yp_interpolated_regular_expression_node_t) {
    {
      .type = YP_NODE_INTERPOLATED_REGULAR_EXPRESSION_NODE,
      .location = {
        .start = opening->start,
        .end = closing->end
      },
    },
    .opening = *opening,
    .closing = *closing
  };

  yp_node_list_init(&node->parts);
  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new InterpolatedStringNode node.
static yp_node_t *
yp_interpolated_string_node_create(yp_parser_t *parser, const yp_token_t *opening, const yp_node_list_t *parts, const yp_token_t *closing) {
  yp_interpolated_string_node_t *node = YP_NODE_ALLOC(yp_interpolated_string_node_t);

  *node = (yp_interpolated_string_node_t) {
    {
      .type = YP_NODE_INTERPOLATED_STRING_NODE,
      .location = {
        .start = opening->start,
        .end = closing->end,
      },
    },
    .opening = *opening,
    .closing = *closing
  };

  if (parts == NULL) {
    yp_node_list_init(&node->parts);
  } else {
    node->parts = *parts;
  }

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new InterpolatedSymbolNode node.
static yp_node_t *
yp_interpolated_symbol_node_create(yp_parser_t *parser, const yp_token_t *opening, const yp_node_list_t *parts, const yp_token_t *closing) {
  yp_interpolated_symbol_node_t *node = YP_NODE_ALLOC(yp_interpolated_symbol_node_t);

  *node = (yp_interpolated_symbol_node_t) {
    {
      .type = YP_NODE_INTERPOLATED_SYMBOL_NODE,
      .location = {
        .start = opening->start,
        .end = closing->end,
      },
    },
    .opening = *opening,
    .closing = *closing
  };

  if (parts == NULL) {
    yp_node_list_init(&node->parts);
  }
  else {
    node->parts = *parts;
  }

  return YP_NODE_DOWNCAST(node);
}

// Allocate a new InterpolatedXStringNode node.
static yp_node_t *
yp_interpolated_xstring_node_create(yp_parser_t *parser, const yp_token_t *opening, const yp_token_t *closing) {
  yp_interpolated_x_string_node_t *node = YP_NODE_ALLOC(yp_interpolated_x_string_node_t);

  *node = (yp_interpolated_x_string_node_t) {
    {
      .type = YP_NODE_INTERPOLATED_X_STRING_NODE,
      .location = {
        .start = opening->start,
        .end = closing->end
      },
    },
    .opening = *opening,
    .closing = *closing
  };

  yp_node_list_init(&node->parts);
  return YP_NODE_DOWNCAST(node);
}

// Allocate a new KeywordParameterNode node.
static yp_node_t *
yp_keyword_parameter_node_create(yp_parser_t *parser, const yp_token_t *name, yp_node_t *value) {
  yp_keyword_parameter_node_t *node = YP_NODE_ALLOC(yp_keyword_parameter_node_t);

  *node = (yp_keyword_parameter_node_t) {
    {
      .type = YP_NODE_KEYWORD_PARAMETER_NODE,
      .location = {
        .start = name->start,
        .end = value == NULL ? name->end : value->location.end
      },
    },
    .name = *name,
    .value = value
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate a new KeywordRestParameterNode node.
static yp_node_t *
yp_keyword_rest_parameter_node_create(yp_parser_t *parser, const yp_token_t *operator, const yp_token_t *name) {
  yp_keyword_rest_parameter_node_t *node = YP_NODE_ALLOC(yp_keyword_rest_parameter_node_t);

  *node = (yp_keyword_rest_parameter_node_t) {
    {
      .type = YP_NODE_KEYWORD_REST_PARAMETER_NODE,
      .location = {
        .start = operator->start,
        .end = (name->type == YP_TOKEN_NOT_PROVIDED ? operator->end : name->end)
      },
    },
    .operator = *operator,
    .name = *name
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate a new LambdaNode node.
static yp_node_t *
yp_lambda_node_create(yp_parser_t *parser, yp_node_t *scope, const yp_token_t *opening, const yp_token_t *lparen, yp_node_t *parameters, const yp_token_t *rparen, yp_node_t *statements) {
  yp_lambda_node_t *node = YP_NODE_ALLOC(yp_lambda_node_t);

  const char *end;
  if (statements != NULL) {
    end = statements->location.end;
  } else if (rparen->type != YP_TOKEN_NOT_PROVIDED) {
    end = rparen->end;
  } else {
    end = opening->end;
  }

  *node = (yp_lambda_node_t) {
    {
      .type = YP_NODE_LAMBDA_NODE,
      .location = {
        .start = opening->start,
        .end = end
      },
    },
    .scope = scope,
    .opening = *opening,
    .lparen = *lparen,
    .parameters = parameters,
    .rparen = *rparen,
    .statements = statements
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate a new LocalVariableReadNode node.
static yp_node_t *
yp_local_variable_read_node_create(yp_parser_t *parser, const yp_token_t *name) {
  yp_local_variable_read_node_t *node = YP_NODE_ALLOC(yp_local_variable_read_node_t);

  *node = (yp_local_variable_read_node_t) {
    {
      .type = YP_NODE_LOCAL_VARIABLE_READ_NODE,
      .location = YP_LOCATION_TOKEN_VALUE(name),
    },
    .name = *name
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new LocalVariableWriteNode node.
static yp_node_t *
yp_local_variable_write_node_create(yp_parser_t *parser, const yp_token_t *name) {
  yp_local_variable_write_node_t *node = YP_NODE_ALLOC(yp_local_variable_write_node_t);

  *node = (yp_local_variable_write_node_t) {
    {
      .type = YP_NODE_LOCAL_VARIABLE_WRITE_NODE,
      .location = YP_LOCATION_TOKEN_VALUE(name),
    },
    .name = *name,
    .operator = not_provided(parser),
    .value = NULL
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new MatchPredicateNode node.
static yp_node_t *
yp_match_predicate_node_create(yp_parser_t *parser, yp_node_t *value, yp_node_t *pattern, const yp_token_t *operator) {
  yp_match_predicate_node_t *node = YP_NODE_ALLOC(yp_match_predicate_node_t);

  *node = (yp_match_predicate_node_t) {
    {
      .type = YP_NODE_MATCH_PREDICATE_NODE,
      .location = {
        .start = value->location.start,
        .end = pattern->location.end
      },
    },
    .value = value,
    .pattern = pattern,
    .operator_loc = YP_LOCATION_TOKEN_VALUE(operator)
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new MatchRequiredNode node.
static yp_node_t *
yp_match_required_node_create(yp_parser_t *parser, yp_node_t *value, yp_node_t *pattern, const yp_token_t *operator) {
  yp_match_required_node_t *node = YP_NODE_ALLOC(yp_match_required_node_t);

  *node = (yp_match_required_node_t) {
    {
      .type = YP_NODE_MATCH_REQUIRED_NODE,
      .location = {
        .start = value->location.start,
        .end = pattern->location.end
      },
    },
    .value = value,
    .pattern = pattern,
    .operator_loc = YP_LOCATION_TOKEN_VALUE(operator)
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate a new MissingNode node.
static yp_node_t *
yp_missing_node_create(yp_parser_t *parser, yp_location_t *location) {
  yp_node_t *node = YP_NODE_ALLOC(yp_node_t);
  *node = (yp_node_t) { .type = YP_NODE_MISSING_NODE, .location = *location };
  return YP_NODE_DOWNCAST(node);
}


// Allocate a new ModuleNode node.
static yp_node_t *
yp_module_node_create(yp_parser_t *parser, yp_node_t *scope, const yp_token_t *module_keyword, yp_node_t *constant_path, yp_node_t *statements, const yp_token_t *end_keyword) {
  yp_module_node_t *node = YP_NODE_ALLOC(yp_module_node_t);

  *node = (yp_module_node_t) {
    {
      .type = YP_NODE_MODULE_NODE,
      .location = {
        .start = module_keyword->start,
        .end = end_keyword->end
      },
    },
    .scope = scope,
    .module_keyword = *module_keyword,
    .constant_path = constant_path,
    .statements = statements,
    .end_keyword = *end_keyword
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate a new MultiWriteNode node.
static yp_node_t *
yp_multi_write_node_create(yp_parser_t *parser, const yp_token_t *operator, yp_node_t *value, const yp_location_t *lparen_loc, const yp_location_t *rparen_loc) {
  yp_multi_write_node_t *node = YP_NODE_ALLOC(yp_multi_write_node_t);

  *node = (yp_multi_write_node_t) {
    {
      .type = YP_NODE_MULTI_WRITE_NODE,
      .location = { .start = NULL, .end = NULL },
    },
    .operator = *operator,
    .value = value,
    .lparen_loc = *lparen_loc,
    .rparen_loc = *rparen_loc
  };

  yp_node_list_init(&node->targets);
  return YP_NODE_DOWNCAST(node);
}

// Append a target to a MultiWriteNode node.
static void
yp_multi_write_node_targets_append(yp_node_t *node, yp_node_t *target) {
  assert(node->type == YP_NODE_MULTI_WRITE_NODE);
  yp_multi_write_node_t *write_node = YP_NODE_UPCAST(node, yp_multi_write_node_t);

  yp_node_list_append2(&write_node->targets, target);

  if (write_node->base.location.start == NULL || (write_node->base.location.start > target->location.start)) {
    write_node->base.location.start = target->location.start;
  }

  if (write_node->base.location.end == NULL || (write_node->base.location.end < target->location.end)) {
    write_node->base.location.end = target->location.end;
  }
}

// Allocate and initialize a new NextNode node.
static yp_node_t *
yp_next_node_create(yp_parser_t *parser, const yp_token_t *keyword, yp_node_t *arguments) {
  assert(keyword->type == YP_TOKEN_KEYWORD_NEXT);
  yp_next_node_t *node = YP_NODE_ALLOC(yp_next_node_t);

  *node = (yp_next_node_t) {
    {
      .type = YP_NODE_NEXT_NODE,
      .location = {
        .start = keyword->start,
        .end = (arguments == NULL ? keyword->end : arguments->location.end)
      },
    },
    .keyword_loc = YP_LOCATION_TOKEN_VALUE(keyword),
    .arguments = arguments
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new NilNode node.
static yp_node_t *
yp_nil_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_KEYWORD_NIL);
  return yp_node_create_from_token(parser, YP_NODE_NIL_NODE, token);
}

// Allocate and initialize a new NoKeywordsParameterNode node.
static yp_node_t *
yp_no_keywords_parameter_node_create(yp_parser_t *parser, const yp_token_t *operator, const yp_token_t *keyword) {
  assert(operator->type == YP_TOKEN_USTAR_STAR);
  assert(keyword->type == YP_TOKEN_KEYWORD_NIL);
  yp_no_keywords_parameter_node_t *node = YP_NODE_ALLOC(yp_no_keywords_parameter_node_t);

  *node = (yp_no_keywords_parameter_node_t) {
    {
      .type = YP_NODE_NO_KEYWORDS_PARAMETER_NODE,
      .location = {
        .start = operator->start,
        .end = keyword->end
      },
    },
    .operator_loc = YP_LOCATION_TOKEN_VALUE(operator),
    .keyword_loc = YP_LOCATION_TOKEN_VALUE(keyword)
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new OperatorAndAssignmentNode node.
static yp_node_t *
yp_operator_and_assignment_node_create(yp_parser_t *parser, yp_node_t *target, const yp_token_t *operator, yp_node_t *value) {
  assert(operator->type == YP_TOKEN_AMPERSAND_AMPERSAND_EQUAL);
  yp_operator_and_assignment_node_t *node = YP_NODE_ALLOC(yp_operator_and_assignment_node_t);

  *node = (yp_operator_and_assignment_node_t) {
    {
      .type = YP_NODE_OPERATOR_AND_ASSIGNMENT_NODE,
      .location = {
        .start = target->location.start,
        .end = value->location.end
      },
    },
    .target = target,
    .value = value,
    .operator_loc = YP_LOCATION_TOKEN_VALUE(operator)
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate a new OperatorAssignmentNode node.
static yp_node_t *
yp_operator_assignment_node_create(yp_parser_t *parser, yp_node_t *target, const yp_token_t *operator, yp_node_t *value) {
  yp_operator_assignment_node_t *node = YP_NODE_ALLOC(yp_operator_assignment_node_t);

  *node = (yp_operator_assignment_node_t) {
    {
      .type = YP_NODE_OPERATOR_ASSIGNMENT_NODE,
      .location = {
        .start = target->location.start,
        .end = value->location.end
      },
    },
    .target = target,
    .operator = *operator,
    .value = value
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new OperatorOrAssignmentNode node.
static yp_node_t *
yp_operator_or_assignment_node_create(yp_parser_t *parser, yp_node_t *target, const yp_token_t *operator, yp_node_t *value) {
  assert(operator->type == YP_TOKEN_PIPE_PIPE_EQUAL);
  yp_operator_or_assignment_node_t *node = YP_NODE_ALLOC(yp_operator_or_assignment_node_t);

  *node = (yp_operator_or_assignment_node_t) {
    {
      .type = YP_NODE_OPERATOR_OR_ASSIGNMENT_NODE,
      .location = {
        .start = target->location.start,
        .end = value->location.end
      },
    },
    .target = target,
    .value = value,
    .operator_loc = YP_LOCATION_TOKEN_VALUE(operator)
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate a new OptionalParameterNode node.
static yp_node_t *
yp_optional_parameter_node_create(yp_parser_t *parser, const yp_token_t *name, const yp_token_t *equal_operator, yp_node_t *value) {
  yp_optional_parameter_node_t *node = YP_NODE_ALLOC(yp_optional_parameter_node_t);

  *node = (yp_optional_parameter_node_t) {
    {
      .type = YP_NODE_OPTIONAL_PARAMETER_NODE,
      .location = {
        .start = name->start,
        .end = value->location.end
      },
    },
    .name = *name,
    .equal_operator = *equal_operator,
    .value = value
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new OrNode node.
static yp_node_t *
yp_or_node_create(yp_parser_t *parser, yp_node_t *left, const yp_token_t *operator, yp_node_t *right) {
  yp_or_node_t *node = YP_NODE_ALLOC(yp_or_node_t);

  *node = (yp_or_node_t) {
    {
      .type = YP_NODE_OR_NODE,
      .location = {
        .start = left->location.start,
        .end = right->location.end
      },
    },
    .left = left,
    .right = right,
    .operator_loc = YP_LOCATION_TOKEN_VALUE(operator)
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new ParametersNode node.
static yp_node_t *
yp_parameters_node_create(yp_parser_t *parser) {
  yp_parameters_node_t *node = YP_NODE_ALLOC(yp_parameters_node_t);

  *node = (yp_parameters_node_t) {
    {
      .type = YP_NODE_PARAMETERS_NODE,
      .location = { .start = NULL, .end = NULL },
    },
    .rest = NULL,
    .keyword_rest = NULL,
    .block = NULL
  };

  yp_node_list_init(&node->requireds);
  yp_node_list_init(&node->optionals);
  yp_node_list_init(&node->keywords);

  return YP_NODE_DOWNCAST(node);
}

// Set the location properly for the parameters node.
static void
yp_parameters_node_location_set(yp_node_t *params, yp_node_t *param) {
  assert(params->type == YP_NODE_PARAMETERS_NODE);

  if (params->location.start == NULL) {
    params->location.start = param->location.start;
  } else {
    params->location.start = params->location.start < param->location.start ? params->location.start : param->location.start;
  }

  if (params->location.end == NULL) {
    params->location.end = param->location.end;
  } else {
    params->location.end = params->location.end > param->location.end ? params->location.end : param->location.end;
  }
}

// Append a required parameter to a ParametersNode node.
static void
yp_parameters_node_requireds_append(yp_node_t *params, yp_node_t *param) {
  assert(params->type == YP_NODE_PARAMETERS_NODE);
  yp_parameters_node_location_set(params, param);
  yp_node_list_append2(&YP_NODE_UPCAST(params, yp_parameters_node_t)->requireds, param);
}

// Append an optional parameter to a ParametersNode node.
static void
yp_parameters_node_optionals_append(yp_node_t *params, yp_node_t *param) {
  assert(params->type == YP_NODE_PARAMETERS_NODE);
  yp_parameters_node_location_set(params, param);
  yp_node_list_append2(&YP_NODE_UPCAST(params, yp_parameters_node_t)->optionals, param);
}

// Set the rest parameter on a ParametersNode node.
static void
yp_parameters_node_rest_set(yp_node_t *params, yp_node_t *param) {
  assert(params->type == YP_NODE_PARAMETERS_NODE);
  yp_parameters_node_location_set(params, param);
  YP_NODE_UPCAST(params, yp_parameters_node_t)->rest = param;
}

// Append a keyword parameter to a ParametersNode node.
static void
yp_parameters_node_keywords_append(yp_node_t *params, yp_node_t *param) {
  assert(params->type == YP_NODE_PARAMETERS_NODE);
  yp_parameters_node_location_set(params, param);
  yp_node_list_append2(&YP_NODE_UPCAST(params, yp_parameters_node_t)->keywords, param);
}

// Set the keyword rest parameter on a ParametersNode node.
static void
yp_parameters_node_keyword_rest_set(yp_node_t *params, yp_node_t *param) {
  assert(params->type == YP_NODE_PARAMETERS_NODE);
  yp_parameters_node_location_set(params, param);
  YP_NODE_UPCAST(params, yp_parameters_node_t)->keyword_rest = param;
}

// Set the block parameter on a ParametersNode node.
static void
yp_parameters_node_block_set(yp_node_t *params, yp_node_t *param) {
  assert(params->type == YP_NODE_PARAMETERS_NODE);
  yp_parameters_node_location_set(params, param);
  YP_NODE_UPCAST(params, yp_parameters_node_t)->block = param;
}

// Allocate a new ProgramNode node.
static yp_node_t *
yp_program_node_create(yp_parser_t *parser, yp_node_t *scope, yp_node_t *statements) {
  yp_program_node_t *node = YP_NODE_ALLOC(yp_program_node_t);

  *node = (yp_program_node_t) {
    {
      .type = YP_NODE_PROGRAM_NODE,
      .location = {
        .start = statements->location.start,
        .end = statements->location.end
      },
    },
    .scope = scope,
    .statements = statements
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize new ParenthesesNode node.
static yp_node_t *
yp_parentheses_node_create(yp_parser_t *parser, const yp_token_t *opening, yp_node_t *statements, const yp_token_t *closing) {
  yp_parentheses_node_t *node = YP_NODE_ALLOC(yp_parentheses_node_t);

  *node = (yp_parentheses_node_t) {
    {
      .type = YP_NODE_PARENTHESES_NODE,
      .location = {
        .start = opening->start,
        .end = closing->end
      },
    },
    .statements = statements,
    .opening_loc = YP_LOCATION_TOKEN_VALUE(opening),
    .closing_loc = YP_LOCATION_TOKEN_VALUE(closing)
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new PinnedExpressionNode node.
static yp_node_t *
yp_pinned_expression_node_create(yp_parser_t *parser, yp_node_t *expression, const yp_token_t *operator, const yp_token_t *lparen, const yp_token_t *rparen) {
  yp_pinned_expression_node_t *node = YP_NODE_ALLOC(yp_pinned_expression_node_t);

  *node = (yp_pinned_expression_node_t) {
    {
      .type = YP_NODE_PINNED_EXPRESSION_NODE,
      .location = {
        .start = operator->start,
        .end = rparen->end
      },
    },
    .expression = expression,
    .operator_loc = YP_LOCATION_TOKEN_VALUE(operator),
    .lparen_loc = YP_LOCATION_TOKEN_VALUE(lparen),
    .rparen_loc = YP_LOCATION_TOKEN_VALUE(rparen)
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new PinnedVariableNode node.
static yp_node_t *
yp_pinned_variable_node_create(yp_parser_t *parser, const yp_token_t *operator, yp_node_t *variable) {
  yp_pinned_variable_node_t *node = YP_NODE_ALLOC(yp_pinned_variable_node_t);

  *node = (yp_pinned_variable_node_t) {
    {
      .type = YP_NODE_PINNED_VARIABLE_NODE,
      .location = {
        .start = operator->start,
        .end = variable->location.end
      },
    },
    .variable = variable,
    .operator_loc = YP_LOCATION_TOKEN_VALUE(operator)
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new PostExecutionNode node.
static yp_node_t *
yp_post_execution_node_create(yp_parser_t *parser, const yp_token_t *keyword, const yp_token_t *opening, yp_node_t *statements, const yp_token_t *closing) {
  yp_post_execution_node_t *node = YP_NODE_ALLOC(yp_post_execution_node_t);

  *node = (yp_post_execution_node_t) {
    {
      .type = YP_NODE_POST_EXECUTION_NODE,
      .location = {
        .start = keyword->start,
        .end = closing->end
      },
    },
    .statements = statements,
    .keyword_loc = YP_LOCATION_TOKEN_VALUE(keyword),
    .opening_loc = YP_LOCATION_TOKEN_VALUE(opening),
    .closing_loc = YP_LOCATION_TOKEN_VALUE(closing)
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new PreExecutionNode node.
static yp_node_t *
yp_pre_execution_node_create(yp_parser_t *parser, const yp_token_t *keyword, const yp_token_t *opening, yp_node_t *statements, const yp_token_t *closing) {
  yp_pre_execution_node_t *node = YP_NODE_ALLOC(yp_pre_execution_node_t);

  *node = (yp_pre_execution_node_t) {
    {
      .type = YP_NODE_PRE_EXECUTION_NODE,
      .location = {
        .start = keyword->start,
        .end = closing->end
      },
    },
    .statements = statements,
    .keyword_loc = YP_LOCATION_TOKEN_VALUE(keyword),
    .opening_loc = YP_LOCATION_TOKEN_VALUE(opening),
    .closing_loc = YP_LOCATION_TOKEN_VALUE(closing)
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize new RangeNode node.
static yp_node_t *
yp_range_node_create(yp_parser_t *parser, yp_node_t *left, const yp_token_t *operator, yp_node_t *right) {
  yp_range_node_t *node = YP_NODE_ALLOC(yp_range_node_t);

  *node = (yp_range_node_t) {
    {
      .type = YP_NODE_RANGE_NODE,
      .location = {
        .start = (left == NULL ? operator->start : left->location.start),
        .end = (right == NULL ? operator->end : right->location.end)
      },
    },
    .left = left,
    .right = right,
    .operator_loc = YP_LOCATION_TOKEN_VALUE(operator),
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new RationalNode node.
static yp_node_t *
yp_rational_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_RATIONAL_NUMBER);
  return yp_node_create_from_token(parser, YP_NODE_RATIONAL_NODE, token);
}

// Allocate and initialize a new RedoNode node.
static yp_node_t *
yp_redo_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_KEYWORD_REDO);
  return yp_node_create_from_token(parser, YP_NODE_REDO_NODE, token);
}

// Allocate a new RegularExpressionNode node.
static yp_node_t *
yp_regular_expression_node_create(yp_parser_t *parser, const yp_token_t *opening, const yp_token_t *content, const yp_token_t *closing) {
  yp_regular_expression_node_t *node = YP_NODE_ALLOC(yp_regular_expression_node_t);

  *node = (yp_regular_expression_node_t) {
    {
      .type = YP_NODE_REGULAR_EXPRESSION_NODE,
      .location = {
        .start = opening->start,
        .end = closing->end
      },
    },
    .opening = *opening,
    .content = *content,
    .closing = *closing
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate a new RequiredDestructuredParameterNode node.
static yp_node_t *
yp_required_destructured_parameter_node_create(yp_parser_t *parser, const yp_token_t *opening, const yp_token_t *closing) {
  yp_required_destructured_parameter_node_t *node = YP_NODE_ALLOC(yp_required_destructured_parameter_node_t);

  *node = (yp_required_destructured_parameter_node_t) {
    {
      .type = YP_NODE_REQUIRED_DESTRUCTURED_PARAMETER_NODE,
      .location = {
        .start = NULL,
        .end = NULL
      },
    },
    .opening = *opening,
    .closing = *closing
  };

  yp_node_list_init(&node->parameters);
  return YP_NODE_DOWNCAST(node);
}

// Allocate a new RequiredParameterNode node.
static yp_node_t *
yp_required_parameter_node_create(yp_parser_t *parser, const yp_token_t *name) {
  yp_required_parameter_node_t *node = YP_NODE_ALLOC(yp_required_parameter_node_t);

  *node = (yp_required_parameter_node_t) {
    {
      .type = YP_NODE_REQUIRED_PARAMETER_NODE,
      .location = {
        .start = name->start,
        .end = name->end
      },
    },
    .name = *name
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate a new RescueModifierNode node.
static yp_node_t *
yp_rescue_modifier_node_create(yp_parser_t *parser, yp_node_t *expression, const yp_token_t *rescue_keyword, yp_node_t *rescue_expression) {
  yp_rescue_modifier_node_t *node = YP_NODE_ALLOC(yp_rescue_modifier_node_t);

  *node = (yp_rescue_modifier_node_t) {
    {
      .type = YP_NODE_RESCUE_MODIFIER_NODE,
      .location = {
        .start = expression->location.start,
        .end = rescue_expression->location.end
      },
    },
    .expression = expression,
    .rescue_keyword = *rescue_keyword,
    .rescue_expression = rescue_expression
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate a new RescueNode node.
static yp_node_t *
yp_rescue_node_create(yp_parser_t *parser, const yp_token_t *rescue_keyword) {
  yp_rescue_node_t *node = YP_NODE_ALLOC(yp_rescue_node_t);

  *node = (yp_rescue_node_t) {
    {
      .type = YP_NODE_RESCUE_NODE,
      .location = {
        .start = rescue_keyword->start,
        .end = rescue_keyword->end
      },
    },
    .rescue_keyword = *rescue_keyword,
    .equal_greater = YP_TOKEN_NOT_PROVIDED_VALUE(parser),
    .exception = NULL,
    .statements = NULL,
    .consequent = NULL
  };

  yp_node_list_init(&node->exceptions);
  return YP_NODE_DOWNCAST(node);
}

// Set the exception of a rescue node, and update the location of the node.
static void
yp_rescue_node_exception_set(yp_node_t *node, yp_node_t *exception) {
  assert(node->type == YP_NODE_RESCUE_NODE);
  yp_rescue_node_t *rescue_node = YP_NODE_UPCAST(node, yp_rescue_node_t);
  rescue_node->exception = exception;
  rescue_node->base.location.end = exception->location.end;
}

// Set the statements of a rescue node, and update the location of the node.
static void
yp_rescue_node_statements_set(yp_node_t *node, yp_node_t *statements) {
  assert(node->type == YP_NODE_RESCUE_NODE);
  yp_rescue_node_t *rescue_node = YP_NODE_UPCAST(node, yp_rescue_node_t);
  rescue_node->statements = statements;
  rescue_node->base.location.end = statements->location.end;
}

// Allocate a new RestParameterNode node.
static yp_node_t *
yp_rest_parameter_node_create(yp_parser_t *parser, const yp_token_t *operator, const yp_token_t *name) {
  yp_rest_parameter_node_t *node = YP_NODE_ALLOC(yp_rest_parameter_node_t);

  *node = (yp_rest_parameter_node_t) {
    {
      .type = YP_NODE_REST_PARAMETER_NODE,
      .location = {
        .start = operator->start,
        .end = (name->type == YP_TOKEN_NOT_PROVIDED ? operator->end : name->end)
      },
    },
    .operator = *operator,
    .name = *name
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new RetryNode node.
static yp_node_t *
yp_retry_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_KEYWORD_RETRY);
  return yp_node_create_from_token(parser, YP_NODE_RETRY_NODE, token);
}

// Allocate a new ReturnNode node.
static yp_node_t *
yp_return_node_create(yp_parser_t *parser, const yp_token_t *keyword, yp_node_t *arguments) {
  yp_return_node_t *node = YP_NODE_ALLOC(yp_return_node_t);

  *node = (yp_return_node_t) {
    {
      .type = YP_NODE_RETURN_NODE,
      .location = {
        .start = keyword->start,
        .end = (arguments == NULL ? keyword->end : arguments->location.end)
      },
    },
    .keyword = *keyword,
    .arguments = arguments
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new Scope node.
static yp_node_t *
yp_scope_node_create(yp_parser_t *parser, const yp_token_t *token) {
  yp_scope_node_t *node = YP_NODE_ALLOC(yp_scope_node_t);

  *node = (yp_scope_node_t) {
    {
      .type = YP_NODE_SCOPE_NODE,
      .location = YP_LOCATION_TOKEN_VALUE(token)
    },
  };

  yp_token_list_init(&node->locals);
  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new SelfNode node.
static yp_node_t *
yp_self_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_KEYWORD_SELF);
  return yp_node_create_from_token(parser, YP_NODE_SELF_NODE, token);
}

// Allocate a new SingletonClassNode node.
static yp_node_t *
yp_singleton_class_node_create(yp_parser_t *parser, yp_node_t *scope, const yp_token_t *class_keyword, const yp_token_t *operator, yp_node_t *expression, yp_node_t *statements, const yp_token_t *end_keyword) {
  yp_singleton_class_node_t *node = YP_NODE_ALLOC(yp_singleton_class_node_t);

  *node = (yp_singleton_class_node_t) {
    {
      .type = YP_NODE_SINGLETON_CLASS_NODE,
      .location = {
        .start = class_keyword->start,
        .end = end_keyword->end
      },
    },
    .scope = scope,
    .class_keyword = *class_keyword,
    .operator = *operator,
    .expression = expression,
    .statements = statements,
    .end_keyword = *end_keyword
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new SourceEncodingNode node.
static yp_node_t *
yp_source_encoding_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_KEYWORD___ENCODING__);
  return yp_node_create_from_token(parser, YP_NODE_SOURCE_ENCODING_NODE, token);
}

// Allocate and initialize a new SourceFileNode node.
static yp_node_t *
yp_source_file_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_KEYWORD___FILE__);
  return yp_node_create_from_token(parser, YP_NODE_SOURCE_FILE_NODE, token);
}

// Allocate and initialize a new SourceLineNode node.
static yp_node_t *
yp_source_line_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_KEYWORD___LINE__);
  return yp_node_create_from_token(parser, YP_NODE_SOURCE_LINE_NODE, token);
}

// Allocate a new SplatNode node.
static yp_node_t *
yp_splat_node_create(yp_parser_t *parser, const yp_token_t *operator, yp_node_t *expression) {
  yp_splat_node_t *node = YP_NODE_ALLOC(yp_splat_node_t);

  *node = (yp_splat_node_t) {
    {
      .type = YP_NODE_SPLAT_NODE,
      .location = {
        .start = operator->start,
        .end = (expression == NULL ? operator->end : expression->location.end)
      },
    },
    .operator = *operator,
    .expression = expression
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new StatementsNode node.
static yp_node_t *
yp_statements_node_create(yp_parser_t *parser) {
  yp_statements_node_t *node = YP_NODE_ALLOC(yp_statements_node_t);

  *node = (yp_statements_node_t) {
    {
      .type = YP_NODE_STATEMENTS_NODE,
      .location = YP_LOCATION_NULL_VALUE(parser)
    },
  };

  yp_node_list_init(&node->body);
  return YP_NODE_DOWNCAST(node);
}

// Get the length of the given StatementsNode node's body.
static size_t
yp_statements_node_body_length(yp_node_t *node) {
  return YP_NODE_UPCAST(node, yp_statements_node_t)->body.size;
}

// Set the location of the given StatementsNode.
static void
yp_statements_node_location_set(yp_node_t *node, const char *start, const char *end) {
  assert(node->type == YP_NODE_STATEMENTS_NODE);
  node->location = (yp_location_t) { .start = start, .end = end };
}

// Append a new node to the given StatementsNode node's body.
static void
yp_statements_node_body_append(yp_node_t *node, yp_node_t *statement) {
  if (yp_statements_node_body_length(node) == 0) {
    node->location.start = statement->location.start;
  }

  yp_node_list_append2(&YP_NODE_UPCAST(node, yp_statements_node_t)->body, statement);
  node->location.end = statement->location.end;
}

// IfNode modifier appears out of alphabetic order so it follows
// StatementsNode creation.
// Allocate and initialize new IfNode node in the modifier form.
static yp_node_t *
yp_if_node_modifier_create(yp_parser_t *parser, yp_node_t *statement, const yp_token_t *if_keyword, yp_node_t *predicate) {
  yp_if_node_t *node = YP_NODE_ALLOC(yp_if_node_t);

  yp_node_t *statements = yp_statements_node_create(parser);
  yp_statements_node_body_append(statements, statement);

  *node = (yp_if_node_t) {
    {
      .type = YP_NODE_IF_NODE,
      .location = {
        .start = statement->location.start,
        .end = predicate->location.end
      },
    },
    .if_keyword = *if_keyword,
    .predicate = predicate,
    .statements = (yp_node_t *)statements,
    .consequent = NULL,
    .end_keyword = not_provided(parser)
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate a new StringConcatNode node.
static yp_node_t *
yp_string_concat_node_create(yp_parser_t *parser, yp_node_t *left, yp_node_t *right) {
  yp_string_concat_node_t *node = YP_NODE_ALLOC(yp_string_concat_node_t);

  *node = (yp_string_concat_node_t) {
    {
      .type = YP_NODE_STRING_CONCAT_NODE,
      .location = {
        .start = left->location.start,
        .end = right->location.end
      },
    },
    .left = left,
    .right = right
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate a new StringInterpolatedNode node.
static yp_node_t *
yp_string_interpolated_node_create(yp_parser_t *parser, const yp_token_t *opening, yp_node_t *statements, const yp_token_t *closing) {
  yp_string_interpolated_node_t *node = YP_NODE_ALLOC(yp_string_interpolated_node_t);

  *node = (yp_string_interpolated_node_t) {
    {
      .type = YP_NODE_STRING_INTERPOLATED_NODE,
      .location = {
        .start = opening->start,
        .end = closing->end
      },
    },
    .opening = *opening,
    .statements = statements,
    .closing = *closing
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate a new StringNode node.
static yp_node_t *
yp_string_node_create(yp_parser_t *parser, const yp_token_t *opening, const yp_token_t *content, const yp_token_t *closing) {
  yp_string_node_t *node = YP_NODE_ALLOC(yp_string_node_t);

  *node = (yp_string_node_t) {
    {
      .type = YP_NODE_STRING_NODE,
      .location = {
        .start = (opening->type == YP_TOKEN_NOT_PROVIDED ? content->start : opening->start),
        .end = (closing->type == YP_TOKEN_NOT_PROVIDED ? content->end : closing->end)
      },
    },
    .opening = *opening,
    .content = *content,
    .closing = *closing
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new SuperNode node.
static yp_node_t *
yp_super_node_create(yp_parser_t *parser, const yp_token_t *keyword, yp_arguments_t *arguments) {
  assert(keyword->type == YP_TOKEN_KEYWORD_SUPER);
  yp_super_node_t *node = YP_NODE_ALLOC(yp_super_node_t);

  const char *end;
  if (arguments->block != NULL) {
    end = arguments->block->location.end;
  } else if (arguments->closing.type != YP_TOKEN_NOT_PROVIDED) {
    end = arguments->closing.end;
  } else if (arguments->arguments != NULL) {
    end = arguments->arguments->location.end;
  } else {
    assert(false && "unreachable");
  }

  *node = (yp_super_node_t) {
    {
      .type = YP_NODE_SUPER_NODE,
      .location = {
        .start = keyword->start,
        .end = end,
      },
    },
    .keyword = *keyword,
    .lparen = arguments->opening,
    .arguments = arguments->arguments,
    .rparen = arguments->closing,
    .block = arguments->block
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate a new SymbolNode node.
static yp_node_t *
yp_symbol_node_create(yp_parser_t *parser, const yp_token_t *opening, const yp_token_t *value, const yp_token_t *closing) {
  yp_symbol_node_t *node = YP_NODE_ALLOC(yp_symbol_node_t);

  *node = (yp_symbol_node_t) {
    {
      .type = YP_NODE_SYMBOL_NODE,
      .location = {
        .start = (opening->type == YP_TOKEN_NOT_PROVIDED ? value->start : opening->start),
        .end = (closing->type == YP_TOKEN_NOT_PROVIDED ? value->end : closing->end)
      },
    },
    .opening = *opening,
    .value = *value,
    .closing = *closing
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new SymbolNode node from a label.
static yp_node_t *
yp_symbol_node_label_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_LABEL || token->type == YP_TOKEN_MISSING);

  yp_token_t opening = not_provided(parser);
  yp_token_t label = { .type = YP_TOKEN_LABEL, .start = token->start, .end = token->end - 1 };
  yp_token_t closing = { .type = YP_TOKEN_LABEL_END, .start = label.end, .end = label.end + 1 };

  yp_node_t *node = yp_symbol_node_create(parser, &opening, &label, &closing);
  yp_unescape_manipulate_string(label.start, label.end - label.start, &YP_NODE_UPCAST(node, yp_symbol_node_t)->unescaped, YP_UNESCAPE_ALL, &parser->error_list);
  return node;
}

// Check if the given node is a label in a hash.
static bool
yp_symbol_node_label_p(yp_node_t *node) {
  return (
    (node->type == YP_NODE_SYMBOL_NODE && ((yp_symbol_node_t *)node)->closing.type == YP_TOKEN_LABEL_END) ||
    (node->type == YP_NODE_INTERPOLATED_SYMBOL_NODE && ((yp_interpolated_symbol_node_t *)node)->closing.type == YP_TOKEN_LABEL_END)
  );
}

// Create a StringNode from the given SymbolNode node.
static yp_node_t *
yp_symbol_node_to_string_node(yp_node_t *node) {
  yp_symbol_node_t *symbol_node = YP_NODE_UPCAST(node, yp_symbol_node_t);
  yp_string_node_t *result = YP_NODE_ALLOC(yp_string_node_t);
  *result = (yp_string_node_t) {
    {
      .location = symbol_node->base.location,
      .type = YP_NODE_STRING_NODE,
    },
    .opening = symbol_node->opening,
    .content = symbol_node->value,
    .closing = symbol_node->closing,
    .unescaped = symbol_node->unescaped
  };
  return YP_NODE_DOWNCAST(result);
}

// Allocate and initialize a new TrueNode node.
static yp_node_t *
yp_true_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_KEYWORD_TRUE);
  return yp_node_create_from_token(parser, YP_NODE_TRUE_NODE, token);
}

// Allocate and initialize a new UndefNode node.
static yp_node_t *
yp_undef_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_KEYWORD_UNDEF);
  yp_undef_node_t *node = YP_NODE_ALLOC(yp_undef_node_t);

  *node = (yp_undef_node_t) {
    {
      .type = YP_NODE_UNDEF_NODE,
      .location = YP_LOCATION_TOKEN_VALUE(token),
    },
    .keyword_loc = YP_LOCATION_TOKEN_VALUE(token)
  };

  yp_node_list_init(&node->names);
  return YP_NODE_DOWNCAST(node);
}

// Append a name to an undef node.
static void
yp_undef_node_append(yp_undef_node_t *node, yp_node_t *name) {
  node->base.location.end = name->location.end;
  yp_node_list_append2(&node->names, name);
}

// Allocate a new UnlessNode node.
static yp_node_t *
yp_unless_node_create(yp_parser_t *parser, const yp_token_t *keyword, yp_node_t *predicate, yp_node_t *statements, yp_node_t *consequent, const yp_token_t *end_keyword) {
  yp_unless_node_t *node = YP_NODE_ALLOC(yp_unless_node_t);

  const char *end;
  if (end_keyword->type != YP_TOKEN_NOT_PROVIDED) {
    end = end_keyword->end;
  } else if (consequent != NULL) {
    end = consequent->location.end;
  } else if (statements != NULL) {
    end = statements->location.end;
  } else {
    end = predicate->location.end;
  }

  *node = (yp_unless_node_t) {
    {
      .type = YP_NODE_UNLESS_NODE,
      .location = {
        .start = keyword->start,
        .end = end
      },
    },
    .keyword = *keyword,
    .predicate = predicate,
    .statements = statements,
    .consequent = consequent,
    .end_keyword = *end_keyword
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize new UnlessNode node in the modifier form.
static yp_node_t *
yp_unless_node_modifier_create(yp_parser_t *parser, yp_node_t *statement, const yp_token_t *unless_keyword, yp_node_t *predicate) {
  yp_unless_node_t *node = YP_NODE_ALLOC(yp_unless_node_t);

  yp_node_t *statements = yp_statements_node_create(parser);
  yp_statements_node_body_append(statements, statement);

  *node = (yp_unless_node_t) {
    {
      .type = YP_NODE_UNLESS_NODE,
      .location = {
        .start = statement->location.start,
        .end = predicate->location.end
      },
    },
    .keyword = *unless_keyword,
    .predicate = predicate,
    .statements = (yp_node_t *)statements,
    .consequent = NULL,
    .end_keyword = not_provided(parser)
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate a new UntilNode node.
static yp_node_t *
yp_until_node_create(yp_parser_t *parser, const yp_token_t *keyword, yp_node_t *predicate, yp_node_t *statements) {
  yp_until_node_t *node = YP_NODE_ALLOC(yp_until_node_t);

  *node = (yp_until_node_t) {
    {
      .type = YP_NODE_UNTIL_NODE,
      .location = {
        .start = keyword->start,
        .end = statements == NULL ? predicate->location.end : statements->location.end
      },
    },
    .keyword = *keyword,
    .predicate = predicate,
    .statements = statements
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate a new WhenNode node.
static yp_node_t *
yp_when_node_create(yp_parser_t *parser, const yp_token_t *when_keyword, yp_node_t *statements) {
  yp_when_node_t *node = YP_NODE_ALLOC(yp_when_node_t);

  *node = (yp_when_node_t) {
    {
      .type = YP_NODE_WHEN_NODE,
      .location = {
        .start = when_keyword->start,
        .end = (statements == NULL ? NULL : statements->location.end)
      },
    },
    .when_keyword = *when_keyword,
    .statements = statements
  };

  yp_node_list_init(&node->conditions);
  return YP_NODE_DOWNCAST(node);
}

// Allocate a new WhileNode node.
static yp_node_t *
yp_while_node_create(yp_parser_t *parser, const yp_token_t *keyword, yp_node_t *predicate, yp_node_t *statements) {
  yp_while_node_t *node = YP_NODE_ALLOC(yp_while_node_t);

  *node = (yp_while_node_t) {
    {
      .type = YP_NODE_WHILE_NODE,
      .location = {
        .start = keyword->start,
        .end = statements == NULL ? predicate->location.end : statements->location.end
      },
    },
    .keyword = *keyword,
    .predicate = predicate,
    .statements = statements
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate and initialize a new XStringNode node.
static yp_node_t *
yp_xstring_node_create(yp_parser_t *parser, const yp_token_t *opening, const yp_token_t *content, const yp_token_t *closing) {
  yp_x_string_node_t *node = YP_NODE_ALLOC(yp_x_string_node_t);

  *node = (yp_x_string_node_t) {
    {
      .type = YP_NODE_X_STRING_NODE,
      .location = {
        .start = opening->start,
        .end = closing->end
      },
    },
    .opening = *opening,
    .content = *content,
    .closing = *closing
  };

  return YP_NODE_DOWNCAST(node);
}

// Allocate a new YieldNode node.
static yp_node_t *
yp_yield_node_create(yp_parser_t *parser, const yp_token_t *keyword, const yp_token_t *lparen, yp_node_t *arguments, const yp_token_t *rparen) {
  yp_yield_node_t *node = YP_NODE_ALLOC(yp_yield_node_t);

  const char *end;
  if (rparen->type != YP_TOKEN_NOT_PROVIDED) {
    end = rparen->end;
  } else if (arguments != NULL) {
    end = arguments->location.end;
  } else if (lparen->type != YP_TOKEN_NOT_PROVIDED) {
    end = lparen->end;
  } else {
    end = keyword->end;
  }

  *node = (yp_yield_node_t) {
    {
      .type = YP_NODE_YIELD_NODE,
      .location = {
        .start = keyword->start,
        .end = end
      },
    },
    .keyword = *keyword,
    .lparen = *lparen,
    .arguments = arguments,
    .rparen = *rparen
  };

  return YP_NODE_DOWNCAST(node);
}

#undef YP_LOCATION_NULL_VALUE
#undef YP_LOCATION_TOKEN_VALUE
#undef YP_LOCATION_NODE_VALUE
#undef YP_TOKEN_NOT_PROVIDED_VALUE

/******************************************************************************/
/* Scope-related functions                                                    */
/******************************************************************************/

// Allocate and initialize a new scope. Push it onto the scope stack.
static void
yp_parser_scope_push(yp_parser_t *parser, const yp_token_t *token, bool top) {
  yp_node_t *node = yp_scope_node_create(parser, token);
  yp_scope_t *scope = (yp_scope_t *) malloc(sizeof(yp_scope_t));
  *scope = (yp_scope_t) { .node = node, .top = top, .previous = parser->current_scope };
  parser->current_scope = scope;
}

// Check if the current scope has a given local variables.
static bool
yp_parser_local_p(yp_parser_t *parser, yp_token_t *token) {
  yp_scope_t *scope = parser->current_scope;

  while (scope != NULL) {
    if (yp_token_list_includes(&YP_NODE_UPCAST(scope->node, yp_scope_node_t)->locals, token)) return true;
    if (scope->top) break;
    scope = scope->previous;
  }

  return false;
}

// Add a local variable to the current scope.
static void
yp_parser_local_add(yp_parser_t *parser, yp_token_t *token) {
  if (!yp_token_list_includes(&YP_NODE_UPCAST(parser->current_scope->node, yp_scope_node_t)->locals, token)) {
    yp_token_list_append(&YP_NODE_UPCAST(parser->current_scope->node, yp_scope_node_t)->locals, token);
  }
}

// Pop the current scope off the scope stack.
static void
yp_parser_scope_pop(yp_parser_t *parser) {
  yp_scope_t *scope = parser->current_scope;
  parser->current_scope = scope->previous;
  free(scope);
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
  if (*c == '_') {
    return 1;
  } else if (((unsigned char) *c) > 127) {
    return 1;
  } else {
    return parser->encoding.alpha_char(c);
  }
}

static inline size_t
char_is_identifier(yp_parser_t *parser, const char *c) {
  size_t width;

  if ((width = parser->encoding.alnum_char(c))) {
    return width;
  } else if (*c == '_') {
    return 1;
  } else if (((unsigned char) *c) > 127) {
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

#define BIT(c, idx) (((c) / 32 - 1 == idx) ? (1U << ((c) % 32)) : 0)
#define PUNCT(idx) ( \
        BIT('~', idx) | BIT('*', idx) | BIT('$', idx) | BIT('?', idx) | \
        BIT('!', idx) | BIT('@', idx) | BIT('/', idx) | BIT('\\', idx) | \
        BIT(';', idx) | BIT(',', idx) | BIT('.', idx) | BIT('=', idx) | \
        BIT(':', idx) | BIT('<', idx) | BIT('>', idx) | BIT('\"', idx) | \
        BIT('&', idx) | BIT('`', idx) | BIT('\'', idx) | BIT('+', idx) | \
        BIT('0', idx))

const unsigned int yp_global_name_punctuation_hash[(0x7e - 0x20 + 31) / 32] = { PUNCT(0), PUNCT(1), PUNCT(2) };

#undef BIT
#undef PUNCT

static inline bool
char_is_global_name_punctuation(const char c) {
  const unsigned int i = c;
  if (i <= 0x20 || 0x7e < i) return false;

  return (yp_global_name_punctuation_hash[(i - 0x20) / 32] >> (c % 32)) & 1;
}

static inline bool
token_is_numbered_parameter(yp_token_t *token) {
  return
    (token->type == YP_TOKEN_IDENTIFIER) &&
    (token->end - token->start == 2) &&
    (token->start[0] == '_') &&
    (char_is_decimal_number(token->start[1]));
}

/******************************************************************************/
/* Stack helpers                                                              */
/******************************************************************************/

static inline void
yp_accepts_block_stack_push(yp_parser_t *parser, bool value) {
  // Use the negation of the value to prevent stack overflow.
  yp_state_stack_push(&parser->accepts_block_stack, !value);
}

static inline void
yp_accepts_block_stack_pop(yp_parser_t *parser) {
  yp_state_stack_pop(&parser->accepts_block_stack);
}

static inline bool
yp_accepts_block_stack_p(yp_parser_t *parser) {
  return !yp_state_stack_p(&parser->accepts_block_stack);
}

/******************************************************************************/
/* Lexer check helpers                                                        */
/******************************************************************************/

// Get the next character in the source starting from parser->current.end and
// adding the given offset. If that position is beyond the end of the source
// then return '\0'.
static inline char
peek_at(yp_parser_t *parser, size_t offset) {
  if (parser->current.end + offset < parser->end) {
    return parser->current.end[offset];
  } else {
    return '\0';
  }
}

// Get the next character in the source starting from parser->current.end. If
// that position is beyond the end of the source then return '\0'.
static inline char
peek(yp_parser_t *parser) {
  if (parser->current.end < parser->end) {
    return *parser->current.end;
  } else {
    return '\0';
  }
}

// If the character to be read matches the given value, then returns true and
// advanced the current pointer.
static inline bool
match(yp_parser_t *parser, char value) {
  if (peek(parser) == value) {
    parser->current.end++;
    return true;
  }
  return false;
}

// Returns the incrementor character that should be used to increment the
// nesting count if one is possible.
static inline char
incrementor(const char start) {
  switch (start) {
    case '(':
    case '[':
    case '{':
    case '<':
      return start;
    default:
      return '\0';
  }
}

// Returns the matching character that should be used to terminate a list
// beginning with the given character.
static inline char
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
/* Encoding-related functions                                                 */
/******************************************************************************/

static yp_encoding_t yp_encoding_ascii = {
  .name = "ascii",
  .char_width = yp_encoding_ascii_char_width,
  .alnum_char = yp_encoding_ascii_alnum_char,
  .alpha_char = yp_encoding_ascii_alpha_char,
  .isupper_char = yp_encoding_ascii_isupper_char
};

static yp_encoding_t yp_encoding_ascii_8bit = {
  .name = "ascii-8bit",
  .char_width = yp_encoding_ascii_8_bit_char_width,
  .alnum_char = yp_encoding_ascii_alnum_char,
  .alpha_char = yp_encoding_ascii_alpha_char,
  .isupper_char = yp_encoding_ascii_isupper_char,
};

static yp_encoding_t yp_encoding_big5 = {
  .name = "big5",
  .char_width = yp_encoding_big5_char_width,
  .alnum_char = yp_encoding_big5_alnum_char,
  .alpha_char = yp_encoding_big5_alpha_char,
  .isupper_char = yp_encoding_big5_isupper_char
};

static yp_encoding_t yp_encoding_euc_jp = {
  .name = "euc-jp",
  .char_width = yp_encoding_euc_jp_char_width,
  .alnum_char = yp_encoding_euc_jp_alnum_char,
  .alpha_char = yp_encoding_euc_jp_alpha_char,
  .isupper_char = yp_encoding_euc_jp_isupper_char
};

static yp_encoding_t yp_encoding_iso_8859_1 = {
  .name = "iso-8859-1",
  .char_width = yp_encoding_iso_8859_1_char_width,
  .alnum_char = yp_encoding_iso_8859_1_alnum_char,
  .alpha_char = yp_encoding_iso_8859_1_alpha_char,
  .isupper_char = yp_encoding_iso_8859_1_isupper_char
};

static yp_encoding_t yp_encoding_iso_8859_2 = {
  .name = "iso-8859-2",
  .char_width = yp_encoding_iso_8859_2_char_width,
  .alnum_char = yp_encoding_iso_8859_2_alnum_char,
  .alpha_char = yp_encoding_iso_8859_2_alpha_char,
  .isupper_char = yp_encoding_iso_8859_2_isupper_char
};

static yp_encoding_t yp_encoding_iso_8859_3 = {
  .name = "iso-8859-3",
  .char_width = yp_encoding_iso_8859_3_char_width,
  .alnum_char = yp_encoding_iso_8859_3_alnum_char,
  .alpha_char = yp_encoding_iso_8859_3_alpha_char,
  .isupper_char = yp_encoding_iso_8859_3_isupper_char
};

static yp_encoding_t yp_encoding_iso_8859_4 = {
  .name = "iso-8859-4",
  .char_width = yp_encoding_iso_8859_4_char_width,
  .alnum_char = yp_encoding_iso_8859_4_alnum_char,
  .alpha_char = yp_encoding_iso_8859_4_alpha_char,
  .isupper_char = yp_encoding_iso_8859_4_isupper_char
};

static yp_encoding_t yp_encoding_iso_8859_5 = {
  .name = "iso-8859-5",
  .char_width = yp_encoding_iso_8859_5_char_width,
  .alnum_char = yp_encoding_iso_8859_5_alnum_char,
  .alpha_char = yp_encoding_iso_8859_5_alpha_char,
  .isupper_char = yp_encoding_iso_8859_5_isupper_char
};

static yp_encoding_t yp_encoding_iso_8859_6 = {
  .name = "iso-8859-6",
  .char_width = yp_encoding_iso_8859_6_char_width,
  .alnum_char = yp_encoding_iso_8859_6_alnum_char,
  .alpha_char = yp_encoding_iso_8859_6_alpha_char,
  .isupper_char = yp_encoding_iso_8859_6_isupper_char
};

static yp_encoding_t yp_encoding_iso_8859_7 = {
  .name = "iso-8859-7",
  .char_width = yp_encoding_iso_8859_7_char_width,
  .alnum_char = yp_encoding_iso_8859_7_alnum_char,
  .alpha_char = yp_encoding_iso_8859_7_alpha_char,
  .isupper_char = yp_encoding_iso_8859_7_isupper_char
};

static yp_encoding_t yp_encoding_iso_8859_8 = {
  .name = "iso-8859-8",
  .char_width = yp_encoding_iso_8859_8_char_width,
  .alnum_char = yp_encoding_iso_8859_8_alnum_char,
  .alpha_char = yp_encoding_iso_8859_8_alpha_char,
  .isupper_char = yp_encoding_iso_8859_8_isupper_char
};

static yp_encoding_t yp_encoding_iso_8859_9 = {
  .name = "iso-8859-9",
  .char_width = yp_encoding_iso_8859_9_char_width,
  .alnum_char = yp_encoding_iso_8859_9_alnum_char,
  .alpha_char = yp_encoding_iso_8859_9_alpha_char,
  .isupper_char = yp_encoding_iso_8859_9_isupper_char
};

static yp_encoding_t yp_encoding_iso_8859_10 = {
  .name = "iso-8859-10",
  .char_width = yp_encoding_iso_8859_10_char_width,
  .alnum_char = yp_encoding_iso_8859_10_alnum_char,
  .alpha_char = yp_encoding_iso_8859_10_alpha_char,
  .isupper_char = yp_encoding_iso_8859_10_isupper_char
};

static yp_encoding_t yp_encoding_iso_8859_11 = {
  .name = "iso-8859-11",
  .char_width = yp_encoding_iso_8859_11_char_width,
  .alnum_char = yp_encoding_iso_8859_11_alnum_char,
  .alpha_char = yp_encoding_iso_8859_11_alpha_char,
  .isupper_char = yp_encoding_iso_8859_11_isupper_char
};

static yp_encoding_t yp_encoding_iso_8859_13 = {
  .name = "iso-8859-13",
  .char_width = yp_encoding_iso_8859_13_char_width,
  .alnum_char = yp_encoding_iso_8859_13_alnum_char,
  .alpha_char = yp_encoding_iso_8859_13_alpha_char,
  .isupper_char = yp_encoding_iso_8859_13_isupper_char
};

static yp_encoding_t yp_encoding_iso_8859_14 = {
  .name = "iso-8859-14",
  .char_width = yp_encoding_iso_8859_14_char_width,
  .alnum_char = yp_encoding_iso_8859_14_alnum_char,
  .alpha_char = yp_encoding_iso_8859_14_alpha_char,
  .isupper_char = yp_encoding_iso_8859_14_isupper_char
};

static yp_encoding_t yp_encoding_iso_8859_15 = {
  .name = "iso-8859-15",
  .char_width = yp_encoding_iso_8859_15_char_width,
  .alnum_char = yp_encoding_iso_8859_15_alnum_char,
  .alpha_char = yp_encoding_iso_8859_15_alpha_char,
  .isupper_char = yp_encoding_iso_8859_15_isupper_char
};

static yp_encoding_t yp_encoding_iso_8859_16 = {
  .name = "iso-8859-16",
  .char_width = yp_encoding_iso_8859_16_char_width,
  .alnum_char = yp_encoding_iso_8859_16_alnum_char,
  .alpha_char = yp_encoding_iso_8859_16_alpha_char,
  .isupper_char = yp_encoding_iso_8859_16_isupper_char
};

static yp_encoding_t yp_encoding_shift_jis = {
  .name = "shift_jis",
  .char_width = yp_encoding_shift_jis_char_width,
  .alnum_char = yp_encoding_shift_jis_alnum_char,
  .alpha_char = yp_encoding_shift_jis_alpha_char,
  .isupper_char = yp_encoding_shift_jis_isupper_char
};

static yp_encoding_t yp_encoding_utf_8 = {
  .name = "utf-8",
  .char_width = yp_encoding_utf_8_char_width,
  .alnum_char = yp_encoding_utf_8_alnum_char,
  .alpha_char = yp_encoding_utf_8_alpha_char,
  .isupper_char = yp_encoding_utf_8_isupper_char
};

static yp_encoding_t yp_encoding_windows_31j = {
  .name = "windows-31j",
  .char_width = yp_encoding_windows_31j_char_width,
  .alnum_char = yp_encoding_windows_31j_alnum_char,
  .alpha_char = yp_encoding_windows_31j_alpha_char,
  .isupper_char = yp_encoding_windows_31j_isupper_char
};

static yp_encoding_t yp_encoding_windows_1251 = {
  .name = "windows-1251",
  .char_width = yp_encoding_windows_1251_char_width,
  .alnum_char = yp_encoding_windows_1251_alnum_char,
  .alpha_char = yp_encoding_windows_1251_alpha_char,
  .isupper_char = yp_encoding_windows_1251_isupper_char
};

static yp_encoding_t yp_encoding_windows_1252 = {
  .name = "windows-1252",
  .char_width = yp_encoding_windows_1252_char_width,
  .alnum_char = yp_encoding_windows_1252_alnum_char,
  .alpha_char = yp_encoding_windows_1252_alpha_char,
  .isupper_char = yp_encoding_windows_1252_isupper_char
};

// Here we're going to check if this is a "magic" comment, and perform whatever
// actions are necessary for it here.
static void
parser_lex_encoding_comment(yp_parser_t *parser) {
  const char *start = parser->current.start + 1;
  const char *end = memchr(start, '\n', parser->end - start);
  if (end == NULL) end = parser->end;

  // These are the patterns we're going to match to find the encoding comment.
  // This is definitely not complete or even really correct.
  const char *encoding_start = NULL;
  if ((encoding_start = strnstr(start, "coding:", end - start)) != NULL) {
    encoding_start += 7;
  } else if ((encoding_start = strnstr(start, "coding=", end - start)) != NULL) {
    encoding_start += 7;
  }

  // If we didn't find anything that matched our patterns, then return. Note
  // that this does a _very_ poor job of actually finding the encoding, and
  // there is a lot of work to do here to better reflect actual magic comment
  // parsing from CRuby, but this at least gets us part of the way there.
  if (encoding_start == NULL) return;

  // Skip any non-newline whitespace after the "coding:" or "coding=".
  encoding_start += yp_strspn_inline_whitespace(encoding_start, end - encoding_start);

  // Now determine the end of the encoding string. This is either the end of
  // the line, the first whitespace character, or a punctuation mark.
  const char *encoding_end = yp_strpbrk(encoding_start, " \t\f\r\v\n;,", end - encoding_start);
  encoding_end = encoding_end == NULL ? end : encoding_end;

  // Finally, we can determine the width of the encoding string.
  size_t width = encoding_end - encoding_start;

  // First, we're going to call out to a user-defined callback if one was
  // provided. If they return an encoding struct that we can use, then we'll
  // use that here.
  if (parser->encoding_decode_callback != NULL) {
    yp_encoding_t *encoding = parser->encoding_decode_callback(parser, encoding_start, width);

    if (encoding != NULL) {
      parser->encoding = *encoding;
      return;
    }
  }

  // Next, we're going to loop through each of the encodings that we handle
  // explicitly. If we found one that we understand, we'll use that value.
#define ENCODING(value, prebuilt) \
  if (width == sizeof(value) - 1 && strncasecmp(encoding_start, value, sizeof(value) - 1) == 0) { \
    parser->encoding = prebuilt; \
    if (parser->encoding_changed_callback != NULL) parser->encoding_changed_callback(parser); \
    return; \
  }

  // Check most common first. (This is pretty arbitrary.)
  ENCODING("utf-8", yp_encoding_utf_8);
  ENCODING("ascii", yp_encoding_ascii);
  ENCODING("ascii-8bit", yp_encoding_ascii_8bit);
  ENCODING("us-ascii", yp_encoding_ascii);
  ENCODING("binary", yp_encoding_ascii_8bit);
  ENCODING("shift_jis", yp_encoding_shift_jis);
  ENCODING("euc-jp", yp_encoding_euc_jp);

  // Then check all the others.
  ENCODING("big5", yp_encoding_big5);
  ENCODING("iso-8859-1", yp_encoding_iso_8859_1);
  ENCODING("iso-8859-2", yp_encoding_iso_8859_2);
  ENCODING("iso-8859-3", yp_encoding_iso_8859_3);
  ENCODING("iso-8859-4", yp_encoding_iso_8859_4);
  ENCODING("iso-8859-5", yp_encoding_iso_8859_5);
  ENCODING("iso-8859-6", yp_encoding_iso_8859_6);
  ENCODING("iso-8859-7", yp_encoding_iso_8859_7);
  ENCODING("iso-8859-8", yp_encoding_iso_8859_8);
  ENCODING("iso-8859-9", yp_encoding_iso_8859_9);
  ENCODING("iso-8859-10", yp_encoding_iso_8859_10);
  ENCODING("iso-8859-11", yp_encoding_iso_8859_11);
  ENCODING("iso-8859-13", yp_encoding_iso_8859_13);
  ENCODING("iso-8859-14", yp_encoding_iso_8859_14);
  ENCODING("iso-8859-15", yp_encoding_iso_8859_15);
  ENCODING("iso-8859-16", yp_encoding_iso_8859_16);
  ENCODING("windows-31j", yp_encoding_windows_31j);
  ENCODING("windows-1251", yp_encoding_windows_1251);
  ENCODING("windows-1252", yp_encoding_windows_1252);
  ENCODING("cp932", yp_encoding_windows_31j);

#undef ENCODING

  // If nothing was returned by this point, then we've got an issue because we
  // didn't understand the encoding that the user was trying to use. In this
  // case we'll keep using the default encoding but add an error to the
  // parser to indicate an unsuccessful parse.
  yp_diagnostic_list_append(&parser->error_list, encoding_start, encoding_end, "Could not understand the encoding specified in the magic comment.");
}

/******************************************************************************/
/* Context manipulations                                                      */
/******************************************************************************/

static bool
context_terminator(yp_context_t context, yp_token_t *token) {
  switch (context) {
    case YP_CONTEXT_MAIN:
    case YP_CONTEXT_DEF_PARAMS:
      return token->type == YP_TOKEN_EOF;
    case YP_CONTEXT_PREEXE:
    case YP_CONTEXT_POSTEXE:
      return token->type == YP_TOKEN_BRACE_RIGHT;
    case YP_CONTEXT_MODULE:
    case YP_CONTEXT_CLASS:
    case YP_CONTEXT_SCLASS:
    case YP_CONTEXT_LAMBDA_DO_END:
    case YP_CONTEXT_DEF:
    case YP_CONTEXT_BLOCK_KEYWORDS:
      return token->type == YP_TOKEN_KEYWORD_END || token->type == YP_TOKEN_KEYWORD_RESCUE || token->type == YP_TOKEN_KEYWORD_ENSURE;
    case YP_CONTEXT_WHILE:
    case YP_CONTEXT_UNTIL:
    case YP_CONTEXT_ELSE:
    case YP_CONTEXT_FOR:
    case YP_CONTEXT_ENSURE:
      return token->type == YP_TOKEN_KEYWORD_END;
    case YP_CONTEXT_CASE_WHEN:
      return token->type == YP_TOKEN_KEYWORD_WHEN || token->type == YP_TOKEN_KEYWORD_END || token->type == YP_TOKEN_KEYWORD_ELSE;
    case YP_CONTEXT_CASE_IN:
      return token->type == YP_TOKEN_KEYWORD_IN || token->type == YP_TOKEN_KEYWORD_END || token->type == YP_TOKEN_KEYWORD_ELSE;
    case YP_CONTEXT_IF:
    case YP_CONTEXT_ELSIF:
      return token->type == YP_TOKEN_KEYWORD_ELSE || token->type == YP_TOKEN_KEYWORD_ELSIF || token->type == YP_TOKEN_KEYWORD_END;
    case YP_CONTEXT_UNLESS:
      return token->type == YP_TOKEN_KEYWORD_ELSE || token->type == YP_TOKEN_KEYWORD_END;
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
    case YP_CONTEXT_LAMBDA_BRACES:
      return token->type == YP_TOKEN_BRACE_RIGHT;
    case YP_CONTEXT_PREDICATE:
      return token->type == YP_TOKEN_KEYWORD_THEN || token->type == YP_TOKEN_NEWLINE || token->type == YP_TOKEN_SEMICOLON;
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

static bool
context_p(yp_parser_t *parser, yp_context_t context) {
  yp_context_node_t *context_node = parser->current_context;

  while (context_node != NULL) {
    if (context_node->context == context) return true;
    context_node = context_node->prev;
  }

  return false;
}

static bool
context_def_p(yp_parser_t *parser) {
  yp_context_node_t *context_node = parser->current_context;

  while (context_node != NULL) {
    switch (context_node->context) {
      case YP_CONTEXT_DEF:
        return true;
      case YP_CONTEXT_CLASS:
      case YP_CONTEXT_MODULE:
      case YP_CONTEXT_SCLASS:
        return false;
      default:
        context_node = context_node->prev;
    }
  }

  return false;
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
    *parser->lex_modes.current = lex_mode;
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

typedef enum {
  YP_IGNORED_NEWLINE_NONE = 0,
  YP_IGNORED_NEWLINE_ALL,
  YP_IGNORED_NEWLINE_PATTERN
} yp_ignored_newline_type_t;

static inline yp_ignored_newline_type_t
lex_state_ignored_p(yp_parser_t *parser) {
  bool ignored = lex_state_p(parser, YP_LEX_STATE_BEG | YP_LEX_STATE_CLASS | YP_LEX_STATE_FNAME | YP_LEX_STATE_DOT) && !lex_state_p(parser, YP_LEX_STATE_LABELED);

  if (ignored) {
    return YP_IGNORED_NEWLINE_ALL;
  } else if (parser->lex_state == (YP_LEX_STATE_ARG | YP_LEX_STATE_LABELED)) {
    return YP_IGNORED_NEWLINE_PATTERN;
  } else {
    return YP_IGNORED_NEWLINE_NONE;
  }
}

static inline bool
lex_state_beg_p(yp_parser_t *parser) {
  return lex_state_p(parser, YP_LEX_STATE_BEG_ANY) || (parser->lex_state == (YP_LEX_STATE_ARG | YP_LEX_STATE_LABELED));
}

static inline bool
lex_state_arg_p(yp_parser_t *parser) {
  return lex_state_p(parser, YP_LEX_STATE_ARG_ANY);
}

static inline bool
lex_state_spcarg_p(yp_parser_t *parser, bool space_seen) {
  return lex_state_arg_p(parser) && space_seen && !char_is_whitespace(*parser->current.end);
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
  if (peek(parser) == '.') {
    if (char_is_decimal_number(peek_at(parser, 1))) {
      parser->current.end += 2;
      parser->current.end += yp_strspn_decimal_number(parser->current.end, parser->end - parser->current.end);
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
      parser->current.end += yp_strspn_decimal_number(parser->current.end, parser->end - parser->current.end);
      type = YP_TOKEN_FLOAT;
    } else {
      yp_diagnostic_list_append(&parser->error_list, parser->current.start, parser->current.end, "Missing exponent.");
      type = YP_TOKEN_FLOAT;
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
        if (char_is_decimal_number(*++parser->current.end)) {
          parser->current.end += yp_strspn_decimal_number(parser->current.end, parser->end - parser->current.end);
        } else {
          yp_diagnostic_list_append(&parser->error_list, parser->current.start, parser->current.end, "Invalid decimal number.");
        }

        break;

      // 0b1111 is a binary number
      case 'b':
      case 'B':
        if (char_is_binary_number(*++parser->current.end)) {
          parser->current.end += yp_strspn_binary_number(parser->current.end, parser->end - parser->current.end);
        } else {
          yp_diagnostic_list_append(&parser->error_list, parser->current.start, parser->current.end, "Invalid binary number.");
        }

        break;

      // 0o1111 is an octal number
      case 'o':
      case 'O':
        if (char_is_octal_number(*++parser->current.end)) {
          parser->current.end += yp_strspn_octal_number(parser->current.end, parser->end - parser->current.end);
        } else {
          yp_diagnostic_list_append(&parser->error_list, parser->current.start, parser->current.end, "Invalid octal number.");
        }

        break;

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
        parser->current.end += yp_strspn_octal_number(parser->current.end, parser->end - parser->current.end);
        break;

      // 0x1111 is a hexadecimal number
      case 'x':
      case 'X':
        if (char_is_hexadecimal_number(*++parser->current.end)) {
          parser->current.end += yp_strspn_hexidecimal_number(parser->current.end, parser->end - parser->current.end);
        } else {
          yp_diagnostic_list_append(&parser->error_list, parser->current.start, parser->current.end, "Invalid hexadecimal number.");
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
    parser->current.end += yp_strspn_decimal_number(parser->current.end, parser->end - parser->current.end);

    // Afterward, we'll lex as far as we can into an optional float suffix.
    type = lex_optional_float_suffix(parser);
  }

  // If the last character that we consumed was an underscore, then this is
  // actually an invalid integer value, and we should return an invalid token.
  if (parser->current.end[-1] == '_') {
    yp_diagnostic_list_append(&parser->error_list, parser->current.start, parser->current.end, "Number literal cannot end with a `_`.");
  }

  return type;
}

static yp_token_type_t
lex_numeric(yp_parser_t *parser) {
  yp_token_type_t type = YP_TOKEN_INTEGER;

  if (parser->current.end < parser->end) {
    type = lex_numeric_prefix(parser);
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

    case '0': {
      parser->current.end++;
      size_t width;

      if ((width = char_is_identifier(parser, parser->current.end)) > 0) {
        do {
          parser->current.end += width;
        } while (parser->current.end < parser->end && (width = char_is_identifier(parser, parser->current.end)) > 0);

        // $0 isn't allowed to be followed by anything.
        yp_diagnostic_list_append(&parser->error_list, parser->current.start, parser->current.end, "Invalid global variable.");
      }

      return YP_TOKEN_GLOBAL_VARIABLE;
    }

    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
      parser->current.end += yp_strspn_decimal_digit(parser->current.end, parser->end - parser->current.end);
      return lex_state_p(parser, YP_LEX_STATE_FNAME) ? YP_TOKEN_GLOBAL_VARIABLE : YP_TOKEN_NTH_REFERENCE;

    case '-':
      parser->current.end++;
      // fallthrough

    default: {
      size_t width;

      if ((width = char_is_identifier(parser, parser->current.end)) > 0) {
        do {
          parser->current.end += width;
        } while (parser->current.end < parser->end && (width = char_is_identifier(parser, parser->current.end)) > 0);
      } else {
        // If we get here, then we have a $ followed by something that isn't
        // recognized as a global variable.
        yp_diagnostic_list_append(&parser->error_list, parser->current.start, parser->current.end, "Invalid global variable.");
      }

      return YP_TOKEN_GLOBAL_VARIABLE;
    }
  }
}

// This function checks if the current token matches a keyword. If it does, it
// returns true. Otherwise, it returns false. The arguments are as follows:
//
// * `value` - the literal string that we're checking for
// * `width` - the length of the token
// * `state` - the state that we should transition to if the token matches
//
static yp_token_type_t
lex_keyword(yp_parser_t *parser, const char *value, yp_lex_state_t state, yp_token_type_t type, yp_token_type_t modifier_type) {
  yp_lex_state_t last_state = parser->lex_state;

  if (strncmp(parser->current.start, value, strlen(value)) == 0) {
    if (parser->lex_state & YP_LEX_STATE_FNAME) {
      lex_state_set(parser, YP_LEX_STATE_ENDFN);
    } else {
      lex_state_set(parser, state);
      if (state == YP_LEX_STATE_BEG) {
        parser->command_start = true;
      }

      if ((modifier_type != YP_TOKEN_EOF) && !(last_state & (YP_LEX_STATE_BEG | YP_LEX_STATE_LABELED | YP_LEX_STATE_CLASS))) {
        lex_state_set(parser, YP_LEX_STATE_BEG | YP_LEX_STATE_LABEL);
        return modifier_type;
      }
    }

    return type;
  }

  return YP_TOKEN_EOF;
}

static yp_token_type_t
lex_identifier(yp_parser_t *parser, bool previous_command_start) {
  // Lex as far as we can into the current identifier.
  size_t width;
  while (parser->current.end < parser->end && (width = char_is_identifier(parser, parser->current.end)) > 0) {
    parser->current.end += width;
  }

  // Now cache the length of the identifier so that we can quickly compare it
  // against known keywords.
  width = parser->current.end - parser->current.start;

  if (parser->current.end < parser->end) {
    if (((parser->current.end + 1 >= parser->end) || (parser->current.end[1] != '=')) && (match(parser, '!') || match(parser, '?'))) {
      // First we'll attempt to extend the identifier by a ! or ?. Then we'll
      // check if we're returning the defined? keyword or just an identifier.
      width++;

      if (
        ((lex_state_p(parser, YP_LEX_STATE_LABEL | YP_LEX_STATE_ENDFN) && !previous_command_start) || lex_state_arg_p(parser)) &&
        (peek(parser) == ':') && (peek_at(parser, 1) != ':')
      ) {
        // If we're in a position where we can accept a : at the end of an
        // identifier, then we'll optionally accept it.
        lex_state_set(parser, YP_LEX_STATE_ARG | YP_LEX_STATE_LABELED);
        (void) match(parser, ':');
        return YP_TOKEN_LABEL;
      }

      if (parser->lex_state != YP_LEX_STATE_DOT) {
        if (width == 8 && (lex_keyword(parser, "defined?", YP_LEX_STATE_ARG, YP_TOKEN_KEYWORD_DEFINED, YP_TOKEN_EOF) != YP_TOKEN_EOF)) {
          return YP_TOKEN_KEYWORD_DEFINED;
        }
      }

      return YP_TOKEN_IDENTIFIER;
    } else if (lex_state_p(parser, YP_LEX_STATE_FNAME) && peek_at(parser, 1) != '~' && peek_at(parser, 1) != '>' && (peek_at(parser, 1) != '=' || peek_at(parser, 2) == '>') && match(parser, '=')) {
      // If we're in a position where we can accept a = at the end of an
      // identifier, then we'll optionally accept it.
      return YP_TOKEN_IDENTIFIER;
    }

    if (
      ((lex_state_p(parser, YP_LEX_STATE_LABEL | YP_LEX_STATE_ENDFN) && !previous_command_start) || lex_state_arg_p(parser)) &&
      parser->current.end[0] == ':' && parser->current.end[1] != ':'
    ) {
      // If we're in a position where we can accept a : at the end of an
      // identifier, then we'll optionally accept it.
      lex_state_set(parser, YP_LEX_STATE_ARG | YP_LEX_STATE_LABELED);
      (void) match(parser, ':');
      return YP_TOKEN_LABEL;
    }
  }

  if (parser->lex_state != YP_LEX_STATE_DOT) {
    yp_token_type_t type;

    switch (width) {
      case 2:
        if (lex_keyword(parser, "do", YP_LEX_STATE_BEG, YP_TOKEN_KEYWORD_DO, YP_TOKEN_EOF) != YP_TOKEN_EOF) {
          if (yp_state_stack_p(&parser->do_loop_stack)) {
            return YP_TOKEN_KEYWORD_DO_LOOP;
          }
          return YP_TOKEN_KEYWORD_DO;
        }

        if ((type = lex_keyword(parser, "if", YP_LEX_STATE_BEG, YP_TOKEN_KEYWORD_IF, YP_TOKEN_KEYWORD_IF_MODIFIER)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "in", YP_LEX_STATE_BEG, YP_TOKEN_KEYWORD_IN, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "or", YP_LEX_STATE_BEG, YP_TOKEN_KEYWORD_OR, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        break;
      case 3:
        if ((type = lex_keyword(parser, "and", YP_LEX_STATE_BEG, YP_TOKEN_KEYWORD_AND, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "def", YP_LEX_STATE_FNAME, YP_TOKEN_KEYWORD_DEF, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "end", YP_LEX_STATE_END, YP_TOKEN_KEYWORD_END, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "END", YP_LEX_STATE_END, YP_TOKEN_KEYWORD_END_UPCASE, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "for", YP_LEX_STATE_BEG, YP_TOKEN_KEYWORD_FOR, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "nil", YP_LEX_STATE_END, YP_TOKEN_KEYWORD_NIL, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "not", YP_LEX_STATE_ARG, YP_TOKEN_KEYWORD_NOT, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        break;
      case 4:
        if ((type = lex_keyword(parser, "case", YP_LEX_STATE_BEG, YP_TOKEN_KEYWORD_CASE, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "else", YP_LEX_STATE_BEG, YP_TOKEN_KEYWORD_ELSE, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "next", YP_LEX_STATE_MID, YP_TOKEN_KEYWORD_NEXT, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "redo", YP_LEX_STATE_END, YP_TOKEN_KEYWORD_REDO, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "self", YP_LEX_STATE_END, YP_TOKEN_KEYWORD_SELF, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "then", YP_LEX_STATE_BEG, YP_TOKEN_KEYWORD_THEN, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "true", YP_LEX_STATE_END, YP_TOKEN_KEYWORD_TRUE, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "when", YP_LEX_STATE_BEG, YP_TOKEN_KEYWORD_WHEN, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        break;
      case 5:
        if ((type = lex_keyword(parser, "alias", YP_LEX_STATE_FNAME | YP_LEX_STATE_FITEM, YP_TOKEN_KEYWORD_ALIAS, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "begin", YP_LEX_STATE_BEG, YP_TOKEN_KEYWORD_BEGIN, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "BEGIN", YP_LEX_STATE_END, YP_TOKEN_KEYWORD_BEGIN_UPCASE, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "break", YP_LEX_STATE_MID, YP_TOKEN_KEYWORD_BREAK, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "class", YP_LEX_STATE_CLASS, YP_TOKEN_KEYWORD_CLASS, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "elsif", YP_LEX_STATE_BEG, YP_TOKEN_KEYWORD_ELSIF, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "false", YP_LEX_STATE_END, YP_TOKEN_KEYWORD_FALSE, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "retry", YP_LEX_STATE_END, YP_TOKEN_KEYWORD_RETRY, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "super", YP_LEX_STATE_ARG, YP_TOKEN_KEYWORD_SUPER, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "undef", YP_LEX_STATE_FNAME | YP_LEX_STATE_FITEM, YP_TOKEN_KEYWORD_UNDEF, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "until", YP_LEX_STATE_BEG, YP_TOKEN_KEYWORD_UNTIL, YP_TOKEN_KEYWORD_UNTIL_MODIFIER)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "while", YP_LEX_STATE_BEG, YP_TOKEN_KEYWORD_WHILE, YP_TOKEN_KEYWORD_WHILE_MODIFIER)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "yield", YP_LEX_STATE_ARG, YP_TOKEN_KEYWORD_YIELD, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        break;
      case 6:
        if ((type = lex_keyword(parser, "ensure", YP_LEX_STATE_BEG, YP_TOKEN_KEYWORD_ENSURE, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "module", YP_LEX_STATE_BEG, YP_TOKEN_KEYWORD_MODULE, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "rescue", YP_LEX_STATE_MID, YP_TOKEN_KEYWORD_RESCUE, YP_TOKEN_KEYWORD_RESCUE_MODIFIER)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "return", YP_LEX_STATE_MID, YP_TOKEN_KEYWORD_RETURN, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "unless", YP_LEX_STATE_BEG, YP_TOKEN_KEYWORD_UNLESS, YP_TOKEN_KEYWORD_UNLESS_MODIFIER)) != YP_TOKEN_EOF) return type;
        break;
      case 8:
        if ((type = lex_keyword(parser, "__LINE__", YP_LEX_STATE_END, YP_TOKEN_KEYWORD___LINE__, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        if ((type = lex_keyword(parser, "__FILE__", YP_LEX_STATE_END, YP_TOKEN_KEYWORD___FILE__, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        break;
      case 12:
        if ((type = lex_keyword(parser, "__ENCODING__", YP_LEX_STATE_END, YP_TOKEN_KEYWORD___ENCODING__, YP_TOKEN_EOF)) != YP_TOKEN_EOF) return type;
        break;
    }
  }

  return parser->encoding.isupper_char(parser->current.start) ? YP_TOKEN_CONSTANT : YP_TOKEN_IDENTIFIER;
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
        if (pound > parser->current.start) {
          parser->current.end = pound;
          return YP_TOKEN_STRING_CONTENT;
        }

        // Otherwise we need to return the embedded variable token
        // and then switch to the embedded variable lex mode.
        lex_mode_push(parser, (yp_lex_mode_t) { .mode = YP_LEX_EMBVAR });
        parser->current.end = pound + 1;
        return YP_TOKEN_EMBVAR;
      }

      // If we didn't get an valid interpolation, then this is just regular
      // string content. This is like if we get "#@-". In this case the caller
      // should keep lexing.
      parser->current.end = variable;
      return YP_TOKEN_NOT_PROVIDED;
    }
    case '$':
      // In this case we may have hit an embedded global variable. If there's
      // not enough room, then we'll just return string content.
      if (pound + 2 >= parser->end) {
        parser->current.end = pound + 1;
        return YP_TOKEN_STRING_CONTENT;
      }

      // This is the character that we're going to check to see if it is the
      // start of an identifier that would indicate that this is a global
      // variable.
      const char *check = pound + 2;

      if (pound[2] == '-') {
        if (pound + 3 >= parser->end) {
          parser->current.end = pound + 2;
          return YP_TOKEN_STRING_CONTENT;
        }

        check++;
      }

      // If the character that we're going to check is the start of an
      // identifier, or we don't have a - and the character is a decimal number
      // or a global name punctuation character, then we've hit an embedded
      // global variable.
      if (
        char_is_identifier_start(parser, check) ||
        (pound[2] != '-' && (char_is_decimal_number(pound[2]) || char_is_global_name_punctuation(pound[2])))
      ) {
        // In this case we've hit an embedded global variable. First check to
        // see if we've already consumed content. If we have, then we need to
        // return that content as string content first.
        if (pound > parser->current.start) {
          parser->current.end = pound;
          return YP_TOKEN_STRING_CONTENT;
        }

        // Otherwise, we need to return the embedded variable token and switch
        // to the embedded variable lex mode.
        lex_mode_push(parser, (yp_lex_mode_t) { .mode = YP_LEX_EMBVAR });
        parser->current.end = pound + 1;
        return YP_TOKEN_EMBVAR;
      }

      // In this case we've hit a #$ that does not indicate a global variable.
      // In this case we'll continue lexing past it.
      parser->current.end = pound + 1;
      return YP_TOKEN_NOT_PROVIDED;
    case '{':
      // In this case it's the start of an embedded expression. If we have
      // already consumed content, then we need to return that content as string
      // content first.
      if (pound > parser->current.start) {
        parser->current.end = pound;
        return YP_TOKEN_STRING_CONTENT;
      }

      parser->enclosure_nesting++;

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
  if (lex_state_end_p(parser)) {
    lex_state_set(parser, YP_LEX_STATE_BEG);
    return YP_TOKEN_QUESTION_MARK;
  }

  if (parser->current.end >= parser->end) {
    yp_diagnostic_list_append(&parser->error_list, parser->current.start, parser->current.end, "Incomplete character syntax.");
    return YP_TOKEN_CHARACTER_LITERAL;
  }

  if (char_is_whitespace(*parser->current.end)) {
    lex_state_set(parser, YP_LEX_STATE_BEG);
    return YP_TOKEN_QUESTION_MARK;
  }

  lex_state_set(parser, YP_LEX_STATE_END);

  if (parser->current.start[1] == '\\') {
    parser->current.end += yp_unescape_calculate_difference(parser->current.start + 1, parser->end - parser->current.start + 1, YP_UNESCAPE_ALL, &parser->error_list);
  } else {
    parser->current.end += parser->encoding.char_width(parser->current.end);
  }

  return YP_TOKEN_CHARACTER_LITERAL;
}

// Lex a variable that starts with an @ sign (either an instance or class
// variable).
static yp_token_type_t
lex_at_variable(yp_parser_t *parser) {
  yp_token_type_t type = match(parser, '@') ? YP_TOKEN_CLASS_VARIABLE : YP_TOKEN_INSTANCE_VARIABLE;
  size_t width;

  if (parser->current.end < parser->end && (width = char_is_identifier_start(parser, parser->current.end)) > 0) {
    parser->current.end += width;

    while (parser->current.end < parser->end && (width = char_is_identifier(parser, parser->current.end)) > 0) {
      parser->current.end += width;
    }
  } else if (type == YP_TOKEN_CLASS_VARIABLE) {
    yp_diagnostic_list_append(&parser->error_list, parser->current.start, parser->current.end, "Incomplete class variable.");
  } else {
    yp_diagnostic_list_append(&parser->error_list, parser->current.start, parser->current.end, "Incomplete instance variable.");
  }

  // If we're lexing an embedded variable, then we need to pop back into the
  // parent lex context.
  if (parser->lex_modes.current->mode == YP_LEX_EMBVAR) {
    lex_mode_pop(parser);
  }

  return type;
}

// Optionally call out to the lex callback if one is provided.
static inline void
parser_lex_callback(yp_parser_t *parser) {
  if (parser->lex_callback) {
    parser->lex_callback->callback(parser->lex_callback->data, parser, &parser->current);
  }
}

// Return a new comment node of the specified type.
static inline yp_comment_t *
parser_comment(yp_parser_t *parser, yp_comment_type_t type) {
  yp_comment_t *comment = (yp_comment_t *) malloc(sizeof(yp_comment_t));
  *comment = (yp_comment_t) {
    .type = type,
    .start = parser->current.start,
    .end = parser->current.end
  };

  return comment;
}

// Lex out embedded documentation, and return when we have either hit the end of
// the file or the end of the embedded documentation. This calls the callback
// manually because only the lexer should see these tokens, not the parser.
static yp_token_type_t
lex_embdoc(yp_parser_t *parser) {
  // First, lex out the EMBDOC_BEGIN token.
  const char *newline = memchr(parser->current.end, '\n', parser->end - parser->current.end);
  parser->current.end = newline == NULL ? parser->end : newline + 1;
  parser->current.type = YP_TOKEN_EMBDOC_BEGIN;
  parser_lex_callback(parser);

  // Now, create a comment that is going to be attached to the parser.
  yp_comment_t *comment = parser_comment(parser, YP_COMMENT_EMBDOC);

  // Now, loop until we find the end of the embedded documentation or the end of
  // the file.
  while (parser->current.end + 5 < parser->end) {
    parser->current.start = parser->current.end;

    // If we've hit the end of the embedded documentation then we'll return that
    // token here.
    if (strncmp(parser->current.end, "=end", 4) == 0 && char_is_whitespace(parser->current.end[4])) {
      const char *newline = memchr(parser->current.end, '\n', parser->end - parser->current.end);
      parser->current.end = newline == NULL ? parser->end : newline + 1;
      parser->current.type = YP_TOKEN_EMBDOC_END;
      parser_lex_callback(parser);

      comment->end = parser->current.end;
      yp_list_append(&parser->comment_list, (yp_list_node_t *) comment);

      return YP_TOKEN_EMBDOC_END;
    }

    // Otherwise, we'll parse until the end of the line and return a line of
    // embedded documentation.
    const char *newline = memchr(parser->current.end, '\n', parser->end - parser->current.end);
    parser->current.end = newline == NULL ? parser->end : newline + 1;
    parser->current.type = YP_TOKEN_EMBDOC_LINE;
    parser_lex_callback(parser);
  }

  yp_diagnostic_list_append(&parser->error_list, parser->current.start, parser->current.end, "Unterminated embdoc");

  comment->end = parser->current.end;
  yp_list_append(&parser->comment_list, (yp_list_node_t *) comment);

  return YP_TOKEN_EOF;
}

// Set the current type to an ignored newline and then call the lex callback.
// This happens in a couple places depending on whether or not we have already
// lexed a comment.
static inline void
parser_lex_ignored_newline(yp_parser_t *parser) {
  parser->current.type = YP_TOKEN_IGNORED_NEWLINE;
  parser_lex_callback(parser);
}

// This is a convenience macro that will set the current token type, call the
// lex callback, and then return from the parser_lex function.
#define LEX(token_type) parser->current.type = token_type; parser_lex_callback(parser); return

// Called when the parser requires a new token. The parser maintains a moving
// window of two tokens at a time: parser.previous and parser.current. This
// function will move the current token into the previous token and then
// lex a new token into the current token.
static void
parser_lex(yp_parser_t *parser) {
  assert(parser->current.end <= parser->end);
  parser->previous = parser->current;

  // This value mirrors cmd_state from CRuby.
  bool previous_command_start = parser->command_start;
  parser->command_start = false;

  // This is used to communicate to the newline lexing function that we've
  // already seen a comment.
  bool lexed_comment = false;

  switch (parser->lex_modes.current->mode) {
    case YP_LEX_DEFAULT:
    case YP_LEX_EMBEXPR:
    case YP_LEX_EMBVAR:

    // We have a specific named label here because we are going to jump back to
    // this location in the event that we have lexed a token that should not be
    // returned to the parser. This includes comments, ignored newlines, and
    // invalid tokens of some form.
    lex_next_token: {
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
      while (parser->current.end < parser->end && chomping) {
        switch (*parser->current.end) {
          case ' ':
          case '\t':
          case '\f':
          case '\v':
          case '\r':
            parser->current.end++;
            space_seen = true;
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

      // We'll check if we're at the end of the file. If we are, then we need to
      // return the EOF token.
      if (parser->current.end >= parser->end) {
        LEX(YP_TOKEN_EOF);
      }

      // Finally, we'll check the current character to determine the next token.
      switch (*parser->current.end++) {
        case '\0':   // NUL or end of script
        case '\004': // ^D
        case '\032': // ^Z
          parser->current.end--;
          LEX(YP_TOKEN_EOF);

        case '#': { // comments
          const char *ending = memchr(parser->current.end, '\n', parser->end - parser->current.end);
          while (ending && ending < parser->end && *ending != '\n') {
            ending = memchr(ending + 1, '\n', parser->end - ending);
          }

          parser->current.end = ending == NULL ? parser->end : ending + 1;
          parser->current.type = YP_TOKEN_COMMENT;
          parser_lex_callback(parser);

          // If we found a comment while lexing, then we're going to add it to the
          // list of comments in the file and keep lexing.
          yp_comment_t *comment = parser_comment(parser, YP_COMMENT_INLINE);
          yp_list_append(&parser->comment_list, (yp_list_node_t *) comment);

          if (parser->current.start == parser->encoding_comment_start) {
            parser_lex_encoding_comment(parser);
          }

          lexed_comment = true;
          // fallthrough
        }

        case '\n': {
          if (parser->heredoc_end != NULL) {
            // If the special resume flag is set, then we need to jump ahead.
            assert(parser->heredoc_end <= parser->end);
            parser->next_start = parser->heredoc_end;
            parser->heredoc_end = NULL;
          }

          // If this is an ignored newline, then we can continue lexing after
          // calling the callback with the ignored newline token.
          yp_ignored_newline_type_t ignored_newline_type;

          switch (ignored_newline_type = lex_state_ignored_p(parser)) {
            case YP_IGNORED_NEWLINE_NONE:
              break;
            case YP_IGNORED_NEWLINE_PATTERN:
              if (parser->pattern_matching_newlines) {
                if (!lexed_comment) parser_lex_ignored_newline(parser);
                lex_state_set(parser, YP_LEX_STATE_BEG);
                parser->command_start = true;
                parser->current.type = YP_TOKEN_NEWLINE;
                return;
              }
            case YP_IGNORED_NEWLINE_ALL:
              if (!lexed_comment) parser_lex_ignored_newline(parser);
              lexed_comment = false;
              goto lex_next_token;
          }

          // Here we need to look ahead and see if there is a call operator
          // (either . or &.) that starts the next line. If there is, then this
          // is going to become an ignored newline and we're going to instead
          // return the call operator.
          const char *next_content = parser->next_start == NULL ? parser->current.end : parser->next_start;
          next_content += yp_strspn_inline_whitespace(next_content, parser->end - next_content);

          if (next_content < parser->end) {
            // If we hit a comment after a newline, then we're going to check
            // if it's ignored or if it's followed by a method call ('.').
            // If it is, then we're going to call the
            // callback with an ignored newline and then continue lexing.
            // Otherwise we'll return a regular newline.
            if (next_content[0] == '#') {
              // Here we look for a "." or "&." following a "\n".
              const char *following = memchr(next_content, '\n', parser->end - next_content);

              while (following && (following < parser->end)) {
                following++;
                following += yp_strspn_inline_whitespace(following, parser->end - following);

                // If this is not followed by a comment, then we can break out
                // of this loop.
                if (*following != '#') break;

                // If there is a comment, then we need to find the end of the
                // comment and continue searching from there.
                following = memchr(following, '\n', parser->end - following);
              }

              // If the lex state was ignored, or we hit a '.' or a '&.',
              // we will lex the ignored newline
              if (lex_state_ignored_p(parser) || (following && ((following[0] == '.') || (following + 1 < parser->end && following[0] == '&' && following[1] == '.')))) {
                if (!lexed_comment) parser_lex_ignored_newline(parser);
                lexed_comment = false;
                goto lex_next_token;
              }
            }

            // If we hit a . after a newline, then we're in a call chain and
            // we need to return the call operator.
            if (
              (next_content[0] == '.') &&
              (next_content + 1 < parser->end) &&
              (next_content[1] != '.')
             ) {
              if (!lexed_comment) parser_lex_ignored_newline(parser);
              lex_state_set(parser, YP_LEX_STATE_DOT);
              parser->current.start = next_content;
              parser->current.end = next_content + 1;
              parser->next_start = NULL;
              LEX(YP_TOKEN_DOT);
            }

            // If we hit a &. after a newline, then we're in a call chain and
            // we need to return the call operator.
            if (next_content + 1 < parser->end && next_content[0] == '&' && next_content[1] == '.') {
              if (!lexed_comment) parser_lex_ignored_newline(parser);
              lex_state_set(parser, YP_LEX_STATE_DOT);
              parser->current.start = next_content;
              parser->current.end = next_content + 2;
              parser->next_start = NULL;
              LEX(YP_TOKEN_AMPERSAND_DOT);
            }
          }

          // At this point we know this is a regular newline, and we can set the
          // necessary state and return the token.
          lex_state_set(parser, YP_LEX_STATE_BEG);
          parser->command_start = true;
          parser->current.type = YP_TOKEN_NEWLINE;
          if (!lexed_comment) parser_lex_callback(parser);
          return;
        }

        // ,
        case ',':
          lex_state_set(parser, YP_LEX_STATE_BEG | YP_LEX_STATE_LABEL);
          LEX(YP_TOKEN_COMMA);

        // (
        case '(': {
          yp_token_type_t type = YP_TOKEN_PARENTHESIS_LEFT;

          if (space_seen && (lex_state_arg_p(parser) || parser->lex_state == (YP_LEX_STATE_END | YP_LEX_STATE_LABEL))) {
            type = YP_TOKEN_PARENTHESIS_LEFT_PARENTHESES;
          }

          parser->enclosure_nesting++;
          lex_state_set(parser, YP_LEX_STATE_BEG | YP_LEX_STATE_LABEL);
          yp_state_stack_push(&parser->do_loop_stack, false);
          LEX(type);
        }

        // )
        case ')':
          parser->enclosure_nesting--;
          lex_state_set(parser, YP_LEX_STATE_ENDFN);
          yp_state_stack_pop(&parser->do_loop_stack);
          LEX(YP_TOKEN_PARENTHESIS_RIGHT);

        // ;
        case ';':
          lex_state_set(parser, YP_LEX_STATE_BEG);
          parser->command_start = true;
          LEX(YP_TOKEN_SEMICOLON);

        // [ [] []=
        case '[':
          parser->enclosure_nesting++;
          yp_token_type_t type = YP_TOKEN_BRACKET_LEFT;

          if (lex_state_operator_p(parser)) {
            if (match(parser, ']')) {
              parser->enclosure_nesting--;
              lex_state_set(parser, YP_LEX_STATE_ARG);
              LEX(match(parser, '=') ? YP_TOKEN_BRACKET_LEFT_RIGHT_EQUAL : YP_TOKEN_BRACKET_LEFT_RIGHT);
            }

            lex_state_set(parser, YP_LEX_STATE_ARG | YP_LEX_STATE_LABEL);
            LEX(type);
          }

          if (lex_state_beg_p(parser) || (lex_state_arg_p(parser) && (space_seen || lex_state_p(parser, YP_LEX_STATE_LABELED)))) {
            type = YP_TOKEN_BRACKET_LEFT_ARRAY;
          }

          lex_state_set(parser, YP_LEX_STATE_BEG | YP_LEX_STATE_LABEL);
          yp_state_stack_push(&parser->do_loop_stack, false);
          LEX(type);

        // ]
        case ']':
          parser->enclosure_nesting--;
          lex_state_set(parser, YP_LEX_STATE_END);
          yp_state_stack_pop(&parser->do_loop_stack);
          LEX(YP_TOKEN_BRACKET_RIGHT);

        // {
        case '{': {
          yp_token_type_t type = YP_TOKEN_BRACE_LEFT;

          if (parser->enclosure_nesting == parser->lambda_enclosure_nesting) {
            // This { begins a lambda
            parser->command_start = true;
            lex_state_set(parser, YP_LEX_STATE_BEG);
            type = YP_TOKEN_LAMBDA_BEGIN;
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
            // This { begins a hash literal
            lex_state_set(parser, YP_LEX_STATE_BEG | YP_LEX_STATE_LABEL);
          }

          parser->enclosure_nesting++;
          parser->brace_nesting++;
          yp_state_stack_push(&parser->do_loop_stack, false);

          LEX(type);
        }

        // }
        case '}':
          parser->enclosure_nesting--;
          yp_state_stack_pop(&parser->do_loop_stack);

          if ((parser->lex_modes.current->mode == YP_LEX_EMBEXPR) && (parser->brace_nesting == 0)) {
            lex_mode_pop(parser);
            LEX(YP_TOKEN_EMBEXPR_END);
          }

          parser->brace_nesting--;
          lex_state_set(parser, YP_LEX_STATE_END);
          LEX(YP_TOKEN_BRACE_RIGHT);

        // * ** **= *=
        case '*': {
          if (match(parser, '*')) {
            if (match(parser, '=')) {
              lex_state_set(parser, YP_LEX_STATE_BEG);
              LEX(YP_TOKEN_STAR_STAR_EQUAL);
            }

            yp_token_type_t type = YP_TOKEN_STAR_STAR;

            if (lex_state_spcarg_p(parser, space_seen) || lex_state_beg_p(parser)) {
              type = YP_TOKEN_USTAR_STAR;
            }

            if (lex_state_operator_p(parser)) {
              lex_state_set(parser, YP_LEX_STATE_ARG);
            } else {
              lex_state_set(parser, YP_LEX_STATE_BEG);
            }

            LEX(type);
          }

          if (match(parser, '=')) {
            lex_state_set(parser, YP_LEX_STATE_BEG);
            LEX(YP_TOKEN_STAR_EQUAL);
          }

          yp_token_type_t type = YP_TOKEN_STAR;

          if (lex_state_spcarg_p(parser, space_seen)) {
            yp_diagnostic_list_append(&parser->warning_list, parser->current.start, parser->current.end, "`*' interpreted as argument prefix");
            type = YP_TOKEN_USTAR;
          } else if (lex_state_beg_p(parser)) {
            type = YP_TOKEN_USTAR;
          }

          if (lex_state_operator_p(parser)) {
            lex_state_set(parser, YP_LEX_STATE_ARG);
          } else {
            lex_state_set(parser, YP_LEX_STATE_BEG);
          }

          LEX(type);
        }

        // ! != !~ !@
        case '!':
          if (lex_state_operator_p(parser)) {
            lex_state_set(parser, YP_LEX_STATE_ARG);
            if (match(parser, '@')) {
              LEX(YP_TOKEN_BANG);
            }
          } else {
            lex_state_set(parser, YP_LEX_STATE_BEG);
          }

          if (match(parser, '=')) {
            LEX(YP_TOKEN_BANG_EQUAL);
          }

          if (match(parser, '~')) {
            LEX(YP_TOKEN_BANG_TILDE);
          }

          LEX(YP_TOKEN_BANG);

        // = => =~ == === =begin
        case '=':
          if (current_token_starts_line(parser) && strncmp(parser->current.end, "begin", 5) == 0 && char_is_whitespace(parser->current.end[5])) {
            yp_token_type_t type = lex_embdoc(parser);

            if (type == YP_TOKEN_EOF) {
              LEX(type);
            }

            goto lex_next_token;
          }

          if (lex_state_operator_p(parser)) {
            lex_state_set(parser, YP_LEX_STATE_ARG);
          } else {
            lex_state_set(parser, YP_LEX_STATE_BEG);
          }

          if (match(parser, '>')) {
            LEX(YP_TOKEN_EQUAL_GREATER);
          }

          if (match(parser, '~')) {
            LEX(YP_TOKEN_EQUAL_TILDE);
          }

          if (match(parser, '=')) {
            LEX(match(parser, '=') ? YP_TOKEN_EQUAL_EQUAL_EQUAL : YP_TOKEN_EQUAL_EQUAL);
          }

          LEX(YP_TOKEN_EQUAL);

        // < << <<= <= <=>
        case '<':
          if (match(parser, '<')) {
            if (
              !lex_state_p(parser, YP_LEX_STATE_DOT | YP_LEX_STATE_CLASS) &&
              !lex_state_end_p(parser) &&
              (!lex_state_p(parser, YP_LEX_STATE_ARG_ANY) || lex_state_p(parser, YP_LEX_STATE_LABELED) || space_seen)
            ) {
              const char *end = parser->current.end;

              yp_heredoc_quote_t quote = YP_HEREDOC_QUOTE_NONE;
              yp_heredoc_indent_t indent = YP_HEREDOC_INDENT_NONE;

              if (match(parser, '-')) {
                indent = YP_HEREDOC_INDENT_DASH;
              }
              else if (match(parser, '~')) {
                indent = YP_HEREDOC_INDENT_TILDE;
              }

              if (match(parser, '`')) {
                quote = YP_HEREDOC_QUOTE_BACKTICK;
              }
              else if (match(parser, '"')) {
                quote = YP_HEREDOC_QUOTE_DOUBLE;
              }
              else if (match(parser, '\'')) {
                quote = YP_HEREDOC_QUOTE_SINGLE;
              }

              const char *ident_start = parser->current.end;
              size_t width;

              if (quote == YP_HEREDOC_QUOTE_NONE && (width = char_is_identifier(parser, parser->current.end)) == 0) {
                parser->current.end = end;
              } else {
                if (quote == YP_HEREDOC_QUOTE_NONE) {
                  parser->current.end += width;

                  while ((width = char_is_identifier(parser, parser->current.end))) {
                    parser->current.end += width;
                  }
                } else {
                  // If we have quotes, then we're going to go until we find the
                  // end quote.
                  while (parser->current.end < parser->end && *parser->current.end != quote) {
                    parser->current.end++;
                  }
                }

                size_t ident_length = parser->current.end - ident_start;
                if (quote != YP_HEREDOC_QUOTE_NONE && !match(parser, quote)) {
                  // TODO: handle unterminated heredoc
                }

                lex_mode_push(parser, (yp_lex_mode_t) {
                  .mode = YP_LEX_HEREDOC,
                  .as.heredoc = {
                    .ident_start = ident_start,
                    .ident_length = ident_length,
                    .next_start = parser->current.end,
                    .quote = quote,
                    .indent = indent
                  }
                });

                if (parser->heredoc_end == NULL) {
                  const char *body_start = (const char *) memchr(parser->current.end, '\n', parser->end - parser->current.end);

                  if (body_start == NULL) {
                    // If there is no newline after the heredoc identifier, then
                    // this is not a valid heredoc declaration. In this case we
                    // will add an error, but we will still return a heredoc
                    // start.
                    yp_diagnostic_list_append(&parser->error_list, parser->current.start, parser->current.end, "Unterminated heredoc.");
                    body_start = parser->end;
                  } else {
                    // Otherwise, we want to indicate that the body of the
                    // heredoc starts on the character after the next newline.
                    body_start++;
                  }

                  parser->next_start = body_start;
                } else {
                  parser->next_start = parser->heredoc_end;
                }

                LEX(YP_TOKEN_HEREDOC_START);
              }
            }

            if (match(parser, '=')) {
              lex_state_set(parser, YP_LEX_STATE_BEG);
              LEX(YP_TOKEN_LESS_LESS_EQUAL);
            }

            if (lex_state_operator_p(parser)) {
              lex_state_set(parser, YP_LEX_STATE_ARG);
            } else {
              if (lex_state_p(parser, YP_LEX_STATE_CLASS)) parser->command_start = true;
              lex_state_set(parser, YP_LEX_STATE_BEG);
            }

            LEX(YP_TOKEN_LESS_LESS);
          }

          if (lex_state_operator_p(parser)) {
            lex_state_set(parser, YP_LEX_STATE_ARG);
          } else {
            if (lex_state_p(parser, YP_LEX_STATE_CLASS)) parser->command_start = true;
            lex_state_set(parser, YP_LEX_STATE_BEG);
          }

          if (match(parser, '=')) {
            if (match(parser, '>')) {
              LEX(YP_TOKEN_LESS_EQUAL_GREATER);
            }

            LEX(YP_TOKEN_LESS_EQUAL);
          }

          LEX(YP_TOKEN_LESS);

        // > >> >>= >=
        case '>':
          if (match(parser, '>')) {
            if (lex_state_operator_p(parser)) {
              lex_state_set(parser, YP_LEX_STATE_ARG);
            } else {
              lex_state_set(parser, YP_LEX_STATE_BEG);
            }
            LEX(match(parser, '=') ? YP_TOKEN_GREATER_GREATER_EQUAL : YP_TOKEN_GREATER_GREATER);
          }

          if (lex_state_operator_p(parser)) {
            lex_state_set(parser, YP_LEX_STATE_ARG);
          } else {
            lex_state_set(parser, YP_LEX_STATE_BEG);
          }

          LEX(match(parser, '=') ? YP_TOKEN_GREATER_EQUAL : YP_TOKEN_GREATER);

        // double-quoted string literal
        case '"': {
          yp_lex_mode_t lex_mode = {
            .mode = YP_LEX_STRING,
            .as.string.incrementor = '\0',
            .as.string.terminator = '"',
            .as.string.nesting = 0,
            .as.string.interpolation = true,
            .as.string.label_allowed = (lex_state_p(parser, YP_LEX_STATE_LABEL | YP_LEX_STATE_ENDFN) && !previous_command_start) || lex_state_arg_p(parser)
          };

          lex_mode_push(parser, lex_mode);
          LEX(YP_TOKEN_STRING_BEGIN);
        }

        // xstring literal
        case '`': {
          if (lex_state_p(parser, YP_LEX_STATE_FNAME)) {
            lex_state_set(parser, YP_LEX_STATE_ENDFN);
            LEX(YP_TOKEN_BACKTICK);
          }

          if (lex_state_p(parser, YP_LEX_STATE_DOT)) {
            if (previous_command_start) {
              lex_state_set(parser, YP_LEX_STATE_CMDARG);
            } else {
              lex_state_set(parser, YP_LEX_STATE_ARG);
            }

            LEX(YP_TOKEN_BACKTICK);
          }

          yp_lex_mode_t lex_mode = {
            .mode = YP_LEX_STRING,
            .as.string.incrementor = '\0',
            .as.string.terminator = '`',
            .as.string.nesting = 0,
            .as.string.interpolation = true,
            .as.string.label_allowed = false
          };

          lex_mode_push(parser, lex_mode);
          LEX(YP_TOKEN_BACKTICK);
        }

        // single-quoted string literal
        case '\'': {
          yp_lex_mode_t lex_mode = {
            .mode = YP_LEX_STRING,
            .as.string.incrementor = '\0',
            .as.string.terminator = '\'',
            .as.string.nesting = 0,
            .as.string.interpolation = false,
            .as.string.label_allowed = (lex_state_p(parser, YP_LEX_STATE_LABEL | YP_LEX_STATE_ENDFN) && !previous_command_start) || lex_state_arg_p(parser)
          };

          lex_mode_push(parser, lex_mode);
          LEX(YP_TOKEN_STRING_BEGIN);
        }

        // ? character literal
        case '?':
          LEX(lex_question_mark(parser));

        // & && &&= &=
        case '&':
          if (match(parser, '&')) {
            lex_state_set(parser, YP_LEX_STATE_BEG);

            if (match(parser, '=')) {
              LEX(YP_TOKEN_AMPERSAND_AMPERSAND_EQUAL);
            }

            LEX(YP_TOKEN_AMPERSAND_AMPERSAND);
          }

          if (match(parser, '=')) {
            lex_state_set(parser, YP_LEX_STATE_BEG);
            LEX(YP_TOKEN_AMPERSAND_EQUAL);
          }

          if (match(parser, '.')) {
            lex_state_set(parser, YP_LEX_STATE_DOT);
            LEX(YP_TOKEN_AMPERSAND_DOT);
          }

          if (lex_state_operator_p(parser)) {
            lex_state_set(parser, YP_LEX_STATE_ARG);
          } else {
            lex_state_set(parser, YP_LEX_STATE_BEG);
          }

          LEX(YP_TOKEN_AMPERSAND);

        // | || ||= |=
        case '|':
          if (match(parser, '|')) {
            if (match(parser, '=')) {
              lex_state_set(parser, YP_LEX_STATE_BEG);
              LEX(YP_TOKEN_PIPE_PIPE_EQUAL);
            }

            if (lex_state_p(parser, YP_LEX_STATE_BEG)) {
              parser->current.end--;
              LEX(YP_TOKEN_PIPE);
            }

            lex_state_set(parser, YP_LEX_STATE_BEG);
            LEX(YP_TOKEN_PIPE_PIPE);
          }

          if (match(parser, '=')) {
            lex_state_set(parser, YP_LEX_STATE_BEG);
            LEX(YP_TOKEN_PIPE_EQUAL);
          }

          if (lex_state_operator_p(parser)) {
            lex_state_set(parser, YP_LEX_STATE_ARG);
          } else {
            lex_state_set(parser, YP_LEX_STATE_BEG | YP_LEX_STATE_LABEL);
          }

          LEX(YP_TOKEN_PIPE);

        // + += +@
        case '+': {
          if (lex_state_operator_p(parser)) {
            lex_state_set(parser, YP_LEX_STATE_ARG);

            if (match(parser, '@')) {
              LEX(YP_TOKEN_UPLUS);
            }

            LEX(YP_TOKEN_PLUS);
          }

          if (match(parser, '=')) {
            lex_state_set(parser, YP_LEX_STATE_BEG);
            LEX(YP_TOKEN_PLUS_EQUAL);
          }

          bool spcarg = lex_state_spcarg_p(parser, space_seen);
          if (spcarg) {
            yp_diagnostic_list_append(
              &parser->warning_list,
              parser->current.start,
              parser->current.end,
              "ambiguous first argument; put parentheses or a space even after `+` operator"
            );
          }

          if (lex_state_beg_p(parser) || spcarg) {
            lex_state_set(parser, YP_LEX_STATE_BEG);

            if (char_is_decimal_number(peek(parser))) {
              parser->current.end++;
              yp_token_type_t type = lex_numeric(parser);
              lex_state_set(parser, YP_LEX_STATE_END);
              LEX(type);
            }

            LEX(YP_TOKEN_UPLUS);
          }

          lex_state_set(parser, YP_LEX_STATE_BEG);
          LEX(YP_TOKEN_PLUS);
        }

        // - -= -@
        case '-': {
          if (lex_state_operator_p(parser)) {
            lex_state_set(parser, YP_LEX_STATE_ARG);

            if (match(parser, '@')) {
              LEX(YP_TOKEN_UMINUS);
            }

            LEX(YP_TOKEN_MINUS);
          }

          if (match(parser, '=')) {
            lex_state_set(parser, YP_LEX_STATE_BEG);
            LEX(YP_TOKEN_MINUS_EQUAL);
          }

          if (match(parser, '>')) {
            lex_state_set(parser, YP_LEX_STATE_ENDFN);
            LEX(YP_TOKEN_MINUS_GREATER);
          }

          bool spcarg = lex_state_spcarg_p(parser, space_seen);
          if (spcarg) {
            yp_diagnostic_list_append(
              &parser->warning_list,
              parser->current.start,
              parser->current.end,
              "ambiguous first argument; put parentheses or a space even after `-` operator"
            );
          }

          if (lex_state_beg_p(parser) || spcarg) {
            lex_state_set(parser, YP_LEX_STATE_BEG);
            LEX(char_is_decimal_number(peek(parser)) ? YP_TOKEN_UMINUS_NUM : YP_TOKEN_UMINUS);
          }

          lex_state_set(parser, YP_LEX_STATE_BEG);
          LEX(YP_TOKEN_MINUS);
        }

        // . .. ...
        case '.': {
          bool beg_p = lex_state_beg_p(parser);

          if (match(parser, '.')) {
            if (match(parser, '.')) {
              if (context_p(parser, YP_CONTEXT_DEF_PARAMS)) {
                lex_state_set(parser, YP_LEX_STATE_ENDARG);
                LEX(YP_TOKEN_UDOT_DOT_DOT);
              }

              lex_state_set(parser, YP_LEX_STATE_BEG);
              LEX(beg_p ? YP_TOKEN_UDOT_DOT_DOT : YP_TOKEN_DOT_DOT_DOT);
            }

            lex_state_set(parser, YP_LEX_STATE_BEG);
            LEX(beg_p ? YP_TOKEN_UDOT_DOT : YP_TOKEN_DOT_DOT);
          }

          lex_state_set(parser, YP_LEX_STATE_DOT);
          LEX(YP_TOKEN_DOT);
        }

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
          LEX(type);
        }

        // :: symbol
        case ':':
          if (match(parser, ':')) {
            if (lex_state_beg_p(parser) || lex_state_p(parser, YP_LEX_STATE_CLASS) || (lex_state_p(parser, YP_LEX_STATE_ARG_ANY) && space_seen)) {
              lex_state_set(parser, YP_LEX_STATE_BEG);
              LEX(YP_TOKEN_UCOLON_COLON);
            }

            lex_state_set(parser, YP_LEX_STATE_DOT);
            LEX(YP_TOKEN_COLON_COLON);
          }

          if (lex_state_end_p(parser) || char_is_whitespace(*parser->current.end) || (*parser->current.end == '#')) {
            lex_state_set(parser, YP_LEX_STATE_BEG);
            LEX(YP_TOKEN_COLON);
          }

          if ((*parser->current.end == '"') || (*parser->current.end == '\'')) {
            yp_lex_mode_t lex_mode = {
              .mode = YP_LEX_STRING,
              .as.string.incrementor = '\0',
              .as.string.terminator = *parser->current.end,
              .as.string.nesting = 0,
              .as.string.interpolation = *parser->current.end == '"',
              .as.string.label_allowed = false
            };

            lex_mode_push(parser, lex_mode);
            parser->current.end++;
          }

          lex_state_set(parser, YP_LEX_STATE_FNAME);
          LEX(YP_TOKEN_SYMBOL_BEGIN);

        // / /=
        case '/':
          if (lex_state_beg_p(parser)) {
            lex_mode_push(parser, (yp_lex_mode_t) {
              .mode = YP_LEX_REGEXP,
              .as.regexp.incrementor = '\0',
              .as.regexp.terminator = '/',
              .as.regexp.nesting = 0
            });

            LEX(YP_TOKEN_REGEXP_BEGIN);
          }

          if (match(parser, '=')) {
            lex_state_set(parser, YP_LEX_STATE_BEG);
            LEX(YP_TOKEN_SLASH_EQUAL);
          }

          if (lex_state_spcarg_p(parser, space_seen)) {
            yp_diagnostic_list_append(&parser->warning_list, parser->current.start, parser->current.end, "ambiguity between regexp and two divisions: wrap regexp in parentheses or add a space after `/' operator");

            lex_mode_push(parser, (yp_lex_mode_t) {
              .mode = YP_LEX_REGEXP,
              .as.regexp.incrementor = '\0',
              .as.regexp.terminator = '/',
              .as.regexp.nesting = 0
            });

            LEX(YP_TOKEN_REGEXP_BEGIN);
          }

          if (lex_state_operator_p(parser)) {
            lex_state_set(parser, YP_LEX_STATE_ARG);
          } else {
            lex_state_set(parser, YP_LEX_STATE_BEG);
          }

          LEX(YP_TOKEN_SLASH);

        // ^ ^=
        case '^':
          if (lex_state_operator_p(parser)) {
            lex_state_set(parser, YP_LEX_STATE_ARG);
          } else {
            lex_state_set(parser, YP_LEX_STATE_BEG);
          }
          LEX(match(parser, '=') ? YP_TOKEN_CARET_EQUAL : YP_TOKEN_CARET);

        // ~ ~@
        case '~':
          if (lex_state_operator_p(parser)) {
            (void) match(parser, '@');
            lex_state_set(parser, YP_LEX_STATE_ARG);
          } else {
            lex_state_set(parser, YP_LEX_STATE_BEG);
          }

          LEX(YP_TOKEN_TILDE);

        // % %= %i %I %q %Q %w %W
        case '%': {
          // In a BEG state, if you encounter a % then you must be starting
          // something. In this case if there is no subsequent character then
          // we have an invalid token.
          if (lex_state_beg_p(parser) && (parser->current.end >= parser->end)) {
            yp_diagnostic_list_append(&parser->error_list, parser->current.start, parser->current.end, "unexpected end of input");
            LEX(YP_TOKEN_STRING_BEGIN);
          }

          if (!lex_state_beg_p(parser) && match(parser, '=')) {
            lex_state_set(parser, YP_LEX_STATE_BEG);
            LEX(YP_TOKEN_PERCENT_EQUAL);
          }
          else if(
            lex_state_beg_p(parser) ||
            (lex_state_p(parser, YP_LEX_STATE_FITEM) && (*parser->current.end == 's')) ||
            lex_state_spcarg_p(parser, space_seen)
          ) {
            if (!parser->encoding.alnum_char(parser->current.end)) {
              lex_mode_push(parser, (yp_lex_mode_t) {
                .mode = YP_LEX_STRING,
                .as.string.incrementor = incrementor(*parser->current.end),
                .as.string.terminator = terminator(*parser->current.end),
                .as.string.nesting = 0,
                .as.string.interpolation = true,
                .as.string.label_allowed = false
              });

              parser->current.end++;
              LEX(YP_TOKEN_STRING_BEGIN);
            }

            switch (*parser->current.end) {
              case 'i': {
                parser->current.end++;
                const char delimiter = *parser->current.end++;

                yp_lex_mode_t lex_mode = {
                  .mode = YP_LEX_LIST,
                  .as.list.incrementor = incrementor(delimiter),
                  .as.list.terminator = terminator(delimiter),
                  .as.list.nesting = 0,
                  .as.list.interpolation = false
                };

                lex_mode_push(parser, lex_mode);
                LEX(YP_TOKEN_PERCENT_LOWER_I);
              }
              case 'I': {
                parser->current.end++;
                const char delimiter = *parser->current.end++;

                yp_lex_mode_t lex_mode = {
                  .mode = YP_LEX_LIST,
                  .as.list.incrementor = incrementor(delimiter),
                  .as.list.terminator = terminator(delimiter),
                  .as.list.nesting = 0,
                  .as.list.interpolation = true
                };

                lex_mode_push(parser, lex_mode);
                LEX(YP_TOKEN_PERCENT_UPPER_I);
              }
              case 'r': {
                parser->current.end++;

                yp_lex_mode_t lex_mode = {
                  .mode = YP_LEX_REGEXP,
                  .as.regexp.incrementor = incrementor(*parser->current.end),
                  .as.regexp.terminator = terminator(*parser->current.end),
                  .as.regexp.nesting = 0
                };

                lex_mode_push(parser, lex_mode);
                parser->current.end++;

                LEX(YP_TOKEN_REGEXP_BEGIN);
              }
              case 'q': {
                parser->current.end++;

                yp_lex_mode_t lex_mode = {
                  .mode = YP_LEX_STRING,
                  .as.string.incrementor = incrementor(*parser->current.end),
                  .as.string.terminator = terminator(*parser->current.end),
                  .as.string.nesting = 0,
                  .as.string.interpolation = false,
                  .as.string.label_allowed = false
                };

                lex_mode_push(parser, lex_mode);
                parser->current.end++;

                LEX(YP_TOKEN_STRING_BEGIN);
              }
              case 'Q': {
                parser->current.end++;

                yp_lex_mode_t lex_mode = {
                  .mode = YP_LEX_STRING,
                  .as.string.incrementor = incrementor(*parser->current.end),
                  .as.string.terminator = terminator(*parser->current.end),
                  .as.string.nesting = 0,
                  .as.string.interpolation = true,
                  .as.string.label_allowed = false
                };

                lex_mode_push(parser, lex_mode);
                parser->current.end++;

                LEX(YP_TOKEN_STRING_BEGIN);
              }
              case 's': {
                parser->current.end++;

                yp_lex_mode_t lex_mode = {
                  .mode = YP_LEX_STRING,
                  .as.string.incrementor = incrementor(*parser->current.end),
                  .as.string.terminator = terminator(*parser->current.end),
                  .as.string.nesting = 0,
                  .as.string.interpolation = false,
                  .as.string.label_allowed = false
                };

                lex_mode_push(parser, lex_mode);
                lex_state_set(parser, YP_LEX_STATE_FNAME | YP_LEX_STATE_FITEM);
                parser->current.end++;

                LEX(YP_TOKEN_SYMBOL_BEGIN);
              }
              case 'w': {
                parser->current.end++;
                const char delimiter = *parser->current.end++;

                yp_lex_mode_t lex_mode = {
                  .mode = YP_LEX_LIST,
                  .as.list.incrementor = incrementor(delimiter),
                  .as.list.terminator = terminator(delimiter),
                  .as.list.nesting = 0,
                  .as.list.interpolation = false
                };

                lex_mode_push(parser, lex_mode);
                LEX(YP_TOKEN_PERCENT_LOWER_W);
              }
              case 'W': {
                parser->current.end++;
                const char delimiter = *parser->current.end++;

                yp_lex_mode_t lex_mode = {
                  .mode = YP_LEX_LIST,
                  .as.list.incrementor = incrementor(delimiter),
                  .as.list.terminator = terminator(delimiter),
                  .as.list.nesting = 0,
                  .as.list.interpolation = true
                };

                lex_mode_push(parser, lex_mode);
                LEX(YP_TOKEN_PERCENT_UPPER_W);
              }
              case 'x': {
                parser->current.end++;

                yp_lex_mode_t lex_mode = {
                  .mode = YP_LEX_STRING,
                  .as.string.incrementor = incrementor(*parser->current.end),
                  .as.string.terminator = terminator(*parser->current.end),
                  .as.string.nesting = 0,
                  .as.string.interpolation = true,
                  .as.string.label_allowed = false
                };

                lex_mode_push(parser, lex_mode);
                parser->current.end++;

                LEX(YP_TOKEN_PERCENT_LOWER_X);
              }
              default:
                // If we get to this point, then we have a % that is completely
                // unparseable. In this case we'll just drop it from the parser
                // and skip past it and hope that the next token is something
                // that we can parse.
                yp_diagnostic_list_append(&parser->error_list, parser->current.start, parser->current.end, "invalid %% token");
                goto lex_next_token;
            }
          }

          lex_state_set(parser, lex_state_operator_p(parser) ? YP_LEX_STATE_ARG : YP_LEX_STATE_BEG);
          LEX(YP_TOKEN_PERCENT);
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
          LEX(type);
        }

        // instance variable, class variable
        case '@':
          lex_state_set(parser, parser->lex_state & YP_LEX_STATE_FNAME ? YP_LEX_STATE_ENDFN : YP_LEX_STATE_END);
          LEX(lex_at_variable(parser));

        default: {
          size_t width = char_is_identifier_start(parser, parser->current.start);

          // If this isn't the beginning of an identifier, then it's an invalid
          // token as we've exhausted all of the other options. We'll skip past
          // it and return the next token.
          if (!width) {
            yp_diagnostic_list_append(&parser->error_list, parser->current.start, parser->current.end, "Invalid token.");
            goto lex_next_token;
          }

          parser->current.end = parser->current.start + width;
          yp_token_type_t type = lex_identifier(parser, previous_command_start);

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
            parser->current.type = YP_TOKEN___END__;
            parser_lex_callback(parser);

            yp_comment_t *comment = parser_comment(parser, YP_COMMENT___END__);
            yp_list_append(&parser->comment_list, (yp_list_node_t *) comment);

            LEX(YP_TOKEN_EOF);
          }

          yp_lex_state_t last_state = parser->lex_state;

          if (type == YP_TOKEN_IDENTIFIER || type == YP_TOKEN_CONSTANT) {
            if (lex_state_p(parser, YP_LEX_STATE_BEG_ANY | YP_LEX_STATE_ARG_ANY | YP_LEX_STATE_DOT)) {
              if (previous_command_start) {
                lex_state_set(parser, YP_LEX_STATE_CMDARG);
              } else {
                lex_state_set(parser, YP_LEX_STATE_ARG);
              }
            } else if (parser->lex_state == YP_LEX_STATE_FNAME) {
              lex_state_set(parser, YP_LEX_STATE_ENDFN);
            } else {
              lex_state_set(parser, YP_LEX_STATE_END);
            }
          }

          if (
            !(last_state & (YP_LEX_STATE_DOT | YP_LEX_STATE_FNAME)) &&
            (type == YP_TOKEN_IDENTIFIER) &&
            yp_parser_local_p(parser, &parser->current)
          ) {
            lex_state_set(parser, YP_LEX_STATE_END | YP_LEX_STATE_LABEL);
          }

          LEX(type);
        }
      }
    }
    case YP_LEX_LIST: {
      // First we'll set the beginning of the token.
      parser->current.start = parser->current.end;

      // If there's any whitespace at the start of the list, then we're going to
      // trim it off the beginning and create a new token.
      size_t whitespace;
      if ((whitespace = yp_strspn_whitespace(parser->current.end, parser->end - parser->current.end)) > 0) {
        parser->current.end += whitespace;
        LEX(YP_TOKEN_WORDS_SEP);
      }

      // We'll check if we're at the end of the file. If we are, then we need to
      // return the EOF token.
      if (parser->current.end >= parser->end) {
        LEX(YP_TOKEN_EOF);
      }

      // These are the places where we need to split up the content of the list.
      // We'll use strpbrk to find the first of these characters.
      char breakpoints[] = "\\ \t\f\r\v\n\0\0\0";

      // Now we'll add the terminator to the list of breakpoints.
      size_t index = 7;
      breakpoints[index++] = parser->lex_modes.current->as.list.terminator;

      // If interpolation is allowed, then we're going to check for the #
      // character. Otherwise we'll only look for escapes and the terminator.
      if (parser->lex_modes.current->as.list.interpolation) {
        breakpoints[index++] = '#';
      }

      // If there is an incrementor, then we'll check for that as well.
      if (parser->lex_modes.current->as.list.incrementor != '\0') {
        breakpoints[index++] = parser->lex_modes.current->as.list.incrementor;
      }

      const char *breakpoint = yp_strpbrk(parser->current.end, breakpoints, parser->end - parser->current.end);
      while (breakpoint != NULL) {
        switch (*breakpoint) {
          case '\0':
            // If we hit a null byte, skip directly past it.
            breakpoint = yp_strpbrk(breakpoint + 1, breakpoints, parser->end - (breakpoint + 1));
            break;
          case '\\': {
            // If we hit escapes, then we need to treat the next token
            // literally. In this case we'll skip past the next character and
            // find the next breakpoint.
            int difference = yp_unescape_calculate_difference(breakpoint, parser->end - breakpoint, YP_UNESCAPE_ALL, &parser->error_list);
            breakpoint = yp_strpbrk(breakpoint + difference, breakpoints, parser->end - (breakpoint + difference));
            break;
          }
          case ' ':
          case '\t':
          case '\f':
          case '\r':
          case '\v':
          case '\n':
            // If we've hit whitespace, then we must have received content by
            // now, so we can return an element of the list.
            parser->current.end = breakpoint;
            LEX(YP_TOKEN_STRING_CONTENT);
          case '#': {
            yp_token_type_t type = lex_interpolation(parser, breakpoint);
            if (type != YP_TOKEN_NOT_PROVIDED) {
              LEX(type);
            }

            // If we haven't returned at this point then we had something
            // that looked like an interpolated class or instance variable
            // like "#@" but wasn't actually. In this case we'll just skip
            // to the next breakpoint.
            breakpoint = yp_strpbrk(parser->current.end, breakpoints, parser->end - parser->current.end);
            break;
          }
          default:
            if (*breakpoint == parser->lex_modes.current->as.list.incrementor) {
              // If we've hit the incrementor, then we need to skip past it and
              // find the next breakpoint.
              breakpoint = yp_strpbrk(breakpoint + 1, breakpoints, parser->end - (breakpoint + 1));
              parser->lex_modes.current->as.list.nesting++;
              break;
            }

            // In this case we've hit the terminator.
            assert(*breakpoint == parser->lex_modes.current->as.list.terminator);

            // If this terminator doesn't actually close the list, then we need
            // to continue on past it.
            if (parser->lex_modes.current->as.list.nesting > 0) {
              breakpoint = yp_strpbrk(breakpoint + 1, breakpoints, parser->end - (breakpoint + 1));
              parser->lex_modes.current->as.list.nesting--;
              break;
            }

            // If we've hit the terminator and we've already skipped past
            // content, then we can return a list node.
            if (breakpoint > parser->current.start) {
              parser->current.end = breakpoint;
              LEX(YP_TOKEN_STRING_CONTENT);
            }

            // Otherwise, switch back to the default state and return the end of
            // the list.
            parser->current.end = breakpoint + 1;
            lex_mode_pop(parser);

            lex_state_set(parser, YP_LEX_STATE_END);
            LEX(YP_TOKEN_STRING_END);
        }
      }

      // If we were unable to find a breakpoint, then this token hits the end of
      // the file.
      LEX(YP_TOKEN_EOF);
    }
    case YP_LEX_REGEXP: {
      // First, we'll set to start of this token to be the current end.
      parser->current.start = parser->current.end;

      // We'll check if we're at the end of the file. If we are, then we need to
      // return the EOF token.
      if (parser->current.end >= parser->end) {
        LEX(YP_TOKEN_EOF);
      }

      // These are the places where we need to split up the content of the
      // regular expression. We'll use strpbrk to find the first of these
      // characters.
      char breakpoints[] = "\\#\0\0";

      breakpoints[2] = parser->lex_modes.current->as.regexp.terminator;
      if (parser->lex_modes.current->as.regexp.incrementor != '\0') {
        breakpoints[3] = parser->lex_modes.current->as.regexp.incrementor;
      }

      const char *breakpoint = yp_strpbrk(parser->current.end, breakpoints, parser->end - parser->current.end);

      while (breakpoint != NULL) {
        switch (*breakpoint) {
          case '\0':
            // If we hit a null byte, skip directly past it.
            breakpoint = yp_strpbrk(breakpoint + 1, breakpoints, parser->end - (breakpoint + 1));
            break;
          case '\\': {
            // If we hit escapes, then we need to treat the next token
            // literally. In this case we'll skip past the next character and
            // find the next breakpoint.
            int difference = yp_unescape_calculate_difference(breakpoint, parser->end - breakpoint, YP_UNESCAPE_ALL, &parser->error_list);
            breakpoint = yp_strpbrk(breakpoint + difference, breakpoints, parser->end - (breakpoint + difference));
            break;
          }
          case '#': {
            yp_token_type_t type = lex_interpolation(parser, breakpoint);
            if (type != YP_TOKEN_NOT_PROVIDED) {
              LEX(type);
            }

            // If we haven't returned at this point then we had something
            // that looked like an interpolated class or instance variable
            // like "#@" but wasn't actually. In this case we'll just skip
            // to the next breakpoint.
            breakpoint = yp_strpbrk(parser->current.end, breakpoints, parser->end - parser->current.end);
            break;
          }
          default: {
            if (*breakpoint == parser->lex_modes.current->as.regexp.incrementor) {
              // If we've hit the incrementor, then we need to skip past it and
              // find the next breakpoint.
              breakpoint = yp_strpbrk(breakpoint + 1, breakpoints, parser->end - (breakpoint + 1));
              parser->lex_modes.current->as.regexp.nesting++;
              break;
            }

            assert(*breakpoint == parser->lex_modes.current->as.regexp.terminator);

            if (parser->lex_modes.current->as.regexp.nesting > 0) {
              breakpoint = yp_strpbrk(breakpoint + 1, breakpoints, parser->end - (breakpoint + 1));
              parser->lex_modes.current->as.regexp.nesting--;
              break;
            }

            // Here we've hit the terminator. If we have already consumed
            // content then we need to return that content as string content
            // first.
            if (breakpoint > parser->current.start) {
              parser->current.end = breakpoint;
              LEX(YP_TOKEN_STRING_CONTENT);
            }

            // Since we've hit the terminator of the regular expression, we now
            // need to parse the options.
            parser->current.end = breakpoint + 1;
            parser->current.end += yp_strspn_regexp_option(parser->current.end, parser->end - parser->current.end);

            lex_mode_pop(parser);
            lex_state_set(parser, YP_LEX_STATE_END);
            LEX(YP_TOKEN_REGEXP_END);
          }
        }
      }

      // At this point, the breakpoint is NULL which means we were unable to
      // find anything before the end of the file.
      LEX(YP_TOKEN_EOF);
    }
    case YP_LEX_STRING: {
      // First, we'll set to start of this token to be the current end.
      parser->current.start = parser->current.end;

      // We'll check if we're at the end of the file. If we are, then we need to
      // return the EOF token.
      if (parser->current.end >= parser->end) {
        LEX(YP_TOKEN_EOF);
      }

      // These are the places where we need to split up the content of the
      // string. We'll use strpbrk to find the first of these characters.
      char breakpoints[] = "\\\0\0\0";
      size_t index = 1;

      // Now add in the terminator.
      breakpoints[index++] = parser->lex_modes.current->as.string.terminator;

      // If interpolation is allowed, then we're going to check for the #
      // character. Otherwise we'll only look for escapes and the terminator.
      if (parser->lex_modes.current->as.string.interpolation) {
        breakpoints[index++] = '#';
      }

      // If we have an incrementor, then we'll add that in as a breakpoint as
      // well.
      if (parser->lex_modes.current->as.string.incrementor != '\0') {
        breakpoints[index++] = parser->lex_modes.current->as.string.incrementor;
      }

      const char *breakpoint = yp_strpbrk(parser->current.end, breakpoints, parser->end - parser->current.end);

      while (breakpoint != NULL) {
        // If we hit the incrementor, then we'll increment then nesting and
        // continue lexing.
        if (
          parser->lex_modes.current->as.string.incrementor != '\0' &&
          *breakpoint == parser->lex_modes.current->as.string.incrementor
        ) {
          parser->lex_modes.current->as.string.nesting++;
          breakpoint = yp_strpbrk(breakpoint + 1, breakpoints, parser->end - (breakpoint + 1));
          continue;
        }

        // Note that we have to check the terminator here first because we could
        // potentially be parsing a % string that has a # character as the
        // terminator.
        if (*breakpoint == parser->lex_modes.current->as.string.terminator) {
          // If this terminator doesn't actually close the string, then we need
          // to continue on past it.
          if (parser->lex_modes.current->as.string.nesting > 0) {
            breakpoint = yp_strpbrk(breakpoint + 1, breakpoints, parser->end - (breakpoint + 1));
            parser->lex_modes.current->as.string.nesting--;
            continue;
          }

          // Here we've hit the terminator. If we have already consumed content
          // then we need to return that content as string content first.
          if (breakpoint > parser->current.start) {
            parser->current.end = breakpoint;
            LEX(YP_TOKEN_STRING_CONTENT);
          }

          // Otherwise we need to switch back to the parent lex mode and
          // return the end of the string.
          parser->current.end = breakpoint + 1;

          if (
            parser->lex_modes.current->as.string.label_allowed &&
            (peek(parser) == ':') &&
            (peek_at(parser, 1) != ':')
          ) {
            parser->current.end++;
            lex_state_set(parser, YP_LEX_STATE_ARG | YP_LEX_STATE_LABELED);
            lex_mode_pop(parser);
            LEX(YP_TOKEN_LABEL_END);
          }

          lex_state_set(parser, YP_LEX_STATE_END);
          lex_mode_pop(parser);
          LEX(YP_TOKEN_STRING_END);
        }

        switch (*breakpoint) {
          case '\0':
            // Skip directly past the null character.
            breakpoint = yp_strpbrk(breakpoint + 1, breakpoints, parser->end - (breakpoint + 1));
            break;
          case '\\': {
            // If we hit escapes, then we need to treat the next token
            // literally. In this case we'll skip past the next character and
            // find the next breakpoint.
            yp_unescape_type_t unescape_type = parser->lex_modes.current->as.string.interpolation ? YP_UNESCAPE_ALL : YP_UNESCAPE_MINIMAL;
            int difference = yp_unescape_calculate_difference(breakpoint, parser->end - breakpoint, unescape_type, &parser->error_list);
            breakpoint = yp_strpbrk(breakpoint + difference, breakpoints, parser->end - (breakpoint + difference));
            break;
          }
          case '#': {
            yp_token_type_t type = lex_interpolation(parser, breakpoint);
            if (type != YP_TOKEN_NOT_PROVIDED) {
              LEX(type);
            }

            // If we haven't returned at this point then we had something that
            // looked like an interpolated class or instance variable like "#@"
            // but wasn't actually. In this case we'll just skip to the next
            // breakpoint.
            breakpoint = yp_strpbrk(parser->current.end, breakpoints, parser->end - parser->current.end);
            break;
          }
          default:
            assert(false && "unreachable");
        }
      }

      // If we've hit the end of the string, then this is an unterminated
      // string. In that case we'll return the EOF token.
      parser->current.end = parser->end;
      LEX(YP_TOKEN_EOF);
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

      // We'll check if we're at the end of the file. If we are, then we need to
      // return the EOF token.
      if (parser->current.end >= parser->end) {
        LEX(YP_TOKEN_EOF);
      }

      // Now let's grab the information about the identifier off of the current
      // lex mode.
      const char *ident_start = parser->lex_modes.current->as.heredoc.ident_start;
      uint32_t ident_length = parser->lex_modes.current->as.heredoc.ident_length;

      // If we are immediately following a newline and we have hit the
      // terminator, then we need to return the ending of the heredoc.
      if (parser->current.start[-1] == '\n') {
        const char *start = parser->current.start;
        if (parser->lex_modes.current->as.heredoc.indent != YP_HEREDOC_INDENT_NONE) {
          start += yp_strspn_inline_whitespace(start, parser->end - start);
        }

        if (strncmp(start, ident_start, ident_length) == 0) {
          bool matched = false;

          if (start[ident_length] == '\n') {
            parser->current.end = start + ident_length + 1;
            matched = true;
          } else if ((start[ident_length] == '\r') && (start[ident_length + 1] == '\n')) {
            parser->current.end = start + ident_length + 2;
            matched = true;
          }

          if (matched) {
            parser->next_start = parser->lex_modes.current->as.heredoc.next_start;
            parser->heredoc_end = parser->current.end;

            lex_mode_pop(parser);
            lex_state_set(parser, YP_LEX_STATE_END);
            LEX(YP_TOKEN_HEREDOC_END);
          }
        }
      }

      // Otherwise we'll be parsing string content. These are the places where
      // we need to split up the content of the heredoc. We'll use strpbrk to
      // find the first of these characters.
      char breakpoints[] = "\n\\#";
      if (parser->lex_modes.current->as.heredoc.quote == YP_HEREDOC_QUOTE_SINGLE) {
        breakpoints[2] = '\0';
      }

      const char *breakpoint = yp_strpbrk(parser->current.end, breakpoints, parser->end - parser->current.end);

      while (breakpoint != NULL) {
        switch (*breakpoint) {
          case '\0':
            // Skip directly past the null character.
            breakpoint = yp_strpbrk(breakpoint + 1, breakpoints, parser->end - (breakpoint + 1));
            break;
          case '\n': {
            const char *start = breakpoint + 1;
            if (parser->lex_modes.current->as.heredoc.indent != YP_HEREDOC_INDENT_NONE) {
              start += yp_strspn_inline_whitespace(start, parser->end - start);
            }

            // If we have hit a newline that is followed by a valid terminator,
            // then we need to return the content of the heredoc here as string
            // content. Then, the next time a token is lexed, it will match
            // again and return the end of the heredoc.
            if (
              (start + ident_length < parser->end) &&
              (strncmp(start, ident_start, ident_length) == 0)
            ) {
              // Heredoc terminators must be followed by a newline to be valid.
              if (start[ident_length] == '\n') {
                parser->current.end = breakpoint + 1;
                LEX(YP_TOKEN_STRING_CONTENT);
              }

              // They can also be followed by a carriage return and then a
              // newline. Be sure here that we don't accidentally read off the
              // end.
              if (
                (start + ident_length + 1 < parser->end) &&
                (start[ident_length] == '\r') &&
                (start[ident_length + 1] == '\n')
              ) {
                parser->current.end = breakpoint + 1;
                LEX(YP_TOKEN_STRING_CONTENT);
              }
            }

            // Otherwise we hit a newline and it wasn't followed by a
            // terminator, so we can continue parsing.
            breakpoint = yp_strpbrk(breakpoint + 1, breakpoints, parser->end - (breakpoint + 1));
            break;
          }
          case '\\': {
            // If we hit escapes, then we need to treat the next token
            // literally. In this case we'll skip past the next character and
            // find the next breakpoint.
            int difference = yp_unescape_calculate_difference(breakpoint, parser->end - breakpoint, YP_UNESCAPE_ALL, &parser->error_list);
            if (breakpoint[1] == '\n') {
              breakpoint++;
            } else {
              breakpoint = yp_strpbrk(breakpoint + difference, breakpoints, parser->end - (breakpoint + difference));
            }
            break;
          }
          case '#': {
            yp_token_type_t type = lex_interpolation(parser, breakpoint);
            if (type != YP_TOKEN_NOT_PROVIDED) {
              LEX(type);
            }

            // If we haven't returned at this point then we had something
            // that looked like an interpolated class or instance variable
            // like "#@" but wasn't actually. In this case we'll just skip
            // to the next breakpoint.
            breakpoint = yp_strpbrk(parser->current.end, breakpoints, parser->end - parser->current.end);
            break;
          }
          default:
            assert(false && "unreachable");
        }
      }

      // If we've hit the end of the string, then this is an unterminated
      // heredoc. In that case we'll return the EOF token.
      parser->current.end = parser->end;
      LEX(YP_TOKEN_EOF);
    }
  }

  assert(false && "unreachable");
}

#undef LEX

/******************************************************************************/
/* Parse functions                                                            */
/******************************************************************************/

// When we are parsing certain content, we need to unescape the content to
// provide to the consumers of the parser. The following functions accept a range
// of characters from the source and unescapes into the provided type.
//
// We have functions for unescaping regular expression nodes, string nodes,
// symbol nodes, and xstring nodes
static yp_node_t *
yp_node_regular_expression_node_create_and_unescape(yp_parser_t *parser, const yp_token_t *opening, const yp_token_t *content, const yp_token_t *closing, yp_unescape_type_t unescape_type) {
  yp_node_t *node = yp_regular_expression_node_create(parser, opening, content, closing);
  yp_unescape_manipulate_string(content->start, content->end - content->start, &YP_NODE_UPCAST(node, yp_regular_expression_node_t)->unescaped, unescape_type, &parser->error_list);
  return node;
}

static yp_node_t *
yp_node_symbol_node_create_and_unescape(yp_parser_t *parser, const yp_token_t *opening, const yp_token_t *content, const yp_token_t *closing) {
  yp_node_t *node = yp_symbol_node_create(parser, opening, content, closing);
  yp_unescape_manipulate_string(content->start, content->end - content->start, &YP_NODE_UPCAST(node, yp_symbol_node_t)->unescaped, YP_UNESCAPE_ALL, &parser->error_list);
  return node;
}

static yp_node_t *
yp_node_string_node_create_and_unescape(yp_parser_t *parser, const yp_token_t *opening, const yp_token_t *content, const yp_token_t *closing, yp_unescape_type_t unescape_type) {
  yp_node_t *node = yp_string_node_create(parser, opening, content, closing);
  yp_unescape_manipulate_string(content->start, content->end - content->start, &YP_NODE_UPCAST(node, yp_string_node_t)->unescaped, unescape_type, &parser->error_list);
  return node;
}

static yp_node_t *
yp_node_xstring_node_create_and_unescape(yp_parser_t *parser, const yp_token_t *opening, const yp_token_t *content, const yp_token_t *closing) {
  yp_node_t *node = yp_xstring_node_create(parser, opening, content, closing);
  yp_unescape_manipulate_string(content->start, content->end - content->start, &YP_NODE_UPCAST(node, yp_x_string_node_t)->unescaped, YP_UNESCAPE_ALL, &parser->error_list);
  return node;
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

// These are the various precedence rules. Because we are using a Pratt parser,
// they are named binding power to represent the manner in which nodes are bound
// together in the stack.
//
// We increment by 2 because we want to leave room for the infix operators to
// specify their associativity by adding or subtracting one.
typedef enum {
  YP_BINDING_POWER_UNSET = 0,            // used to indicate this token cannot be used as an infix operator
  YP_BINDING_POWER_STATEMENT = 2,
  YP_BINDING_POWER_MODIFIER = 4,         // if unless until while in rescue
  YP_BINDING_POWER_COMPOSITION = 6,      // and or
  YP_BINDING_POWER_NOT = 8,              // not
  YP_BINDING_POWER_MATCH = 10,           // =>
  YP_BINDING_POWER_DEFINED = 12,         // defined?
  YP_BINDING_POWER_ASSIGNMENT = 14,      // = += -= *= /= %= &= |= ^= &&= ||= <<= >>= **=
  YP_BINDING_POWER_TERNARY = 16,         // ?:
  YP_BINDING_POWER_RANGE = 18,           // .. ...
  YP_BINDING_POWER_LOGICAL_OR = 20,      // ||
  YP_BINDING_POWER_LOGICAL_AND = 22,     // &&
  YP_BINDING_POWER_EQUALITY = 24,        // <=> == === != =~ !~
  YP_BINDING_POWER_COMPARISON = 26,      // > >= < <=
  YP_BINDING_POWER_BITWISE_OR = 28,      // | ^
  YP_BINDING_POWER_BITWISE_AND = 30,     // &
  YP_BINDING_POWER_SHIFT = 32,           // << >>
  YP_BINDING_POWER_TERM = 34,            // + -
  YP_BINDING_POWER_FACTOR = 36,          // * / %
  YP_BINDING_POWER_UMINUS = 38,          // -@
  YP_BINDING_POWER_EXPONENT = 40,        // **
  YP_BINDING_POWER_UNARY = 42,           // ! ~ +@
  YP_BINDING_POWER_INDEX = 44,           // [] []=
  YP_BINDING_POWER_CALL = 46,            // :: .
  YP_BINDING_POWER_MAX = 48
} yp_binding_power_t;

// This struct represents a set of binding powers used for a given token. They
// are combined in this way to make it easier to represent associativity.
typedef struct {
  yp_binding_power_t left;
  yp_binding_power_t right;
  bool binary;
} yp_binding_powers_t;

#define BINDING_POWER_ASSIGNMENT { YP_BINDING_POWER_UNARY, YP_BINDING_POWER_ASSIGNMENT, true }
#define LEFT_ASSOCIATIVE(precedence) { precedence, precedence + 1, true }
#define RIGHT_ASSOCIATIVE(precedence) { precedence, precedence, true }
#define RIGHT_ASSOCIATIVE_UNARY(precedence) { precedence, precedence, false }

yp_binding_powers_t yp_binding_powers[YP_TOKEN_MAXIMUM] = {
  // if unless until while in rescue
  [YP_TOKEN_KEYWORD_IF_MODIFIER] = LEFT_ASSOCIATIVE(YP_BINDING_POWER_MODIFIER),
  [YP_TOKEN_KEYWORD_UNLESS_MODIFIER] = LEFT_ASSOCIATIVE(YP_BINDING_POWER_MODIFIER),
  [YP_TOKEN_KEYWORD_UNTIL_MODIFIER] = LEFT_ASSOCIATIVE(YP_BINDING_POWER_MODIFIER),
  [YP_TOKEN_KEYWORD_WHILE_MODIFIER] = LEFT_ASSOCIATIVE(YP_BINDING_POWER_MODIFIER),
  [YP_TOKEN_KEYWORD_IN] = LEFT_ASSOCIATIVE(YP_BINDING_POWER_MODIFIER),
  [YP_TOKEN_KEYWORD_RESCUE_MODIFIER] = LEFT_ASSOCIATIVE(YP_BINDING_POWER_MODIFIER),

  // and or
  [YP_TOKEN_KEYWORD_AND] = LEFT_ASSOCIATIVE(YP_BINDING_POWER_COMPOSITION),
  [YP_TOKEN_KEYWORD_OR] = LEFT_ASSOCIATIVE(YP_BINDING_POWER_COMPOSITION),

  // =>
  [YP_TOKEN_EQUAL_GREATER] = LEFT_ASSOCIATIVE(YP_BINDING_POWER_MATCH),

  // &&= &= ^= = >>= <<= -= %= |= += /= *= **=
  [YP_TOKEN_AMPERSAND_AMPERSAND_EQUAL] = BINDING_POWER_ASSIGNMENT,
  [YP_TOKEN_AMPERSAND_EQUAL] = BINDING_POWER_ASSIGNMENT,
  [YP_TOKEN_CARET_EQUAL] = BINDING_POWER_ASSIGNMENT,
  [YP_TOKEN_EQUAL] = BINDING_POWER_ASSIGNMENT,
  [YP_TOKEN_GREATER_GREATER_EQUAL] = BINDING_POWER_ASSIGNMENT,
  [YP_TOKEN_LESS_LESS_EQUAL] = BINDING_POWER_ASSIGNMENT,
  [YP_TOKEN_MINUS_EQUAL] = BINDING_POWER_ASSIGNMENT,
  [YP_TOKEN_PERCENT_EQUAL] = BINDING_POWER_ASSIGNMENT,
  [YP_TOKEN_PIPE_EQUAL] = BINDING_POWER_ASSIGNMENT,
  [YP_TOKEN_PIPE_PIPE_EQUAL] = BINDING_POWER_ASSIGNMENT,
  [YP_TOKEN_PLUS_EQUAL] = BINDING_POWER_ASSIGNMENT,
  [YP_TOKEN_SLASH_EQUAL] = BINDING_POWER_ASSIGNMENT,
  [YP_TOKEN_STAR_EQUAL] = BINDING_POWER_ASSIGNMENT,
  [YP_TOKEN_STAR_STAR_EQUAL] = BINDING_POWER_ASSIGNMENT,

  // ?:
  [YP_TOKEN_QUESTION_MARK] = RIGHT_ASSOCIATIVE(YP_BINDING_POWER_TERNARY),

  // .. ...
  [YP_TOKEN_DOT_DOT] = LEFT_ASSOCIATIVE(YP_BINDING_POWER_RANGE),
  [YP_TOKEN_DOT_DOT_DOT] = LEFT_ASSOCIATIVE(YP_BINDING_POWER_RANGE),

  // ||
  [YP_TOKEN_PIPE_PIPE] = LEFT_ASSOCIATIVE(YP_BINDING_POWER_LOGICAL_OR),

  // &&
  [YP_TOKEN_AMPERSAND_AMPERSAND] = LEFT_ASSOCIATIVE(YP_BINDING_POWER_LOGICAL_AND),

  // != !~ == === =~ <=>
  [YP_TOKEN_BANG_EQUAL] = RIGHT_ASSOCIATIVE(YP_BINDING_POWER_EQUALITY),
  [YP_TOKEN_BANG_TILDE] = RIGHT_ASSOCIATIVE(YP_BINDING_POWER_EQUALITY),
  [YP_TOKEN_EQUAL_EQUAL] = RIGHT_ASSOCIATIVE(YP_BINDING_POWER_EQUALITY),
  [YP_TOKEN_EQUAL_EQUAL_EQUAL] = RIGHT_ASSOCIATIVE(YP_BINDING_POWER_EQUALITY),
  [YP_TOKEN_EQUAL_TILDE] = RIGHT_ASSOCIATIVE(YP_BINDING_POWER_EQUALITY),
  [YP_TOKEN_LESS_EQUAL_GREATER] = RIGHT_ASSOCIATIVE(YP_BINDING_POWER_EQUALITY),

  // > >= < <=
  [YP_TOKEN_GREATER] = RIGHT_ASSOCIATIVE(YP_BINDING_POWER_COMPARISON),
  [YP_TOKEN_GREATER_EQUAL] = RIGHT_ASSOCIATIVE(YP_BINDING_POWER_COMPARISON),
  [YP_TOKEN_LESS] = RIGHT_ASSOCIATIVE(YP_BINDING_POWER_COMPARISON),
  [YP_TOKEN_LESS_EQUAL] = RIGHT_ASSOCIATIVE(YP_BINDING_POWER_COMPARISON),

  // ^ |
  [YP_TOKEN_CARET] = RIGHT_ASSOCIATIVE(YP_BINDING_POWER_BITWISE_OR),
  [YP_TOKEN_PIPE] = RIGHT_ASSOCIATIVE(YP_BINDING_POWER_BITWISE_OR),

  // &
  [YP_TOKEN_AMPERSAND] = RIGHT_ASSOCIATIVE(YP_BINDING_POWER_BITWISE_AND),

  // >> <<
  [YP_TOKEN_GREATER_GREATER] = RIGHT_ASSOCIATIVE(YP_BINDING_POWER_SHIFT),
  [YP_TOKEN_LESS_LESS] = RIGHT_ASSOCIATIVE(YP_BINDING_POWER_SHIFT),

  // - +
  [YP_TOKEN_MINUS] = LEFT_ASSOCIATIVE(YP_BINDING_POWER_TERM),
  [YP_TOKEN_PLUS] = LEFT_ASSOCIATIVE(YP_BINDING_POWER_TERM),

  // % / *
  [YP_TOKEN_PERCENT] = LEFT_ASSOCIATIVE(YP_BINDING_POWER_FACTOR),
  [YP_TOKEN_SLASH] = LEFT_ASSOCIATIVE(YP_BINDING_POWER_FACTOR),
  [YP_TOKEN_STAR] = LEFT_ASSOCIATIVE(YP_BINDING_POWER_FACTOR),
  [YP_TOKEN_USTAR] = LEFT_ASSOCIATIVE(YP_BINDING_POWER_FACTOR),

  // -@
  [YP_TOKEN_UMINUS] = RIGHT_ASSOCIATIVE_UNARY(YP_BINDING_POWER_UMINUS),
  [YP_TOKEN_UMINUS_NUM] = RIGHT_ASSOCIATIVE_UNARY(YP_BINDING_POWER_UMINUS),

  // **
  [YP_TOKEN_STAR_STAR] = RIGHT_ASSOCIATIVE(YP_BINDING_POWER_EXPONENT),
  [YP_TOKEN_USTAR_STAR] = RIGHT_ASSOCIATIVE_UNARY(YP_BINDING_POWER_UNARY),

  // ! ~ +@
  [YP_TOKEN_BANG] = RIGHT_ASSOCIATIVE_UNARY(YP_BINDING_POWER_UNARY),
  [YP_TOKEN_TILDE] = RIGHT_ASSOCIATIVE_UNARY(YP_BINDING_POWER_UNARY),
  [YP_TOKEN_UPLUS] = RIGHT_ASSOCIATIVE_UNARY(YP_BINDING_POWER_UNARY),

  // [
  [YP_TOKEN_BRACKET_LEFT] = LEFT_ASSOCIATIVE(YP_BINDING_POWER_INDEX),

  // :: . &.
  [YP_TOKEN_COLON_COLON] = RIGHT_ASSOCIATIVE(YP_BINDING_POWER_CALL),
  [YP_TOKEN_DOT] = RIGHT_ASSOCIATIVE(YP_BINDING_POWER_CALL),
  [YP_TOKEN_AMPERSAND_DOT] = RIGHT_ASSOCIATIVE(YP_BINDING_POWER_CALL)
};

#undef BINDING_POWER_ASSIGNMENT
#undef LEFT_ASSOCIATIVE
#undef RIGHT_ASSOCIATIVE
#undef RIGHT_ASSOCIATIVE_UNARY

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

  yp_diagnostic_list_append(&parser->error_list, parser->previous.end, parser->previous.end, message);

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

  yp_diagnostic_list_append(&parser->error_list, parser->previous.end, parser->previous.end, message);
  parser->previous =
    (yp_token_t) { .type = YP_TOKEN_MISSING, .start = parser->previous.end, .end = parser->previous.end };
}

static yp_node_t *
parse_expression(yp_parser_t *parser, yp_binding_power_t binding_power, const char *message);

// This function controls whether or not we will attempt to parse an expression
// beginning at the subsequent token. It is used when we are in a context where
// an expression is optional.
//
// For example, looking at a range object when we've already lexed the operator,
// we need to know if we should attempt to parse an expression on the right.
//
// For another example, if we've parsed an identifier or a method call and we do
// not have parentheses, then the next token may be the start of an argument or
// it may not.
//
// CRuby parsers that are generated would resolve this by using a lookahead and
// potentially backtracking. We attempt to do this by just looking at the next
// token and making a decision based on that. I am not sure if this is going to
// work in all cases, it may need to be refactored later. But it appears to work
// for now.
static inline bool
token_begins_expression_p(yp_token_type_t type) {
  switch (type) {
    case YP_TOKEN_EQUAL_GREATER:
    case YP_TOKEN_KEYWORD_IN:
      // We need to special case this because it is a binary operator that
      // should not be marked as beginning an expression.
      return false;
    case YP_TOKEN_BRACE_RIGHT:
    case YP_TOKEN_BRACKET_RIGHT:
    case YP_TOKEN_COLON:
    case YP_TOKEN_COMMA:
    case YP_TOKEN_EMBEXPR_END:
    case YP_TOKEN_EOF:
    case YP_TOKEN_LAMBDA_BEGIN:
    case YP_TOKEN_KEYWORD_DO:
    case YP_TOKEN_KEYWORD_DO_LOOP:
    case YP_TOKEN_KEYWORD_END:
    case YP_TOKEN_KEYWORD_ELSIF:
    case YP_TOKEN_KEYWORD_THEN:
    case YP_TOKEN_KEYWORD_WHEN:
    case YP_TOKEN_NEWLINE:
    case YP_TOKEN_PARENTHESIS_RIGHT:
    case YP_TOKEN_SEMICOLON:
      // The reason we need this short-circuit is because we're using the
      // binding powers table to tell us if the subsequent token could
      // potentially be the start of an expression . If there _is_ a binding
      // power for one of these tokens, then we should remove it from this list
      // and let it be handled by the default case below.
      assert(yp_binding_powers[type].left == YP_BINDING_POWER_UNSET);
      return false;
    case YP_TOKEN_UCOLON_COLON:
    case YP_TOKEN_UMINUS:
    case YP_TOKEN_UMINUS_NUM:
    case YP_TOKEN_UPLUS:
    case YP_TOKEN_BANG:
    case YP_TOKEN_TILDE:
    case YP_TOKEN_UDOT_DOT:
    case YP_TOKEN_UDOT_DOT_DOT:
      // These unary tokens actually do have binding power associated with them
      // so that we can correctly place them into the precedence order. But we
      // want them to be marked as beginning an expression, so we need to
      // special case them here.
      return true;
    default:
      return yp_binding_powers[type].left == YP_BINDING_POWER_UNSET;
  }
}

// Parse an expression with the given binding power that may be optionally
// prefixed by the * operator.
static yp_node_t *
parse_starred_expression(yp_parser_t *parser, yp_binding_power_t binding_power, const char *message) {
  if (accept(parser, YP_TOKEN_USTAR)) {
    yp_token_t operator = parser->previous;
    yp_node_t *expression = parse_expression(parser, binding_power, "Expected expression after `*'.");
    return yp_splat_node_create(parser, &operator, expression);
  }

  return parse_expression(parser, binding_power, message);
}

// Convert the given node into a valid target node.
static yp_node_t *
parse_target(yp_parser_t *parser, yp_node_t *target, yp_token_t *operator, yp_node_t *value) {
  switch (target->type) {
    case YP_NODE_MISSING_NODE:
      return target;
    case YP_NODE_CLASS_VARIABLE_READ_NODE:
      yp_class_variable_read_node_to_class_variable_write_node(parser, target, operator, value);
      return target;
    case YP_NODE_CONSTANT_PATH_NODE:
    case YP_NODE_CONSTANT_READ_NODE:
      return yp_constant_path_write_node_create(parser, target, operator, value);
    case YP_NODE_GLOBAL_VARIABLE_READ_NODE: {
      yp_node_t *result = yp_global_variable_write_node_create(parser, &YP_NODE_UPCAST(target, yp_global_variable_read_node_t)->name, operator, value);
      yp_node_destroy(parser, target);
      return result;
    }
    case YP_NODE_LOCAL_VARIABLE_READ_NODE: {
      yp_local_variable_read_node_t *read_node = YP_NODE_UPCAST(target, yp_local_variable_read_node_t);
      yp_token_t name = read_node->name;
      yp_parser_local_add(parser, &name);
      yp_local_variable_write_node_t *write_node = YP_NODE_UPCAST(
        yp_local_variable_write_node_create(parser, &read_node->name),
        yp_local_variable_write_node_t
      );
      write_node->base.location.start = name.start;
      write_node->operator = *operator;
      if (value != NULL) {
        write_node->value = value;
        write_node->base.location.end = value->location.end;
      }
      // TODO: hb destory read node
      return YP_NODE_DOWNCAST(write_node);

      // yp_token_t name = target->as.local_variable_read_node.name;
      // yp_parser_local_add(parser, &name);

      // yp_node_clear(target);

      // target->type = YP_NODE_LOCAL_VARIABLE_WRITE_NODE;
      // target->location.start = name.start;

      // target->as.local_variable_write_node.name = name;
      // target->as.local_variable_write_node.operator = *operator;

      // if (value != NULL) {
      //   target->as.local_variable_write_node.value = value;
      //   target->location.end = value->location.end;
      // }

      // return target;
    }
    case YP_NODE_INSTANCE_VARIABLE_READ_NODE:
      yp_instance_variable_write_node_create(parser, target, operator, value);
      return target;
    case YP_NODE_MULTI_WRITE_NODE: {
      yp_multi_write_node_t *write_node = YP_NODE_UPCAST(target, yp_multi_write_node_t);
      write_node->operator = *operator;

      if (value != NULL) {
        write_node->value = value;
        write_node->base.location.end = value->location.end;
      }

      return YP_NODE_DOWNCAST(write_node);
    }
    case YP_NODE_SPLAT_NODE: {
      yp_splat_node_t *splat_node = YP_NODE_UPCAST(target, yp_splat_node_t);
      if (splat_node->expression != NULL) {
        splat_node->expression = parse_target(parser, splat_node->expression, operator, value);
      }

      yp_location_t location = { .start = NULL, .end = NULL };
      yp_node_t *multi_write = yp_multi_write_node_create(parser, operator, value, &location, &location);
      yp_multi_write_node_targets_append(multi_write, target);

      return multi_write;
    }
    case YP_NODE_CALL_NODE: {
      // If we have no arguments to the call node and we need this to be a
      // target then this is either a method call or a local variable write.
      yp_call_node_t *call_node = YP_NODE_UPCAST(target, yp_call_node_t);
      if (
        (call_node->opening.type == YP_TOKEN_NOT_PROVIDED) &&
        (call_node->arguments == NULL) &&
        (call_node->block == NULL)
      ) {
        if (call_node->receiver == NULL) {
          // When we get here, we have a local variable write, because it
          // was previously marked as a method call but now we have an =.
          // This looks like:
          //
          //     foo = 1
          //
          // When it was parsed in the prefix position, foo was seen as a
          // method call with no receiver and no arguments. Now we have an
          // =, so we know it's a local variable write.
          yp_token_t name = call_node->message;
          yp_parser_local_add(parser, &name);

          // Not entirely sure why we need to clear this out, but it seems that
          // something about the memory layout in the union is causing the type
          // to have a problem if we don't.
          // yp_node_clear(target);

          // TODO: hb destroy the call node

          yp_node_t *write_node = yp_local_variable_write_node_create(parser, &name);
          YP_NODE_UPCAST(write_node, yp_local_variable_write_node_t)->operator = *operator;

          // target->type = YP_NODE_LOCAL_VARIABLE_WRITE_NODE;
          // target->location.start = name.start;

          // target->as.local_variable_write_node.name = name;
          // target->as.local_variable_write_node.operator = *operator;

          if (value != NULL) {
            YP_NODE_UPCAST(write_node, yp_local_variable_write_node_t)->value = value;
            write_node->location.end = value->location.end;
            // target->as.local_variable_write_node.value = value;
            // target->location.end = value->location.end;
          }

          if (token_is_numbered_parameter(&name)) {
            yp_diagnostic_list_append(&parser->error_list, name.start, name.end, "reserved for numbered parameter");
          }

          return write_node;
        }

        // When we get here, we have a method call, because it was
        // previously marked as a method call but now we have an =. This
        // looks like:
        //
        //     foo.bar = 1
        //
        // When it was parsed in the prefix position, foo.bar was seen as a
        // method call with no arguments. Now we have an =, so we know it's
        // a method call with an argument. In this case we will create the
        // arguments node, parse the argument, and add it to the list.
        if (value) {
          call_node->arguments = yp_arguments_node_create(parser);
          yp_arguments_node_arguments_append(call_node->arguments, value);
        }

        // The method name needs to change. If we previously had foo, we now
        // need foo=. In this case we'll allocate a new owned string, copy
        // the previous method name in, and append an =.
        size_t length = yp_string_length(&call_node->name);
        char *name = malloc(length + 2);
        sprintf(name, "%.*s=", (int) length, yp_string_source(&call_node->name));

        // Now switch the name to the new string.
        yp_string_free(&call_node->name);
        yp_string_owned_init(&call_node->name, name, length + 1);

        return target;
      }

      // If there is no call operator and the message is "[]" then this is
      // an aref expression, and we can transform it into an aset
      // expression.
      if (
        (call_node->call_operator.type == YP_TOKEN_NOT_PROVIDED) &&
        (call_node->message.type == YP_TOKEN_BRACKET_LEFT_RIGHT) &&
        (call_node->block == NULL)
      ) {
        call_node->message.type = YP_TOKEN_BRACKET_LEFT_RIGHT_EQUAL;

        if (value != NULL) {
          if (call_node->arguments == NULL) {
            call_node->arguments = yp_arguments_node_create(parser);
          }

          yp_arguments_node_arguments_append(call_node->arguments, value);
          call_node->base.location.end = value->location.end;
        }

        // Free the previous name and replace it with "[]=".
        yp_string_free(&call_node->name);
        yp_string_constant_init(&call_node->name, "[]=", 3);
        return YP_NODE_DOWNCAST(call_node);
      }

      // If there are arguments on the call node, then it can't be a method
      // call ending with = or a local variable write, so it must be a
      // syntax error. In this case we'll fall through to our default
      // handling.
    }
    default:
      // In this case we have a node that we don't know how to convert into a
      // target. We need to treat it as an error. For now, we'll mark it as an
      // error and just skip right past it.
      yp_diagnostic_list_append(&parser->error_list, operator->start, operator->end, "Unexpected `='.");
      return target;
  }
}

// Parse a list of targets for assignment. This is used in the case of a for
// loop or a multi-assignment. For example, in the following code:
//
//     for foo, bar in baz
//         ^^^^^^^^
//
// The targets are `foo` and `bar`. This function will either return a single
// target node or a multi-target node.
static yp_node_t *
parse_targets(yp_parser_t *parser, yp_node_t *first_target, yp_binding_power_t binding_power) {
  yp_token_t operator = not_provided(parser);

  // The first_target parameter can be NULL in the case that we're parsing a
  // location that we know requires a multi write, as in the case of a for loop.
  // In this case we will set up the parsing loop slightly differently.
  if (first_target != NULL) {
    first_target = parse_target(parser, first_target, &operator, NULL);

    if (!match_type_p(parser, YP_TOKEN_COMMA)) {
      return first_target;
    }
  }

  yp_location_t lparen_loc = { .start = NULL, .end = NULL };
  yp_node_t *result = yp_multi_write_node_create(parser, &operator, NULL, &lparen_loc, &lparen_loc);

  if (first_target != NULL) {
    yp_multi_write_node_targets_append(result, first_target);
  }

  yp_node_t *target;
  bool has_splat = false;

  if (first_target == NULL || accept(parser, YP_TOKEN_COMMA)) {
    do {
      if (accept(parser, YP_TOKEN_USTAR)) {
        // Here we have a splat operator. It can have a name or be anonymous. It
        // can be the final target or be in the middle if there haven't been any
        // others yet.

        if (has_splat) {
          yp_diagnostic_list_append(&parser->error_list, parser->previous.start, parser->previous.end, "Multiple splats in multi-assignment.");
        }

        yp_token_t star_operator = parser->previous;
        yp_node_t *name = NULL;

        if (token_begins_expression_p(parser->current.type)) {
          yp_token_t operator = not_provided(parser);
          name = parse_expression(parser, binding_power, "Expected an expression after '*'.");
          name = parse_target(parser, name, &operator, NULL);
        }

        yp_node_t *splat = yp_splat_node_create(parser, &star_operator, name);
        yp_multi_write_node_targets_append(result, splat);
        has_splat = true;
      } else if (accept(parser, YP_TOKEN_PARENTHESIS_LEFT)) {
        // Here we have a parenthesized list of targets. We'll recurse down into
        // the parentheses by calling parse_targets again and then finish out
        // the node when it returns.

        yp_token_t lparen = parser->previous;
        yp_node_t *first_child_target = parse_expression(parser, YP_BINDING_POWER_STATEMENT, "Expected an expression after '('.");
        yp_node_t *child_target = parse_targets(parser, first_child_target, YP_BINDING_POWER_STATEMENT);

        expect(parser, YP_TOKEN_PARENTHESIS_RIGHT, "Expected an ')' after multi-assignment.");
        yp_token_t rparen = parser->previous;

        if (child_target->type == YP_NODE_MULTI_WRITE_NODE &&
            first_target == NULL &&
            YP_NODE_UPCAST(result, yp_multi_write_node_t)->targets.size == 0
        ) {
          yp_node_destroy(parser, result);
          result = child_target;
          result->location.start = lparen.start;
          result->location.end = rparen.end;

          YP_NODE_UPCAST(result, yp_multi_write_node_t)->lparen_loc = (yp_location_t) { .start = lparen.start, .end = lparen.end };
          YP_NODE_UPCAST(result, yp_multi_write_node_t)->rparen_loc = (yp_location_t) { .start = rparen.start, .end = rparen.end };
        } else {
          if (child_target->type == YP_NODE_MULTI_WRITE_NODE) {
            target = child_target;
            YP_NODE_UPCAST(target, yp_multi_write_node_t)->lparen_loc = (yp_location_t) { .start = lparen.start, .end = lparen.end };
            YP_NODE_UPCAST(target, yp_multi_write_node_t)->rparen_loc = (yp_location_t) { .start = rparen.start, .end = rparen.end };
          } else {
            yp_token_t operator = not_provided(parser);

            target = yp_multi_write_node_create(
              parser,
              &operator,
              NULL,
              &(yp_location_t) { .start = lparen.start, .end = lparen.end },
              &(yp_location_t) { .start = rparen.start, .end = rparen.end }
            );

            yp_multi_write_node_targets_append(target, child_target);
          }

          target->location.end = rparen.end;
          yp_multi_write_node_targets_append(result, target);
        }
      } else {
        if (!token_begins_expression_p(parser->current.type) && !match_type_p(parser, YP_TOKEN_USTAR)) {
          if (
            first_target == NULL &&
            YP_NODE_UPCAST(result, yp_multi_write_node_t)->targets.size == 0
          ) {
            // If we get here, then we weren't able to parse anything at all, so
            // we need to return a missing node.
            yp_node_destroy(parser, result);
            yp_diagnostic_list_append(&parser->error_list, operator.start, operator.end, "Expected index after for.");
            return yp_missing_node_create(parser, &(yp_location_t) { .start = operator.start, .end = operator.end });
          }

          // If we get here, then we have a trailing , in a multi write node.
          // We need to indicate this somehow in the tree, so we'll add an
          // anonymous splat.
          yp_node_t *splat = yp_splat_node_create(parser, &parser->previous, NULL);
          yp_multi_write_node_targets_append(result, splat);
          return result;
        }

        target = parse_expression(parser, binding_power, "Expected another expression after ','.");
        target = parse_target(parser, target, &operator, NULL);

        yp_multi_write_node_targets_append(result, target);
      }
    } while (accept(parser, YP_TOKEN_COMMA));
  }

  return result;
}

// Parse a list of statements separated by newlines or semicolons.
static yp_node_t *
parse_statements(yp_parser_t *parser, yp_context_t context) {
  context_push(parser, context);
  yp_node_t *statements = yp_statements_node_create(parser);

  while (!context_terminator(context, &parser->current)) {
    // Ignore semicolon without statements before them
    if (accept(parser, YP_TOKEN_SEMICOLON) || accept(parser, YP_TOKEN_NEWLINE)) {
      continue;
    }

    yp_node_t *node = parse_expression(parser, YP_BINDING_POWER_STATEMENT, "Expected to be able to parse an expression.");
    yp_statements_node_body_append(statements, node);

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

// Parse all of the elements of a hash.
static void
parse_assocs(yp_parser_t *parser, yp_node_t *node) {
  while (true) {
    yp_node_t *element;

    switch (parser->current.type) {
      case YP_TOKEN_USTAR_STAR: {
        parser_lex(parser);
        yp_token_t operator = parser->previous;
        yp_node_t *value = NULL;

        if (token_begins_expression_p(parser->current.type)) {
          value = parse_expression(parser, YP_BINDING_POWER_DEFINED, "Expected an expression after ** in hash.");
        } else if (!yp_parser_local_p(parser, &operator)) {
          yp_diagnostic_list_append(&parser->error_list, operator.start, operator.end, "Expected an expression after ** in hash.");
        }

        element = yp_assoc_splat_node_create(parser, value, &operator);
        break;
      }
      case YP_TOKEN_LABEL: {
        parser_lex(parser);

        yp_node_t *key = yp_symbol_node_label_create(parser, &parser->previous);
        yp_token_t operator = not_provided(parser);
        yp_node_t *value = NULL;

        if (token_begins_expression_p(parser->current.type)) {
          value = parse_expression(parser, YP_BINDING_POWER_DEFINED, "Expected an expression after the label in hash.");
        }

        element = yp_assoc_node_create(parser, key, &operator, value);
        break;
      }
      default: {
        yp_node_t *key = parse_expression(parser, YP_BINDING_POWER_DEFINED, "Expected a key in the hash literal.");
        yp_token_t operator;

        if (yp_symbol_node_label_p(key)) {
          operator = not_provided(parser);
        } else {
          expect(parser, YP_TOKEN_EQUAL_GREATER, "Expected a => between the key and the value in the hash.");
          operator = parser->previous;
        }

        yp_node_t *value = parse_expression(parser, YP_BINDING_POWER_DEFINED, "Expected a value in the hash literal.");
        element = yp_assoc_node_create(parser, key, &operator, value);
        break;
      }
    }

    yp_node_list_append(parser, node, &YP_NODE_UPCAST(node, yp_hash_node_t)->elements, element);

    // If there's no comma after the element, then we're done.
    if (!accept(parser, YP_TOKEN_COMMA)) return;

    // If the next element starts with a label or a **, then we know we have
    // another element in the hash, so we'll continue parsing.
    if (match_any_type_p(parser, 2, YP_TOKEN_USTAR_STAR, YP_TOKEN_LABEL)) continue;

    // Otherwise we need to check if the subsequent token begins an expression.
    // If it does, then we'll continue parsing.
    if (token_begins_expression_p(parser->current.type)) continue;

    // Otherwise by default we will exit out of this loop.
    return;
  }
}

// Parse a list of arguments.
static void
parse_arguments(yp_parser_t *parser, yp_node_t *arguments, bool accepts_forwarding, yp_token_type_t terminator) {
  yp_binding_power_t binding_power = yp_binding_powers[parser->current.type].left;

  // First we need to check if the next token is one that could be the start of
  // an argument. If it's not, then we can just return.
  if (
    match_any_type_p(parser, 2, terminator, YP_TOKEN_EOF) ||
    (binding_power != YP_BINDING_POWER_UNSET && binding_power < YP_BINDING_POWER_RANGE) ||
    context_terminator(parser->current_context->context, &parser->current)
  ) {
    return;
  }

  bool parsed_bare_hash = false;
  bool parsed_block_argument = false;

  while (!match_type_p(parser, YP_TOKEN_EOF)) {
    if (parsed_block_argument) {
      yp_diagnostic_list_append(&parser->error_list, parser->current.start, parser->current.end, "Unexpected argument after block argument.");
    }

    yp_node_t *argument = NULL;

    switch (parser->current.type) {
      case YP_TOKEN_USTAR_STAR:
      case YP_TOKEN_LABEL: {
        if (parsed_bare_hash) {
          yp_diagnostic_list_append(&parser->error_list, parser->current.start, parser->current.end, "Unexpected bare hash.");
        }

        yp_token_t opening = not_provided(parser);
        yp_token_t closing = not_provided(parser);
        argument = yp_hash_node_create(parser, &opening, &closing);

        if (!match_any_type_p(parser, 7, terminator, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON, YP_TOKEN_EOF, YP_TOKEN_BRACE_RIGHT, YP_TOKEN_KEYWORD_DO, YP_TOKEN_PARENTHESIS_RIGHT)) {
          parse_assocs(parser, argument);
        }

        parsed_bare_hash = true;
        break;
      }
      case YP_TOKEN_AMPERSAND: {
        parser_lex(parser);
        yp_token_t operator = parser->previous;
        yp_node_t *expression = NULL;

        if (token_begins_expression_p(parser->current.type)) {
          expression = parse_expression(parser, YP_BINDING_POWER_DEFINED, "Expected to be able to parse an argument.");
        } else if (!yp_parser_local_p(parser, &operator)) {
          yp_diagnostic_list_append(&parser->error_list, operator.start, operator.end, "unexpected & when parent method is not forwarding.");
        }

        argument = yp_block_argument_node_create(parser, &operator, expression);
        parsed_block_argument = true;
        break;
      }
      case YP_TOKEN_USTAR: {
        parser_lex(parser);
        yp_token_t operator = parser->previous;

        if (match_any_type_p(parser, 2, YP_TOKEN_PARENTHESIS_RIGHT, YP_TOKEN_COMMA)) {
          if (!yp_parser_local_p(parser, &parser->previous)) {
            yp_diagnostic_list_append(&parser->error_list, operator.start, operator.end, "unexpected * when parent method is not forwarding.");
          }

          argument = yp_splat_node_create(parser, &operator, NULL);
        } else {
          yp_node_t *expression = parse_expression(parser, YP_BINDING_POWER_DEFINED, "Expected an expression after '*' in argument.");

          if (parsed_bare_hash) {
            yp_diagnostic_list_append(&parser->error_list, operator.start, expression->location.end, "Unexpected splat argument after double splat.");
          }

          argument = yp_splat_node_create(parser, &operator, expression);
        }

        break;
      }
      case YP_TOKEN_UDOT_DOT_DOT: {
        if (accepts_forwarding) {
          parser_lex(parser);

          if (token_begins_expression_p(parser->current.type)) {
            // If the token begins an expression then this ... was not actually
            // argument forwarding but was instead a range.
            yp_token_t operator = parser->previous;
            yp_node_t *right = parse_expression(parser, YP_BINDING_POWER_RANGE, "Expected a value after the operator.");
            argument = yp_range_node_create(parser, NULL, &operator, right);
          } else {
            if (!yp_parser_local_p(parser, &parser->previous)) {
              yp_diagnostic_list_append(&parser->error_list, parser->previous.start, parser->previous.end, "unexpected ... when parent method is not forwarding.");
            }

            argument = yp_forwarding_arguments_node_create(parser, &parser->previous);
            break;
          }
        }

        // fallthrough
      }
      default: {
        if (argument == NULL) {
          argument = parse_expression(parser, YP_BINDING_POWER_DEFINED, "Expected to be able to parse an argument.");
        }

        if (yp_symbol_node_label_p(argument) || accept(parser, YP_TOKEN_EQUAL_GREATER)) {
          if (parsed_bare_hash) {
            yp_diagnostic_list_append(&parser->error_list, parser->previous.start, parser->previous.end, "Unexpected bare hash argument.");
          }

          yp_token_t operator;
          if (parser->previous.type == YP_TOKEN_EQUAL_GREATER) {
            operator = parser->previous;
          } else {
            operator = not_provided(parser);
          }

          yp_token_t opening = not_provided(parser);
          yp_token_t closing = not_provided(parser);
          yp_hash_node_t *bare_hash = YP_NODE_UPCAST(yp_hash_node_create(parser, &opening, &closing), yp_hash_node_t);

          // Finish parsing the one we are part way through
          yp_node_t *value = parse_expression(parser, YP_BINDING_POWER_DEFINED, "Expected a value in the hash literal.");

          argument = yp_assoc_node_create(parser, argument, &operator, value);
          yp_node_list_append(parser, YP_NODE_DOWNCAST(bare_hash), &bare_hash->elements, argument);
          argument = YP_NODE_DOWNCAST(bare_hash);

          // Then parse more if we have a comma
          if (accept(parser, YP_TOKEN_COMMA) && (
            token_begins_expression_p(parser->current.type) ||
            match_any_type_p(parser, 2, YP_TOKEN_USTAR_STAR, YP_TOKEN_LABEL)
          )) {
            parse_assocs(parser, argument);
          }

          parsed_bare_hash = true;
        }

        break;
      }
    }

    yp_arguments_node_arguments_append(arguments, argument);

    // If parsing the argument failed, we need to stop parsing arguments.
    if (argument->type == YP_NODE_MISSING_NODE || parser->recovering) break;

    // If the terminator of these arguments is not EOF, then we have a specific
    // token we're looking for. In that case we can accept a newline here
    // because it is not functioning as a statement terminator.
    if (terminator != YP_TOKEN_EOF) accept(parser, YP_TOKEN_NEWLINE);

    if (parser->previous.type == YP_TOKEN_COMMA && parsed_bare_hash) {
      // If we previously were on a comma and we just parsed a bare hash, then
      // we want to continue parsing arguments. This is because the comma was
      // grabbed up by the hash parser.
    } else {
      // If there is no comma at the end of the argument list then we're done
      // parsing arguments and can break out of this loop.
      if (!accept(parser, YP_TOKEN_COMMA)) break;
    }

    // If we hit the terminator, then that means we have a trailing comma so we
    // can accept that output as well.
    if (match_type_p(parser, terminator)) break;
  }
}

// Required parameters on method, block, and lambda declarations can be
// destructured using parentheses. This looks like:
//
//     def foo((bar, baz))
//     end
//
// It can recurse infinitely down, and splats are allowed to group arguments.
static yp_node_t *
parse_required_destructured_parameter(yp_parser_t *parser) {
  expect(parser, YP_TOKEN_PARENTHESIS_LEFT, "Expected '(' to start a required parameter.");

  yp_token_t opening = parser->previous;
  yp_required_destructured_parameter_node_t *node = YP_NODE_UPCAST(
    yp_required_destructured_parameter_node_create(parser, &opening, &opening),
    yp_required_destructured_parameter_node_t
  );
  bool parsed_splat;

  do {
    yp_node_t *param;

    if (node->parameters.size > 0 && match_type_p(parser, YP_TOKEN_PARENTHESIS_RIGHT)) {
      if (parsed_splat) {
        yp_diagnostic_list_append(&parser->error_list, parser->previous.start, parser->previous.end, "Unexpected splat after splat.");
      }

      param = yp_splat_node_create(parser, &parser->previous, NULL);
      yp_node_list_append(parser, YP_NODE_DOWNCAST(node), &node->parameters, param);
      break;
    }

    if (match_type_p(parser, YP_TOKEN_PARENTHESIS_LEFT)) {
      param = parse_required_destructured_parameter(parser);
    } else if (accept(parser, YP_TOKEN_USTAR)) {
      if (parsed_splat) {
        yp_diagnostic_list_append(&parser->error_list, parser->previous.start, parser->previous.end, "Unexpected splat after splat.");
      }

      yp_token_t star = parser->previous;
      yp_node_t *value = NULL;

      if (accept(parser, YP_TOKEN_IDENTIFIER)) {
        yp_token_t name = parser->previous;
        value = yp_required_parameter_node_create(parser, &name);
        yp_parser_local_add(parser, &name);
      }

      param = yp_splat_node_create(parser, &star, value);
      parsed_splat = true;
    } else {
      expect(parser, YP_TOKEN_IDENTIFIER, "Expected an identifier for a required parameter.");
      yp_token_t name = parser->previous;

      param = yp_required_parameter_node_create(parser, &name);
      yp_parser_local_add(parser, &name);
    }

    yp_node_list_append(parser, YP_NODE_DOWNCAST(node), &node->parameters, param);
  } while (accept(parser, YP_TOKEN_COMMA));

  expect(parser, YP_TOKEN_PARENTHESIS_RIGHT, "Expected ')' to end a required parameter.");
  node->closing = parser->previous;
  node->base.location.end = parser->previous.end;

  return YP_NODE_DOWNCAST(node);
}

// Parse a list of parameters on a method definition.
static yp_node_t *
parse_parameters(
  yp_parser_t *parser,
  yp_binding_power_t binding_power,
  bool uses_parentheses,
  bool allows_trailing_comma
) {
  yp_node_t *params = yp_parameters_node_create(parser);

  do {
    switch (parser->current.type) {
      case YP_TOKEN_PARENTHESIS_LEFT: {
        yp_node_t *param = parse_required_destructured_parameter(parser);
        yp_parameters_node_requireds_append(params, param);
        break;
      }
      case YP_TOKEN_AMPERSAND: {
        parser_lex(parser);

        yp_token_t operator = parser->previous;
        yp_token_t name;

        if (accept(parser, YP_TOKEN_IDENTIFIER)) {
          name = parser->previous;
          yp_parser_local_add(parser, &name);
        } else {
          name = not_provided(parser);
          yp_parser_local_add(parser, &operator);
        }

        yp_node_t *param = yp_block_parameter_node_create(parser, &name, &operator);
        yp_parameters_node_block_set(params, param);
        break;
      }
      case YP_TOKEN_UDOT_DOT_DOT: {
        parser_lex(parser);

        yp_parser_local_add(parser, &parser->previous);
        yp_node_t *param = yp_forwarding_parameter_node_create(parser, &parser->previous);
        yp_parameters_node_keyword_rest_set(params, param);
        break;
      }
      case YP_TOKEN_IDENTIFIER: {
        parser_lex(parser);

        yp_token_t name = parser->previous;
        yp_parser_local_add(parser, &name);

        if (accept(parser, YP_TOKEN_EQUAL)) {
          yp_token_t operator = parser->previous;
          yp_node_t *value = parse_expression(parser, binding_power, "Expected to find a default value for the parameter.");

          yp_node_t *param = yp_optional_parameter_node_create(parser, &name, &operator, value);
          yp_parameters_node_optionals_append(params, param);

          // If parsing the value of the parameter resulted in error recovery,
          // then we can put a missing node in its place and stop parsing the
          // parameters entirely now.
          if (parser->recovering) return params;
        } else {
          yp_node_t *param = yp_required_parameter_node_create(parser, &name);
          yp_parameters_node_requireds_append(params, param);
        }

        break;
      }
      case YP_TOKEN_LABEL: {
        parser_lex(parser);

        yp_token_t name = parser->previous;
        yp_token_t local = name;
        local.end -= 1;
        yp_parser_local_add(parser, &local);

        switch (parser->current.type) {
          case YP_TOKEN_COMMA:
          case YP_TOKEN_PARENTHESIS_RIGHT:
          case YP_TOKEN_PIPE: {
            yp_node_t *param = yp_keyword_parameter_node_create(parser, &name, NULL);
            yp_parameters_node_keywords_append(params, param);
            break;
          }
          case YP_TOKEN_SEMICOLON:
          case YP_TOKEN_NEWLINE: {
            if (uses_parentheses) {
              return params;
            }

            yp_node_t *param = yp_keyword_parameter_node_create(parser, &name, NULL);
            yp_parameters_node_keywords_append(params, param);
            break;
          }
          default: {
            yp_node_t *value = NULL;
            if (token_begins_expression_p(parser->current.type)) {
              value = parse_expression(parser, binding_power, "Expected to find a default value for the keyword parameter.");
            }

            yp_node_t *param = yp_keyword_parameter_node_create(parser, &name, value);
            yp_parameters_node_keywords_append(params, param);

            // If parsing the value of the parameter resulted in error recovery,
            // then we can put a missing node in its place and stop parsing the
            // parameters entirely now.
            if (parser->recovering) return params;
          }
        }

        break;
      }
      case YP_TOKEN_USTAR:
      case YP_TOKEN_STAR: {
        parser_lex(parser);

        yp_token_t operator = parser->previous;
        yp_token_t name;

        if (accept(parser, YP_TOKEN_IDENTIFIER)) {
          name = parser->previous;
          yp_parser_local_add(parser, &name);
        } else {
          name = not_provided(parser);
          yp_parser_local_add(parser, &operator);
        }

        yp_node_t *param = yp_rest_parameter_node_create(parser, &operator, &name);
        yp_parameters_node_rest_set(params, param);
        break;
      }
      case YP_TOKEN_STAR_STAR:
      case YP_TOKEN_USTAR_STAR: {
        parser_lex(parser);

        yp_token_t operator = parser->previous;
        yp_node_t *param;

        if (accept(parser, YP_TOKEN_KEYWORD_NIL)) {
          param = yp_no_keywords_parameter_node_create(parser, &operator, &parser->previous);
        } else {
          yp_token_t name;

          if (accept(parser, YP_TOKEN_IDENTIFIER)) {
            name = parser->previous;
            yp_parser_local_add(parser, &name);
          } else {
            name = not_provided(parser);
            yp_parser_local_add(parser, &operator);
          }

          param = yp_keyword_rest_parameter_node_create(parser, &operator, &name);
        }

        yp_parameters_node_keyword_rest_set(params, param);
        break;
      }
      case YP_TOKEN_CONSTANT:
        parser_lex(parser);
        yp_diagnostic_list_append(&parser->error_list, parser->previous.start, parser->previous.end, "Formal argument cannot be a constant");
        break;
      case YP_TOKEN_INSTANCE_VARIABLE:
        parser_lex(parser);
        yp_diagnostic_list_append(&parser->error_list, parser->previous.start, parser->previous.end, "Formal argument cannot be an instance variable");
        break;
      case YP_TOKEN_GLOBAL_VARIABLE:
        parser_lex(parser);
        yp_diagnostic_list_append(&parser->error_list, parser->previous.start, parser->previous.end, "Formal argument cannot be a global variable");
        break;
      case YP_TOKEN_CLASS_VARIABLE:
        parser_lex(parser);
        yp_diagnostic_list_append(&parser->error_list, parser->previous.start, parser->previous.end, "Formal argument cannot be a class variable");
        break;
      default:
        if (parser->previous.type == YP_TOKEN_COMMA) {
          if (allows_trailing_comma) {
            // If we get here, then we have a trailing comma in a block
            // parameter list. We need to create an anonymous rest parameter to
            // represent it.
            yp_token_t name = not_provided(parser);
            yp_node_t *param = yp_rest_parameter_node_create(parser, &parser->previous, &name);
            yp_parameters_node_rest_set(params, param);
          } else {
            yp_diagnostic_list_append(&parser->error_list, parser->previous.start, parser->previous.end, "Unexpected ','.");
          }
        }

        return params;
    }

    if (uses_parentheses) {
      accept(parser, YP_TOKEN_NEWLINE);
    }
  } while (accept(parser, YP_TOKEN_COMMA));

  return params;
}

// Parse any number of rescue clauses. This will form a linked list of if
// nodes pointing to each other from the top.
static inline void
parse_rescues(yp_parser_t *parser, yp_node_t *parent_node) {
  yp_node_t *current = NULL;

  while (accept(parser, YP_TOKEN_KEYWORD_RESCUE)) {
    yp_rescue_node_t *rescue = YP_NODE_UPCAST(
      yp_rescue_node_create(parser, &parser->previous),
      yp_rescue_node_t
    );

    switch (parser->current.type) {
      case YP_TOKEN_EQUAL_GREATER: {
        // Here we have an immediate => after the rescue keyword, in which case
        // we're going to have an empty list of exceptions to rescue (which
        // implies StandardError).
        parser_lex(parser);
        rescue->equal_greater = parser->previous;

        yp_node_t *node = parse_expression(parser, YP_BINDING_POWER_INDEX, "Expected an exception variable after `=>` in rescue statement.");
        yp_token_t operator = not_provided(parser);
        node = parse_target(parser, node, &operator, NULL);

        rescue->exception = node;
        break;
      }
      case YP_TOKEN_NEWLINE:
      case YP_TOKEN_SEMICOLON:
      case YP_TOKEN_KEYWORD_THEN:
        // Here we have a terminator for the rescue keyword, in which case we're
        // going to just continue on.
        break;
      default: {
        if (token_begins_expression_p(parser->current.type) || match_type_p(parser, YP_TOKEN_USTAR)) {
          // Here we have something that could be an exception expression, so
          // we'll attempt to parse it here and any others delimited by commas.

          do {
            yp_node_t *expression = parse_starred_expression(parser, YP_BINDING_POWER_DEFINED, "Expected to find a rescued expression.");
            yp_node_list_append(parser, YP_NODE_DOWNCAST(rescue), &rescue->exceptions, expression);

            // If we hit a newline, then this is the end of the rescue expression. We
            // can continue on to parse the statements.
            if (match_any_type_p(parser, 3, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON, YP_TOKEN_KEYWORD_THEN)) break;

            // If we hit a `=>` then we're going to parse the exception variable. Once
            // we've done that, we'll break out of the loop and parse the statements.
            if (accept(parser, YP_TOKEN_EQUAL_GREATER)) {
              rescue->equal_greater = parser->previous;

              yp_node_t *node = parse_expression(parser, YP_BINDING_POWER_INDEX, "Expected an exception variable after `=>` in rescue statement.");
              yp_token_t operator = not_provided(parser);
              node = parse_target(parser, node, &operator, NULL);

              yp_rescue_node_exception_set(YP_NODE_DOWNCAST(rescue), node);
              break;
            }
          } while (accept(parser, YP_TOKEN_COMMA));
        }
      }
    }

    if (accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON)) {
      accept(parser, YP_TOKEN_KEYWORD_THEN);
    } else {
      expect(parser, YP_TOKEN_KEYWORD_THEN, "Expected a terminator after rescue clause.");
    }

    if (!match_any_type_p(parser, 3, YP_TOKEN_KEYWORD_ELSE, YP_TOKEN_KEYWORD_ENSURE, YP_TOKEN_KEYWORD_END)) {
      yp_rescue_node_statements_set(YP_NODE_DOWNCAST(rescue), parse_statements(parser, YP_CONTEXT_RESCUE));
      accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);
    }

    if (current == NULL) {
      yp_begin_node_rescue_clause_set(parent_node, YP_NODE_DOWNCAST(rescue));
    } else {
      YP_NODE_UPCAST(current, yp_rescue_node_t)->consequent = YP_NODE_DOWNCAST(rescue);
    }

    current = YP_NODE_DOWNCAST(rescue);
  }

  if (accept(parser, YP_TOKEN_KEYWORD_ELSE)) {
    yp_token_t else_keyword = parser->previous;
    accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

    yp_node_t *else_statements = NULL;
    if (!match_any_type_p(parser, 2, YP_TOKEN_KEYWORD_END, YP_TOKEN_KEYWORD_ENSURE)) {
      else_statements = parse_statements(parser, YP_CONTEXT_RESCUE_ELSE);
      accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);
    }

    yp_node_t *else_clause = yp_else_node_create(parser, &else_keyword, else_statements, &parser->current);
    yp_begin_node_else_clause_set(parent_node, else_clause);
  }

  if (accept(parser, YP_TOKEN_KEYWORD_ENSURE)) {
    yp_token_t ensure_keyword = parser->previous;
    accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

    yp_node_t *ensure_statements = NULL;
    if (!match_type_p(parser, YP_TOKEN_KEYWORD_END)) {
      ensure_statements = parse_statements(parser, YP_CONTEXT_ENSURE);
      accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);
    }

    yp_node_t *ensure_clause = yp_ensure_node_create(parser, &ensure_keyword, ensure_statements, &parser->current);
    yp_begin_node_ensure_clause_set(parent_node, ensure_clause);
  }

  if (parser->current.type == YP_TOKEN_KEYWORD_END) {
    yp_begin_node_end_keyword_set(parent_node, &parser->current);
  } else {
    yp_token_t end_keyword = (yp_token_t) { .type = YP_TOKEN_MISSING, .start = parser->previous.end, .end = parser->previous.end };
    yp_begin_node_end_keyword_set(parent_node, &end_keyword);
  }
}

static inline yp_node_t *
parse_rescues_as_begin(yp_parser_t *parser, yp_node_t *statements) {
  yp_token_t no_begin_token = not_provided(parser);
  yp_node_t *begin_node = yp_begin_node_create(parser, &no_begin_token, statements);
  parse_rescues(parser, begin_node);
  return begin_node;
}

// Parse a list of parameters and local on a block definition.
static yp_node_t *
parse_block_parameters(yp_parser_t *parser, bool allows_trailing_comma) {
  yp_node_t *parameters = NULL;
  if (!match_type_p(parser, YP_TOKEN_SEMICOLON)) {
    parameters = parse_parameters(parser, YP_BINDING_POWER_INDEX, false, allows_trailing_comma);
  }

  yp_node_t *block_parameters = yp_block_parameters_node_create(parser, parameters);
  if (accept(parser, YP_TOKEN_SEMICOLON)) {
    do {
      expect(parser, YP_TOKEN_IDENTIFIER, "Expected a local variable name.");
      yp_parser_local_add(parser, &parser->previous);
      yp_block_parameters_node_append_local(block_parameters, &parser->previous);
    } while (accept(parser, YP_TOKEN_COMMA));
  }

  return block_parameters;
}

// Parse a block.
static yp_node_t *
parse_block(yp_parser_t *parser) {
  yp_token_t opening = parser->previous;
  accept(parser, YP_TOKEN_NEWLINE);

  yp_accepts_block_stack_push(parser, true);
  yp_parser_scope_push(parser, &opening, false);
  yp_node_t *parameters = NULL;

  if (accept(parser, YP_TOKEN_PIPE)) {
    parameters = parse_block_parameters(parser, true);
    accept(parser, YP_TOKEN_NEWLINE);

    parser->command_start = true;
    expect(parser, YP_TOKEN_PIPE, "Expected block parameters to end with '|'.");
  }

  accept(parser, YP_TOKEN_NEWLINE);

  yp_node_t *statements = NULL;

  if (opening.type == YP_TOKEN_BRACE_LEFT) {
    if (!match_type_p(parser, YP_TOKEN_BRACE_RIGHT)) {
      statements = parse_statements(parser, YP_CONTEXT_BLOCK_BRACES);
    }

    expect(parser, YP_TOKEN_BRACE_RIGHT, "Expected block beginning with '{' to end with '}'.");
  } else {
    if (!match_type_p(parser, YP_TOKEN_KEYWORD_END)) {
      if (!match_any_type_p(parser, 3, YP_TOKEN_KEYWORD_RESCUE, YP_TOKEN_KEYWORD_ELSE, YP_TOKEN_KEYWORD_ENSURE)) {
        statements = parse_statements(parser, YP_CONTEXT_BLOCK_KEYWORDS);
      }

      if (match_any_type_p(parser, 2, YP_TOKEN_KEYWORD_RESCUE, YP_TOKEN_KEYWORD_ENSURE)) {
        statements = parse_rescues_as_begin(parser, statements);
      }
    }

    expect(parser, YP_TOKEN_KEYWORD_END, "Expected block beginning with 'do' to end with 'end'.");
  }

  yp_node_t *scope = parser->current_scope->node;
  yp_parser_scope_pop(parser);
  yp_accepts_block_stack_pop(parser);
  return yp_block_node_create(parser, scope, &opening, parameters, statements, &parser->previous);
}

// Parse a list of arguments and their surrounding parentheses if they are
// present.
static void
parse_arguments_list(yp_parser_t *parser, yp_arguments_t *arguments, bool accepts_block) {
  if (accept(parser, YP_TOKEN_PARENTHESIS_LEFT)) {
    arguments->opening = parser->previous;

    if (accept(parser, YP_TOKEN_PARENTHESIS_RIGHT)) {
      arguments->closing = parser->previous;
    } else {
      arguments->arguments = yp_arguments_node_create(parser);

      yp_accepts_block_stack_push(parser, true);
      parse_arguments(parser, arguments->arguments, true, YP_TOKEN_PARENTHESIS_RIGHT);
      expect(parser, YP_TOKEN_PARENTHESIS_RIGHT, "Expected a ')' to close the argument list.");
      yp_accepts_block_stack_pop(parser);

      arguments->closing = parser->previous;
    }
  } else if ((token_begins_expression_p(parser->current.type) || match_any_type_p(parser, 2, YP_TOKEN_USTAR, YP_TOKEN_USTAR_STAR)) && !match_type_p(parser, YP_TOKEN_BRACE_LEFT)) {
    yp_accepts_block_stack_push(parser, false);

    // If we get here, then the subsequent token cannot be used as an infix
    // operator. In this case we assume the subsequent token is part of an
    // argument to this method call.
    arguments->arguments = yp_arguments_node_create(parser);
    parse_arguments(parser, arguments->arguments, true, YP_TOKEN_EOF);

    yp_accepts_block_stack_pop(parser);
  }

  // If we're at the end of the arguments, we can now check if there is a block
  // node that starts with a {. If there is, then we can parse it and add it to
  // the arguments.
  if (accepts_block) {
    if (accept(parser, YP_TOKEN_BRACE_LEFT)) {
      arguments->block = parse_block(parser);
    } else if (yp_accepts_block_stack_p(parser) && accept(parser, YP_TOKEN_KEYWORD_DO)) {
      arguments->block = parse_block(parser);
    }
  }
}

static inline yp_node_t *
parse_conditional(yp_parser_t *parser, yp_context_t context) {
  yp_token_t keyword = parser->previous;

  context_push(parser, YP_CONTEXT_PREDICATE);
  yp_node_t *predicate = parse_expression(parser, YP_BINDING_POWER_COMPOSITION, "Expected to find a predicate for the conditional.");

  // Predicates are closed by a term, a "then", or a term and then a "then".
  accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);
  accept(parser, YP_TOKEN_KEYWORD_THEN);

  context_pop(parser);
  yp_node_t *statements = NULL;

  if (!match_any_type_p(parser, 3, YP_TOKEN_KEYWORD_ELSIF, YP_TOKEN_KEYWORD_ELSE, YP_TOKEN_KEYWORD_END)) {
    statements = parse_statements(parser, context);
    accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);
  }

  yp_token_t end_keyword = not_provided(parser);
  yp_node_t *parent;

  switch (context) {
    case YP_CONTEXT_IF:
      parent = yp_if_node_create(parser, &keyword, predicate, statements, NULL, &end_keyword);
      break;
    case YP_CONTEXT_UNLESS:
      parent = yp_unless_node_create(parser, &keyword, predicate, statements, NULL, &end_keyword);
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
    yp_node_t *predicate = parse_expression(parser, YP_BINDING_POWER_COMPOSITION, "Expected to find a predicate for the elsif clause.");

    // Predicates are closed by a term, a "then", or a term and then a "then".
    accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);
    accept(parser, YP_TOKEN_KEYWORD_THEN);

    yp_node_t *statements = parse_statements(parser, YP_CONTEXT_ELSIF);
    accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

    yp_node_t *elsif = yp_if_node_create(parser, &elsif_keyword, predicate, statements, NULL, &end_keyword);
    YP_NODE_UPCAST(current, yp_if_node_t)->consequent = elsif;
    current = elsif;
  }

  switch (parser->current.type) {
    case YP_TOKEN_KEYWORD_ELSE: {
      parser_lex(parser);
      yp_token_t else_keyword = parser->previous;
      yp_node_t *else_statements = parse_statements(parser, YP_CONTEXT_ELSE);

      accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);
      expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close `else` clause.");

      yp_node_t *else_node = yp_else_node_create(parser, &else_keyword, else_statements, &parser->previous);
      YP_NODE_UPCAST(current, yp_if_node_t)->consequent = else_node;
      YP_NODE_UPCAST(parent, yp_if_node_t)->end_keyword = parser->previous;
      break;
    }
    case YP_TOKEN_KEYWORD_END: {
      parser_lex(parser);
      YP_NODE_UPCAST(parent, yp_if_node_t)->end_keyword = parser->previous;
      break;
    }
    default:
      expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close `if` statement.");
      YP_NODE_UPCAST(parent, yp_if_node_t)->end_keyword = parser->previous;
      break;
  }

  return parent;
}

// This macro allows you to define a case statement for all of the keywords.
// It's meant to be used in a switch statement.
#define YP_CASE_KEYWORD YP_TOKEN_KEYWORD___LINE__: case YP_TOKEN_KEYWORD___FILE__: case YP_TOKEN_KEYWORD_ALIAS: \
  case YP_TOKEN_KEYWORD_AND: case YP_TOKEN_KEYWORD_BEGIN: case YP_TOKEN_KEYWORD_BEGIN_UPCASE: \
  case YP_TOKEN_KEYWORD_BREAK: case YP_TOKEN_KEYWORD_CASE: case YP_TOKEN_KEYWORD_CLASS: case YP_TOKEN_KEYWORD_DEF: \
  case YP_TOKEN_KEYWORD_DEFINED: case YP_TOKEN_KEYWORD_DO: case YP_TOKEN_KEYWORD_DO_LOOP: case YP_TOKEN_KEYWORD_ELSE: \
  case YP_TOKEN_KEYWORD_ELSIF: case YP_TOKEN_KEYWORD_END: case YP_TOKEN_KEYWORD_END_UPCASE: \
  case YP_TOKEN_KEYWORD_ENSURE: case YP_TOKEN_KEYWORD_FALSE: case YP_TOKEN_KEYWORD_FOR: case YP_TOKEN_KEYWORD_IF: \
  case YP_TOKEN_KEYWORD_IN: case YP_TOKEN_KEYWORD_MODULE: case YP_TOKEN_KEYWORD_NEXT: case YP_TOKEN_KEYWORD_NIL: \
  case YP_TOKEN_KEYWORD_NOT: case YP_TOKEN_KEYWORD_OR: case YP_TOKEN_KEYWORD_REDO: case YP_TOKEN_KEYWORD_RESCUE: \
  case YP_TOKEN_KEYWORD_RETRY: case YP_TOKEN_KEYWORD_RETURN: case YP_TOKEN_KEYWORD_SELF: case YP_TOKEN_KEYWORD_SUPER: \
  case YP_TOKEN_KEYWORD_THEN: case YP_TOKEN_KEYWORD_TRUE: case YP_TOKEN_KEYWORD_UNDEF: case YP_TOKEN_KEYWORD_UNLESS: \
  case YP_TOKEN_KEYWORD_UNTIL: case YP_TOKEN_KEYWORD_WHEN: case YP_TOKEN_KEYWORD_WHILE: case YP_TOKEN_KEYWORD_YIELD

// This macro allows you to define a case statement for all of the operators.
// It's meant to be used in a switch statement.
#define YP_CASE_OPERATOR YP_TOKEN_AMPERSAND: case YP_TOKEN_BACKTICK: case YP_TOKEN_BANG_EQUAL: \
  case YP_TOKEN_BANG_TILDE: case YP_TOKEN_BANG: case YP_TOKEN_BRACKET_LEFT_RIGHT_EQUAL: \
  case YP_TOKEN_BRACKET_LEFT_RIGHT: case YP_TOKEN_CARET: case YP_TOKEN_EQUAL_EQUAL_EQUAL: case YP_TOKEN_EQUAL_EQUAL: \
  case YP_TOKEN_EQUAL_TILDE: case YP_TOKEN_GREATER_EQUAL: case YP_TOKEN_GREATER_GREATER: case YP_TOKEN_GREATER: \
  case YP_TOKEN_LESS_EQUAL_GREATER: case YP_TOKEN_LESS_EQUAL: case YP_TOKEN_LESS_LESS: case YP_TOKEN_LESS: \
  case YP_TOKEN_MINUS: case YP_TOKEN_PERCENT: case YP_TOKEN_PIPE: case YP_TOKEN_PLUS: case YP_TOKEN_SLASH: \
  case YP_TOKEN_STAR_STAR: case YP_TOKEN_STAR: case YP_TOKEN_TILDE: case YP_TOKEN_UMINUS: case YP_TOKEN_UMINUS_NUM: \
  case YP_TOKEN_UPLUS: case YP_TOKEN_USTAR: case YP_TOKEN_USTAR_STAR

// This macro allows you to define a case statement for all of the token types
// that represent the beginning of nodes that are "primitives" in a pattern
// matching expression.
#define YP_CASE_PRIMITIVE YP_TOKEN_INTEGER: case YP_TOKEN_FLOAT: case YP_TOKEN_RATIONAL_NUMBER: \
  case YP_TOKEN_IMAGINARY_NUMBER: case YP_TOKEN_SYMBOL_BEGIN: case YP_TOKEN_REGEXP_BEGIN: case YP_TOKEN_BACKTICK: \
  case YP_TOKEN_PERCENT_LOWER_X: case YP_TOKEN_PERCENT_LOWER_I: case YP_TOKEN_PERCENT_LOWER_W: \
  case YP_TOKEN_PERCENT_UPPER_I: case YP_TOKEN_PERCENT_UPPER_W: case YP_TOKEN_STRING_BEGIN: case YP_TOKEN_KEYWORD_NIL: \
  case YP_TOKEN_KEYWORD_SELF: case YP_TOKEN_KEYWORD_TRUE: case YP_TOKEN_KEYWORD_FALSE: case YP_TOKEN_KEYWORD___FILE__: \
  case YP_TOKEN_KEYWORD___LINE__: case YP_TOKEN_KEYWORD___ENCODING__: case YP_TOKEN_MINUS_GREATER: \
  case YP_TOKEN_HEREDOC_START: case YP_TOKEN_UMINUS_NUM

// This macro allows you to define a case statement for all of the token types
// that could begin a parameter.
#define YP_CASE_PARAMETER YP_TOKEN_AMPERSAND: case YP_TOKEN_UDOT_DOT_DOT: case YP_TOKEN_IDENTIFIER: \
  case YP_TOKEN_LABEL: case YP_TOKEN_USTAR: case YP_TOKEN_STAR: case YP_TOKEN_STAR_STAR: case YP_TOKEN_USTAR_STAR: case YP_TOKEN_CONSTANT: \
  case YP_TOKEN_INSTANCE_VARIABLE: case YP_TOKEN_GLOBAL_VARIABLE: case YP_TOKEN_CLASS_VARIABLE

// This macro allows you to define a case statement for all of the nodes that
// can be transformed into write targets.
#define YP_CASE_WRITABLE YP_NODE_CLASS_VARIABLE_READ_NODE: case YP_NODE_CONSTANT_PATH_NODE: \
  case YP_NODE_CONSTANT_READ_NODE: case YP_NODE_GLOBAL_VARIABLE_READ_NODE: case YP_NODE_LOCAL_VARIABLE_READ_NODE: \
  case YP_NODE_INSTANCE_VARIABLE_READ_NODE: case YP_NODE_MULTI_WRITE_NODE

// Parse a node that is part of a string. If the subsequent tokens cannot be
// parsed as a string part, then NULL is returned.
static yp_node_t *
parse_string_part(yp_parser_t *parser) {
  switch (parser->current.type) {
    // Here the lexer has returned to us plain string content. In this case
    // we'll create a string node that has no opening or closing and return that
    // as the part. These kinds of parts look like:
    //
    //     "aaa #{bbb} #@ccc ddd"
    //      ^^^^      ^     ^^^^
    case YP_TOKEN_STRING_CONTENT: {
      parser_lex(parser);

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
      yp_lex_state_t state = parser->lex_state;
      int brace_nesting = parser->brace_nesting;

      parser->brace_nesting = 0;
      lex_state_set(parser, YP_LEX_STATE_BEG);
      parser_lex(parser);

      yp_token_t opening = parser->previous;
      yp_node_t *statements = NULL;

      if (!match_type_p(parser, YP_TOKEN_EMBEXPR_END)) {
        yp_accepts_block_stack_push(parser, true);
        statements = parse_statements(parser, YP_CONTEXT_EMBEXPR);
        yp_accepts_block_stack_pop(parser);
      }

      parser->brace_nesting = brace_nesting;
      lex_state_set(parser, state);

      expect(parser, YP_TOKEN_EMBEXPR_END, "Expected a closing delimiter for an embedded expression.");
      yp_token_t closing = parser->previous;

      return yp_string_interpolated_node_create(parser, &opening, statements, &closing);
    }
    // Here the lexer has returned the beginning of an embedded variable. In
    // that case we'll parse the variable and create an appropriate node for it
    // and then return that node. These kinds of parts look like:
    //
    //     "aaa #{bbb} #@ccc ddd"
    //                 ^^^^^
    case YP_TOKEN_EMBVAR: {
      lex_state_set(parser, YP_LEX_STATE_BEG);
      parser_lex(parser);

      switch (parser->current.type) {
        // In this case a global variable is being interpolated. We'll create
        // a global variable read node.
        case YP_TOKEN_BACK_REFERENCE:
        case YP_TOKEN_GLOBAL_VARIABLE:
        case YP_TOKEN_NTH_REFERENCE:
          parser_lex(parser);
          return yp_global_variable_read_node_create(parser, &parser->previous);
        // In this case an instance variable is being interpolated. We'll
        // create an instance variable read node.
        case YP_TOKEN_INSTANCE_VARIABLE:
          parser_lex(parser);
          return yp_instance_variable_read_node_create(parser, &parser->previous);
        // In this case a class variable is being interpolated. We'll create a
        // class variable read node.
        case YP_TOKEN_CLASS_VARIABLE:
          parser_lex(parser);
          return yp_class_variable_read_node_create(parser, &parser->previous);
        // We can hit here if we got an invalid token. In that case we'll not
        // attempt to lex this token and instead just return a missing node.
        default:
          expect(parser, YP_TOKEN_IDENTIFIER, "Expected a valid embedded variable.");

          return yp_missing_node_create(parser, &(yp_location_t) {
            .start = parser->current.start,
            .end = parser->current.end
          });
      }
    }
    default:
      parser_lex(parser);
      yp_diagnostic_list_append(&parser->error_list, parser->previous.start, parser->previous.end, "Could not understand string part");
      return NULL;
  }
}

static yp_node_t *
parse_symbol(yp_parser_t *parser, yp_lex_mode_t *lex_mode, yp_lex_state_t next_state) {
  yp_token_t opening = parser->previous;

  if (lex_mode->mode != YP_LEX_STRING) {
    if (next_state != YP_LEX_STATE_NONE) {
      lex_state_set(parser, next_state);
    }
    yp_token_t symbol;

    switch (parser->current.type) {
      case YP_TOKEN_IDENTIFIER:
      case YP_TOKEN_CONSTANT:
      case YP_TOKEN_INSTANCE_VARIABLE:
      case YP_TOKEN_CLASS_VARIABLE:
      case YP_TOKEN_GLOBAL_VARIABLE:
      case YP_TOKEN_NTH_REFERENCE:
      case YP_TOKEN_BACK_REFERENCE:
      case YP_CASE_KEYWORD:
        parser_lex(parser);
        symbol = parser->previous;
        break;
      case YP_CASE_OPERATOR:
        lex_state_set(parser, next_state == YP_LEX_STATE_NONE ? YP_LEX_STATE_ENDFN : next_state);
        parser_lex(parser);
        symbol = parser->previous;
        break;
      default:
        expect(parser, YP_TOKEN_IDENTIFIER, "Expected symbol.");
        symbol = parser->previous;
        break;
    }

    yp_token_t closing = not_provided(parser);
    return yp_node_symbol_node_create_and_unescape(parser, &opening, &symbol, &closing);
  }

  // If we weren't in a string in the previous check then we have to be now.
  assert(lex_mode->mode == YP_LEX_STRING);

  if (lex_mode->as.string.interpolation) {
    yp_interpolated_symbol_node_t *interpolated = YP_NODE_UPCAST(
      yp_interpolated_symbol_node_create(parser, &opening, NULL, &opening),
      yp_interpolated_symbol_node_t
    );

    while (!match_any_type_p(parser, 2, YP_TOKEN_STRING_END, YP_TOKEN_EOF)) {
      yp_node_t *part = parse_string_part(parser);
      if (part != NULL) {
        yp_node_list_append(parser, YP_NODE_DOWNCAST(interpolated), &interpolated->parts, part);
      }
    }

    if (next_state != YP_LEX_STATE_NONE) {
      lex_state_set(parser, next_state);
    }
    expect(parser, YP_TOKEN_STRING_END, "Expected a closing delimiter for an interpolated symbol.");

    interpolated->closing = parser->previous;
    return YP_NODE_DOWNCAST(interpolated);
  }

  yp_token_t content;
  if (accept(parser, YP_TOKEN_STRING_CONTENT)) {
    content = parser->previous;
  } else {
    content = (yp_token_t) { .type = YP_TOKEN_STRING_CONTENT, .start = parser->previous.end, .end = parser->previous.end };
  }

  if (next_state != YP_LEX_STATE_NONE) {
    lex_state_set(parser, next_state);
  }
  expect(parser, YP_TOKEN_STRING_END, "Expected a closing delimiter for a dynamic symbol.");

  return yp_node_symbol_node_create_and_unescape(parser, &opening, &content, &parser->previous);
}

// Parse an argument to undef which can either be a bare word, a
// symbol, or an interpolated symbol.
static inline yp_node_t *
parse_undef_argument(yp_parser_t *parser) {
  switch (parser->current.type) {
    case YP_CASE_OPERATOR:
    case YP_CASE_KEYWORD:
    case YP_TOKEN_IDENTIFIER: {
      parser_lex(parser);

      yp_token_t opening = not_provided(parser);
      yp_token_t closing = not_provided(parser);

      return yp_node_symbol_node_create_and_unescape(parser, &opening, &parser->previous, &closing);
    }
    case YP_TOKEN_SYMBOL_BEGIN: {
      yp_lex_mode_t *lex_mode = parser->lex_modes.current;
      parser_lex(parser);
      return parse_symbol(parser, lex_mode, YP_LEX_STATE_NONE);
    }
    default:
      yp_diagnostic_list_append(&parser->error_list, parser->current.start, parser->current.end, "Expected a bare word or symbol argument.");

      return yp_missing_node_create(parser, &(yp_location_t) {
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
    case YP_CASE_OPERATOR:
    case YP_CASE_KEYWORD:
    case YP_TOKEN_IDENTIFIER: {
      if (first) {
        lex_state_set(parser, YP_LEX_STATE_FNAME | YP_LEX_STATE_FITEM);
      }

      parser_lex(parser);
      yp_token_t opening = not_provided(parser);
      yp_token_t closing = not_provided(parser);

      return yp_node_symbol_node_create_and_unescape(parser, &opening, &parser->previous, &closing);
    }
    case YP_TOKEN_SYMBOL_BEGIN: {
      yp_lex_mode_t *lex_mode = parser->lex_modes.current;
      parser_lex(parser);

      return parse_symbol(parser, lex_mode, first ? YP_LEX_STATE_FNAME | YP_LEX_STATE_FITEM : YP_LEX_STATE_NONE);
    }
    case YP_TOKEN_BACK_REFERENCE:
    case YP_TOKEN_NTH_REFERENCE:
    case YP_TOKEN_GLOBAL_VARIABLE: {
      parser_lex(parser);
      return yp_global_variable_read_node_create(parser, &parser->previous);
    }
    default:
      yp_diagnostic_list_append(&parser->error_list, parser->current.start, parser->current.end, "Expected a bare word, symbol or global variable argument.");

      return yp_missing_node_create(parser, &(yp_location_t) {
        .start = parser->current.start,
        .end = parser->current.end
      });
  }
}

// Parse an identifier into either a local variable read or a call.
static yp_node_t *
parse_vcall(yp_parser_t *parser) {
  if (
    (parser->current.type != YP_TOKEN_PARENTHESIS_LEFT) &&
    (parser->previous.end[-1] != '!') &&
    (parser->previous.end[-1] != '?') &&
    yp_parser_local_p(parser, &parser->previous)
  ) {
    return yp_local_variable_read_node_create(parser, &parser->previous);
  }

  return yp_call_node_vcall_create(parser, &parser->previous);
}

static yp_node_t *
parse_identifier(yp_parser_t *parser) {
  yp_node_t *node = parse_vcall(parser);

  if (node->type == YP_NODE_CALL_NODE) {
    yp_arguments_t arguments = yp_arguments(parser);
    parse_arguments_list(parser, &arguments, true);

    YP_NODE_UPCAST(node, yp_call_node_t)->opening = arguments.opening;
    YP_NODE_UPCAST(node, yp_call_node_t)->arguments = arguments.arguments;
    YP_NODE_UPCAST(node, yp_call_node_t)->closing = arguments.closing;
    YP_NODE_UPCAST(node, yp_call_node_t)->block = arguments.block;

    if (arguments.block != NULL) {
      node->location.end = arguments.block->location.end;
    } else if (arguments.closing.type == YP_TOKEN_NOT_PROVIDED) {
      node->location.end = YP_NODE_UPCAST(node, yp_call_node_t)->message.end;
    } else {
      node->location.end = arguments.closing.end;
    }
  }

  return node;
}

static inline yp_token_t
parse_method_definition_name(yp_parser_t *parser) {
  switch (parser->current.type) {
    case YP_CASE_KEYWORD:
    case YP_TOKEN_CONSTANT:
    case YP_TOKEN_IDENTIFIER:
      parser_lex(parser);
      return parser->previous;
    case YP_CASE_OPERATOR:
      lex_state_set(parser, YP_LEX_STATE_ENDFN);
      parser_lex(parser);
      return parser->previous;
    default:
      return not_provided(parser);
  }
}

static yp_node_t *
parse_pattern(yp_parser_t *parser, bool top_pattern, const char *message);

// Accept any number of constants joined by :: delimiters.
static yp_node_t *
parse_pattern_constant_path(yp_parser_t *parser, yp_node_t *node) {
  // Now, if there are any :: operators that follow, parse them as constant
  // path nodes.
  while (accept(parser, YP_TOKEN_COLON_COLON)) {
    yp_token_t delimiter = parser->previous;
    expect(parser, YP_TOKEN_CONSTANT, "Expected a constant after the :: operator.");

    yp_node_t *child = yp_constant_read_node_create(parser, &parser->previous);
    node = yp_constant_path_node_create(parser, node, &delimiter, child);
  }

  // If there is a [ or ( that follows, then this is part of a larger pattern
  // expression. We'll parse the inner pattern here, then modify the returned
  // inner pattern with our constant path attached.
  if (match_any_type_p(parser, 2, YP_TOKEN_BRACKET_LEFT, YP_TOKEN_PARENTHESIS_LEFT)) {
    yp_token_t opening;
    yp_token_t closing;
    yp_node_t *inner = NULL;

    if (accept(parser, YP_TOKEN_BRACKET_LEFT)) {
      opening = parser->previous;

      if (!accept(parser, YP_TOKEN_BRACKET_RIGHT)) {
        inner = parse_pattern(parser, true, "Expected a pattern expression after the [ operator.");
        expect(parser, YP_TOKEN_BRACKET_RIGHT, "Expected a ] to close the pattern expression.");
      }

      closing = parser->previous;
    } else {
      parser_lex(parser);
      opening = parser->previous;

      if (!accept(parser, YP_TOKEN_PARENTHESIS_RIGHT)) {
        inner = parse_pattern(parser, true, "Expected a pattern expression after the ( operator.");
        expect(parser, YP_TOKEN_PARENTHESIS_RIGHT, "Expected a ) to close the pattern expression.");
      }

      closing = parser->previous;
    }

    if (inner) {
      // Now that we have the inner pattern, check to see if it's an array, find,
      // or hash pattern. If it is, then we'll attach our constant path to it. If
      // it's not, then we'll create an array pattern.
      switch (inner->type) {
        case YP_NODE_ARRAY_PATTERN_NODE: {
          yp_array_pattern_node_t *array_pattern_node = YP_NODE_UPCAST(inner, yp_array_pattern_node_t);
          array_pattern_node->base.location.start = node->location.start;
          array_pattern_node->base.location.end = closing.end;

          array_pattern_node->constant = node;
          array_pattern_node->opening_loc = (yp_location_t) { .start = opening.start, .end = opening.end };
          array_pattern_node->closing_loc = (yp_location_t) { .start = closing.start, .end = closing.end };

          node = YP_NODE_DOWNCAST(array_pattern_node);
          break;
        }
        case YP_NODE_FIND_PATTERN_NODE: {
          yp_find_pattern_node_t *find_pattern_node = YP_NODE_UPCAST(inner, yp_find_pattern_node_t);
          find_pattern_node->base.location.start = node->location.start;
          find_pattern_node->base.location.end = closing.end;

          find_pattern_node->constant = node;
          find_pattern_node->opening_loc = (yp_location_t) { .start = opening.start, .end = opening.end };
          find_pattern_node->closing_loc = (yp_location_t) { .start = closing.start, .end = closing.end };

          node = YP_NODE_DOWNCAST(find_pattern_node);
          break;
        }
        case YP_NODE_HASH_PATTERN_NODE: {
          yp_hash_pattern_node_t *hash_pattern_node = YP_NODE_UPCAST(inner, yp_hash_pattern_node_t);
          hash_pattern_node->base.location.start = node->location.start;
          hash_pattern_node->base.location.end = closing.end;

          hash_pattern_node->constant = node;
          hash_pattern_node->opening_loc = (yp_location_t) { .start = opening.start, .end = opening.end };
          hash_pattern_node->closing_loc = (yp_location_t) { .start = closing.start, .end = closing.end };

          node = YP_NODE_DOWNCAST(hash_pattern_node);
          break;
        }
        default: {
          node = yp_array_pattern_node_constant_create(parser, node, &opening, &closing);
          yp_node_list_append2(&YP_NODE_UPCAST(node, yp_array_pattern_node_t)->requireds, inner);
          break;
        }
      }
    } else {
      // If there was no inner pattern, then we have something like Foo() or
      // Foo[]. In that case we'll create an array pattern with no requireds.
      node = yp_array_pattern_node_constant_create(parser, node, &opening, &closing);
    }
  }

  return node;
}

// Parse a rest pattern.
static yp_node_t *
parse_pattern_rest(yp_parser_t *parser) {
  assert(parser->previous.type == YP_TOKEN_USTAR);
  yp_token_t operator = parser->previous;
  yp_node_t *name = NULL;

  // Rest patterns don't necessarily have a name associated with them. So we
  // will check for that here. If they do, then we'll add it to the local table
  // since this pattern will cause it to become a local variable.
  if (accept(parser, YP_TOKEN_IDENTIFIER)) {
    yp_token_t identifier = parser->previous;
    yp_parser_local_add(parser, &identifier);
    name = yp_local_variable_write_node_create(parser, &identifier);
  }

  // Finally we can return the created node.
  return yp_splat_node_create(parser, &operator, name);
}

// Parse a keyword rest node.
static yp_node_t *
parse_pattern_keyword_rest(yp_parser_t *parser) {
  assert(parser->current.type == YP_TOKEN_USTAR_STAR);
  parser_lex(parser);

  yp_token_t operator = parser->previous;
  yp_node_t *value = NULL;

  if (accept(parser, YP_TOKEN_KEYWORD_NIL)) {
    return yp_no_keywords_parameter_node_create(parser, &operator, &parser->previous);
  }

  if (accept(parser, YP_TOKEN_IDENTIFIER)) {
    yp_parser_local_add(parser, &parser->previous);
    value = yp_local_variable_write_node_create(parser, &parser->previous);
  }

  return yp_assoc_splat_node_create(parser, value, &operator);
}

// Parse a hash pattern.
static yp_node_t *
parse_pattern_hash(yp_parser_t *parser, yp_node_t *first_assoc) {
  if (!match_any_type_p(parser, 7, YP_TOKEN_COMMA, YP_TOKEN_KEYWORD_THEN, YP_TOKEN_BRACE_RIGHT, YP_TOKEN_BRACKET_RIGHT, YP_TOKEN_PARENTHESIS_RIGHT, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON)) {
    // Here we have a value for the first assoc in the list, so we will parse it
    // now and update the first assoc.
    yp_node_t *value = parse_pattern(parser, false, "Expected a pattern expression after the key.");

    first_assoc->location.end = value->location.end;
    YP_NODE_UPCAST(first_assoc, yp_assoc_node_t)->value = value;
  }

  yp_node_list_t assocs;
  yp_node_list_init(&assocs);
  yp_node_list_append2(&assocs, first_assoc);

  // If there are any other assocs, then we'll parse them now.
  while (accept(parser, YP_TOKEN_COMMA)) {
    // Here we need to break to support trailing commas.
    if (match_any_type_p(parser, 6, YP_TOKEN_KEYWORD_THEN, YP_TOKEN_BRACE_RIGHT, YP_TOKEN_BRACKET_RIGHT, YP_TOKEN_PARENTHESIS_RIGHT, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON)) {
      break;
    }

    yp_node_t *assoc;

    if (match_type_p(parser, YP_TOKEN_USTAR_STAR)) {
      assoc = parse_pattern_keyword_rest(parser);
    } else {
      expect(parser, YP_TOKEN_LABEL, "Expected a label after the `,'.");
      yp_node_t *key = yp_symbol_node_label_create(parser, &parser->previous);
      yp_node_t *value = NULL;

      if (!match_any_type_p(parser, 7, YP_TOKEN_COMMA, YP_TOKEN_KEYWORD_THEN, YP_TOKEN_BRACE_RIGHT, YP_TOKEN_BRACKET_RIGHT, YP_TOKEN_PARENTHESIS_RIGHT, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON)) {
        value = parse_pattern(parser, false, "Expected a pattern expression after the key.");
      }

      yp_token_t operator = not_provided(parser);
      assoc = yp_assoc_node_create(parser, key, &operator, value);
    }

    yp_node_list_append2(&assocs, assoc);
  }

  yp_node_t *node = yp_hash_pattern_node_node_list_create(parser, &assocs);
  free(assocs.nodes);

  return node;
}

// Parse a pattern expression primitive.
static yp_node_t *
parse_pattern_primitive(yp_parser_t *parser, const char *message) {
  switch (parser->current.type) {
    case YP_TOKEN_IDENTIFIER: {
      parser_lex(parser);
      yp_parser_local_add(parser, &parser->previous);
      return yp_local_variable_write_node_create(parser, &parser->previous);
    }
    case YP_TOKEN_BRACKET_LEFT_ARRAY: {
      yp_token_t opening = parser->current;
      parser_lex(parser);

      if (accept(parser, YP_TOKEN_BRACKET_RIGHT)) {
        // If we have an empty array pattern, then we'll just return a new
        // array pattern node.
        return yp_array_pattern_node_empty_create(parser, &opening, &parser->previous);
      }

      // Otherwise, we'll parse the inner pattern, then deal with it depending
      // on the type it returns.
      yp_node_t *inner = parse_pattern(parser, true, "Expected a pattern expression after the [ operator.");

      expect(parser, YP_TOKEN_BRACKET_RIGHT, "Expected a ] to close the pattern expression.");
      yp_token_t closing = parser->previous;

      switch (inner->type) {
        case YP_NODE_ARRAY_PATTERN_NODE: {
          yp_array_pattern_node_t *array_pattern_node = YP_NODE_UPCAST(inner, yp_array_pattern_node_t);
          if (array_pattern_node->opening_loc.start == NULL) {
            array_pattern_node->base.location.start = opening.start;
            array_pattern_node->base.location.end = closing.end;

            array_pattern_node->opening_loc = (yp_location_t) { .start = opening.start, .end = opening.end };
            array_pattern_node->closing_loc = (yp_location_t) { .start = closing.start, .end = closing.end };

            return YP_NODE_DOWNCAST(array_pattern_node);
          }

          break;
        }
        case YP_NODE_FIND_PATTERN_NODE: {
          yp_find_pattern_node_t *find_pattern_node = YP_NODE_UPCAST(inner, yp_find_pattern_node_t);
          if (find_pattern_node->opening_loc.start == NULL) {
            find_pattern_node->base.location.start = opening.start;
            find_pattern_node->base.location.end = closing.end;

            find_pattern_node->opening_loc = (yp_location_t) { .start = opening.start, .end = opening.end };
            find_pattern_node->closing_loc = (yp_location_t) { .start = closing.start, .end = closing.end };

            return YP_NODE_DOWNCAST(find_pattern_node);
          }

          break;
        }
        default:
          break;
      }

      yp_node_t *node = yp_array_pattern_node_empty_create(parser, &opening, &closing);
      yp_node_list_append2(&YP_NODE_UPCAST(node, yp_array_pattern_node_t)->requireds, inner);
      return node;
    }
    case YP_TOKEN_BRACE_LEFT: {
      bool previous_pattern_matching_newlines = parser->pattern_matching_newlines;
      parser->pattern_matching_newlines = false;

      yp_node_t *node;
      yp_token_t opening = parser->current;
      parser_lex(parser);

      if (accept(parser, YP_TOKEN_BRACE_RIGHT)) {
        // If we have an empty hash pattern, then we'll just return a new hash
        // pattern node.
        node = yp_hash_pattern_node_empty_create(parser, &opening, &parser->previous);
      } else {
        yp_node_t *key;

        switch (parser->current.type) {
          case YP_TOKEN_LABEL:
            parser_lex(parser);
            key = yp_symbol_node_label_create(parser, &parser->previous);
            break;
          case YP_TOKEN_USTAR_STAR:
            key = parse_pattern_keyword_rest(parser);
            break;
          case YP_TOKEN_STRING_BEGIN:
            key = parse_expression(parser, YP_BINDING_POWER_MAX, "Expected a key in the hash pattern.");
            if (!yp_symbol_node_label_p(key)) {
              yp_diagnostic_list_append(&parser->error_list, key->location.start, key->location.end, "Expected a label as the key in the hash pattern.");
            }

            break;
          default:
            parser_lex(parser);
            yp_diagnostic_list_append(&parser->error_list, parser->previous.start, parser->previous.end, "Expected a key in the hash pattern.");
            key = yp_missing_node_create(parser, &(yp_location_t) { .start = parser->previous.start, .end = parser->previous.end });
            break;
        }

        yp_token_t operator = not_provided(parser);
        node = parse_pattern_hash(parser, yp_assoc_node_create(parser, key, &operator, NULL));

        accept(parser, YP_TOKEN_NEWLINE);
        expect(parser, YP_TOKEN_BRACE_RIGHT, "Expected a } to close the pattern expression.");
        yp_token_t closing = parser->previous;

        node->location.start = opening.start;
        node->location.end = closing.end;

        YP_NODE_UPCAST(node, yp_hash_pattern_node_t)->opening_loc = (yp_location_t) { .start = opening.start, .end = opening.end };
        YP_NODE_UPCAST(node, yp_hash_pattern_node_t)->closing_loc = (yp_location_t) { .start = closing.start, .end = closing.end };
      }

      parser->pattern_matching_newlines = previous_pattern_matching_newlines;
      return node;
    }
    case YP_TOKEN_UDOT_DOT:
    case YP_TOKEN_UDOT_DOT_DOT: {
      yp_token_t operator = parser->current;
      parser_lex(parser);

      // Since we have a unary range operator, we need to parse the subsequent
      // expression as the right side of the range.
      switch (parser->current.type) {
        case YP_CASE_PRIMITIVE: {
          yp_node_t *right = parse_expression(parser, YP_BINDING_POWER_MAX, "Expected an expression after the range operator.");
          return yp_range_node_create(parser, NULL, &operator, right);
        }
        default: {
          yp_diagnostic_list_append(&parser->error_list, operator.start, operator.end, "Expected an expression after the range operator.");

          yp_node_t *right = yp_missing_node_create(parser, &(yp_location_t) { .start = operator.start, .end = operator.end });
          return yp_range_node_create(parser, NULL, &operator, right);
        }
      }
    }
    case YP_CASE_PRIMITIVE: {
      yp_node_t *node = parse_expression(parser, YP_BINDING_POWER_MAX, message);

      // Now that we have a primitive, we need to check if it's part of a range.
      if (accept_any(parser, 2, YP_TOKEN_DOT_DOT, YP_TOKEN_DOT_DOT_DOT)) {
        yp_token_t operator = parser->previous;

        // Now that we have the operator, we need to check if this is followed
        // by another expression. If it is, then we will create a full range
        // node. Otherwise, we'll create an endless range.
        switch (parser->current.type) {
          case YP_CASE_PRIMITIVE: {
            yp_node_t *right = parse_expression(parser, YP_BINDING_POWER_MAX, "Expected an expression after the range operator.");
            return yp_range_node_create(parser, node, &operator, right);
          }
          default:
            return yp_range_node_create(parser, node, &operator, NULL);
        }
      }

      return node;
    }
    case YP_TOKEN_CARET: {
      parser_lex(parser);
      yp_token_t operator = parser->previous;

      // At this point we have a pin operator. We need to check the subsequent
      // expression to determine if it's a variable or an expression.
      switch (parser->current.type) {
        case YP_TOKEN_IDENTIFIER: {
          parser_lex(parser);
          yp_node_t *variable = yp_local_variable_read_node_create(parser, &parser->previous);

          return yp_pinned_variable_node_create(parser, &operator, variable);
        }
        case YP_TOKEN_INSTANCE_VARIABLE: {
          parser_lex(parser);
          yp_node_t *variable = yp_instance_variable_read_node_create(parser, &parser->previous);

          return yp_pinned_variable_node_create(parser, &operator, variable);
        }
        case YP_TOKEN_CLASS_VARIABLE: {
          parser_lex(parser);
          yp_node_t *variable = yp_class_variable_read_node_create(parser, &parser->previous);

          return yp_pinned_variable_node_create(parser, &operator, variable);
        }
        case YP_TOKEN_GLOBAL_VARIABLE:
        case YP_TOKEN_NTH_REFERENCE:
        case YP_TOKEN_BACK_REFERENCE: {
          parser_lex(parser);
          yp_node_t *variable = yp_global_variable_read_node_create(parser, &parser->previous);

          return yp_pinned_variable_node_create(parser, &operator, variable);
        }
        case YP_TOKEN_PARENTHESIS_LEFT: {
          bool previous_pattern_matching_newlines = parser->pattern_matching_newlines;
          parser->pattern_matching_newlines = false;

          yp_token_t lparen = parser->current;
          parser_lex(parser);

          yp_node_t *expression = parse_expression(parser, YP_BINDING_POWER_STATEMENT, "Expected an expression after the pin operator.");
          parser->pattern_matching_newlines = previous_pattern_matching_newlines;

          expect(parser, YP_TOKEN_PARENTHESIS_RIGHT, "Expected a closing parenthesis after the expression.");
          return yp_pinned_expression_node_create(parser, expression, &operator, &lparen, &parser->previous);
        }
        default: {
          // If we get here, then we have a pin operator followed by something
          // not understood. We'll create a missing node and return that.
          yp_diagnostic_list_append(&parser->error_list, operator.start, operator.end, "Expected a variable after the pin operator.");
          yp_node_t *variable = yp_missing_node_create(parser, &(yp_location_t) { .start = operator.start, .end = operator.end });

          return yp_pinned_variable_node_create(parser, &operator, variable);
        }
      }
    }
    case YP_TOKEN_UCOLON_COLON: {
      yp_token_t delimiter = parser->current;
      parser_lex(parser);

      expect(parser, YP_TOKEN_CONSTANT, "Expected a constant after the :: operator.");
      yp_node_t *child = yp_constant_read_node_create(parser, &parser->previous);
      yp_node_t *node = yp_constant_path_node_create(parser, NULL, &delimiter, child);

      return parse_pattern_constant_path(parser, node);
    }
    case YP_TOKEN_CONSTANT: {
      yp_token_t constant = parser->current;
      parser_lex(parser);

      yp_node_t *node = yp_constant_read_node_create(parser, &constant);
      return parse_pattern_constant_path(parser, node);
    }
    default:
      yp_diagnostic_list_append(&parser->error_list, parser->current.start, parser->current.end, message);

      return yp_missing_node_create(parser, &(yp_location_t) {
        .start = parser->current.start,
        .end = parser->current.end
      });
  }
}

// Parse any number of primitives joined by alternation and ended optionally by
// assignment.
static yp_node_t *
parse_pattern_primitives(yp_parser_t *parser, const char *message) {
  yp_node_t *node = NULL;

  do {
    yp_token_t operator = parser->previous;

    switch (parser->current.type) {
      case YP_TOKEN_IDENTIFIER:
      case YP_TOKEN_BRACKET_LEFT_ARRAY:
      case YP_TOKEN_BRACE_LEFT:
      case YP_TOKEN_CARET:
      case YP_TOKEN_CONSTANT:
      case YP_TOKEN_UCOLON_COLON:
      case YP_TOKEN_UDOT_DOT:
      case YP_TOKEN_UDOT_DOT_DOT:
      case YP_CASE_PRIMITIVE: {
        if (node == NULL) {
          node = parse_pattern_primitive(parser, message);
        } else {
          yp_node_t *right = parse_pattern_primitive(parser, "Expected to be able to parse a pattern after `|'.");
          node = yp_alternation_pattern_node_create(parser, node, right, &operator);
        }

        break;
      }
      case YP_TOKEN_PARENTHESIS_LEFT: {
        parser_lex(parser);
        node = parse_pattern(parser, false, "Expected a pattern after the opening parenthesis.");

        expect(parser, YP_TOKEN_PARENTHESIS_RIGHT, "Expected a closing parenthesis after the pattern.");
        break;
      }
      default: {
        yp_diagnostic_list_append(&parser->error_list, parser->current.start, parser->current.end, message);
        yp_node_t *right = yp_missing_node_create(parser, &(yp_location_t) {
          .start = parser->current.start,
          .end = parser->current.end
        });

        if (node == NULL) {
          node = right;
        } else {
          node = yp_alternation_pattern_node_create(parser, node, right, &operator);
        }

        break;
      }
    }
  } while (accept(parser, YP_TOKEN_PIPE));

  // If we have an =>, then we are assigning this pattern to a variable.
  // In this case we should create an assignment node.
  while (accept(parser, YP_TOKEN_EQUAL_GREATER)) {
    yp_token_t operator = parser->previous;

    expect(parser, YP_TOKEN_IDENTIFIER, "Expected an identifier after the `=>' operator.");
    yp_token_t identifier = parser->previous;

    yp_parser_local_add(parser, &identifier);
    yp_node_t *target = yp_local_variable_write_node_create(parser, &identifier);

    node = yp_as_pattern_node_create(parser, node, target, &operator);
  }

  return node;
}

// Parse a pattern matching expression.
static yp_node_t *
parse_pattern(yp_parser_t *parser, bool top_pattern, const char *message) {
  yp_node_t *node = NULL;

  bool leading_rest = false;
  bool trailing_rest = false;

  switch (parser->current.type) {
    case YP_TOKEN_LABEL: {
      parser_lex(parser);
      yp_node_t *key = yp_symbol_node_label_create(parser, &parser->previous);
      yp_token_t operator = not_provided(parser);

      return parse_pattern_hash(parser, yp_assoc_node_create(parser, key, &operator, NULL));
    }
    case YP_TOKEN_USTAR_STAR: {
      node = parse_pattern_keyword_rest(parser);
      return parse_pattern_hash(parser, node);
    }
    case YP_TOKEN_USTAR: {
      if (top_pattern) {
        parser_lex(parser);
        node = parse_pattern_rest(parser);
        leading_rest = true;
        break;
      }
    }
    default:
      node = parse_pattern_primitives(parser, message);
      break;
  }

  // If we got a dynamic label symbol, then we need to treat it like the
  // beginning of a hash pattern.
  if (yp_symbol_node_label_p(node)) {
    yp_token_t operator = not_provided(parser);
    return parse_pattern_hash(parser, yp_assoc_node_create(parser, node, &operator, NULL));
  }

  if (top_pattern && match_type_p(parser, YP_TOKEN_COMMA)) {
    // If we have a comma, then we are now parsing either an array pattern or a
    // find pattern. We need to parse all of the patterns, put them into a big
    // list, and then determine which type of node we have.
    yp_node_list_t nodes;
    yp_node_list_init(&nodes);
    yp_node_list_append2(&nodes, node);

    // Gather up all of the patterns into the list.
    while (accept(parser, YP_TOKEN_COMMA)) {
      // Break early here in case we have a trailing comma.
      if (match_any_type_p(parser, 5, YP_TOKEN_KEYWORD_THEN, YP_TOKEN_BRACE_RIGHT, YP_TOKEN_BRACKET_RIGHT, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON)) {
        break;
      }

      if (accept(parser, YP_TOKEN_USTAR)) {
        node = parse_pattern_rest(parser);

        // If we have already parsed a splat pattern, then this is an error. We
        // will continue to parse the rest of the patterns, but we will indicate
        // it as an error.
        if (trailing_rest) {
          yp_diagnostic_list_append(&parser->error_list, parser->previous.start, parser->previous.end, "Unexpected rest pattern.");
        }

        trailing_rest = true;
      } else {
        node = parse_pattern_primitives(parser, "Expected a pattern after the comma.");
      }

      yp_node_list_append2(&nodes, node);
    }

    // If the first pattern and the last pattern are rest patterns, then we will
    // call this a find pattern, regardless of how many rest patterns are in
    // between because we know we already added the appropriate errors.
    // Otherwise we will create an array pattern.
    if (nodes.nodes[0]->type == YP_NODE_SPLAT_NODE && nodes.nodes[nodes.size - 1]->type == YP_NODE_SPLAT_NODE) {
      node = yp_find_pattern_node_create(parser, &nodes);
    } else {
      node = yp_array_pattern_node_node_list_create(parser, &nodes);
    }

    free(nodes.nodes);
  } else if (leading_rest) {
    // Otherwise, if we parsed a single splat pattern, then we know we have an
    // array pattern, so we can go ahead and create that node.
    node = yp_array_pattern_node_rest_create(parser, node);
  }

  return node;
}

// Parse an expression that begins with the previous node that we just lexed.
static inline yp_node_t *
parse_expression_prefix(yp_parser_t *parser, yp_binding_power_t binding_power) {
  yp_lex_mode_t *lex_mode = parser->lex_modes.current;

  switch (parser->current.type) {
    case YP_TOKEN_BRACKET_LEFT_ARRAY: {
      parser_lex(parser);

      yp_token_t opening = parser->previous;
      yp_node_t *array = yp_array_node_create(parser, &opening, &opening);
      yp_accepts_block_stack_push(parser, true);
      bool parsed_bare_hash = false;

      while (!match_any_type_p(parser, 2, YP_TOKEN_BRACKET_RIGHT, YP_TOKEN_EOF)) {
        // Handle the case where we don't have a comma and we have a newline followed by a right bracket.
        if (accept(parser, YP_TOKEN_NEWLINE) && match_type_p(parser, YP_TOKEN_BRACKET_RIGHT)) {
          break;
        }

        if (yp_array_node_size(array) != 0) {
          expect(parser, YP_TOKEN_COMMA, "Expected a separator for the elements in an array.");
        }

        // If we have a right bracket immediately following a comma, this is
        // allowed since it's a trailing comma. In this case we can break out of
        // the loop.
        if (match_type_p(parser, YP_TOKEN_BRACKET_RIGHT)) break;

        yp_node_t *element;

        if (accept(parser, YP_TOKEN_USTAR)) {
          yp_node_t *expression = parse_expression(parser, YP_BINDING_POWER_DEFINED, "Expected an expression after '*' in the array.");
          element = yp_splat_node_create(parser, &parser->previous, expression);
        } else if (match_any_type_p(parser, 2, YP_TOKEN_LABEL, YP_TOKEN_USTAR_STAR)) {
          if (parsed_bare_hash) {
            yp_diagnostic_list_append(&parser->error_list, parser->current.start, parser->current.end, "Unexpected bare hash.");
          }

          yp_token_t opening = not_provided(parser);
          yp_token_t closing = not_provided(parser);
          element = yp_hash_node_create(parser, &opening, &closing);

          if (!match_any_type_p(parser, 8, YP_TOKEN_EOF, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON, YP_TOKEN_EOF, YP_TOKEN_BRACE_RIGHT, YP_TOKEN_BRACKET_RIGHT, YP_TOKEN_KEYWORD_DO, YP_TOKEN_PARENTHESIS_RIGHT)) {
            parse_assocs(parser, element);
          }

          parsed_bare_hash = true;
        } else {
          element = parse_expression(parser, YP_BINDING_POWER_DEFINED, "Expected an element for the array.");

          if (yp_symbol_node_label_p(element) || accept(parser, YP_TOKEN_EQUAL_GREATER)) {
            if (parsed_bare_hash) {
              yp_diagnostic_list_append(&parser->error_list, parser->previous.start, parser->previous.end, "Unexpected bare hash.");
            }

            yp_token_t opening = not_provided(parser);
            yp_token_t closing = not_provided(parser);
            yp_node_t *hash = yp_hash_node_create(parser, &opening, &closing);

            yp_token_t operator;
            if (parser->previous.type == YP_TOKEN_EQUAL_GREATER) {
              operator = parser->previous;
            } else {
              operator = not_provided(parser);
            }

            yp_node_t *value = parse_expression(parser, YP_BINDING_POWER_DEFINED, "Expected a value in the hash literal.");
            yp_node_t *assoc = yp_assoc_node_create(parser, element, &operator, value);
            yp_node_list_append(parser, hash, &YP_NODE_UPCAST(hash, yp_hash_node_t)->elements, assoc);

            element = hash;
            if (accept(parser, YP_TOKEN_COMMA) && !match_type_p(parser, YP_TOKEN_BRACKET_RIGHT)) {
              parse_assocs(parser, element);
            }

            parsed_bare_hash = true;
          }
        }

        yp_array_node_elements_append(array, element);
        if (element->type == YP_NODE_MISSING_NODE) break;
      }

      accept(parser, YP_TOKEN_NEWLINE);
      expect(parser, YP_TOKEN_BRACKET_RIGHT, "Expected a closing bracket for the array.");
      yp_array_node_close_set(array, &parser->previous);
      yp_accepts_block_stack_pop(parser);

      return array;
    }
    case YP_TOKEN_PARENTHESIS_LEFT:
    case YP_TOKEN_PARENTHESIS_LEFT_PARENTHESES: {
      parser_lex(parser);

      yp_token_t opening = parser->previous;
      while (accept_any(parser, 2, YP_TOKEN_SEMICOLON, YP_TOKEN_NEWLINE));

      // If this is the end of the file or we match a right parenthesis, then
      // we have an empty parentheses node, and we can immediately return.
      if (match_any_type_p(parser, 2, YP_TOKEN_PARENTHESIS_RIGHT, YP_TOKEN_EOF)) {
        expect(parser, YP_TOKEN_PARENTHESIS_RIGHT, "Expected a closing parenthesis.");
        return yp_parentheses_node_create(parser, &opening, NULL, &parser->previous);
      }

      // Otherwise, we're going to parse the first statement in the list of
      // statements within the parentheses.
      yp_accepts_block_stack_push(parser, true);
      yp_node_t *statement = parse_expression(parser, YP_BINDING_POWER_STATEMENT, "Expected to be able to parse an expression.");
      while (accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON));

      // If we hit a right parenthesis, then we're done parsing the parentheses
      // node, and we can check which kind of node we should return.
      if (accept(parser, YP_TOKEN_PARENTHESIS_RIGHT)) {
        yp_accepts_block_stack_pop(parser);

        // If we have a single statement and are ending on a right parenthesis,
        // then we need to check if this is possibly a multiple assignment node.
        if (
          binding_power == YP_BINDING_POWER_STATEMENT &&
          statement->type == YP_NODE_MULTI_WRITE_NODE &&
          match_any_type_p(parser, 2, YP_TOKEN_COMMA, YP_TOKEN_EQUAL)
        ) {
          YP_NODE_UPCAST(statement, yp_multi_write_node_t)->lparen_loc = (yp_location_t) { .start = opening.start, .end = opening.end };
          YP_NODE_UPCAST(statement, yp_multi_write_node_t)->rparen_loc = (yp_location_t) { .start = parser->previous.start, .end = parser->previous.end };
          return parse_targets(parser, statement, YP_BINDING_POWER_INDEX);
        }

        // If we have a single statement and are ending on a right parenthesis
        // and we didn't return a multiple assignment node, then we can return a
        // regular parentheses node now.
        yp_node_t *statements = yp_statements_node_create(parser);
        yp_statements_node_body_append(statements, statement);

        return yp_parentheses_node_create(parser, &opening, statements, &parser->previous);
      }

      // If we have more than one statement in the set of parentheses, then we
      // are going to parse all of them as a list of statements. We'll do that
      // here.
      context_push(parser, YP_CONTEXT_PARENS);
      yp_node_t *statements = yp_statements_node_create(parser);
      yp_statements_node_body_append(statements, statement);

      while (!match_type_p(parser, YP_TOKEN_PARENTHESIS_RIGHT)) {
        // Ignore semicolon without statements before them
        if (accept_any(parser, 2, YP_TOKEN_SEMICOLON, YP_TOKEN_NEWLINE)) continue;

        yp_node_t *node = parse_expression(parser, YP_BINDING_POWER_STATEMENT, "Expected to be able to parse an expression.");
        yp_statements_node_body_append(statements, node);

        // If we're recovering from a syntax error, then we need to stop parsing the
        // statements now.
        if (parser->recovering) {
          // If this is the level of context where the recovery has happened, then
          // we can mark the parser as done recovering.
          if (match_type_p(parser, YP_TOKEN_PARENTHESIS_RIGHT)) parser->recovering = false;
          break;
        }

        if (!accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON)) break;
      }

      context_pop(parser);
      yp_accepts_block_stack_pop(parser);
      expect(parser, YP_TOKEN_PARENTHESIS_RIGHT, "Expected a closing parenthesis.");

      return yp_parentheses_node_create(parser, &opening, statements, &parser->previous);
    }
    case YP_TOKEN_BRACE_LEFT: {
      yp_accepts_block_stack_push(parser, true);
      parser_lex(parser);

      yp_token_t opening = parser->previous;
      yp_node_t *node = yp_hash_node_create(parser, &opening, &opening);

      if (!match_any_type_p(parser, 2, YP_TOKEN_BRACE_RIGHT, YP_TOKEN_EOF)) {
        parse_assocs(parser, node);
        accept(parser, YP_TOKEN_NEWLINE);
      }

      yp_accepts_block_stack_pop(parser);
      expect(parser, YP_TOKEN_BRACE_RIGHT, "Expected a closing delimiter for a hash literal.");
      YP_NODE_UPCAST(node, yp_hash_node_t)->closing = parser->previous;

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
    case YP_TOKEN_CLASS_VARIABLE: {
      parser_lex(parser);
      yp_node_t *node = yp_class_variable_read_node_create(parser, &parser->previous);

      if (binding_power == YP_BINDING_POWER_STATEMENT && match_type_p(parser, YP_TOKEN_COMMA)) {
        node = parse_targets(parser, node, YP_BINDING_POWER_INDEX);
      }

      return node;
    }
    case YP_TOKEN_CONSTANT: {
      parser_lex(parser);
      yp_token_t constant = parser->previous;

      // If a constant is immediately followed by parentheses, then this is in
      // fact a method call, not a constant read.
      if (
        match_type_p(parser, YP_TOKEN_PARENTHESIS_LEFT) ||
        (binding_power <= YP_BINDING_POWER_ASSIGNMENT && (token_begins_expression_p(parser->current.type) || match_any_type_p(parser, 2, YP_TOKEN_USTAR, YP_TOKEN_USTAR_STAR))) ||
        (yp_accepts_block_stack_p(parser) && match_type_p(parser, YP_TOKEN_KEYWORD_DO))
      ) {
        yp_arguments_t arguments = yp_arguments(parser);
        parse_arguments_list(parser, &arguments, true);
        return yp_call_node_fcall_create(parser, &constant, &arguments);
      }

      yp_node_t *node = yp_constant_read_node_create(parser, &parser->previous);

      if ((binding_power == YP_BINDING_POWER_STATEMENT) && match_type_p(parser, YP_TOKEN_COMMA)) {
        // If we get here, then we have a comma immediately following a
        // constant, so we're going to parse this as a multiple assignment.
        node = parse_targets(parser, node, YP_BINDING_POWER_INDEX);
      }

      return node;
    }
    case YP_TOKEN_UCOLON_COLON: {
      parser_lex(parser);

      yp_token_t delimiter = parser->previous;
      expect(parser, YP_TOKEN_CONSTANT, "Expected a constant after ::.");

      yp_node_t *constant = yp_constant_read_node_create(parser, &parser->previous);
      yp_node_t *node = yp_constant_path_node_create(parser, NULL, &delimiter, constant);

      if ((binding_power == YP_BINDING_POWER_STATEMENT) && match_type_p(parser, YP_TOKEN_COMMA)) {
        node = parse_targets(parser, node, YP_BINDING_POWER_INDEX);
      }

      return node;
    }
    case YP_TOKEN_UDOT_DOT:
    case YP_TOKEN_UDOT_DOT_DOT: {
      yp_token_t operator = parser->current;
      parser_lex(parser);

      yp_node_t *right = parse_expression(parser, binding_power, "Expected a value after the operator.");
      return yp_range_node_create(parser, NULL, &operator, right);
    }
    case YP_TOKEN_FLOAT:
      parser_lex(parser);
      return yp_float_node_create(parser, &parser->previous);
    case YP_TOKEN_NTH_REFERENCE:
    case YP_TOKEN_GLOBAL_VARIABLE:
    case YP_TOKEN_BACK_REFERENCE: {
      parser_lex(parser);
      yp_node_t *node = yp_global_variable_read_node_create(parser, &parser->previous);

      if (binding_power == YP_BINDING_POWER_STATEMENT && match_type_p(parser, YP_TOKEN_COMMA)) {
        node = parse_targets(parser, node, YP_BINDING_POWER_INDEX);
      }

      return node;
    }
    case YP_TOKEN_IDENTIFIER: {
      parser_lex(parser);
      yp_token_t identifier = parser->previous;
      yp_node_t *node = parse_identifier(parser);

      // If an identifier is followed by something that looks like an argument,
      // then this is in fact a method call, not a local read.
      if (
        (binding_power <= YP_BINDING_POWER_ASSIGNMENT && (
          token_begins_expression_p(parser->current.type) || match_any_type_p(parser, 2, YP_TOKEN_USTAR, YP_TOKEN_USTAR_STAR)
        )) ||
        (yp_accepts_block_stack_p(parser) && match_type_p(parser, YP_TOKEN_KEYWORD_DO))
      ) {
        yp_arguments_t arguments = yp_arguments(parser);
        parse_arguments_list(parser, &arguments, true);

        yp_node_t *fcall = yp_call_node_fcall_create(parser, &identifier, &arguments);
        yp_node_destroy(parser, node);
        return fcall;
      }

      if ((binding_power == YP_BINDING_POWER_STATEMENT) && match_type_p(parser, YP_TOKEN_COMMA)) {
        node = parse_targets(parser, node, YP_BINDING_POWER_INDEX);
      }

      return node;
    }
    case YP_TOKEN_HEREDOC_START: {
      parser_lex(parser);
      yp_node_t *node;
      yp_heredoc_quote_t quote = parser->lex_modes.current->as.heredoc.quote;
      yp_heredoc_indent_t indent = parser->lex_modes.current->as.heredoc.indent;

      if (quote == YP_HEREDOC_QUOTE_BACKTICK) {
        node = yp_interpolated_xstring_node_create(parser, &parser->previous, &parser->previous);
      }
      else {
        node = yp_heredoc_node_create(parser, &parser->previous, &parser->previous, 0);
      }

      yp_node_list_t *node_list;

      if (quote == YP_HEREDOC_QUOTE_BACKTICK) {
        node_list = &YP_NODE_UPCAST(node, yp_interpolated_x_string_node_t)->parts;
      }
      else {
        node_list = &YP_NODE_UPCAST(node, yp_heredoc_node_t)->parts;
      }

      while (!match_any_type_p(parser, 2, YP_TOKEN_HEREDOC_END, YP_TOKEN_EOF)) {
        yp_node_t *part = parse_string_part(parser);
        if (part != NULL) {
          if (quote == YP_HEREDOC_QUOTE_BACKTICK) {
            yp_node_list_append(parser, node, &YP_NODE_UPCAST(node, yp_interpolated_x_string_node_t)->parts, part);
          }
          else {
            yp_node_list_append(parser, node, &YP_NODE_UPCAST(node, yp_heredoc_node_t)->parts, part);
          }
        }
      }

      expect(parser, YP_TOKEN_HEREDOC_END, "Expected a closing delimiter for heredoc.");

      if (indent == YP_HEREDOC_INDENT_TILDE) {
        // Tilde heredocs trim the leading whitespace of all lines to the minimum amount of leading
        // whitespace. We need to calculate the minimum amount of leading whitespace
        int min_whitespace = -1;

        for (int i = 0; i < node_list->size; i++) {
          yp_node_t *node = node_list->nodes[i];

          if (node->type == YP_NODE_STRING_NODE && *YP_NODE_UPCAST(node, yp_string_node_t)->content.start != '\n' &&
              // If the previous node wasn't a string node, we don't want to trim whitespace
              (i == 0 || node_list->nodes[i-1]->type == YP_NODE_STRING_NODE)
             ) {
            int cur_whitespace;
            const char *cur_char = YP_NODE_UPCAST(node, yp_string_node_t)->content.start;

            while (cur_char && cur_char < YP_NODE_UPCAST(node, yp_string_node_t)->content.end) {
              // Any empty newlines aren't included in the minimum whitespace calculation
              while(cur_char < YP_NODE_UPCAST(node, yp_string_node_t)->content.end && *cur_char == '\n') {
                cur_char++;
              }

              if (cur_char == YP_NODE_UPCAST(node, yp_string_node_t)->content.end) {
                break;
              }

              cur_whitespace = 0;

              while(char_is_non_newline_whitespace(*cur_char) && cur_char < YP_NODE_UPCAST(node, yp_string_node_t)->content.end) {
                if (cur_char[0] == '\t') {
                  cur_whitespace += YP_TAB_WHITESPACE_SIZE;
                }
                else {
                  cur_whitespace++;
                }
                cur_char++;
              }

              if (cur_whitespace < min_whitespace || min_whitespace == -1) {
                min_whitespace = cur_whitespace;
              }

              cur_char = memchr(cur_char + 1, '\n', parser->end - (cur_char + 1));
              if (cur_char) {
                cur_char++;
              }
            }
          }
        }

        if (min_whitespace > 0) {
          YP_NODE_UPCAST(node, yp_heredoc_node_t)->dedent = min_whitespace;

          // Iterate over all nodes, and trim whitespace accordingly
          for (int i = 0; i < node_list->size; i++) {
            yp_node_t *node = node_list->nodes[i];

            if (node->type == YP_NODE_STRING_NODE) {
              yp_string_t *node_str = &YP_NODE_UPCAST(node, yp_string_node_t)->unescaped;

              // We convert all strings to be "owned" to make it simpler to manipulate memory
              if (node_str->type != YP_STRING_OWNED) {
                size_t length = yp_string_length(node_str);
                const char *original = yp_string_source(node_str);
                yp_string_owned_init(node_str, malloc(length), length);
                memcpy(node_str->as.owned.source, original, length);
              }

              const char *cur_char = node_str->as.owned.source;
              size_t new_size = node_str->as.owned.length;

              // Construct a new string, with which we'll replace the existing string
              char new_str[node_str->as.owned.length];
              int new_str_index = 0;

              bool first_iteration = (i == 0);

              while (cur_char < node_str->as.owned.source + node_str->as.owned.length) {
                if (!first_iteration) {
                  new_str[new_str_index] = cur_char[0];
                  new_str_index++;
                  cur_char++;

                  if (cur_char == (node_str->as.owned.source + node_str->as.owned.length)) {
                    break;
                  }
                }

                // Skip over the whitespace
                if (first_iteration || cur_char[-1] == '\n') {
                  first_iteration = false;
                  int trimmed_whitespace = min_whitespace;

                  while (trimmed_whitespace > 0 && cur_char[0] != '\n' && cur_char < (node_str->as.owned.source + node_str->as.owned.length)) {
                    if (*cur_char == '\t') {
                      if (trimmed_whitespace < YP_TAB_WHITESPACE_SIZE) break;
                      trimmed_whitespace -= YP_TAB_WHITESPACE_SIZE;
                    }
                    else {
                      trimmed_whitespace--;
                    }

                    cur_char++;
                    new_size--;
                  }
                }
              }

              // Copy over the new string
              memcpy(node_str->as.owned.source, new_str, new_size);
              node_str->as.owned.length = new_size;
            }
          }
        }
      }

      if (quote == YP_HEREDOC_QUOTE_BACKTICK) {
        YP_NODE_UPCAST(node, yp_interpolated_x_string_node_t)->closing = parser->previous;
      }
      else {
        YP_NODE_UPCAST(node, yp_heredoc_node_t)->closing = parser->previous;
      }

      return node;
    }
    case YP_TOKEN_IMAGINARY_NUMBER:
      parser_lex(parser);
      return yp_imaginary_node_create(parser, &parser->previous);
    case YP_TOKEN_INSTANCE_VARIABLE: {
      parser_lex(parser);
      yp_node_t *node = yp_instance_variable_read_node_create(parser, &parser->previous);

      if (binding_power == YP_BINDING_POWER_STATEMENT && match_type_p(parser, YP_TOKEN_COMMA)) {
        node = parse_targets(parser, node, YP_BINDING_POWER_INDEX);
      }

      return node;
    }
    case YP_TOKEN_INTEGER:
      parser_lex(parser);
      return yp_integer_node_create(parser, &parser->previous);
    case YP_TOKEN_KEYWORD___ENCODING__:
      parser_lex(parser);
      return yp_source_encoding_node_create(parser, &parser->previous);
    case YP_TOKEN_KEYWORD___FILE__:
      parser_lex(parser);
      return yp_source_file_node_create(parser, &parser->previous);
    case YP_TOKEN_KEYWORD___LINE__:
      parser_lex(parser);
      return yp_source_line_node_create(parser, &parser->previous);
    case YP_TOKEN_KEYWORD_ALIAS: {
      parser_lex(parser);
      yp_token_t keyword = parser->previous;

      yp_node_t *left = parse_alias_argument(parser, true);
      yp_node_t *right = parse_alias_argument(parser, false);

      switch (left->type) {
        case YP_NODE_SYMBOL_NODE:
        case YP_NODE_INTERPOLATED_SYMBOL_NODE: {
          if (right->type != YP_NODE_SYMBOL_NODE && right->type != YP_NODE_INTERPOLATED_SYMBOL_NODE) {
            yp_diagnostic_list_append(&parser->error_list, right->location.start, right->location.end, "Expected a bare word or symbol argument.");
          }
          break;
        }
        case YP_NODE_GLOBAL_VARIABLE_READ_NODE: {
          if (right->type == YP_NODE_GLOBAL_VARIABLE_READ_NODE) {
            yp_token_t *name = &YP_NODE_UPCAST(right, yp_global_variable_read_node_t)->name;

            if (name->type == YP_TOKEN_NTH_REFERENCE) {
              yp_diagnostic_list_append(&parser->error_list, right->location.start, right->location.end, "Can't make alias for number variables.");
            }
          } else {
            yp_diagnostic_list_append(&parser->error_list, right->location.start, right->location.end, "Expected a global variable.");
          }
          break;
        }
        default:
          break;
      }

      return yp_alias_node_create(parser, &keyword, left, right);
    }
    case YP_TOKEN_KEYWORD_CASE: {
      parser_lex(parser);
      yp_token_t case_keyword = parser->previous;
      yp_node_t *predicate = NULL;

      if (
        accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON) ||
        match_any_type_p(parser, 3, YP_TOKEN_KEYWORD_WHEN, YP_TOKEN_KEYWORD_IN, YP_TOKEN_KEYWORD_END) ||
        !token_begins_expression_p(parser->current.type)
      ) {
        predicate = NULL;
      } else {
        predicate = parse_expression(parser, YP_BINDING_POWER_COMPOSITION, "Expected a value after case keyword.");
        accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);
      }

      if (accept(parser, YP_TOKEN_KEYWORD_END)) {
        return yp_case_node_create(parser, &case_keyword, predicate, NULL, &parser->previous);
      }

      // At this point we can create a case node, though we don't yet know if it
      // is a case-in or case-when node.
      yp_token_t end_keyword = not_provided(parser);
      yp_node_t *case_node = yp_case_node_create(parser, &case_keyword, predicate, NULL, &end_keyword);

      if (match_type_p(parser, YP_TOKEN_KEYWORD_WHEN)) {
        // At this point we've seen a when keyword, so we know this is a
        // case-when node. We will continue to parse the when nodes until we hit
        // the end of the list.
        while (accept(parser, YP_TOKEN_KEYWORD_WHEN)) {
          yp_token_t when_keyword = parser->previous;
          yp_when_node_t *when_node = YP_NODE_UPCAST(
            yp_when_node_create(parser, &when_keyword, NULL),
            yp_when_node_t
          );

          do {
            if (accept(parser, YP_TOKEN_USTAR)) {
              yp_token_t operator = parser->previous;
              yp_node_t *expression = parse_expression(parser, YP_BINDING_POWER_DEFINED, "Expected a value after `*' operator.");

              yp_node_t *star_node = yp_splat_node_create(parser, &operator, expression);
              yp_node_list_append(parser, YP_NODE_DOWNCAST(when_node), &when_node->conditions, star_node);

              if (expression->type == YP_NODE_MISSING_NODE) break;
            } else {
              yp_node_t *condition = parse_expression(parser, YP_BINDING_POWER_DEFINED, "Expected a value after when keyword.");
              yp_node_list_append(parser, YP_NODE_DOWNCAST(when_node), &when_node->conditions, condition);

              if (condition->type == YP_NODE_MISSING_NODE) break;
            }
          } while (accept(parser, YP_TOKEN_COMMA));

          if (accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON)) {
            accept(parser, YP_TOKEN_KEYWORD_THEN);
          } else {
            expect(parser, YP_TOKEN_KEYWORD_THEN, "Expected a delimiter after the predicates of a `when' clause.");
          }

          if (!match_any_type_p(parser, 3, YP_TOKEN_KEYWORD_WHEN, YP_TOKEN_KEYWORD_ELSE, YP_TOKEN_KEYWORD_END)) {
            when_node->statements = parse_statements(parser, YP_CONTEXT_CASE_WHEN);
          }

          yp_case_node_condition_append(case_node, YP_NODE_DOWNCAST(when_node));
        }
      } else {
        // At this point we expect that we're parsing a case-in node. We will
        // continue to parse the in nodes until we hit the end of the list.
        while (match_type_p(parser, YP_TOKEN_KEYWORD_IN)) {
          bool previous_pattern_matching_newlines = parser->pattern_matching_newlines;
          parser->pattern_matching_newlines = true;

          lex_state_set(parser, YP_LEX_STATE_BEG | YP_LEX_STATE_LABEL);
          parser->command_start = false;
          parser_lex(parser);

          yp_token_t in_keyword = parser->previous;
          yp_node_t *pattern = parse_pattern(parser, true, "Expected a pattern after `in' keyword.");
          parser->pattern_matching_newlines = previous_pattern_matching_newlines;

          // Since we're in the top-level of the case-in node we need to check
          // for guard clauses in the form of `if` or `unless` statements.
          if (accept(parser, YP_TOKEN_KEYWORD_IF_MODIFIER)) {
            yp_token_t keyword = parser->previous;
            yp_node_t *predicate = parse_expression(parser, YP_BINDING_POWER_DEFINED, "Expected a value after guard keyword.");
            pattern = yp_if_node_modifier_create(parser, pattern, &keyword, predicate);
          } else if (accept(parser, YP_TOKEN_KEYWORD_UNLESS_MODIFIER)) {
            yp_token_t keyword = parser->previous;
            yp_node_t *predicate = parse_expression(parser, YP_BINDING_POWER_DEFINED, "Expected a value after guard keyword.");
            pattern = yp_unless_node_modifier_create(parser, pattern, &keyword, predicate);
          }

          // Now we need to check for the terminator of the in node's pattern.
          // It can be a newline or semicolon optionally followed by a `then`
          // keyword.
          yp_token_t then_keyword;
          if (accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON)) {
            if (accept(parser, YP_TOKEN_KEYWORD_THEN)) {
              then_keyword = parser->previous;
            } else {
              then_keyword = not_provided(parser);
            }
          } else {
            expect(parser, YP_TOKEN_KEYWORD_THEN, "Expected a delimiter after the predicates of an `in' clause.");
            then_keyword = parser->previous;
          }

          // Now we can actually parse the statements associated with the in
          // node.
          yp_node_t *statements;
          if (match_any_type_p(parser, 3, YP_TOKEN_KEYWORD_IN, YP_TOKEN_KEYWORD_ELSE, YP_TOKEN_KEYWORD_END)) {
            statements = NULL;
          } else {
            statements = parse_statements(parser, YP_CONTEXT_CASE_IN);
          }

          // Now that we have the full pattern and statements, we can create the
          // node and attach it to the case node.
          yp_node_t *condition = yp_in_node_create(parser, pattern, statements, &in_keyword, &then_keyword);
          yp_case_node_condition_append(case_node, condition);
        }
      }

      accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);
      if (accept(parser, YP_TOKEN_KEYWORD_ELSE)) {
        yp_token_t else_keyword = parser->previous;
        yp_node_t *else_node;

        if (!match_type_p(parser, YP_TOKEN_KEYWORD_END)) {
          else_node = yp_else_node_create(parser, &else_keyword, parse_statements(parser, YP_CONTEXT_ELSE), &parser->current);
        } else {
          else_node = yp_else_node_create(parser, &else_keyword, NULL, &parser->current);
        }

        yp_case_node_consequent_set(case_node, else_node);
      }

      expect(parser, YP_TOKEN_KEYWORD_END, "Expected case statement to end with an end keyword.");
      yp_case_node_end_keyword_loc_set(case_node, &parser->previous);
      return case_node;
    }
    case YP_TOKEN_KEYWORD_BEGIN: {
      parser_lex(parser);

      yp_token_t begin_keyword = parser->previous;
      accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);
      yp_node_t *begin_statements = NULL;

      if (!match_any_type_p(parser, 3, YP_TOKEN_KEYWORD_RESCUE, YP_TOKEN_KEYWORD_ENSURE, YP_TOKEN_KEYWORD_END)) {
        yp_accepts_block_stack_push(parser, true);
        begin_statements = parse_statements(parser, YP_CONTEXT_BEGIN);
        yp_accepts_block_stack_pop(parser);
        accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);
      }

      yp_node_t *begin_node = yp_begin_node_create(parser, &begin_keyword, begin_statements);
      parse_rescues(parser, begin_node);

      expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close `begin` statement.");
      begin_node->location.end = parser->previous.end;
      yp_begin_node_end_keyword_set(begin_node, &parser->previous);

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

      return yp_pre_execution_node_create(parser, &keyword, &opening, statements, &closing);
    }
    case YP_TOKEN_KEYWORD_BREAK:
    case YP_TOKEN_KEYWORD_NEXT:
    case YP_TOKEN_KEYWORD_RETURN: {
      parser_lex(parser);

      yp_token_t keyword = parser->previous;
      yp_node_t *arguments = NULL;

      if (
        token_begins_expression_p(parser->current.type) ||
        match_any_type_p(parser, 2, YP_TOKEN_USTAR, YP_TOKEN_USTAR_STAR)
      ) {
        yp_binding_power_t binding_power = yp_binding_powers[parser->current.type].left;

        if (binding_power == YP_BINDING_POWER_UNSET || binding_power >= YP_BINDING_POWER_RANGE) {
          arguments = yp_arguments_node_create(parser);
          parse_arguments(parser, arguments, false, YP_TOKEN_EOF);
        }
      }

      switch (keyword.type) {
        case YP_TOKEN_KEYWORD_BREAK:
          return yp_break_node_create(parser, &keyword, arguments);
        case YP_TOKEN_KEYWORD_NEXT:
          return yp_next_node_create(parser, &keyword, arguments);
        case YP_TOKEN_KEYWORD_RETURN:
          return yp_return_node_create(parser, &keyword, arguments);
        default:
          assert(false && "unreachable");
      }
    }
    case YP_TOKEN_KEYWORD_SUPER: {
      parser_lex(parser);

      yp_token_t keyword = parser->previous;
      yp_arguments_t arguments = yp_arguments(parser);
      parse_arguments_list(parser, &arguments, true);

      if (arguments.opening.type == YP_TOKEN_NOT_PROVIDED && arguments.arguments == NULL) {
        return yp_forwarding_super_node_create(parser, &keyword, &arguments);
      }

      return yp_super_node_create(parser, &keyword, &arguments);
    }
    case YP_TOKEN_KEYWORD_YIELD: {
      parser_lex(parser);

      yp_token_t keyword = parser->previous;
      yp_arguments_t arguments = yp_arguments(parser);
      parse_arguments_list(parser, &arguments, false);

      return yp_yield_node_create(parser, &keyword, &arguments.opening, arguments.arguments, &arguments.closing);
    }
    case YP_TOKEN_KEYWORD_CLASS: {
      parser_lex(parser);
      yp_token_t class_keyword = parser->previous;

      if (accept(parser, YP_TOKEN_LESS_LESS)) {
        yp_token_t operator = parser->previous;
        yp_node_t *expression = parse_expression(parser, YP_BINDING_POWER_NOT, "Expected to find an expression after `<<`.");

        yp_parser_scope_push(parser, &class_keyword, true);
        accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);

        yp_node_t *statements = NULL;
        if (!match_any_type_p(parser, 3, YP_TOKEN_KEYWORD_RESCUE, YP_TOKEN_KEYWORD_ENSURE, YP_TOKEN_KEYWORD_END)) {
          statements = parse_statements(parser, YP_CONTEXT_SCLASS);
        }

        if (match_any_type_p(parser, 2, YP_TOKEN_KEYWORD_RESCUE, YP_TOKEN_KEYWORD_ENSURE)) {
          statements = parse_rescues_as_begin(parser, statements);
        }

        expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close `class` statement.");

        yp_node_t *scope = parser->current_scope->node;
        yp_parser_scope_pop(parser);
        return yp_singleton_class_node_create(parser, scope, &class_keyword, &operator, expression, statements, &parser->previous);
      }

      yp_node_t *name = parse_expression(parser, YP_BINDING_POWER_CALL, "Expected to find a class name after `class`.");
      yp_token_t inheritance_operator;
      yp_node_t *superclass;

      if (match_type_p(parser, YP_TOKEN_LESS)) {
        inheritance_operator = parser->current;
        lex_state_set(parser, YP_LEX_STATE_BEG);

        parser->command_start = true;
        parser_lex(parser);

        superclass = parse_expression(parser, YP_BINDING_POWER_COMPOSITION, "Expected to find a superclass after `<`.");
      } else {
        inheritance_operator = not_provided(parser);
        superclass = NULL;
      }

      yp_parser_scope_push(parser, &class_keyword, true);
      accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);
      yp_node_t *statements = NULL;

      if (!match_any_type_p(parser, 3, YP_TOKEN_KEYWORD_RESCUE, YP_TOKEN_KEYWORD_ENSURE, YP_TOKEN_KEYWORD_END)) {
        yp_accepts_block_stack_push(parser, true);
        statements = parse_statements(parser, YP_CONTEXT_CLASS);
        yp_accepts_block_stack_pop(parser);
      }

      if (match_any_type_p(parser, 2, YP_TOKEN_KEYWORD_RESCUE, YP_TOKEN_KEYWORD_ENSURE)) {
        statements = parse_rescues_as_begin(parser, statements);
      }

      expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close `class` statement.");

      yp_node_t *scope = parser->current_scope->node;
      yp_parser_scope_pop(parser);
      return yp_class_node_create(parser, scope, &class_keyword, name, &inheritance_operator, superclass, statements, &parser->previous);
    }
    case YP_TOKEN_KEYWORD_DEF: {
      yp_token_t def_keyword = parser->current;

      yp_node_t *receiver = NULL;
      yp_token_t operator = not_provided(parser);
      yp_token_t name = not_provided(parser);

      context_push(parser, YP_CONTEXT_DEF_PARAMS);
      parser_lex(parser);

      switch (parser->current.type) {
        case YP_CASE_OPERATOR:
          yp_parser_scope_push(parser, &def_keyword, true);
          lex_state_set(parser, YP_LEX_STATE_ENDFN);
          parser_lex(parser);
          name = parser->previous;
          break;
        case YP_TOKEN_IDENTIFIER: {
          yp_parser_scope_push(parser, &def_keyword, true);
          parser_lex(parser);

          if (match_any_type_p(parser, 2, YP_TOKEN_DOT, YP_TOKEN_COLON_COLON)) {
            receiver = parse_vcall(parser);

            lex_state_set(parser, YP_LEX_STATE_FNAME);
            parser_lex(parser);

            operator = parser->previous;
            name = parse_method_definition_name(parser);

            if (name.type == YP_TOKEN_MISSING) {
              yp_diagnostic_list_append(&parser->error_list, parser->previous.start, parser->previous.end, "Expected a method name after receiver.");
            }
          } else {
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
          yp_parser_scope_push(parser, &def_keyword, true);
          parser_lex(parser);
          yp_token_t identifier = parser->previous;

          if (match_any_type_p(parser, 2, YP_TOKEN_DOT, YP_TOKEN_COLON_COLON)) {
            lex_state_set(parser, YP_LEX_STATE_FNAME);
            parser_lex(parser);
            operator = parser->previous;

            switch (identifier.type) {
              case YP_TOKEN_CONSTANT:
                receiver = yp_constant_read_node_create(parser, &identifier);
                break;
              case YP_TOKEN_INSTANCE_VARIABLE:
                receiver = yp_instance_variable_read_node_create(parser, &identifier);
                break;
              case YP_TOKEN_CLASS_VARIABLE:
                receiver = yp_class_variable_read_node_create(parser, &identifier);
                break;
              case YP_TOKEN_GLOBAL_VARIABLE:
                receiver = yp_global_variable_read_node_create(parser, &identifier);
                break;
              case YP_TOKEN_KEYWORD_NIL:
                receiver = yp_nil_node_create(parser, &identifier);
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
                receiver = yp_source_file_node_create(parser, &identifier);
                break;
              case YP_TOKEN_KEYWORD___LINE__:
                receiver = yp_source_line_node_create(parser, &identifier);
                break;
              case YP_TOKEN_KEYWORD___ENCODING__:
                receiver = yp_source_encoding_node_create(parser, &identifier);
                break;
              default:
                break;
            }

            name = parse_method_definition_name(parser);
            if (name.type == YP_TOKEN_MISSING) {
              yp_diagnostic_list_append(&parser->error_list, parser->previous.start, parser->previous.end, "Expected a method name after receiver.");
            }
          } else {
            name = identifier;
          }
          break;
        }
        case YP_TOKEN_PARENTHESIS_LEFT: {
          parser_lex(parser);
          yp_token_t lparen = parser->previous;
          yp_node_t *expression = parse_expression(parser, YP_BINDING_POWER_STATEMENT, "Expected to be able to parse receiver.");

          expect(parser, YP_TOKEN_PARENTHESIS_RIGHT, "Expected closing ')' for receiver.");
          yp_token_t rparen = parser->previous;

          lex_state_set(parser, YP_LEX_STATE_FNAME);
          expect_any(parser, "Expected '.' or '::' after receiver", 2, YP_TOKEN_DOT, YP_TOKEN_COLON_COLON);
          operator = parser->previous;

          receiver = yp_parentheses_node_create(parser, &lparen, expression, &rparen);

          yp_parser_scope_push(parser, &def_keyword, true);
          name = parse_method_definition_name(parser);
          break;
        }
        default:
          yp_parser_scope_push(parser, &def_keyword, true);
          name = parse_method_definition_name(parser);

          if (name.type == YP_TOKEN_MISSING) {
            yp_diagnostic_list_append(&parser->error_list, parser->previous.start, parser->previous.end, "Expected a method name after receiver.");
          }
          break;
      }

      yp_token_t lparen;
      yp_token_t rparen;
      yp_node_t *params;

      switch (parser->current.type) {
        case YP_TOKEN_PARENTHESIS_LEFT: {
          parser_lex(parser);
          lparen = parser->previous;

          if (match_type_p(parser, YP_TOKEN_PARENTHESIS_RIGHT)) {
            params = NULL;
          } else {
            params = parse_parameters(parser, YP_BINDING_POWER_DEFINED, true, false);
          }

          lex_state_set(parser, YP_LEX_STATE_BEG);
          parser->command_start = true;

          expect(parser, YP_TOKEN_PARENTHESIS_RIGHT, "Expected ')' after left parenthesis.");
          rparen = parser->previous;
          break;
        }
        case YP_CASE_PARAMETER: {
          lparen = not_provided(parser);
          rparen = not_provided(parser);
          params = parse_parameters(parser, YP_BINDING_POWER_DEFINED, false, false);
          break;
        }
        default: {
          lparen = not_provided(parser);
          rparen = not_provided(parser);
          params = NULL;
          break;
        }
      }

      context_pop(parser);
      yp_node_t *statements = NULL;
      yp_token_t equal;
      yp_token_t end_keyword;

      if (accept(parser, YP_TOKEN_EQUAL)) {
        equal = parser->previous;

        context_push(parser, YP_CONTEXT_DEF);
        statements = yp_statements_node_create(parser);

        yp_node_t *statement = parse_expression(parser, YP_BINDING_POWER_DEFINED, "Expected to be able to parse body of endless method definition.");
        yp_statements_node_body_append(statements, statement);

        context_pop(parser);
        end_keyword = not_provided(parser);
      } else {
        equal = not_provided(parser);

        if (lparen.type == YP_TOKEN_NOT_PROVIDED) {
          lex_state_set(parser, YP_LEX_STATE_BEG);
          parser->command_start = true;
          expect_any(parser, "Expected a terminator after the parameters", 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);
        } else {
          accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);
        }

        yp_accepts_block_stack_push(parser, true);
        if (!match_any_type_p(parser, 3, YP_TOKEN_KEYWORD_RESCUE, YP_TOKEN_KEYWORD_ENSURE, YP_TOKEN_KEYWORD_END)) {
          statements = parse_statements(parser, YP_CONTEXT_DEF);
        }

        if (match_any_type_p(parser, 2, YP_TOKEN_KEYWORD_RESCUE, YP_TOKEN_KEYWORD_ENSURE)) {
          statements = parse_rescues_as_begin(parser, statements);
        }

        yp_accepts_block_stack_pop(parser);
        expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close `def` statement.");
        end_keyword = parser->previous;
      }

      yp_node_t *scope = parser->current_scope->node;
      yp_parser_scope_pop(parser);

      return yp_def_node_create(
        parser,
        &name,
        receiver,
        params,
        statements,
        scope,
        &def_keyword,
        &operator,
        &lparen,
        &rparen,
        &equal,
        &end_keyword
      );
    }
    case YP_TOKEN_KEYWORD_DEFINED: {
      parser_lex(parser);
      yp_token_t keyword = parser->previous;

      yp_token_t lparen;
      yp_token_t rparen;
      yp_node_t *expression;

      if (accept(parser, YP_TOKEN_PARENTHESIS_LEFT)) {
        lparen = parser->previous;
        expression = parse_expression(parser, YP_BINDING_POWER_COMPOSITION, "Expected expression after `defined?`.");

        if (parser->recovering) {
          rparen = not_provided(parser);
        } else {
          expect(parser, YP_TOKEN_PARENTHESIS_RIGHT, "Expected ')' after 'defined?' expression.");
          rparen = parser->previous;
        }
      } else {
        lparen = not_provided(parser);
        rparen = not_provided(parser);
        expression = parse_expression(parser, YP_BINDING_POWER_DEFINED, "Expected expression after `defined?`.");
      }

      return yp_defined_node_create(
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

      return yp_post_execution_node_create(parser, &keyword, &opening, statements, &closing);
    }
    case YP_TOKEN_KEYWORD_FALSE:
      parser_lex(parser);
      return yp_false_node_create(parser, &parser->previous);
    case YP_TOKEN_KEYWORD_FOR: {
      parser_lex(parser);
      yp_token_t for_keyword = parser->previous;

      yp_node_t *index = parse_targets(parser, NULL, YP_BINDING_POWER_INDEX);
      yp_state_stack_push(&parser->do_loop_stack, true);

      expect(parser, YP_TOKEN_KEYWORD_IN, "Expected keyword in.");
      yp_token_t in_keyword = parser->previous;

      yp_node_t *collection = parse_expression(parser, YP_BINDING_POWER_COMPOSITION, "Expected collection.");
      yp_state_stack_pop(&parser->do_loop_stack);

      yp_token_t do_keyword;
      if (accept(parser, YP_TOKEN_KEYWORD_DO_LOOP)) {
        do_keyword = parser->previous;
      } else {
        do_keyword = not_provided(parser);
      }

      accept_any(parser, 2, YP_TOKEN_SEMICOLON, YP_TOKEN_NEWLINE);
      yp_node_t *statements = NULL;

      if (!accept(parser, YP_TOKEN_KEYWORD_END)) {
        statements = parse_statements(parser, YP_CONTEXT_FOR);
        expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close for loop.");
      }

      return yp_for_node_create(parser, index, collection, statements, &for_keyword, &in_keyword, &do_keyword, &parser->previous);
    }
    case YP_TOKEN_KEYWORD_IF:
      parser_lex(parser);
      return parse_conditional(parser, YP_CONTEXT_IF);
    case YP_TOKEN_KEYWORD_UNDEF: {
      parser_lex(parser);
      yp_undef_node_t *undef = YP_NODE_UPCAST(
        yp_undef_node_create(parser, &parser->previous),
        yp_undef_node_t
      );

      yp_node_t *name = parse_undef_argument(parser);
      if (name->type == YP_NODE_MISSING_NODE) {
        return YP_NODE_DOWNCAST(undef);
      }

      yp_undef_node_append(undef, name);

      while (match_type_p(parser, YP_TOKEN_COMMA)) {
        lex_state_set(parser, YP_LEX_STATE_FNAME | YP_LEX_STATE_FITEM);
        parser_lex(parser);
        name = parse_undef_argument(parser);
        if (name->type == YP_NODE_MISSING_NODE) {
          return YP_NODE_DOWNCAST(undef);
        }

        yp_undef_node_append(undef, name);
      }

      return YP_NODE_DOWNCAST(undef);
    }
    case YP_TOKEN_KEYWORD_NOT: {
      parser_lex(parser);

      yp_token_t message = parser->previous;
      yp_arguments_t arguments = yp_arguments(parser);
      yp_node_t *receiver = NULL;

      if (accept(parser, YP_TOKEN_PARENTHESIS_LEFT)) {
        arguments.opening = parser->previous;

        if (accept(parser, YP_TOKEN_PARENTHESIS_RIGHT)) {
          arguments.closing = parser->previous;
        } else {
          receiver = parse_expression(parser, YP_BINDING_POWER_COMPOSITION, "Expected expression after `not`.");

          if (!parser->recovering) {
            expect(parser, YP_TOKEN_PARENTHESIS_RIGHT, "Expected ')' after 'not' expression.");
            arguments.closing = parser->previous;
          }
        }
      } else {
        receiver = parse_expression(parser, YP_BINDING_POWER_DEFINED, "Expected expression after `not`.");
      }

      return yp_call_node_not_create(parser, receiver, &message, &arguments);
    }
    case YP_TOKEN_KEYWORD_UNLESS:
      parser_lex(parser);
      return parse_conditional(parser, YP_CONTEXT_UNLESS);
    case YP_TOKEN_KEYWORD_MODULE: {
      parser_lex(parser);

      yp_token_t module_keyword = parser->previous;
      yp_node_t *name = parse_expression(parser, YP_BINDING_POWER_CALL, "Expected to find a module name after `module`.");

      // If we can recover from a syntax error that occurred while parsing the
      // name of the module, then we'll handle that here.
      if (name->type == YP_NODE_MISSING_NODE) {
        yp_node_t *scope = yp_scope_node_create(parser, &module_keyword);
        yp_token_t end_keyword = (yp_token_t) { .type = YP_TOKEN_MISSING, .start = parser->previous.end, .end = parser->previous.end };
        return yp_module_node_create(parser, scope, &module_keyword, name, NULL, &end_keyword);
      }

      while (accept(parser, YP_TOKEN_COLON_COLON)) {
        yp_token_t double_colon = parser->previous;

        expect(parser, YP_TOKEN_CONSTANT, "Expected to find a module name after `::`.");
        yp_node_t *constant = yp_constant_read_node_create(parser, &parser->previous);

        name = yp_constant_path_node_create(parser, name, &double_colon, constant);
      }

      yp_parser_scope_push(parser, &module_keyword, true);
      accept_any(parser, 2, YP_TOKEN_SEMICOLON, YP_TOKEN_NEWLINE);
      yp_node_t *statements = NULL;

      if (!match_any_type_p(parser, 3, YP_TOKEN_KEYWORD_RESCUE, YP_TOKEN_KEYWORD_ENSURE, YP_TOKEN_KEYWORD_END)) {
        yp_accepts_block_stack_push(parser, true);
        statements = parse_statements(parser, YP_CONTEXT_MODULE);
        yp_accepts_block_stack_pop(parser);
      }

      if (match_any_type_p(parser, 2, YP_TOKEN_KEYWORD_RESCUE, YP_TOKEN_KEYWORD_ENSURE)) {
        statements = parse_rescues_as_begin(parser, statements);
      }

      yp_node_t *scope = parser->current_scope->node;
      yp_parser_scope_pop(parser);

      expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close `module` statement.");

      if (context_def_p(parser)) {
        yp_diagnostic_list_append(&parser->error_list, module_keyword.start, module_keyword.end, "Module definition in method body");
      }

      return yp_module_node_create(parser, scope, &module_keyword, name, statements, &parser->previous);
    }
    case YP_TOKEN_KEYWORD_NIL:
      parser_lex(parser);
      return yp_nil_node_create(parser, &parser->previous);
    case YP_TOKEN_KEYWORD_REDO:
      parser_lex(parser);
      return yp_redo_node_create(parser, &parser->previous);
    case YP_TOKEN_KEYWORD_RETRY:
      parser_lex(parser);
      return yp_retry_node_create(parser, &parser->previous);
    case YP_TOKEN_KEYWORD_SELF:
      parser_lex(parser);
      return yp_self_node_create(parser, &parser->previous);
    case YP_TOKEN_KEYWORD_TRUE:
      parser_lex(parser);
      return yp_true_node_create(parser, &parser->previous);
    case YP_TOKEN_KEYWORD_UNTIL: {
      yp_state_stack_push(&parser->do_loop_stack, true);
      parser_lex(parser);
      yp_token_t keyword = parser->previous;

      yp_node_t *predicate = parse_expression(parser, YP_BINDING_POWER_COMPOSITION, "Expected predicate expression after `until`.");
      yp_state_stack_pop(&parser->do_loop_stack);

      accept_any(parser, 3, YP_TOKEN_KEYWORD_DO_LOOP, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);
      yp_node_t *statements = NULL;

      if (!accept(parser, YP_TOKEN_KEYWORD_END)) {
        statements = parse_statements(parser, YP_CONTEXT_UNTIL);
        accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);
        expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close `until` statement.");
      }

      return yp_until_node_create(parser, &keyword, predicate, statements);
    }
    case YP_TOKEN_KEYWORD_WHILE: {
      yp_state_stack_push(&parser->do_loop_stack, true);
      parser_lex(parser);
      yp_token_t keyword = parser->previous;

      yp_node_t *predicate = parse_expression(parser, YP_BINDING_POWER_COMPOSITION, "Expected predicate expression after `while`.");
      yp_state_stack_pop(&parser->do_loop_stack);

      accept_any(parser, 3, YP_TOKEN_KEYWORD_DO_LOOP, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);
      yp_node_t *statements = NULL;

      if (!accept(parser, YP_TOKEN_KEYWORD_END)) {
        statements = parse_statements(parser, YP_CONTEXT_WHILE);
        accept_any(parser, 2, YP_TOKEN_NEWLINE, YP_TOKEN_SEMICOLON);
        expect(parser, YP_TOKEN_KEYWORD_END, "Expected `end` to close `while` statement.");
      }

      return yp_while_node_create(parser, &keyword, predicate, statements);
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
          if (match_type_p(parser, YP_TOKEN_STRING_END)) break;
        }

        expect(parser, YP_TOKEN_STRING_CONTENT, "Expected a symbol in a `%i` list.");

        yp_token_t opening = not_provided(parser);
        yp_token_t closing = not_provided(parser);

        yp_node_t *symbol = yp_node_symbol_node_create_and_unescape(parser, &opening, &parser->previous, &closing);
        yp_array_node_elements_append(array, symbol);
      }

      expect(parser, YP_TOKEN_STRING_END, "Expected a closing delimiter for a `%i` list.");
      yp_array_node_close_set(array, &parser->previous);

      return array;
    }
    case YP_TOKEN_PERCENT_UPPER_I: {
      parser_lex(parser);
      yp_token_t opening = parser->previous;
      yp_node_t *array = yp_array_node_create(parser, &opening, &opening);

      // This is the current node that we are parsing that will be added to the
      // list of elements.
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
              yp_array_node_elements_append(array, current);
              current = NULL;
            }

            parser_lex(parser);
            break;
          }
          case YP_TOKEN_STRING_CONTENT: {
            yp_token_t opening = not_provided(parser);
            yp_token_t closing = not_provided(parser);

            if (current == NULL) {
              // If we hit content and the current node is NULL, then this is
              // the first string content we've seen. In that case we're going
              // to create a new string node and set that to the current.
              parser_lex(parser);
              current = yp_node_symbol_node_create_and_unescape(parser, &opening, &parser->previous, &closing);
            } else if (current->type == YP_NODE_INTERPOLATED_SYMBOL_NODE) {
              // If we hit string content and the current node is an
              // interpolated string, then we need to append the string content
              // to the list of child nodes.
              yp_node_t *part = parse_string_part(parser);
              yp_node_list_append(parser, current, &YP_NODE_UPCAST(current, yp_interpolated_symbol_node_t)->parts, part);
            } else {
              assert(false && "unreachable");
            }

            break;
          }
          case YP_TOKEN_EMBVAR: {
            if (current == NULL) {
              // If we hit an embedded variable and the current node is NULL,
              // then this is the start of a new string. We'll set the current
              // node to a new interpolated string.
              yp_token_t opening = not_provided(parser);
              yp_token_t closing = not_provided(parser);
              current = yp_interpolated_symbol_node_create(parser, &opening, NULL, &closing);
            } else if (current->type == YP_NODE_SYMBOL_NODE) {
              // If we hit an embedded variable and the current node is a string
              // node, then we'll convert the current into an interpolated
              // string and add the string node to the list of parts.
              yp_token_t opening = not_provided(parser);
              yp_token_t closing = not_provided(parser);
              yp_node_t *interpolated = yp_interpolated_symbol_node_create(parser, &opening, NULL, &closing);

              yp_symbol_node_to_string_node(current);
              yp_node_list_append(parser, interpolated, &YP_NODE_UPCAST(interpolated, yp_interpolated_symbol_node_t)->parts, current);
              current = interpolated;
            } else {
              // If we hit an embedded variable and the current node is an
              // interpolated string, then we'll just add the embedded variable.
            }

            yp_node_t *part = parse_string_part(parser);
            yp_node_list_append(parser, current, &YP_NODE_UPCAST(current, yp_interpolated_symbol_node_t)->parts, part);
            break;
          }
          case YP_TOKEN_EMBEXPR_BEGIN: {
            if (current == NULL) {
              // If we hit an embedded expression and the current node is NULL,
              // then this is the start of a new string. We'll set the current
              // node to a new interpolated string.
              yp_token_t opening = not_provided(parser);
              yp_token_t closing = not_provided(parser);
              current = yp_interpolated_symbol_node_create(parser, &opening, NULL, &closing);
            } else if (current->type == YP_NODE_SYMBOL_NODE) {
              // If we hit an embedded expression and the current node is a
              // string node, then we'll convert the current into an
              // interpolated string and add the string node to the list of
              // parts.
              yp_token_t opening = not_provided(parser);
              yp_token_t closing = not_provided(parser);
              yp_node_t *interpolated = yp_interpolated_symbol_node_create(parser, &opening, NULL, &closing);

              yp_symbol_node_to_string_node(current);
              yp_node_list_append(parser, interpolated, &YP_NODE_UPCAST(interpolated, yp_interpolated_symbol_node_t)->parts, current);
              current = interpolated;
            } else if (current->type == YP_NODE_INTERPOLATED_SYMBOL_NODE) {
              // If we hit an embedded expression and the current node is an
              // interpolated string, then we'll just continue on.
            } else {
              assert(false && "unreachable");
            }

            yp_node_t *part = parse_string_part(parser);
            yp_node_list_append(parser, current, &YP_NODE_UPCAST(current, yp_interpolated_string_node_t)->parts, part);
            break;
          }
          default:
            expect(parser, YP_TOKEN_STRING_CONTENT, "Expected a symbol in a `%I` list.");
            parser_lex(parser);
            break;
        }
      }

      // If we have a current node, then we need to append it to the list.
      if (current) {
        yp_array_node_elements_append(array, current);
      }

      expect(parser, YP_TOKEN_STRING_END, "Expected a closing delimiter for a `%I` list.");
      yp_array_node_close_set(array, &parser->previous);

      return array;
    }
    case YP_TOKEN_PERCENT_LOWER_W: {
      parser_lex(parser);
      yp_token_t opening = parser->previous;
      yp_node_t *array = yp_array_node_create(parser, &opening, &opening);

      // skip all leading whitespaces
      accept(parser, YP_TOKEN_WORDS_SEP);

      while (!match_any_type_p(parser, 2, YP_TOKEN_STRING_END, YP_TOKEN_EOF)) {
        if (yp_array_node_size(array) == 0) {
          accept(parser, YP_TOKEN_WORDS_SEP);
        } else {
          expect(parser, YP_TOKEN_WORDS_SEP, "Expected a separator for the strings in a `%w` list.");
          if (match_type_p(parser, YP_TOKEN_STRING_END)) break;
        }
        expect(parser, YP_TOKEN_STRING_CONTENT, "Expected a string in a `%w` list.");

        yp_token_t opening = not_provided(parser);
        yp_token_t closing = not_provided(parser);
        yp_node_t *string = yp_node_string_node_create_and_unescape(parser, &opening, &parser->previous, &closing, YP_UNESCAPE_MINIMAL);
        yp_array_node_elements_append(array, string);
      }

      expect(parser, YP_TOKEN_STRING_END, "Expected a closing delimiter for a `%w` list.");
      yp_array_node_close_set(array, &parser->previous);

      return array;
    }
    case YP_TOKEN_PERCENT_UPPER_W: {
      parser_lex(parser);
      yp_token_t opening = parser->previous;
      yp_node_t *array = yp_array_node_create(parser, &opening, &opening);

      // This is the current node that we are parsing that will be added to the
      // list of elements.
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
              yp_array_node_elements_append(array, current);
              current = NULL;
            }

            parser_lex(parser);
            break;
          }
          case YP_TOKEN_STRING_CONTENT: {
            if (current == NULL) {
              // If we hit content and the current node is NULL, then this is
              // the first string content we've seen. In that case we're going
              // to create a new string node and set that to the current.
              current = parse_string_part(parser);
            } else if (current->type == YP_NODE_INTERPOLATED_STRING_NODE) {
              // If we hit string content and the current node is an
              // interpolated string, then we need to append the string content
              // to the list of child nodes.
              yp_node_t *part = parse_string_part(parser);
              yp_node_list_append(parser, current, &YP_NODE_UPCAST(current, yp_interpolated_string_node_t)->parts, part);
            } else {
              assert(false && "unreachable");
            }

            break;
          }
          case YP_TOKEN_EMBVAR: {
            if (current == NULL) {
              // If we hit an embedded variable and the current node is NULL,
              // then this is the start of a new string. We'll set the current
              // node to a new interpolated string.
              yp_token_t opening = not_provided(parser);
              yp_token_t closing = not_provided(parser);
              current = yp_interpolated_string_node_create(parser, &opening, NULL, &closing);
            } else if (current->type == YP_NODE_STRING_NODE) {
              // If we hit an embedded variable and the current node is a string
              // node, then we'll convert the current into an interpolated
              // string and add the string node to the list of parts.
              yp_token_t opening = not_provided(parser);
              yp_token_t closing = not_provided(parser);
              yp_interpolated_string_node_t *interpolated = YP_NODE_UPCAST(
                yp_interpolated_string_node_create(parser, &opening, NULL, &closing),
                yp_interpolated_string_node_t
              );

              yp_node_list_append(parser, YP_NODE_DOWNCAST(interpolated), &interpolated->parts, current);
              current = YP_NODE_DOWNCAST(interpolated);
            } else {
              // If we hit an embedded variable and the current node is an
              // interpolated string, then we'll just add the embedded variable.
            }

            yp_node_t *part = parse_string_part(parser);
            yp_node_list_append(parser, current, &YP_NODE_UPCAST(current, yp_interpolated_string_node_t)->parts, part);
            break;
          }
          case YP_TOKEN_EMBEXPR_BEGIN: {
            if (current == NULL) {
              // If we hit an embedded expression and the current node is NULL,
              // then this is the start of a new string. We'll set the current
              // node to a new interpolated string.
              yp_token_t opening = not_provided(parser);
              yp_token_t closing = not_provided(parser);
              current = yp_interpolated_string_node_create(parser, &opening, NULL, &closing);
            } else if (current->type == YP_NODE_STRING_NODE) {
              // If we hit an embedded expression and the current node is a
              // string node, then we'll convert the current into an
              // interpolated string and add the string node to the list of
              // parts.
              yp_token_t opening = not_provided(parser);
              yp_token_t closing = not_provided(parser);
              yp_node_t *interpolated = yp_interpolated_string_node_create(parser, &opening, NULL, &closing);
              yp_node_list_append(parser, interpolated, &YP_NODE_UPCAST(interpolated, yp_interpolated_string_node_t)->parts, current);
              current = interpolated;
            } else if (current->type == YP_NODE_INTERPOLATED_STRING_NODE) {
              // If we hit an embedded expression and the current node is an
              // interpolated string, then we'll just continue on.
            } else {
              assert(false && "unreachable");
            }

            yp_node_t *part = parse_string_part(parser);
            yp_node_list_append(parser, current, &YP_NODE_UPCAST(current, yp_interpolated_string_node_t)->parts, part);
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
        yp_array_node_elements_append(array, current);
      }

      expect(parser, YP_TOKEN_STRING_END, "Expected a closing delimiter for a `%W` list.");
      yp_array_node_close_set(array, &parser->previous);

      return array;
    }
    case YP_TOKEN_RATIONAL_NUMBER:
      parser_lex(parser);
      return yp_rational_node_create(parser, &parser->previous);
    case YP_TOKEN_REGEXP_BEGIN: {
      yp_token_t opening = parser->current;
      parser_lex(parser);

      if (match_type_p(parser, YP_TOKEN_REGEXP_END)) {
        // If we get here, then we have an end immediately after a start. In
        // that case we'll create an empty content token and return an
        // uninterpolated regular expression.
        yp_token_t content = (yp_token_t) {
          .type = YP_TOKEN_STRING_CONTENT,
          .start = parser->previous.end,
          .end = parser->previous.end
        };

        parser_lex(parser);
        return yp_regular_expression_node_create(parser, &opening, &content, &parser->previous);
      }

      yp_node_t *node;

      if (match_type_p(parser, YP_TOKEN_STRING_CONTENT)) {
        // In this case we've hit string content so we know the regular
        // expression at least has something in it. We'll need to check if the
        // following token is the end (in which case we can return a plain
        // regular expression) or if it's not then it has interpolation.
        yp_token_t content = parser->current;
        parser_lex(parser);

        // If we hit an end, then we can create a regular expression node
        // without interpolation, which can be represented more succinctly and
        // more easily compiled.
        if (accept(parser, YP_TOKEN_REGEXP_END)) {
          return yp_node_regular_expression_node_create_and_unescape(parser, &opening, &content, &parser->previous, YP_UNESCAPE_ALL);
        }

        // If we get here, then we have interpolation so we'll need to create
        // a regular expression node with interpolation.
        node = yp_interpolated_regular_expression_node_create(parser, &opening, &opening);

        yp_token_t opening = not_provided(parser);
        yp_token_t closing = not_provided(parser);
        yp_node_t *part = yp_node_string_node_create_and_unescape(parser, &opening, &parser->previous, &closing, YP_UNESCAPE_ALL);

        yp_node_list_append(parser, node, &YP_NODE_UPCAST(node, yp_interpolated_regular_expression_node_t)->parts, part);
      } else {
        // If the first part of the body of the regular expression is not a
        // string content, then we have interpolation and we need to create an
        // interpolated regular expression node.
        node = yp_interpolated_regular_expression_node_create(parser, &opening, &opening);
      }

      // Now that we're here and we have interpolation, we'll parse all of the
      // parts into the list.
      while (!match_any_type_p(parser, 2, YP_TOKEN_REGEXP_END, YP_TOKEN_EOF)) {
        yp_node_t *part = parse_string_part(parser);
        if (part != NULL) {
          yp_node_list_append(parser, node, &YP_NODE_UPCAST(node, yp_interpolated_regular_expression_node_t)->parts, part);
        }
      }

      expect(parser, YP_TOKEN_REGEXP_END, "Expected a closing delimiter for a regular expression.");
      YP_NODE_UPCAST(node, yp_interpolated_regular_expression_node_t)->closing = parser->previous;
      node->location.end = parser->previous.end;

      return node;
    }
    case YP_TOKEN_BACKTICK:
    case YP_TOKEN_PERCENT_LOWER_X: {
      parser_lex(parser);
      yp_token_t opening = parser->previous;

      // When we get here, we don't know if this string is going to have
      // interpolation or not, even though it is allowed. Still, we want to be
      // able to return a string node without interpolation if we can since
      // it'll be faster.
      if (match_type_p(parser, YP_TOKEN_STRING_END)) {
        // If we get here, then we have an end immediately after a start. In
        // that case we'll create an empty content token and return an
        // uninterpolated string.
        yp_token_t content = (yp_token_t) {
          .type = YP_TOKEN_STRING_CONTENT,
          .start = parser->previous.end,
          .end = parser->previous.end
        };

        parser_lex(parser);
        return yp_xstring_node_create(parser, &opening, &content, &parser->previous);
      }

      yp_node_t *node;

      if (match_type_p(parser, YP_TOKEN_STRING_CONTENT)) {
        // In this case we've hit string content so we know the string at least
        // has something in it. We'll need to check if the following token is
        // the end (in which case we can return a plain string) or if it's not
        // then it has interpolation.
        yp_token_t content = parser->current;
        parser_lex(parser);

        if (accept(parser, YP_TOKEN_STRING_END)) {
          return yp_node_xstring_node_create_and_unescape(parser, &opening, &content, &parser->previous);
        }

        // If we get here, then we have interpolation so we'll need to create
        // a string node with interpolation.
        node = yp_interpolated_xstring_node_create(parser, &opening, &opening);

        yp_token_t opening = not_provided(parser);
        yp_token_t closing = not_provided(parser);
        yp_node_t *part = yp_node_string_node_create_and_unescape(parser, &opening, &parser->previous, &closing, YP_UNESCAPE_ALL);
        yp_node_list_append(parser, node, &YP_NODE_UPCAST(node, yp_interpolated_x_string_node_t)->parts, part);
      } else {
        // If the first part of the body of the string is not a string content,
        // then we have interpolation and we need to create an interpolated
        // string node.
        node = yp_interpolated_xstring_node_create(parser, &opening, &opening);
      }

      while (!match_any_type_p(parser, 2, YP_TOKEN_STRING_END, YP_TOKEN_EOF)) {
        yp_node_t *part = parse_string_part(parser);
        if (part != NULL) yp_node_list_append(parser, node, &YP_NODE_UPCAST(node, yp_interpolated_x_string_node_t)->parts, part);
      }

      expect(parser, YP_TOKEN_STRING_END, "Expected a closing delimiter for an xstring.");
      YP_NODE_UPCAST(node, yp_interpolated_x_string_node_t)->closing = parser->previous;
      node->location.end = parser->previous.end;

      return node;
    }
    case YP_TOKEN_USTAR: {
      parser_lex(parser);

      // * operators at the beginning of expressions are only valid in the
      // context of a multiple assignment. We enforce that here. We'll still lex
      // past it though and create a missing node place.
      if (binding_power != YP_BINDING_POWER_STATEMENT) {
        return yp_missing_node_create(parser, &(yp_location_t) {
          .start = parser->previous.start,
          .end = parser->previous.end,
        });
      }

      yp_token_t operator = parser->previous;
      yp_node_t *name = NULL;

      if (token_begins_expression_p(parser->current.type)) {
        name = parse_expression(parser, YP_BINDING_POWER_INDEX, "Expected an expression after '*'.");
      }

      yp_node_t *splat = yp_splat_node_create(parser, &operator, name);
      return parse_targets(parser, splat, YP_BINDING_POWER_INDEX);
    }
    case YP_TOKEN_BANG: {
      parser_lex(parser);

      yp_token_t operator = parser->previous;
      yp_node_t *receiver = parse_expression(parser, yp_binding_powers[parser->previous.type].right, "Expected a receiver after unary !.");
      yp_node_t *node = yp_call_node_unary_create(parser, &operator, receiver, "!");

      return node;
    }
    case YP_TOKEN_TILDE: {
      parser_lex(parser);

      yp_token_t operator = parser->previous;
      yp_node_t *receiver = parse_expression(parser, yp_binding_powers[parser->previous.type].right, "Expected a receiver after unary ~.");
      yp_node_t *node = yp_call_node_unary_create(parser, &operator, receiver, "~");

      return node;
    }
    case YP_TOKEN_UMINUS:
    case YP_TOKEN_UMINUS_NUM: {
      parser_lex(parser);

      yp_token_t operator = parser->previous;
      yp_node_t *receiver = parse_expression(parser, yp_binding_powers[parser->previous.type].right, "Expected a receiver after unary -.");
      yp_node_t *node = yp_call_node_unary_create(parser, &operator, receiver, "-@");

      return node;
    }
    case YP_TOKEN_MINUS_GREATER: {
      parser->lambda_enclosure_nesting = parser->enclosure_nesting;
      yp_accepts_block_stack_push(parser, true);
      parser_lex(parser);

      yp_token_t opening = parser->previous;
      yp_parser_scope_push(parser, &opening, false);

      yp_token_t lparen;
      yp_token_t rparen;
      yp_node_t *params;

      switch (parser->current.type) {
        case YP_TOKEN_PARENTHESIS_LEFT: {
          parser_lex(parser);
          lparen = parser->previous;

          if (match_type_p(parser, YP_TOKEN_PARENTHESIS_RIGHT)) {
            params = NULL;
          } else {
            params = parse_block_parameters(parser, false);
          }

          accept(parser, YP_TOKEN_NEWLINE);
          expect(parser, YP_TOKEN_PARENTHESIS_RIGHT, "Expected ')' after left parenthesis.");
          rparen = parser->previous;
          break;
        }
        case YP_CASE_PARAMETER: {
          lparen = not_provided(parser);
          rparen = not_provided(parser);
          params = parse_block_parameters(parser, false);
          break;
        }
        default: {
          lparen = not_provided(parser);
          rparen = not_provided(parser);
          params = NULL;
          break;
        }
      }

      yp_node_t *body = NULL;
      parser->lambda_enclosure_nesting = -1;

      if (accept(parser, YP_TOKEN_LAMBDA_BEGIN)) {
        if (!accept(parser, YP_TOKEN_BRACE_RIGHT)) {
          body = parse_statements(parser, YP_CONTEXT_LAMBDA_BRACES);
          expect(parser, YP_TOKEN_BRACE_RIGHT, "Expecting '}' to close lambda block.");
        }
      } else {
        expect(parser, YP_TOKEN_KEYWORD_DO, "Expected a 'do' keyword or a '{' to open lambda block.");

        if (!match_any_type_p(parser, 3, YP_TOKEN_KEYWORD_END, YP_TOKEN_KEYWORD_RESCUE, YP_TOKEN_KEYWORD_ENSURE)) {
          body = parse_statements(parser, YP_CONTEXT_LAMBDA_DO_END);
        }

        if (match_any_type_p(parser, 2, YP_TOKEN_KEYWORD_RESCUE, YP_TOKEN_KEYWORD_ENSURE)) {
          body = parse_rescues_as_begin(parser, body);
        }

        expect(parser, YP_TOKEN_KEYWORD_END, "Expecting 'end' keyword to close lambda block.");
      }

      yp_node_t *scope = parser->current_scope->node;
      yp_parser_scope_pop(parser);
      yp_accepts_block_stack_pop(parser);
      return yp_lambda_node_create(parser, scope, &opening, &lparen, params, &rparen, body);
    }
    case YP_TOKEN_UPLUS: {
      parser_lex(parser);

      yp_token_t operator = parser->previous;
      yp_node_t *receiver = parse_expression(parser, yp_binding_powers[parser->previous.type].right, "Expected a receiver after unary +.");
      yp_node_t *node = yp_call_node_unary_create(parser, &operator, receiver, "+@");

      return node;
    }
    case YP_TOKEN_STRING_BEGIN: {
      parser_lex(parser);

      yp_token_t opening = parser->previous;
      yp_node_t *node;

      if (accept(parser, YP_TOKEN_STRING_END)) {
        // If we get here, then we have an end immediately after a start. In
        // that case we'll create an empty content token and return an
        // uninterpolated string.
        yp_token_t content = (yp_token_t) {
          .type = YP_TOKEN_STRING_CONTENT,
          .start = parser->previous.start,
          .end = parser->previous.start
        };

        node = yp_node_string_node_create_and_unescape(parser, &opening, &content, &parser->previous, YP_UNESCAPE_NONE);
      } else if (accept(parser, YP_TOKEN_LABEL_END)) {
        // If we get here, then we have an end of a label immediately after a
        // start. In that case we'll create an empty symbol node.
        yp_token_t opening = not_provided(parser);
        yp_token_t content = (yp_token_t) {
          .type = YP_TOKEN_STRING_CONTENT,
          .start = parser->previous.start,
          .end = parser->previous.start
        };

        return yp_symbol_node_create(parser, &opening, &content, &parser->previous);
      } else if (!lex_mode->as.string.interpolation) {
        // If we don't accept interpolation then we only expect there to be a
        // single string content token immediately after the opening delimiter.
        expect(parser, YP_TOKEN_STRING_CONTENT, "Expected string content after opening delimiter.");
        yp_token_t content = parser->previous;

        if (accept(parser, YP_TOKEN_LABEL_END)) {
          return yp_node_symbol_node_create_and_unescape(parser, &opening, &content, &parser->previous);
        }

        expect(parser, YP_TOKEN_STRING_END, "Expected a closing delimiter for a string literal.");
        node = yp_node_string_node_create_and_unescape(parser, &opening, &content, &parser->previous, YP_UNESCAPE_MINIMAL);
      } else if (match_type_p(parser, YP_TOKEN_STRING_CONTENT)) {
        // In this case we've hit string content so we know the string at
        // least has something in it. We'll need to check if the following
        // token is the end (in which case we can return a plain string) or if
        // it's not then it has interpolation.
        yp_token_t content = parser->current;
        parser_lex(parser);

        if (accept(parser, YP_TOKEN_STRING_END)) {
          node = yp_node_string_node_create_and_unescape(parser, &opening, &content, &parser->previous, YP_UNESCAPE_ALL);
        } else if (accept(parser, YP_TOKEN_LABEL_END)) {
          return yp_node_symbol_node_create_and_unescape(parser, &opening, &content, &parser->previous);
        } else {
          // If we get here, then we have interpolation so we'll need to create
          // a string or symbol node with interpolation.
          yp_node_list_t parts;
          yp_node_list_init(&parts);

          yp_token_t string_opening = not_provided(parser);
          yp_token_t string_closing = not_provided(parser);
          yp_node_t *part = yp_node_string_node_create_and_unescape(parser, &string_opening, &parser->previous, &string_closing, YP_UNESCAPE_ALL);
          yp_node_list_append2(&parts, part);

          while (!match_any_type_p(parser, 3, YP_TOKEN_STRING_END, YP_TOKEN_LABEL_END, YP_TOKEN_EOF)) {
            yp_node_t *part = parse_string_part(parser);
            if (part != NULL) yp_node_list_append2(&parts, part);
          }

          if (accept(parser, YP_TOKEN_LABEL_END)) {
            return yp_interpolated_symbol_node_create(parser, &opening, &parts, &parser->previous);
          }

          expect(parser, YP_TOKEN_STRING_END, "Expected a closing delimiter for an interpolated string.");
          node = yp_interpolated_string_node_create(parser, &opening, &parts, &parser->previous);
        }
      } else {
        // If we get here, then the first part of the string is not plain string
        // content, in which case we need to parse the string as an interpolated
        // string.
        yp_node_list_t parts;
        yp_node_list_init(&parts);

        while (!match_any_type_p(parser, 3, YP_TOKEN_STRING_END, YP_TOKEN_LABEL_END, YP_TOKEN_EOF)) {
          yp_node_t *part = parse_string_part(parser);
          if (part != NULL) yp_node_list_append2(&parts, part);
        }

        if (accept(parser, YP_TOKEN_LABEL_END)) {
          return yp_interpolated_symbol_node_create(parser, &opening, &parts, &parser->previous);
        }

        expect(parser, YP_TOKEN_STRING_END, "Expected a closing delimiter for an interpolated string.");
        node = yp_interpolated_string_node_create(parser, &opening, &parts, &parser->previous);
      }

      // If there's a string immediately following this string, then it's a
      // concatenatation. In this case we'll parse the next string and create a
      // node in the tree that concatenates the two strings.
      if (parser->current.type == YP_TOKEN_STRING_BEGIN) {
        return yp_string_concat_node_create(
          parser,
          node,
          parse_expression(parser, YP_BINDING_POWER_CALL, "Expected string on the right side of concatenation.")
        );
      } else {
        return node;
      }
    }
    case YP_TOKEN_SYMBOL_BEGIN:
      parser_lex(parser);
      return parse_symbol(parser, lex_mode, YP_LEX_STATE_END);
    default:
      if (context_recoverable(parser, &parser->current)) {
        parser->recovering = true;
      }

      return yp_missing_node_create(parser, &(yp_location_t) {
        .start = parser->previous.start,
        .end = parser->previous.end,
      });
  }
}

static inline yp_node_t *
parse_assignment_value(yp_parser_t *parser, yp_binding_power_t previous_binding_power, yp_binding_power_t binding_power, const char *message) {
  yp_node_t *value = parse_starred_expression(parser, binding_power, message);

  if (previous_binding_power == YP_BINDING_POWER_STATEMENT && accept(parser, YP_TOKEN_COMMA)) {
    yp_token_t opening = not_provided(parser);
    yp_token_t closing = not_provided(parser);
    yp_node_t *array = yp_array_node_create(parser, &opening, &closing);

    yp_array_node_elements_append(array, value);
    value = array;

    do {
      yp_node_t *element = parse_starred_expression(parser, binding_power, "Expected an element for the array.");
      yp_array_node_elements_append(array, element);
      if (element->type == YP_NODE_MISSING_NODE) break;
    } while (accept(parser, YP_TOKEN_COMMA));
  }

  return value;
}

static inline yp_node_t *
parse_expression_infix(yp_parser_t *parser, yp_node_t *node, yp_binding_power_t previous_binding_power, yp_binding_power_t binding_power) {
  yp_token_t token = parser->current;

  switch (token.type) {
    case YP_TOKEN_EQUAL: {
      switch (node->type) {
        case YP_NODE_CALL_NODE: {
          // If we have no arguments to the call node and we need this to be a
          // target then this is either a method call or a local variable write.
          // This _must_ happen before the value is parsed because it could be
          // referenced in the value.
          if (yp_call_node_vcall_p(node)) {
            yp_parser_local_add(parser, &YP_NODE_UPCAST(node, yp_call_node_t)->message);
          }

          // fallthrough
        }
        case YP_CASE_WRITABLE: {
          parser_lex(parser);
          yp_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, "Expected a value after =.");
          return parse_target(parser, node, &token, value);
        }
        case YP_NODE_SPLAT_NODE: {
          switch (YP_NODE_UPCAST(node, yp_splat_node_t)->expression->type) {
            case YP_CASE_WRITABLE: {
              parser_lex(parser);
              yp_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, "Expected a value after =.");
              return parse_target(parser, node, &token, value);
            }
            default: {}
          }

          // fallthrough
        }
        default:
          parser_lex(parser);

          // In this case we have an = sign, but we don't know what it's for. We
          // need to treat it as an error. For now, we'll mark it as an error
          // and just skip right past it.
          yp_diagnostic_list_append(&parser->error_list, token.start, token.end, "Unexpected `='.");
          return node;
      }
    }
    case YP_TOKEN_AMPERSAND_AMPERSAND_EQUAL: {
      switch (node->type) {
        case YP_NODE_CALL_NODE: {
          // If we have no arguments to the call node and we need this to be a
          // target then this is either a method call or a local variable write.
          // This _must_ happen before the value is parsed because it could be
          // referenced in the value.
          if (yp_call_node_vcall_p(node)) {
            yp_parser_local_add(parser, &YP_NODE_UPCAST(node, yp_call_node_t)->message);
          }

          // fallthrough
        }
        case YP_CASE_WRITABLE: {
          yp_token_t operator = parser->current;
          parser_lex(parser);

          yp_token_t target_operator = not_provided(parser);
          node = parse_target(parser, node, &target_operator, NULL);

          if (node->type == YP_NODE_MULTI_WRITE_NODE) {
            yp_diagnostic_list_append(&parser->error_list, operator.start, operator.end, "Cannot use `&&=' on a multi-write.");
          }

          yp_node_t *value = parse_expression(parser, binding_power, "Expected a value after &&=");
          return yp_operator_and_assignment_node_create(parser, node, &token, value);
        }
        default:
          parser_lex(parser);

          // In this case we have an &&= sign, but we don't know what it's for.
          // We need to treat it as an error. For now, we'll mark it as an error
          // and just skip right past it.
          yp_diagnostic_list_append(&parser->error_list, parser->previous.start, parser->previous.end, "Unexpected `&&='.");
          return node;
      }
    }
    case YP_TOKEN_PIPE_PIPE_EQUAL: {
      switch (node->type) {
        case YP_NODE_CALL_NODE: {
          // If we have no arguments to the call node and we need this to be a
          // target then this is either a method call or a local variable write.
          // This _must_ happen before the value is parsed because it could be
          // referenced in the value.
          if (yp_call_node_vcall_p(node)) {
            yp_parser_local_add(parser, &YP_NODE_UPCAST(node, yp_call_node_t)->message);
          }

          // fallthrough
        }
        case YP_CASE_WRITABLE: {
          yp_token_t operator = parser->current;
          parser_lex(parser);

          yp_token_t target_operator = not_provided(parser);
          node = parse_target(parser, node, &target_operator, NULL);

          if (node->type == YP_NODE_MULTI_WRITE_NODE) {
            yp_diagnostic_list_append(&parser->error_list, operator.start, operator.end, "Cannot use `||=' on a multi-write.");
          }

          yp_node_t *value = parse_expression(parser, binding_power, "Expected a value after ||=");
          return yp_operator_or_assignment_node_create(parser, node, &token, value);
        }
        default:
          parser_lex(parser);

          // In this case we have an ||= sign, but we don't know what it's for.
          // We need to treat it as an error. For now, we'll mark it as an error
          // and just skip right past it.
          yp_diagnostic_list_append(&parser->error_list, parser->previous.start, parser->previous.end, "Unexpected `||='.");
          return node;
      }
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
      switch (node->type) {
        case YP_NODE_CALL_NODE: {
          // If we have no arguments to the call node and we need this to be a
          // target then this is either a method call or a local variable write.
          // This _must_ happen before the value is parsed because it could be
          // referenced in the value.
          if (yp_call_node_vcall_p(node)) {
            yp_parser_local_add(parser, &YP_NODE_UPCAST(node, yp_call_node_t)->message);
          }

          // fallthrough
        }
        case YP_CASE_WRITABLE: {
          yp_token_t operator = not_provided(parser);
          node = parse_target(parser, node, &operator, NULL);

          parser_lex(parser);
          yp_node_t *value = parse_expression(parser, binding_power, "Expected a value after the operator.");
          return yp_operator_assignment_node_create(parser, node, &token, value);
        }
        default:
          parser_lex(parser);

          // In this case we have an operator but we don't know what it's for.
          // We need to treat it as an error. For now, we'll mark it as an error
          // and just skip right past it.
          yp_diagnostic_list_append(&parser->error_list, parser->previous.start, parser->previous.end, "Unexpected operator.");
          return node;
      }
    }
    case YP_TOKEN_AMPERSAND_AMPERSAND:
    case YP_TOKEN_KEYWORD_AND: {
      parser_lex(parser);

      yp_node_t *right = parse_expression(parser, binding_power, "Expected a value after the operator.");
      return yp_and_node_create(parser, node, &token, right);
    }
    case YP_TOKEN_KEYWORD_OR:
    case YP_TOKEN_PIPE_PIPE: {
      parser_lex(parser);

      yp_node_t *right = parse_expression(parser, binding_power, "Expected a value after the operator.");
      return yp_or_node_create(parser, node, &token, right);
    }
    case YP_TOKEN_EQUAL_TILDE: {
      // Note that we _must_ parse the value before adding the local variables
      // in order to properly mirror the behavior of Ruby. For example,
      //
      //     /(?<foo>bar)/ =~ foo
      //
      // In this case, `foo` should be a method call and not a local yet.
      parser_lex(parser);
      yp_node_t *argument = parse_expression(parser, binding_power, "Expected a value after the operator.");

      // If the receiver of this =~ is a regular expression node, then we need
      // to introduce local variables for it based on its named capture groups.
      if (node->type == YP_NODE_REGULAR_EXPRESSION_NODE) {
        yp_string_list_t named_captures;
        yp_string_list_init(&named_captures);

        yp_token_t *content = &YP_NODE_UPCAST(node, yp_regular_expression_node_t)->content;
        assert(yp_regexp_named_capture_group_names(content->start, content->end - content->start, &named_captures));

        for (size_t index = 0; index < named_captures.length; index++) {
          yp_string_t *name = &named_captures.strings[index];
          assert(name->type == YP_STRING_SHARED);

          yp_parser_local_add(parser, &(yp_token_t) {
            .type = YP_TOKEN_IDENTIFIER,
            .start = name->as.shared.start,
            .end = name->as.shared.end
          });
        }

        yp_string_list_free(&named_captures);
      }

      return yp_call_node_binary_create(parser, node, &token, argument);
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
      parser_lex(parser);

      yp_node_t *argument = parse_expression(parser, binding_power, "Expected a value after the operator.");
      return yp_call_node_binary_create(parser, node, &token, argument);
    }
    case YP_TOKEN_AMPERSAND_DOT:
    case YP_TOKEN_DOT: {
      parser_lex(parser);
      yp_token_t operator = parser->previous;
      yp_arguments_t arguments = yp_arguments(parser);

      // This if statement handles the foo.() syntax.
      if (match_type_p(parser, YP_TOKEN_PARENTHESIS_LEFT)) {
        parse_arguments_list(parser, &arguments, true);
        return yp_call_node_shorthand_create(parser, node, &operator, &arguments);
      }

      yp_token_t message;

      switch (parser->current.type) {
        case YP_CASE_OPERATOR:
        case YP_CASE_KEYWORD:
        case YP_TOKEN_CONSTANT:
        case YP_TOKEN_IDENTIFIER: {
          parser_lex(parser);
          message = parser->previous;
          break;
        }
        default: {
          yp_diagnostic_list_append(&parser->error_list, parser->current.start, parser->current.end, "Expected a valid method name");
          message = (yp_token_t) { .type = YP_TOKEN_MISSING, .start = parser->previous.end, .end = parser->previous.end };
        }
      }

      parse_arguments_list(parser, &arguments, true);
      yp_node_t *call = yp_call_node_call_create(parser, node, &operator, &message, &arguments);

      if (
        (previous_binding_power == YP_BINDING_POWER_STATEMENT) &&
        arguments.arguments == NULL &&
        arguments.opening.type == YP_TOKEN_NOT_PROVIDED &&
        match_type_p(parser, YP_TOKEN_COMMA)
      ) {
        return parse_targets(parser, call, YP_BINDING_POWER_INDEX);
      } else {
        return call;
      }
    }
    case YP_TOKEN_DOT_DOT:
    case YP_TOKEN_DOT_DOT_DOT: {
      parser_lex(parser);

      yp_node_t *right = NULL;
      if (token_begins_expression_p(parser->current.type)) {
        right = parse_expression(parser, binding_power, "Expected a value after the operator.");
      }

      return yp_range_node_create(parser, node, &token, right);
    }
    case YP_TOKEN_KEYWORD_IF_MODIFIER: {
      yp_token_t keyword = parser->current;
      parser_lex(parser);

      yp_node_t *predicate = parse_expression(parser, binding_power, "Expected a predicate after `if'.");
      return yp_if_node_modifier_create(parser, node, &keyword, predicate);
    }
    case YP_TOKEN_KEYWORD_UNLESS_MODIFIER: {
      yp_token_t keyword = parser->current;
      parser_lex(parser);

      yp_node_t *predicate = parse_expression(parser, binding_power, "Expected a predicate after `unless'.");
      return yp_unless_node_modifier_create(parser, node, &keyword, predicate);
    }
    case YP_TOKEN_KEYWORD_UNTIL_MODIFIER: {
      parser_lex(parser);
      yp_node_t *statements = yp_statements_node_create(parser);
      yp_statements_node_body_append(statements, node);

      yp_node_t *predicate = parse_expression(parser, binding_power, "Expected a predicate after 'until'");
      return yp_until_node_create(parser, &token, predicate, statements);
    }
    case YP_TOKEN_KEYWORD_WHILE_MODIFIER: {
      parser_lex(parser);
      yp_node_t *statements = yp_statements_node_create(parser);
      yp_statements_node_body_append(statements, node);

      yp_node_t *predicate = parse_expression(parser, binding_power, "Expected a predicate after 'while'");
      return yp_while_node_create(parser, &token, predicate, statements);
    }
    case YP_TOKEN_QUESTION_MARK: {
      parser_lex(parser);
      yp_node_t *true_expression = parse_expression(parser, YP_BINDING_POWER_DEFINED, "Expected a value after '?'");

      if (parser->recovering) {
        // If parsing the true expression of this ternary resulted in a syntax
        // error that we can recover from, then we're going to put missing nodes
        // and tokens into the remaining places. We want to be sure to do this
        // before the `expect` function call to make sure it doesn't
        // accidentally move past a ':' token that occurs after the syntax
        // error.
        yp_token_t colon = (yp_token_t) { .type = YP_TOKEN_MISSING, .start = parser->previous.end, .end = parser->previous.end };
        yp_node_t *false_expression = yp_missing_node_create(parser, &(yp_location_t) {
          .start = colon.start,
          .end = colon.end,
        });

        return yp_if_node_ternary_create(parser, node, &token, true_expression, &colon, false_expression);
      }

      accept(parser, YP_TOKEN_NEWLINE);
      expect(parser, YP_TOKEN_COLON, "Expected ':' after true expression in ternary operator.");

      yp_token_t colon = parser->previous;
      yp_node_t *false_expression = parse_expression(parser, YP_BINDING_POWER_DEFINED, "Expected a value after ':'");

      return yp_if_node_ternary_create(parser, node, &token, true_expression, &colon, false_expression);
    }
    case YP_TOKEN_COLON_COLON: {
      parser_lex(parser);
      yp_token_t delimiter = parser->previous;

      switch (parser->current.type) {
        case YP_TOKEN_CONSTANT: {
          parser_lex(parser);

          // If we have a constant immediately following a '::' operator, then
          // this can either be a constant path or a method call, depending on
          // what follows the constant.
          //
          // If we have parentheses, then this is a method call. That would look
          // like Foo::Bar().
          if (
            (parser->current.type == YP_TOKEN_PARENTHESIS_LEFT) ||
            (token_begins_expression_p(parser->current.type) || match_any_type_p(parser, 2, YP_TOKEN_USTAR, YP_TOKEN_USTAR_STAR))
          ) {
            yp_token_t message = parser->previous;
            yp_arguments_t arguments = yp_arguments(parser);
            parse_arguments_list(parser, &arguments, true);
            return yp_call_node_call_create(parser, node, &delimiter, &message, &arguments);
          }

          // Otherwise, this is a constant path. That would look like Foo::Bar.
          yp_node_t *child = yp_constant_read_node_create(parser, &parser->previous);
          return yp_constant_path_node_create(parser, node, &delimiter, child);
        }
        case YP_TOKEN_IDENTIFIER: {
          parser_lex(parser);

          // If we have an identifier following a '::' operator, then it is for
          // sure a method call.
          yp_arguments_t arguments = yp_arguments(parser);
          parse_arguments_list(parser, &arguments, true);
          return yp_call_node_call_create(parser, node, &delimiter, &parser->previous, &arguments);
        }
        case YP_TOKEN_PARENTHESIS_LEFT: {
          // If we have a parenthesis following a '::' operator, then it is the
          // method call shorthand. That would look like Foo::(bar).
          yp_arguments_t arguments = yp_arguments(parser);
          parse_arguments_list(parser, &arguments, true);

          return yp_call_node_shorthand_create(parser, node, &delimiter, &arguments);
        }
        default: {
          yp_diagnostic_list_append(&parser->error_list, delimiter.start, delimiter.end, "Expected identifier or constant after '::'");

          yp_node_t *child = yp_missing_node_create(parser, &(yp_location_t) {
            .start = delimiter.start,
            .end = delimiter.end,
          });

          return yp_constant_path_node_create(parser, node, &delimiter, child);
        }
      }
    }
    case YP_TOKEN_KEYWORD_RESCUE_MODIFIER: {
      parser_lex(parser);
      accept(parser, YP_TOKEN_NEWLINE);
      yp_node_t *value = parse_expression(parser, binding_power, "Expected a value after the rescue keyword.");

      return yp_rescue_modifier_node_create(parser, node, &token, value);
    }
    case YP_TOKEN_BRACKET_LEFT: {
      parser_lex(parser);

      yp_arguments_t arguments = yp_arguments(parser);
      arguments.opening = parser->previous;

      if (!accept(parser, YP_TOKEN_BRACKET_RIGHT)) {
        yp_accepts_block_stack_push(parser, true);
        arguments.arguments = yp_arguments_node_create(parser);

        parse_arguments(parser, arguments.arguments, false, YP_TOKEN_BRACKET_RIGHT);
        yp_accepts_block_stack_pop(parser);

        expect(parser, YP_TOKEN_BRACKET_RIGHT, "Expected ']' to close the bracket expression.");
      }

      arguments.closing = parser->previous;

      // If we have a comma after the closing bracket then this is a multiple
      // assignment and we should parse the targets.
      if (previous_binding_power == YP_BINDING_POWER_STATEMENT && match_type_p(parser, YP_TOKEN_COMMA)) {
        yp_node_t *aref = yp_call_node_aref_create(parser, node, &arguments);
        return parse_targets(parser, aref, YP_BINDING_POWER_INDEX);
      }

      // If we're at the end of the arguments, we can now check if there is a
      // block node that starts with a {. If there is, then we can parse it and
      // add it to the arguments.
      if (accept(parser, YP_TOKEN_BRACE_LEFT)) {
        arguments.block = parse_block(parser);
      } else if (yp_accepts_block_stack_p(parser) && accept(parser, YP_TOKEN_KEYWORD_DO)) {
        arguments.block = parse_block(parser);
      }

      return yp_call_node_aref_create(parser, node, &arguments);
    }
    case YP_TOKEN_KEYWORD_IN: {
      bool previous_pattern_matching_newlines = parser->pattern_matching_newlines;
      parser->pattern_matching_newlines = true;

      yp_token_t operator = parser->current;
      parser->command_start = false;
      lex_state_set(parser, YP_LEX_STATE_BEG | YP_LEX_STATE_LABEL);

      parser_lex(parser);

      yp_node_t *pattern = parse_pattern(parser, true, "Expected a pattern after `in'.");
      parser->pattern_matching_newlines = previous_pattern_matching_newlines;

      return yp_match_predicate_node_create(parser, node, pattern, &operator);
    }
    case YP_TOKEN_EQUAL_GREATER: {
      bool previous_pattern_matching_newlines = parser->pattern_matching_newlines;
      parser->pattern_matching_newlines = true;

      yp_token_t operator = parser->current;
      parser->command_start = false;
      lex_state_set(parser, YP_LEX_STATE_BEG | YP_LEX_STATE_LABEL);

      parser_lex(parser);

      yp_node_t *pattern = parse_pattern(parser, true, "Expected a pattern after `=>'.");
      parser->pattern_matching_newlines = previous_pattern_matching_newlines;

      return yp_match_required_node_create(parser, node, pattern, &operator);
    }
    default:
      assert(false && "unreachable");
      return NULL;
  }
}

// Parse an expression at the given point of the parser using the given binding
// power to parse subsequent chains. If this function finds a syntax error, it
// will append the error message to the parser's error list.
//
// Consumers of this function should always check parser->recovering to
// determine if they need to perform additional cleanup.
static yp_node_t *
parse_expression(yp_parser_t *parser, yp_binding_power_t binding_power, const char *message) {
  yp_token_t recovery = parser->previous;
  yp_node_t *node = parse_expression_prefix(parser, binding_power);

  // If we found a syntax error, then the type of node returned by
  // parse_expression_prefix is going to be a missing node. In that case we need
  // to add the error message to the parser's error list.
  if (node->type == YP_NODE_MISSING_NODE) {
    yp_diagnostic_list_append(&parser->error_list, recovery.end, recovery.end, message);
    return node;
  }

  // Otherwise we'll look and see if the next token can be parsed as an infix
  // operator. If it can, then we'll parse it using parse_expression_infix.
  yp_binding_powers_t current_binding_powers;
  while (
    current_binding_powers = yp_binding_powers[parser->current.type],
    binding_power <= current_binding_powers.left &&
    current_binding_powers.binary
   ) {
    node = parse_expression_infix(parser, node, binding_power, current_binding_powers.right);
  }

  return node;
}

static yp_node_t *
parse_program(yp_parser_t *parser) {
  yp_parser_scope_push(parser, &(yp_token_t) { .type = YP_TOKEN_EOF, .start = parser->start, .end = parser->start }, true);
  parser_lex(parser);

  yp_node_t *statements = parse_statements(parser, YP_CONTEXT_MAIN);
  yp_node_t *scope = parser->current_scope->node;
  yp_parser_scope_pop(parser);

  // If this is an empty file, then we're still going to parse all of the
  // statements in order to gather up all of the comments and such. Here we'll
  // correct the location information.
  if (yp_statements_node_body_length(statements) == 0) {
    yp_statements_node_location_set(statements, parser->start, parser->start);
  }

  return yp_program_node_create(parser, scope, statements);
}

/******************************************************************************/
/* External functions                                                         */
/******************************************************************************/

// Initialize a parser with the given start and end pointers.
__attribute__((__visibility__("default"))) extern void
yp_parser_init(yp_parser_t *parser, const char *source, size_t size) {
  *parser = (yp_parser_t) {
    .lex_state = YP_LEX_STATE_BEG,
    .command_start = true,
    .enclosure_nesting = 0,
    .lambda_enclosure_nesting = -1,
    .brace_nesting = 0,
    .lex_modes = {
      .index = 0,
      .stack = {{ .mode = YP_LEX_DEFAULT }},
      .current = &parser->lex_modes.stack[0],
    },
    .start = source,
    .end = source + size,
    .previous = { .type = YP_TOKEN_EOF, .start = source, .end = source },
    .current = { .type = YP_TOKEN_EOF, .start = source, .end = source },
    .next_start = NULL,
    .heredoc_end = NULL,
    .current_scope = NULL,
    .current_context = NULL,
    .recovering = false,
    .encoding = yp_encoding_utf_8,
    .encoding_changed_callback = NULL,
    .encoding_decode_callback = NULL,
    .encoding_comment_start = source,
    .lex_callback = NULL,
    .pattern_matching_newlines = false
  };

  yp_state_stack_init(&parser->do_loop_stack);
  yp_state_stack_init(&parser->accepts_block_stack);
  yp_accepts_block_stack_push(parser, true);

  yp_list_init(&parser->warning_list);
  yp_list_init(&parser->error_list);
  yp_list_init(&parser->comment_list);

  if (size >= 3 && (unsigned char) source[0] == 0xef && (unsigned char) source[1] == 0xbb && (unsigned char) source[2] == 0xbf) {
    // If the first three bytes of the source are the UTF-8 BOM, then we'll skip
    // over them.
    parser->current.end += 3;
  } else if (size >= 2 && source[0] == '#' && source[1] == '!') {
    // If the first two bytes of the source are a shebang, then we'll indicate
    // that the encoding comment is at the end of the shebang.
    const char *encoding_comment_start = memchr(source, '\n', size);
    if (encoding_comment_start) {
      parser->encoding_comment_start = encoding_comment_start + 1;
    }
  }
}

// Register a callback that will be called whenever YARP changes the encoding it
// is using to parse based on the magic comment.
__attribute__((__visibility__("default"))) extern void
yp_parser_register_encoding_changed_callback(yp_parser_t *parser, yp_encoding_changed_callback_t callback) {
  parser->encoding_changed_callback = callback;
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

// Free all of the memory associated with the comment list.
static inline void
yp_comment_list_free(yp_list_t *list) {
  yp_list_node_t *node, *next;

  for (node = list->head; node != NULL; node = next) {
    next = node->next;

    yp_comment_t *comment = (yp_comment_t *) node;
    free(comment);
  }
}

// Free any memory associated with the given parser.
__attribute__((__visibility__("default"))) extern void
yp_parser_free(yp_parser_t *parser) {
  yp_diagnostic_list_free(&parser->error_list);
  yp_diagnostic_list_free(&parser->warning_list);
  yp_comment_list_free(&parser->comment_list);
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

#undef YP_CASE_KEYWORD
#undef YP_CASE_OPERATOR
#undef YP_CASE_WRITABLE
#undef YP_STRINGIZE
#undef YP_STRINGIZE0
#undef YP_VERSION_MACRO
