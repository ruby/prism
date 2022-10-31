#ifndef YARP_LIST_H
#define YARP_LIST_H

#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

// This represents a node in the linked list.
typedef struct yp_list_node {
  uint32_t start;
  uint32_t end;
  struct yp_list_node *next;
} yp_list_node_t;

// This represents the overall linked list. It keeps a pointer to the head and
// tail so that iteration is easy and pushing new nodes is easy.
typedef struct {
  yp_list_node_t *head;
  yp_list_node_t *tail;
} yp_list_t;

// Allocate a new list.
yp_list_t *
yp_list_alloc(void);

// Initializes a new list.
void
yp_list_init(yp_list_t *list);

// Append a node to the given list.
void
yp_list_append(yp_list_t *list, yp_list_node_t *node);

// Deallocate the internal state of the given list.
void
yp_list_free(yp_list_t *list);

#endif
