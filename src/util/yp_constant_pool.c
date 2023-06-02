#include "yarp/util/yp_constant_pool.h"

// A relatively simple hash function (djb2) that is used to hash strings. We are
// optimizing here for simplicity and speed.
static inline size_t
yp_constant_pool_hash(const char *start, size_t length) {
    // This is a prime number used as the initial value for the hash function.
    size_t value = 5381;

    for (size_t index = 0; index < length; index++) {
        value = ((value << 5) + value) + ((unsigned char) start[index]);
    }

    return value;
}

// Resize a constant pool to a given capacity.
static inline bool
yp_constant_pool_resize(yp_constant_pool_t *constant_pool) {
    size_t next_capacity = constant_pool->capacity * 2;
    yp_constant_t *next_constants = calloc(next_capacity, sizeof(yp_constant_t));
    if (next_constants == NULL) return false;

    // For each constant in the current constant pool, rehash the content, find
    // the index in the next constant pool, and insert it.
    for (size_t index = 0; index < constant_pool->capacity; index++) {
        yp_constant_t *constant = &constant_pool->constants[index];

        // If an id is set on this constant, then we know we have content here.
        // In this case we need to insert it into the next constant pool.
        if (constant->id != 0) {
            size_t next_index = constant->hash % next_capacity;

            // This implements linear scanning to find the next available slot
            // in case this index is already taken. We don't need to bother
            // comparing the values since we know that the hash is unique.
            while (next_constants[next_index].id != 0) {
                next_index = (next_index + 1) % next_capacity;
            }

            // Here we copy over the entire constant, which includes the id so
            // that they are consistent between resizes.
            next_constants[next_index] = *constant;
        }
    }

    free(constant_pool->constants);
    constant_pool->constants = next_constants;
    constant_pool->capacity = next_capacity;
    return true;
}

// Initialize a new constant pool with a given capacity.
bool
yp_constant_pool_init(yp_constant_pool_t *constant_pool, size_t capacity) {
    constant_pool->constants = calloc(capacity, sizeof(yp_constant_t));
    if (constant_pool->constants == NULL) return false;

    constant_pool->size = 0;
    constant_pool->capacity = capacity;
    return true;
}

// Insert a constant into a constant pool. Returns the id of the constant, or 0
// if any potential calls to resize fail.
yp_constant_id_t
yp_constant_pool_insert(yp_constant_pool_t *constant_pool, const char *start, size_t length) {
    if (constant_pool->size >= constant_pool->capacity * 0.75) {
        if (!yp_constant_pool_resize(constant_pool)) return 0;
    }

    size_t hash = yp_constant_pool_hash(start, length);
    size_t index = hash % constant_pool->capacity;
    yp_constant_t *constant;

    while (constant = &constant_pool->constants[index], constant->id != 0) {
        // If there is a collision, then we need to check if the content is the
        // same as the content we are trying to insert. If it is, then we can
        // return the id of the existing constant.
        if ((constant->length == length) && strncmp(constant->start, start, length) == 0) {
            return constant_pool->constants[index].id;
        }

        index = (index + 1) % constant_pool->capacity;
    }

    yp_constant_id_t id = ++constant_pool->size;
    constant_pool->constants[index] = (yp_constant_t) {
        .id = id,
        .start = start,
        .length = length,
        .hash = hash
    };

    return id;
}

// Free the memory associated with a constant pool.
void
yp_constant_pool_free(yp_constant_pool_t *constant_pool) {
    free(constant_pool->constants);
}
