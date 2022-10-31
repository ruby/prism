#include "error.h"

static yp_error_t *
yp_error_alloc(void) {
  return (yp_error_t *) malloc(sizeof(yp_error_t));
}

static void
yp_error_init(yp_error_t *error, const char *source, uint32_t position) {
  *error = (yp_error_t) { .location = { .start = position, .end = position } };
  yp_string_constant_init(&error->message, source, strlen(source));
}

// Allocate a new list of errors.
yp_error_list_t *
yp_error_list_alloc(void) {
  return (yp_error_list_t *) malloc(sizeof(yp_error_list_t));
}

// Initializes a list of errors.
void
yp_error_list_init(yp_error_list_t *error_list) {
  *error_list = (yp_error_list_t) { .head = NULL, .tail = NULL };
}

// Append an error to the given list of errors.
void
yp_error_list_append(yp_error_list_t *error_list, const char *message, uint32_t position) {
  yp_error_t *error = yp_error_alloc();
  yp_error_init(error, message, position);

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
yp_error_list_free(yp_error_list_t *error_list) {
  yp_error_t *previous, *current;

  for (current = error_list->head; current != NULL;) {
    previous = current;
    current = current->next;
    yp_string_free(&previous->message);
    free(previous);
  }
}
