#include "yarp/enc/yp_encoding.h"

typedef uint32_t windows_31j_codepoint_t;

#define WINDOWS_31J_ALPHA_CODEPOINTS_LENGTH 4
windows_31j_codepoint_t windows_31j_alpha_codepoints[WINDOWS_31J_ALPHA_CODEPOINTS_LENGTH] = {
  0x41, 0x5A,
  0x61, 0x7A,
};

#define WINDOWS_31J_ALNUM_CODEPOINTS_LENGTH 6
windows_31j_codepoint_t windows_31j_alnum_codepoints[WINDOWS_31J_ALNUM_CODEPOINTS_LENGTH] = {
  0x30, 0x39,
  0x41, 0x5A,
  0x61, 0x7A,
};

#define WINDOWS_31J_ISUPPER_CODEPOINTS_LENGTH 2
windows_31j_codepoint_t windows_31j_isupper_codepoints[WINDOWS_31J_ISUPPER_CODEPOINTS_LENGTH] = {
  0x41, 0x5A,
};

static bool
windows_31j_codepoint_match(windows_31j_codepoint_t codepoint, windows_31j_codepoint_t *codepoints, size_t size) {
  for (size_t index = 0; index < size; index += 2) {
    if (codepoint >= codepoints[index] && codepoint <= codepoints[index + 1])
      return true;
  }
  return false;
}

static windows_31j_codepoint_t
windows_31j_codepoint(const char *c, size_t *width) {
  const unsigned char *uc = (const unsigned char *) c;

  // These are the single byte characters.
  if (*uc < 0x80 || (*uc >= 0xA1 && *uc <= 0xDF)) {
    *width = 1;
    return *uc;
  }

  // These are the double byte characters.
  if (
    ((uc[0] >= 0x81 && uc[0] <= 0x9F) || (uc[0] >= 0xE0 && uc[0] <= 0xFC)) &&
    (uc[1] >= 0x40 && uc[1] <= 0xFC)
  ) {
    *width = 2;
    return (windows_31j_codepoint_t) (uc[0] << 8 | uc[1]);
  }

  *width = 0;
  return 0;
}

size_t
yp_encoding_windows_31j_char_width(const char *c) {
  size_t width;
  windows_31j_codepoint(c, &width);

  return width;
}

size_t
yp_encoding_windows_31j_alpha_char(const char *c) {
  size_t width;
  windows_31j_codepoint_t codepoint = windows_31j_codepoint(c, &width);

  return (codepoint && windows_31j_codepoint_match(codepoint, windows_31j_alpha_codepoints, WINDOWS_31J_ALPHA_CODEPOINTS_LENGTH)) ? width : 0;
}

size_t
yp_encoding_windows_31j_alnum_char(const char *c) {
  size_t width;
  windows_31j_codepoint_t codepoint = windows_31j_codepoint(c, &width);

  return (codepoint && windows_31j_codepoint_match(codepoint, windows_31j_alnum_codepoints, WINDOWS_31J_ALNUM_CODEPOINTS_LENGTH)) ? width : 0;
}

bool
yp_encoding_windows_31j_isupper_char(const char *c) {
  size_t width;
  windows_31j_codepoint_t codepoint = windows_31j_codepoint(c, &width);

  return codepoint && windows_31j_codepoint_match(codepoint, windows_31j_isupper_codepoints, WINDOWS_31J_ISUPPER_CODEPOINTS_LENGTH);
}

#undef WINDOWS_31J_ALPHA_CODEPOINTS_LENGTH
#undef WINDOWS_31J_ALNUM_CODEPOINTS_LENGTH
#undef WINDOWS_31J_ISUPPER_CODEPOINTS_LENGTH
