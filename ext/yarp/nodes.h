#ifndef YARP_NODES_H
#define YARP_NODES_H

#include <stdlib.h>
#include <stdint.h>
#include "parser.h"

typedef struct {
  uint64_t start;
  uint64_t end;
} yp_location_t;

typedef enum {
  YP_NODE_ASSIGNMENT,
  YP_NODE_BINARY,
  YP_NODE_FLOAT_LITERAL,
  YP_NODE_IDENTIFIER,
  YP_NODE_INTEGER_LITERAL,
  YP_NODE_VARIABLE_REFERENCE,
} yp_node_type_t;

// This is the overall tagged union representing a node in the syntax tree.
typedef struct yp_node {
  // This represents the type of the node. It somewhat maps to the nodes that
  // existed in the original grammar and ripper, but it's not a 1:1 mapping.
  yp_node_type_t type;

  // This is the location of the node in the source. It's a range of bytes
  // containing a start and an end.
  yp_location_t location;

  // Every entry in this union is a different kind of node in the tree. For
  // the most part they only contain one or two child nodes, except for the
  // more complicated nodes like params. There may be an opportunity for
  // optimization here by combining node types that share the same shape, but
  // it might not end up mattering in the final compiled code.
  union {
    // Assignment
    struct {
      struct yp_node *target;
      yp_token_t operator;
      struct yp_node *value;
    } assignment;

    // Binary
    struct {
      struct yp_node *left;
      yp_token_t operator;
      struct yp_node *right;
    } binary;

    // FloatLiteral
    struct {
      yp_token_t value;
    } float_literal;

    // Identifier
    struct {
      yp_token_t value;
    } identifier;

    // IntegerLiteral
    struct {
      yp_token_t value;
    } integer_literal;

    // VariableReference
    struct {
      struct yp_node *value;
    } variable_reference;
  } as;
} yp_node_t;

yp_node_t *
yp_node_alloc_assignment(yp_parser_t *parser, yp_node_t *target, yp_token_t *operator, yp_node_t *value);

yp_node_t *
yp_node_alloc_binary(yp_parser_t *parser, yp_node_t *left, yp_token_t *operator, yp_node_t *right);

yp_node_t *
yp_node_alloc_float_literal(yp_parser_t *parser, yp_token_t *value);

yp_node_t *
yp_node_alloc_identifier(yp_parser_t *parser, yp_token_t *value);

yp_node_t *
yp_node_alloc_integer_literal(yp_parser_t *parser, yp_token_t *value);

yp_node_t *
yp_node_alloc_variable_reference(yp_parser_t *parser, yp_node_t *value);

void
yp_node_dealloc(yp_parser_t *parser, yp_node_t *node);

#endif
