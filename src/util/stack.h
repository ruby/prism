#ifndef YARP_STACK_H
#define YARP_STACK_H

#include <stddef.h>
#include <stdlib.h>

#define STACK_DECL(stack_type, item_type, create_fn, destroy_fn, push_fn, pop_fn, last_fn, size_fn)                    \
  typedef struct {                                                                                                     \
    item_type *ptr;                                                                                                    \
    size_t size;                                                                                                       \
    size_t capacity;                                                                                                   \
  } stack_type;                                                                                                        \
  stack_type create_fn(size_t capacity);                                                                               \
  void destroy_fn(stack_type *stack);                                                                                  \
  void push_fn(stack_type *stack, item_type item);                                                                     \
  item_type pop_fn(stack_type *stack);                                                                                 \
  item_type *last_fn(stack_type *stack);                                                                               \
  size_t size_fn(const stack_type *stack);

#define STACK_IMPL(stack_type, item_type, create_fn, destroy_fn, push_fn, pop_fn, last_fn, size_fn)                    \
  stack_type create_fn(size_t capacity) {                                                                              \
    item_type *ptr = (item_type *) malloc(sizeof(item_type) * capacity);                                               \
    return (stack_type) { .ptr = ptr, .size = 0, .capacity = capacity };                                               \
  }                                                                                                                    \
  void destroy_fn(stack_type *stack) {                                                                                 \
    free(stack->ptr);                                                                                                  \
  }                                                                                                                    \
  void push_fn(stack_type *stack, item_type item) {                                                                    \
    if (stack->capacity == stack->size) {                                                                              \
      stack->capacity = stack->capacity * 2;                                                                           \
      stack->ptr = realloc(stack->ptr, sizeof(item_type) * stack->capacity);                                           \
    }                                                                                                                  \
    stack->ptr[stack->size] = item;                                                                                    \
    stack->size += 1;                                                                                                  \
  }                                                                                                                    \
  item_type pop_fn(stack_type *stack) {                                                                                \
    item_type last = stack->ptr[stack->size - 1];                                                                      \
    if (stack->size > 0) {                                                                                             \
      stack->size -= 1;                                                                                                \
    }                                                                                                                  \
    return last;                                                                                                       \
  }                                                                                                                    \
  item_type *last_fn(stack_type *stack) {                                                                              \
    if (stack->size > 0) {                                                                                             \
      return stack->ptr + stack->size - 1;                                                                             \
    } else {                                                                                                           \
      return NULL;                                                                                                     \
    }                                                                                                                  \
  }                                                                                                                    \
  size_t size_fn(const stack_type *stack) {                                                                            \
    return stack->size;                                                                                                \
  }

#endif // YARP_STACK_H
