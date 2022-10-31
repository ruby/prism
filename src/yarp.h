#ifndef YARP_H
#define YARP_H

#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "util/yp_buffer.h"
#include "ast.h"
#include "error.h"
#include "parser.h"
#include "node.h"

#define YP_VERSION_MAJOR 0
#define YP_VERSION_MINOR 2
#define YP_VERSION_PATCH 0

void
yp_serialize_node(yp_parser_t *parser, yp_node_t *node, yp_buffer_t *buffer);

void
yp_print_node(yp_parser_t *parser, yp_node_t *node);

// Returns the YARP version and notably the serialization format
__attribute__((__visibility__("default"))) extern char*
yp_version(void);

// Initialize a parser with the given start and end pointers.
__attribute__((__visibility__("default"))) extern void
yp_parser_init(yp_parser_t *parser, const char *source, off_t size);

// Free any memory associated with the given parser.
__attribute__((__visibility__("default"))) extern void
yp_parser_free(yp_parser_t *parser);

// Get the next token type and set its value on the current pointer.
__attribute__((__visibility__("default"))) extern void
yp_lex_token(yp_parser_t *parser);

// Parse the Ruby source associated with the given parser and return the tree.
__attribute__((__visibility__("default"))) extern yp_node_t *
yp_parse(yp_parser_t *parser);

// Deallocate a node and all of its children.
__attribute__((__visibility__("default"))) extern void
yp_node_destroy(yp_parser_t *parser, struct yp_node *node);

// Pretty-prints the AST represented by the given node to the given buffer.
__attribute__((__visibility__("default"))) extern void
yp_prettyprint(yp_parser_t *parser, yp_node_t *node, yp_buffer_t *buffer);

// Serialize the AST represented by the given node to the given buffer.
__attribute__((__visibility__("default"))) extern void
yp_serialize(yp_parser_t *parser, yp_node_t *node, yp_buffer_t *buffer);

__attribute__((__visibility__("default"))) extern const char *
yp_token_type_to_str(yp_token_type_t token_type);

__attribute__((__visibility__("default"))) extern yp_token_type_t
yp_token_type_from_str(const char *str);

#endif
