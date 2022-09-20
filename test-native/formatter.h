#ifndef YARP_TEST_FORMATTER_H
#define YARP_TEST_FORMATTER_H

#define eprintf(...) fprintf(stderr, __VA_ARGS__)

#define red(...)                                                                                                       \
  eprintf("\033[0;31m");                                                                                               \
  eprintf(__VA_ARGS__);                                                                                                \
  eprintf("\033[0m");

#define green(...)                                                                                                     \
  eprintf("\033[0;32m");                                                                                               \
  eprintf(__VA_ARGS__);                                                                                                \
  eprintf("\033[0m");

#endif // YARP_TEST_FORMATTER_H
