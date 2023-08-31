#include "yarp/util/yp_alloc.h"

void *
yp_malloc(yp_allocator_t *allocator, size_t size) {
    (void)allocator;
    return malloc(size);
}

void *
yp_calloc(yp_allocator_t *allocator, size_t num, size_t size) {
    (void)allocator;
    return calloc(num, size);
}

void
yp_free(yp_allocator_t *allocator, void *ptr) {
    (void)allocator;
    free(ptr);
}

void
yp_allocator_init(yp_allocator_t *allocator, size_t capacity) {
    (void)capacity;
    allocator->pool_count = 0;
    allocator->pool = NULL;
    allocator->large_pool = NULL;
}

void
yp_allocator_free(yp_allocator_t *allocator) {
    // NO OP
    (void)allocator;
}
