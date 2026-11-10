#ifndef PRISM_EXT_NODE_H
#define PRISM_EXT_NODE_H

#define EXPECTED_PRISM_VERSION "2.1.0"

#include <ruby.h>
#include <ruby/encoding.h>
#include <ruby/version.h>
#include "prism.h"

VALUE pm_source_new(const pm_parser_t *parser, rb_encoding *encoding, VALUE comments, VALUE comment_attachments, VALUE comment_ranges, bool freeze);
VALUE pm_token_new(const pm_parser_t *parser, const pm_token_t *token, rb_encoding *encoding, VALUE source, bool freeze);
VALUE pm_ast_new(const pm_parser_t *parser, const pm_node_t *node, rb_encoding *encoding, VALUE source, bool freeze);
VALUE pm_integer_new(const pm_integer_t *integer);
VALUE pm_compile_unit_new(const pm_parser_t *parser, const PrismUnit *unit, bool freeze);

void Init_prism_api_node(void);
void Init_prism_api_compile(void);
RUBY_FUNC_EXPORTED void Init_prism(void);

#endif
