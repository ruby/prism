#ifndef YARP_H
#define YARP_H

#include "location.h"
#include "token.h"
#include <fcntl.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

// When lexing Ruby source, the lexer has a small amount of state to tell which
// kind of token it is currently lexing. For example, when we find the start of
// a string, the first token that we return is a TOKEN_STRING_BEGIN token. After
// that the lexer is now in the YP_LEX_STRING mode, and will return tokens that
// are found as part of a string.
typedef struct yp_lex_mode {
  enum {
    // This state is used when any given token is being lexed.
    YP_LEX_DEFAULT,

    // This state is used when we're lexing an embdoc (a =begin..=end comment).
    YP_LEX_EMBDOC,

    // This state is used when we're lexing as normal but inside an embedded
    // expression of a string.
    YP_LEX_EMBEXPR,

    // This state is used when we are lexing a list of tokens, as in a %w word
    // list literal or a %i symbol list literal.
    YP_LEX_LIST,

    // This state is used when a regular expression has been begun and we are
    // looking for the terminator.
    YP_LEX_REGEXP,

    // This state is used when we are lexing a string or a string-like token, as
    // in string content with either quote or an xstring.
    YP_LEX_STRING,

    // This state is used when a symbol has already been begun (e.g., by a
    // colon) and we still need to lex the rest of the symbol.
    YP_LEX_SYMBOL,
  } mode;

  // This is the terminator of the current state. It is used when lexing a
  // string (either single or double quoted) and an xstring.
  char term;

  // Whether or not interpolation is allowed in this lex state. This corresponds
  // to some LEX_LIST states (e.g., %W) and LEX_STRING states (e.g., double
  // quotes).
  bool interp;

  // The previous lex state so that it knows how to pop.
  struct yp_lex_mode *prev;
} yp_lex_mode_t;

// We pre-allocate a certain number of lex states in order to avoid having to
// call malloc too many times while parsing. You really shouldn't need more than
// this because you only really nest deeply when doing string interpolation.
#define YP_LEX_STACK_SIZE 4

// A forward declaration since our error handler struct accepts a parser for
// each of its function calls.
typedef struct yp_parser yp_parser_t;

// This struct is for handling error recovery. We're going to provide our own
// implementation for default, but this is an extension point if folks want to
// provide their own.
//
// Each function is going to be provided with a pointer to the struct itself, at
// which point it is expected to set the parsers state to whatever it should be
// in order to recover from the error. If it can't recover, it should return
// TOKEN_INVALID.
typedef struct {
  yp_token_type_t (*unterminated_embdoc)(yp_parser_t *parser);
  yp_token_type_t (*unterminated_list)(yp_parser_t *parser);
  yp_token_type_t (*unterminated_regexp)(yp_parser_t *parser);
  yp_token_type_t (*unterminated_string)(yp_parser_t *parser);
} yp_error_handler_t;

// This struct represents the overall parser. It contains a reference to the
// source file, as well as pointers that indicate where in the source it's
// currently parsing. It also contains the most recent and current token that
// it's considering.
struct yp_parser {
  struct {
    yp_lex_mode_t *current;                 // the current state of the lexer
    yp_lex_mode_t stack[YP_LEX_STACK_SIZE]; // the stack of lexer states
    size_t index;                           // the current index into the lexer state stack
  } lex_modes;

  const char *start;   // the pointer to the start of the source
  const char *end;     // the pointer to the end of the source
  yp_token_t previous; // the previous token we were considering
  yp_token_t current;  // the current token we're considering
  int lineno;          // the current line number we're looking at

  yp_error_handler_t *error_handler; // the error handler
};

struct yp_node;
typedef struct yp_node_list {
  struct yp_node **nodes;
  size_t size;
  size_t capacity;
} yp_node_list_t;

/******************************************************************************/
/* BEGIN TEMPLATE                                                             */
/******************************************************************************/

