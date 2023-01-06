#include "unescape.h"

static inline bool
char_is_space(const char c) {
  return c == ' ' || ('\t' <= c && c <= '\r');
}

static inline bool
char_is_octal_number(const char c) {
  return c >= '0' && c <= '7';
}

static inline bool
char_is_hexadecimal_number(const char c) {
  return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}

static inline bool
char_is_hexadecimal_numbers(const char *c, size_t length) {
  for (size_t index = 0; index < length; index++) {
    if (!char_is_hexadecimal_number(c[index])) {
      return false;
    }
  }
  return true;
}

// This is a lookup table for unescapes that only take up a single character.
static const char unescape_chars[] = {
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
  if (!char_is_octal_number(backslash[2])) {
    return 2;
  }

  *value = (*value << 3) | (backslash[2] - '0');
  if (!char_is_octal_number(backslash[3])) {
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

// Scan the 4 digits of a Unicode escape into the value. Returns the number of
// digits scanned. This function assumes that the characters have already been
// validated.
static inline void
unescape_unicode(const char *string, size_t length, uint32_t *value) {
  *value = 0;
  for (size_t index = 0; index < length; index++) {
    if (index != 0) *value <<= 4;
    *value |= unescape_hexadecimal_digit(string[index]);
  }
}

// Accepts the pointer to the string to write the unicode value along with the
// 32-bit value to write. Writes the UTF-8 representation of the value to the
// string and returns the number of bytes written.
static inline size_t
unescape_unicode_write(char *destination, uint32_t value) {
  if (value <= 0x7F) {
    // 0xxxxxxx
    destination[0] = value;
    return 1;
  }

  if (value <= 0x7FF) {
    // 110xxxxx 10xxxxxx
    destination[0] = 0xC0 | (value >> 6);
    destination[1] = 0x80 | (value & 0x3F);
    return 2;
  }

  if (value <= 0xFFFF) {
    // 1110xxxx 10xxxxxx 10xxxxxx
    destination[0] = 0xE0 | (value >> 12);
    destination[1] = 0x80 | ((value >> 6) & 0x3F);
    destination[2] = 0x80 | (value & 0x3F);
    return 3;
  }

  // At this point it must be a 4 digit UTF-8 representation. If it's not, then
  // the input is invalid.
  assert(value <= 0x10FFFF);

  // 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
  destination[0] = 0xF0 | (value >> 18);
  destination[1] = 0x80 | ((value >> 12) & 0x3F);
  destination[2] = 0x80 | ((value >> 6) & 0x3F);
  destination[3] = 0x80 | (value & 0x3F);
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
__attribute__((__visibility__("default"))) extern bool
yp_unescape(const char *value, size_t length, yp_string_t *string, yp_unescape_type_t unescape_type) {
  if (unescape_type == YP_UNESCAPE_NONE) {
    // If we're not unescaping then we can reference the source directly.
    yp_string_shared_init(string, value, value + length);
    return true;
  }

  const char *backslash = memchr(value, '\\', length);

  if (backslash == NULL) {
    // Here there are no escapes, so we can reference the source directly.
    yp_string_shared_init(string, value, value + length);
    return true;
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
          case 'u': {
            if (backslash[2] == '{') {
              const char *unicode_cursor = backslash + 3;

              while ((*unicode_cursor != '}') && (unicode_cursor < end)) {
                const char *unicode_start = unicode_cursor;
                while ((unicode_cursor < end) && char_is_hexadecimal_number(*unicode_cursor)) unicode_cursor++;

                uint32_t value;
                unescape_unicode(unicode_start, unicode_cursor - unicode_start, &value);
                dest_length += unescape_unicode_write(dest + dest_length, value);

                while ((unicode_cursor < end) && char_is_space(*unicode_cursor)) unicode_cursor++;
              }

              cursor = unicode_cursor + 1;
              break;
            }

            if (char_is_hexadecimal_numbers(backslash + 2, 4)) {
              uint32_t value;
              unescape_unicode(backslash + 2, 4, &value);

              cursor = backslash + 6;
              dest_length += unescape_unicode_write(dest + dest_length, value);
              break;
            }

            return false;
          }
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
            if (backslash[2] != '-') {
              // handle invalid escape here
            } else if (backslash[3] == '?') {
              cursor = backslash + 4;
              dest[dest_length++] = 0x7f;
            } else {
              // check printable character here
            }
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
        break;
    }

    backslash = memchr(cursor, '\\', end - cursor);
  }

  // We need to copy the final segment of the string after the last escape.
  memcpy(dest + dest_length, cursor, end - cursor);

  // We also need to update the length at the end. This is because every escape
  // reduces the length of the final string, and we don't want garbage at the
  // end.
  string->as.owned.length = dest_length + (end - cursor);
  return true;
}
