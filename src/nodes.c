#include "nodes.h"

#define YP_LOCATION_NULL_VALUE(parser) ((yp_location_t) { .start = (parser)->start, .end = (parser)->start })
#define YP_LOCATION_TOKEN_VALUE(token) ((yp_location_t) { .start = (token)->start, .end = (token)->end })
#define YP_LOCATION_NODE_VALUE(node) ((yp_location_t) { .start = (node)->location.start, .end = (node)->location.end })
#define YP_TOKEN_NOT_PROVIDED_VALUE(parser) ((yp_token_t) { .type = YP_TOKEN_NOT_PROVIDED, .start = (parser)->start, .end = (parser)->start })

/******************************************************************************/
/* Helper functions                                                           */
/******************************************************************************/

// Initialize a stack-allocated yp_arguments_t struct to its default values and
// return it.
yp_arguments_t
yp_arguments(yp_parser_t *parser) {
  return (yp_arguments_t) {
    .opening = YP_TOKEN_NOT_PROVIDED_VALUE(parser),
    .arguments = NULL,
    .closing = YP_TOKEN_NOT_PROVIDED_VALUE(parser),
    .block = NULL
  };
}

// Initiailize a list of nodes.
void
yp_node_list_init(yp_node_list_t *node_list) {
  *node_list = (yp_node_list_t) { .nodes = NULL, .size = 0, .capacity = 0 };
}

// Append a new node onto the end of the node list.
void
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

// Allocate and initialize a new node of the given type from the given token.
// This function is used for simple nodes that effectively wrap a token.
static inline yp_node_t *
yp_node_create_from_token(yp_parser_t *parser, yp_node_type_t type, const yp_token_t *token) {
  yp_node_t *node = yp_node_alloc(parser);
  *node = (yp_node_t) { .type = type, .location = YP_LOCATION_TOKEN_VALUE(token) };
  return node;
}

/******************************************************************************/
/* Node-specific functions                                                    */
/******************************************************************************/

// Allocate and initialize a new alias node.
yp_node_t *
yp_alias_node_create(yp_parser_t *parser, const yp_token_t *keyword, yp_node_t *new_name, yp_node_t *old_name) {
  assert(keyword->type == YP_TOKEN_KEYWORD_ALIAS);
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_ALIAS_NODE,
    .location = {
      .start = keyword->start,
      .end = old_name->location.end
    },
    .as.alias_node = {
      .new_name = new_name,
      .old_name = old_name,
      .keyword_loc = YP_LOCATION_TOKEN_VALUE(keyword)
    }
  };

  return node;
}

// Allocate and initialize a new and node.
yp_node_t *
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
yp_node_t *
yp_arguments_node_create(yp_parser_t *parser) {
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_ARGUMENTS_NODE,
    .location = YP_LOCATION_NULL_VALUE(parser)
  };

  yp_node_list_init(&node->as.arguments_node.arguments);
  return node;
}

// Return the size of the given arguments node.
size_t
yp_arguments_node_size(yp_node_t *node) {
  return node->as.arguments_node.arguments.size;
}

// Append an argument to an arguments node.
void
yp_arguments_node_append(yp_node_t *arguments, yp_node_t *argument) {
  if (yp_arguments_node_size(arguments) == 0) {
    arguments->location.start = argument->location.start;
  }
  arguments->location.end = argument->location.end;
  yp_node_list_append2(&arguments->as.arguments_node.arguments, argument);
}

// Allocate and initialize a new ArrayNode node.
yp_node_t *
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
size_t
yp_array_node_size(yp_node_t *node) {
  return node->as.array_node.elements.size;
}

// Append an argument to an array node.
void
yp_array_node_append(yp_node_t *node, yp_node_t *element) {
  yp_node_list_append2(&node->as.array_node.elements, element);
}

