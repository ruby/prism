#include "yarp/util/yp_strnstr.h"

// Find the first occurrence of the needle string in haystack string, searching
// at maximum length bytes. Haystack is not assumed to be null terminated, but
// needle is.
const char *
yp_strnstr(const char *haystack, const char *needle, size_t length) {
  size_t needle_length = strnlen(needle, length);

  // If it wouldn't be possible to find the needle because we can't search
  // enough characters, return NULL.
  if (needle_length > length) return NULL;

  // This is the last possible position in haystack where the needle could
  // start.
  const char *haystack_limit = haystack + length - needle_length + 1;

  while ((haystack = memchr(haystack, needle[0], haystack_limit - haystack)) != NULL) {
    if (!strncmp(haystack, needle, needle_length)) return haystack;
    haystack++;
  }

  return NULL;
}
