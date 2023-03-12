#include "yp_strspn.h"

#define YP_STRSPN_BIT_WHITESPACE (1 << 0)
#define YP_STRSPN_BIT_INLINE_WHITESPACE (1 << 1)
#define YP_STRSPN_BIT_DECIMAL_DIGIT (1 << 2)
#define YP_STRSPN_BIT_HEXIDECIMAL_DIGIT (1 << 3)
#define YP_STRSPN_BIT_BINARY_NUMBER (1 << 4)
#define YP_STRSPN_BIT_OCTAL_NUMBER (1 << 5)
#define YP_STRSPN_BIT_DECIMAL_NUMBER (1 << 6)
#define YP_STRSPN_BIT_HEXIDECIMAL_NUMBER (1 << 7)

const unsigned char yp_strspn_table[128] = {
  //       0           1           2           3           4           5           6           7           8           9           A           B           C           D           E           F
  0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000011, 0b00000001, 0b00000011, 0b00000011, 0b00000011, 0b00000000, 0b00000000, // 0x
  0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, // 1x
  0b00000011, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, // 2x
  0b11111100, 0b11111100, 0b11101100, 0b11101100, 0b11101100, 0b11101100, 0b11101100, 0b11101100, 0b11001100, 0b11001100, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, // 3x
  0b00000000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, // 4x
  0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b11110000, // 5x
  0b00000000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, // 6x
  0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, // 7x
};

// Returns the number of characters at the start of the string string that are
// whitespace. Disallows searching past the given maximum number of characters.
size_t
yp_strspn_whitespace(const char *string, size_t maximum) {
  size_t size = 0;
  while (size < maximum && (yp_strspn_table[(unsigned char) string[size]] & YP_STRSPN_BIT_WHITESPACE)) size++;
  return size;
}

// Returns the number of characters at the start of the string string that are
// whitespace excluding newline characters. Disallows searching past the given
// maximum number of characters.
size_t
yp_strspn_inline_whitespace(const char *string, size_t maximum) {
  size_t size = 0;
  while (size < maximum && (yp_strspn_table[(unsigned char) string[size]] & YP_STRSPN_BIT_INLINE_WHITESPACE)) size++;
  return size;
}

// Returns the number of characters at the start of the string string that are
// decimal digits. Disallows searching past the given maximum number of
// characters.
size_t
yp_strspn_decimal_digit(const char *string, size_t maximum) {
  size_t size = 0;
  while (size < maximum && (yp_strspn_table[(unsigned char) string[size]] & YP_STRSPN_BIT_DECIMAL_DIGIT)) size++;
  return size;
}

// Returns the number of characters at the start of the string string that are
// hexidecimal digits. Disallows searching past the given maximum number of
// characters.
size_t
yp_strspn_hexidecimal_digit(const char *string, size_t maximum) {
  size_t size = 0;
  while (size < maximum && (yp_strspn_table[(unsigned char) string[size]] & YP_STRSPN_BIT_HEXIDECIMAL_DIGIT)) size++;
  return size;
}

// Returns the number of characters at the start of the string string that are
// binary digits or underscores. Disallows searching past the given maximum
// number of characters.
size_t
yp_strspn_binary_number(const char *string, size_t maximum) {
  size_t size = 0;
  while (size < maximum && (yp_strspn_table[(unsigned char) string[size]] & YP_STRSPN_BIT_BINARY_NUMBER)) size++;
  return size;
}

// Returns the number of characters at the start of the string string that are
// octal digits or underscores. Disallows searching past the given maximum
// number of characters.
size_t
yp_strspn_octal_number(const char *string, size_t maximum) {
  size_t size = 0;
  while (size < maximum && (yp_strspn_table[(unsigned char) string[size]] & YP_STRSPN_BIT_OCTAL_NUMBER)) size++;
  return size;
}

// Returns the number of characters at the start of the string string that are
// decimal digits or underscores. Disallows searching past the given maximum
// number of characters.
size_t
yp_strspn_decimal_number(const char *string, size_t maximum) {
  size_t size = 0;
  while (size < maximum && (yp_strspn_table[(unsigned char) string[size]] & YP_STRSPN_BIT_DECIMAL_NUMBER)) size++;
  return size;
}

// Returns the number of characters at the start of the string string that are
// hexidecimal digits or underscores. Disallows searching past the given maximum
// number of characters.
size_t
yp_strspn_hexidecimal_number(const char *string, size_t maximum) {
  size_t size = 0;
  while (size < maximum && (yp_strspn_table[(unsigned char) string[size]] & YP_STRSPN_BIT_HEXIDECIMAL_NUMBER)) size++;
  return size;
}

#undef YP_STRSPN_BIT_WHITESPACE
#undef YP_STRSPN_BIT_INLINE_WHITESPACE
#undef YP_STRSPN_BIT_DECIMAL_DIGIT
#undef YP_STRSPN_BIT_HEXIDECIMAL_DIGIT
#undef YP_STRSPN_BIT_BINARY_NUMBER
#undef YP_STRSPN_BIT_OCTAL_NUMBER
#undef YP_STRSPN_BIT_DECIMAL_NUMBER
#undef YP_STRSPN_BIT_HEXIDECIMAL_NUMBER
