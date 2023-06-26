#ifndef YARP_NODE_H
#define YARP_NODE_H

#include "yarp/defines.h"
#include "yarp/parser.h"

// Deallocate a node and all of its children.
YP_EXPORTED_FUNCTION void yp_node_destroy(yp_parser_t *parser, struct yp_node *node);

#endif
