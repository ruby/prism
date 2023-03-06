#include "yp_strspn.h"

const char yp_strspn_decimal_number_table[128] = {
  ['0'] = 1,
  ['1'] = 1,
  ['2'] = 1,
  ['3'] = 1,
  ['4'] = 1,
  ['5'] = 1,
  ['6'] = 1,
  ['7'] = 1,
  ['8'] = 1,
  ['9'] = 1,
  ['_'] = 1
};

const char yp_strspn_whitespace_table[128] = {
  [' '] = 1,
  ['\t'] = 1,
  ['\v'] = 1,
  ['\f'] = 1,
  ['\r'] = 1,
  ['\n'] = 1
};

// Returns the number of characters at the start of the string string that are
// decimal numbers or underscores. Disallows searching past the given maximum
// number of characters.
size_t
yp_strspn_decimal_number(const char *string, size_t maximum) {
  size_t size = 0;
  while (size < maximum && yp_strspn_decimal_number_table[(unsigned char) string[size]]) size++;
  return size;
}

// Returns the number of characters at the start of the string string that are
// whitespace excluding newline characters. Disallows searching past the given
// maximum number of characters.
size_t
yp_strspn_inline_whitespace(const char *string, size_t maximum) {
  size_t size = 0;
  while (size < maximum && string[size] != '\n' && yp_strspn_whitespace_table[(unsigned char) string[size]]) size++;
  return size;
}

// Returns the number of characters at the start of the string string that are
// whitespace. Disallows searching past the given maximum number of characters.
size_t
yp_strspn_whitespace(const char *string, size_t maximum) {
  size_t size = 0;
  while (size < maximum && yp_strspn_whitespace_table[(unsigned char) string[size]]) size++;
  return size;
}
