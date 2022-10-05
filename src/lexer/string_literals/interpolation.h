#ifndef YARP_STRING_LITERALS_INTERPOLATION_H
#define YARP_STRING_LITERALS_INTERPOLATION_H

#include <stdbool.h>
#include <stddef.h>

typedef struct {
  size_t curly_level; // stores current level of curly braces to distinguish "%Q{{}}"
  bool active;
  bool supported;
} interpolation_t;

interpolation_t
yp_interpolation_unsupported();
interpolation_t
yp_interpolation_supported(size_t curly_level);

#endif // YARP_STRING_LITERALS_INTERPOLATION_H
