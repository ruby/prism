#ifndef YARP_ALLOC_H
#define YARP_ALLOC_H

#include "yarp/defines.h"
#include <stdlib.h>

typedef struct yp_memory_pool {
    size_t capacity;
    size_t size;
    char *memory;
    struct yp_memory_pool *prev;
} yp_memory_pool_t;

typedef struct yp_allocator {
    size_t pool_count;
    yp_memory_pool_t *pool;

    yp_memory_pool_t *large_pool;
} yp_allocator_t;

void *
yp_malloc(yp_allocator_t *allocator, size_t size);

void *
yp_calloc(yp_allocator_t *allocator, size_t num, size_t size);

void
yp_free(yp_allocator_t *allocator, void *ptr);

void
yp_allocator_init(yp_allocator_t *allocator, size_t size);

void
yp_allocator_free(yp_allocator_t *allocator);

#endif // YARP_ALLOC_H
