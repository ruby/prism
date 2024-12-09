#include "prism/allocator.h"

#define PM_ALLOCATOR_CAPACITY_DEFAULT 4096

/**
 * Initialize an allocator with the given capacity.
 */
void
pm_allocator_init(pm_allocator_t *allocator, size_t capacity) {
    char *memory = xmalloc(capacity);
    if (memory == NULL) {
        fprintf(stderr, "[pm_allocator_init] failed to allocate memory\n");
        abort();
    }

    *allocator = (pm_allocator_t) {
        .head = {
            .next = NULL,
            .start = memory,
            .current = memory,
            .end = memory + capacity
        },
        .tail = &allocator->head
    };
}

/**
 * Allocate memory from the given allocator.
 */
void *
pm_allocator_arena_alloc(pm_allocator_t *allocator, size_t size, size_t alignment) {
    assert(size > 0);

    char *result = allocator->tail->current;
    uintptr_t delta = 0;
    uintptr_t current = (uintptr_t) allocator->tail->current;
    if (current % alignment != 0) {
        delta = alignment - (current % alignment);
    }
    result += delta;

    char *next = result + size;

    if (next >= allocator->tail->end) {
        size_t next_capacity = PM_ALLOCATOR_CAPACITY_DEFAULT;

        // In case the requested size is larger than our default capacity, scale
        // up just this node in the linked list to fit the allocation.
        if (size > next_capacity) next_capacity = size;

        char *memory = xmalloc(sizeof(pm_allocator_page_t) + next_capacity);
        if (memory == NULL) {
            fprintf(stderr, "[pm_allocator_arena_alloc] failed to allocate memory\n");
            abort();
        }

        pm_allocator_page_t *next_allocator_page = (pm_allocator_page_t *) memory;
        char *start = memory + sizeof(pm_allocator_page_t);

        // Assume the alignment is correct because malloc should give us back
        // the most relaxed alignment possible.
        assert(((uintptr_t) start) % alignment == 0);

        *next_allocator_page = (pm_allocator_page_t) {
            .next = NULL,
            .start = start,
            .current = NULL, // set at the end
            .end = start + next_capacity
        };

        allocator->tail->next = next_allocator_page;
        allocator->tail = next_allocator_page;

        result = allocator->tail->start;
        next = result + size;
    }

    allocator->tail->current = next;
    return result;
}

/**
 * Allocate memory from the given allocator and zero out the memory.
 */
void *
pm_allocator_arena_calloc(pm_allocator_t *allocator, size_t count, size_t size, size_t alignment) {
    assert(size > 0);

    size_t product = count * size;
    assert(product / size == count);

    void *memory = pm_allocator_arena_alloc(allocator, product, alignment);
    memset(memory, 0, product);

    return memory;
}

/**
 * Frees the internal memory associated with the allocator.
 */
void pm_allocator_free(pm_allocator_t *allocator) {
    bool top_level = true;

    for (pm_allocator_page_t *current = &allocator->head; current != NULL;) {
        pm_allocator_page_t *previous = current;
        current = current->next;

        // If the memory block is immediately after the allocation of the
        // allocator itself, then it came from pm_allocator_arena_alloc, so we
        // should free it. Otherwise we assume it was embedded into another
        // struct or allocated on the stack.
        if (top_level) {
            free(previous->start);
        } else {
            free(previous);
        }

        top_level = false;
    }
}
