#ifndef YP_NODES_H
#define YP_NODES_H

#include "assert.h"
#include "ast.h"
#include "parser.h"
#include "string.h"
#include "unescape.h"

// Initiailize a list of nodes.
void
yp_node_list_init(yp_node_list_t *node_list);

// Append a new node onto the end of the node list.
void
yp_node_list_append2(yp_node_list_t *list, yp_node_t *node);

// Allocate and initialize a new alias node.
yp_node_t *
yp_alias_node_create(yp_parser_t *parser, const yp_token_t *keyword, yp_node_t *new_name, yp_node_t *old_name);

// Allocate and initialize a new and node.
yp_node_t *
yp_and_node_create(yp_parser_t *parser, yp_node_t *left, const yp_token_t *oper, yp_node_t *right);

// Allocate an initialize a new arguments node.
yp_node_t *
yp_arguments_node_create(yp_parser_t *parser);

// Return the size of the given arguments node.
size_t
yp_arguments_node_size(yp_node_t *node);

// Append an argument to an arguments node.
void
yp_arguments_node_append(yp_node_t *arguments, yp_node_t *argument);

// Allocate and initialize a new ArrayNode node.
yp_node_t *
yp_array_node_create(yp_parser_t *parser, const yp_token_t *opening, const yp_token_t *closing);

// Return the size of the given array node.
size_t
yp_array_node_size(yp_node_t *node);

// Append an argument to an array node.
void
yp_array_node_append(yp_node_t *node, yp_node_t *element);

// Set the closing token and end location of an array node.
void
yp_array_node_close_set(yp_node_t *node, const yp_token_t *closing);

// Allocate and initialize a new assoc node.
yp_node_t *
yp_assoc_node_create(yp_parser_t *parser, yp_node_t *key, const yp_token_t *oper, yp_node_t *value);

// Allocate and initialize a new assoc splat node.
yp_node_t *
yp_assoc_splat_node_create(yp_parser_t *parser, yp_node_t *value, const yp_token_t *oper);

// Allocate and initialize new a begin node.
yp_node_t *
yp_begin_node_create(yp_parser_t *parser, const yp_token_t *begin_keyword, yp_node_t *statements);

// Set the rescue clause and end location of a begin node.
void
yp_begin_node_rescue_clause_set(yp_node_t *node, yp_node_t *rescue_clause);

// Set the else clause and end location of a begin node.
void
yp_begin_node_else_clause_set(yp_node_t *node, yp_node_t *else_clause);

// Set the ensure clause and end location of a begin node.
void
yp_begin_node_ensure_clause_set(yp_node_t *node, yp_node_t *ensure_clause);

// Set the end keyword and end location of a begin node.
void
yp_begin_node_end_keyword_set(yp_node_t *node, const yp_token_t *end_keyword);

// Allocate and initialize a new BlockParameterNode node.
yp_node_t *
yp_block_parameter_node_create(yp_parser_t *parser, const yp_token_t *name, const yp_token_t *oper);

// Allocate and initialize a new BreakNode node.
yp_node_t *
yp_break_node_create(yp_parser_t *parser, const yp_token_t *keyword, yp_node_t *arguments);

// This is a special out parameter to the parse_arguments_list function that
// includes opening and closing parentheses in addition to the arguments since
// it's so common. It is handy to use when passing argument information to one
// of the call node creation functions.
typedef struct {
  yp_token_t opening;
  yp_node_t *arguments;
  yp_token_t closing;
  yp_node_t *block;
} yp_arguments_t;

// Initialize a stack-allocated yp_arguments_t struct to its default values and
// return it.
yp_arguments_t
yp_arguments();

// Allocate and initialize a new CallNode node. This sets everything to NULL or
// YP_TOKEN_NOT_PROVIDED as appropriate such that its values can be overridden
// in the various specializations of this function.
yp_node_t *
yp_call_node_create(yp_parser_t *parser);

// Allocate and initialize a new CallNode node from an aref or an aset
// expression.
yp_node_t *
yp_call_node_aref_create(yp_parser_t *parser, yp_node_t *receiver, yp_arguments_t *arguments);

