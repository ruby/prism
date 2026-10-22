#include "prism/compile.h"

#include "prism/compiler/align.h"
#include "prism/internal/allocator.h"
#include "prism/internal/arena.h"
#include "prism/internal/constant_pool.h"
#include "prism/internal/line_offset_list.h"
#include "prism/internal/parser.h"
#include "prism/node.h"

#include <assert.h>
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#define PM_CONSTANT_BACKTICK (pm_constant_id_t) -1
static const pm_constant_t backtick_constant = { .start = (const uint8_t *) "`", .length = 1 };

static const pm_constant_t *
compile_constant(const pm_parser_t *parser, pm_constant_id_t constant_id) {
    if (constant_id == PM_CONSTANT_BACKTICK) {
        return &backtick_constant;
    } else {
        return pm_parser_constant(parser, constant_id);
    }
}

typedef enum {
    kPrismInsnAliasMethod,
    kPrismInsnBranch,
    kPrismInsnBranchIf,
    kPrismInsnCall,
    kPrismInsnDefineMethod,
    kPrismInsnDefinedCVar,
    kPrismInsnDefinedGVar,
    kPrismInsnLoadCVar,
    kPrismInsnLoadGVar,
    kPrismInsnLoadIVar,
    kPrismInsnLoadLVar,
    kPrismInsnLoadObject,
    kPrismInsnLoadSelf,
    kPrismInsnNewArray,
    kPrismInsnNewArrayStatic,
    kPrismInsnNewRange,
    kPrismInsnReturn,
    kPrismInsnStoreCVar,
    kPrismInsnStoreGVar,
    kPrismInsnStoreIVar,
    kPrismInsnStoreLVar,
    kPrismInsnTraceLine
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
        struct { uint32_t local_id; } lvar;
        struct { pm_constant_id_t name_id; uint32_t graph_id; } method;
        struct { pm_constant_id_t name_id; } name;
        struct { uint32_t object_id; } object;
        struct { bool exclude_end; } range;
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
    kPrismObjectArray,
    kPrismObjectFalse,
    kPrismObjectFloat,
    kPrismObjectInteger,
    kPrismObjectNil,
    kPrismObjectString,
    kPrismObjectSymbol,
    kPrismObjectTrue
} PrismObjectKind;

typedef struct {
    PrismObjectKind kind;
    union {
        struct { uint32_t nobject_ids; uint32_t *object_ids; } array;
        struct { double value; } floating;
        struct { const pm_integer_t *value; } integer;
        struct { pm_node_flags_t flags; const pm_string_t *unescaped; } string;
    } as;
} PrismObject;

typedef struct {
    PrismBlock *blocks;
    uint32_t *opnds;
    uint32_t *local_ids;
    uint32_t nblocks;
    uint32_t nopnds;
    uint32_t nlocal_ids;
    uint32_t blocks_capa;
    uint32_t opnds_capa;
    uint32_t value_id;
    uint32_t parent_id;
} PrismGraph;

typedef struct {
    pm_constant_id_t name_id;
    uint32_t graph_id;
} PrismLocal;

typedef struct {
    PrismGraph *graphs;
    PrismObject *objects;
    PrismLocal *locals;
    uint32_t ngraphs;
    uint32_t nobjects;
    uint32_t nlocals;
    uint32_t graphs_capa;
    uint32_t objects_capa;
    uint32_t locals_capa;
} PrismUnit;

typedef struct {
    uint32_t graph_id;
    uint32_t block_id;
    int32_t lineno;
} PrismBuilderState;

typedef struct {
    const pm_parser_t *parser;
    pm_arena_t *arena;
    PrismUnit *unit;
    PrismBuilderState state;
} PrismBuilder;

/******************************************************************************/

#define PrismBuilder_graph(builder_) ((builder_)->unit->graphs + (builder_)->state.graph_id)

static uint32_t
make_local(PrismBuilder *builder, pm_constant_id_t name_id) {
    PrismUnit *unit = builder->unit;

    if (unit->nlocals == unit->locals_capa) {
        uint32_t next_capa = unit->locals_capa ? unit->locals_capa * 2 : 8;
        PrismLocal *next_mem = pm_arena_realloc(builder->arena, unit->locals, sizeof(PrismLocal) * unit->locals_capa, sizeof(PrismLocal) * next_capa, PRISM_ALIGNOF(PrismLocal));

        unit->locals_capa = next_capa;
        unit->locals = next_mem;
    }

    uint32_t local_id = unit->nlocals++;
    unit->locals[local_id] = (PrismLocal) { .name_id = name_id, .graph_id = builder->state.graph_id };
    return local_id;
}

