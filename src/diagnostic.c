#include "yarp/diagnostic.h"

// Append an error to the given list of diagnostic.
void
yp_diagnostic_list_append(yp_list_t *list, const char *start, const char *end, const char *message) {
  yp_diagnostic_t *diagnostic = (yp_diagnostic_t *) malloc(sizeof(yp_diagnostic_t));
  yp_string_t *message_string = yp_string_alloc();
  yp_string_constant_init(message_string, message, strlen(message));
  *diagnostic = (yp_diagnostic_t) {
    .start = start,
    .end = end,
    .message = message_string,
  };
  yp_list_append(list, (yp_list_node_t *) diagnostic);
}

// Deallocate the internal state of the given diagnostic list.
void
yp_diagnostic_list_free(yp_list_t *list) {
  yp_list_node_t *node, *next;

  for (node = list->head; node != NULL; node = next) {
    next = node->next;

    yp_diagnostic_t *diagnostic = (yp_diagnostic_t *) node;
    yp_string_free(diagnostic->message);
    free(diagnostic);
  }
}
