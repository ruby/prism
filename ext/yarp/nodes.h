#ifndef YARP_NODES_H
#define YARP_NODES_H

#include <ruby.h>
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
  YP_NODE_PROGRAM,
  YP_NODE_STATEMENTS,
  YP_NODE_VARIABLE_REFERENCE,
} yp_node_type_t;

struct yp_node_list;

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

    // Program
    struct {
      struct yp_node *statements;
    } program;

    // Statements
    struct {
      struct yp_node_list *body;
    } statements;

    // VariableReference
    struct {
      struct yp_node *value;
    } variable_reference;
  } as;
} yp_node_t;

typedef struct yp_node_list {
  yp_node_t *nodes;
  size_t size;
  size_t capacity;
} yp_node_list_t;

// Append a new node onto the end of the node list.
void
yp_node_list_append(yp_parser_t *parser, yp_node_list_t *list, yp_node_t *node);

// Allocate a new Assignment node.
yp_node_t *
yp_node_alloc_assignment(yp_parser_t *parser, yp_node_t *target, yp_token_t *operator, yp_node_t *value);

// Allocate a new Binary node.
yp_node_t *
yp_node_alloc_binary(yp_parser_t *parser, yp_node_t *left, yp_token_t *operator, yp_node_t *right);

// Allocate a new FloatLiteral node.
yp_node_t *
yp_node_alloc_float_literal(yp_parser_t *parser, yp_token_t *value);

// Allocate a new Identifier node.
yp_node_t *
yp_node_alloc_identifier(yp_parser_t *parser, yp_token_t *value);

// Allocate a new IntegerLiteral node.
yp_node_t *
yp_node_alloc_integer_literal(yp_parser_t *parser, yp_token_t *value);

// Allocate a new Program node.
yp_node_t *
yp_node_alloc_program(yp_parser_t *parser, yp_node_t *statements);

// Allocate a new Statements node.
yp_node_t *
yp_node_alloc_statements(yp_parser_t *parser);

// Allocate a new VariableReference node.
yp_node_t *
yp_node_alloc_variable_reference(yp_parser_t *parser, yp_node_t *value);

void
yp_node_dealloc(yp_parser_t *parser, yp_node_t *node);

void
Init_yarp_nodes(void);

#endif
