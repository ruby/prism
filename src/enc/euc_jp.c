#include "yp_encoding.h"

typedef uint32_t euc_jp_codepoint_t;

#define EUC_JP_ALPHA_CODEPOINTS_LENGTH 4
euc_jp_codepoint_t euc_jp_alpha_codepoints[EUC_JP_ALPHA_CODEPOINTS_LENGTH] = {
  0x41, 0x5A,
  0x61, 0x7A,
};

#define EUC_JP_ALNUM_CODEPOINTS_LENGTH 6
euc_jp_codepoint_t euc_jp_alnum_codepoints[EUC_JP_ALNUM_CODEPOINTS_LENGTH] = {
  0x30, 0x39,
  0x41, 0x5A,
  0x61, 0x7A,
};

#define EUC_JP_ISUPPER_CODEPOINTS_LENGTH 2
euc_jp_codepoint_t euc_jp_isupper_codepoints[EUC_JP_ISUPPER_CODEPOINTS_LENGTH] = {
  0x41, 0x5A,
};

static bool
euc_jp_codepoint_match(euc_jp_codepoint_t codepoint, euc_jp_codepoint_t *codepoints, size_t size) {
  for (size_t index = 0; index < size; index += 2) {
    if (codepoint >= codepoints[index] && codepoint <= codepoints[index + 1])
      return true;
  }
  return false;
}

static euc_jp_codepoint_t
euc_jp_codepoint(const char *c, size_t *width) {
  const unsigned char *uc = (const unsigned char *) c;

  // These are the single byte characters.
  if (*uc < 0x80) {
    *width = 1;
    return *uc;
  }

  // These are the double byte characters.
  if (
    ((uc[0] == 0x8E) && (uc[1] >= 0xA1 && uc[1] <= 0xFE)) ||
    ((uc[0] >= 0xA1 && uc[0] <= 0xFE) && (uc[1] >= 0xA1 && uc[1] <= 0xFE))
  ) {
    *width = 2;
    return uc[0] << 8 | uc[1];
  }

  *width = 0;
  return 0;
}

size_t
yp_encoding_euc_jp_char_width(const char *c) {
  size_t width;
  euc_jp_codepoint(c, &width);

  return width;
}

size_t
yp_encoding_euc_jp_alpha_char(const char *c) {
  size_t width;
  euc_jp_codepoint_t codepoint = euc_jp_codepoint(c, &width);

  return (codepoint && euc_jp_codepoint_match(codepoint, euc_jp_alpha_codepoints, EUC_JP_ALPHA_CODEPOINTS_LENGTH)) ? width : 0;
}

size_t
yp_encoding_euc_jp_alnum_char(const char *c) {
  size_t width;
  euc_jp_codepoint_t codepoint = euc_jp_codepoint(c, &width);

  return (codepoint && euc_jp_codepoint_match(codepoint, euc_jp_alnum_codepoints, EUC_JP_ALNUM_CODEPOINTS_LENGTH)) ? width : 0;
}

bool
yp_encoding_euc_jp_isupper_char(const char *c) {
  size_t width;
  euc_jp_codepoint_t codepoint = euc_jp_codepoint(c, &width);

  return codepoint && euc_jp_codepoint_match(codepoint, euc_jp_isupper_codepoints, EUC_JP_ISUPPER_CODEPOINTS_LENGTH);
}

#undef EUC_JP_ALPHA_CODEPOINTS_LENGTH
#undef EUC_JP_ALNUM_CODEPOINTS_LENGTH
#undef EUC_JP_ISUPPER_CODEPOINTS_LENGTH
