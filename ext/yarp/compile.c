#include "extension.h"

typedef enum {
  YP_ISEQ_TYPE_TOP,
  YP_ISEQ_TYPE_BLOCK,
  YP_ISEQ_TYPE_METHOD
} yp_iseq_type_t;

typedef enum {
  YP_RUBY_EVENT_B_CALL,
  YP_RUBY_EVENT_B_RETURN
} yp_ruby_event_t;

typedef struct yp_iseq_compiler {
  // This is the parent compiler. It is used to communicate between ISEQs that
  // need to be able to jump back to the parent ISEQ.
  struct yp_iseq_compiler *parent;

  // This is the list of local variables that are defined on this scope.
  yp_token_list_t *locals;

  // This is the instruction sequence that we are compiling. It's actually just
  // a Ruby array that maps to the output of RubyVM::InstructionSequence#to_a.
  VALUE insns;

  // list of byte offsets of newline characters in the string
  // used to find the line that a node starts on.
  char **newline_locations;

  // line last emitted as an event.
  // used to not repeat the line number
  int lineno;

  // This is a list of IDs coming from the instructions that are being compiled.
  // In theory they should be deterministic, but we don't have that
  // functionality yet. Fortunately you can pass -1 for all of them and
  // everything for the most part continues to work.
  VALUE node_ids;

  // This is the current size of the instruction sequence's stack.
  int stack_size;

  // This is the maximum size of the instruction sequence's stack.
  int stack_max;

  // This is the name of the instruction sequence.
  const char *name;

  // This is the type of the instruction sequence.
  yp_iseq_type_t type;

  // This is the current size of the instruction sequence's instructions and
  // operands.
  size_t size;

  // This is the index of the current inline storage.
  size_t inline_storage_index;
} yp_iseq_compiler_t;

static void
yp_iseq_compiler_init(yp_iseq_compiler_t *compiler, int lineno, char **newline_locations, yp_iseq_compiler_t *parent, yp_token_list_t *locals, const char *name, yp_iseq_type_t type) {
  *compiler = (yp_iseq_compiler_t) {
    .parent = parent,
    .lineno = lineno,
    .newline_locations = newline_locations,
    .locals = locals,
    .insns = rb_ary_new(),
    .node_ids = rb_ary_new(),
    .stack_size = 0,
    .stack_max = 0,
    .name = name,
    .type = type,
    .size = 0,
    .inline_storage_index = 0
  };
}

/******************************************************************************/
/* Utilities                                                                  */
/******************************************************************************/

static inline int
sizet2int(size_t value) {
  if (value > INT_MAX) rb_raise(rb_eRuntimeError, "value too large");
  return (int) value;
}

static inline int
local_index(yp_iseq_compiler_t *compiler, int depth, const char *start, const char *end) {
  int compiler_index;
  yp_iseq_compiler_t *local_compiler = compiler;

  for (compiler_index = 0; compiler_index < depth; compiler_index++) {
    local_compiler = local_compiler->parent;
  }

  size_t local_index;
  long local_size = end - start;

  for (local_index = 0; local_index < local_compiler->locals->size; local_index++) {
    yp_token_t *local = &local_compiler->locals->tokens[local_index];

    if ((local->end - local->start == local_size) && strncmp(local->start, start, local_size) == 0) {
      return sizet2int(local_compiler->locals->size - local_index + 2);
    }
  }

  return -1;
}

static inline int
node_line_number(yp_iseq_compiler_t *compiler, yp_node_t *node) {
  const char *start = node->location.start;

  // call nodes which are infix should use the message field for its line number
  if (node->type == YP_NODE_CALL_NODE) {
    start = node->as.call_node.message.start;
  }


  int index = 0;

  while (compiler->newline_locations[index] != NULL) {
    if (start < compiler->newline_locations[index]) {
      return index + 1;
    }
    index++;
  }
  return index;
}

/******************************************************************************/
/* Parse specific VALUEs from strings                                         */
/******************************************************************************/

static VALUE
parse_number(const char *start, const char *end) {
  size_t length = end - start;

  char *buffer = malloc(length + 1);
  memcpy(buffer, start, length);

  buffer[length] = '\0';
  VALUE number = rb_cstr_to_inum(buffer, -10, Qfalse);

  free(buffer);
  return number;
}

static inline VALUE
parse_string(yp_string_t *string) {
  return rb_str_new(yp_string_source(string), yp_string_length(string));
}

static inline ID
parse_symbol(const char *start, const char *end) {
  return rb_intern2(start, end - start);
}

