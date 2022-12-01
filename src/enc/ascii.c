#include "yp_encoding.h"

size_t
yp_encoding_ascii_char(const char *c) {
  const unsigned char *uc = (const unsigned char *) c;
  if (*uc < 128) return 1;
  return 0;
}

size_t
yp_encoding_ascii_alpha_char(const char *c) {
  if ((*c >= 'a' && *c <= 'z') || (*c >= 'A' && *c <= 'Z')) return 1;
  return 0;
}

size_t
yp_encoding_ascii_alnum_char(const char *c) {
  if (yp_encoding_ascii_alpha_char(c) || (*c >= '0' && *c <= '9')) return 1;
  return 0;
}
