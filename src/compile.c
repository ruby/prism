#include "prism/compile.h"

#include "prism/internal/allocator.h"
#include "prism/node.h"

#include <assert.h>
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

typedef enum {
    kPrismInsnBranch,
    kPrismInsnBranchIf,
    kPrismInsnCall,
    kPrismInsnDefinedGVar,
    kPrismInsnLoadCVar,
    kPrismInsnLoadGVar,
    kPrismInsnLoadIVar,
    kPrismInsnLoadObject,
    kPrismInsnLoadSelf,
    kPrismInsnReturn,
    kPrismInsnStoreCVar,
    kPrismInsnStoreGVar,
    kPrismInsnStoreIVar
} PrismInsnKind;

typedef struct {
    PrismInsnKind kind;
    uint32_t node_id;
    pm_location_t location;
    uint32_t opnds_off;
    uint32_t opnds_len;
    union {
        struct { uint32_t block_id; } branch;
        struct { uint32_t then_block_id; uint32_t else_block_id; uint32_t then_opnds_len; } branchif;
        struct { pm_constant_id_t name_id; } name;
        struct { uint32_t object_id; } object;
    } as;
} PrismInsn;

typedef struct {
    PrismInsn *insns;
    uint32_t *params;
    uint32_t ninsns;
    uint32_t nparams;
    uint32_t insns_capa;
} PrismBlock;

typedef enum {
    kPrismObjectFalse,
    kPrismObjectFloat,
    kPrismObjectInteger,
    kPrismObjectNil,
    kPrismObjectSymbol,
    kPrismObjectTrue
} PrismObjectKind;

typedef struct {
    PrismObjectKind kind;
    union {
        struct { double value; } floating;
        struct { const pm_integer_t *value; } integer;
        struct { pm_node_flags_t flags; const pm_string_t *unescaped; } symbol;
    } as;
} PrismObject;

typedef struct {
    PrismBlock *blocks;
    uint32_t *opnds;
    PrismObject *objects;
    uint32_t nblocks;
    uint32_t nopnds;
    uint32_t nobjects;
    uint32_t blocks_capa;
    uint32_t opnds_capa;
    uint32_t objects_capa;
    uint32_t value_id;
} PrismGraph;

typedef struct {
    uint32_t block_id;
} PrismBuilder;

/******************************************************************************/

static inline uint32_t
make_value(PrismGraph *graph) {
    return graph->value_id++;
}

static uint32_t
make_block(PrismGraph *graph, uint32_t nparams) {
    if (graph->nblocks == graph->blocks_capa) {
        uint32_t next_capa = graph->blocks_capa ? graph->blocks_capa * 2 : 8;
        PrismBlock *next_blocks = xrealloc_sized(graph->blocks, sizeof(PrismBlock) * next_capa, sizeof(PrismBlock) * graph->blocks_capa);
        if (!next_blocks) abort();

        graph->blocks_capa = next_capa;
        graph->blocks = next_blocks;
    }

    uint32_t *params = NULL;
    if (nparams) {
        params = xmalloc(sizeof(uint32_t) * nparams);
        if (!params) abort();

        for (uint32_t idx = 0; idx < nparams; ++idx) {
            params[idx] = make_value(graph);
        }
    }

    uint32_t block_id = graph->nblocks++;
    graph->blocks[block_id] = (PrismBlock) { .insns = NULL, .params = params, .ninsns = 0, .nparams = nparams, .insns_capa = 0 };
    return block_id;
}

static uint32_t
make_object(PrismGraph *graph, PrismObjectKind kind) {
    if (graph->nobjects == graph->objects_capa) {
        uint32_t next_capa = graph->objects_capa ? graph->objects_capa * 2 : 8;
        PrismObject *next_mem = xrealloc_sized(graph->objects, sizeof(PrismObject) * next_capa, sizeof(PrismObject) * graph->objects_capa);
        if (!next_mem) abort();

        graph->objects_capa = next_capa;
        graph->objects = next_mem;
    }

    uint32_t object_id = graph->nobjects++;
    graph->objects[object_id] = (PrismObject) { .kind = kind };
    return object_id;
}

