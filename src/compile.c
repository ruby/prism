#include "prism/compile.h"

#include "prism/compiler/align.h"
#include "prism/internal/allocator.h"
#include "prism/internal/arena.h"
#include "prism/internal/buffer.h"
#include "prism/internal/compile.h"
#include "prism/internal/constant_pool.h"
#include "prism/internal/integer.h"
#include "prism/internal/line_offset_list.h"
#include "prism/internal/oom.h"
#include "prism/internal/parser.h"
#include "prism/node.h"

#include <assert.h>
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#define PM_CONSTANT_ID_BACKTICK (pm_constant_id_t) -1
static const pm_constant_t backtick_constant = { .start = (const uint8_t *) "`", .length = 1 };

static const pm_constant_t *
compile_constant(const pm_parser_t *parser, pm_constant_id_t constant_id) {
    switch (constant_id) {
        case PM_CONSTANT_ID_BACKTICK:
            return &backtick_constant;
        default:
            return pm_parser_constant(parser, constant_id);
    }
}

typedef struct {
    uint32_t graph_id;
    uint32_t block_id;
    int32_t lineno;
    const pm_constant_id_list_t *locals;
    uint32_t *shadowed;
} PrismBuilderState;

typedef struct {
    const pm_parser_t *parser;
    pm_arena_t *arena;
    PrismUnit *unit;
    PrismBuilderState state;
    uint32_t *bindings;
} PrismBuilder;

/******************************************************************************/

PrismUnit *
pm_unit_new(void) {
    PrismUnit *unit = xcalloc(1, sizeof(PrismUnit));
    if (!unit) PRISM_OOM();
    return unit;
}

uint32_t
pm_unit_nobjects(const PrismUnit *unit) {
    return unit->nobjects;
}

const PrismObject *
pm_unit_object(const PrismUnit *unit, uint32_t object_id) {
    return unit->objects + object_id;
}

PrismObjectKind
pm_object_kind(const PrismObject *object) {
    return object->kind;
}

uint32_t
pm_unit_nlocals(const PrismUnit *unit) {
    return unit->nlocals;
}

const PrismLocal *
pm_unit_local(const PrismUnit *unit, uint32_t local_id) {
    return unit->locals + local_id;
}

const pm_constant_t *
pm_local_name(const pm_parser_t *parser, const PrismLocal *local) {
    return compile_constant(parser, local->name_id);
}

uint32_t
pm_unit_ngraphs(const PrismUnit *unit) {
    return unit->ngraphs;
}

const PrismGraph *
pm_unit_graph(const PrismUnit *unit, uint32_t graph_id) {
    return unit->graphs + graph_id;
}

PrismGraphKind
pm_graph_kind(const PrismGraph *graph) {
    return graph->kind;
}

uint32_t
pm_graph_parent_id(const PrismGraph *graph) {
    return graph->parent_id;
}

uint32_t
pm_graph_nblocks(const PrismGraph *graph) {
    return graph->nblocks;
}

const PrismBlock *
pm_graph_block(const PrismGraph *graph, uint32_t block_id) {
    assert(block_id < graph->nblocks);
    return graph->blocks + block_id;
}

uint32_t
pm_graph_nlocals(const PrismGraph *graph) {
    return graph->nlocal_ids;
}

uint32_t
pm_graph_local_id(const PrismGraph *graph, uint32_t local_idx) {
    assert(local_idx < graph->nlocal_ids);
    return graph->local_ids[local_idx];
}

uint32_t
pm_block_ninsns(const PrismBlock *block) {
    return block->ninsns;
}

uint32_t
pm_block_nparams(const PrismBlock *block) {
    return block->nparams;
}

uint32_t
pm_block_param(const PrismBlock *block, uint32_t param_idx) {
    assert(param_idx < block->nparams);
    return block->params[param_idx];
}

const PrismInsn *
pm_block_insn(const PrismBlock *block, uint32_t insn_idx) {
    return block->insns + insn_idx;
}

PrismInsnKind
pm_insn_kind(const PrismInsn *insn) {
    return insn->kind;
}

uint32_t
pm_insn_node_id(const PrismInsn *insn) {
    return insn->node_id;
}

uint32_t
pm_insn_nopnds(const PrismInsn *insn) {
    return insn->opnds_len;
}

uint32_t
pm_insn_opnd(const PrismGraph *graph, const PrismInsn *insn, uint32_t opnd_idx) {
    return graph->opnds[insn->opnds_off + opnd_idx];
}

uint32_t
pm_object_array_size(const PrismObject *object) {
    return object->as.array.nobject_ids;
}

uint32_t
pm_object_array_object_id(const PrismObject *object, uint32_t idx) {
    return object->as.array.object_ids[idx];
}

const char *
pm_object_encoding_name(const PrismObject *object) {
    return object->as.encoding.name;
}

double
pm_object_float(const PrismObject *object) {
    return object->as.floating.value;
}

uint32_t
pm_object_hash_size(const PrismObject *object) {
    return object->as.hash.nobject_ids / 2;
}

uint32_t
pm_object_hash_key_object_id(const PrismObject *object, uint32_t idx) {
    return object->as.hash.object_ids[idx * 2];
}

uint32_t
pm_object_hash_value_object_id(const PrismObject *object, uint32_t idx) {
    return object->as.hash.object_ids[idx * 2 + 1];
}

uint32_t
pm_object_imaginary_object_id(const PrismObject *object) {
    return object->as.imaginary.numeric_id;
}

const pm_integer_t *
pm_object_integer(const PrismObject *object) {
    return object->as.integer.value;
}

const pm_integer_t *
pm_object_rational_numerator(const PrismObject *object) {
    return object->as.rational.numerator;
}

const pm_integer_t *
pm_object_rational_denominator(const PrismObject *object) {
    return object->as.rational.denominator;
}

const pm_string_t *
pm_object_string(const PrismObject *object) {
    return object->as.string.unescaped;
}

pm_node_flags_t
pm_object_flags(const PrismObject *object) {
    return object->as.string.flags;
}

uint32_t
pm_insn_branch_block_id(const PrismInsn *insn) {
    return insn->as.branch.block_id;
}

PRISM_EXPORTED_FUNCTION uint32_t
pm_insn_branchif_then_block_id(const PrismInsn *insn) {
    return insn->as.branchif.then_block_id;
}
PRISM_EXPORTED_FUNCTION uint32_t
pm_insn_branchif_else_block_id(const PrismInsn *insn) {
    return insn->as.branchif.else_block_id;
}
PRISM_EXPORTED_FUNCTION uint32_t
pm_insn_branchif_then_nopnds(const PrismInsn *insn) {
    return insn->as.branchif.then_opnds_len;
}

const pm_constant_t *
pm_insn_name(const pm_parser_t *parser, const PrismInsn *insn) {
    return compile_constant(parser, insn->as.name.name_id);
}

const pm_constant_t *
pm_insn_define_name(const pm_parser_t *parser, const PrismInsn *insn) {
    return compile_constant(parser, insn->as.define.name_id);
}

uint32_t
pm_insn_define_graph_id(const PrismInsn *insn) {
    return insn->as.define.graph_id;
}

uint32_t
pm_insn_define_singleton_class_graph_id(const PrismInsn *insn) {
    return insn->as.define_singleton_class.graph_id;
}

uint32_t
pm_insn_extract_group_number(const PrismInsn *insn) {
    return insn->as.extract_group.number;
}

const PrismConstantPath *
pm_insn_constant_path(const PrismInsn *insn) {
    return &insn->as.constant_path;
}

uint32_t
pm_insn_local_id(const PrismInsn *insn) {
    return insn->as.lvar.local_id;
}

uint32_t
pm_insn_object_id(const PrismInsn *insn) {
    return insn->as.object.object_id;
}

pm_node_flags_t
pm_insn_regexp_flags(const PrismInsn *insn) {
    return insn->as.regexp.flags;
}

int32_t
pm_insn_trace_lineno(const PrismInsn *insn) {
    return insn->as.trace_line.lineno;
}

uint32_t
PrismConstantPath_size(const PrismConstantPath *constant_path) {
    return constant_path->size;
}

const pm_constant_t *
PrismConstantPath_constant(const pm_parser_t *parser, const PrismConstantPath *constant_path, uint32_t idx) {
    assert(idx < constant_path->size);

    pm_constant_id_t constant_id;
    if (constant_path->size == 1) {
        constant_id = constant_path->as.constant_id;
    } else {
        constant_id = constant_path->as.constant_ids[idx];
    }

    return compile_constant(parser, constant_id);
}

/******************************************************************************/

static PrismConstantPath
PrismConstantPath_new(PrismBuilder *builder, uint32_t size) {
    if (size == 1) {
        return (PrismConstantPath) { .size = 1 };
    } else {
        pm_constant_id_t *constant_ids = pm_arena_alloc(builder->arena, sizeof(pm_constant_id_t) * size, PRISM_ALIGNOF(pm_constant_id_t));
        return (PrismConstantPath) { .size = size, .as.constant_ids = constant_ids };
    }
}

/*
static pm_constant_id_t
PrismConstantPath_get(PrismConstantPath *constant_path, uint32_t index) {
    assert(index < constant_path->size);

    if (constant_path->size == 1) {
        return constant_path->as.constant_id;
    } else {
        return constant_path->as.constant_ids[index];
    }
}
*/

static void
PrismConstantPath_set(PrismConstantPath *constant_path, uint32_t index, pm_constant_id_t constant_id) {
    assert(index < constant_path->size);

    if (constant_path->size == 1) {
        constant_path->as.constant_id = constant_id;
    } else {
        constant_path->as.constant_ids[index] = constant_id;
    }
}

/******************************************************************************/

#define PrismBuilder_graph(builder_) ((builder_)->unit->graphs + (builder_)->state.graph_id)

static uint32_t
make_local(PrismBuilder *builder, pm_constant_id_t name_id) {
    PrismUnit *unit = builder->unit;

    if (unit->nlocals == unit->locals_capa) {
        uint32_t next_capa = unit->locals_capa ? unit->locals_capa * 2 : 8;
        PrismLocal *next_mem = pm_arena_realloc(builder->arena, unit->locals, sizeof(PrismLocal) * next_capa, sizeof(PrismLocal) * unit->locals_capa, PRISM_ALIGNOF(PrismLocal));

        unit->locals_capa = next_capa;
        unit->locals = next_mem;
    }

    uint32_t local_id = unit->nlocals++;
    unit->locals[local_id] = (PrismLocal) { .name_id = name_id, .graph_id = builder->state.graph_id };
    return local_id;
}

static uint32_t
make_graph(PrismBuilder *builder, PrismGraphKind kind, uint32_t parent_id, uint32_t nlocal_ids) {
    PrismUnit *unit = builder->unit;

    if (unit->ngraphs == unit->graphs_capa) {
        uint32_t next_capa = unit->graphs_capa ? unit->graphs_capa * 2 : 8;
        PrismGraph *next_mem = pm_arena_realloc(builder->arena, unit->graphs, sizeof(PrismGraph) * next_capa, sizeof(PrismGraph) * unit->graphs_capa, PRISM_ALIGNOF(PrismGraph));

        unit->graphs_capa = next_capa;
        unit->graphs = next_mem;
    }

    uint32_t *local_ids = NULL;
    if (nlocal_ids) {
        local_ids = pm_arena_alloc(builder->arena, sizeof(uint32_t) * nlocal_ids, PRISM_ALIGNOF(uint32_t));
    }

    uint32_t graph_id = unit->ngraphs++;
    unit->graphs[graph_id] = (PrismGraph) { .kind = kind, .parent_id = parent_id, .local_ids = local_ids, .nlocal_ids = nlocal_ids };
    return graph_id;
}

static inline uint32_t
make_value(PrismBuilder *builder) {
    return PrismBuilder_graph(builder)->value_id++;
}

static uint32_t
make_block(PrismBuilder *builder, uint32_t nparams) {
    PrismGraph *graph = PrismBuilder_graph(builder);

    if (graph->nblocks == graph->blocks_capa) {
        uint32_t next_capa = graph->blocks_capa ? graph->blocks_capa * 2 : 8;
        PrismBlock *next_blocks = pm_arena_realloc(builder->arena, graph->blocks, sizeof(PrismBlock) * next_capa, sizeof(PrismBlock) * graph->blocks_capa, PRISM_ALIGNOF(PrismBlock));

        graph->blocks_capa = next_capa;
        graph->blocks = next_blocks;
    }

    uint32_t *params = NULL;
    if (nparams) {
        params = pm_arena_alloc(builder->arena, sizeof(uint32_t) * nparams, PRISM_ALIGNOF(uint32_t));
        for (uint32_t idx = 0; idx < nparams; ++idx) {
            params[idx] = make_value(builder);
        }
    }

    uint32_t block_id = graph->nblocks++;
    graph->blocks[block_id] = (PrismBlock) { .insns = NULL, .params = params, .ninsns = 0, .nparams = nparams, .insns_capa = 0 };
    return block_id;
}

static PrismBuilderState
push_scope(PrismBuilder *builder, uint32_t graph_id, uint32_t nparams, const pm_constant_id_list_t *locals) {
    PrismBuilderState state = builder->state;

    builder->state = (PrismBuilderState) {
        .graph_id = graph_id,
        .lineno = builder->parser->start_line - 1,
        .locals = locals
    };

    builder->state.block_id = make_block(builder, nparams);

    if (locals->size) {
        PrismGraph *graph = PrismBuilder_graph(builder);
        uint32_t *shadowed = pm_arena_alloc(builder->arena, sizeof(uint32_t) * locals->size, PRISM_ALIGNOF(uint32_t));

        for (size_t idx = 0; idx < locals->size; ++idx) {
            pm_constant_id_t name_id = locals->ids[idx];

#ifndef NDEBUG
            uint32_t bound_id = builder->bindings[name_id];
            assert(bound_id >= builder->unit->nlocals || builder->unit->locals[bound_id].name_id != name_id || builder->unit->locals[bound_id].graph_id != graph_id);
#endif

            uint32_t local_id = make_local(builder, name_id);
            graph->local_ids[idx] = local_id;
            shadowed[idx] = builder->bindings[name_id];
            builder->bindings[name_id] = local_id;
        }

        builder->state.shadowed = shadowed;
    }

    return state;
}

