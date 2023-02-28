#include "yp_encoding.h"

__attribute__((__visibility__("default"))) extern size_t
yp_encoding_iso_8859_9_alpha_char(const char *c) {
  const unsigned char v = *c;

  return (
    (v >= 0x41 && v <= 0x5A) ||
    (v >= 0x61 && v <= 0x7A) ||
    (v == 0xAA) ||
    (v == 0xB5) ||
    (v == 0xBA) ||
    (v >= 0xC0 && v <= 0xD6) ||
    (v >= 0xD8 && v <= 0xF6) ||
    (v >= 0xF8 && v <= 0xFF)
  );
}

__attribute__((__visibility__("default"))) extern size_t
yp_encoding_iso_8859_9_alnum_char(const char *c) {
  const unsigned char v = *c;

  return ((v >= 0x30 && v <= 0x39) || yp_encoding_iso_8859_9_alpha_char(c));
}
