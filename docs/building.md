# Building

The following describes how to build prism from source. This comes directly from the [Makefile](../Makefile).

## Common

All of the source files match `src/**/*.c` and all of the headers match `include/**/*.h`.

The following flags should be used to compile prism:

* `-std=c99` - Use the C99 standard
* `-Wall -Wconversion -Wextra -Wpedantic -Wundef -Wno-missing-braces` - Enable the warnings we care about
* `-Werror` - Treat warnings as errors
* `-fvisibility=hidden` - Hide all symbols by default

## Shared

If you want to build prism as a shared library and link against it, you should compile with:

* `-fPIC -shared` - Compile as a shared library
* `-DPRISM_EXPORT_SYMBOLS` - Export the symbols (by default nothing is exported)

## Flags

`make` respects the `MAKEFLAGS` environment variable. As such, to speed up the build you can run:

```
MAKEFLAGS="-j10" bundle exec rake compile
```
