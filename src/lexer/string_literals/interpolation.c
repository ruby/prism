#include "interpolation.h"

interpolation_t
yp_interpolation_unsupported() {
  return (interpolation_t) { .curly_level = 0, .active = false, .supported = false };
}

interpolation_t
yp_interpolation_supported(size_t curly_level) {
  return (interpolation_t) { .curly_level = curly_level, .active = false, .supported = true };
}
