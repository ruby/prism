#include "yarp/util/yp_string_list.h"

// Initialize a yp_string_list_t with its default values.
void
yp_string_list_init(yp_string_list_t *string_list) {
    yp_string_t *strings = (yp_string_t *) malloc(sizeof(yp_string_t));

    if (strings == NULL) {
        *string_list = (yp_string_list_t) { .strings = NULL, .length = 0, .capacity = 0 };
    } else {
        *string_list = (yp_string_list_t) { .strings = strings, .length = 0, .capacity = 1 };
    }
}

// Append a yp_string_t to the given string list.
void
yp_string_list_append(yp_string_list_t *string_list, yp_string_t *string) {
    if (string_list->length >= string_list->capacity) {
        size_t next_capacity = string_list->capacity == 0 ? 1 : string_list->capacity * 2;
        yp_string_t *next_strings = (yp_string_t *) realloc(string_list->strings, sizeof(yp_string_t) * next_capacity);

        if (next_strings == NULL) return;
        string_list->capacity = next_capacity;
        string_list->strings = next_strings;
    }

    string_list->strings[string_list->length++] = *string;
}

// Free the memory associated with the string list.
void
yp_string_list_free(yp_string_list_t *string_list) {
    if (string_list->strings != NULL) {
        free(string_list->strings);
    }
}