// Set the closing token and end location of an array node.
void
yp_array_node_close_set(yp_node_t *node, const yp_token_t *closing) {
  assert(closing->type == YP_TOKEN_BRACKET_RIGHT || closing->type == YP_TOKEN_STRING_END || closing->type == YP_TOKEN_MISSING);
  node->location.end = closing->end;
  node->as.array_node.closing = *closing;
}

// Allocate and initialize a new assoc node.
yp_node_t *
yp_assoc_node_create(yp_parser_t *parser, yp_node_t *key, const yp_token_t *operator, yp_node_t *value) {
  yp_node_t *node = yp_node_alloc(parser);
  const char *end;

  if (value != NULL) {
    end = value->location.end;
  } else if (operator->type != YP_TOKEN_NOT_PROVIDED) {
    end = operator->end;
  } else {
    end = key->location.end;
  }

  *node = (yp_node_t) {
    .type = YP_NODE_ASSOC_NODE,
    .location = {
      .start = key->location.start,
      .end = end
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
yp_node_t *
yp_assoc_splat_node_create(yp_parser_t *parser, yp_node_t *value, const yp_token_t *operator) {
  assert(operator->type == YP_TOKEN_STAR_STAR);
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_ASSOC_SPLAT_NODE,
    .location = {
      .start = operator->start,
      .end = value->location.end
    },
    .as.assoc_splat_node = {
      .value = value,
      .operator_loc = YP_LOCATION_TOKEN_VALUE(operator)
    }
  };

  return node;
}

// Allocate and initialize new a begin node.
yp_node_t *
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
      .end_keyword = YP_TOKEN_NOT_PROVIDED_VALUE(parser)
    }
  };

  return node;
}

// Set the rescue clause and end location of a begin node.
void
yp_begin_node_rescue_clause_set(yp_node_t *node, yp_node_t *rescue_clause) {
  node->location.end = rescue_clause->location.end;
  node->as.begin_node.rescue_clause = rescue_clause;
}

// Set the else clause and end location of a begin node.
void
yp_begin_node_else_clause_set(yp_node_t *node, yp_node_t *else_clause) {
  node->location.end = else_clause->location.end;
  node->as.begin_node.else_clause = else_clause;
}

// Set the ensure clause and end location of a begin node.
void
yp_begin_node_ensure_clause_set(yp_node_t *node, yp_node_t *ensure_clause) {
  node->location.end = ensure_clause->location.end;
  node->as.begin_node.ensure_clause = ensure_clause;
}

// Set the end keyword and end location of a begin node.
void
yp_begin_node_end_keyword_set(yp_node_t *node, const yp_token_t *end_keyword) {
  assert(end_keyword->type == YP_TOKEN_KEYWORD_END || end_keyword->type == YP_TOKEN_MISSING);
  node->location.end = end_keyword->end;
  node->as.begin_node.end_keyword = *end_keyword;
}

// Allocate and initialize a new BlockArgumentNode node.
yp_node_t *
yp_block_argument_node_create(yp_parser_t *parser, const yp_token_t *operator, yp_node_t *expression) {
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_BLOCK_ARGUMENT_NODE,
    .location = {
      .start = operator->start,
      .end = expression->location.end
    },
    .as.block_argument_node = {
      .expression = expression,
      .operator_loc = YP_LOCATION_TOKEN_VALUE(operator)
    }
  };

  return node;
}

// Allocate and initialize a new BlockParameterNode node.
yp_node_t *
yp_block_parameter_node_create(yp_parser_t *parser, const yp_token_t *name, const yp_token_t *operator) {
  assert(operator->type == YP_TOKEN_NOT_PROVIDED || operator->type == YP_TOKEN_AMPERSAND);
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_BLOCK_PARAMETER_NODE,
    .location = {
      .start = operator->start,
      .end = (name->type == YP_TOKEN_NOT_PROVIDED ? operator->end : name->end)
    },
    .as.block_parameter_node = {
      .name = *name,
      .operator_loc = YP_LOCATION_TOKEN_VALUE(operator)
    }
  };

  return node;
}