static uint32_t
make_graph(PrismBuilder *builder, uint32_t parent_id, uint32_t nlocal_ids) {
    PrismUnit *unit = builder->unit;

    if (unit->ngraphs == unit->graphs_capa) {
        uint32_t next_capa = unit->graphs_capa ? unit->graphs_capa * 2 : 8;
        PrismGraph *next_mem = pm_arena_realloc(builder->arena, unit->graphs, sizeof(PrismGraph) * unit->graphs_capa, sizeof(PrismGraph) * next_capa, PRISM_ALIGNOF(PrismGraph));

        unit->graphs_capa = next_capa;
        unit->graphs = next_mem;
    }

    uint32_t *local_ids = NULL;
    if (nlocal_ids) {
        local_ids = pm_arena_alloc(builder->arena, sizeof(uint32_t) * nlocal_ids, PRISM_ALIGNOF(uint32_t));
    }

    uint32_t graph_id = unit->ngraphs++;
    unit->graphs[graph_id] = (PrismGraph) { .parent_id = parent_id, .local_ids = local_ids, .nlocal_ids = nlocal_ids };
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
        PrismBlock *next_blocks = pm_arena_realloc(builder->arena, graph->blocks, sizeof(PrismBlock) * graph->blocks_capa, sizeof(PrismBlock) * next_capa, PRISM_ALIGNOF(PrismBlock));

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

static uint32_t
make_object(PrismBuilder *builder, PrismObjectKind kind) {
    PrismUnit *unit = builder->unit;

    if (unit->nobjects == unit->objects_capa) {
        uint32_t next_capa = unit->objects_capa ? unit->objects_capa * 2 : 8;
        PrismObject *next_mem = pm_arena_realloc(builder->arena, unit->objects, sizeof(PrismObject) * unit->objects_capa, sizeof(PrismObject) * next_capa, PRISM_ALIGNOF(PrismObject));

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
make_insn(PrismBuilder *builder, PrismInsnKind kind, uint32_t node_id, pm_location_t location, uint32_t opnds_len) {
    PrismGraph *graph = PrismBuilder_graph(builder);
    PrismBlock *block = graph->blocks + builder->state.block_id;

    if (block->ninsns == block->insns_capa) {
        uint32_t next_capa = block->insns_capa ? block->insns_capa * 2 : 8;
        PrismInsn *next_insns = pm_arena_realloc(builder->arena, block->insns, sizeof(PrismInsn) * block->insns_capa, sizeof(PrismInsn) * next_capa, PRISM_ALIGNOF(PrismInsn));

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

            uint32_t *next_opnds = pm_arena_realloc(builder->arena, graph->opnds, sizeof(uint32_t) * graph->opnds_capa, sizeof(uint32_t) * next_capa, PRISM_ALIGNOF(uint32_t));

            graph->opnds_capa = next_capa;
            graph->opnds = next_opnds;
        }

        graph->nopnds += opnds_len;
    }

    return insn;
}

/******************************************************************************/

static void
emit_alias_method(PrismBuilder *builder, uint32_t node_id, pm_location_t location, uint32_t new_name_id, uint32_t old_name_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnAliasMethod, node_id, location, 2);

    PrismGraph *graph = PrismBuilder_graph(builder);
    graph->opnds[insn->opnds_off] = new_name_id;
    graph->opnds[insn->opnds_off + 1] = old_name_id;
}

static void
emit_branch(PrismBuilder *builder, uint32_t node_id, pm_location_t location, uint32_t block_id, uint32_t opnds_len, uint32_t *opnd_ids) {
    PrismInsn *insn = make_insn(builder, kPrismInsnBranch, node_id, location, opnds_len);
    insn->as.branch.block_id = block_id;

    if (opnds_len) {
        memcpy(PrismBuilder_graph(builder)->opnds + insn->opnds_off, opnd_ids, sizeof(uint32_t) * opnds_len);
    }
}

static void
emit_branchif(PrismBuilder *builder, uint32_t node_id, pm_location_t location, uint32_t predicate_id, uint32_t then_block_id, uint32_t then_opnds_len, uint32_t *then_opnd_ids, uint32_t else_block_id, uint32_t else_opnds_len, uint32_t *else_opnd_ids) {
    PrismInsn *insn = make_insn(builder, kPrismInsnBranchIf, node_id, location, 1 + then_opnds_len + else_opnds_len);
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
emit_call(PrismBuilder *builder, uint32_t node_id, pm_location_t location, pm_constant_id_t name_id, uint32_t receiver_id, size_t nargument_ids, uint32_t *argument_ids) {
    PrismInsn *insn = make_insn(builder, kPrismInsnCall, node_id, location, 2 + (uint32_t) nargument_ids);
    insn->as.name.name_id = name_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;
    graph->opnds[insn->opnds_off + 1] = receiver_id;
    memcpy(graph->opnds + insn->opnds_off + 2, argument_ids, sizeof(uint32_t) * nargument_ids);

    return value_id;
}

static void
emit_define_method(PrismBuilder *builder, uint32_t node_id, pm_location_t location, pm_constant_id_t name_id, uint32_t graph_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnDefineMethod, node_id, location, 0);
    insn->as.method.name_id = name_id;
    insn->as.method.graph_id = graph_id;
}

static uint32_t
emit_defined_cvar(PrismBuilder *builder, uint32_t node_id, pm_location_t location, pm_constant_id_t name_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnDefinedCVar, node_id, location, 1);
    insn->as.name.name_id = name_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_defined_gvar(PrismBuilder *builder, uint32_t node_id, pm_location_t location, pm_constant_id_t name_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnDefinedGVar, node_id, location, 1);
    insn->as.name.name_id = name_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_load_name(PrismBuilder *builder, uint32_t node_id, pm_location_t location, PrismInsnKind kind, pm_constant_id_t name_id) {
    PrismInsn *insn = make_insn(builder, kind, node_id, location, 1);
    insn->as.name.name_id = name_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_load_cvar(PrismBuilder *builder, uint32_t node_id, pm_location_t location, pm_constant_id_t name_id) {
    return emit_load_name(builder, node_id, location, kPrismInsnLoadCVar, name_id);
}

static uint32_t
emit_load_gvar(PrismBuilder *builder, uint32_t node_id, pm_location_t location, pm_constant_id_t name_id) {
    return emit_load_name(builder, node_id, location, kPrismInsnLoadGVar, name_id);
}

static uint32_t
emit_load_ivar(PrismBuilder *builder, uint32_t node_id, pm_location_t location, pm_constant_id_t name_id) {
    return emit_load_name(builder, node_id, location, kPrismInsnLoadIVar, name_id);
}

static uint32_t
emit_load_lvar(PrismBuilder *builder, uint32_t node_id, pm_location_t location, uint32_t local_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnLoadLVar, node_id, location, 1);
    insn->as.lvar.local_id = local_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_load_object(PrismBuilder *builder, uint32_t node_id, pm_location_t location, uint32_t object_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnLoadObject, node_id, location, 1);
    insn->as.object.object_id = object_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_load_nil(PrismBuilder *builder, uint32_t node_id, pm_location_t location) {
    return emit_load_object(builder, node_id, location, make_object(builder, kPrismObjectNil));
}

static uint32_t
emit_load_self(PrismBuilder *builder, uint32_t node_id, pm_location_t location) {
    PrismInsn *insn = make_insn(builder, kPrismInsnLoadSelf, node_id, location, 1);

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_new_array(PrismBuilder *builder, uint32_t node_id, pm_location_t location, uint32_t nelement_ids, uint32_t *element_ids) {
    PrismInsn *insn = make_insn(builder, kPrismInsnNewArray, node_id, location, 1 + nelement_ids);

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;
    memcpy(graph->opnds + insn->opnds_off + 1, element_ids, nelement_ids * sizeof(uint32_t));

    return value_id;
}

static uint32_t
emit_new_array_static(PrismBuilder *builder, uint32_t node_id, pm_location_t location, uint32_t object_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnNewArrayStatic, node_id, location, 1);
    insn->as.object.object_id = object_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_new_range(PrismBuilder *builder, uint32_t node_id, pm_location_t location, uint32_t left_id, uint32_t right_id, bool exclude_end) {
    PrismInsn *insn = make_insn(builder, kPrismInsnNewRange, node_id, location, 3);
    insn->as.range.exclude_end = exclude_end;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off + 0] = value_id;
    graph->opnds[insn->opnds_off + 1] = left_id;
    graph->opnds[insn->opnds_off + 2] = right_id;

    return value_id;
}

static void
emit_return(PrismBuilder *builder, uint32_t node_id, pm_location_t location, uint32_t value_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnReturn, node_id, location, 1);

    PrismGraph *graph = PrismBuilder_graph(builder);
    graph->opnds[insn->opnds_off] = value_id;
}

static void
emit_store_name(PrismBuilder *builder, uint32_t node_id, pm_location_t location, PrismInsnKind kind, pm_constant_id_t name_id, uint32_t value_id) {
    PrismInsn *insn = make_insn(builder, kind, node_id, location, 1);
    insn->as.name.name_id = name_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    graph->opnds[insn->opnds_off] = value_id;
}

static void
emit_store_cvar(PrismBuilder *builder, uint32_t node_id, pm_location_t location, pm_constant_id_t name_id, uint32_t value_id) {
    emit_store_name(builder, node_id, location, kPrismInsnStoreCVar, name_id, value_id);
}

static void
emit_store_gvar(PrismBuilder *builder, uint32_t node_id, pm_location_t location, pm_constant_id_t name_id, uint32_t value_id) {
    emit_store_name(builder, node_id, location, kPrismInsnStoreGVar, name_id, value_id);
}

static void
emit_store_ivar(PrismBuilder *builder, uint32_t node_id, pm_location_t location, pm_constant_id_t name_id, uint32_t value_id) {
    emit_store_name(builder, node_id, location, kPrismInsnStoreIVar, name_id, value_id);
}

static void
emit_store_lvar(PrismBuilder *builder, uint32_t node_id, pm_location_t location, uint32_t local_id, uint32_t value_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnStoreLVar, node_id, location, 1);
    insn->as.lvar.local_id = local_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    graph->opnds[insn->opnds_off] = value_id;
}

