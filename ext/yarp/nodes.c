#include "nodes.h"
#include "parser.h"

// Allocate the space for a new yp_node_t. Currently we're not using the
// parser argument, but it's there to allow for the future possibility of
// pre-allocating larger memory pools and then pulling from those here.
static inline yp_node_t *
yp_node_alloc(yp_parser_t *parser) {
  return malloc(sizeof(yp_node_t));
}

// Deallocate the space for a yp_node_t. Similarly to yp_node_alloc, we're not
// using the parser argument, but it's there to allow for the future possibility
// of pre-allocating larger memory pools.
static inline void
yp_node_free(yp_parser_t *parser, yp_node_t *node) {
  free(node);
}

// Allocate a new Assignment node.
yp_node_t *
yp_node_alloc_assignment(yp_parser_t *parser, yp_node_t *target, yp_token_t *operator, yp_node_t *value) {
  yp_node_t *node = yp_node_alloc(parser);
  *node = (yp_node_t) {
    .type = YP_NODE_ASSIGNMENT,
    .location = { .start = target->location.start, .end = value->location.end },
    .as.assignment = {
      .target = target,
      .operator = *operator,
      .value = value,
    }
  };
  return node;
}

// Allocate a new Binary node.
yp_node_t *
yp_node_alloc_binary(yp_parser_t *parser, yp_node_t *left, yp_token_t *operator, yp_node_t *right) {
  yp_node_t *node = yp_node_alloc(parser);
  *node = (yp_node_t) {
    .type = YP_NODE_BINARY,
    .location = { .start = left->location.start, .end = right->location.end },
    .as.binary = {
      .left = left,
      .operator = *operator,
      .right = right,
    }
  };
  return node;
}

// Allocate a new FloatLiteral node.
yp_node_t *
yp_node_alloc_float_literal(yp_parser_t *parser, yp_token_t *value) {
  yp_node_t *node = yp_node_alloc(parser);
  *node = (yp_node_t) {
    .type = YP_NODE_FLOAT_LITERAL,
    .location = { .start = value->start - parser->start, .end = value->end - parser->end },
    .as.float_literal = {
      .value = *value,
    }
  };
  return node;
}

// Allocate a new Identifier node.
yp_node_t *
yp_node_alloc_identifier(yp_parser_t *parser, yp_token_t *value) {
  yp_node_t *node = yp_node_alloc(parser);
  *node = (yp_node_t) {
    .type = YP_NODE_IDENTIFIER,
    .location = { .start = value->start - parser->start, .end = value->end - parser->end },
    .as.identifier = {
      .value = *value,
    }
  };
  return node;
}

// Allocate a new IntegerLiteral node.
yp_node_t *
yp_node_alloc_integer_literal(yp_parser_t *parser, yp_token_t *value) {
  yp_node_t *node = yp_node_alloc(parser);
  *node = (yp_node_t) {
    .type = YP_NODE_INTEGER_LITERAL,
    .location = { .start = value->start - parser->start, .end = value->end - parser->end },
    .as.integer_literal = {
      .value = *value,
    }
  };
  return node;
}

// Allocate a new VariableReference node.
yp_node_t *
yp_node_alloc_variable_reference(yp_parser_t *parser, yp_node_t *value) {
  yp_node_t *node = yp_node_alloc(parser);
  *node = (yp_node_t) {
    .type = YP_NODE_VARIABLE_REFERENCE,
    .location = value->location,
    .as.variable_reference = {
      .value = value,
    }
  };
  return node;
}

// Deallocate a node in the tree.
void
yp_node_dealloc(yp_parser_t *parser, yp_node_t *node) {
  switch (node->type) {
    case YP_NODE_ASSIGNMENT:
      yp_node_dealloc(parser, node->as.assignment.target);
      yp_node_dealloc(parser, node->as.assignment.value);
      yp_node_free(parser, node);
      break;
    case YP_NODE_BINARY:
      yp_node_dealloc(parser, node->as.binary.left);
      yp_node_dealloc(parser, node->as.binary.right);
      yp_node_free(parser, node);
      break;
    case YP_NODE_FLOAT_LITERAL:
      yp_node_free(parser, node);
      break;
    case YP_NODE_IDENTIFIER:
      yp_node_free(parser, node);
      break;
    case YP_NODE_INTEGER_LITERAL:
      yp_node_free(parser, node);
      break;
    case YP_NODE_VARIABLE_REFERENCE:
      yp_node_dealloc(parser, node->as.variable_reference.value);
      yp_node_free(parser, node);
      break;
  }
}
