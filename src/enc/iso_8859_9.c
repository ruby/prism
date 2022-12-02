#include "yp_encoding.h"

size_t
yp_encoding_iso_8859_9_alpha_char(const char *c) {
  const unsigned char *uc = (const unsigned char *) c;

  return (
    (*uc >= 0x41 && *uc <= 0x5A) ||
    (*uc >= 0x61 && *uc <= 0x7A) ||
    (*uc == 0xAA) ||
    (*uc == 0xB5) ||
    (*uc == 0xBA) ||
    (*uc >= 0xC0 && *uc <= 0xD6) ||
    (*uc >= 0xD8 && *uc <= 0xF6) ||
    (*uc >= 0xF8 && *uc <= 0xFF)
  );
}

size_t
yp_encoding_iso_8859_9_alnum_char(const char *c) {
  const unsigned char *uc = (const unsigned char *) c;

  return ((*uc >= 0x30 && *uc <= 0x39) || yp_encoding_iso_8859_9_alpha_char(c));
}
