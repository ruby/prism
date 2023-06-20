// This files must be required before any system header
// as it influences which functions system headers declare.

#ifndef YARP_DEFINES_H
#define YARP_DEFINES_H

// For strnlen(), strncasecmp()
#if defined(_WIN32)
#   define YP_EXPORTED_FUNCTION __declspec(dllexport) extern
#else
#   ifndef YP_EXPORTED_FUNCTION
#       ifndef RUBY_FUNC_EXPORTED
#           define YP_EXPORTED_FUNCTION __attribute__((__visibility__("default"))) extern
#       else
#           define YP_EXPORTED_FUNCTION RUBY_FUNC_EXPORTED
#       endif
#   endif
#endif

#if defined(__GNUC__)
# define YP_ATTRIBUTE_UNUSED __attribute__((unused))
#else
# define YP_ATTRIBUTE_UNUSED
#endif

#endif