static void
pop_scope(PrismBuilder *builder, PrismBuilderState state) {
    const pm_constant_id_list_t *locals = builder->state.locals;

    for (size_t idx = 0; idx < locals->size; ++idx) {
        builder->bindings[locals->ids[idx]] = builder->state.shadowed[idx];
    }

    builder->state = state;
}

static uint32_t
make_object(PrismBuilder *builder, PrismObjectKind kind) {
    PrismUnit *unit = builder->unit;

    if (unit->nobjects == unit->objects_capa) {
        uint32_t next_capa = unit->objects_capa ? unit->objects_capa * 2 : 8;
        PrismObject *next_mem = pm_arena_realloc(builder->arena, unit->objects, sizeof(PrismObject) * next_capa, sizeof(PrismObject) * unit->objects_capa, PRISM_ALIGNOF(PrismObject));

        unit->objects_capa = next_capa;
        unit->objects = next_mem;
    }

    uint32_t object_id = unit->nobjects++;
    unit->objects[object_id] = (PrismObject) { .kind = kind };
    return object_id;
}

static uint32_t
make_object_constant_id(PrismBuilder *builder, pm_constant_id_t constant_id) {
    uint32_t object_id = make_object(builder, kPrismObjectSymbol);
    pm_string_t *name = pm_arena_alloc(builder->arena, sizeof(pm_string_t), PRISM_ALIGNOF(pm_string_t));

    const pm_constant_t *constant = compile_constant(builder->parser, constant_id);
    *name = (pm_string_t) { .source = pm_constant_start(constant), .length = pm_constant_length(constant) };

    builder->unit->objects[object_id].as.string.flags = 0;
    builder->unit->objects[object_id].as.string.unescaped = name;
    return object_id;
}

static PrismInsn *
make_insn(PrismBuilder *builder, PrismInsnKind kind, uint32_t node_id, uint32_t opnds_len) {
    PrismGraph *graph = PrismBuilder_graph(builder);
    PrismBlock *block = graph->blocks + builder->state.block_id;

    if (block->ninsns == block->insns_capa) {
        uint32_t next_capa = block->insns_capa ? block->insns_capa * 2 : 8;
        PrismInsn *next_insns = pm_arena_realloc(builder->arena, block->insns, sizeof(PrismInsn) * next_capa, sizeof(PrismInsn) * block->insns_capa, PRISM_ALIGNOF(PrismInsn));

        block->insns_capa = next_capa;
        block->insns = next_insns;
    }

    PrismInsn *insn = block->insns + block->ninsns++;
    *insn = (PrismInsn) {
        .kind = kind,
        .node_id = node_id,
        .opnds_off = graph->nopnds,
        .opnds_len = opnds_len
    };

    if (opnds_len) {
        if ((opnds_len > graph->opnds_capa) || (graph->nopnds > graph->opnds_capa - opnds_len)) {
            uint32_t next_capa = graph->opnds_capa ? graph->opnds_capa * 2 : 8;
            while ((opnds_len > next_capa) || (graph->nopnds > next_capa - opnds_len)) {
                next_capa *= 2;
            }

            uint32_t *next_opnds = pm_arena_realloc(builder->arena, graph->opnds, sizeof(uint32_t) * next_capa, sizeof(uint32_t) * graph->opnds_capa, PRISM_ALIGNOF(uint32_t));

            graph->opnds_capa = next_capa;
            graph->opnds = next_opnds;
        }

        graph->nopnds += opnds_len;
    }

    return insn;
}

/******************************************************************************/

static void
emit_alias_method(PrismBuilder *builder, uint32_t node_id, uint32_t new_name_id, uint32_t old_name_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnAliasMethod, node_id, 2);

    PrismGraph *graph = PrismBuilder_graph(builder);
    graph->opnds[insn->opnds_off] = new_name_id;
    graph->opnds[insn->opnds_off + 1] = old_name_id;
}

static void
emit_branch(PrismBuilder *builder, uint32_t node_id, uint32_t block_id, uint32_t opnds_len, uint32_t *opnd_ids) {
    PrismInsn *insn = make_insn(builder, kPrismInsnBranch, node_id, opnds_len);
    insn->as.branch.block_id = block_id;

    if (opnds_len) {
        memcpy(PrismBuilder_graph(builder)->opnds + insn->opnds_off, opnd_ids, sizeof(uint32_t) * opnds_len);
    }
}

static void
emit_branchif(PrismBuilder *builder, uint32_t node_id, uint32_t predicate_id, uint32_t then_block_id, uint32_t then_opnds_len, uint32_t *then_opnd_ids, uint32_t else_block_id, uint32_t else_opnds_len, uint32_t *else_opnd_ids) {
    PrismInsn *insn = make_insn(builder, kPrismInsnBranchIf, node_id, 1 + then_opnds_len + else_opnds_len);
    insn->as.branchif.then_block_id = then_block_id;
    insn->as.branchif.else_block_id = else_block_id;
    insn->as.branchif.then_opnds_len = then_opnds_len;

    PrismGraph *graph = PrismBuilder_graph(builder);
    graph->opnds[insn->opnds_off] = predicate_id;

    if (then_opnds_len) {
        memcpy(graph->opnds + 1 + insn->opnds_off, then_opnd_ids, sizeof(uint32_t) * then_opnds_len);
    }

    if (else_opnds_len) {
        memcpy(graph->opnds + 1 + insn->opnds_off + then_opnds_len, else_opnd_ids, sizeof(uint32_t) * else_opnds_len);
    }
}

static uint32_t
emit_call(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t receiver_id, size_t nargument_ids, uint32_t *argument_ids) {
    PrismInsn *insn = make_insn(builder, kPrismInsnCall, node_id, 2 + (uint32_t) nargument_ids);
    insn->as.name.name_id = name_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;
    graph->opnds[insn->opnds_off + 1] = receiver_id;
    memcpy(graph->opnds + insn->opnds_off + 2, argument_ids, sizeof(uint32_t) * nargument_ids);

    return value_id;
}

static uint32_t
emit_coerce_hash(PrismBuilder *builder, uint32_t node_id, uint32_t value_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnCoerceHash, node_id, 2);

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t hash_id = make_value(builder);
    graph->opnds[insn->opnds_off] = hash_id;
    graph->opnds[insn->opnds_off + 1] = value_id;

    return hash_id;
}

static uint32_t
emit_coerce_string(PrismBuilder *builder, uint32_t node_id, uint32_t value_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnCoerceString, node_id, 2);

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t string_id = make_value(builder);
    graph->opnds[insn->opnds_off] = string_id;
    graph->opnds[insn->opnds_off + 1] = value_id;

    return string_id;
}

static uint32_t
emit_define_class_abs(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t graph_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnDefineClassAbs, node_id, 1);
    insn->as.define.name_id = name_id;
    insn->as.define.graph_id = graph_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_define_class_abs_super(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t superclass_id, uint32_t graph_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnDefineClassAbsSuper, node_id, 2);
    insn->as.define.name_id = name_id;
    insn->as.define.graph_id = graph_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;
    graph->opnds[insn->opnds_off + 1] = superclass_id;

    return value_id;
}

static uint32_t
emit_define_class_nest_rel(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t graph_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnDefineClassNestRel, node_id, 1);
    insn->as.define.name_id = name_id;
    insn->as.define.graph_id = graph_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_define_class_nest_rel_super(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t superclass_id, uint32_t graph_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnDefineClassNestRelSuper, node_id, 2);
    insn->as.define.name_id = name_id;
    insn->as.define.graph_id = graph_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;
    graph->opnds[insn->opnds_off + 1] = superclass_id;

    return value_id;
}

static uint32_t
emit_define_class_recv_rel(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t receiver_id, uint32_t graph_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnDefineClassRecvRel, node_id, 2);
    insn->as.define.name_id = name_id;
    insn->as.define.graph_id = graph_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;
    graph->opnds[insn->opnds_off + 1] = receiver_id;

    return value_id;
}

static uint32_t
emit_define_class_recv_rel_super(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t receiver_id, uint32_t superclass_id, uint32_t graph_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnDefineClassRecvRelSuper, node_id, 3);
    insn->as.define.name_id = name_id;
    insn->as.define.graph_id = graph_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;
    graph->opnds[insn->opnds_off + 1] = receiver_id;
    graph->opnds[insn->opnds_off + 2] = superclass_id;

    return value_id;
}

static void
emit_define_method(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t graph_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnDefineMethod, node_id, 0);
    insn->as.define.name_id = name_id;
    insn->as.define.graph_id = graph_id;
}

static uint32_t
emit_define_singleton_class(PrismBuilder *builder, uint32_t node_id, uint32_t graph_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnDefineSingletonClass, node_id, 1);
    insn->as.define_singleton_class.graph_id = graph_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_defined_cvar(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnDefinedCVar, node_id, 1);
    insn->as.name.name_id = name_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_defined_gvar(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnDefinedGVar, node_id, 1);
    insn->as.name.name_id = name_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_extract_last_match_group(PrismBuilder *builder, uint32_t node_id, uint32_t last_match_id, uint32_t number) {
    PrismInsn *insn = make_insn(builder, kPrismInsnExtractLastMatchGroup, node_id, 2);
    insn->as.extract_group.number = number;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;
    graph->opnds[insn->opnds_off + 1] = last_match_id;

    return value_id;
}

static uint32_t
emit_extract_last_match_match(PrismBuilder *builder, uint32_t node_id, uint32_t last_match_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnExtractLastMatchMatch, node_id, 2);

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;
    graph->opnds[insn->opnds_off + 1] = last_match_id;

    return value_id;
}

static uint32_t
emit_extract_last_match_paren(PrismBuilder *builder, uint32_t node_id, uint32_t last_match_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnExtractLastMatchParen, node_id, 2);

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;
    graph->opnds[insn->opnds_off + 1] = last_match_id;

    return value_id;
}

static uint32_t
emit_extract_last_match_post(PrismBuilder *builder, uint32_t node_id, uint32_t last_match_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnExtractLastMatchPost, node_id, 2);

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;
    graph->opnds[insn->opnds_off + 1] = last_match_id;

    return value_id;
}

static uint32_t
emit_extract_last_match_pre(PrismBuilder *builder, uint32_t node_id, uint32_t last_match_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnExtractLastMatchPre, node_id, 2);

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;
    graph->opnds[insn->opnds_off + 1] = last_match_id;

    return value_id;
}

static uint32_t
emit_load_const_abs(PrismBuilder *builder, uint32_t node_id, PrismConstantPath constant_path) {
    PrismInsn *insn = make_insn(builder, kPrismInsnLoadConstAbs, node_id, 1);
    insn->as.constant_path = constant_path;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_load_const_nest_rel(PrismBuilder *builder, uint32_t node_id, PrismConstantPath constant_path) {
    PrismInsn *insn = make_insn(builder, kPrismInsnLoadConstNestRel, node_id, 1);
    insn->as.constant_path = constant_path;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_load_const_recv_rel(PrismBuilder *builder, uint32_t node_id, uint32_t receiver_id, PrismConstantPath constant_path) {
    PrismInsn *insn = make_insn(builder, kPrismInsnLoadConstRecvRel, node_id, 2);
    insn->as.constant_path = constant_path;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;
    graph->opnds[insn->opnds_off + 1] = receiver_id;

    return value_id;
}

static uint32_t
emit_load_name(PrismBuilder *builder, uint32_t node_id, PrismInsnKind kind, pm_constant_id_t name_id) {
    PrismInsn *insn = make_insn(builder, kind, node_id, 1);
    insn->as.name.name_id = name_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_load_cvar(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id) {
    return emit_load_name(builder, node_id, kPrismInsnLoadCVar, name_id);
}

static uint32_t
emit_load_gvar(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id) {
    return emit_load_name(builder, node_id, kPrismInsnLoadGVar, name_id);
}

static uint32_t
emit_load_ivar(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id) {
    return emit_load_name(builder, node_id, kPrismInsnLoadIVar, name_id);
}

static uint32_t
emit_load_last_match(PrismBuilder *builder, uint32_t node_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnLoadLastMatch, node_id, 1);

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_load_lvar(PrismBuilder *builder, uint32_t node_id, uint32_t local_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnLoadLVar, node_id, 1);
    insn->as.lvar.local_id = local_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_load_object(PrismBuilder *builder, uint32_t node_id, uint32_t object_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnLoadObject, node_id, 1);
    insn->as.object.object_id = object_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_load_true(PrismBuilder *builder, uint32_t node_id) {
    return emit_load_object(builder, node_id, make_object(builder, kPrismObjectTrue));
}

static uint32_t
emit_load_false(PrismBuilder *builder, uint32_t node_id) {
    return emit_load_object(builder, node_id, make_object(builder, kPrismObjectFalse));
}

static uint32_t
emit_load_nil(PrismBuilder *builder, uint32_t node_id) {
    return emit_load_object(builder, node_id, make_object(builder, kPrismObjectNil));
}

static uint32_t
emit_load_self(PrismBuilder *builder, uint32_t node_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnLoadSelf, node_id, 1);

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_match(PrismBuilder *builder, uint32_t node_id, uint32_t value_id, uint32_t pattern_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnMatch, node_id, 3);

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t result_id = make_value(builder);
    graph->opnds[insn->opnds_off] = result_id;
    graph->opnds[insn->opnds_off + 1] = value_id;
    graph->opnds[insn->opnds_off + 2] = pattern_id;

    return result_id;
}

static uint32_t
emit_merge_hash(PrismBuilder *builder, uint32_t node_id, uint32_t left_id, uint32_t right_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnMergeHash, node_id, 3);

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;
    graph->opnds[insn->opnds_off + 1] = left_id;
    graph->opnds[insn->opnds_off + 2] = right_id;

    return value_id;
}

static uint32_t
emit_new_array(PrismBuilder *builder, uint32_t node_id, uint32_t nelement_ids, uint32_t *element_ids) {
    PrismInsn *insn = make_insn(builder, kPrismInsnNewArray, node_id, 1 + nelement_ids);

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;
    memcpy(graph->opnds + insn->opnds_off + 1, element_ids, nelement_ids * sizeof(uint32_t));

    return value_id;
}

static uint32_t
emit_new_array_static(PrismBuilder *builder, uint32_t node_id, uint32_t object_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnNewArrayStatic, node_id, 1);
    insn->as.object.object_id = object_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_new_hash(PrismBuilder *builder, uint32_t node_id, uint32_t nelement_ids, uint32_t *element_ids) {
    PrismInsn *insn = make_insn(builder, kPrismInsnNewHash, node_id, 1 + nelement_ids);

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;
    if (nelement_ids != 0) memcpy(graph->opnds + insn->opnds_off + 1, element_ids, nelement_ids * sizeof(uint32_t));

    return value_id;
}

static uint32_t
emit_new_hash_static(PrismBuilder *builder, uint32_t node_id, uint32_t object_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnNewHashStatic, node_id, 1);
    insn->as.object.object_id = object_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_new_range(PrismBuilder *builder, bool exclusive, uint32_t node_id, uint32_t left_id, uint32_t right_id) {
    PrismInsn *insn = make_insn(builder, exclusive ? kPrismInsnNewRangeExc : kPrismInsnNewRangeInc, node_id, 3);

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off + 0] = value_id;
    graph->opnds[insn->opnds_off + 1] = left_id;
    graph->opnds[insn->opnds_off + 2] = right_id;

    return value_id;
}

