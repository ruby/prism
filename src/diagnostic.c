#include "diagnostic.h"

// Append an error to the given list of diagnostic.
void
yp_diagnostic_list_append(yp_list_t *list, const char *message, uint32_t position) {
  yp_diagnostic_t *diagnostic = (yp_diagnostic_t *) malloc(sizeof(yp_diagnostic_t));
  *diagnostic = (yp_diagnostic_t) { .start = position, .end = position };

  yp_string_constant_init(&diagnostic->message, message, strlen(message));
  yp_list_append(list, (yp_list_node_t *) diagnostic);
}

// Deallocate the internal state of the given diagnostic list.
void
yp_diagnostic_list_free(yp_list_t *list) {
  yp_list_node_t *node = list->head;
  yp_list_node_t *next;

  while (node != NULL) {
    next = node->next;
    yp_string_free(&((yp_diagnostic_t *) node)->message);
    free(node);
    node = next;
  }
}