static inline ID
parse_location_symbol(yp_location_t *location) {
  return parse_symbol(location->start, location->end);
}

static inline ID
parse_token_symbol(yp_token_t *token) {
  return parse_symbol(token->start, token->end);
}

static inline ID
parse_node_symbol(yp_node_t *node) {
  return parse_symbol(node->location.start, node->location.end);
}

static inline ID
parse_string_symbol(yp_string_t *string) {
  const char *start = yp_string_source(string);
  return parse_symbol(start, start + yp_string_length(string));
}

/******************************************************************************/
/* Create Ruby objects for compilation                                        */
/******************************************************************************/

static VALUE
yp_iseq_new(yp_iseq_compiler_t *compiler, yp_node_t *params) {
  VALUE code_locations = rb_ary_new_capa(4);
  rb_ary_push(code_locations, INT2FIX(1));
  rb_ary_push(code_locations, INT2FIX(0));
  rb_ary_push(code_locations, INT2FIX(1));
  rb_ary_push(code_locations, INT2FIX(0));

  VALUE data = rb_hash_new();
  rb_hash_aset(data, ID2SYM(rb_intern("arg_size")), INT2FIX(0));
  rb_hash_aset(data, ID2SYM(rb_intern("local_size")), INT2FIX(compiler->stack_max - 1));
  rb_hash_aset(data, ID2SYM(rb_intern("stack_max")), INT2FIX(compiler->stack_max));
  rb_hash_aset(data, ID2SYM(rb_intern("node_id")), INT2FIX(-1));
  rb_hash_aset(data, ID2SYM(rb_intern("code_locations")), code_locations);
  rb_hash_aset(data, ID2SYM(rb_intern("node_ids")), compiler->node_ids);

  VALUE type;
  switch (compiler->type) {
    case YP_ISEQ_TYPE_TOP:
      type = ID2SYM(rb_intern("top"));
      break;
    case YP_ISEQ_TYPE_BLOCK:
      type = ID2SYM(rb_intern("block"));
      break;

    case YP_ISEQ_TYPE_METHOD:
      type = ID2SYM(rb_intern("method"));
      break;
  }

  VALUE rb_locals = rb_ary_new();
  for (size_t i = 0; i < compiler->locals->size; i++) {
    rb_ary_push(rb_locals, ID2SYM(parse_token_symbol(&compiler->locals->tokens[i])));
  }

  VALUE rb_options = rb_hash_new();
  if (params) {
    size_t required_count = params->as.parameters_node.requireds.size;
    rb_hash_aset(rb_options, rb_str_new2("lead_num"), INT2NUM((int)required_count));
  }

  VALUE iseq = rb_ary_new_capa(13);
  rb_ary_push(iseq, rb_str_new_cstr("YARVInstructionSequence/SimpleDataFormat"));
  rb_ary_push(iseq, INT2FIX(3));
  rb_ary_push(iseq, INT2FIX(2));
  rb_ary_push(iseq, INT2FIX(1));
  rb_ary_push(iseq, data);
  rb_ary_push(iseq, rb_str_new_cstr(compiler->name));
  rb_ary_push(iseq, rb_str_new_cstr("<compiled>"));
  rb_ary_push(iseq, rb_str_new_cstr("<compiled>"));
  rb_ary_push(iseq, INT2FIX(1));
  rb_ary_push(iseq, type);
  rb_ary_push(iseq, rb_locals); // locals
  rb_ary_push(iseq, rb_options); // {:lead_num=>1, :ambiguous_param0=>true} what is this?
  rb_ary_push(iseq, rb_ary_new()); // what is this?

  rb_ary_push(iseq, compiler->insns);

  return iseq;
}

// static const int YP_CALLDATA_ARGS_SPLAT = 1 << 0;
// static const int YP_CALLDATA_ARGS_BLOCKARG = 1 << 1;
static const int YP_CALLDATA_FCALL = 1 << 2;
static const int YP_CALLDATA_VCALL = 1 << 3;
static const int YP_CALLDATA_ARGS_SIMPLE = 1 << 4;
// static const int YP_CALLDATA_BLOCKISEQ = 1 << 5;
// static const int YP_CALLDATA_KWARG = 1 << 6;
// static const int YP_CALLDATA_KW_SPLAT = 1 << 7;
// static const int YP_CALLDATA_TAILCALL = 1 << 8;
// static const int YP_CALLDATA_SUPER = 1 << 9;
// static const int YP_CALLDATA_ZSUPER = 1 << 10;
// static const int YP_CALLDATA_OPT_SEND = 1 << 11;
// static const int YP_CALLDATA_KW_SPLAT_MUT = 1 << 12;

