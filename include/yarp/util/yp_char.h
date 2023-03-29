#ifndef YARP_CHAR_H
#define YARP_CHAR_H

#include <stdbool.h>

bool
char_is_binary_number(const char c);

bool
char_is_octal_number(const char c);

bool
char_is_decimal_number(const char c);

bool
char_is_hexadecimal_number(const char c);

bool
char_is_non_newline_whitespace(const char c);

bool
char_is_whitespace(const char c);

#endif