static void
emit_trace_line(PrismBuilder *builder, uint32_t node_id, pm_location_t location) {
    make_insn(builder, kPrismInsnTraceLine, node_id, location, 0);
}

/******************************************************************************/

static uint32_t
resolve_local(PrismBuilder *builder, pm_constant_id_t name_id) {
    uint32_t graph_id = builder->state.graph_id;

    while (1) {
        PrismGraph *graph = builder->unit->graphs + graph_id;

        for (uint32_t idx = 0; idx < graph->nlocal_ids; ++idx) {
            uint32_t local_id = graph->local_ids[idx];
            if (builder->unit->locals[local_id].name_id == name_id) {
                return local_id;
            }
        }

        if (graph->parent_id == UINT32_MAX) break;
        graph_id = graph->parent_id;
    }

    assert(false && "unreachable");
    return UINT32_MAX;
}

static uint32_t
static_literal(PrismBuilder *builder, const pm_node_t *node) {
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
        case PM_INTEGER_NODE: {
            const pm_integer_node_t *cast = (const pm_integer_node_t *) node;

            uint32_t object_id = make_object(builder, kPrismObjectInteger);
            PrismObject *object = builder->unit->objects + object_id;
            object->as.integer.value = &cast->value;

            return object_id;
        }
        default:
            assert(false && "unsupported static literal node type");
            return UINT32_MAX;
    }
}