static VALUE
yp_calldata_new(ID mid, int flag, size_t orig_argc) {
  VALUE calldata = rb_hash_new();

  rb_hash_aset(calldata, ID2SYM(rb_intern("mid")), ID2SYM(mid));
  rb_hash_aset(calldata, ID2SYM(rb_intern("flag")), INT2FIX(flag));
  rb_hash_aset(calldata, ID2SYM(rb_intern("orig_argc")), INT2FIX(orig_argc));

  return calldata;
}

static inline VALUE
yp_inline_storage_new(yp_iseq_compiler_t *compiler) {
  return INT2FIX(compiler->inline_storage_index++);
}

/******************************************************************************/
/* Push instructions onto a compiler                                          */
/******************************************************************************/

static VALUE
push_insn(yp_iseq_compiler_t *compiler, int stack_change, int lineno, size_t size, ...) {
  if (lineno != compiler->lineno) {
    compiler->lineno = lineno;
    rb_ary_push(compiler->insns, INT2NUM(lineno));
  }

  va_list opnds;
  va_start(opnds, size);

  VALUE insn = rb_ary_new_capa(size);
  for (size_t index = 0; index < size; index++) {
    rb_ary_push(insn, va_arg(opnds, VALUE));
  }

  va_end(opnds);

  compiler->stack_size += stack_change;
  if (compiler->stack_size > compiler->stack_max) {
    compiler->stack_max = compiler->stack_size;
  }

  compiler->size += size;
  rb_ary_push(compiler->insns, insn);
  rb_ary_push(compiler->node_ids, INT2FIX(-1));

  return insn;
}

static VALUE
push_label(yp_iseq_compiler_t *compiler) {
  VALUE label = ID2SYM(rb_intern_str(rb_sprintf("label_%zu", compiler->size)));
  rb_ary_push(compiler->insns, label);
  return label;
}

static void
push_ruby_event(yp_iseq_compiler_t *compiler, yp_ruby_event_t event) {
  switch (event) {
    case YP_RUBY_EVENT_B_CALL:
      rb_ary_push(compiler->insns, ID2SYM(rb_intern("RUBY_EVENT_B_CALL")));
      break;
    case YP_RUBY_EVENT_B_RETURN:
      rb_ary_push(compiler->insns, ID2SYM(rb_intern("RUBY_EVENT_B_RETURN")));
      break;
  }
}

static inline VALUE
push_anytostring(yp_iseq_compiler_t *compiler, int lineno) {
  return push_insn(compiler, -2 + 1, lineno, 1, ID2SYM(rb_intern("anytostring")));
}

static inline VALUE
push_branchif(yp_iseq_compiler_t *compiler, int lineno, VALUE label) {
  return push_insn(compiler, -1 + 0, lineno, 2, ID2SYM(rb_intern("branchif")), label);
}

static inline VALUE
push_branchunless(yp_iseq_compiler_t *compiler, int lineno, VALUE label) {
  return push_insn(compiler, -1 + 0, lineno, 2, ID2SYM(rb_intern("branchunless")), label);
}

static inline VALUE
push_concatstrings(yp_iseq_compiler_t *compiler, int lineno, int count) {
  return push_insn(compiler, -count + 1, lineno, 2, ID2SYM(rb_intern("concatstrings")), INT2FIX(count));
}

static inline VALUE
push_definemethod(yp_iseq_compiler_t *compiler, int lineno, VALUE name, VALUE method_iseq) {
  return push_insn(compiler, -1 + 2, lineno, 3, ID2SYM(rb_intern("definemethod")), name, method_iseq);
}

static inline VALUE
push_dup(yp_iseq_compiler_t *compiler, int lineno) {
  return push_insn(compiler, -1 + 2, lineno, 1, ID2SYM(rb_intern("dup")));
}

static inline VALUE
push_getclassvariable(yp_iseq_compiler_t *compiler, int lineno, VALUE name, VALUE inline_storage) {
  return push_insn(compiler, -0 + 1, lineno, 3, ID2SYM(rb_intern("getclassvariable")), name, inline_storage);
}

static inline VALUE
push_getconstant(yp_iseq_compiler_t *compiler, int lineno, VALUE name) {
  return push_insn(compiler, -2 + 1, lineno, 2, ID2SYM(rb_intern("getconstant")), name);
}

