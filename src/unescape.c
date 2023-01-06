#include "unescape.h"

static inline bool
char_is_decimal_number(const char c) {
  return c >= '0' && c <= '9';
}

static inline bool
char_is_hexadecimal_number(const char c) {
  return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}

// This is a lookup table for unescapes that only take up a single character.
static const char unescape_chars[128] = {
  ['\''] = '\'',
  ['\\'] = '\\',
  ['a'] = '\a',
  ['b'] = '\b',
  ['e'] = '\e',
  ['f'] = '\f',
  ['n'] = '\n',
  ['r'] = '\r',
  ['s'] = ' ',
  ['t'] = '\t',
  ['v'] = '\v'
};

// Scan the 1-3 digits of octal into the value. Returns the number of digits
// scanned.
static inline size_t
unescape_octal(const char *backslash, unsigned char *value) {
  *value = backslash[1] - '0';
  if (!char_is_decimal_number(backslash[2])) {
    return 2;
  }

  *value = (*value << 3) | (backslash[2] - '0');
  if (!char_is_decimal_number(backslash[3])) {
    return 3;
  }

  *value = (*value << 3) | (backslash[3] - '0');
  return 4;
}

// Convert a hexadecimal digit into its equivalent value.
static inline unsigned char
unescape_hexadecimal_digit(const char value) {
  return (value <= '9') ? value - '0' : (value & 0x7) + 9;
}

// Scan the 1-2 digits of hexadecimal into the value. Returns the number of
// digits scanned.
static inline size_t
unescape_hexadecimal(const char *backslash, unsigned char *value) {
  *value = unescape_hexadecimal_digit(backslash[2]);
  if (!char_is_hexadecimal_number(backslash[3])) {
    return 3;
  }

  *value = (*value << 4) | unescape_hexadecimal_digit(backslash[3]);
  return 4;
}

