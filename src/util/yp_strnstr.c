#include "yarp/util/yp_strnstr.h"

const char *
yp_strnstr(const char *haystack, const char *needle, size_t length) {
    size_t needle_length = strlen(needle);
    if (needle_length > length) return NULL;

    const char *haystack_limit = haystack + length - needle_length + 1;

    while ((haystack = memchr(haystack, needle[0], (size_t) (haystack_limit - haystack))) != NULL) {
        if (!strncmp(haystack, needle, needle_length)) return haystack;
        haystack++;
    }

    return NULL;
}
