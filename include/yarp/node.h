#ifndef YARP_NODE_H
#define YARP_NODE_H

#include "yarp/defines.h"
#include "yarp/parser.h"

// An empty list of locations. Used in initialization functions.
#define YP_EMPTY_LOCATION_LIST ((yp_location_list_t) { .locations = NULL, .size = 0, .capacity = 0 })

// Append a token to the given list.
void yp_location_list_append(yp_location_list_t *list, const yp_token_t *token);

// An empty list of nodes. Used in initialization functions.
#define YP_EMPTY_NODE_LIST ((yp_node_list_t) { .nodes = NULL, .size = 0, .capacity = 0 })

// Append a new node onto the end of the node list.
void yp_node_list_append(yp_node_list_t *list, yp_node_t *node);

// Deallocate a node and all of its children.
YP_EXPORTED_FUNCTION void yp_node_destroy(yp_parser_t *parser, struct yp_node *node);

#endif // YARP_NODE_H
