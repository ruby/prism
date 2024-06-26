#include "prism/allocator.h"

#define PM_ALLOCATOR_CAPACITY_DEFAULT 4096

/**
 * Initialize an allocator with the given capacity.
 */
void
pm_allocator_init(pm_allocator_t *allocator, size_t capacity) {
    char *memory = malloc(capacity);
    if (memory == NULL) {
        fprintf(stderr, "[pm_allocator_init] failed to allocate memory\n");
        abort();
    }

    *allocator = (pm_allocator_t) {
        .next = NULL,
        .start = memory,
        .current = memory,
        .end = memory + capacity
    };
}

/**
 * Allocate memory from the given allocator.
 */
void *
pm_allocator_alloc(pm_allocator_t *allocator, size_t size, size_t alignment) {
    assert(size > 0);

    char *result = allocator->current;
    uintptr_t delta = 0;
    uintptr_t current = (uintptr_t) allocator->current;
    if (current % alignment != 0) {
        delta = alignment - (current % alignment);
    }
    result += delta;

    char *next = result + size;

    if (next >= allocator->end) {
        size_t next_capacity = PM_ALLOCATOR_CAPACITY_DEFAULT;

        // In case the requested size is larger than our default capacity, scale
        // up just this node in the linked list to fit the allocation.
        if (size > next_capacity) next_capacity = size;

        char *next_allocator_memory = malloc(sizeof(pm_allocator_t) + next_capacity);
        if (next_allocator_memory == NULL) {
            fprintf(stderr, "[pm_allocator_alloc] failed to allocate memory\n");
            abort();
        }

        pm_allocator_t *next_allocator = (pm_allocator_t *) next_allocator_memory;
        char *start = next_allocator_memory + sizeof(pm_allocator_t);

        // Assume the alignment is correct because malloc should give us back
        // the most relaxed alignment possible.
        assert(((uintptr_t) start) % alignment == 0);

        *next_allocator = (pm_allocator_t) {
            .next = NULL,
            .start = start,
            .current = NULL, // set at the end
            .end = start + next_capacity
        };

        allocator->next = next_allocator;
        allocator = next_allocator;

        result = allocator->start;
        next = next_allocator->current + size;
    }

    allocator->current = next;
    return result;
}

/**
 * Allocate memory from the given allocator and zero out the memory.
 */
void *
pm_allocator_calloc(pm_allocator_t *allocator, size_t count, size_t size, size_t alignment) {
    assert(size > 0);

    size_t product = count * size;
    assert(product / size == count);

    void *memory = pm_allocator_alloc(allocator, product, alignment);
    memset(memory, 0, product);

    return memory;
}

/**
 * Frees the internal memory associated with the allocator.
 */
void pm_allocator_free(pm_allocator_t *allocator) {
    for (pm_allocator_t *current = allocator; current != NULL;) {
        if (current->end != current->start) free(current->start);

        pm_allocator_t *previous = current;
        current = current->next;

        if (previous != allocator) free(previous);
    }
}