static PrismInsn *
make_insn(PrismBuilder *builder, PrismGraph *graph, PrismInsnKind kind, uint32_t node_id, pm_location_t location, uint32_t opnds_len) {
    PrismBlock *block = graph->blocks + builder->block_id;

    if (block->ninsns == block->insns_capa) {
        uint32_t next_capa = block->insns_capa ? block->insns_capa * 2 : 8;
        PrismInsn *next_insns = xrealloc_sized(block->insns, sizeof(PrismInsn) * next_capa, sizeof(PrismInsn) * block->insns_capa);
        if (!next_insns) abort();

        block->insns_capa = next_capa;
        block->insns = next_insns;
    }

    PrismInsn *insn = block->insns + block->ninsns++;
    *insn = (PrismInsn) {
        .kind = kind,
        .node_id = node_id,
        .location = location,
        .opnds_off = graph->nopnds,
        .opnds_len = opnds_len
    };

    if (opnds_len) {
        if ((opnds_len > graph->opnds_capa) || (graph->nopnds > graph->opnds_capa - opnds_len)) {
            uint32_t next_capa = graph->opnds_capa ? graph->opnds_capa * 2 : 8;
            while ((opnds_len > next_capa) || (graph->nopnds > next_capa - opnds_len)) {
                next_capa *= 2;
            }

            uint32_t *next_opnds = xrealloc_sized(graph->opnds, sizeof(uint32_t) * next_capa, sizeof(uint32_t) * graph->opnds_capa);
            if (!next_opnds) abort();

            graph->opnds_capa = next_capa;
            graph->opnds = next_opnds;
        }

        graph->nopnds += opnds_len;
    }

    return insn;
}

/******************************************************************************/

static void
emit_branch(PrismBuilder *builder, PrismGraph *graph, uint32_t node_id, pm_location_t location, uint32_t block_id, uint32_t opnds_len, uint32_t *opnd_ids) {
    PrismInsn *insn = make_insn(builder, graph, kPrismInsnBranch, node_id, location, opnds_len);
    insn->as.branch.block_id = block_id;

    if (opnds_len) {
        memcpy(graph->opnds + insn->opnds_off, opnd_ids, sizeof(uint32_t) * opnds_len);
    }
}

static void
emit_branchif(PrismBuilder *builder, PrismGraph *graph, uint32_t node_id, pm_location_t location, uint32_t predicate_id, uint32_t then_block_id, uint32_t then_opnds_len, uint32_t *then_opnd_ids, uint32_t else_block_id, uint32_t else_opnds_len, uint32_t *else_opnd_ids) {
    PrismInsn *insn = make_insn(builder, graph, kPrismInsnBranchIf, node_id, location, 1 + then_opnds_len + else_opnds_len);
    insn->as.branchif.then_block_id = then_block_id;
    insn->as.branchif.else_block_id = else_block_id;
    insn->as.branchif.then_opnds_len = then_opnds_len;

    graph->opnds[insn->opnds_off] = predicate_id;

    if (then_opnds_len) {
        memcpy(graph->opnds + 1 + insn->opnds_off, then_opnd_ids, sizeof(uint32_t) * then_opnds_len);
    }

    if (else_opnds_len) {
        memcpy(graph->opnds + 1 + insn->opnds_off + then_opnds_len, else_opnd_ids, sizeof(uint32_t) * else_opnds_len);
    }
}

static uint32_t
emit_call(PrismBuilder *builder, PrismGraph *graph, uint32_t node_id, pm_location_t location, pm_constant_id_t name_id, uint32_t receiver_id, size_t nargument_ids, uint32_t *argument_ids) {
    PrismInsn *insn = make_insn(builder, graph, kPrismInsnCall, node_id, location, 2 + (uint32_t) nargument_ids);
    insn->as.name.name_id = name_id;

    uint32_t value_id = make_value(graph);
    graph->opnds[insn->opnds_off] = value_id;
    graph->opnds[insn->opnds_off + 1] = receiver_id;

    for (size_t idx = 0; idx < nargument_ids; ++idx) {
        graph->opnds[insn->opnds_off + 2 + idx] = argument_ids[idx];
    }

    return value_id;
}