static inline VALUE
push_getglobal(yp_iseq_compiler_t *compiler, int lineno, VALUE name) {
  return push_insn(compiler, -0 + 1, lineno, 2, ID2SYM(rb_intern("getglobal")), name);
}

static inline VALUE
push_getinstancevariable(yp_iseq_compiler_t *compiler, int lineno, VALUE name, VALUE inline_storage) {
  return push_insn(compiler, -0 + 1, lineno, 3, ID2SYM(rb_intern("getinstancevariable")), name, inline_storage);
}

static inline VALUE
push_getlocal(yp_iseq_compiler_t *compiler, int lineno, VALUE index, VALUE depth) {
  return push_insn(compiler, -0 + 1, lineno, 3, ID2SYM(rb_intern("getlocal")), index, depth);
}

static inline VALUE
push_leave(yp_iseq_compiler_t *compiler, int lineno) {
  return push_insn(compiler, -1 + 0, lineno, 1, ID2SYM(rb_intern("leave")));
}

static inline VALUE
push_newarray(yp_iseq_compiler_t *compiler, int lineno, int count) {
  return push_insn(compiler, -count + 1, lineno, 2, ID2SYM(rb_intern("newarray")), INT2FIX(count));
}

static inline VALUE
push_newhash(yp_iseq_compiler_t *compiler, int lineno, int count) {
  return push_insn(compiler, -count + 1, lineno, 2, ID2SYM(rb_intern("newhash")), INT2FIX(count));
}

static inline VALUE
push_newrange(yp_iseq_compiler_t *compiler, int lineno, VALUE flag) {
  return push_insn(compiler, -2 + 1, lineno, 2, ID2SYM(rb_intern("newrange")), flag);
}

static inline VALUE
push_objtostring(yp_iseq_compiler_t *compiler, int lineno, VALUE calldata) {
  return push_insn(compiler, -1 + 1, lineno, 2, ID2SYM(rb_intern("objtostring")), calldata);
}

static inline VALUE
push_pop(yp_iseq_compiler_t *compiler, int lineno) {
  return push_insn(compiler, -1 + 0, lineno, 1, ID2SYM(rb_intern("pop")));
}

static inline VALUE
push_putnil(yp_iseq_compiler_t *compiler, int lineno) {
  return push_insn(compiler, -0 + 1, lineno, 1, ID2SYM(rb_intern("putnil")));
}

static inline VALUE
push_putobject(yp_iseq_compiler_t *compiler, int lineno, VALUE value) {
  return push_insn(compiler, -0 + 1, lineno, 2, ID2SYM(rb_intern("putobject")), value);
}

static inline VALUE
push_putself(yp_iseq_compiler_t *compiler, int lineno) {
  return push_insn(compiler, -0 + 1, lineno, 1, ID2SYM(rb_intern("putself")));
}

static inline VALUE
push_setlocal(yp_iseq_compiler_t *compiler, int lineno, VALUE index, VALUE depth) {
  return push_insn(compiler, -1 + 0, lineno, 3, ID2SYM(rb_intern("setlocal")), index, depth);
}

static const VALUE YP_SPECIALOBJECT_VMCORE = INT2FIX(1);
static const VALUE YP_SPECIALOBJECT_CBASE = INT2FIX(2);
// static const VALUE YP_SPECIALOBJECT_CONST_BASE = INT2FIX(3);

static inline VALUE
push_putspecialobject(yp_iseq_compiler_t *compiler, int lineno, VALUE object) {
  return push_insn(compiler, -0 + 1, lineno, 2, ID2SYM(rb_intern("putspecialobject")), object);
}

static inline VALUE
push_putstring(yp_iseq_compiler_t *compiler, int lineno, VALUE string) {
  return push_insn(compiler, -0 + 1, lineno, 2, ID2SYM(rb_intern("putstring")), string);
}

static inline VALUE
push_send(yp_iseq_compiler_t *compiler, int lineno, int stack_change, VALUE calldata, VALUE block_iseq) {
  return push_insn(compiler, stack_change, lineno, 3, ID2SYM(rb_intern("send")), calldata, block_iseq);
}

static inline VALUE
push_setclassvariable(yp_iseq_compiler_t *compiler, int lineno, VALUE name, VALUE inline_storage) {
  return push_insn(compiler, -1 + 0, lineno, 3, ID2SYM(rb_intern("setclassvariable")), name, inline_storage);
}

static inline VALUE
push_setglobal(yp_iseq_compiler_t *compiler, int lineno, VALUE name) {
  return push_insn(compiler, -1 + 0, lineno, 2, ID2SYM(rb_intern("setglobal")), name);
}

