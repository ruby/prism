#include "error.h"

static yp_error_t *
yp_error_create(const char *message, uint64_t position) {
  yp_error_t *error = malloc(sizeof(yp_error_t));

  size_t length = strlen(message);
  char *source = malloc(length);

  *error = (yp_error_t) {
    .location = { .start = position, .end = position },
    .message = {
      .type = YP_STRING_OWNED,
      .as.owned = { .source = source, .length = length }
    }
  };

  memcpy(source, message, length);
  return error;
}

// Initializes a list of errors.
void
yp_error_list_create(yp_error_list_t *error_list) {
  *error_list = (yp_error_list_t) { .head = NULL, .tail = NULL };
}

// Append an error to the given list of errors.
void
yp_error_list_append(yp_error_list_t *error_list, const char *message, uint64_t position) {
  yp_error_t *error = yp_error_create(message, position);

  if (error_list->head == NULL) {
    error_list->head = error;
    error_list->tail = error;
  } else {
    error_list->tail->next = error;
    error_list->tail = error;
  }
}

// Deallocate the internal state of the given error list.
void
yp_error_list_destroy(yp_error_list_t *error_list) {
  yp_error_t *previous, *current;

  for (current = error_list->head; current != NULL;) {
    previous = current;
    current = current->next;
    yp_string_destroy(&previous->message);
    free(previous);
  }
}
