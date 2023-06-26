#include "yarp/util/yp_newline_list.h"

// Initialize a new newline list with the given capacity. Returns true if the
// allocation of the offsets succeeds, otherwise returns false.
void
yp_newline_list_init(yp_newline_list_t *list, const char *start, size_t capacity) {
    list->offsets = (size_t *) malloc(sizeof(size_t) * capacity);
    if (list->offsets == NULL) return;

    list->start = start;

    // This is 1 instead of 0 because we want to include the first line of the
    // file as having offset 0, which is set because of calloc.
    list->size = 1;
    list->capacity = capacity;

    list->last_index = 0;
    list->last_offset = 0;
}

// Append a new offset to the newline list. Returns true if the reallocation of
// the offsets succeeds (if one was necessary), otherwise returns false.
void
yp_newline_list_append(yp_newline_list_t *list, const char *cursor) {
    assert(cursor >= list->start);

    if (list->size == list->capacity) {
        size_t next_capacity = list->capacity < 4 ? 4 : list->capacity * 3 / 2;
        size_t *next_offsets = (size_t *) realloc(list->offsets, next_capacity * sizeof(size_t));

        if (next_offsets == NULL) return;
        list->capacity = next_capacity;
        list->offsets = next_offsets;
    }

    list->offsets[list->size++] = (size_t) (cursor - list->start);
}

// Returns the line and column of the given offset, assuming we don't have any
// information about the previous index that we found.
static yp_line_column_t
yp_newline_list_line_column_search(yp_newline_list_t *list, size_t offset) {
    size_t left = 0;
    size_t right = list->size - 1;

    while (left <= right) {
        size_t mid = left + (right - left) / 2;

        if (list->offsets[mid] == offset) {
            return ((yp_line_column_t) { mid, 0 });
        }

        if (list->offsets[mid] < offset) {
            left = mid + 1;
        } else {
            right = mid - 1;
        }
    }

    return ((yp_line_column_t) { left - 1, offset - list->offsets[left - 1] });
}

// Returns the line and column of the given offset, assuming we know the last
// index that we found.
static yp_line_column_t
yp_newline_list_line_column_scan(yp_newline_list_t *list, size_t offset) {
    if (offset > list->last_offset) {
        size_t index = list->last_index;
        while (index < list->size && list->offsets[index] < offset) {
            index++;
        }

        if (index == list->size) {
            return ((yp_line_column_t) { index - 1, offset - list->offsets[index - 1] });
        }

        return ((yp_line_column_t) { index, 0 });
    } else {
        size_t index = list->last_index;
        while (index > 0 && list->offsets[index] > offset) {
            index--;
        }

        if (index == 0) {
            return ((yp_line_column_t) { 0, offset });
        }

        return ((yp_line_column_t) { index, offset - list->offsets[index - 1] });
    }
}

// Returns the line and column of the given offset. If the offset is not in the
// list, the line and column of the closest offset less than the given offset
// are returned.
yp_line_column_t
yp_newline_list_line_column(yp_newline_list_t *list, const char *cursor) {
    assert(cursor >= list->start);
    size_t offset = (size_t) (cursor - list->start);
    yp_line_column_t result;

    if (list->last_offset == 0) {
        result = yp_newline_list_line_column_search(list, offset);
    } else {
        result = yp_newline_list_line_column_scan(list, offset);
    }

    list->last_index = result.line;
    list->last_offset = offset;

    return result;
}

// Free the internal memory allocated for the newline list.
void
yp_newline_list_free(yp_newline_list_t *list) {
    free(list->offsets);
}