typedef enum {
  YP_NODE_ASSIGNMENT,
  YP_NODE_BINARY,
  YP_NODE_CHARACTER_LITERAL,
  YP_NODE_FLOAT_LITERAL,
  YP_NODE_IDENTIFIER,
  YP_NODE_IF_MODIFIER,
  YP_NODE_IMAGINARY_LITERAL,
  YP_NODE_INTEGER_LITERAL,
  YP_NODE_OPERATOR_ASSIGNMENT,
  YP_NODE_PROGRAM,
  YP_NODE_RATIONAL_LITERAL,
  YP_NODE_REDO,
  YP_NODE_RETRY,
  YP_NODE_STATEMENTS,
  YP_NODE_TERNARY,
  YP_NODE_UNLESS_MODIFIER,
  YP_NODE_UNTIL_MODIFIER,
  YP_NODE_VARIABLE_REFERENCE,
  YP_NODE_WHILE_MODIFIER,
} yp_node_type_t;

// This is the overall tagged union representing a node in the syntax tree.
typedef struct yp_node {
  // This represents the type of the node. It somewhat maps to the nodes that
  // existed in the original grammar and ripper, but it's not a 1:1 mapping.
  yp_node_type_t type;

  // This is the location of the node in the source. It's a range of bytes
  // containing a start and an end.
  yp_location_t location;

  // Every entry in this union is a different kind of node in the tree. For
  // the most part they only contain one or two child nodes, except for the
  // more complicated nodes like params. There may be an opportunity for
  // optimization here by combining node types that share the same shape, but
  // it might not end up mattering in the final compiled code.
  union {
    // Assignment
    struct {
      struct yp_node *target;
      yp_token_t operator;
      struct yp_node *value;
    } assignment;

    // Binary
    struct {
      struct yp_node *left;
      yp_token_t operator;
      struct yp_node *right;
    } binary;

    // CharacterLiteral
    struct {
      yp_token_t value;
    } character_literal;

    // FloatLiteral
    struct {
      yp_token_t value;
    } float_literal;

    // Identifier
    struct {
      yp_token_t value;
    } identifier;

    // IfModifier
    struct {
      struct yp_node *statement;
      yp_token_t keyword;
      struct yp_node *predicate;
    } if_modifier;

    // ImaginaryLiteral
    struct {
      yp_token_t value;
    } imaginary_literal;

    // IntegerLiteral
    struct {
      yp_token_t value;
    } integer_literal;

    // OperatorAssignment
    struct {
      struct yp_node *target;
      yp_token_t operator;
      struct yp_node *value;
    } operator_assignment;

    // Program
    struct {
      struct yp_node *statements;
    } program;

    // RationalLiteral
    struct {
      yp_token_t value;
    } rational_literal;

    // Redo
    struct {
      yp_token_t value;
    } redo;

    // Retry
    struct {
      yp_token_t value;
    } retry;

    // Statements
    struct {
      struct yp_node_list *body;
    } statements;

    // Ternary
    struct {
      struct yp_node *predicate;
      yp_token_t question_mark;
      struct yp_node *true_expression;
      yp_token_t colon;
      struct yp_node *false_expression;
    } ternary;

    // UnlessModifier
    struct {
      struct yp_node *statement;
      yp_token_t keyword;
      struct yp_node *predicate;
    } unless_modifier;

    // UntilModifier
    struct {
      struct yp_node *statement;
      yp_token_t keyword;
      struct yp_node *predicate;
    } until_modifier;

    // VariableReference
    struct {
      yp_token_t value;
    } variable_reference;

    // WhileModifier
    struct {
      struct yp_node *statement;
      yp_token_t keyword;
      struct yp_node *predicate;
    } while_modifier;
  } as;
} yp_node_t;

/******************************************************************************/
/* END TEMPLATE                                                               */
/******************************************************************************/

// Initialize a parser with the given start and end pointers.
void
yp_parser_init(yp_parser_t *parser, const char *source, off_t size);

// Get the next token type and set its value on the current pointer.
void
yp_lex_token(yp_parser_t *parser);

// Parse the Ruby source associated with the given parser and return the tree.
yp_node_t *
yp_parse(yp_parser_t *parser);

// Deallocate a node and all of its children.
void
yp_node_dealloc(yp_parser_t *parser, struct yp_node *node);

#endif