// Allocate and initialize a new BreakNode node.
yp_node_t *
yp_break_node_create(yp_parser_t *parser, const yp_token_t *keyword, yp_node_t *arguments) {
  assert(keyword->type == YP_TOKEN_KEYWORD_BREAK);
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_BREAK_NODE,
    .location = {
      .start = keyword->start,
      .end = (arguments == NULL ? keyword->end : arguments->location.end)
    },
    .as.break_node = {
      .arguments = arguments,
      .keyword_loc = YP_LOCATION_TOKEN_VALUE(keyword)
    }
  };

  return node;
}

// Allocate and initialize a new CallNode node. This sets everything to NULL or
// YP_TOKEN_NOT_PROVIDED as appropriate such that its values can be overridden
// in the various specializations of this function.
yp_node_t *
yp_call_node_create(yp_parser_t *parser) {
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_CALL_NODE,
    .location = YP_LOCATION_NULL_VALUE(parser),
    .as.call_node = {
      .receiver = NULL,
      .call_operator = YP_TOKEN_NOT_PROVIDED_VALUE(parser),
      .message = YP_TOKEN_NOT_PROVIDED_VALUE(parser),
      .opening = YP_TOKEN_NOT_PROVIDED_VALUE(parser),
      .arguments = NULL,
      .closing = YP_TOKEN_NOT_PROVIDED_VALUE(parser),
      .block = NULL
    }
  };

  return node;
}

// Allocate and initialize a new CallNode node from an aref or an aset
// expression.
yp_node_t *
yp_call_node_aref_create(yp_parser_t *parser, yp_node_t *receiver, yp_arguments_t *arguments) {
  yp_node_t *node = yp_call_node_create(parser);

  node->location.start = receiver->location.start;
  if (arguments->block != NULL) {
    node->location.end = arguments->block->location.end;
  } else {
    node->location.end = arguments->closing.end;
  }

  node->as.call_node.receiver = receiver;
  node->as.call_node.message = (yp_token_t) {
    .type = YP_TOKEN_BRACKET_LEFT_RIGHT,
    .start = arguments->opening.start,
    .end = arguments->opening.end
  };

  node->as.call_node.opening = arguments->opening;
  node->as.call_node.arguments = arguments->arguments;
  node->as.call_node.closing = arguments->closing;
  node->as.call_node.block = arguments->block;

  yp_string_constant_init(&node->as.call_node.name, "[]", 2);
  return node;
}

// Allocate and initialize a new CallNode node from a binary expression.
yp_node_t *
yp_call_node_binary_create(yp_parser_t *parser, yp_node_t *receiver, yp_token_t *operator, yp_node_t *argument) {
  yp_node_t *node = yp_call_node_create(parser);

  node->location.start = receiver->location.start;
  node->location.end = argument->location.end;

  node->as.call_node.receiver = receiver;
  node->as.call_node.message = *operator;

  yp_node_t *arguments = yp_arguments_node_create(parser);
  yp_arguments_node_append(arguments, argument);
  node->as.call_node.arguments = arguments;

  yp_string_shared_init(&node->as.call_node.name, operator->start, operator->end);
  return node;
}

// Allocate and initialize a new CallNode node from a call expression.
yp_node_t *
yp_call_node_call_create(yp_parser_t *parser, yp_node_t *receiver, yp_token_t *operator, yp_token_t *message, yp_arguments_t *arguments) {
  yp_node_t *node = yp_call_node_create(parser);

  node->location.start = receiver->location.start;
  if (arguments->block != NULL) {
    node->location.end = arguments->block->location.end;
  } else if (arguments->closing.type != YP_TOKEN_NOT_PROVIDED) {
    node->location.end = arguments->closing.end;
  } else if (arguments->arguments != NULL) {
    node->location.end = arguments->arguments->location.end;
  } else {
    node->location.end = message->end;
  }

  node->as.call_node.receiver = receiver;
  node->as.call_node.call_operator = *operator;
  node->as.call_node.message = *message;
  node->as.call_node.opening = arguments->opening;
  node->as.call_node.arguments = arguments->arguments;
  node->as.call_node.closing = arguments->closing;
  node->as.call_node.block = arguments->block;

  yp_string_shared_init(&node->as.call_node.name, message->start, message->end);
  return node;
}

