# /**
 * @file allocator.h
 *
 * An arena allocator.
 */
#ifndef PRISM_ALLOCATOR_H
#define PRISM_ALLOCATOR_H

#include "prism/defines.h"
#include <assert.h>
#include <stdbool.h>
#include <stdlib.h>

typedef struct pm_allocator_page {
    struct pm_allocator_page *next;
    char *start;
    char *current;
    char *end;
} pm_allocator_page_t;

typedef struct pm_allocator {
    pm_allocator_page_t head;
    pm_allocator_page_t *tail;
} pm_allocator_t;

/**
 * Initialize an allocator with the given capacity.
 */
void pm_allocator_init(pm_allocator_t *allocator, size_t capacity);

/**
 * Retrieve a scratch allocator with the given capacity.
 */
pm_allocator_t pm_allocator_scratch(size_t capacity);

/**
 * Allocate memory from the given allocator.
 */
void * pm_allocator_arena_alloc(pm_allocator_t *allocator, size_t size, size_t alignment);

/**
 * Allocate memory from the given allocator and zero out the memory.
 */
void * pm_allocator_arena_calloc(pm_allocator_t *allocator, size_t count, size_t size, size_t alignment);

/**
 * Retrieve a pointer to the next slot that would be allocated.
 */
void * pm_allocator_current(pm_allocator_t *allocator);

/**
 * Reset the allocator back to the given slot.
 */
void pm_allocator_reset(pm_allocator_t *allocator, void *current);

/**
 * Frees the internal memory associated with the allocator.
 */
void pm_allocator_free(pm_allocator_t *allocator);

#endif