static uint32_t compile_node(PrismBuilder *builder, const pm_node_t *node);

static uint32_t
compile_instance_variable_logical_write_node(PrismBuilder *builder, const pm_node_t *node, pm_constant_id_t name, const pm_node_t *value) {
    uint32_t set_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    uint32_t predicate_id = emit_load_ivar(builder, node->node_id, node->location, name);
    if (PM_NODE_TYPE(node) == PM_INSTANCE_VARIABLE_AND_WRITE_NODE) {
        emit_branchif(builder, node->node_id, node->location, predicate_id, set_block_id, 0, NULL, join_block_id, 1, &predicate_id);
    } else {
        emit_branchif(builder, node->node_id, node->location, predicate_id, join_block_id, 1, &predicate_id, set_block_id, 0, NULL);
    }

    builder->state.block_id = set_block_id;
    uint32_t value_id = compile_node(builder, value);
    emit_store_ivar(builder, node->node_id, node->location, name, value_id);
    emit_branch(builder, node->node_id, node->location, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

static uint32_t
compile_local_variable_logical_write_node(PrismBuilder *builder, const pm_node_t *node, pm_constant_id_t name_id, const pm_node_t *value) {
    uint32_t set_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    uint32_t resolved_id = resolve_local(builder, name_id);
    uint32_t local_id = emit_load_lvar(builder, node->node_id, node->location, resolved_id);
    if (PM_NODE_TYPE_P(node, PM_LOCAL_VARIABLE_AND_WRITE_NODE)) {
        emit_branchif(builder, node->node_id, node->location, local_id, set_block_id, 0, NULL, join_block_id, 1, &local_id);
    } else {
        emit_branchif(builder, node->node_id, node->location, local_id, join_block_id, 1, &local_id, set_block_id, 0, NULL);
    }

    builder->state.block_id = set_block_id;
    uint32_t value_id = compile_node(builder, value);
    emit_store_lvar(builder, node->node_id, node->location, resolved_id, value_id);
    emit_branch(builder, node->node_id, node->location, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

static uint32_t
compile_logical_node(PrismBuilder *builder, const pm_node_t *node, const pm_node_t *left, const pm_node_t *right) {
    uint32_t right_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    uint32_t left_value_id = compile_node(builder, left);
    if (PM_NODE_TYPE(node) == PM_AND_NODE) {
        emit_branchif(builder, node->node_id, node->location, left_value_id, right_block_id, 0, NULL, join_block_id, 1, &left_value_id);
    } else {
        emit_branchif(builder, node->node_id, node->location, left_value_id, join_block_id, 1, &left_value_id, right_block_id, 0, NULL);
    }

    builder->state.block_id = right_block_id;
    uint32_t right_value_id = compile_node(builder, right);
    emit_branch(builder, node->node_id, node->location, join_block_id, 1, &right_value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

static uint32_t
compile_loop_node(PrismBuilder *builder, const pm_node_t *node, const pm_node_t *predicate, const pm_statements_node_t *statements) {
    uint32_t predicate_block_id = make_block(builder, 0);
    uint32_t loop_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 0);

    emit_branch(builder, node->node_id, node->location, PM_NODE_FLAG_P(node, PM_LOOP_FLAGS_BEGIN_MODIFIER) ? loop_block_id : predicate_block_id, 0, NULL);

    builder->state.block_id = predicate_block_id;
    uint32_t predicate_id = compile_node(builder, predicate);
    if (PM_NODE_TYPE_P(node, PM_WHILE_NODE)) {
        emit_branchif(builder, node->node_id, node->location, predicate_id, loop_block_id, 0, NULL, join_block_id, 0, NULL);
    } else {
        emit_branchif(builder, node->node_id, node->location, predicate_id, join_block_id, 0, NULL, loop_block_id, 0, NULL);
    }

    builder->state.block_id = loop_block_id;
    if (statements) {
        compile_node(builder, PM_NODE_UPCAST(statements));
    }
    emit_branch(builder, node->node_id, node->location, predicate_block_id, 0, NULL);

    builder->state.block_id = join_block_id;
    return emit_load_nil(builder, node->node_id, node->location);
}

/******************************************************************************/

static uint32_t
compile_alias_method_node(PrismBuilder *builder, const pm_alias_method_node_t *node) {
    uint32_t new_name_id = compile_node(builder, node->new_name);
    uint32_t old_name_id = compile_node(builder, node->old_name);
    emit_alias_method(builder, node->base.node_id, node->base.location, new_name_id, old_name_id);
    return emit_load_nil(builder, node->base.node_id, node->base.location);
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
        return emit_new_array_static(builder, node->base.node_id, node->base.location, object_id);
    } else {
        uint32_t *element_ids = pm_arena_alloc(builder->arena, sizeof(uint32_t) * nelements, PRISM_ALIGNOF(uint32_t));
        for (size_t idx = 0; idx < nelements; ++idx) {
            element_ids[idx] = compile_node(builder, node->elements.nodes[idx]);
        }

        return emit_new_array(builder, node->base.node_id, node->base.location, (uint32_t) nelements, element_ids);
    }
}

static uint32_t
compile_call_node(PrismBuilder *builder, const pm_call_node_t *node) {
    uint32_t receiver_id;
    if (node->receiver) {
        receiver_id = compile_node(builder, node->receiver);
    } else {
        receiver_id = emit_load_self(builder, node->base.node_id, node->base.location);
    }

    size_t nargument_ids = 0;
    uint32_t *argument_ids = NULL;

    if (node->arguments) {
        nargument_ids = node->arguments->arguments.size;
        argument_ids = xmalloc(sizeof(uint32_t) * nargument_ids);
        if (!argument_ids) abort();

        for (size_t idx = 0; idx < nargument_ids; ++idx) {
            argument_ids[idx] = compile_node(builder, node->arguments->arguments.nodes[idx]);
        }
    }

    uint32_t value_id = emit_call(builder, node->base.node_id, node->base.location, node->name, receiver_id, nargument_ids, argument_ids);
    if (nargument_ids) xfree(argument_ids);
    return value_id;
}

static uint32_t
compile_class_variable_read_node(PrismBuilder *builder, const pm_class_variable_read_node_t *node) {
    return emit_load_cvar(builder, node->base.node_id, node->base.location, node->name);
}

static uint32_t
compile_class_variable_write_node(PrismBuilder *builder, const pm_class_variable_write_node_t *node) {
    uint32_t value_id = compile_node(builder, node->value);
    emit_store_cvar(builder, node->base.node_id, node->base.location, node->name, value_id);
    return value_id;
}

static uint32_t
compile_class_variable_operator_write_node(PrismBuilder *builder, const pm_class_variable_operator_write_node_t *node) {
    uint32_t receiver_id = emit_load_cvar(builder, node->base.node_id, node->base.location, node->name);
    uint32_t value_id = compile_node(builder, node->value);
    uint32_t result_id = emit_call(builder, node->base.node_id, node->base.location, node->binary_operator, receiver_id, 1, &value_id);
    emit_store_cvar(builder, node->base.node_id, node->base.location, node->name, result_id);
    return result_id;
}

static uint32_t
compile_class_variable_and_write_node(PrismBuilder *builder, const pm_class_variable_and_write_node_t *node) {
    uint32_t set_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    uint32_t predicate_id = emit_load_cvar(builder, node->base.node_id, node->base.location, node->name);
    emit_branchif(builder, node->base.node_id, node->base.location, predicate_id, set_block_id, 0, NULL, join_block_id, 1, &predicate_id);

    builder->state.block_id = set_block_id;
    uint32_t value_id = compile_node(builder, node->value);
    emit_store_cvar(builder, node->base.node_id, node->base.location, node->name, value_id);
    emit_branch(builder, node->base.node_id, node->base.location, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

static uint32_t
compile_class_variable_or_write_node(PrismBuilder *builder, const pm_class_variable_or_write_node_t *node) {
    uint32_t defined_block_id = make_block(builder, 0);
    uint32_t undefined_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    uint32_t defined_id = emit_defined_cvar(builder, node->base.node_id, node->base.location, node->name);
    emit_branchif(builder, node->base.node_id, node->base.location, defined_id, defined_block_id, 0, NULL, undefined_block_id, 0, NULL);

    builder->state.block_id = defined_block_id;
    uint32_t predicate_id = emit_load_cvar(builder, node->base.node_id, node->base.location, node->name);
    emit_branchif(builder, node->base.node_id, node->base.location, predicate_id, join_block_id, 1, &predicate_id, undefined_block_id, 0, NULL);

    builder->state.block_id = undefined_block_id;
    uint32_t value_id = compile_node(builder, node->value);
    emit_store_cvar(builder, node->base.node_id, node->base.location, node->name, value_id);
    emit_branch(builder, node->base.node_id, node->base.location, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

static uint32_t
compile_def_node(PrismBuilder *builder, const pm_def_node_t *node) {
    PrismBuilderState state = builder->state;
    uint32_t graph_id = make_graph(builder, UINT32_MAX, (uint32_t) node->locals.size);

    uint32_t nparams = 0;
    const pm_parameters_node_t *parameters = node->parameters;
    if (parameters) {
        nparams = (uint32_t) parameters->requireds.size;
    }

    builder->state.graph_id = graph_id;
    builder->state.block_id = make_block(builder, nparams);
    builder->state.lineno = builder->parser->start_line - 1;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t *params = graph->blocks[builder->state.block_id].params;

    for (size_t idx = 0; idx < node->locals.size; ++idx) {
        graph->local_ids[idx] = make_local(builder, node->locals.ids[idx]);
    }

    if (parameters) {
        for (size_t idx = 0; idx < parameters->requireds.size; ++idx) {
            const pm_node_t *required = parameters->requireds.nodes[idx];

            if (PM_NODE_TYPE_P(required, PM_REQUIRED_PARAMETER_NODE)) {
                uint32_t resolved_id = resolve_local(builder, ((const pm_required_parameter_node_t *) required)->name);
                emit_store_lvar(builder, required->node_id, required->location, resolved_id, params[idx]);
            }
        }
    }

    uint32_t value_id;
    if (node->body) {
        value_id = compile_node(builder, node->body);
    } else {
        value_id = emit_load_nil(builder, node->base.node_id, node->base.location);
    }

    emit_return(builder, node->base.node_id, node->base.location, value_id);

    builder->state = state;
    emit_define_method(builder, node->base.node_id, node->base.location, node->name, graph_id);

    uint32_t object_id = make_object_constant_id(builder, node->name);
    return emit_load_object(builder, node->base.node_id, node->base.location, object_id);
}

static uint32_t
compile_false_node(PrismBuilder *builder, const pm_false_node_t *node) {
    uint32_t object_id = make_object(builder, kPrismObjectFalse);
    return emit_load_object(builder, node->base.node_id, node->base.location, object_id);
}

static uint32_t
compile_float_node(PrismBuilder *builder, const pm_float_node_t *node) {
    uint32_t object_id = make_object(builder, kPrismObjectFloat);
    builder->unit->objects[object_id].as.floating.value = node->value;
    return emit_load_object(builder, node->base.node_id, node->base.location, object_id);
}

static uint32_t
compile_global_variable_read_node(PrismBuilder *builder, const pm_global_variable_read_node_t *node) {
    return emit_load_gvar(builder, node->base.node_id, node->base.location, node->name);
}

static uint32_t
compile_global_variable_write_node(PrismBuilder *builder, const pm_global_variable_write_node_t *node) {
    uint32_t value_id = compile_node(builder, node->value);
    emit_store_gvar(builder, node->base.node_id, node->base.location, node->name, value_id);
    return value_id;
}

static uint32_t
compile_global_variable_operator_write_node(PrismBuilder *builder, const pm_global_variable_operator_write_node_t *node) {
    uint32_t receiver_id = emit_load_gvar(builder, node->base.node_id, node->base.location, node->name);
    uint32_t value_id = compile_node(builder, node->value);
    uint32_t result_id = emit_call(builder, node->base.node_id, node->base.location, node->binary_operator, receiver_id, 1, &value_id);
    emit_store_gvar(builder, node->base.node_id, node->base.location, node->name, result_id);
    return result_id;
}

static uint32_t
compile_global_variable_and_write_node(PrismBuilder *builder, const pm_global_variable_and_write_node_t *node) {
    uint32_t set_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    uint32_t predicate_id = emit_load_gvar(builder, node->base.node_id, node->base.location, node->name);
    emit_branchif(builder, node->base.node_id, node->base.location, predicate_id, set_block_id, 0, NULL, join_block_id, 1, &predicate_id);

    builder->state.block_id = set_block_id;
    uint32_t value_id = compile_node(builder, node->value);
    emit_store_gvar(builder, node->base.node_id, node->base.location, node->name, value_id);
    emit_branch(builder, node->base.node_id, node->base.location, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

static uint32_t
compile_global_variable_or_write_node(PrismBuilder *builder, const pm_global_variable_or_write_node_t *node) {
    uint32_t defined_block_id = make_block(builder, 0);
    uint32_t undefined_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    uint32_t defined_id = emit_defined_gvar(builder, node->base.node_id, node->base.location, node->name);
    emit_branchif(builder, node->base.node_id, node->base.location, defined_id, defined_block_id, 0, NULL, undefined_block_id, 0, NULL);

    builder->state.block_id = defined_block_id;
    uint32_t predicate_id = emit_load_gvar(builder, node->base.node_id, node->base.location, node->name);
    emit_branchif(builder, node->base.node_id, node->base.location, predicate_id, join_block_id, 1, &predicate_id, undefined_block_id, 0, NULL);

    builder->state.block_id = undefined_block_id;
    uint32_t value_id = compile_node(builder, node->value);
    emit_store_gvar(builder, node->base.node_id, node->base.location, node->name, value_id);
    emit_branch(builder, node->base.node_id, node->base.location, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

static uint32_t
compile_instance_variable_read_node(PrismBuilder *builder, const pm_instance_variable_read_node_t *node) {
    return emit_load_ivar(builder, node->base.node_id, node->base.location, node->name);
}

static uint32_t
compile_instance_variable_write_node(PrismBuilder *builder, const pm_instance_variable_write_node_t *node) {
    uint32_t value_id = compile_node(builder, node->value);
    emit_store_ivar(builder, node->base.node_id, node->base.location, node->name, value_id);
    return value_id;
}

static uint32_t
compile_instance_variable_operator_write_node(PrismBuilder *builder, const pm_instance_variable_operator_write_node_t *node) {
    uint32_t receiver_id = emit_load_ivar(builder, node->base.node_id, node->base.location, node->name);
    uint32_t value_id = compile_node(builder, node->value);
    uint32_t result_id = emit_call(builder, node->base.node_id, node->base.location, node->binary_operator, receiver_id, 1, &value_id);
    emit_store_ivar(builder, node->base.node_id, node->base.location, node->name, result_id);
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
    uint32_t object_id = make_object(builder, kPrismObjectInteger);
    builder->unit->objects[object_id].as.integer.value = &node->value;
    return emit_load_object(builder, node->base.node_id, node->base.location, object_id);
}

static uint32_t
compile_local_variable_read_node(PrismBuilder *builder, const pm_local_variable_read_node_t *node) {
    uint32_t local_id = resolve_local(builder, node->name);
    return emit_load_lvar(builder, node->base.node_id, node->base.location, local_id);
}

static uint32_t
compile_local_variable_write_node(PrismBuilder *builder, const pm_local_variable_write_node_t *node) {
    uint32_t local_id = resolve_local(builder, node->name);
    uint32_t value_id = compile_node(builder, node->value);
    emit_store_lvar(builder, node->base.node_id, node->base.location, local_id, value_id);
    return value_id;
}

static uint32_t
compile_local_variable_operator_write_node(PrismBuilder *builder, const pm_local_variable_operator_write_node_t *node) {
    uint32_t resolved_id = resolve_local(builder, node->name);
    uint32_t local_id = emit_load_lvar(builder, node->base.node_id, node->base.location, resolved_id);
    uint32_t value_id = compile_node(builder, node->value);
    uint32_t result_id = emit_call(builder, node->base.node_id, node->base.location, node->binary_operator, local_id, 1, &value_id);
    emit_store_lvar(builder, node->base.node_id, node->base.location, resolved_id, result_id);
    return result_id;
}

static uint32_t
compile_local_variable_and_write_node(PrismBuilder *builder, const pm_local_variable_and_write_node_t *node) {
    return compile_local_variable_logical_write_node(builder, PM_NODE_UPCAST(node), node->name, node->value);
}

static uint32_t
compile_local_variable_or_write_node(PrismBuilder *builder, const pm_local_variable_or_write_node_t *node) {
    return compile_local_variable_logical_write_node(builder, PM_NODE_UPCAST(node), node->name, node->value);
}

static uint32_t
compile_nil_node(PrismBuilder *builder, const pm_nil_node_t *node) {
    uint32_t object_id = make_object(builder, kPrismObjectNil);
    return emit_load_object(builder, node->base.node_id, node->base.location, object_id);
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
        return emit_load_nil(builder, node->base.node_id, node->base.location);
    }
}

static uint32_t
compile_program_node(PrismBuilder *builder, const pm_program_node_t *node) {
    builder->state.graph_id = make_graph(builder, UINT32_MAX, (uint32_t) node->locals.size);
    builder->state.block_id = make_block(builder, 0);

    PrismGraph *graph = PrismBuilder_graph(builder);
    for (size_t idx = 0; idx < node->locals.size; ++idx) {
        graph->local_ids[idx] = make_local(builder, node->locals.ids[idx]);
    }

    const pm_statements_node_t *statements = (const pm_statements_node_t *) node->statements;
    uint32_t value_id;

    if (statements->body.size) {
        value_id = compile_node(builder, PM_NODE_UPCAST(statements));
    } else {
        value_id = emit_load_nil(builder, node->base.node_id, node->base.location);
    }

    emit_return(builder, node->base.node_id, node->base.location, value_id);
    return UINT32_MAX;
}

static uint32_t
compile_range_node(PrismBuilder *builder, const pm_range_node_t *node) {
    uint32_t left_id;
    if (node->left) {
        left_id = compile_node(builder, node->left);
    } else {
        left_id = emit_load_nil(builder, node->base.node_id, node->base.location);
    }

    uint32_t right_id;
    if (node->right) {
        right_id = compile_node(builder, node->right);
    } else {
        right_id = emit_load_nil(builder, node->base.node_id, node->base.location);
    }

    return emit_new_range(builder, node->base.node_id, node->base.location, left_id, right_id, PM_NODE_FLAG_P(node, PM_RANGE_FLAGS_EXCLUDE_END));
}

static uint32_t
compile_self_node(PrismBuilder *builder, const pm_self_node_t *node) {
    return emit_load_self(builder, node->base.node_id, node->base.location);
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

    return emit_load_object(builder, node->base.node_id, node->base.location, object_id);
}

static uint32_t
compile_symbol_node(PrismBuilder *builder, const pm_symbol_node_t *node) {
    uint32_t object_id = make_object(builder, kPrismObjectSymbol);
    PrismObject *object = builder->unit->objects + object_id;

    object->as.string.flags = node->base.flags;
    object->as.string.unescaped = &node->unescaped;

    return emit_load_object(builder, node->base.node_id, node->base.location, object_id);
}

static uint32_t
compile_true_node(PrismBuilder *builder, const pm_true_node_t *node) {
    uint32_t object_id = make_object(builder, kPrismObjectTrue);
    return emit_load_object(builder, node->base.node_id, node->base.location, object_id);
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

    uint32_t receiver_id = emit_load_self(builder, node->base.node_id, node->base.location);
    uint32_t argument_id = emit_load_object(builder, node->base.node_id, node->base.location, object_id);
    return emit_call(builder, node->base.node_id, node->base.location, PM_CONSTANT_BACKTICK, receiver_id, 1, &argument_id);
}

static uint32_t
compile_node(PrismBuilder *builder, const pm_node_t *node) {
    if (PM_NODE_FLAG_P(node, PM_NODE_FLAG_NEWLINE)) {
        int32_t lineno = pm_line_offset_list_line(&builder->parser->line_offsets, node->location.start, builder->parser->start_line);
        if (builder->state.lineno != lineno) {
            emit_trace_line(builder, node->node_id, node->location);
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
        case PM_CALL_NODE:
            return compile_call_node(builder, (const pm_call_node_t *) node);
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
        case PM_DEF_NODE:
            return compile_def_node(builder, (const pm_def_node_t *) node);
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
        case PM_NIL_NODE:
            return compile_nil_node(builder, (const pm_nil_node_t *) node);
        case PM_OR_NODE:
            return compile_or_node(builder, (const pm_or_node_t *) node);
        case PM_PARENTHESES_NODE:
            return compile_parentheses_node(builder, (const pm_parentheses_node_t *) node);
        case PM_PROGRAM_NODE:
            return compile_program_node(builder, (const pm_program_node_t *) node);
        case PM_RANGE_NODE:
            return compile_range_node(builder, (const pm_range_node_t *) node);
        case PM_SELF_NODE:
            return compile_self_node(builder, (const pm_self_node_t *) node);
        case PM_STATEMENTS_NODE:
            return compile_statements_node(builder, (const pm_statements_node_t *) node);
        case PM_STRING_NODE:
            return compile_string_node(builder, (const pm_string_node_t *) node);
        case PM_SYMBOL_NODE:
            return compile_symbol_node(builder, (const pm_symbol_node_t *) node);
        case PM_TRUE_NODE:
            return compile_true_node(builder, (const pm_true_node_t *) node);
        case PM_UNTIL_NODE:
            return compile_until_node(builder, (const pm_until_node_t *) node);
        case PM_WHILE_NODE:
            return compile_while_node(builder, (const pm_while_node_t *) node);
        case PM_X_STRING_NODE:
            return compile_x_string_node(builder, (const pm_x_string_node_t *) node);
        case PM_REQUIRED_PARAMETER_NODE:
            fprintf(stderr, "Handled elsewhere: %s\n", pm_node_type(node->type));
            abort();
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
                case kPrismInsnDefineMethod: {
                    const pm_constant_t *constant = compile_constant(builder->parser, insn->as.method.name_id);
                    printf("define_method :%.*s, g%" PRIu32 "\n", (int) pm_constant_length(constant), (const char *) pm_constant_start(constant), insn->as.method.graph_id);
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
                case kPrismInsnLoadLVar: {
                    printf("%%%" PRIu32 " = load_lvar v%" PRIu32 "\n", opnds[0], insn->as.lvar.local_id);
                    break;
                }
                case kPrismInsnLoadObject: {
                    printf("%%%" PRIu32 " = load_object ", opnds[0]);
                    dump_object(builder, insn->as.object.object_id);
                    printf("\n");
                    break;
                }
                case kPrismInsnLoadSelf:
                    printf("%%%" PRIu32 " = load_self\n", opnds[0]);
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
                case kPrismInsnNewRange:
                    printf("%%%" PRIu32 " = new_range %%%" PRIu32 ", %%%" PRIu32 ", exclude_end=%d\n", opnds[0], opnds[1], opnds[2], insn->as.range.exclude_end);
                    break;
                case kPrismInsnReturn:
                    printf("return %%%" PRIu32 "\n", opnds[0]);
                    break;
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
                case kPrismInsnTraceLine:
                    printf("trace_line %d\n", pm_line_offset_list_line(&builder->parser->line_offsets, insn->location.start, builder->parser->start_line));
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

void
pm_compile(const pm_parser_t *parser, const pm_node_t *node) {
    pm_arena_t arena = { 0 };
    PrismUnit unit = { 0 };
    PrismBuilder builder = {
        .parser = parser,
        .arena = &arena,
        .unit = &unit,
        .state = {
            .graph_id = 0,
            .block_id = 0,
            .lineno = parser->start_line - 1
        }
    };

    compile_node(&builder, node);
    dump_unit(&builder);
    pm_arena_cleanup(&arena);
}