// Allocate and initialize a new CallNode node from a call to a method name
// without a receiver that could not have been a local variable read.
yp_node_t *
yp_call_node_fcall_create(yp_parser_t *parser, yp_token_t *message, yp_arguments_t *arguments) {
  yp_node_t *node = yp_call_node_create(parser);

  node->location.start = message->start;
  if (arguments->block != NULL) {
    node->location.end = arguments->block->location.end;
  } else {
    node->location.end = arguments->closing.end;
  }

  node->as.call_node.message = *message;
  node->as.call_node.opening = arguments->opening;
  node->as.call_node.arguments = arguments->arguments;
  node->as.call_node.closing = arguments->closing;
  node->as.call_node.block = arguments->block;

  yp_string_shared_init(&node->as.call_node.name, message->start, message->end);
  return node;
}

// Allocate and initialize a new CallNode node from a not expression.
yp_node_t *
yp_call_node_not_create(yp_parser_t *parser, yp_node_t *receiver, yp_token_t *message, yp_arguments_t *arguments) {
  yp_node_t *node = yp_call_node_create(parser);

  node->location.start = message->start;
  if (arguments->closing.type != YP_TOKEN_NOT_PROVIDED) {
    node->location.end = arguments->closing.end;
  } else {
    node->location.end = receiver->location.end;
  }

  node->as.call_node.receiver = receiver;
  node->as.call_node.message = *message;
  node->as.call_node.opening = arguments->opening;
  node->as.call_node.arguments = arguments->arguments;
  node->as.call_node.closing = arguments->closing;

  yp_string_constant_init(&node->as.call_node.name, "!", 1);
  return node;
}

// Allocate and initialize a new CallNode node from a call shorthand expression.
yp_node_t *
yp_call_node_shorthand_create(yp_parser_t *parser, yp_node_t *receiver, yp_token_t *operator, yp_arguments_t *arguments) {
  yp_node_t *node = yp_call_node_create(parser);

  node->location.start = receiver->location.start;
  if (arguments->block != NULL) {
    node->location.end = arguments->block->location.end;
  } else {
    node->location.end = arguments->closing.end;
  }

  node->as.call_node.receiver = receiver;
  node->as.call_node.call_operator = *operator;
  node->as.call_node.opening = arguments->opening;
  node->as.call_node.arguments = arguments->arguments;
  node->as.call_node.closing = arguments->closing;
  node->as.call_node.block = arguments->block;

  yp_string_constant_init(&node->as.call_node.name, "call", 4);
  return node;
}

// Allocate and initialize a new CallNode node from a unary operator expression.
yp_node_t *
yp_call_node_unary_create(yp_parser_t *parser, yp_token_t *operator, yp_node_t *receiver, const char *name) {
  yp_node_t *node = yp_call_node_create(parser);

  node->location.start = operator->start;
  node->location.end = receiver->location.end;

  node->as.call_node.receiver = receiver;
  node->as.call_node.message = *operator;

  yp_string_constant_init(&node->as.call_node.name, name, strnlen(name, 2));
  return node;
}

// Allocate and initialize a new CallNode node from a call to a method name
// without a receiver that could also have been a local variable read.
yp_node_t *
yp_call_node_vcall_create(yp_parser_t *parser, yp_token_t *message) {
  yp_node_t *node = yp_call_node_create(parser);

  node->location.start = message->start;
  node->location.end = message->end;

  node->as.call_node.message = *message;

  yp_string_shared_init(&node->as.call_node.name, message->start, message->end);
  return node;
}

