#ifndef YARP_STRNSTR_H
#define YARP_STRNSTR_H

#include <stddef.h>
#include <string.h>

// Find the first occurrence of the needle string in haystack string, searching
// at maximum length bytes. Haystack is not assumed to be null terminated, but
// needle is.
const char *
yp_strnstr(const char *haystack, const char *needle, size_t length);

#endif
