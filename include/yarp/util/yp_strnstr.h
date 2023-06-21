#ifndef YP_STRNSTR_H
#define YP_STRNSTR_H

#include "yarp/defines.h"

#include <stddef.h>
#include <string.h>

// Here we have rolled our own version of strnstr because for the most part it
// is not available unless on BSD, and even then -std=c99 sometimes does not
// include it.
const char * yp_strnstr(const char *haystack, const char *needle, size_t length);

#endif