// Unescape the contents of the given token into the given string using the
// given unescape mode. The supported escapes are:
//
// \a             bell, ASCII 07h (BEL)
// \b             backspace, ASCII 08h (BS)
// \t             horizontal tab, ASCII 09h (TAB)
// \n             newline (line feed), ASCII 0Ah (LF)
// \v             vertical tab, ASCII 0Bh (VT)
// \f             form feed, ASCII 0Ch (FF)
// \r             carriage return, ASCII 0Dh (CR)
// \e             escape, ASCII 1Bh (ESC)
// \s             space, ASCII 20h (SPC)
// \\             backslash
// \nnn           octal bit pattern, where nnn is 1-3 octal digits ([0-7])
// \xnn           hexadecimal bit pattern, where nn is 1-2 hexadecimal digits ([0-9a-fA-F])
// \unnnn         Unicode character, where nnnn is exactly 4 hexadecimal digits ([0-9a-fA-F])
// \u{nnnn ...}   Unicode character(s), where each nnnn is 1-6 hexadecimal digits ([0-9a-fA-F])
// \cx or \C-x    control character, where x is an ASCII printable character
// \M-x           meta character, where x is an ASCII printable character
// \M-\C-x        meta control character, where x is an ASCII printable character
// \M-\cx         same as above
// \c\M-x         same as above
// \c? or \C-?    delete, ASCII 7Fh (DEL)
//
__attribute__((__visibility__("default"))) extern void
yp_unescape(const char *value, size_t length, yp_string_t *string, yp_unescape_type_t unescape_type) {
  if (unescape_type == YP_UNESCAPE_NONE) {
    // If we're not unescaping then we can reference the source directly.
    yp_string_shared_init(string, value, value + length);
    return;
  }

  const char *backslash = memchr(value, '\\', length);

  if (backslash == NULL) {
    // Here there are no escapes, so we can reference the source directly.
    yp_string_shared_init(string, value, value + length);
    return;
  }

  // Here we have found an escape character, so we need to handle all escapes
  // within the string.
  yp_string_owned_init(string, malloc(length), length);

  // This is the memory address where we're putting the unescaped string.
  char *dest = string->as.owned.source;
  size_t dest_length = 0;

  // This is the current position in the source string that we're looking at.
  // It's going to move along behind the backslash so that we can copy each
  // segment of the string that doesn't contain an escape.
  const char *cursor = value;
  const char *end = value + length;

  // For each escape found in the source string, we will handle it and update
  // the moving cursor->backslash window.
  while (backslash != NULL && backslash < end) {
    // This is the size of the segment of the string from the previous escape
    // or the start of the string to the current escape.
    size_t segment_size = backslash - cursor;

    // Here we're going to copy everything up until the escape into the
    // destination buffer.
    memcpy(dest + dest_length, cursor, segment_size);
    dest_length += segment_size;

    switch (backslash[1]) {
      case '\\':
      case '\'':
        dest[dest_length++] = unescape_chars[(unsigned char) backslash[1]];
        cursor = backslash + 2;
        break;
      default:
        if (unescape_type == YP_UNESCAPE_MINIMAL) {
          // In this case we're escaping something that doesn't need escaping.
          dest[dest_length++] = '\\';
          cursor = backslash + 1;
          break;
        }

        // This is the only type of unescaping left. In this case we need to
        // handle all of the different unescapes.
        assert(unescape_type == YP_UNESCAPE_ALL);

        switch (backslash[1]) {
          // \a \b \e \f \n \r \s \t \v
          case 'a':
          case 'b':
          case 'e':
          case 'f':
          case 'n':
          case 'r':
          case 's':
          case 't':
          case 'v':
            dest[dest_length++] = unescape_chars[(unsigned char) backslash[1]];
            cursor = backslash + 2;
            break;
          // \nnn         octal bit pattern, where nnn is 1-3 octal digits ([0-7])
          case '0': case '1': case '2': case '3': case '4':
          case '5': case '6': case '7': case '8': case '9': {
            unsigned char value;
            cursor = backslash + unescape_octal(backslash, &value);
            dest[dest_length++] = value;
            break;
          }
          // \xnn         hexadecimal bit pattern, where nn is 1-2 hexadecimal digits ([0-9a-fA-F])
          case 'x': {
            unsigned char value;
            cursor = backslash + unescape_hexadecimal(backslash, &value);
            dest[dest_length++] = value;
            break;
          }
          // \unnnn       Unicode character, where nnnn is exactly 4 hexadecimal digits ([0-9a-fA-F])
          // \u{nnnn ...} Unicode character(s), where each nnnn is 1-6 hexadecimal digits ([0-9a-fA-F])
          case 'u':
            break;
          // \cx          control character, where x is an ASCII printable character
          // \c\M-x       meta control character, where x is an ASCII printable character
          // \c?          delete, ASCII 7Fh (DEL)
          case 'c':
            switch (backslash[2]) {
              case '\\':
                break;
              case '?':
                cursor = backslash + 3;
                dest[dest_length++] = 0x7f;
                break;
              default:
                break;
            }
            break;
          // \C-x         control character, where x is an ASCII printable character
          // \C-?         delete, ASCII 7Fh (DEL)
          case 'C':
            break;
          // \M-x         meta character, where x is an ASCII printable character
          // \M-\C-x      meta control character, where x is an ASCII printable character
          // \M-\cx       meta control character, where x is an ASCII printable character
          case 'M':
            break;
          // In this case we're escaping something that doesn't need escaping.
          default:
            dest[dest_length++] = '\\';
            cursor = backslash + 1;
            break;
        }
    }

    backslash = memchr(cursor, '\\', end - cursor);
  }

  // We need to copy the final segment of the string after the last escape.
  memcpy(dest + dest_length, cursor, end - cursor);

  // We also need to update the length at the end. This is because every escape
  // reduces the length of the final string, and we don't want garbage at the
  // end.
  string->as.owned.length = dest_length + (end - cursor);
}
