#include "buffer.h"
#include "yarp.h"

#define YARP_SERIALIZE_MAJOR 0
#define YARP_SERIALIZE_MINOR 1
#define YARP_SERIALIZE_PATCH 0

/******************************************************************************/
/* BEGIN TEMPLATE                                                             */
/******************************************************************************/

static void
serialize_token(yp_parser_t *parser, yp_token_t *token, yp_buffer_t *buffer) {
  yp_buffer_append_u8(buffer, token->type);
  yp_buffer_append_u64(buffer, token->start - parser->start);
  yp_buffer_append_u64(buffer, token->end - parser->start);
}

static void
serialize_node(yp_parser_t *parser, yp_node_t *node, yp_buffer_t *buffer) {
  yp_buffer_append_u8(buffer, node->type);

  size_t offset = buffer->length;
  yp_buffer_append_u64(buffer, 0);

  yp_buffer_append_u64(buffer, node->location.start);
  yp_buffer_append_u64(buffer, node->location.end);

  switch (node->type) {
    case YP_NODE_ASSIGNMENT: {
      serialize_node(parser, node->as.assignment.target, buffer);
      serialize_token(parser, &node->as.assignment.operator, buffer);
      serialize_node(parser, node->as.assignment.value, buffer);
      break;
    }
    case YP_NODE_BINARY: {
      serialize_node(parser, node->as.binary.left, buffer);
      serialize_token(parser, &node->as.binary.operator, buffer);
      serialize_node(parser, node->as.binary.right, buffer);
      break;
    }
    case YP_NODE_CHARACTER_LITERAL: {
      serialize_token(parser, &node->as.character_literal.value, buffer);
      break;
    }
    case YP_NODE_CLASS_VARIABLE_READ: {
      serialize_token(parser, &node->as.class_variable_read.name, buffer);
      break;
    }
    case YP_NODE_CLASS_VARIABLE_WRITE: {
      serialize_token(parser, &node->as.class_variable_write.name, buffer);
      serialize_token(parser, &node->as.class_variable_write.operator, buffer);
      serialize_node(parser, node->as.class_variable_write.value, buffer);
      break;
    }
    case YP_NODE_FALSE_NODE: {
      serialize_token(parser, &node->as.false_node.keyword, buffer);
      break;
    }
    case YP_NODE_FLOAT_LITERAL: {
      serialize_token(parser, &node->as.float_literal.value, buffer);
      break;
    }
    case YP_NODE_GLOBAL_VARIABLE_READ: {
      serialize_token(parser, &node->as.global_variable_read.name, buffer);
      break;
    }
    case YP_NODE_GLOBAL_VARIABLE_WRITE: {
      serialize_token(parser, &node->as.global_variable_write.name, buffer);
      serialize_token(parser, &node->as.global_variable_write.operator, buffer);
      serialize_node(parser, node->as.global_variable_write.value, buffer);
      break;
    }
    case YP_NODE_IF_NODE: {
      serialize_token(parser, &node->as.if_node.keyword, buffer);
      serialize_node(parser, node->as.if_node.predicate, buffer);
      serialize_node(parser, node->as.if_node.statements, buffer);
      break;
    }
    case YP_NODE_IMAGINARY_LITERAL: {
      serialize_token(parser, &node->as.imaginary_literal.value, buffer);
      break;
    }
    case YP_NODE_INSTANCE_VARIABLE_READ: {
      serialize_token(parser, &node->as.instance_variable_read.name, buffer);
      break;
    }
    case YP_NODE_INSTANCE_VARIABLE_WRITE: {
      serialize_token(parser, &node->as.instance_variable_write.name, buffer);
      serialize_token(parser, &node->as.instance_variable_write.operator, buffer);
      serialize_node(parser, node->as.instance_variable_write.value, buffer);
      break;
    }
    case YP_NODE_INTEGER_LITERAL: {
      serialize_token(parser, &node->as.integer_literal.value, buffer);
      break;
    }
    case YP_NODE_NIL_NODE: {
      serialize_token(parser, &node->as.nil_node.keyword, buffer);
      break;
    }
    case YP_NODE_OPERATOR_ASSIGNMENT: {
      serialize_node(parser, node->as.operator_assignment.target, buffer);
      serialize_token(parser, &node->as.operator_assignment.operator, buffer);
      serialize_node(parser, node->as.operator_assignment.value, buffer);
      break;
    }
    case YP_NODE_PROGRAM: {
      serialize_node(parser, node->as.program.statements, buffer);
      break;
    }
    case YP_NODE_RATIONAL_LITERAL: {
      serialize_token(parser, &node->as.rational_literal.value, buffer);
      break;
    }
    case YP_NODE_REDO: {
      serialize_token(parser, &node->as.redo.value, buffer);
      break;
    }
    case YP_NODE_RETRY: {
      serialize_token(parser, &node->as.retry.value, buffer);
      break;
    }
    case YP_NODE_SELF_NODE: {
      serialize_token(parser, &node->as.self_node.keyword, buffer);
      break;
    }
    case YP_NODE_STATEMENTS: {
      uint64_t size = node->as.statements.body->size;
      yp_buffer_append_u64(buffer, size);
      for (uint64_t index = 0; index < size; index++) {
        serialize_node(parser, node->as.statements.body->nodes[index], buffer);
      }
      break;
    }
    case YP_NODE_TERNARY: {
      serialize_node(parser, node->as.ternary.predicate, buffer);
      serialize_token(parser, &node->as.ternary.question_mark, buffer);
      serialize_node(parser, node->as.ternary.true_expression, buffer);
      serialize_token(parser, &node->as.ternary.colon, buffer);
      serialize_node(parser, node->as.ternary.false_expression, buffer);
      break;
    }
    case YP_NODE_TRUE_NODE: {
      serialize_token(parser, &node->as.true_node.keyword, buffer);
      break;
    }
    case YP_NODE_UNLESS_MODIFIER: {
      serialize_node(parser, node->as.unless_modifier.statement, buffer);
      serialize_token(parser, &node->as.unless_modifier.keyword, buffer);
      serialize_node(parser, node->as.unless_modifier.predicate, buffer);
      break;
    }
    case YP_NODE_UNTIL_MODIFIER: {
      serialize_node(parser, node->as.until_modifier.statement, buffer);
      serialize_token(parser, &node->as.until_modifier.keyword, buffer);
      serialize_node(parser, node->as.until_modifier.predicate, buffer);
      break;
    }
    case YP_NODE_VARIABLE_REFERENCE: {
      serialize_token(parser, &node->as.variable_reference.value, buffer);
      break;
    }
    case YP_NODE_WHILE_MODIFIER: {
      serialize_node(parser, node->as.while_modifier.statement, buffer);
      serialize_token(parser, &node->as.while_modifier.keyword, buffer);
      serialize_node(parser, node->as.while_modifier.predicate, buffer);
      break;
    }
  }

  uint64_t length = buffer->length - offset - sizeof(uint64_t);
  memcpy(buffer->value + offset, &length, sizeof(uint64_t));
}

/******************************************************************************/
/* END TEMPLATE                                                               */
/******************************************************************************/

void
yp_serialize(yp_parser_t *parser, yp_node_t *node, yp_buffer_t *buffer) {
  yp_buffer_append_str(buffer, "YARP", 4);
  yp_buffer_append_u8(buffer, YARP_SERIALIZE_MAJOR);
  yp_buffer_append_u8(buffer, YARP_SERIALIZE_MINOR);
  yp_buffer_append_u8(buffer, YARP_SERIALIZE_PATCH);

  serialize_node(parser, node, buffer);
  yp_buffer_append_str(buffer, "\0", 1);
}