static uint32_t
emit_new_regexp(PrismBuilder *builder, uint32_t node_id, uint32_t nvalue_ids, uint32_t *value_ids, pm_node_flags_t flags) {
    PrismInsn *insn = make_insn(builder, kPrismInsnNewRegexp, node_id, 1 + nvalue_ids);
    insn->as.regexp.flags = flags;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;
    memcpy(graph->opnds + insn->opnds_off + 1, value_ids, nvalue_ids * sizeof(uint32_t));

    return value_id;
}

static uint32_t
emit_new_string(PrismBuilder *builder, uint32_t node_id, uint32_t nvalue_ids, uint32_t *value_ids) {
    PrismInsn *insn = make_insn(builder, kPrismInsnNewString, node_id, 1 + nvalue_ids);

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;
    memcpy(graph->opnds + insn->opnds_off + 1, value_ids, nvalue_ids * sizeof(uint32_t));

    return value_id;
}

static uint32_t
emit_new_symbol(PrismBuilder *builder, uint32_t node_id, uint32_t nvalue_ids, uint32_t *value_ids) {
    PrismInsn *insn = make_insn(builder, kPrismInsnNewSymbol, node_id, 1 + nvalue_ids);

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;
    memcpy(graph->opnds + insn->opnds_off + 1, value_ids, nvalue_ids * sizeof(uint32_t));

    return value_id;
}

static void
emit_return(PrismBuilder *builder, uint32_t node_id, uint32_t value_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnReturn, node_id, 1);

    PrismGraph *graph = PrismBuilder_graph(builder);
    graph->opnds[insn->opnds_off] = value_id;
}

static uint32_t
emit_store_const_abs(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t value_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnStoreConstAbs, node_id, 1);
    insn->as.name.name_id = name_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_store_const_nest_rel(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t value_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnStoreConstNestRel, node_id, 1);
    insn->as.name.name_id = name_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_store_const_recv_rel(PrismBuilder *builder, uint32_t node_id, uint32_t receiver_id, pm_constant_id_t name_id, uint32_t value_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnStoreConstRecvRel, node_id, 2);
    insn->as.name.name_id = name_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    graph->opnds[insn->opnds_off] = receiver_id;
    graph->opnds[insn->opnds_off + 1] = value_id;

    return value_id;
}

static void
emit_store_name(PrismBuilder *builder, uint32_t node_id, PrismInsnKind kind, pm_constant_id_t name_id, uint32_t value_id) {
    PrismInsn *insn = make_insn(builder, kind, node_id, 1);
    insn->as.name.name_id = name_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    graph->opnds[insn->opnds_off] = value_id;
}

static void
emit_store_cvar(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t value_id) {
    emit_store_name(builder, node_id, kPrismInsnStoreCVar, name_id, value_id);
}

static void
emit_store_gvar(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t value_id) {
    emit_store_name(builder, node_id, kPrismInsnStoreGVar, name_id, value_id);
}

static void
emit_store_ivar(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t value_id) {
    emit_store_name(builder, node_id, kPrismInsnStoreIVar, name_id, value_id);
}

static void
emit_store_lvar(PrismBuilder *builder, uint32_t node_id, uint32_t local_id, uint32_t value_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnStoreLVar, node_id, 1);
    insn->as.lvar.local_id = local_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    graph->opnds[insn->opnds_off] = value_id;
}

static void
emit_trace_call(PrismBuilder *builder, uint32_t node_id) {
    make_insn(builder, kPrismInsnTraceCall, node_id, 0);
}

static void
emit_trace_class(PrismBuilder *builder, uint32_t node_id) {
    make_insn(builder, kPrismInsnTraceClass, node_id, 0);
}

static void
emit_trace_end(PrismBuilder *builder, uint32_t node_id) {
    make_insn(builder, kPrismInsnTraceEnd, node_id, 0);
}

static void
emit_trace_line(PrismBuilder *builder, uint32_t node_id, int32_t lineno) {
    PrismInsn *insn = make_insn(builder, kPrismInsnTraceLine, node_id, 0);
    insn->as.trace_line.lineno = lineno;
}

static void
emit_trace_return(PrismBuilder *builder, uint32_t node_id, uint32_t value_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnTraceReturn, node_id, 1);

    PrismGraph *graph = PrismBuilder_graph(builder);
    graph->opnds[insn->opnds_off] = value_id;
}

static void
emit_undef_method(PrismBuilder *builder, uint32_t node_id, uint32_t name_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnUndefMethod, node_id, 1);

    PrismGraph *graph = PrismBuilder_graph(builder);
    graph->opnds[insn->opnds_off] = name_id;
}

/******************************************************************************/

static uint32_t
resolve_local(PrismBuilder *builder, pm_constant_id_t name_id, uint32_t depth) {
    uint32_t local_id = builder->bindings[name_id];

#ifndef NDEBUG
    uint32_t graph_id = builder->state.graph_id;
    for (uint32_t level = 0; level < depth; ++level) {
        graph_id = builder->unit->graphs[graph_id].parent_id;
        assert(graph_id != UINT32_MAX);
    }

    assert(local_id < builder->unit->nlocals);
    assert(builder->unit->locals[local_id].name_id == name_id);
    assert(builder->unit->locals[local_id].graph_id == graph_id);
#else
    (void) depth;
#endif

    return local_id;
}

static uint32_t
static_literal(PrismBuilder *builder, const pm_node_t *node) {
    assert(PM_NODE_FLAG_P(node, PM_NODE_FLAG_STATIC_LITERAL));

    switch (PM_NODE_TYPE(node)) {
        case PM_ARRAY_NODE: {
            const pm_array_node_t *cast = (const pm_array_node_t *) node;
            uint32_t nobject_ids = (uint32_t) cast->elements.size;
            uint32_t *object_ids = pm_arena_alloc(builder->arena, sizeof(uint32_t) * nobject_ids, PRISM_ALIGNOF(uint32_t));

            for (uint32_t idx = 0; idx < nobject_ids; ++idx) {
                object_ids[idx] = static_literal(builder, cast->elements.nodes[idx]);
            }

            uint32_t object_id = make_object(builder, kPrismObjectArray);
            PrismObject *object = builder->unit->objects + object_id;
            object->as.array.nobject_ids = nobject_ids;
            object->as.array.object_ids = object_ids;

            return object_id;
        }
        case PM_FLOAT_NODE: {
            const pm_float_node_t *cast = (const pm_float_node_t *) node;

            uint32_t object_id = make_object(builder, kPrismObjectFloat);
            PrismObject *object = builder->unit->objects + object_id;
            object->as.floating.value = cast->value;

            return object_id;
        }
        case PM_HASH_NODE: {
            const pm_hash_node_t *cast = (const pm_hash_node_t *) node;
            uint32_t nobject_ids = (uint32_t) cast->elements.size * 2;
            uint32_t *object_ids = pm_arena_alloc(builder->arena, sizeof(uint32_t) * nobject_ids, PRISM_ALIGNOF(uint32_t));

            for (uint32_t idx = 0; idx < nobject_ids; idx += 2) {
                const pm_assoc_node_t *assoc = (const pm_assoc_node_t *) cast->elements.nodes[idx >> 1];
                object_ids[idx] = static_literal(builder, assoc->key);
                object_ids[idx + 1] = static_literal(builder, assoc->value);
            }

            uint32_t object_id = make_object(builder, kPrismObjectHash);
            PrismObject *object = builder->unit->objects + object_id;
            object->as.hash.nobject_ids = nobject_ids;
            object->as.hash.object_ids = object_ids;

            return object_id;
        }
        case PM_IMAGINARY_NODE: {
            const pm_imaginary_node_t *cast = (const pm_imaginary_node_t *) node;

            uint32_t numeric_id = static_literal(builder, cast->numeric);
            uint32_t object_id = make_object(builder, kPrismObjectImaginary);
            PrismObject *object = builder->unit->objects + object_id;
            object->as.imaginary.numeric_id = numeric_id;

            return object_id;
        }
        case PM_INTEGER_NODE: {
            const pm_integer_node_t *cast = (const pm_integer_node_t *) node;

            uint32_t object_id = make_object(builder, kPrismObjectInteger);
            PrismObject *object = builder->unit->objects + object_id;
            object->as.integer.value = &cast->value;

            return object_id;
        }
        case PM_RATIONAL_NODE: {
            const pm_rational_node_t *cast = (const pm_rational_node_t *) node;

            uint32_t object_id = make_object(builder, kPrismObjectRational);
            PrismObject *object = builder->unit->objects + object_id;
            object->as.rational.numerator = &cast->numerator;
            object->as.rational.denominator = &cast->denominator;

            return object_id;
        }
        case PM_STRING_NODE: {
            const pm_string_node_t *cast = (const pm_string_node_t *) node;

            uint32_t object_id = make_object(builder, kPrismObjectString);
            PrismObject *object = builder->unit->objects + object_id;
            object->as.string.flags = node->flags;
            object->as.string.unescaped = &cast->unescaped;

            return object_id;
        }
        case PM_SYMBOL_NODE: {
            const pm_symbol_node_t *cast = (const pm_symbol_node_t *) node;

            uint32_t object_id = make_object(builder, kPrismObjectSymbol);
            PrismObject *object = builder->unit->objects + object_id;
            object->as.string.flags = node->flags;
            object->as.string.unescaped = &cast->unescaped;

            return object_id;
        }
        default:
            fprintf(stderr, "unsupported static literal node type: %s\n", pm_node_type(node->type));
            abort();
    }
}

/******************************************************************************/

static uint32_t compile_node(PrismBuilder *builder, const pm_node_t *node);

