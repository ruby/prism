#ifndef YARP_BUFFER_H
#define YARP_BUFFER_H

#include <stdlib.h>
#include <string.h>

typedef struct {
  char *value;
  size_t length;
  size_t capacity;
} yp_buffer_t;

yp_buffer_t *
yp_buffer_alloc();

void
yp_buffer_append_str(yp_buffer_t *buffer, const char *value, size_t length);

void
yp_buffer_append_u8(yp_buffer_t *buffer, uint8_t value);

void
yp_buffer_append_u16(yp_buffer_t *buffer, uint16_t value);

void
yp_buffer_append_u32(yp_buffer_t *buffer, uint32_t value);

void
yp_buffer_append_u64(yp_buffer_t *buffer, uint64_t value);

void
yp_buffer_free(yp_buffer_t *buffer);

#endif
