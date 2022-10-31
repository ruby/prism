#include "yp_encoding.h"

size_t
yp_encoding_iso_8859_9_alpha_char(const char *c) {
  const unsigned char v = *c;

  return (
    (v >= 65 && v <= 90) ||
    (v >= 97 && v <= 122) ||
    (v == 170) ||
    (v == 181) ||
    (v == 186) ||
    (v >= 192 && v <= 214) ||
    (v >= 216 && v <= 246) ||
    (v >= 248 && v <= 255)
  );
}

size_t
yp_encoding_iso_8859_9_alnum_char(const char *c) {
  const unsigned char v = *c;

  return ((v >= 48 && v <= 57) || yp_encoding_iso_8859_9_alpha_char(c));
}
