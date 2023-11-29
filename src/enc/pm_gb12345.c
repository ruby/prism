#include "prism/enc/pm_encoding.h"

static size_t
pm_encoding_gb12345_char_width(const uint8_t *b, ptrdiff_t n) {
    // GB12345 is a multi-byte encoding, similar to GB2312.
    // These are the double byte characters.
    if (
        (n > 1) &&
        ((b[0] >= 0xA1 && b[0] <= 0xF7) && (b[1] >= 0xA1 && b[1] <= 0xFE))
    ) {
        return 2;
    }

    return 0;
}

static size_t
pm_encoding_gb12345_alpha_char(const uint8_t *b, ptrdiff_t n) {
    // GB12345 primarily encodes Chinese characters, which do not fit the concept of 'alphabetic' in the Latin sense.
    return 0;
}

static size_t
pm_encoding_gb12345_alnum_char(const uint8_t *b, ptrdiff_t n) {
    // GB12345 encodes Chinese characters, and the concept of 'alphanumeric' doesn't apply in the same way as it does in Latin-based encodings.
    return 0;
}

static bool
pm_encoding_gb12345_isupper_char(const uint8_t *b, ptrdiff_t n) {
    // The concept of uppercase doesn't apply to Chinese characters.
    return false;
}

/** GB12345 encoding */
pm_encoding_t pm_encoding_gb12345 = {
    .name = "GB12345",
    .char_width = pm_encoding_gb12345_char_width,
    .alnum_char = pm_encoding_gb12345_alnum_char,
    .alpha_char = pm_encoding_gb12345_alpha_char,
    .isupper_char = pm_encoding_gb12345_isupper_char,
    .multibyte = true
};
