#ifndef YARP_SERIALIZE_H
#define YARP_SERIALIZE_H

#include "buffer.h"
#include "yarp.h"

void
yp_serialize_node(yp_parser_t *parser, yp_node_t *node, yp_buffer_t *buffer);

#endif // YARP_SERIALIZE_H
