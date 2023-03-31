#include "yarp/util/yp_char.h"

#define YP_CHAR_BIT_WHITESPACE (1 << 0)
#define YP_CHAR_BIT_INLINE_WHITESPACE (1 << 1)
#define YP_CHAR_BIT_DECIMAL_DIGIT (1 << 2)
#define YP_CHAR_BIT_HEXIDECIMAL_DIGIT (1 << 3)
#define YP_CHAR_BIT_OCTAL_NUMBER (1 << 4)
#define YP_CHAR_BIT_DECIMAL_NUMBER (1 << 5)
#define YP_CHAR_BIT_HEXIDECIMAL_NUMBER (1 << 6)
#define YP_CHAR_BIT_REGEXP_OPTION (1 << 7)

const unsigned char yp_char_table[256] = {
  // 0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x01, 0x03, 0x03, 0x03, 0x00, 0x00, // 0x
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 1x
  0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 2x
  0x7c, 0x7c, 0x7c, 0x7c, 0x7c, 0x7c, 0x7c, 0x7c, 0x6c, 0x6c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 3x
  0x00, 0x48, 0x48, 0x48, 0x48, 0x48, 0x48, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 4x
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x70, // 5x
  0x00, 0x48, 0x48, 0x48, 0x48, 0xc8, 0x48, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x80, 0x80, 0x80, // 6x
  0x00, 0x00, 0x00, 0x80, 0x00, 0x80, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 7x
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 8x
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 9x
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // Ax
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // Bx
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // Cx
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // Dx
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // Ex
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // Fx
};

// Returns the number of characters at the start of the string that are
// whitespace. Disallows searching past the given maximum number of characters.
size_t
yp_strspn_whitespace(const char *string, long length) {
  if (length <= 0) return 0;

  size_t size = 0;
  size_t maximum = (size_t) length;

  while (size < maximum && (yp_char_table[(unsigned char) string[size]] & YP_CHAR_BIT_WHITESPACE)) size++;
  return size;
}

// Returns the number of characters at the start of the string that are inline
// whitespace. Disallows searching past the given maximum number of characters.
size_t
yp_strspn_inline_whitespace(const char *string, long length) {
  if (length <= 0) return 0;

  size_t size = 0;
  size_t maximum = (size_t) length;

  while (size < maximum && (yp_char_table[(unsigned char) string[size]] & YP_CHAR_BIT_INLINE_WHITESPACE)) size++;
  return size;
}

// Returns the number of characters at the start of the string that are decimal
// digits. Disallows searching past the given maximum number of characters.
size_t
yp_strspn_decimal_digit(const char *string, long length) {
  if (length <= 0) return 0;

  size_t size = 0;
  size_t maximum = (size_t) length;

  while (size < maximum && (yp_char_table[(unsigned char) string[size]] & YP_CHAR_BIT_DECIMAL_DIGIT)) size++;
  return size;
}

// Returns the number of characters at the start of the string that are
// hexidecimal digits. Disallows searching past the given maximum number of
// characters.
size_t
yp_strspn_hexidecimal_digit(const char *string, long length) {
  if (length <= 0) return 0;

  size_t size = 0;
  size_t maximum = (size_t) length;

  while (size < maximum && (yp_char_table[(unsigned char) string[size]] & YP_CHAR_BIT_HEXIDECIMAL_DIGIT)) size++;
  return size;
}

// Returns the number of characters at the start of the string that are octal
// digits or underscores.  Disallows searching past the given maximum number of
// characters.
size_t
yp_strspn_octal_number(const char *string, long length) {
  if (length <= 0) return 0;

  size_t size = 0;
  size_t maximum = (size_t) length;

  while (size < maximum && (yp_char_table[(unsigned char) string[size]] & YP_CHAR_BIT_OCTAL_NUMBER)) size++;
  return size;
}

// Returns the number of characters at the start of the string that are decimal
// digits or underscores. Disallows searching past the given maximum number of
// characters.
size_t
yp_strspn_decimal_number(const char *string, long length) {
  if (length <= 0) return 0;

  size_t size = 0;
  size_t maximum = (size_t) length;

  while (size < maximum && (yp_char_table[(unsigned char) string[size]] & YP_CHAR_BIT_DECIMAL_NUMBER)) size++;
  return size;
}

// Returns the number of characters at the start of the string that are
// hexidecimal digits or underscores. Disallows searching past the given maximum
// number of characters.
size_t
yp_strspn_hexidecimal_number(const char *string, long length) {
  if (length <= 0) return 0;

  size_t size = 0;
  size_t maximum = (size_t) length;

  while (size < maximum && (yp_char_table[(unsigned char) string[size]] & YP_CHAR_BIT_HEXIDECIMAL_NUMBER)) size++;
  return size;
}

// Returns the number of characters at the start of the string that are regexp
// options. Disallows searching past the given maximum number of characters.
size_t
yp_strspn_regexp_option(const char *string, long length) {
  if (length <= 0) return 0;

  size_t size = 0;
  size_t maximum = (size_t) length;

  while (size < maximum && (yp_char_table[(unsigned char) string[size]] & YP_CHAR_BIT_REGEXP_OPTION)) size++;
  return size;
}

// Returns the number of characters at the start of the string that are binary
// digits or underscores. Disallows searching past the given maximum number of
// characters.
size_t
yp_strspn_binary_number(const char *string, long length) {
  if (length <= 0) return 0;

  size_t size = 0;
  size_t maximum = (size_t) length;

  while (size < maximum && (string[size] == '0' || string[size] == '1' || string[size] == '_')) size++;
  return size;
}

// Returns true if the given character is a whitespace character.
bool
yp_char_is_whitespace(const char c) {
  return (yp_char_table[(unsigned char) c] & YP_CHAR_BIT_WHITESPACE) != 0;
}

// Returns true if the given character is an inline whitespace character.
bool
yp_char_is_inline_whitespace(const char c) {
  return (yp_char_table[(unsigned char) c] & YP_CHAR_BIT_INLINE_WHITESPACE) != 0;
}

// Returns true if the given character is a binary digit.
bool
yp_char_is_binary_digit(const char c) {
  return c == '0' || c == '1';
}

// Returns true if the given character is an octal digit.
bool
yp_char_is_octal_digit(const char c) {
  return c >= '0' && c <= '7';
}

// Returns true if the given character is a decimal digit.
bool
yp_char_is_decimal_digit(const char c) {
  return (yp_char_table[(unsigned char) c] & YP_CHAR_BIT_DECIMAL_DIGIT) != 0;
}

// Returns true if the given character is a hexidecimal digit.
bool
yp_char_is_hexidecimal_digit(const char c) {
  return (yp_char_table[(unsigned char) c] & YP_CHAR_BIT_HEXIDECIMAL_DIGIT) != 0;
}

#undef YP_CHAR_BIT_WHITESPACE
#undef YP_CHAR_BIT_INLINE_WHITESPACE
#undef YP_CHAR_BIT_DECIMAL_DIGIT
#undef YP_CHAR_BIT_HEXIDECIMAL_DIGIT
#undef YP_CHAR_BIT_OCTAL_NUMBER
#undef YP_CHAR_BIT_DECIMAL_NUMBER
#undef YP_CHAR_BIT_HEXIDECIMAL_NUMBER
#undef YP_CHAR_BIT_REGEXP_OPTION
