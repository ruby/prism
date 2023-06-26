#ifndef YARP_MEMSIZE_H
#define YARP_MEMSIZE_H

#include "yarp/defines.h"
#include "yarp/ast.h"

#include <stdint.h>

// This struct stores the information gathered by the yp_node_memsize function.
// It contains both the memory footprint and additionally metadata about the
// shape of the tree.
typedef struct {
    size_t memsize;
    size_t node_count;
} yp_memsize_t;

// Calculates the memory footprint of a given node.
YP_EXPORTED_FUNCTION void yp_node_memsize(yp_node_t *node, yp_memsize_t *memsize);

#endif
