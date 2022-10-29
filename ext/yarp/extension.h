#ifndef YARP_EXT_NODE_H
#define YARP_EXT_NODE_H

#include <ruby.h>
#include <yarp.h>

#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

VALUE
yp_token_new(yp_parser_t *parser, yp_token_t *token);

VALUE
yp_node_new(yp_parser_t *parser, yp_node_t *node);

#endif // YARP_EXT_NODE_H
