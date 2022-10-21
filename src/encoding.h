#ifndef YARP_ENCODING_H
#define YARP_ENCODING_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

size_t yp_encoding_ascii_alpha_char(const char *c);
size_t yp_encoding_ascii_alnum_char(const char *c);
size_t yp_encoding_utf8_alpha_char(const char *c);
size_t yp_encoding_utf8_alnum_char(const char *c);

#endif
