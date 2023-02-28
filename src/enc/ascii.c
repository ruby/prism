#include "yp_encoding.h"

__attribute__((__visibility__("default"))) extern size_t
yp_encoding_ascii_alpha_char(const char *c) {
  const unsigned char v = *c;

  if ((v >= 'a' && v <= 'z') || (v >= 'A' && v <= 'Z')) return 1;
  return 0;
}

__attribute__((__visibility__("default"))) extern size_t
yp_encoding_ascii_alnum_char(const char *c) {
  const unsigned char v = *c;

  if (yp_encoding_ascii_alpha_char(c) || (v >= '0' && v <= '9')) return 1;
  return 0;
}
