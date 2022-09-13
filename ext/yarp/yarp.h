#ifndef YARP_H
#define YARP_H

#include <ruby.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include "nodes.h"

// Initialize a parser with the given start and end pointers.
void
yp_parser_init(yp_parser_t *parser, const char *source, off_t size, yp_error_handler_t *error_handler);

// Get the next token type and set its value on the current pointer.
void
yp_lex_token(yp_parser_t *parser);

// Parse the Ruby source associated with the given parser and return the tree.
yp_node_t *
yp_parse(yp_parser_t *parser);

#endif
