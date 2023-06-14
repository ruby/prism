#ifndef YARP_ALLOCATOR_H
#define YARP_ALLOCATOR_H

#include <stdlib.h>

typedef struct {
    void *memory;
    void *current;

    size_t size;
    size_t capacity;
} yp_allocator_t;

#endif
