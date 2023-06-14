#ifndef YARP_NODE_H
#define YARP_NODE_H

#include "yarp/defines.h"

#include "yarp.h"
#include "yarp/parser.h"

// Append a token to the given list.
void yp_location_list_append(yp_location_list_t *list, const yp_token_t *token);

// Initiailize a list of nodes.
void yp_node_list_init(yp_node_list_t *node_list);

// Append a new node onto the end of the node list.
void yp_node_list_append(yp_node_list_t *list, yp_node_t *node);

// Clear the node but preserves the location.
void yp_node_clear(yp_node_t *node);

#define YP_EMPTY_NODE_LIST { .nodes = NULL, .size = 0, .capacity = 0 }
#define YP_EMPTY_LOCATION_LIST { .locations = NULL, .size = 0, .capacity = 0 }

#endif // YARP_NODE_H