// Returns whether or not this call node is a "vcall" (a call to a method name
// without a receiver that could also have been a local variable read).
bool
yp_call_node_vcall_p(yp_node_t *node) {
  return (
    (node->as.call_node.opening.type == YP_TOKEN_NOT_PROVIDED) &&
    (node->as.call_node.arguments == NULL) &&
    (node->as.call_node.block == NULL) &&
    (node->as.call_node.receiver == NULL)
  );
}

// Allocate and initialize a new ClassVariableReadNode node.
yp_node_t *
yp_class_variable_read_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_CLASS_VARIABLE);
  return yp_node_create_from_token(parser, YP_NODE_CLASS_VARIABLE_READ_NODE, token);
}

// Initialize a new ClassVariableWriteNode node from a ClassVariableRead node.
yp_node_t *
yp_class_variable_write_node_init(yp_parser_t *parser, yp_node_t *node, yp_token_t *operator, yp_node_t *value) {
  assert(node->type == YP_NODE_CLASS_VARIABLE_READ_NODE);
  node->type = YP_NODE_CLASS_VARIABLE_WRITE_NODE;

  node->as.class_variable_write_node.name_loc = YP_LOCATION_NODE_VALUE(node);
  node->as.class_variable_write_node.operator_loc = YP_LOCATION_TOKEN_VALUE(operator);

  if (value != NULL) {
    node->location.end = value->location.end;
    node->as.class_variable_write_node.value = value;
  }

  return node;
}

// Allocate and initialize a new DefNode node.
yp_node_t *
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
  yp_node_t *node = yp_node_alloc(parser);
  const char *end;

  if (end_keyword->type == YP_TOKEN_NOT_PROVIDED) {
    end = statements->location.end;
  } else {
    end = end_keyword->end;
  }

  *node = (yp_node_t) {
    .type = YP_NODE_DEF_NODE,
    .location = { .start = def_keyword->start, .end = end },
    .as.def_node = {
      .name = *name,
      .receiver = receiver,
      .parameters = parameters,
      .statements = statements,
      .scope = scope,
      .def_keyword_loc = YP_LOCATION_TOKEN_VALUE(def_keyword),
      .operator_loc = YP_LOCATION_TOKEN_VALUE(operator),
      .lparen_loc = YP_LOCATION_TOKEN_VALUE(lparen),
      .rparen_loc = YP_LOCATION_TOKEN_VALUE(rparen),
      .equal_loc = YP_LOCATION_TOKEN_VALUE(equal),
      .end_keyword_loc = YP_LOCATION_TOKEN_VALUE(end_keyword)
    }
  };

  return node;
}

// Allocate and initialize a new FalseNode node.
yp_node_t *
yp_false_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_KEYWORD_FALSE);
  return yp_node_create_from_token(parser, YP_NODE_FALSE_NODE, token);
}

// Allocate and initialize a new FloatNode node.
yp_node_t *
yp_float_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_FLOAT);
  return yp_node_create_from_token(parser, YP_NODE_FLOAT_NODE, token);
}

// Allocate and initialize a new ForNode node.
yp_node_t *
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
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_FOR_NODE,
    .location = { .start = for_keyword->start, .end = statements->location.end },
    .as.for_node = {
      .index = index,
      .collection = collection,
      .statements = statements,
      .for_keyword_loc = YP_LOCATION_TOKEN_VALUE(for_keyword),
      .in_keyword_loc = YP_LOCATION_TOKEN_VALUE(in_keyword),
      .do_keyword_loc = YP_LOCATION_TOKEN_VALUE(do_keyword),
      .end_keyword_loc = YP_LOCATION_TOKEN_VALUE(end_keyword)
    }
  };

  return node;
}

// Allocate and initialize a new ForwardingArgumentsNode node.
yp_node_t *
yp_forwarding_arguments_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_UDOT_DOT_DOT);
  return yp_node_create_from_token(parser, YP_NODE_FORWARDING_ARGUMENTS_NODE, token);
}

// Allocate and initialize a new ForwardingParameterNode node.
yp_node_t *
yp_forwarding_parameter_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_UDOT_DOT_DOT);
  return yp_node_create_from_token(parser, YP_NODE_FORWARDING_PARAMETER_NODE, token);
}

