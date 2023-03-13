#ifndef YP_STRSPN_H
#define YP_STRSPN_H

#include <stddef.h>

// Returns the number of characters at the start of the string string that are
// whitespace. Disallows searching past the given maximum number of characters.
size_t
yp_strspn_whitespace(const char *string, size_t maximum);

// Returns the number of characters at the start of the string string that are
// whitespace excluding newline characters. Disallows searching past the given
// maximum number of characters.
size_t
yp_strspn_inline_whitespace(const char *string, size_t maximum);

// Returns the number of characters at the start of the string string that are
// decimal digits. Disallows searching past the given maximum number of
// characters.
size_t
yp_strspn_decimal_digit(const char *string, size_t maximum);

// Returns the number of characters at the start of the string string that are
// hexidecimal digits. Disallows searching past the given maximum number of
// characters.
size_t
yp_strspn_hexidecimal_digit(const char *string, size_t maximum);

// Returns the number of characters at the start of the string string that are
// binary digits or underscores. Disallows searching past the given maximum
// number of characters.
size_t
yp_strspn_binary_number(const char *string, size_t maximum);

// Returns the number of characters at the start of the string string that are
// octal digits or underscores. Disallows searching past the given maximum
// number of characters.
size_t
yp_strspn_octal_number(const char *string, size_t maximum);

// Returns the number of characters at the start of the string string that are
// decimal digits or underscores. Disallows searching past the given maximum
// number of characters.
size_t
yp_strspn_decimal_number(const char *string, size_t maximum);

// Returns the number of characters at the start of the string string that are
// hexidecimal digits or underscores. Disallows searching past the given maximum
// number of characters.
size_t
yp_strspn_hexidecimal_number(const char *string, size_t maximum);

#endif
