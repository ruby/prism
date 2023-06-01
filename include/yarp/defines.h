// This files must be required before any system header
// as it influences which functions system headers declare.

#ifndef YARP_DEFINES_H
#define YARP_DEFINES_H

// For strnlen(), strncasecmp()
#ifndef _XOPEN_SOURCE
#define _XOPEN_SOURCE 700
#endif

#ifndef YP_EXPORTED_FUNCTION
#define YP_EXPORTED_FUNCTION __attribute__((__visibility__("default")))
#endif

#endif