// Allocate and initialize a new CallNode node from a binary expression.
yp_node_t *
yp_call_node_binary_create(yp_parser_t *parser, yp_node_t *receiver, yp_token_t *oper, yp_node_t *argument);

// Allocate and initialize a new CallNode node from a call expression.
yp_node_t *
yp_call_node_call_create(yp_parser_t *parser, yp_node_t *receiver, yp_token_t *oper, yp_token_t *message, yp_arguments_t *arguments);

// Allocate and initialize a new CallNode node from a call to a method name
// without a receiver that could not have been a local variable read.
yp_node_t *
yp_call_node_fcall_create(yp_parser_t *parser, yp_token_t *message, yp_arguments_t *arguments);

// Allocate and initialize a new CallNode node from a not expression.
yp_node_t *
yp_call_node_not_create(yp_parser_t *parser, yp_node_t *receiver, yp_token_t *message, yp_arguments_t *arguments);

// Allocate and initialize a new CallNode node from a call shorthand expression.
yp_node_t *
yp_call_node_shorthand_create(yp_parser_t *parser, yp_node_t *receiver, yp_token_t *oper, yp_arguments_t *arguments);

// Allocate and initialize a new CallNode node from a unary operator expression.
yp_node_t *
yp_call_node_unary_create(yp_parser_t *parser, yp_token_t *oper, yp_node_t *receiver, const char *name);

// Allocate and initialize a new CallNode node from a call to a method name
// without a receiver that could also have been a local variable read.
yp_node_t *
yp_call_node_vcall_create(yp_parser_t *parser, yp_token_t *message);

// Returns whether or not this call node is a "vcall" (a call to a method name
// without a receiver that could also have been a local variable read).
bool
yp_call_node_vcall_p(yp_node_t *node);

// Allocate and initialize a new ClassVariableReadNode node.
yp_node_t *
yp_class_variable_read_node_create(yp_parser_t *parser, const yp_token_t *token);

// Initialize a new ClassVariableWriteNode node from a ClassVariableRead node.
yp_node_t *
yp_class_variable_write_node_init(yp_parser_t *parser, yp_node_t *node, yp_token_t *oper, yp_node_t *value);

// Allocate and initialize a new DefNode node.
yp_node_t *
yp_def_node_create(yp_parser_t *parser, const yp_token_t *name, yp_node_t *receiver, yp_node_t *parameters, yp_node_t *statements, yp_node_t *scope, const yp_token_t *def_keyword, const yp_token_t *oper, const yp_token_t *lparen, const yp_token_t *rparen, const yp_token_t *equal, const yp_token_t *end_keyword);

// Allocate and initialize a new FalseNode node.
yp_node_t *
yp_false_node_create(yp_parser_t *parser, const yp_token_t *token);

// Allocate and initialize a new FloatNode node.
yp_node_t *
yp_float_node_create(yp_parser_t *parser, const yp_token_t *token);

// Allocate and initialize a new ForNode node.
yp_node_t *
yp_for_node_create(yp_parser_t *parser, yp_node_t *index, yp_node_t *collection, yp_node_t *statements, const yp_token_t *for_keyword, const yp_token_t *in_keyword, const yp_token_t *do_keyword, const yp_token_t *end_keyword);

// Allocate and initialize a new ForwardingArgumentsNode node.
yp_node_t *
yp_forwarding_arguments_node_create(yp_parser_t *parser, const yp_token_t *token);

// Allocate and initialize a new ForwardingParameterNode node.
yp_node_t *
yp_forwarding_parameter_node_create(yp_parser_t *parser, const yp_token_t *token);

// Allocate and initialize a new ForwardingSuper node.
yp_node_t *
yp_forwarding_super_node_create(yp_parser_t *parser, const yp_token_t *token, yp_arguments_t *arguments);

// Allocate and initialize a new ImaginaryNode node.
yp_node_t *
yp_imaginary_node_create(yp_parser_t *parser, const yp_token_t *token);

// Allocate and initialize a new InstanceVariableReadNode node.
yp_node_t *
yp_instance_variable_read_node_create(yp_parser_t *parser, const yp_token_t *token);

