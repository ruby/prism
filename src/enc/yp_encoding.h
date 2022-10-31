#ifndef YARP_ENCODING_H
#define YARP_ENCODING_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

typedef struct {
  size_t (*alpha_char)(const char *c);
  size_t (*alnum_char)(const char *c);
} yp_encoding_t;

size_t
yp_encoding_ascii_alpha_char(const char *c);

size_t
yp_encoding_ascii_alnum_char(const char *c);

size_t
yp_encoding_utf8_alpha_char(const char *c);

size_t
yp_encoding_utf8_alnum_char(const char *c);

static yp_encoding_t yp_encoding_ascii = {
  .alnum_char = yp_encoding_ascii_alnum_char,
  .alpha_char = yp_encoding_ascii_alpha_char
};

static yp_encoding_t yp_encoding_utf8 = {
  .alnum_char = yp_encoding_utf8_alnum_char,
  .alpha_char = yp_encoding_utf8_alpha_char
};

#endif