static inline VALUE
push_setinstancevariable(yp_iseq_compiler_t *compiler, int lineno, VALUE name, VALUE inline_storage) {
  return push_insn(compiler, -1 + 0, lineno, 3, ID2SYM(rb_intern("setinstancevariable")), name, inline_storage);
}

/******************************************************************************/
/* Compile an AST node using the given compiler                               */
/******************************************************************************/

static void
yp_compile_node(yp_iseq_compiler_t *compiler, yp_node_t *node);

static void
yp_compile_node(yp_iseq_compiler_t *compiler, yp_node_t *node) {
  switch (node->type) {
    case YP_NODE_ALIAS_NODE:
      push_putspecialobject(compiler, node_line_number(compiler, node), YP_SPECIALOBJECT_VMCORE);
      push_putspecialobject(compiler, node_line_number(compiler, node), YP_SPECIALOBJECT_CBASE);
      yp_compile_node(compiler, node->as.alias_node.new_name);
      yp_compile_node(compiler, node->as.alias_node.old_name);
      push_send(compiler, node_line_number(compiler, node), -3, yp_calldata_new(rb_intern("core#set_method_alias"), YP_CALLDATA_ARGS_SIMPLE, 3), Qnil);
      return;
    case YP_NODE_AND_NODE: {
      yp_compile_node(compiler, node->as.and_node.left);
      push_dup(compiler, node_line_number(compiler, node));
      VALUE branchunless = push_branchunless(compiler, node_line_number(compiler, node), Qnil);

      push_pop(compiler, node_line_number(compiler, node));
      yp_compile_node(compiler, node->as.and_node.right);

      VALUE label = push_label(compiler);
      rb_ary_store(branchunless, 1, label);

      return;
    }
    case YP_NODE_ARGUMENTS_NODE: {
      yp_node_list_t node_list = node->as.arguments_node.arguments;
      for (size_t index = 0; index < node_list.size; index++) {
        yp_compile_node(compiler, node_list.nodes[index]);
      }
      return;
    }
    case YP_NODE_ARRAY_NODE: {
      yp_node_list_t elements = node->as.array_node.elements;
      for (size_t index = 0; index < elements.size; index++) {
        yp_compile_node(compiler, elements.nodes[index]);
      }
      push_newarray(compiler, node_line_number(compiler, node), sizet2int(elements.size));
      return;
    }
    case YP_NODE_ASSOC_NODE:
      yp_compile_node(compiler, node->as.assoc_node.key);
      yp_compile_node(compiler, node->as.assoc_node.value);
      return;
    case YP_NODE_BLOCK_NODE:
      push_ruby_event(compiler, YP_RUBY_EVENT_B_CALL);
      if (node->as.block_node.statements) {
        yp_compile_node(compiler, node->as.block_node.statements);
      } else {
        push_putnil(compiler, node_line_number(compiler, node));
      }
      push_ruby_event(compiler, YP_RUBY_EVENT_B_RETURN);
      push_leave(compiler, node_line_number(compiler, node));
      return;
    case YP_NODE_CALL_NODE: {
      ID mid = parse_token_symbol(&node->as.call_node.message);
      int flags = 0;
      size_t orig_argc;

      if (node->as.call_node.receiver == NULL) {
        push_putself(compiler, node_line_number(compiler, node));
      } else {
        yp_compile_node(compiler, node->as.call_node.receiver);
      }

      if (node->as.call_node.arguments == NULL) {
        if (flags & YP_CALLDATA_FCALL) flags |= YP_CALLDATA_VCALL;
        orig_argc = 0;
      } else {
        yp_node_t *arguments = node->as.call_node.arguments;
        yp_compile_node(compiler, arguments);
        orig_argc = arguments->as.arguments_node.arguments.size;
      }

      VALUE block_iseq = Qnil;
      if (node->as.call_node.block != NULL) {
        int ln = node_line_number(compiler, node);

        yp_iseq_compiler_t block_compiler;
        yp_iseq_compiler_init(
          &block_compiler,
          ln,
          compiler->newline_locations,
          compiler,
          &node->as.call_node.block->as.block_node.scope->as.scope.locals,
          "block in <compiled>",
          YP_ISEQ_TYPE_BLOCK
        );

        rb_ary_push(block_compiler.insns, INT2NUM(ln));
        rb_ary_push(block_compiler.insns, ID2SYM(rb_intern("RUBY_EVENT_LINE")));

        yp_compile_node(&block_compiler, node->as.call_node.block);
        block_iseq = yp_iseq_new(&block_compiler, node->as.call_node.block->as.block_node.parameters);
      }

      if (block_iseq == Qnil && flags == 0) {
        flags |= YP_CALLDATA_ARGS_SIMPLE;
      }

      if (node->as.call_node.receiver == NULL) {
        flags |= YP_CALLDATA_FCALL;

        if (block_iseq == Qnil && node->as.call_node.arguments == NULL) {
          flags |= YP_CALLDATA_VCALL;
        }
      }



      push_send(compiler, node_line_number(compiler, node), -sizet2int(orig_argc), yp_calldata_new(mid, flags, orig_argc), block_iseq);
      return;
    }
    case YP_NODE_CLASS_VARIABLE_READ_NODE:
      push_getclassvariable(compiler, node_line_number(compiler, node), ID2SYM(parse_node_symbol(node)), yp_inline_storage_new(compiler));
      return;
    case YP_NODE_CLASS_VARIABLE_WRITE_NODE:
      if (node->as.class_variable_write_node.value == NULL) {
        rb_raise(rb_eNotImpError, "class variable write without value not implemented");
      }

      yp_compile_node(compiler, node->as.class_variable_write_node.value);
      push_setclassvariable(compiler, node_line_number(compiler, node), ID2SYM(parse_location_symbol(&node->as.class_variable_write_node.name_loc)), yp_inline_storage_new(compiler));
      return;
    case YP_NODE_CONSTANT_PATH_NODE:
      yp_compile_node(compiler, node->as.constant_path_node.parent);
      push_putobject(compiler, node_line_number(compiler, node), Qfalse);
      push_getconstant(compiler, node_line_number(compiler, node), ID2SYM(parse_node_symbol(node->as.constant_path_node.child)));
      return;
    case YP_NODE_CONSTANT_READ_NODE:
      push_putnil(compiler, node_line_number(compiler, node));
      push_putobject(compiler, node_line_number(compiler, node), Qtrue);
      push_getconstant(compiler, node_line_number(compiler, node), ID2SYM(parse_node_symbol(node)));
      return;
    case YP_NODE_FALSE_NODE:
      push_putobject(compiler, node_line_number(compiler, node), Qfalse);
      return;
    case YP_NODE_GLOBAL_VARIABLE_READ_NODE:
      push_getglobal(compiler, node_line_number(compiler, node), ID2SYM(parse_token_symbol(&node->as.global_variable_read_node.name)));
      return;
    case YP_NODE_GLOBAL_VARIABLE_WRITE_NODE:
      if (node->as.global_variable_write_node.value == NULL) {
        rb_raise(rb_eNotImpError, "global variable write without value not implemented");
      }

      yp_compile_node(compiler, node->as.global_variable_write_node.value);
      push_dup(compiler, node_line_number(compiler, node));
      push_setglobal(compiler, node_line_number(compiler, node), ID2SYM(parse_token_symbol(&node->as.global_variable_write_node.name)));
      return;
    case YP_NODE_HASH_NODE: {
      yp_node_list_t elements = node->as.hash_node.elements;

      for (size_t index = 0; index < elements.size; index++) {
        yp_compile_node(compiler, elements.nodes[index]);
      }

      push_newhash(compiler, node_line_number(compiler, node), sizet2int(elements.size * 2));
      return;
    }
    case YP_NODE_INSTANCE_VARIABLE_READ_NODE:
      push_getinstancevariable(compiler, node_line_number(compiler, node), ID2SYM(parse_node_symbol(node)), yp_inline_storage_new(compiler));
      return;
    case YP_NODE_INSTANCE_VARIABLE_WRITE_NODE:
      if (node->as.instance_variable_write_node.value == NULL) {
        rb_raise(rb_eNotImpError, "instance variable write without value not implemented");
      }

      yp_compile_node(compiler, node->as.instance_variable_write_node.value);
      push_dup(compiler, node_line_number(compiler, node));
      push_setinstancevariable(compiler, node_line_number(compiler, node), ID2SYM(parse_location_symbol(&node->as.instance_variable_write_node.name_loc)), yp_inline_storage_new(compiler));
      return;
    case YP_NODE_INTEGER_NODE:
      push_putobject(compiler, node_line_number(compiler, node), parse_number(node->location.start, node->location.end));
      return;
    case YP_NODE_INTERPOLATED_STRING_NODE: {
      yp_node_list_t parts = node->as.interpolated_string_node.parts;

      for (size_t index = 0; index < parts.size; index++) {
        yp_node_t *part = parts.nodes[index];

        switch (part->type) {
          case YP_NODE_STRING_NODE:
            push_putobject(compiler, node_line_number(compiler, node), parse_string(&part->as.string_node.unescaped));
            break;
          default:
            yp_compile_node(compiler, part);
            push_dup(compiler, node_line_number(compiler, node));
            push_objtostring(compiler, node_line_number(compiler, node), yp_calldata_new(rb_intern("to_s"), YP_CALLDATA_FCALL | YP_CALLDATA_ARGS_SIMPLE, 0));
            push_anytostring(compiler, node_line_number(compiler, node));
            break;
        }
      }

      push_concatstrings(compiler, node_line_number(compiler, node), sizet2int(parts.size));
      return;
    }
    case YP_NODE_LOCAL_VARIABLE_READ_NODE: {
      int depth = node->as.local_variable_read_node.depth;
      int index = local_index(
        compiler,
        depth,
        node->as.local_variable_read_node.name.start,
        node->as.local_variable_read_node.name.end
      );

      push_getlocal(compiler, node_line_number(compiler, node), INT2FIX(index), INT2FIX(depth));
      return;
    }
    case YP_NODE_LOCAL_VARIABLE_WRITE_NODE: {
      if (node->as.local_variable_write_node.value == NULL) {
        rb_raise(rb_eNotImpError, "local variable write without value not implemented");
      }

      int depth = node->as.local_variable_write_node.depth;
      int index = local_index(
        compiler,
        depth,
        node->as.local_variable_write_node.name.start,
        node->as.local_variable_write_node.name.end
      );

      yp_compile_node(compiler, node->as.local_variable_write_node.value);
      push_dup(compiler, node_line_number(compiler, node));
      push_setlocal(compiler, node_line_number(compiler, node), INT2FIX(index), INT2FIX(depth));
      return;
    }
    case YP_NODE_NIL_NODE:
      push_putnil(compiler, node_line_number(compiler, node));
      return;
    case YP_NODE_OR_NODE: {
      yp_compile_node(compiler, node->as.or_node.left);
      push_dup(compiler, node_line_number(compiler, node));
      VALUE branchif = push_branchif(compiler, node_line_number(compiler, node), Qnil);

      push_pop(compiler, node_line_number(compiler, node));
      yp_compile_node(compiler, node->as.and_node.right);

      VALUE label = push_label(compiler);
      rb_ary_store(branchif, 1, label);

      return;
    }
    case YP_NODE_PROGRAM_NODE:
      yp_compile_node(compiler, node->as.program_node.statements);
      push_leave(compiler, node_line_number(compiler, node));
      return;
    case YP_NODE_RANGE_NODE:
      if (node->as.range_node.left == NULL) {
        push_putnil(compiler, node_line_number(compiler, node));
      } else {
        yp_compile_node(compiler, node->as.range_node.left);
      }

      if (node->as.range_node.right == NULL) {
        push_putnil(compiler, node_line_number(compiler, node));
      } else {
        yp_compile_node(compiler, node->as.range_node.right);
      }

      yp_location_t operator_loc = node->as.range_node.operator_loc;
      push_newrange(compiler, node_line_number(compiler, node), INT2FIX((operator_loc.end - operator_loc.start) == 3));
      return;
    case YP_NODE_SELF_NODE:
      push_putself(compiler, node_line_number(compiler, node));
      return;
    case YP_NODE_STATEMENTS_NODE: {
      yp_node_list_t node_list = node->as.statements_node.body;
      for (size_t index = 0; index < node_list.size; index++) {
        yp_compile_node(compiler, node_list.nodes[index]);
        if (index < node_list.size - 1) push_pop(compiler, node_line_number(compiler, node));
      }
      return;
    }
    case YP_NODE_STRING_NODE:
      push_putstring(compiler, node_line_number(compiler, node), parse_string(&node->as.string_node.unescaped));
      return;
    case YP_NODE_STRING_INTERPOLATED_NODE:
      yp_compile_node(compiler, node->as.string_interpolated_node.statements);
      return;
    case YP_NODE_SYMBOL_NODE:
      push_putobject(compiler, node_line_number(compiler, node), ID2SYM(parse_string_symbol(&node->as.symbol_node.unescaped)));
      return;
    case YP_NODE_TRUE_NODE:
      push_putobject(compiler, node_line_number(compiler, node), Qtrue);
      return;
    case YP_NODE_UNDEF_NODE: {
      yp_node_list_t *node_list = &node->as.undef_node.names;

      for (size_t index = 0; index < node_list->size; index++) {
        push_putspecialobject(compiler, node_line_number(compiler, node), YP_SPECIALOBJECT_VMCORE);
        push_putspecialobject(compiler, node_line_number(compiler, node), YP_SPECIALOBJECT_CBASE);
        yp_compile_node(compiler, node_list->nodes[index]);
        push_send(compiler, node_line_number(compiler, node), -2, yp_calldata_new(rb_intern("core#undef_method"), YP_CALLDATA_ARGS_SIMPLE, 2), Qnil);

        if (index < node_list->size - 1) push_pop(compiler, node_line_number(compiler, node));
      }

      return;
    }
    case YP_NODE_X_STRING_NODE:
      push_putself(compiler, node_line_number(compiler, node));
      push_putobject(compiler, node_line_number(compiler, node), parse_string(&node->as.x_string_node.unescaped));
      push_send(compiler, node_line_number(compiler, node), -1, yp_calldata_new(rb_intern("`"), YP_CALLDATA_FCALL | YP_CALLDATA_ARGS_SIMPLE, 1), Qnil);
      return;

    case YP_NODE_DEF_NODE: {
      const char * start = node->as.def_node.name.start;
      const char * end = node->as.def_node.name.end;

      size_t length = end - start;
      char *name = malloc(length + 1);
      memcpy(name, start, length);

      name[length] = '\0';
      VALUE rb_name = ID2SYM(parse_token_symbol(&node->as.def_node.name));
      int ln = node_line_number(compiler, node);

      yp_iseq_compiler_t method_compiler;
      yp_iseq_compiler_init(
        &method_compiler,
        ln,
        compiler->newline_locations,
        compiler,
        &node->as.def_node.scope->as.scope.locals,
        name,
        YP_ISEQ_TYPE_METHOD
      );

      rb_ary_push(method_compiler.insns, INT2NUM(ln));
      rb_ary_push(method_compiler.insns, ID2SYM(rb_intern("RUBY_EVENT_LINE")));

      // optional arguments
      if (node->as.def_node.parameters->as.parameters_node.optionals.size > 0) {
        yp_node_list_t optionals = node->as.def_node.parameters->as.parameters_node.optionals;
        for (int i = 0; i < optionals.size; i++) {
          push_label(&method_compiler);
          yp_compile_node(&method_compiler, optionals.nodes[i]);
        }
        push_label(&method_compiler);
      }


      if (node->as.def_node.statements != NULL && node->as.def_node.statements->as.statements_node.body.size > 0) {
        yp_compile_node(&method_compiler, node->as.def_node.statements);
      } else {
        push_putnil(&method_compiler, node_line_number(compiler, node));
      }

      // TODO: this line number uses the end not the start.
      push_leave(&method_compiler, node_line_number(compiler, node));

      VALUE method_iseq = yp_iseq_new(&method_compiler, node->as.def_node.parameters);
      push_definemethod(compiler, node_line_number(compiler, node), rb_name, method_iseq);
      push_putobject(compiler, node_line_number(compiler, node), rb_name);
      return;
    }
    case YP_NODE_OPTIONAL_PARAMETER_NODE: {
      // Optional parameter depth is always 0
      int depth = 0;
      int index = local_index(
                              compiler,
                              depth,
                              node->as.optional_parameter_node.name.start,
                              node->as.optional_parameter_node.name.end
                              );

      yp_compile_node(compiler, node->as.optional_parameter_node.value);
      push_setlocal(compiler, 0, INT2FIX(index), INT2FIX(depth));
      /* push_putobject(compiler, node_line_number(compiler, node),  */
      return;
    }
    default:
      rb_raise(rb_eNotImpError, "node type %d not implemented", node->type);

      return;
  }
}

// This function compiles the given node into a list of instructions.
VALUE
yp_compile(yp_node_t *node, char **newline_locations) {
  yp_iseq_compiler_t compiler;

  int ln = node_line_number(&compiler, node);

  yp_iseq_compiler_init(
    &compiler,
    ln,
    newline_locations,
    NULL,
    &node->as.program_node.scope->as.scope.locals,
    "<compiled>",
    YP_ISEQ_TYPE_TOP
  );

  rb_ary_push(compiler.insns, INT2NUM(ln));
  rb_ary_push(compiler.insns, ID2SYM(rb_intern("RUBY_EVENT_LINE")));

  yp_compile_node(&compiler, node);
  return yp_iseq_new(&compiler, NULL);
}
