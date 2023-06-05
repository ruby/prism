// The constant pool is a data structure that stores a set of strings. Each
// string is assigned a unique id, which can be used to compare strings for
// equality. This comparison ends up being much faster than strcmp, since it
// only requires a single integer comparison.

#ifndef YP_CONSTANT_POOL_H
#define YP_CONSTANT_POOL_H

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

typedef unsigned long yp_constant_id_t;

typedef struct {
    yp_constant_id_t id;
    const char *start;
    size_t length;
    size_t hash;
} yp_constant_t;

typedef struct {
    yp_constant_t *constants;
    size_t size;
    size_t capacity;
} yp_constant_pool_t;

// Initialize a new constant pool with a given capacity.
bool yp_constant_pool_init(yp_constant_pool_t *constant_pool, size_t capacity);

// Insert a constant into a constant pool. Returns the id of the constant, or 0
// if any potential calls to resize fail.
yp_constant_id_t yp_constant_pool_insert(yp_constant_pool_t *constant_pool, const char *start, size_t length);

// Free the memory associated with a constant pool.
void yp_constant_pool_free(yp_constant_pool_t *constant_pool);

#endif