// Allocate and initialize a new ForwardingSuper node.
yp_node_t *
yp_forwarding_super_node_create(yp_parser_t *parser, const yp_token_t *token, yp_arguments_t *arguments) {
  assert(token->type == YP_TOKEN_KEYWORD_SUPER);
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_FORWARDING_SUPER_NODE,
    .location = {
      .start = token->start,
      .end = arguments->block != NULL ? arguments->block->location.end : token->end
    },
    .as.forwarding_super_node.block = arguments->block
  };

  return node;
}

// Allocate and initialize a new ImaginaryNode node.
yp_node_t *
yp_imaginary_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_IMAGINARY_NUMBER);
  return yp_node_create_from_token(parser, YP_NODE_IMAGINARY_NODE, token);
}

// Allocate and initialize a new InstanceVariableReadNode node.
yp_node_t *
yp_instance_variable_read_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_INSTANCE_VARIABLE);
  return yp_node_create_from_token(parser, YP_NODE_INSTANCE_VARIABLE_READ_NODE, token);
}

// Initialize a new InstanceVariableWriteNode node from an InstanceVariableRead node.
yp_node_t *
yp_instance_variable_write_node_init(yp_parser_t *parser, yp_node_t *node, yp_token_t *operator, yp_node_t *value) {
  assert(node->type == YP_NODE_INSTANCE_VARIABLE_READ_NODE);
  node->type = YP_NODE_INSTANCE_VARIABLE_WRITE_NODE;

  node->as.instance_variable_write_node.name_loc = YP_LOCATION_NODE_VALUE(node);
  node->as.instance_variable_write_node.operator_loc = YP_LOCATION_TOKEN_VALUE(operator);

  if (value != NULL) {
    node->as.instance_variable_write_node.value = value;
    node->location.end = value->location.end;
  }

  return node;
}

// Allocate and initialize a new IntegerNode node.
yp_node_t *
yp_integer_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_INTEGER);
  return yp_node_create_from_token(parser, YP_NODE_INTEGER_NODE, token);
}

// Allocate and initialize a new InterpolatedStringNode node.
yp_node_t *
yp_interpolated_string_node_create(yp_parser_t *parser, const yp_token_t *opening, const yp_node_list_t *parts, const yp_token_t *closing) {
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_INTERPOLATED_STRING_NODE,
    .location = {
      .start = opening->start,
      .end = closing->end,
    },
    .as.interpolated_string_node = {
      .opening = *opening,
      .parts = *parts,
      .closing = *closing
    }
  };

  return node;
}

// Allocate and initialize a new InterpolatedSymbolNode node.
yp_node_t *
yp_interpolated_symbol_node_create(yp_parser_t *parser, const yp_token_t *opening, const yp_node_list_t *parts, const yp_token_t *closing) {
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_INTERPOLATED_SYMBOL_NODE,
    .location = {
      .start = opening->start,
      .end = closing->end,
    },
    .as.interpolated_symbol_node = {
      .opening = *opening,
      .parts = *parts,
      .closing = *closing
    }
  };

  return node;
}

// Allocate and initialize a new NextNode node.
yp_node_t *
yp_next_node_create(yp_parser_t *parser, const yp_token_t *keyword, yp_node_t *arguments) {
  assert(keyword->type == YP_TOKEN_KEYWORD_NEXT);
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_NEXT_NODE,
    .location = {
      .start = keyword->start,
      .end = (arguments == NULL ? keyword->end : arguments->location.end)
    },
    .as.next_node = {
      .keyword_loc = YP_LOCATION_TOKEN_VALUE(keyword),
      .arguments = arguments
    }
  };

  return node;
}

// Allocate and initialize a new NilNode node.
yp_node_t *
yp_nil_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_KEYWORD_NIL);
  return yp_node_create_from_token(parser, YP_NODE_NIL_NODE, token);
}

