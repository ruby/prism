#ifndef YARP_INPUT_H
#define YARP_INPUT_H

typedef struct {
  const char *start; // the pointer to the start of the source
  const char *end;   // the pointer to the end of the source
  const char *pos;   // the pointer to the current position
} yp_input_t;

#endif // YARP_INPUT_H
