#ifndef YARP_STRING_H
#define YARP_STRING_H

#include <stdbool.h>
#include <stddef.h>

typedef struct {
  enum {
    STRING_SHARED,
    STRING_OWNED,
  } type;

  union {
    struct {
      const char *start;
      const char *end;
    } shared;

    struct {
      char *ptr;
      size_t length;
    } owned;
  } as;
} yp_string_t;

// Constructs shared string that is based on initial input
yp_string_t
new_string_shared(const char *start, const char *end);

// Constructs owned string that contains owned value
yp_string_t
new_string_owned(char *ptr, size_t length);

// Returns true if string is shared
bool
is_string_shared(const yp_string_t *string);

// Returns true if string is owned
bool
is_string_owned(const yp_string_t *string);

// Returns length of the string
size_t
string_length(const yp_string_t *string);

// Returns read-only pointer of the string
const char *
string_ptr(const yp_string_t *string);

// Destructor of a string, de-allocates internal state of the string
// if needed (i.e. if string is owned)
void
string_drop(yp_string_t *string);

#endif // YARP_STRING_H