// Allocate and initialize a new NoKeywordsParameterNode node.
yp_node_t *
yp_no_keywords_parameter_node_create(yp_parser_t *parser, const yp_token_t *operator, const yp_token_t *keyword) {
  assert(operator->type == YP_TOKEN_STAR_STAR);
  assert(keyword->type == YP_TOKEN_KEYWORD_NIL);
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_NO_KEYWORDS_PARAMETER_NODE,
    .location = {
      .start = operator->start,
      .end = keyword->end
    },
    .as.no_keywords_parameter_node = {
      .operator_loc = YP_LOCATION_TOKEN_VALUE(operator),
      .keyword_loc = YP_LOCATION_TOKEN_VALUE(keyword)
    }
  };

  return node;
}

// Allocate and initialize a new OperatorAndAssignmentNode node.
yp_node_t *
yp_operator_and_assignment_node_create(yp_parser_t *parser, yp_node_t *target, const yp_token_t *operator, yp_node_t *value) {
  assert(operator->type == YP_TOKEN_AMPERSAND_AMPERSAND_EQUAL);
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_OPERATOR_AND_ASSIGNMENT_NODE,
    .location = {
      .start = target->location.start,
      .end = value->location.end
    },
    .as.operator_and_assignment_node = {
      .target = target,
      .value = value,
      .operator_loc = YP_LOCATION_TOKEN_VALUE(operator)
    }
  };

  return node;
}

// Allocate and initialize a new PostExecutionNode node.
yp_node_t *
yp_post_execution_node_create(yp_parser_t *parser, const yp_token_t *keyword, const yp_token_t *opening, yp_node_t *statements, const yp_token_t *closing) {
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_POST_EXECUTION_NODE,
    .location = {
      .start = keyword->start,
      .end = closing->end
    },
    .as.post_execution_node = {
      .statements = statements,
      .keyword_loc = YP_LOCATION_TOKEN_VALUE(keyword),
      .opening_loc = YP_LOCATION_TOKEN_VALUE(opening),
      .closing_loc = YP_LOCATION_TOKEN_VALUE(closing)
    }
  };

  return node;
}

// Allocate and initialize a new PreExecutionNode node.
yp_node_t *
yp_pre_execution_node_create(yp_parser_t *parser, const yp_token_t *keyword, const yp_token_t *opening, yp_node_t *statements, const yp_token_t *closing) {
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_PRE_EXECUTION_NODE,
    .location = {
      .start = keyword->start,
      .end = closing->end
    },
    .as.pre_execution_node = {
      .statements = statements,
      .keyword_loc = YP_LOCATION_TOKEN_VALUE(keyword),
      .opening_loc = YP_LOCATION_TOKEN_VALUE(opening),
      .closing_loc = YP_LOCATION_TOKEN_VALUE(closing)
    }
  };

  return node;
}

// Allocate and initialize a new RationalNode node.
yp_node_t *
yp_rational_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_RATIONAL_NUMBER);
  return yp_node_create_from_token(parser, YP_NODE_RATIONAL_NODE, token);
}

// Allocate and initialize a new RedoNode node.
yp_node_t *
yp_redo_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_KEYWORD_REDO);
  return yp_node_create_from_token(parser, YP_NODE_REDO_NODE, token);
}

// Allocate and initialize a new RetryNode node.
yp_node_t *
yp_retry_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_KEYWORD_RETRY);
  return yp_node_create_from_token(parser, YP_NODE_RETRY_NODE, token);
}

// Allocate and initialize a new SelfNode node.
yp_node_t *
yp_self_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_KEYWORD_SELF);
  return yp_node_create_from_token(parser, YP_NODE_SELF_NODE, token);
}

// Allocate and initialize a new SourceEncodingNode node.
yp_node_t *
yp_source_encoding_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_KEYWORD___ENCODING__);
  return yp_node_create_from_token(parser, YP_NODE_SOURCE_ENCODING_NODE, token);
}