static uint32_t
compile_instance_variable_logical_write_node(PrismBuilder *builder, const pm_node_t *node, pm_constant_id_t name, const pm_node_t *value) {
    uint32_t set_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    uint32_t predicate_id = emit_load_ivar(builder, node->node_id, name);
    if (PM_NODE_TYPE(node) == PM_INSTANCE_VARIABLE_AND_WRITE_NODE) {
        emit_branchif(builder, node->node_id, predicate_id, set_block_id, 0, NULL, join_block_id, 1, &predicate_id);
    } else {
        emit_branchif(builder, node->node_id, predicate_id, join_block_id, 1, &predicate_id, set_block_id, 0, NULL);
    }

    builder->state.block_id = set_block_id;
    uint32_t value_id = compile_node(builder, value);
    emit_store_ivar(builder, node->node_id, name, value_id);
    emit_branch(builder, node->node_id, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

static uint32_t
compile_local_variable_logical_write_node(PrismBuilder *builder, const pm_node_t *node, pm_constant_id_t name_id, uint32_t depth, const pm_node_t *value) {
    uint32_t set_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    uint32_t resolved_id = resolve_local(builder, name_id, depth);
    uint32_t local_id = emit_load_lvar(builder, node->node_id, resolved_id);
    if (PM_NODE_TYPE_P(node, PM_LOCAL_VARIABLE_AND_WRITE_NODE)) {
        emit_branchif(builder, node->node_id, local_id, set_block_id, 0, NULL, join_block_id, 1, &local_id);
    } else {
        emit_branchif(builder, node->node_id, local_id, join_block_id, 1, &local_id, set_block_id, 0, NULL);
    }

    builder->state.block_id = set_block_id;
    uint32_t value_id = compile_node(builder, value);
    emit_store_lvar(builder, node->node_id, resolved_id, value_id);
    emit_branch(builder, node->node_id, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

static uint32_t
compile_logical_node(PrismBuilder *builder, const pm_node_t *node, const pm_node_t *left, const pm_node_t *right) {
    uint32_t right_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    uint32_t left_value_id = compile_node(builder, left);
    if (PM_NODE_TYPE(node) == PM_AND_NODE) {
        emit_branchif(builder, node->node_id, left_value_id, right_block_id, 0, NULL, join_block_id, 1, &left_value_id);
    } else {
        emit_branchif(builder, node->node_id, left_value_id, join_block_id, 1, &left_value_id, right_block_id, 0, NULL);
    }

    builder->state.block_id = right_block_id;
    uint32_t right_value_id = compile_node(builder, right);
    emit_branch(builder, node->node_id, join_block_id, 1, &right_value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

static uint32_t
compile_loop_node(PrismBuilder *builder, const pm_node_t *node, const pm_node_t *predicate, const pm_statements_node_t *statements) {
    uint32_t predicate_block_id = make_block(builder, 0);
    uint32_t loop_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 0);

    emit_branch(builder, node->node_id, PM_NODE_FLAG_P(node, PM_LOOP_FLAGS_BEGIN_MODIFIER) ? loop_block_id : predicate_block_id, 0, NULL);

    builder->state.block_id = predicate_block_id;
    uint32_t predicate_id = compile_node(builder, predicate);
    if (PM_NODE_TYPE_P(node, PM_WHILE_NODE)) {
        emit_branchif(builder, node->node_id, predicate_id, loop_block_id, 0, NULL, join_block_id, 0, NULL);
    } else {
        emit_branchif(builder, node->node_id, predicate_id, join_block_id, 0, NULL, loop_block_id, 0, NULL);
    }

    builder->state.block_id = loop_block_id;
    if (statements) {
        compile_node(builder, PM_NODE_UPCAST(statements));
    }
    emit_branch(builder, node->node_id, predicate_block_id, 0, NULL);

    builder->state.block_id = join_block_id;
    return emit_load_nil(builder, node->node_id);
}

static void
compile_pattern_match(PrismBuilder *builder, const pm_node_t *node, uint32_t value_id, uint32_t matched_block_id, uint32_t unmatched_block_id) {
    switch (PM_NODE_TYPE(node)) {
        case PM_ALTERNATION_PATTERN_NODE: {
            const pm_alternation_pattern_node_t *cast = (const pm_alternation_pattern_node_t *) node;

            uint32_t else_block_id = make_block(builder, 0);
            compile_pattern_match(builder, cast->left, value_id, matched_block_id, else_block_id);

            builder->state.block_id = else_block_id;
            compile_pattern_match(builder, cast->right, value_id, matched_block_id, unmatched_block_id);
            break;
        }
        case PM_ARRAY_NODE:
        case PM_CONSTANT_PATH_NODE:
        case PM_CONSTANT_READ_NODE:
        case PM_FALSE_NODE:
        case PM_FLOAT_NODE:
        case PM_GLOBAL_VARIABLE_READ_NODE:
        case PM_IMAGINARY_NODE:
        case PM_INSTANCE_VARIABLE_READ_NODE:
        /* case PM_IT_LOCAL_VARIABLE_READ_NODE: */
        case PM_INTEGER_NODE:
        case PM_INTERPOLATED_REGULAR_EXPRESSION_NODE:
        case PM_INTERPOLATED_STRING_NODE:
        case PM_INTERPOLATED_SYMBOL_NODE:
        case PM_INTERPOLATED_X_STRING_NODE:
        /* case PM_LAMBDA_NODE: */
        case PM_LOCAL_VARIABLE_READ_NODE:
        case PM_NIL_NODE:
        case PM_SOURCE_ENCODING_NODE:
        /* case PM_SOURCE_FILE_NODE: */
        case PM_SOURCE_LINE_NODE:
        case PM_RANGE_NODE:
        case PM_RATIONAL_NODE:
        case PM_REGULAR_EXPRESSION_NODE:
        case PM_SELF_NODE:
        case PM_STRING_NODE:
        case PM_SYMBOL_NODE:
        case PM_TRUE_NODE:
        case PM_X_STRING_NODE: {
            uint32_t pattern_id = compile_node(builder, node);
            uint32_t predicate_id = emit_match(builder, node->node_id, value_id, pattern_id);
            emit_branchif(builder, node->node_id, predicate_id, matched_block_id, 0, NULL, unmatched_block_id, 0, NULL);
            break;
        }
        default:
            fprintf(stderr, "Unsupported pattern: %s\n", pm_node_type(node->type));
            abort();
    }
}

/******************************************************************************/

static uint32_t
compile_alias_method_node(PrismBuilder *builder, const pm_alias_method_node_t *node) {
    uint32_t new_name_id = compile_node(builder, node->new_name);
    uint32_t old_name_id = compile_node(builder, node->old_name);
    emit_alias_method(builder, node->base.node_id, new_name_id, old_name_id);
    return emit_load_nil(builder, node->base.node_id);
}

static uint32_t
compile_and_node(PrismBuilder *builder, const pm_and_node_t *node) {
    return compile_logical_node(builder, PM_NODE_UPCAST(node), node->left, node->right);
}

static uint32_t
compile_array_node(PrismBuilder *builder, const pm_array_node_t *node) {
    size_t nelements = node->elements.size;

    if (PM_NODE_FLAG_P(node, PM_NODE_FLAG_STATIC_LITERAL) && nelements) {
        uint32_t object_id = static_literal(builder, PM_NODE_UPCAST(node));
        return emit_new_array_static(builder, node->base.node_id, object_id);
    } else {
        uint32_t *element_ids = pm_arena_alloc(builder->arena, sizeof(uint32_t) * nelements, PRISM_ALIGNOF(uint32_t));
        for (size_t idx = 0; idx < nelements; ++idx) {
            element_ids[idx] = compile_node(builder, node->elements.nodes[idx]);
        }

        return emit_new_array(builder, node->base.node_id, (uint32_t) nelements, element_ids);
    }
}

static uint32_t
compile_back_reference_read_node(PrismBuilder *builder, const pm_back_reference_read_node_t *node) {
    const pm_constant_t *constant = compile_constant(builder->parser, node->name);
    uint32_t last_match_id = emit_load_last_match(builder, node->base.node_id);
    uint32_t value_id;

    switch (pm_constant_start(constant)[1]) {
        case '&':
            value_id = emit_extract_last_match_match(builder, node->base.node_id, last_match_id);
            break;
        case '`':
            value_id = emit_extract_last_match_pre(builder, node->base.node_id, last_match_id);
            break;
        case '\'':
            value_id = emit_extract_last_match_post(builder, node->base.node_id, last_match_id);
            break;
        case '+':
            value_id = emit_extract_last_match_paren(builder, node->base.node_id, last_match_id);
            break;
        default:
            assert(false && "unreachable");
            value_id = UINT32_MAX;
            break;
    }

    return value_id;
}

static uint32_t
compile_call_node(PrismBuilder *builder, const pm_call_node_t *node) {
    uint32_t receiver_id;
    if (node->receiver) {
        receiver_id = compile_node(builder, node->receiver);
    } else {
        receiver_id = emit_load_self(builder, node->base.node_id);
    }

    size_t nargument_ids = 0;
    uint32_t *argument_ids = NULL;

    if (node->arguments) {
        nargument_ids = node->arguments->arguments.size;
        argument_ids = pm_arena_alloc(builder->arena, sizeof(uint32_t) * nargument_ids, PRISM_ALIGNOF(uint32_t));

        for (size_t idx = 0; idx < nargument_ids; ++idx) {
            argument_ids[idx] = compile_node(builder, node->arguments->arguments.nodes[idx]);
        }
    }

    return emit_call(builder, node->base.node_id, node->name, receiver_id, nargument_ids, argument_ids);
}

static uint32_t
compile_class_node(PrismBuilder *builder, const pm_class_node_t *node) {
    uint32_t graph_id = make_graph(builder, kPrismGraphClass, UINT32_MAX, (uint32_t) node->locals.size);
    PrismBuilderState state = push_scope(builder, graph_id, 0, &node->locals);

    emit_trace_class(builder, node->base.node_id);
    uint32_t value_id = UINT32_MAX;

    if (node->body) {
        value_id = compile_node(builder, node->body);
    }

    if (value_id == UINT32_MAX) {
        value_id = emit_load_nil(builder, node->base.node_id);
    }

    emit_trace_end(builder, node->base.node_id);
    emit_return(builder, node->base.node_id, value_id);
    pop_scope(builder, state);

    uint32_t result_id;
    if (PM_NODE_TYPE_P(node->constant_path, PM_CONSTANT_READ_NODE)) {
        if (node->superclass) {
            uint32_t superclass_id = compile_node(builder, node->superclass);
            result_id = emit_define_class_nest_rel_super(builder, node->base.node_id, node->name, superclass_id, graph_id);
        } else {
            result_id = emit_define_class_nest_rel(builder, node->base.node_id, node->name, graph_id);
        }
    } else {
        const pm_constant_path_node_t *constant_path = (const pm_constant_path_node_t *) node->constant_path;
        if (constant_path->parent) {
            uint32_t receiver_id = compile_node(builder, constant_path->parent);
            if (node->superclass) {
                uint32_t superclass_id = compile_node(builder, node->superclass);
                result_id = emit_define_class_recv_rel_super(builder, node->base.node_id, node->name, receiver_id, superclass_id, graph_id);
            } else {
                result_id = emit_define_class_recv_rel(builder, node->base.node_id, node->name, receiver_id, graph_id);
            }
        } else if (node->superclass) {
            uint32_t superclass_id = compile_node(builder, node->superclass);
            result_id = emit_define_class_abs_super(builder, node->base.node_id, node->name, superclass_id, graph_id);
        } else {
            result_id = emit_define_class_abs(builder, node->base.node_id, node->name, graph_id);
        }
    }

    return result_id;
}

static uint32_t
compile_class_variable_read_node(PrismBuilder *builder, const pm_class_variable_read_node_t *node) {
    return emit_load_cvar(builder, node->base.node_id, node->name);
}

static uint32_t
compile_class_variable_write_node(PrismBuilder *builder, const pm_class_variable_write_node_t *node) {
    uint32_t value_id = compile_node(builder, node->value);
    emit_store_cvar(builder, node->base.node_id, node->name, value_id);
    return value_id;
}

static uint32_t
compile_class_variable_operator_write_node(PrismBuilder *builder, const pm_class_variable_operator_write_node_t *node) {
    uint32_t receiver_id = emit_load_cvar(builder, node->base.node_id, node->name);
    uint32_t value_id = compile_node(builder, node->value);
    uint32_t result_id = emit_call(builder, node->base.node_id, node->binary_operator, receiver_id, 1, &value_id);
    emit_store_cvar(builder, node->base.node_id, node->name, result_id);
    return result_id;
}

static uint32_t
compile_class_variable_and_write_node(PrismBuilder *builder, const pm_class_variable_and_write_node_t *node) {
    uint32_t set_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    uint32_t predicate_id = emit_load_cvar(builder, node->base.node_id, node->name);
    emit_branchif(builder, node->base.node_id, predicate_id, set_block_id, 0, NULL, join_block_id, 1, &predicate_id);

    builder->state.block_id = set_block_id;
    uint32_t value_id = compile_node(builder, node->value);
    emit_store_cvar(builder, node->base.node_id, node->name, value_id);
    emit_branch(builder, node->base.node_id, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

static uint32_t
compile_class_variable_or_write_node(PrismBuilder *builder, const pm_class_variable_or_write_node_t *node) {
    uint32_t defined_block_id = make_block(builder, 0);
    uint32_t undefined_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    uint32_t defined_id = emit_defined_cvar(builder, node->base.node_id, node->name);
    emit_branchif(builder, node->base.node_id, defined_id, defined_block_id, 0, NULL, undefined_block_id, 0, NULL);

    builder->state.block_id = defined_block_id;
    uint32_t predicate_id = emit_load_cvar(builder, node->base.node_id, node->name);
    emit_branchif(builder, node->base.node_id, predicate_id, join_block_id, 1, &predicate_id, undefined_block_id, 0, NULL);

    builder->state.block_id = undefined_block_id;
    uint32_t value_id = compile_node(builder, node->value);
    emit_store_cvar(builder, node->base.node_id, node->name, value_id);
    emit_branch(builder, node->base.node_id, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

static uint32_t
compile_constant_read_node(PrismBuilder *builder, const pm_constant_read_node_t *node) {
    PrismConstantPath constant_path = PrismConstantPath_new(builder, 1);
    PrismConstantPath_set(&constant_path, 0, node->name);
    return emit_load_const_nest_rel(builder, node->base.node_id, constant_path);
}

static uint32_t
compile_constant_write_node(PrismBuilder *builder, const pm_constant_write_node_t *node) {
    uint32_t value_id = compile_node(builder, node->value);
    emit_store_const_nest_rel(builder, node->base.node_id, node->name, value_id);
    return value_id;
}

static uint32_t
compile_constant_operator_write_node(PrismBuilder *builder, const pm_constant_operator_write_node_t *node) {
    PrismConstantPath constant_path = PrismConstantPath_new(builder, 1);
    PrismConstantPath_set(&constant_path, 0, node->name);

    uint32_t receiver_id = emit_load_const_nest_rel(builder, node->base.node_id, constant_path);
    uint32_t value_id = compile_node(builder, node->value);
    uint32_t result_id = emit_call(builder, node->base.node_id, node->binary_operator, receiver_id, 1, &value_id);
    emit_store_const_nest_rel(builder, node->base.node_id, node->name, result_id);

    return result_id;
}

static uint32_t
compile_constant_path_node(PrismBuilder *builder, const pm_constant_path_node_t *node) {
    const pm_node_t *current = PM_NODE_UPCAST(node);
    uint32_t depth = 0;

    while (current && PM_NODE_TYPE_P(current, PM_CONSTANT_PATH_NODE)) {
        current = ((const pm_constant_path_node_t *) current)->parent;
        depth++;
    }

    if (current && PM_NODE_TYPE_P(current, PM_CONSTANT_READ_NODE)) {
        depth++;
    }

    PrismConstantPath constant_path = PrismConstantPath_new(builder, depth);
    current = PM_NODE_UPCAST(node);

    while (current && PM_NODE_TYPE_P(current, PM_CONSTANT_PATH_NODE)) {
        PrismConstantPath_set(&constant_path, --depth, (uint32_t) ((const pm_constant_path_node_t *) current)->name);
        current = ((const pm_constant_path_node_t *) current)->parent;
    }

    uint32_t value_id;
    if (!current) {
        value_id = emit_load_const_abs(builder, node->base.node_id, constant_path);
    } else if (PM_NODE_TYPE_P(current, PM_CONSTANT_READ_NODE)) {
        PrismConstantPath_set(&constant_path, 0, (uint32_t) ((const pm_constant_read_node_t *) current)->name);
        value_id = emit_load_const_nest_rel(builder, node->base.node_id, constant_path);
    } else {
        uint32_t receiver_id = compile_node(builder, current);
        value_id = emit_load_const_recv_rel(builder, node->base.node_id, receiver_id, constant_path);
    }

    return value_id;
}

static uint32_t
compile_constant_path_write_node(PrismBuilder *builder, const pm_constant_path_write_node_t *node) {
    if (node->target->parent) {
        uint32_t receiver_id = compile_node(builder, node->target->parent);
        uint32_t value_id = compile_node(builder, node->value);

        return emit_store_const_recv_rel(builder, node->base.node_id, receiver_id, node->target->name, value_id);
    } else {
        uint32_t value_id = compile_node(builder, node->value);
        return emit_store_const_abs(builder, node->base.node_id, node->target->name, value_id);
    }
}

static uint32_t
compile_constant_path_operator_write_node(PrismBuilder *builder, const pm_constant_path_operator_write_node_t *node) {
    PrismConstantPath constant_path = PrismConstantPath_new(builder, 1);
    PrismConstantPath_set(&constant_path, 0, (uint32_t) node->target->name);

    if (node->target->parent) {
        uint32_t parent_id = compile_node(builder, node->target->parent);

        uint32_t receiver_id = emit_load_const_recv_rel(builder, node->base.node_id, parent_id, constant_path);
        uint32_t value_id = compile_node(builder, node->value);
        uint32_t result_id = emit_call(builder, node->base.node_id, node->binary_operator, receiver_id, 1, &value_id);

        return emit_store_const_recv_rel(builder, node->base.node_id, parent_id, node->target->name, result_id);
    } else {
        uint32_t receiver_id = emit_load_const_abs(builder, node->base.node_id, constant_path);
        uint32_t value_id = compile_node(builder, node->value);
        uint32_t result_id = emit_call(builder, node->base.node_id, node->binary_operator, receiver_id, 1, &value_id);

        return emit_store_const_abs(builder, node->base.node_id, node->target->name, result_id);
    }
}

static uint32_t
compile_def_node(PrismBuilder *builder, const pm_def_node_t *node) {
    uint32_t graph_id = make_graph(builder, kPrismGraphDef, UINT32_MAX, (uint32_t) node->locals.size);

    uint32_t nparams = 0;
    const pm_parameters_node_t *parameters = node->parameters;
    if (parameters) {
        nparams = (uint32_t) parameters->requireds.size;
    }

    PrismBuilderState state = push_scope(builder, graph_id, nparams, &node->locals);
    uint32_t *params = PrismBuilder_graph(builder)->blocks[builder->state.block_id].params;

    if (parameters) {
        for (size_t idx = 0; idx < parameters->requireds.size; ++idx) {
            const pm_node_t *required = parameters->requireds.nodes[idx];

            if (PM_NODE_TYPE_P(required, PM_REQUIRED_PARAMETER_NODE)) {
                uint32_t resolved_id = resolve_local(builder, ((const pm_required_parameter_node_t *) required)->name, 0);
                emit_store_lvar(builder, required->node_id, resolved_id, params[idx]);
            }
        }
    }

    emit_trace_call(builder, node->base.node_id);

    uint32_t value_id = UINT32_MAX;
    if (node->body) {
        value_id = compile_node(builder, node->body);
    }

    if (value_id == UINT32_MAX) {
        value_id = emit_load_nil(builder, node->base.node_id);
    }

    emit_trace_return(builder, node->base.node_id, value_id);
    emit_return(builder, node->base.node_id, value_id);

    pop_scope(builder, state);
    emit_define_method(builder, node->base.node_id, node->name, graph_id);

    uint32_t object_id = make_object_constant_id(builder, node->name);
    return emit_load_object(builder, node->base.node_id, object_id);
}

static uint32_t
compile_embedded_statements_node(PrismBuilder *builder, const pm_embedded_statements_node_t *node) {
    uint32_t string_id;
    if (node->statements) {
        string_id = compile_node(builder, PM_NODE_UPCAST(node->statements));
    } else {
        string_id = emit_load_nil(builder, node->base.node_id);
    }

    return emit_coerce_string(builder, node->base.node_id, string_id);
}

static uint32_t
compile_embedded_variable_node(PrismBuilder *builder, const pm_embedded_variable_node_t *node) {
    uint32_t string_id = compile_node(builder, node->variable);
    return emit_coerce_string(builder, node->base.node_id, string_id);
}

static uint32_t
compile_false_node(PrismBuilder *builder, const pm_false_node_t *node) {
    return emit_load_false(builder, node->base.node_id);
}

static uint32_t
compile_float_node(PrismBuilder *builder, const pm_float_node_t *node) {
    uint32_t object_id = static_literal(builder, PM_NODE_UPCAST(node));
    return emit_load_object(builder, node->base.node_id, object_id);
}

static uint32_t
compile_global_variable_read_node(PrismBuilder *builder, const pm_global_variable_read_node_t *node) {
    return emit_load_gvar(builder, node->base.node_id, node->name);
}

static uint32_t
compile_global_variable_write_node(PrismBuilder *builder, const pm_global_variable_write_node_t *node) {
    uint32_t value_id = compile_node(builder, node->value);
    emit_store_gvar(builder, node->base.node_id, node->name, value_id);
    return value_id;
}

static uint32_t
compile_global_variable_operator_write_node(PrismBuilder *builder, const pm_global_variable_operator_write_node_t *node) {
    uint32_t receiver_id = emit_load_gvar(builder, node->base.node_id, node->name);
    uint32_t value_id = compile_node(builder, node->value);
    uint32_t result_id = emit_call(builder, node->base.node_id, node->binary_operator, receiver_id, 1, &value_id);
    emit_store_gvar(builder, node->base.node_id, node->name, result_id);
    return result_id;
}

static uint32_t
compile_global_variable_and_write_node(PrismBuilder *builder, const pm_global_variable_and_write_node_t *node) {
    uint32_t set_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    uint32_t predicate_id = emit_load_gvar(builder, node->base.node_id, node->name);
    emit_branchif(builder, node->base.node_id, predicate_id, set_block_id, 0, NULL, join_block_id, 1, &predicate_id);

    builder->state.block_id = set_block_id;
    uint32_t value_id = compile_node(builder, node->value);
    emit_store_gvar(builder, node->base.node_id, node->name, value_id);
    emit_branch(builder, node->base.node_id, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

static uint32_t
compile_global_variable_or_write_node(PrismBuilder *builder, const pm_global_variable_or_write_node_t *node) {
    uint32_t defined_block_id = make_block(builder, 0);
    uint32_t undefined_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    uint32_t defined_id = emit_defined_gvar(builder, node->base.node_id, node->name);
    emit_branchif(builder, node->base.node_id, defined_id, defined_block_id, 0, NULL, undefined_block_id, 0, NULL);

    builder->state.block_id = defined_block_id;
    uint32_t predicate_id = emit_load_gvar(builder, node->base.node_id, node->name);
    emit_branchif(builder, node->base.node_id, predicate_id, join_block_id, 1, &predicate_id, undefined_block_id, 0, NULL);

    builder->state.block_id = undefined_block_id;
    uint32_t value_id = compile_node(builder, node->value);
    emit_store_gvar(builder, node->base.node_id, node->name, value_id);
    emit_branch(builder, node->base.node_id, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

static uint32_t
compile_hash_node(PrismBuilder *builder, const pm_hash_node_t *node) {
    size_t nelements = node->elements.size;
    uint32_t value_id = UINT32_MAX;

    if (PM_NODE_FLAG_P(node, PM_NODE_FLAG_STATIC_LITERAL) && nelements) {
        uint32_t object_id = static_literal(builder, PM_NODE_UPCAST(node));
        value_id = emit_new_hash_static(builder, node->base.node_id, object_id);
    } else {
        for (uint32_t element_idx = 0; element_idx < nelements; ++element_idx) {
            uint32_t assocs_start_idx = element_idx;
            while (element_idx < nelements && PM_NODE_TYPE_P(node->elements.nodes[element_idx], PM_ASSOC_NODE)) element_idx++;

            if (assocs_start_idx < element_idx) {
                uint32_t nvalue_ids = (element_idx - assocs_start_idx) * 2;
                uint32_t *value_ids = pm_arena_alloc(builder->arena, sizeof(uint32_t) * nvalue_ids, PRISM_ALIGNOF(uint32_t));

                for (uint32_t assoc_idx = assocs_start_idx; assoc_idx < element_idx; ++assoc_idx) {
                    const pm_assoc_node_t *assoc = (const pm_assoc_node_t *) node->elements.nodes[assoc_idx];
                    value_ids[(assoc_idx - assocs_start_idx) * 2] = compile_node(builder, assoc->key);
                    value_ids[(assoc_idx - assocs_start_idx) * 2 + 1] = compile_node(builder, assoc->value);
                }

                uint32_t hash_id = emit_new_hash(builder, node->base.node_id, nvalue_ids, value_ids);
                value_id = value_id == UINT32_MAX ? hash_id : emit_merge_hash(builder, node->base.node_id, value_id, hash_id);
            }

            if (element_idx < nelements) {
                const pm_assoc_splat_node_t *assoc_splat = (const pm_assoc_splat_node_t *) node->elements.nodes[element_idx];
                uint32_t splat_id = compile_node(builder, assoc_splat->value);
                uint32_t hash_id = emit_coerce_hash(builder, assoc_splat->base.node_id, splat_id);
                value_id = value_id == UINT32_MAX ? hash_id : emit_merge_hash(builder, node->base.node_id, value_id, hash_id);
            }
        }
    }

    if (value_id == UINT32_MAX) value_id = emit_new_hash(builder, node->base.node_id, 0, NULL);
    return value_id;
}

static uint32_t
compile_imaginary_node(PrismBuilder *builder, const pm_imaginary_node_t *node) {
    uint32_t object_id = static_literal(builder, PM_NODE_UPCAST(node));
    return emit_load_object(builder, node->base.node_id, object_id);
}

static uint32_t
compile_implicit_node(PrismBuilder *builder, const pm_implicit_node_t *node) {
    return compile_node(builder, node->value);
}

static uint32_t
compile_instance_variable_read_node(PrismBuilder *builder, const pm_instance_variable_read_node_t *node) {
    return emit_load_ivar(builder, node->base.node_id, node->name);
}

static uint32_t
compile_instance_variable_write_node(PrismBuilder *builder, const pm_instance_variable_write_node_t *node) {
    uint32_t value_id = compile_node(builder, node->value);
    emit_store_ivar(builder, node->base.node_id, node->name, value_id);
    return value_id;
}

static uint32_t
compile_instance_variable_operator_write_node(PrismBuilder *builder, const pm_instance_variable_operator_write_node_t *node) {
    uint32_t receiver_id = emit_load_ivar(builder, node->base.node_id, node->name);
    uint32_t value_id = compile_node(builder, node->value);
    uint32_t result_id = emit_call(builder, node->base.node_id, node->binary_operator, receiver_id, 1, &value_id);
    emit_store_ivar(builder, node->base.node_id, node->name, result_id);
    return result_id;
}

static uint32_t
compile_instance_variable_and_write_node(PrismBuilder *builder, const pm_instance_variable_and_write_node_t *node) {
    return compile_instance_variable_logical_write_node(builder, PM_NODE_UPCAST(node), node->name, node->value);
}

static uint32_t
compile_instance_variable_or_write_node(PrismBuilder *builder, const pm_instance_variable_or_write_node_t *node) {
    return compile_instance_variable_logical_write_node(builder, PM_NODE_UPCAST(node), node->name, node->value);
}

static uint32_t
compile_integer_node(PrismBuilder *builder, const pm_integer_node_t *node) {
    uint32_t object_id = static_literal(builder, PM_NODE_UPCAST(node));
    return emit_load_object(builder, node->base.node_id, object_id);
}

static uint32_t
compile_interpolated_regular_expression_node(PrismBuilder *builder, const pm_interpolated_regular_expression_node_t *node) {
    uint32_t nvalue_ids = (uint32_t) node->parts.size;
    uint32_t *value_ids = pm_arena_alloc(builder->arena, nvalue_ids * sizeof(uint32_t), PRISM_ALIGNOF(uint32_t));

    for (uint32_t idx = 0; idx < nvalue_ids; ++idx) {
        value_ids[idx] = compile_node(builder, node->parts.nodes[idx]);
    }

    return emit_new_regexp(builder, node->base.node_id, nvalue_ids, value_ids, node->base.flags);
}

static uint32_t
compile_interpolated_string_node(PrismBuilder *builder, const pm_interpolated_string_node_t *node) {
    uint32_t nvalue_ids = (uint32_t) node->parts.size;
    uint32_t *value_ids = pm_arena_alloc(builder->arena, nvalue_ids * sizeof(uint32_t), PRISM_ALIGNOF(uint32_t));

    for (uint32_t idx = 0; idx < nvalue_ids; ++idx) {
        value_ids[idx] = compile_node(builder, node->parts.nodes[idx]);
    }

    return emit_new_string(builder, node->base.node_id, nvalue_ids, value_ids);
}

static uint32_t
compile_interpolated_symbol_node(PrismBuilder *builder, const pm_interpolated_symbol_node_t *node) {
    uint32_t nvalue_ids = (uint32_t) node->parts.size;
    uint32_t *value_ids = pm_arena_alloc(builder->arena, nvalue_ids * sizeof(uint32_t), PRISM_ALIGNOF(uint32_t));

    for (uint32_t idx = 0; idx < nvalue_ids; ++idx) {
        value_ids[idx] = compile_node(builder, node->parts.nodes[idx]);
    }

    return emit_new_symbol(builder, node->base.node_id, nvalue_ids, value_ids);
}

static uint32_t
compile_interpolated_x_string_node(PrismBuilder *builder, const pm_interpolated_x_string_node_t *node) {
    uint32_t receiver_id = emit_load_self(builder, node->base.node_id);
    uint32_t nvalue_ids = (uint32_t) node->parts.size;
    uint32_t *value_ids = pm_arena_alloc(builder->arena, nvalue_ids * sizeof(uint32_t), PRISM_ALIGNOF(uint32_t));

    for (uint32_t idx = 0; idx < nvalue_ids; ++idx) {
        value_ids[idx] = compile_node(builder, node->parts.nodes[idx]);
    }

    uint32_t string_id = emit_new_string(builder, node->base.node_id, nvalue_ids, value_ids);
    return emit_call(builder, node->base.node_id, PM_CONSTANT_ID_BACKTICK, receiver_id, 1, &string_id);
}

static uint32_t
compile_local_variable_read_node(PrismBuilder *builder, const pm_local_variable_read_node_t *node) {
    uint32_t local_id = resolve_local(builder, node->name, node->depth);
    return emit_load_lvar(builder, node->base.node_id, local_id);
}

static uint32_t
compile_local_variable_write_node(PrismBuilder *builder, const pm_local_variable_write_node_t *node) {
    uint32_t local_id = resolve_local(builder, node->name, node->depth);
    uint32_t value_id = compile_node(builder, node->value);
    emit_store_lvar(builder, node->base.node_id, local_id, value_id);
    return value_id;
}

static uint32_t
compile_local_variable_operator_write_node(PrismBuilder *builder, const pm_local_variable_operator_write_node_t *node) {
    uint32_t resolved_id = resolve_local(builder, node->name, node->depth);
    uint32_t local_id = emit_load_lvar(builder, node->base.node_id, resolved_id);
    uint32_t value_id = compile_node(builder, node->value);
    uint32_t result_id = emit_call(builder, node->base.node_id, node->binary_operator, local_id, 1, &value_id);
    emit_store_lvar(builder, node->base.node_id, resolved_id, result_id);
    return result_id;
}

static uint32_t
compile_local_variable_and_write_node(PrismBuilder *builder, const pm_local_variable_and_write_node_t *node) {
    return compile_local_variable_logical_write_node(builder, PM_NODE_UPCAST(node), node->name, node->depth, node->value);
}

static uint32_t
compile_local_variable_or_write_node(PrismBuilder *builder, const pm_local_variable_or_write_node_t *node) {
    return compile_local_variable_logical_write_node(builder, PM_NODE_UPCAST(node), node->name, node->depth, node->value);
}

static uint32_t
compile_match_predicate_node(PrismBuilder *builder, const pm_match_predicate_node_t *node) {
    uint32_t matched_block_id = make_block(builder, 0);
    uint32_t unmatched_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    uint32_t value_id = compile_node(builder, node->value);
    compile_pattern_match(builder, node->pattern, value_id, matched_block_id, unmatched_block_id);

    builder->state.block_id = matched_block_id;
    uint32_t result_id = emit_load_true(builder, node->base.node_id);
    emit_branch(builder, node->base.node_id, join_block_id, 1, &result_id);

    builder->state.block_id = unmatched_block_id;
    result_id = emit_load_false(builder, node->base.node_id);
    emit_branch(builder, node->base.node_id, join_block_id, 1, &result_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

static uint32_t
compile_nil_node(PrismBuilder *builder, const pm_nil_node_t *node) {
    uint32_t object_id = make_object(builder, kPrismObjectNil);
    return emit_load_object(builder, node->base.node_id, object_id);
}

static uint32_t
compile_numbered_reference_read_node(PrismBuilder *builder, const pm_numbered_reference_read_node_t *node) {
    uint32_t last_match_id = emit_load_last_match(builder, node->base.node_id);
    return emit_extract_last_match_group(builder, node->base.node_id, last_match_id, node->number);
}

static uint32_t
compile_or_node(PrismBuilder *builder, const pm_or_node_t *node) {
    return compile_logical_node(builder, PM_NODE_UPCAST(node), node->left, node->right);
}

static uint32_t
compile_parentheses_node(PrismBuilder *builder, const pm_parentheses_node_t *node) {
    if (node->body) {
        return compile_node(builder, node->body);
    } else {
        return emit_load_nil(builder, node->base.node_id);
    }
}

static uint32_t
compile_program_node(PrismBuilder *builder, const pm_program_node_t *node) {
    uint32_t graph_id = make_graph(builder, kPrismGraphProgram, UINT32_MAX, (uint32_t) node->locals.size);
    PrismBuilderState state = push_scope(builder, graph_id, 0, &node->locals);

    const pm_statements_node_t *statements = (const pm_statements_node_t *) node->statements;
    uint32_t value_id = UINT32_MAX;

    if (statements->body.size) {
        value_id = compile_node(builder, PM_NODE_UPCAST(statements));
    }

    if (value_id == UINT32_MAX) {
        value_id = emit_load_nil(builder, node->base.node_id);
    }

    emit_return(builder, node->base.node_id, value_id);
    pop_scope(builder, state);
    return UINT32_MAX;
}

static uint32_t
compile_range_node(PrismBuilder *builder, const pm_range_node_t *node) {
    uint32_t left_id;
    if (node->left) {
        left_id = compile_node(builder, node->left);
    } else {
        left_id = emit_load_nil(builder, node->base.node_id);
    }

    uint32_t right_id;
    if (node->right) {
        right_id = compile_node(builder, node->right);
    } else {
        right_id = emit_load_nil(builder, node->base.node_id);
    }

    return emit_new_range(builder, PM_NODE_FLAG_P(node, PM_RANGE_FLAGS_EXCLUDE_END), node->base.node_id, left_id, right_id);
}

static uint32_t
compile_rational_node(PrismBuilder *builder, const pm_rational_node_t *node) {
    uint32_t object_id = static_literal(builder, PM_NODE_UPCAST(node));
    return emit_load_object(builder, node->base.node_id, object_id);
}

static uint32_t
compile_regular_expression_node(PrismBuilder *builder, const pm_regular_expression_node_t *node) {
    uint32_t object_id = make_object(builder, kPrismObjectRegexp);
    PrismObject *object = builder->unit->objects + object_id;

    object->as.string.flags = node->base.flags;
    object->as.string.unescaped = &node->unescaped;

    return emit_load_object(builder, node->base.node_id, object_id);
}

static uint32_t
compile_return_node(PrismBuilder *builder, const pm_return_node_t *node) {
    uint32_t value_id;

    if (node->arguments) {
        uint32_t nargument_ids = (uint32_t) node->arguments->arguments.size;
        uint32_t *argument_ids = pm_arena_alloc(builder->arena, sizeof(uint32_t) * nargument_ids, PRISM_ALIGNOF(uint32_t));

        for (uint32_t idx = 0; idx < nargument_ids; ++idx) {
            argument_ids[idx] = compile_node(builder, node->arguments->arguments.nodes[idx]);
        }

        value_id = emit_new_array(builder, node->base.node_id, nargument_ids, argument_ids);
    } else {
        value_id = emit_load_nil(builder, node->base.node_id);
    }

    if (builder->unit->graphs[builder->state.graph_id].kind == kPrismGraphDef) {
        emit_trace_return(builder, node->base.node_id, value_id);
    }

    emit_return(builder, node->base.node_id, value_id);
    return UINT32_MAX;
}

static uint32_t
compile_self_node(PrismBuilder *builder, const pm_self_node_t *node) {
    return emit_load_self(builder, node->base.node_id);
}

static uint32_t
compile_singleton_class_node(PrismBuilder *builder, const pm_singleton_class_node_t *node) {
    uint32_t graph_id = make_graph(builder, kPrismGraphSingletonClass, UINT32_MAX, (uint32_t) node->locals.size);
    PrismBuilderState state = push_scope(builder, graph_id, 0, &node->locals);

    uint32_t value_id = UINT32_MAX;

    if (node->body) {
        value_id = compile_node(builder, node->body);
    }

    if (value_id == UINT32_MAX) {
        value_id = emit_load_nil(builder, node->base.node_id);
    }

    emit_return(builder, node->base.node_id, value_id);
    pop_scope(builder, state);

    return emit_define_singleton_class(builder, node->base.node_id, graph_id);
}

static uint32_t
compile_source_encoding_node(PrismBuilder *builder, const pm_source_encoding_node_t *node) {
    uint32_t object_id = make_object(builder, kPrismObjectEncoding);
    PrismObject *object = builder->unit->objects + object_id;

    object->as.encoding.name = builder->parser->encoding->name;

    return emit_load_object(builder, node->base.node_id, object_id);
}

static uint32_t
compile_source_line_node(PrismBuilder *builder, const pm_source_line_node_t *node) {
    uint32_t object_id = make_object(builder, kPrismObjectInteger);
    PrismObject *object = builder->unit->objects + object_id;

    int32_t lineno = pm_line_offset_list_line(&builder->parser->line_offsets, node->base.location.start, builder->parser->start_line);
    pm_integer_t *integer = pm_arena_alloc(builder->arena, sizeof(pm_integer_t), PRISM_ALIGNOF(pm_integer_t));
    *integer = pm_integer_int32(lineno);
    object->as.integer.value = integer;

    return emit_load_object(builder, node->base.node_id, object_id);
}

static uint32_t
compile_statements_node(PrismBuilder *builder, const pm_statements_node_t *node) {
    uint32_t value_id;
    for (size_t idx = 0; idx < node->body.size; ++idx) {
        value_id = compile_node(builder, node->body.nodes[idx]);
    }

    return value_id;
}

static uint32_t
compile_string_node(PrismBuilder *builder, const pm_string_node_t *node) {
    uint32_t object_id = make_object(builder, kPrismObjectString);
    PrismObject *object = builder->unit->objects + object_id;

    object->as.string.flags = node->base.flags;
    object->as.string.unescaped = &node->unescaped;

    return emit_load_object(builder, node->base.node_id, object_id);
}

static uint32_t
compile_symbol_node(PrismBuilder *builder, const pm_symbol_node_t *node) {
    uint32_t object_id = make_object(builder, kPrismObjectSymbol);
    PrismObject *object = builder->unit->objects + object_id;

    object->as.string.flags = node->base.flags;
    object->as.string.unescaped = &node->unescaped;

    return emit_load_object(builder, node->base.node_id, object_id);
}

static uint32_t
compile_true_node(PrismBuilder *builder, const pm_true_node_t *node) {
    return emit_load_true(builder, node->base.node_id);
}

static uint32_t
compile_undef_node(PrismBuilder *builder, const pm_undef_node_t *node) {
    for (size_t idx = 0; idx < node->names.size; ++idx) {
        uint32_t name_id = compile_node(builder, node->names.nodes[idx]);
        emit_undef_method(builder, node->base.node_id, name_id);
    }
    return emit_load_nil(builder, node->base.node_id);
}

static uint32_t
compile_until_node(PrismBuilder *builder, const pm_until_node_t *node) {
    return compile_loop_node(builder, PM_NODE_UPCAST(node), node->predicate, node->statements);
}

static uint32_t
compile_while_node(PrismBuilder *builder, const pm_while_node_t *node) {
    return compile_loop_node(builder, PM_NODE_UPCAST(node), node->predicate, node->statements);
}

static uint32_t
compile_x_string_node(PrismBuilder *builder, const pm_x_string_node_t *node) {
    uint32_t object_id = make_object(builder, kPrismObjectString);
    PrismObject *object = builder->unit->objects + object_id;

    object->as.string.flags = node->base.flags;
    object->as.string.unescaped = &node->unescaped;

    uint32_t receiver_id = emit_load_self(builder, node->base.node_id);
    uint32_t argument_id = emit_load_object(builder, node->base.node_id, object_id);
    return emit_call(builder, node->base.node_id, PM_CONSTANT_ID_BACKTICK, receiver_id, 1, &argument_id);
}

static uint32_t
compile_node(PrismBuilder *builder, const pm_node_t *node) {
    if (PM_NODE_FLAG_P(node, PM_NODE_FLAG_NEWLINE)) {
        int32_t lineno = pm_line_offset_list_line(&builder->parser->line_offsets, node->location.start, builder->parser->start_line);
        if (builder->state.lineno != lineno) {
            emit_trace_line(builder, node->node_id, lineno);
            builder->state.lineno = lineno;
        }
    }

    switch (PM_NODE_TYPE(node)) {
        case PM_ALIAS_METHOD_NODE:
            return compile_alias_method_node(builder, (const pm_alias_method_node_t *) node);
        case PM_AND_NODE:
            return compile_and_node(builder, (const pm_and_node_t *) node);
        case PM_ARRAY_NODE:
            return compile_array_node(builder, (const pm_array_node_t *) node);
        case PM_BACK_REFERENCE_READ_NODE:
            return compile_back_reference_read_node(builder, (const pm_back_reference_read_node_t *) node);
        case PM_CALL_NODE:
            return compile_call_node(builder, (const pm_call_node_t *) node);
        case PM_CLASS_NODE:
            return compile_class_node(builder, (const pm_class_node_t *) node);
        case PM_CLASS_VARIABLE_READ_NODE:
            return compile_class_variable_read_node(builder, (const pm_class_variable_read_node_t *) node);
        case PM_CLASS_VARIABLE_WRITE_NODE:
            return compile_class_variable_write_node(builder, (const pm_class_variable_write_node_t *) node);
        case PM_CLASS_VARIABLE_OPERATOR_WRITE_NODE:
            return compile_class_variable_operator_write_node(builder, (const pm_class_variable_operator_write_node_t *) node);
        case PM_CLASS_VARIABLE_AND_WRITE_NODE:
            return compile_class_variable_and_write_node(builder, (const pm_class_variable_and_write_node_t *) node);
        case PM_CLASS_VARIABLE_OR_WRITE_NODE:
            return compile_class_variable_or_write_node(builder, (const pm_class_variable_or_write_node_t *) node);
        case PM_CONSTANT_READ_NODE:
            return compile_constant_read_node(builder, (const pm_constant_read_node_t *) node);
        case PM_CONSTANT_WRITE_NODE:
            return compile_constant_write_node(builder, (const pm_constant_write_node_t *) node);
        case PM_CONSTANT_OPERATOR_WRITE_NODE:
            return compile_constant_operator_write_node(builder, (const pm_constant_operator_write_node_t *) node);
        case PM_CONSTANT_PATH_NODE:
            return compile_constant_path_node(builder, (const pm_constant_path_node_t *) node);
        case PM_CONSTANT_PATH_WRITE_NODE:
            return compile_constant_path_write_node(builder, (const pm_constant_path_write_node_t *) node);
        case PM_CONSTANT_PATH_OPERATOR_WRITE_NODE:
            return compile_constant_path_operator_write_node(builder, (const pm_constant_path_operator_write_node_t *) node);
        case PM_DEF_NODE:
            return compile_def_node(builder, (const pm_def_node_t *) node);
        case PM_EMBEDDED_STATEMENTS_NODE:
            return compile_embedded_statements_node(builder, (const pm_embedded_statements_node_t *) node);
        case PM_EMBEDDED_VARIABLE_NODE:
            return compile_embedded_variable_node(builder, (const pm_embedded_variable_node_t *) node);
        case PM_FALSE_NODE:
            return compile_false_node(builder, (const pm_false_node_t *) node);
        case PM_FLOAT_NODE:
            return compile_float_node(builder, (const pm_float_node_t *) node);
        case PM_GLOBAL_VARIABLE_READ_NODE:
            return compile_global_variable_read_node(builder, (const pm_global_variable_read_node_t *) node);
        case PM_GLOBAL_VARIABLE_WRITE_NODE:
            return compile_global_variable_write_node(builder, (const pm_global_variable_write_node_t *) node);
        case PM_GLOBAL_VARIABLE_OPERATOR_WRITE_NODE:
            return compile_global_variable_operator_write_node(builder, (const pm_global_variable_operator_write_node_t *) node);
        case PM_GLOBAL_VARIABLE_AND_WRITE_NODE:
            return compile_global_variable_and_write_node(builder, (const pm_global_variable_and_write_node_t *) node);
        case PM_GLOBAL_VARIABLE_OR_WRITE_NODE:
            return compile_global_variable_or_write_node(builder, (const pm_global_variable_or_write_node_t *) node);
        case PM_HASH_NODE:
            return compile_hash_node(builder, (const pm_hash_node_t *) node);
        case PM_IMAGINARY_NODE:
            return compile_imaginary_node(builder, (const pm_imaginary_node_t *) node);
        case PM_IMPLICIT_NODE:
            return compile_implicit_node(builder, (const pm_implicit_node_t *) node);
        case PM_INSTANCE_VARIABLE_READ_NODE:
            return compile_instance_variable_read_node(builder, (const pm_instance_variable_read_node_t *) node);
        case PM_INSTANCE_VARIABLE_WRITE_NODE:
            return compile_instance_variable_write_node(builder, (const pm_instance_variable_write_node_t *) node);
        case PM_INSTANCE_VARIABLE_OPERATOR_WRITE_NODE:
            return compile_instance_variable_operator_write_node(builder, (const pm_instance_variable_operator_write_node_t *) node);
        case PM_INSTANCE_VARIABLE_AND_WRITE_NODE:
            return compile_instance_variable_and_write_node(builder, (const pm_instance_variable_and_write_node_t *) node);
        case PM_INSTANCE_VARIABLE_OR_WRITE_NODE:
            return compile_instance_variable_or_write_node(builder, (const pm_instance_variable_or_write_node_t *) node);
        case PM_INTEGER_NODE:
            return compile_integer_node(builder, (const pm_integer_node_t *) node);
        case PM_INTERPOLATED_REGULAR_EXPRESSION_NODE:
            return compile_interpolated_regular_expression_node(builder, (const pm_interpolated_regular_expression_node_t *) node);
        case PM_INTERPOLATED_STRING_NODE:
            return compile_interpolated_string_node(builder, (const pm_interpolated_string_node_t *) node);
        case PM_INTERPOLATED_SYMBOL_NODE:
            return compile_interpolated_symbol_node(builder, (const pm_interpolated_symbol_node_t *) node);
        case PM_INTERPOLATED_X_STRING_NODE:
            return compile_interpolated_x_string_node(builder, (const pm_interpolated_x_string_node_t *) node);
        case PM_LOCAL_VARIABLE_READ_NODE:
            return compile_local_variable_read_node(builder, (const pm_local_variable_read_node_t *) node);
        case PM_LOCAL_VARIABLE_WRITE_NODE:
            return compile_local_variable_write_node(builder, (const pm_local_variable_write_node_t *) node);
        case PM_LOCAL_VARIABLE_OPERATOR_WRITE_NODE:
            return compile_local_variable_operator_write_node(builder, (const pm_local_variable_operator_write_node_t *) node);
        case PM_LOCAL_VARIABLE_AND_WRITE_NODE:
            return compile_local_variable_and_write_node(builder, (const pm_local_variable_and_write_node_t *) node);
        case PM_LOCAL_VARIABLE_OR_WRITE_NODE:
            return compile_local_variable_or_write_node(builder, (const pm_local_variable_or_write_node_t *) node);
        case PM_MATCH_PREDICATE_NODE:
            return compile_match_predicate_node(builder, (const pm_match_predicate_node_t *) node);
        case PM_NIL_NODE:
            return compile_nil_node(builder, (const pm_nil_node_t *) node);
        case PM_NUMBERED_REFERENCE_READ_NODE:
            return compile_numbered_reference_read_node(builder, (const pm_numbered_reference_read_node_t *) node);
        case PM_OR_NODE:
            return compile_or_node(builder, (const pm_or_node_t *) node);
        case PM_PARENTHESES_NODE:
            return compile_parentheses_node(builder, (const pm_parentheses_node_t *) node);
        case PM_PROGRAM_NODE:
            return compile_program_node(builder, (const pm_program_node_t *) node);
        case PM_RANGE_NODE:
            return compile_range_node(builder, (const pm_range_node_t *) node);
        case PM_RATIONAL_NODE:
            return compile_rational_node(builder, (const pm_rational_node_t *) node);
        case PM_REGULAR_EXPRESSION_NODE:
            return compile_regular_expression_node(builder, (const pm_regular_expression_node_t *) node);
        case PM_RETURN_NODE:
            return compile_return_node(builder, (const pm_return_node_t *) node);
        case PM_SELF_NODE:
            return compile_self_node(builder, (const pm_self_node_t *) node);
        case PM_SINGLETON_CLASS_NODE:
            return compile_singleton_class_node(builder, (const pm_singleton_class_node_t *) node);
        case PM_SOURCE_ENCODING_NODE:
            return compile_source_encoding_node(builder, (const pm_source_encoding_node_t *) node);
        case PM_SOURCE_LINE_NODE:
            return compile_source_line_node(builder, (const pm_source_line_node_t *) node);
        case PM_STATEMENTS_NODE:
            return compile_statements_node(builder, (const pm_statements_node_t *) node);
        case PM_STRING_NODE:
            return compile_string_node(builder, (const pm_string_node_t *) node);
        case PM_SYMBOL_NODE:
            return compile_symbol_node(builder, (const pm_symbol_node_t *) node);
        case PM_TRUE_NODE:
            return compile_true_node(builder, (const pm_true_node_t *) node);
        case PM_UNDEF_NODE:
            return compile_undef_node(builder, (const pm_undef_node_t *) node);
        case PM_UNTIL_NODE:
            return compile_until_node(builder, (const pm_until_node_t *) node);
        case PM_WHILE_NODE:
            return compile_while_node(builder, (const pm_while_node_t *) node);
        case PM_X_STRING_NODE:
            return compile_x_string_node(builder, (const pm_x_string_node_t *) node);
        case PM_ERROR_RECOVERY_NODE:
            fprintf(stderr, "Cannot compile syntax errors\n");
            abort();
        case PM_ALTERNATION_PATTERN_NODE:
        case PM_ASSOC_NODE:
        case PM_ASSOC_SPLAT_NODE:
        case PM_REQUIRED_PARAMETER_NODE:
            fprintf(stderr, "Handled elsewhere: %s\n", pm_node_type(node->type));
            abort();
        default:
            fprintf(stderr, "Unhandled node type: %s\n", pm_node_type(node->type));
            abort();
    }
}

/******************************************************************************/

/*
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
dump_object(PrismBuilder *builder, uint32_t object_id) {
    PrismObject *object = builder->unit->objects + object_id;

    switch (object->kind) {
        case kPrismObjectArray: {
            printf("[");
            for (uint32_t idx = 0; idx < object->as.array.nobject_ids; ++idx) {
                if (idx > 0) printf(", ");
                dump_object(builder, object->as.array.object_ids[idx]);
            }
            printf("]");
            break;
        }
        case kPrismObjectEncoding:
            printf("encoding(%s)", object->as.encoding.name);
            break;
        case kPrismObjectFalse:
            printf("false");
            break;
        case kPrismObjectFloat:
            printf("%f", object->as.floating.value);
            break;
        case kPrismObjectHash: {
            printf("{ ");
            for (uint32_t idx = 0; idx < object->as.hash.nobject_ids; ++idx) {
                if (idx > 0) printf(", ");
                dump_object(builder, object->as.hash.object_ids[idx]);
                printf(" => ");
                dump_object(builder, object->as.hash.object_ids[++idx]);
            }
            printf(" }");
            break;
        }
        case kPrismObjectImaginary:
            dump_object(builder, object->as.imaginary.numeric_id);
            printf("i");
            break;
        case kPrismObjectInteger: {
            pm_buffer_t buffer = { 0 };
            pm_integer_string(&buffer, object->as.integer.value);
            printf("%.*s", (int) pm_buffer_length(&buffer), (const char *) pm_buffer_value(&buffer));
            pm_buffer_cleanup(&buffer);
            break;
        }
        case kPrismObjectNil:
            printf("nil");
            break;
        case kPrismObjectRational: {
            pm_buffer_t buffer = { 0 };
            PM_BUFFER_APPEND_LITERAL(&buffer, "(");
            pm_integer_string(&buffer, object->as.rational.numerator);
            PM_BUFFER_APPEND_LITERAL(&buffer, "/");
            pm_integer_string(&buffer, object->as.rational.denominator);
            PM_BUFFER_APPEND_LITERAL(&buffer, ")");
            printf("%.*s", (int) pm_buffer_length(&buffer), (const char *) pm_buffer_value(&buffer));
            pm_buffer_cleanup(&buffer);
            break;
        }
        case kPrismObjectRegexp: {
            const pm_string_t *unescaped = object->as.string.unescaped;
            printf("/%.*s/", (int) pm_string_length(unescaped), (const char *) pm_string_source(unescaped));
            break;
        }
        case kPrismObjectString: {
            const pm_string_t *unescaped = object->as.string.unescaped;
            printf("\"%.*s\"", (int) pm_string_length(unescaped), (const char *) pm_string_source(unescaped));
            break;
        }
        case kPrismObjectSymbol: {
            const pm_string_t *unescaped = object->as.string.unescaped;
            printf(":%.*s", (int) pm_string_length(unescaped), (const char *) pm_string_source(unescaped));
            break;
        }
        case kPrismObjectTrue:
            printf("true");
            break;
    }
}

static void
dump_constant_path(PrismBuilder *builder, PrismConstantPath *path) {
    for (uint32_t idx = 0; idx < path->size; idx++) {
        const pm_constant_t *constant = compile_constant(builder->parser, PrismConstantPath_get(path, idx));
        if (idx > 0) printf("::");
        printf("%.*s", (int) pm_constant_length(constant), (const char *) pm_constant_start(constant));
    }
}

static void
dump_graph(PrismBuilder *builder, PrismGraph *graph) {
    for (uint32_t block_id = 0; block_id < graph->nblocks; ++block_id) {
        PrismBlock *block = &graph->blocks[block_id];

        printf("  ");
        printf("bb%" PRIu32, block_id);
        dump_values(block->nparams, block->params);
        printf(":\n");

        for (uint32_t insn_id = 0; insn_id < block->ninsns; ++insn_id) {
            PrismInsn *insn = &block->insns[insn_id];
            uint32_t *opnds = &graph->opnds[insn->opnds_off];
            printf("    ");

            switch (insn->kind) {
                case kPrismInsnAliasMethod:
                    printf("alias_method %%%" PRIu32 ", %%%" PRIu32 "\n", opnds[0], opnds[1]);
                    break;
                case kPrismInsnBranch: {
                    printf("branch bb%" PRIu32, insn->as.branchif.then_block_id);
                    dump_values(insn->opnds_len, opnds);
                    printf("\n");
                    break;
                }
                case kPrismInsnBranchIf: {
                    printf("branchif %%%" PRIu32 " bb%" PRIu32, opnds[0], insn->as.branchif.then_block_id);
                    dump_values(insn->as.branchif.then_opnds_len, opnds + 1);
                    printf(" bb%" PRIu32, insn->as.branchif.else_block_id);
                    dump_values(insn->opnds_len - insn->as.branchif.then_opnds_len - 1, opnds + 1 + insn->as.branchif.then_opnds_len);
                    printf("\n");
                    break;
                }
                case kPrismInsnCall: {
                    const pm_constant_t *constant = compile_constant(builder->parser, insn->as.name.name_id);
                    printf("%%%" PRIu32 " = call %%%" PRIu32 ".%.*s", opnds[0], opnds[1], (int) pm_constant_length(constant), (const char *) pm_constant_start(constant));
                    dump_values(insn->opnds_len - 2, opnds + 2);
                    printf("\n");
                    break;
                }
                case kPrismInsnCoerceHash:
                    printf("%%%" PRIu32 " = coerce_hash %%%" PRIu32 "\n", opnds[0], opnds[1]);
                    break;
                case kPrismInsnCoerceString:
                    printf("%%%" PRIu32 " = coerce_string %%%" PRIu32 "\n", opnds[0], opnds[1]);
                    break;
                case kPrismInsnDefineClassAbs: {
                    const pm_constant_t *name = compile_constant(builder->parser, insn->as.define.name_id);
                    printf("%%%" PRIu32 " = define_class_abs(::%.*s, g%" PRIu32 ")\n", opnds[0], (int) pm_constant_length(name), (const char *) pm_constant_start(name), insn->as.define.graph_id);
                    break;
                }
                case kPrismInsnDefineClassAbsSuper: {
                    const pm_constant_t *name = compile_constant(builder->parser, insn->as.define.name_id);
                    printf("%%%" PRIu32 " = define_class_abs_super(::%.*s, %%%" PRIu32 ", g%" PRIu32 ")\n", opnds[0], (int) pm_constant_length(name), (const char *) pm_constant_start(name), opnds[1], insn->as.define.graph_id);
                    break;
                }
                case kPrismInsnDefineClassNestRel: {
                    const pm_constant_t *name = compile_constant(builder->parser, insn->as.define.name_id);
                    printf("%%%" PRIu32 " = define_class_nest_rel(%.*s, g%" PRIu32 ")\n", opnds[0], (int) pm_constant_length(name), (const char *) pm_constant_start(name), insn->as.define.graph_id);
                    break;
                }
                case kPrismInsnDefineClassNestRelSuper: {
                    const pm_constant_t *name = compile_constant(builder->parser, insn->as.define.name_id);
                    printf("%%%" PRIu32 " = define_class_nest_rel_super(%.*s, %%%" PRIu32 ", g%" PRIu32 ")\n", opnds[0], (int) pm_constant_length(name), (const char *) pm_constant_start(name), opnds[1], insn->as.define.graph_id);
                    break;
                }
                case kPrismInsnDefineClassRecvRel: {
                    const pm_constant_t *name = compile_constant(builder->parser, insn->as.define.name_id);
                    printf("%%%" PRIu32 " = define_class_recv_rel(%.*s, %%%" PRIu32 ", g%" PRIu32 ")\n", opnds[0], (int) pm_constant_length(name), (const char *) pm_constant_start(name), opnds[1], insn->as.define.graph_id);
                    break;
                }
                case kPrismInsnDefineClassRecvRelSuper: {
                    const pm_constant_t *name = compile_constant(builder->parser, insn->as.define.name_id);
                    printf("%%%" PRIu32 " = define_class_recv_rel_super(%.*s, %%%" PRIu32 ", %%%" PRIu32 ", g%" PRIu32 ")\n", opnds[0], (int) pm_constant_length(name), (const char *) pm_constant_start(name), opnds[1], opnds[2], insn->as.define.graph_id);
                    break;
                }
                case kPrismInsnDefineMethod: {
                    const pm_constant_t *constant = compile_constant(builder->parser, insn->as.define.name_id);
                    printf("define_method :%.*s, g%" PRIu32 "\n", (int) pm_constant_length(constant), (const char *) pm_constant_start(constant), insn->as.define.graph_id);
                    break;
                }
                case kPrismInsnDefineSingletonClass: {
                    printf("%%%" PRIu32 " = define_singleton_class g%" PRIu32 "\n", opnds[0], insn->as.define_singleton_class.graph_id);
                    break;
                }
                case kPrismInsnDefinedCVar: {
                    const pm_constant_t *constant = compile_constant(builder->parser, insn->as.name.name_id);
                    printf("%%%" PRIu32 " = defined_cvar %.*s\n", opnds[0], (int) pm_constant_length(constant), (const char *) pm_constant_start(constant));
                    break;
                }
                case kPrismInsnDefinedGVar: {
                    const pm_constant_t *constant = compile_constant(builder->parser, insn->as.name.name_id);
                    printf("%%%" PRIu32 " = defined_gvar %.*s\n", opnds[0], (int) pm_constant_length(constant), (const char *) pm_constant_start(constant));
                    break;
                }
                case kPrismInsnExtractLastMatchGroup:
                    printf("%%%" PRIu32 " = extract_last_match_group %%%" PRIu32 ", group=%" PRIu32 "\n", opnds[0], opnds[1], insn->as.extract_group.number);
                    break;
                case kPrismInsnExtractLastMatchMatch:
                    printf("%%%" PRIu32 " = extract_last_match_match %%%" PRIu32 "\n", opnds[0], opnds[1]);
                    break;
                case kPrismInsnExtractLastMatchParen:
                    printf("%%%" PRIu32 " = extract_last_match_paren %%%" PRIu32 "\n", opnds[0], opnds[1]);
                    break;
                case kPrismInsnExtractLastMatchPost:
                    printf("%%%" PRIu32 " = extract_last_match_post %%%" PRIu32 "\n", opnds[0], opnds[1]);
                    break;
                case kPrismInsnExtractLastMatchPre:
                    printf("%%%" PRIu32 " = extract_last_match_pre %%%" PRIu32 "\n", opnds[0], opnds[1]);
                    break;
                case kPrismInsnLoadConstAbs:
                    printf("%%%" PRIu32 " = load_const_abs(::", opnds[0]);
                    dump_constant_path(builder, &insn->as.constant_path);
                    printf(")\n");
                    break;
                case kPrismInsnLoadConstNestRel:
                    printf("%%%" PRIu32 " = load_const_nest_rel(", opnds[0]);
                    dump_constant_path(builder, &insn->as.constant_path);
                    printf(")\n");
                    break;
                case kPrismInsnLoadConstRecvRel:
                    printf("%%%" PRIu32 " = load_const_recv_rel(%%%" PRIu32 ", ", opnds[0], opnds[1]);
                    dump_constant_path(builder, &insn->as.constant_path);
                    printf(")\n");
                    break;
                case kPrismInsnLoadCVar: {
                    const pm_constant_t *constant = compile_constant(builder->parser, insn->as.name.name_id);
                    printf("%%%" PRIu32 " = load_cvar %.*s\n", opnds[0], (int) pm_constant_length(constant), (const char *) pm_constant_start(constant));
                    break;
                }
                case kPrismInsnLoadGVar: {
                    const pm_constant_t *constant = compile_constant(builder->parser, insn->as.name.name_id);
                    printf("%%%" PRIu32 " = load_gvar %.*s\n", opnds[0], (int) pm_constant_length(constant), (const char *) pm_constant_start(constant));
                    break;
                }
                case kPrismInsnLoadIVar: {
                    const pm_constant_t *constant = compile_constant(builder->parser, insn->as.name.name_id);
                    printf("%%%" PRIu32 " = load_ivar %.*s\n", opnds[0], (int) pm_constant_length(constant), (const char *) pm_constant_start(constant));
                    break;
                }
                case kPrismInsnLoadLastMatch: {
                    printf("%%%" PRIu32 " = load_last_match\n", opnds[0]);
                    break;
                }
                case kPrismInsnLoadLVar: {
                    printf("%%%" PRIu32 " = load_lvar v%" PRIu32 "\n", opnds[0], insn->as.lvar.local_id);
                    break;
                }
                case kPrismInsnLoadObject: {
                    printf("%%%" PRIu32 " = load_object(", opnds[0]);
                    dump_object(builder, insn->as.object.object_id);
                    printf(")\n");
                    break;
                }
                case kPrismInsnLoadSelf:
                    printf("%%%" PRIu32 " = load_self\n", opnds[0]);
                    break;
                case kPrismInsnMatch:
                    printf("%%%" PRIu32 " = match %%%" PRIu32 ", %%%" PRIu32 "\n", opnds[0], opnds[1], opnds[2]);
                    break;
                case kPrismInsnMergeHash:
                    printf("%%%" PRIu32 " = merge_hash %%%" PRIu32 ", %%%" PRIu32 "\n", opnds[0], opnds[1], opnds[2]);
                    break;
                case kPrismInsnNewArray:
                    printf("%%%" PRIu32 " = new_array", opnds[0]);
                    dump_values(insn->opnds_len - 1, opnds + 1);
                    printf("\n");
                    break;
                case kPrismInsnNewArrayStatic:
                    printf("%%%" PRIu32 " = new_array_static ", opnds[0]);
                    dump_object(builder, insn->as.object.object_id);
                    printf("\n");
                    break;
                case kPrismInsnNewHash:
                    printf("%%%" PRIu32 " = new_hash", opnds[0]);
                    dump_values(insn->opnds_len - 1, opnds + 1);
                    printf("\n");
                    break;
                case kPrismInsnNewHashStatic:
                    printf("%%%" PRIu32 " = new_hash_static ", opnds[0]);
                    dump_object(builder, insn->as.object.object_id);
                    printf("\n");
                    break;
                case kPrismInsnNewRange:
                    printf("%%%" PRIu32 " = new_range %%%" PRIu32 ", %%%" PRIu32 ", exclude_end=%d\n", opnds[0], opnds[1], opnds[2], insn->as.range.exclude_end);
                    break;
                case kPrismInsnNewRegexp:
                    printf("%%%" PRIu32 " = new_regexp", opnds[0]);
                    dump_values(insn->opnds_len - 1, opnds + 1);
                    printf(" flags=%" PRIu16 "\n", insn->as.regexp.flags);
                    break;
                case kPrismInsnNewString:
                    printf("%%%" PRIu32 " = new_string", opnds[0]);
                    dump_values(insn->opnds_len - 1, opnds + 1);
                    printf("\n");
                    break;
                case kPrismInsnNewSymbol:
                    printf("%%%" PRIu32 " = new_symbol", opnds[0]);
                    dump_values(insn->opnds_len - 1, opnds + 1);
                    printf("\n");
                    break;
                case kPrismInsnReturn:
                    printf("return %%%" PRIu32 "\n", opnds[0]);
                    break;
                case kPrismInsnStoreConstAbs: {
                    const pm_constant_t *constant = compile_constant(builder->parser, insn->as.name.name_id);
                    printf("store_const_abs(::%.*s, %%%" PRIu32 ")\n", (int) pm_constant_length(constant), (const char *) pm_constant_start(constant), opnds[0]);
                    break;
                }
                case kPrismInsnStoreConstNestRel: {
                    const pm_constant_t *constant = compile_constant(builder->parser, insn->as.name.name_id);
                    printf("store_const_nest_rel(%.*s, %%%" PRIu32 ")\n", (int) pm_constant_length(constant), (const char *) pm_constant_start(constant), opnds[0]);
                    break;
                }
                case kPrismInsnStoreConstRecvRel: {
                    const pm_constant_t *constant = compile_constant(builder->parser, insn->as.name.name_id);
                    printf("store_const_recv_rel(%%%" PRIu32 ", %.*s, %%%" PRIu32 ")\n", opnds[0], (int) pm_constant_length(constant), (const char *) pm_constant_start(constant), opnds[1]);
                    break;
                }
                case kPrismInsnStoreCVar: {
                    const pm_constant_t *constant = compile_constant(builder->parser, insn->as.name.name_id);
                    printf("store_cvar %.*s, %%%" PRIu32 "\n", (int) pm_constant_length(constant), (const char *) pm_constant_start(constant), opnds[0]);
                    break;
                }
                case kPrismInsnStoreGVar: {
                    const pm_constant_t *constant = compile_constant(builder->parser, insn->as.name.name_id);
                    printf("store_gvar %.*s, %%%" PRIu32 "\n", (int) pm_constant_length(constant), (const char *) pm_constant_start(constant), opnds[0]);
                    break;
                }
                case kPrismInsnStoreIVar: {
                    const pm_constant_t *constant = compile_constant(builder->parser, insn->as.name.name_id);
                    printf("store_ivar %.*s, %%%" PRIu32 "\n", (int) pm_constant_length(constant), (const char *) pm_constant_start(constant), opnds[0]);
                    break;
                }
                case kPrismInsnStoreLVar:
                    printf("store_lvar v%" PRIu32 ", %%%" PRIu32 "\n", insn->as.lvar.local_id, opnds[0]);
                    break;
                case kPrismInsnTraceCall:
                    printf("trace_call\n");
                    break;
                case kPrismInsnTraceClass:
                    printf("trace_class\n");
                    break;
                case kPrismInsnTraceEnd:
                    printf("trace_end\n");
                    break;
                case kPrismInsnTraceLine:
                    printf("trace_line %" PRId32 "\n", insn->as.trace_line.lineno);
                    break;
                case kPrismInsnTraceReturn:
                    printf("trace_return %%%" PRIu32 "\n", opnds[0]);
                    break;
                case kPrismInsnUndefMethod:
                    printf("undef_method %%%" PRIu32 "\n", opnds[0]);
                    break;
            }
        }
    }
}

static void
dump_unit(PrismBuilder *builder) {
    for (uint32_t local_id = 0; local_id < builder->unit->nlocals; ++local_id) {
        PrismLocal *local = builder->unit->locals + local_id;
        const pm_constant_t *constant = compile_constant(builder->parser, local->name_id);
        printf("v%" PRIu32 ": %.*s @ g%" PRIu32 "\n", local_id, (int) pm_constant_length(constant), (const char *) pm_constant_start(constant), local->graph_id);
    }

    for (uint32_t graph_id = 0; graph_id < builder->unit->ngraphs; ++graph_id) {
        printf("g%" PRIu32 ":\n", graph_id);
        dump_graph(builder, builder->unit->graphs + graph_id);
    }
}
*/

void
pm_compile(const pm_parser_t *parser, const pm_node_t *node, pm_arena_t *arena, PrismUnit *unit) {
    PrismBuilder builder = {
        .parser = parser,
        .arena = arena,
        .unit = unit,
        .state = {
            .graph_id = 0,
            .block_id = 0,
            .lineno = parser->start_line - 1
        },
        .bindings = pm_arena_zalloc(arena, sizeof(uint32_t) * ((size_t) parser->constant_pool.size + 1), PRISM_ALIGNOF(uint32_t))
    };

    compile_node(&builder, node);
    /* dump_unit(&builder); */
}
