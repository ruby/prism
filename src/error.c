#include "error.h"

// Append an error to the given list of errors.
void
yp_error_list_append(yp_list_t *list, const char *message, uint32_t position) {
  yp_error_t *error = (yp_error_t *) malloc(sizeof(yp_error_t));
  *error = (yp_error_t) { .node.start = position, .node.end = position };

  yp_string_constant_init(&error->message, message, strlen(message));
  yp_list_append(list, (yp_list_node_t *) error);
}

// Deallocate the internal state of the given error list.
void
yp_error_list_free(yp_list_t *list) {
  yp_list_node_t *node = list->head;
  yp_list_node_t *next;

  while (node != NULL) {
    next = node->next;
    yp_string_free(&((yp_error_t *) node)->message);
    free(node);
    node = next;
  }
}
