#ifndef YARP_ENCODING_H
#define YARP_ENCODING_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

size_t
yp_encoding_ascii_alpha_char(const char *c);

size_t
yp_encoding_ascii_alnum_char(const char *c);

size_t
yp_encoding_iso_8859_9_alpha_char(const char *c);

size_t
yp_encoding_iso_8859_9_alnum_char(const char *c);

size_t
yp_encoding_utf_8_alpha_char(const char *c);

size_t
yp_encoding_utf_8_alnum_char(const char *c);

#endif