// Initialize a new InstanceVariableWriteNode node from an InstanceVariableRead node.
yp_node_t *
yp_instance_variable_write_node_init(yp_parser_t *parser, yp_node_t *node, yp_token_t *oper, yp_node_t *value);

// Allocate and initialize a new IntegerNode node.
yp_node_t *
yp_integer_node_create(yp_parser_t *parser, const yp_token_t *token);

// Allocate and initialize a new InterpolatedStringNode node.
yp_node_t *
yp_interpolated_string_node_create(yp_parser_t *parser, const yp_token_t *opening, const yp_node_list_t *parts, const yp_token_t *closing);

// Allocate and initialize a new InterpolatedSymbolNode node.
yp_node_t *
yp_interpolated_symbol_node_create(yp_parser_t *parser, const yp_token_t *opening, const yp_node_list_t *parts, const yp_token_t *closing);

// Allocate and initialize a new NextNode node.
yp_node_t *
yp_next_node_create(yp_parser_t *parser, const yp_token_t *keyword, yp_node_t *arguments);

// Allocate and initialize a new NilNode node.
yp_node_t *
yp_nil_node_create(yp_parser_t *parser, const yp_token_t *token);

// Allocate and initialize a new NoKeywordsParameterNode node.
yp_node_t *
yp_no_keywords_parameter_node_create(yp_parser_t *parser, const yp_token_t *oper, const yp_token_t *keyword);

// Allocate and initialize a new OperatorAndAssignmentNode node.
yp_node_t *
yp_operator_and_assignment_node_create(yp_parser_t *parser, yp_node_t *target, const yp_token_t *oper, yp_node_t *value);

// Allocate and initialize a new PostExecutionNode node.
yp_node_t *
yp_post_execution_node_create(yp_parser_t *parser, const yp_token_t *keyword, const yp_token_t *opening, yp_node_t *statements, const yp_token_t *closing);

// Allocate and initialize a new PreExecutionNode node.
yp_node_t *
yp_pre_execution_node_create(yp_parser_t *parser, const yp_token_t *keyword, const yp_token_t *opening, yp_node_t *statements, const yp_token_t *closing);

// Allocate and initialize a new RationalNode node.
yp_node_t *
yp_rational_node_create(yp_parser_t *parser, const yp_token_t *token);

// Allocate and initialize a new RedoNode node.
yp_node_t *
yp_redo_node_create(yp_parser_t *parser, const yp_token_t *token);

// Allocate and initialize a new RetryNode node.
yp_node_t *
yp_retry_node_create(yp_parser_t *parser, const yp_token_t *token);

// Allocate and initialize a new SelfNode node.
yp_node_t *
yp_self_node_create(yp_parser_t *parser, const yp_token_t *token);

// Allocate and initialize a new SourceEncodingNode node.
yp_node_t *
yp_source_encoding_node_create(yp_parser_t *parser, const yp_token_t *token);

// Allocate and initialize a new SourceFileNode node.
yp_node_t *
yp_source_file_node_create(yp_parser_t *parser, const yp_token_t *token);

// Allocate and initialize a new SourceLineNode node.
yp_node_t *
yp_source_line_node_create(yp_parser_t *parser, const yp_token_t *token);

// Check if the given node is a label in a hash.
bool
yp_symbol_node_label_p(yp_node_t *node);

// Convert the given SymbolNode node to a StringNode node.
void
yp_symbol_node_to_string_node(yp_parser_t *parser, yp_node_t *node);

// Allocate and initialize a new SuperNode node.
yp_node_t *
yp_super_node_create(yp_parser_t *parser, const yp_token_t *keyword, yp_arguments_t *arguments);

// Allocate and initialize a new TrueNode node.
yp_node_t *
yp_true_node_create(yp_parser_t *parser, const yp_token_t *token);

// Allocate and initialize a new UndefNode node.
yp_node_t *
yp_undef_node_create(yp_parser_t *parser, const yp_token_t *token);

// Append a name to an undef node.
void
yp_undef_node_append(yp_node_t *node, yp_node_t *name);

// Allocate and initialize a new XStringNode node.
yp_node_t *
yp_xstring_node_create(yp_parser_t *parser, const yp_token_t *opening, const yp_token_t *content, const yp_token_t *closing);

#endif
