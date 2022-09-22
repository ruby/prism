#ifndef YARP_LOCATION_H
#define YARP_LOCATION_H

#include <stdint.h>

// This represents a range of bytes in the source string to which a node or
// token corresponds.
typedef struct {
  uint64_t start;
  uint64_t end;
} yp_location_t;

#endif // YARP_LOCATION_H