static uint32_t
emit_defined_gvar(PrismBuilder *builder, PrismGraph *graph, uint32_t node_id, pm_location_t location, pm_constant_id_t name_id) {
    PrismInsn *insn = make_insn(builder, graph, kPrismInsnDefinedGVar, node_id, location, 1);
    insn->as.name.name_id = name_id;

    uint32_t value_id = make_value(graph);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_load_name(PrismBuilder *builder, PrismGraph *graph, uint32_t node_id, pm_location_t location, PrismInsnKind kind, pm_constant_id_t name_id) {
    PrismInsn *insn = make_insn(builder, graph, kind, node_id, location, 1);
    insn->as.name.name_id = name_id;

    uint32_t value_id = make_value(graph);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_load_cvar(PrismBuilder *builder, PrismGraph *graph, uint32_t node_id, pm_location_t location, pm_constant_id_t name_id) {
    return emit_load_name(builder, graph, node_id, location, kPrismInsnLoadCVar, name_id);
}

static uint32_t
emit_load_gvar(PrismBuilder *builder, PrismGraph *graph, uint32_t node_id, pm_location_t location, pm_constant_id_t name_id) {
    return emit_load_name(builder, graph, node_id, location, kPrismInsnLoadGVar, name_id);
}

static uint32_t
emit_load_ivar(PrismBuilder *builder, PrismGraph *graph, uint32_t node_id, pm_location_t location, pm_constant_id_t name_id) {
    return emit_load_name(builder, graph, node_id, location, kPrismInsnLoadIVar, name_id);
}

static uint32_t
emit_load_object(PrismBuilder *builder, PrismGraph *graph, uint32_t node_id, pm_location_t location, uint32_t object_id) {
    PrismInsn *insn = make_insn(builder, graph, kPrismInsnLoadObject, node_id, location, 1);
    insn->as.object.object_id = object_id;

    uint32_t value_id = make_value(graph);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_load_nil(PrismBuilder *builder, PrismGraph *graph, uint32_t node_id, pm_location_t location) {
    return emit_load_object(builder, graph, node_id, location, make_object(graph, kPrismObjectNil));
}

static uint32_t
emit_load_self(PrismBuilder *builder, PrismGraph *graph, uint32_t node_id, pm_location_t location) {
    PrismInsn *insn = make_insn(builder, graph, kPrismInsnLoadSelf, node_id, location, 1);

    uint32_t value_id = make_value(graph);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static void
emit_return(PrismBuilder *builder, PrismGraph *graph, uint32_t node_id, pm_location_t location, uint32_t value_id) {
    PrismInsn *insn = make_insn(builder, graph, kPrismInsnReturn, node_id, location, 1);

    graph->opnds[insn->opnds_off] = value_id;
}

static uint32_t
emit_store_name(PrismBuilder *builder, PrismGraph *graph, uint32_t node_id, pm_location_t location, PrismInsnKind kind, pm_constant_id_t name_id, uint32_t value_id) {
    PrismInsn *insn = make_insn(builder, graph, kind, node_id, location, 1);
    insn->as.name.name_id = name_id;

    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_store_cvar(PrismBuilder *builder, PrismGraph *graph, uint32_t node_id, pm_location_t location, pm_constant_id_t name_id, uint32_t value_id) {
    return emit_store_name(builder, graph, node_id, location, kPrismInsnStoreCVar, name_id, value_id);
}

static uint32_t
emit_store_gvar(PrismBuilder *builder, PrismGraph *graph, uint32_t node_id, pm_location_t location, pm_constant_id_t name_id, uint32_t value_id) {
    return emit_store_name(builder, graph, node_id, location, kPrismInsnStoreGVar, name_id, value_id);
}

static uint32_t
emit_store_ivar(PrismBuilder *builder, PrismGraph *graph, uint32_t node_id, pm_location_t location, pm_constant_id_t name_id, uint32_t value_id) {
    return emit_store_name(builder, graph, node_id, location, kPrismInsnStoreIVar, name_id, value_id);
}

/******************************************************************************/

static uint32_t compile_node(PrismBuilder *builder, PrismGraph *graph, const pm_node_t *node);

static uint32_t
compile_logical_node(PrismBuilder *builder, PrismGraph *graph, const pm_node_t *node, const pm_node_t *left, const pm_node_t *right) {
    uint32_t right_block_id = make_block(graph, 0);
    uint32_t join_block_id = make_block(graph, 1);

    uint32_t left_value_id = compile_node(builder, graph, left);
    if (PM_NODE_TYPE(node) == PM_AND_NODE) {
        emit_branchif(builder, graph, node->node_id, node->location, left_value_id, right_block_id, 0, NULL, join_block_id, 1, &left_value_id);
    } else {
        emit_branchif(builder, graph, node->node_id, node->location, left_value_id, join_block_id, 1, &left_value_id, right_block_id, 0, NULL);
    }

    builder->block_id = right_block_id;
    uint32_t right_value_id = compile_node(builder, graph, right);
    emit_branch(builder, graph, node->node_id, node->location, join_block_id, 1, &right_value_id);

    builder->block_id = join_block_id;
    return graph->blocks[join_block_id].params[0];
}

static uint32_t
compile_and_node(PrismBuilder *builder, PrismGraph *graph, const pm_and_node_t *node) {
    return compile_logical_node(builder, graph, PM_NODE_UPCAST(node), node->left, node->right);
}

static uint32_t
compile_call_node(PrismBuilder *builder, PrismGraph *graph, const pm_call_node_t *node) {
    uint32_t receiver_id;
    if (node->receiver) {
        receiver_id = compile_node(builder, graph, node->receiver);
    } else {
        receiver_id = emit_load_self(builder, graph, node->base.node_id, node->base.location);
    }

    size_t nargument_ids = 0;
    uint32_t *argument_ids = NULL;

    if (node->arguments) {
        nargument_ids = node->arguments->arguments.size;
        argument_ids = xmalloc(sizeof(uint32_t) * nargument_ids);
        if (!argument_ids) abort();

        for (size_t idx = 0; idx < nargument_ids; ++idx) {
            argument_ids[idx] = compile_node(builder, graph, node->arguments->arguments.nodes[idx]);
        }
    }

    return emit_call(builder, graph, node->base.node_id, node->base.location, node->name, receiver_id, nargument_ids, argument_ids);
}

static uint32_t
compile_class_variable_read_node(PrismBuilder *builder, PrismGraph *graph, const pm_class_variable_read_node_t *node) {
    return emit_load_cvar(builder, graph, node->base.node_id, node->base.location, node->name);
}

static uint32_t
compile_class_variable_write_node(PrismBuilder *builder, PrismGraph *graph, const pm_class_variable_write_node_t *node) {
    uint32_t value_id = compile_node(builder, graph, node->value);
    emit_store_cvar(builder, graph, node->base.node_id, node->base.location, node->name, value_id);
    return value_id;
}

static uint32_t
compile_class_variable_operator_write_node(PrismBuilder *builder, PrismGraph *graph, const pm_class_variable_operator_write_node_t *node) {
    uint32_t receiver_id = emit_load_cvar(builder, graph, node->base.node_id, node->base.location, node->name);
    uint32_t value_id = compile_node(builder, graph, node->value);
    uint32_t result_id = emit_call(builder, graph, node->base.node_id, node->base.location, node->binary_operator, receiver_id, 1, &value_id);
    emit_store_cvar(builder, graph, node->base.node_id, node->base.location, node->name, result_id);
    return result_id;
}

static uint32_t
compile_class_variable_and_write_node(PrismBuilder *builder, PrismGraph *graph, const pm_class_variable_and_write_node_t *node) {
    uint32_t set_block_id = make_block(graph, 0);
    uint32_t join_block_id = make_block(graph, 1);

    uint32_t predicate_id = emit_load_cvar(builder, graph, node->base.node_id, node->base.location, node->name);
    emit_branchif(builder, graph, node->base.node_id, node->base.location, predicate_id, set_block_id, 0, NULL, join_block_id, 1, &predicate_id);

    builder->block_id = set_block_id;
    uint32_t value_id = compile_node(builder, graph, node->value);
    emit_store_cvar(builder, graph, node->base.node_id, node->base.location, node->name, value_id);
    emit_branch(builder, graph, node->base.node_id, node->base.location, join_block_id, 1, &value_id);

    builder->block_id = join_block_id;
    return graph->blocks[join_block_id].params[0];
}

static uint32_t
compile_false_node(PrismBuilder *builder, PrismGraph *graph, const pm_false_node_t *node) {
    uint32_t object_id = make_object(graph, kPrismObjectFalse);
    return emit_load_object(builder, graph, node->base.node_id, node->base.location, object_id);
}

static uint32_t
compile_float_node(PrismBuilder *builder, PrismGraph *graph, const pm_float_node_t *node) {
    uint32_t object_id = make_object(graph, kPrismObjectFloat);
    graph->objects[object_id].as.floating.value = node->value;
    return emit_load_object(builder, graph, node->base.node_id, node->base.location, object_id);
}

static uint32_t
compile_global_variable_read_node(PrismBuilder *builder, PrismGraph *graph, const pm_global_variable_read_node_t *node) {
    return emit_load_gvar(builder, graph, node->base.node_id, node->base.location, node->name);
}

static uint32_t
compile_global_variable_write_node(PrismBuilder *builder, PrismGraph *graph, const pm_global_variable_write_node_t *node) {
    uint32_t value_id = compile_node(builder, graph, node->value);
    emit_store_gvar(builder, graph, node->base.node_id, node->base.location, node->name, value_id);
    return value_id;
}

static uint32_t
compile_global_variable_operator_write_node(PrismBuilder *builder, PrismGraph *graph, const pm_global_variable_operator_write_node_t *node) {
    uint32_t receiver_id = emit_load_gvar(builder, graph, node->base.node_id, node->base.location, node->name);
    uint32_t value_id = compile_node(builder, graph, node->value);
    uint32_t result_id = emit_call(builder, graph, node->base.node_id, node->base.location, node->binary_operator, receiver_id, 1, &value_id);
    emit_store_gvar(builder, graph, node->base.node_id, node->base.location, node->name, result_id);
    return result_id;
}

static uint32_t
compile_global_variable_and_write_node(PrismBuilder *builder, PrismGraph *graph, const pm_global_variable_and_write_node_t *node) {
    uint32_t set_block_id = make_block(graph, 0);
    uint32_t join_block_id = make_block(graph, 1);

    uint32_t predicate_id = emit_load_gvar(builder, graph, node->base.node_id, node->base.location, node->name);
    emit_branchif(builder, graph, node->base.node_id, node->base.location, predicate_id, set_block_id, 0, NULL, join_block_id, 1, &predicate_id);

    builder->block_id = set_block_id;
    uint32_t value_id = compile_node(builder, graph, node->value);
    emit_store_gvar(builder, graph, node->base.node_id, node->base.location, node->name, value_id);
    emit_branch(builder, graph, node->base.node_id, node->base.location, join_block_id, 1, &value_id);

    builder->block_id = join_block_id;
    return graph->blocks[join_block_id].params[0];
}

static uint32_t
compile_global_variable_or_write_node(PrismBuilder *builder, PrismGraph *graph, const pm_global_variable_or_write_node_t *node) {
    uint32_t defined_block_id = make_block(graph, 0);
    uint32_t undefined_block_id = make_block(graph, 0);
    uint32_t join_block_id = make_block(graph, 1);

    uint32_t defined_id = emit_defined_gvar(builder, graph, node->base.node_id, node->base.location, node->name);
    emit_branchif(builder, graph, node->base.node_id, node->base.location, defined_id, defined_block_id, 0, NULL, undefined_block_id, 0, NULL);

    builder->block_id = defined_block_id;
    uint32_t predicate_id = emit_load_gvar(builder, graph, node->base.node_id, node->base.location, node->name);
    emit_branchif(builder, graph, node->base.node_id, node->base.location, predicate_id, join_block_id, 1, &predicate_id, undefined_block_id, 0, NULL);

    builder->block_id = undefined_block_id;
    uint32_t value_id = compile_node(builder, graph, node->value);
    emit_store_gvar(builder, graph, node->base.node_id, node->base.location, node->name, value_id);
    emit_branch(builder, graph, node->base.node_id, node->base.location, join_block_id, 1, &value_id);

    builder->block_id = join_block_id;
    return graph->blocks[join_block_id].params[0];
}

static uint32_t
compile_instance_variable_read_node(PrismBuilder *builder, PrismGraph *graph, const pm_instance_variable_read_node_t *node) {
    return emit_load_ivar(builder, graph, node->base.node_id, node->base.location, node->name);
}

static uint32_t
compile_instance_variable_write_node(PrismBuilder *builder, PrismGraph *graph, const pm_instance_variable_write_node_t *node) {
    uint32_t value_id = compile_node(builder, graph, node->value);
    emit_store_ivar(builder, graph, node->base.node_id, node->base.location, node->name, value_id);
    return value_id;
}

static uint32_t
compile_instance_variable_operator_write_node(PrismBuilder *builder, PrismGraph *graph, const pm_instance_variable_operator_write_node_t *node) {
    uint32_t receiver_id = emit_load_ivar(builder, graph, node->base.node_id, node->base.location, node->name);
    uint32_t value_id = compile_node(builder, graph, node->value);
    uint32_t result_id = emit_call(builder, graph, node->base.node_id, node->base.location, node->binary_operator, receiver_id, 1, &value_id);
    emit_store_ivar(builder, graph, node->base.node_id, node->base.location, node->name, result_id);
    return result_id;
}

static uint32_t
compile_instance_variable_and_write_node(PrismBuilder *builder, PrismGraph *graph, const pm_instance_variable_and_write_node_t *node) {
    uint32_t set_block_id = make_block(graph, 0);
    uint32_t join_block_id = make_block(graph, 1);

    uint32_t predicate_id = emit_load_ivar(builder, graph, node->base.node_id, node->base.location, node->name);
    emit_branchif(builder, graph, node->base.node_id, node->base.location, predicate_id, set_block_id, 0, NULL, join_block_id, 1, &predicate_id);

    builder->block_id = set_block_id;
    uint32_t value_id = compile_node(builder, graph, node->value);
    emit_store_ivar(builder, graph, node->base.node_id, node->base.location, node->name, value_id);
    emit_branch(builder, graph, node->base.node_id, node->base.location, join_block_id, 1, &value_id);

    builder->block_id = join_block_id;
    return graph->blocks[join_block_id].params[0];
}

static uint32_t
compile_integer_node(PrismBuilder *builder, PrismGraph *graph, const pm_integer_node_t *node) {
    uint32_t object_id = make_object(graph, kPrismObjectInteger);
    graph->objects[object_id].as.integer.value = &node->value;
    return emit_load_object(builder, graph, node->base.node_id, node->base.location, object_id);
}

static uint32_t
compile_nil_node(PrismBuilder *builder, PrismGraph *graph, const pm_nil_node_t *node) {
    uint32_t object_id = make_object(graph, kPrismObjectNil);
    return emit_load_object(builder, graph, node->base.node_id, node->base.location, object_id);
}

static uint32_t
compile_or_node(PrismBuilder *builder, PrismGraph *graph, const pm_or_node_t *node) {
    return compile_logical_node(builder, graph, PM_NODE_UPCAST(node), node->left, node->right);
}

static uint32_t
compile_parentheses_node(PrismBuilder *builder, PrismGraph *graph, const pm_parentheses_node_t *node) {
    if (node->body) {
        return compile_node(builder, graph, node->body);
    } else {
        return emit_load_nil(builder, graph, node->base.node_id, node->base.location);
    }
}

static uint32_t
compile_program_node(PrismBuilder *builder, PrismGraph *graph, const pm_program_node_t *node) {
    builder->block_id = make_block(graph, 0);
    uint32_t value_id;

    const pm_statements_node_t *statements = (const pm_statements_node_t *) node->statements;
    if (statements->body.size) {
        value_id = compile_node(builder, graph, PM_NODE_UPCAST(statements));
    } else {
        value_id = emit_load_nil(builder, graph, node->base.node_id, node->base.location);
    }

    emit_return(builder, graph, node->base.node_id, node->base.location, value_id);
    return UINT32_MAX;
}

static uint32_t
compile_self_node(PrismBuilder *builder, PrismGraph *graph, const pm_self_node_t *node) {
    return emit_load_self(builder, graph, node->base.node_id, node->base.location);
}

static uint32_t
compile_statements_node(PrismBuilder *builder, PrismGraph *graph, const pm_statements_node_t *node) {
    uint32_t value_id;
    for (size_t idx = 0; idx < node->body.size; ++idx) {
        value_id = compile_node(builder, graph, node->body.nodes[idx]);
    }

    return value_id;
}

static uint32_t
compile_symbol_node(PrismBuilder *builder, PrismGraph *graph, const pm_symbol_node_t *node) {
    uint32_t object_id = make_object(graph, kPrismObjectSymbol);
    PrismObject *object = graph->objects + object_id;

    object->as.symbol.flags = node->base.flags;
    object->as.symbol.unescaped = &node->unescaped;

    return emit_load_object(builder, graph, node->base.node_id, node->base.location, object_id);
}

static uint32_t
compile_true_node(PrismBuilder *builder, PrismGraph *graph, const pm_true_node_t *node) {
    uint32_t object_id = make_object(graph, kPrismObjectTrue);
    return emit_load_object(builder, graph, node->base.node_id, node->base.location, object_id);
}

static uint32_t
compile_node(PrismBuilder *builder, PrismGraph *graph, const pm_node_t *node) {
    switch (PM_NODE_TYPE(node)) {
        case PM_AND_NODE:
            return compile_and_node(builder, graph, (const pm_and_node_t *) node);
        case PM_CALL_NODE:
            return compile_call_node(builder, graph, (const pm_call_node_t *) node);
        case PM_CLASS_VARIABLE_READ_NODE:
            return compile_class_variable_read_node(builder, graph, (const pm_class_variable_read_node_t *) node);
        case PM_CLASS_VARIABLE_WRITE_NODE:
            return compile_class_variable_write_node(builder, graph, (const pm_class_variable_write_node_t *) node);
        case PM_CLASS_VARIABLE_OPERATOR_WRITE_NODE:
            return compile_class_variable_operator_write_node(builder, graph, (const pm_class_variable_operator_write_node_t *) node);
        case PM_CLASS_VARIABLE_AND_WRITE_NODE:
            return compile_class_variable_and_write_node(builder, graph, (const pm_class_variable_and_write_node_t *) node);
        case PM_FALSE_NODE:
            return compile_false_node(builder, graph, (const pm_false_node_t *) node);
        case PM_FLOAT_NODE:
            return compile_float_node(builder, graph, (const pm_float_node_t *) node);
        case PM_GLOBAL_VARIABLE_READ_NODE:
            return compile_global_variable_read_node(builder, graph, (const pm_global_variable_read_node_t *) node);
        case PM_GLOBAL_VARIABLE_WRITE_NODE:
            return compile_global_variable_write_node(builder, graph, (const pm_global_variable_write_node_t *) node);
        case PM_GLOBAL_VARIABLE_OPERATOR_WRITE_NODE:
            return compile_global_variable_operator_write_node(builder, graph, (const pm_global_variable_operator_write_node_t *) node);
        case PM_GLOBAL_VARIABLE_AND_WRITE_NODE:
            return compile_global_variable_and_write_node(builder, graph, (const pm_global_variable_and_write_node_t *) node);
        case PM_GLOBAL_VARIABLE_OR_WRITE_NODE:
            return compile_global_variable_or_write_node(builder, graph, (const pm_global_variable_or_write_node_t *) node);
        case PM_INSTANCE_VARIABLE_READ_NODE:
            return compile_instance_variable_read_node(builder, graph, (const pm_instance_variable_read_node_t *) node);
        case PM_INSTANCE_VARIABLE_WRITE_NODE:
            return compile_instance_variable_write_node(builder, graph, (const pm_instance_variable_write_node_t *) node);
        case PM_INSTANCE_VARIABLE_OPERATOR_WRITE_NODE:
            return compile_instance_variable_operator_write_node(builder, graph, (const pm_instance_variable_operator_write_node_t *) node);
        case PM_INSTANCE_VARIABLE_AND_WRITE_NODE:
            return compile_instance_variable_and_write_node(builder, graph, (const pm_instance_variable_and_write_node_t *) node);
        case PM_INTEGER_NODE:
            return compile_integer_node(builder, graph, (const pm_integer_node_t *) node);
        case PM_NIL_NODE:
            return compile_nil_node(builder, graph, (const pm_nil_node_t *) node);
        case PM_OR_NODE:
            return compile_or_node(builder, graph, (const pm_or_node_t *) node);
        case PM_PARENTHESES_NODE:
            return compile_parentheses_node(builder, graph, (const pm_parentheses_node_t *) node);
        case PM_PROGRAM_NODE:
            return compile_program_node(builder, graph, (const pm_program_node_t *) node);
        case PM_SELF_NODE:
            return compile_self_node(builder, graph, (const pm_self_node_t *) node);
        case PM_STATEMENTS_NODE:
            return compile_statements_node(builder, graph, (const pm_statements_node_t *) node);
        case PM_SYMBOL_NODE:
            return compile_symbol_node(builder, graph, (const pm_symbol_node_t *) node);
        case PM_TRUE_NODE:
            return compile_true_node(builder, graph, (const pm_true_node_t *) node);
        default:
            fprintf(stderr, "Unhandled node type: %s\n", pm_node_type(node->type));
            abort();
    }
}

/******************************************************************************/

static void
dump_values(uint32_t nvalues, uint32_t *values) {
    if (nvalues) {
        printf("(");
        for (uint32_t idx = 0; idx < nvalues; ++idx) {
            if (idx > 0) printf(", ");
            printf("%%%" PRIu32, values[idx]);
        }
        printf(")");
    }
}

static void
dump_object(PrismObject *object) {
    switch (object->kind) {
        case kPrismObjectFalse:
            printf("false");
            break;
        case kPrismObjectFloat:
            printf("%f", object->as.floating.value);
            break;
        case kPrismObjectInteger:
            printf("%" PRIu32, object->as.integer.value->value); /* TODO */
            break;
        case kPrismObjectNil:
            printf("nil");
            break;
        case kPrismObjectSymbol: {
            const pm_string_t *unescaped = object->as.symbol.unescaped; 
            printf(":%.*s", (int) pm_string_length(unescaped), (const char *) pm_string_source(unescaped));
            break;
        }
        case kPrismObjectTrue:
            printf("true");
            break;
    }
}

static void
dump_graph(const pm_parser_t *parser, PrismGraph *graph) {
    for (uint32_t block_id = 0; block_id < graph->nblocks; ++block_id) {
        PrismBlock *block = &graph->blocks[block_id];

        printf("bb%" PRIu32, block_id);
        dump_values(block->nparams, block->params);
        printf(":\n");

        for (uint32_t insn_id = 0; insn_id < block->ninsns; ++insn_id) {
            PrismInsn *insn = &block->insns[insn_id];
            uint32_t *opnds = &graph->opnds[insn->opnds_off];

            switch (insn->kind) {
                case kPrismInsnBranch: {
                    printf("  branch bb%" PRIu32, insn->as.branchif.then_block_id);
                    dump_values(insn->opnds_len, opnds);
                    printf("\n");
                    break;
                }
                case kPrismInsnBranchIf: {
                    printf("  branchif %%%" PRIu32 " bb%" PRIu32, opnds[0], insn->as.branchif.then_block_id);
                    dump_values(insn->as.branchif.then_opnds_len, opnds + 1);
                    printf(" bb%" PRIu32, insn->as.branchif.else_block_id);
                    dump_values(insn->opnds_len - insn->as.branchif.then_opnds_len - 1, opnds + 1 + insn->as.branchif.then_opnds_len);
                    printf("\n");
                    break;
                }
                case kPrismInsnCall: {
                    printf("  %%%" PRIu32 " = call %%%" PRIu32 ".", opnds[0], opnds[1]);

                    const pm_constant_t *constant = pm_parser_constant(parser, insn->as.name.name_id);
                    printf("%.*s(", (int) pm_constant_length(constant), (const char *) pm_constant_start(constant));

                    for (uint32_t idx = 0; idx < insn->opnds_len - 2; ++idx) {
                        printf("%%%" PRIu32, opnds[2 + idx]);
                    }

                    printf(")\n");
                    break;
                }
                case kPrismInsnDefinedGVar: {
                    printf("  %%%" PRIu32 " = defined_gvar ", opnds[0]);
                    const pm_constant_t *constant = pm_parser_constant(parser, insn->as.name.name_id);
                    printf("%.*s\n", (int) pm_constant_length(constant), (const char *) pm_constant_start(constant));
                    break;
                }
                case kPrismInsnLoadCVar: {
                    printf("  %%%" PRIu32 " = load_cvar ", opnds[0]);
                    const pm_constant_t *constant = pm_parser_constant(parser, insn->as.name.name_id);
                    printf("%.*s\n", (int) pm_constant_length(constant), (const char *) pm_constant_start(constant));
                    break;
                }
                case kPrismInsnLoadGVar: {
                    printf("  %%%" PRIu32 " = load_gvar ", opnds[0]);
                    const pm_constant_t *constant = pm_parser_constant(parser, insn->as.name.name_id);
                    printf("%.*s\n", (int) pm_constant_length(constant), (const char *) pm_constant_start(constant));
                    break;
                }
                case kPrismInsnLoadIVar: {
                    printf("  %%%" PRIu32 " = load_ivar ", opnds[0]);
                    const pm_constant_t *constant = pm_parser_constant(parser, insn->as.name.name_id);
                    printf("%.*s\n", (int) pm_constant_length(constant), (const char *) pm_constant_start(constant));
                    break;
                }
                case kPrismInsnLoadObject: {
                    printf("  %%%" PRIu32 " = load_object ", opnds[0]);
                    dump_object(&graph->objects[insn->as.object.object_id]);
                    printf("\n");
                    break;
                }
                case kPrismInsnLoadSelf:
                    printf("  %%%" PRIu32 " = load_self\n", opnds[0]);
                    break;
                case kPrismInsnReturn:
                    printf("  return %%%" PRIu32 "\n", opnds[0]);
                    break;
                case kPrismInsnStoreCVar: {
                    printf("  store_cvar ");
                    const pm_constant_t *constant = pm_parser_constant(parser, insn->as.name.name_id);
                    printf("%.*s, %%%" PRIu32 "\n", (int) pm_constant_length(constant), (const char *) pm_constant_start(constant), opnds[0]);
                    break;
                }
                case kPrismInsnStoreGVar: {
                    printf("  store_gvar ");
                    const pm_constant_t *constant = pm_parser_constant(parser, insn->as.name.name_id);
                    printf("%.*s, %%%" PRIu32 "\n", (int) pm_constant_length(constant), (const char *) pm_constant_start(constant), opnds[0]);
                    break;
                }
                case kPrismInsnStoreIVar: {
                    printf("  store_ivar ");
                    const pm_constant_t *constant = pm_parser_constant(parser, insn->as.name.name_id);
                    printf("%.*s, %%%" PRIu32 "\n", (int) pm_constant_length(constant), (const char *) pm_constant_start(constant), opnds[0]);
                    break;
                }
            }
        }
    }
}

void
pm_compile(const pm_parser_t *parser, const pm_node_t *node) {
    PrismBuilder builder = { 0 };
    PrismGraph graph = { 0 };
    compile_node(&builder, &graph, node);
    dump_graph(parser, &graph);
}
