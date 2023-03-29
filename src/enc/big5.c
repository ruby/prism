#include "yarp/enc/yp_encoding.h"

typedef uint32_t big5_codepoint_t;

#define BIG5_ALPHA_CODEPOINTS_LENGTH 4
big5_codepoint_t big5_alpha_codepoints[BIG5_ALPHA_CODEPOINTS_LENGTH] = {
  0x41, 0x5A,
  0x61, 0x7A,
};

#define BIG5_ALNUM_CODEPOINTS_LENGTH 6
big5_codepoint_t big5_alnum_codepoints[BIG5_ALNUM_CODEPOINTS_LENGTH] = {
  0x30, 0x39,
  0x41, 0x5A,
  0x61, 0x7A,
};

#define BIG5_ISUPPER_CODEPOINTS_LENGTH 2
big5_codepoint_t big5_isupper_codepoints[BIG5_ISUPPER_CODEPOINTS_LENGTH] = {
  0x41, 0x5A,
};

static bool
big5_codepoint_match(big5_codepoint_t codepoint, big5_codepoint_t *codepoints, size_t size) {
  for (size_t index = 0; index < size; index += 2) {
    if (codepoint >= codepoints[index] && codepoint <= codepoints[index + 1])
      return true;
  }
  return false;
}

static big5_codepoint_t
big5_codepoint(const char *c, size_t *width) {
  const unsigned char *uc = (const unsigned char *) c;

  // These are the single byte characters.
  if (*uc < 0x80) {
    *width = 1;
    return *uc;
  }

  // These are the double byte characters.
  if ((uc[0] >= 0xA1 && uc[0] <= 0xFE) && (uc[1] >= 0x40 && uc[1] <= 0xFE)) {
    *width = 2;
    return (big5_codepoint_t) (uc[0] << 8 | uc[1]);
  }

  *width = 0;
  return 0;
}

size_t
yp_encoding_big5_char_width(const char *c) {
  size_t width;
  big5_codepoint(c, &width);

  return width;
}

size_t
yp_encoding_big5_alpha_char(const char *c) {
  size_t width;
  big5_codepoint_t codepoint = big5_codepoint(c, &width);

  return (codepoint && big5_codepoint_match(codepoint, big5_alpha_codepoints, BIG5_ALPHA_CODEPOINTS_LENGTH)) ? width : 0;
}

size_t
yp_encoding_big5_alnum_char(const char *c) {
  size_t width;
  big5_codepoint_t codepoint = big5_codepoint(c, &width);

  return (codepoint && big5_codepoint_match(codepoint, big5_alnum_codepoints, BIG5_ALNUM_CODEPOINTS_LENGTH)) ? width : 0;
}

bool
yp_encoding_big5_isupper_char(const char *c) {
  size_t width;
  big5_codepoint_t codepoint = big5_codepoint(c, &width);

  return codepoint && big5_codepoint_match(codepoint, big5_isupper_codepoints, BIG5_ISUPPER_CODEPOINTS_LENGTH);
}

#undef BIG5_ALPHA_CODEPOINTS_LENGTH
#undef BIG5_ALNUM_CODEPOINTS_LENGTH
#undef BIG5_ISUPPER_CODEPOINTS_LENGTH