// Allocate and initialize a new SourceFileNode node.
yp_node_t *
yp_source_file_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_KEYWORD___FILE__);
  return yp_node_create_from_token(parser, YP_NODE_SOURCE_FILE_NODE, token);
}

// Allocate and initialize a new SourceLineNode node.
yp_node_t *
yp_source_line_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_KEYWORD___LINE__);
  return yp_node_create_from_token(parser, YP_NODE_SOURCE_LINE_NODE, token);
}

// Check if the given node is a label in a hash.
bool
yp_symbol_node_label_p(yp_node_t *node) {
  return (
    (node->type == YP_NODE_SYMBOL_NODE && node->as.symbol_node.closing.type == YP_TOKEN_LABEL_END) ||
    (node->type == YP_NODE_INTERPOLATED_SYMBOL_NODE && node->as.interpolated_symbol_node.closing.type == YP_TOKEN_LABEL_END)
  );
}

// Convert the given SymbolNode node to a StringNode node.
void
yp_symbol_node_to_string_node(yp_parser_t *parser, yp_node_t *node) {
  *node = (yp_node_t) {
    .type = YP_NODE_STRING_NODE,
    .location = node->location,
    .as.string_node = {
      .opening = node->as.symbol_node.opening,
      .content = node->as.symbol_node.value,
      .closing = node->as.symbol_node.closing
    }
  };

  yp_unescape(
    node->as.string_node.content.start,
    node->as.string_node.content.end - node->as.string_node.content.start,
    &node->as.string_node.unescaped,
    YP_UNESCAPE_ALL,
    &parser->error_list
  );
}

// Allocate and initialize a new SuperNode node.
yp_node_t *
yp_super_node_create(yp_parser_t *parser, const yp_token_t *keyword, yp_arguments_t *arguments) {
  assert(keyword->type == YP_TOKEN_KEYWORD_SUPER);
  yp_node_t *node = yp_node_alloc(parser);

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

  *node = (yp_node_t) {
    .type = YP_NODE_SUPER_NODE,
    .location = {
      .start = keyword->start,
      .end = end,
    },
    .as.super_node = {
      .keyword = *keyword,
      .lparen = arguments->opening,
      .arguments = arguments->arguments,
      .rparen = arguments->closing,
      .block = arguments->block
    }
  };

  return node;
}

// Allocate and initialize a new TrueNode node.
yp_node_t *
yp_true_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_KEYWORD_TRUE);
  return yp_node_create_from_token(parser, YP_NODE_TRUE_NODE, token);
}

// Allocate and initialize a new UndefNode node.
yp_node_t *
yp_undef_node_create(yp_parser_t *parser, const yp_token_t *token) {
  assert(token->type == YP_TOKEN_KEYWORD_UNDEF);
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_UNDEF_NODE,
    .location = YP_LOCATION_TOKEN_VALUE(token),
    .as.undef_node.keyword_loc = YP_LOCATION_TOKEN_VALUE(token)
  };

  yp_node_list_init(&node->as.undef_node.names);
  return node;
}

// Append a name to an undef node.
void
yp_undef_node_append(yp_node_t *node, yp_node_t *name) {
  node->location.end = name->location.end;
  yp_node_list_append2(&node->as.undef_node.names, name);
}

// Allocate and initialize a new XStringNode node.
yp_node_t *
yp_xstring_node_create(yp_parser_t *parser, const yp_token_t *opening, const yp_token_t *content, const yp_token_t *closing) {
  yp_node_t *node = yp_node_alloc(parser);

  *node = (yp_node_t) {
    .type = YP_NODE_X_STRING_NODE,
    .location = {
      .start = opening->start,
      .end = closing->end
    },
    .as.x_string_node = {
      .opening = *opening,
      .content = *content,
      .closing = *closing
    }
  };

  return node;
}

#undef YP_LOCATION_NULL_VALUE
#undef YP_LOCATION_TOKEN_VALUE
#undef YP_LOCATION_NODE_VALUE
#undef YP_TOKEN_NOT_PROVIDED_VALUE
