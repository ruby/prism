#include "yarp/util/yp_list.h"

// Returns true if the given list is empty.
PRISM_EXPORTED_FUNCTION bool
yp_list_empty_p(yp_list_t *list) {
    return list->head == NULL;
}

// Returns the size of the list.
PRISM_EXPORTED_FUNCTION size_t
yp_list_size(yp_list_t *list) {
    return list->size;
}

// Append a node to the given list.
void
yp_list_append(yp_list_t *list, yp_list_node_t *node) {
    if (list->head == NULL) {
        list->head = node;
    } else {
        list->tail->next = node;
    }

    list->tail = node;
    list->size++;
}

// Deallocate the internal state of the given list.
PRISM_EXPORTED_FUNCTION void
yp_list_free(yp_list_t *list) {
    yp_list_node_t *node = list->head;
    yp_list_node_t *next;

    while (node != NULL) {
        next = node->next;
        free(node);
        node = next;
    }

    list->size = 0;
}
