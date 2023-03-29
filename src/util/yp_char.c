#include "yarp/util/yp_char.h"

bool
char_is_binary_number(const char c) {
  return c == '0' || c == '1';
}

bool
char_is_octal_number(const char c) {
  return c >= '0' && c <= '7';
}

bool
char_is_decimal_number(const char c) {
  return c >= '0' && c <= '9';
}

bool
char_is_hexadecimal_number(const char c) {
  return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}

bool
char_is_non_newline_whitespace(const char c) {
  return c == ' ' || c == '\t' || c == '\f' || c == '\r' || c == '\v';
}

bool
char_is_whitespace(const char c) {
  return char_is_non_newline_whitespace(c) || c == '\n';
}
