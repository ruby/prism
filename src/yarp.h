#ifndef YARP_H
#define YARP_H

#include "buffer.h"
#include "node.h"
#include "token_type.h"
#include "location.h"
#include "parser.h"
#include "serialize.h"
#include "token.h"
#include <fcntl.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

#define YP_VERSION_MAJOR 0
#define YP_VERSION_MINOR 1
#define YP_VERSION_PATCH 0

// Initialize a parser with the given start and end pointers.
__attribute__ ((__visibility__("default"))) extern void
yp_parser_init(yp_parser_t *parser, const char *source, off_t size);

// Get the next token type and set its value on the current pointer.
__attribute__ ((__visibility__("default"))) extern void
yp_lex_token(yp_parser_t *parser);

// Parse the Ruby source associated with the given parser and return the tree.
__attribute__ ((__visibility__("default"))) extern yp_node_t *
yp_parse(yp_parser_t *parser);

// Deallocate a node and all of its children.
__attribute__ ((__visibility__("default"))) extern void
yp_node_dealloc(yp_parser_t *parser, struct yp_node *node);

// Serialize the AST represented by the given node to the given buffer.
__attribute__ ((__visibility__("default"))) extern void
yp_serialize(yp_parser_t *parser, yp_node_t *node, yp_buffer_t *buffer);

#endif
