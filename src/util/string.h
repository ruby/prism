#ifndef YARP_STRING_H
#define YARP_STRING_H

#include <stddef.h>
#include <stdlib.h>

// This struct represents a string value.
typedef struct {
  enum { YP_STRING_SHARED, YP_STRING_OWNED, YP_STRING_CONSTANT } type;

  union {
    struct {
      const char *start;
      const char *end;
    } shared;

    struct {
      char *source;
      size_t length;
    } owned;

    struct {
      const char *source;
      size_t length;
    } constant;
  } as;
} yp_string_t;

// Constructs a shared string that is based on initial input.
yp_string_t *
yp_string_shared_create(const char *start, const char *end);

// Constructs an owned string that is responsible for freeing allocated memory.
yp_string_t *
yp_string_owned_create(char *source, size_t length);

// Constructs a constant string that doesn't own its memory source.
yp_string_t *
yp_string_constant_create(const char *source, size_t length);

// Returns the length associated with the string.
__attribute__ ((__visibility__("default"))) extern size_t
yp_string_length(const yp_string_t *string);

// Returns the start pointer associated with the string.
__attribute__ ((__visibility__("default"))) extern const char *
yp_string_source(const yp_string_t *string);

// Deallocates the internal state of the string if needed and the string itself.
void
yp_string_destroy(yp_string_t *string);

#endif // YARP_STRING_H
