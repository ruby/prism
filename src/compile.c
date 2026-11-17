#include "prism/compile.h"

#include "prism/compiler/align.h"
#include "prism/internal/allocator.h"
#include "prism/internal/arena.h"
#include "prism/internal/compile.h"
#include "prism/internal/constant_pool.h"
#include "prism/internal/integer.h"
#include "prism/internal/line_offset_list.h"
#include "prism/internal/oom.h"
#include "prism/internal/parser.h"
#include "prism/node.h"

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#define PM_CONSTANT_ID_BACKTICK (pm_constant_id_t) -1
#define PM_CONSTANT_ID_LAST_LINE (pm_constant_id_t) -2
#define PM_CONSTANT_ID_MATCH (pm_constant_id_t) -3
#define PM_CONSTANT_ID_EACH (pm_constant_id_t) -4
#define PM_CONSTANT_ID_IT (pm_constant_id_t) -5
#define PM_CONSTANT_ID_ASET (pm_constant_id_t) -6
#define PM_CONSTANT_ID_LENGTH (pm_constant_id_t) -7
#define PM_CONSTANT_ID_EQUAL (pm_constant_id_t) -8
#define PM_CONSTANT_ID_LINE_NUMBER (pm_constant_id_t) -9
#define PM_CONSTANT_ID_REST (pm_constant_id_t) -10
#define PM_CONSTANT_ID_KEYWORD_REST (pm_constant_id_t) -11
#define PM_CONSTANT_ID_BLOCK (pm_constant_id_t) -12
#define PM_CONSTANT_ID_DESTRUCTURED (pm_constant_id_t) -13
#define PM_CONSTANT_ID_AREF (pm_constant_id_t) -14
#define PM_CONSTANT_ID_UMINUS (pm_constant_id_t) -15
#define PM_CONSTANT_ID_GREATER_EQUAL (pm_constant_id_t) -16
#define PM_CONSTANT_ID_ADD (pm_constant_id_t) -17
#define PM_CONSTANT_ID_SUBTRACT (pm_constant_id_t) -18
#define PM_CONSTANT_ID_LESS_EQUAL (pm_constant_id_t) -19
#define PM_CONSTANT_ID_DUP (pm_constant_id_t) -20
#define PM_CONSTANT_ID_KEY_P (pm_constant_id_t) -21
#define PM_CONSTANT_ID_DELETE (pm_constant_id_t) -22
#define PM_CONSTANT_ID_EMPTY_P (pm_constant_id_t) -23

static const pm_constant_t builtin_constants[] = {
    { .start = (const uint8_t *) "`", .length = 1 },
    { .start = (const uint8_t *) "$_", .length = 2 },
    { .start = (const uint8_t *) "=~", .length = 2 },
    { .start = (const uint8_t *) "each", .length = 4 },
    { .start = (const uint8_t *) "it", .length = 2 },
    { .start = (const uint8_t *) "[]=", .length = 3 },
    { .start = (const uint8_t *) "length", .length = 6 },
    { .start = (const uint8_t *) "==", .length = 2 },
    { .start = (const uint8_t *) "$.", .length = 2 },
    { .start = (const uint8_t *) "*", .length = 1 },
    { .start = (const uint8_t *) "**", .length = 2 },
    { .start = (const uint8_t *) "&", .length = 1 },
    { .start = (const uint8_t *) "<destructured>", .length = 14 },
    { .start = (const uint8_t *) "[]", .length = 2 },
    { .start = (const uint8_t *) "-@", .length = 2 },
    { .start = (const uint8_t *) ">=", .length = 2 },
    { .start = (const uint8_t *) "+", .length = 1 },
    { .start = (const uint8_t *) "-", .length = 1 },
    { .start = (const uint8_t *) "<=", .length = 2 },
    { .start = (const uint8_t *) "dup", .length = 3 },
    { .start = (const uint8_t *) "key?", .length = 4 },
    { .start = (const uint8_t *) "delete", .length = 6 },
    { .start = (const uint8_t *) "empty?", .length = 6 },
};

static const uint32_t nbuiltin_constants = sizeof(builtin_constants) / sizeof(builtin_constants[0]);

static const pm_constant_t *
compile_constant(const pm_parser_t *parser, pm_constant_id_t constant_id) {
    uint32_t index = UINT32_MAX - constant_id;
    return index < nbuiltin_constants ? &builtin_constants[index] : pm_parser_constant(parser, constant_id);
}

typedef struct {
    uint32_t *ids;
    size_t size;
    uint32_t block_id;
    uint32_t last_id;
    bool splat;
    bool keywords;
    bool block_argument;
} PrismArguments;

typedef struct {
    uint32_t graph_id;
    uint32_t block_id;
    uint32_t region_id;
    uint32_t retry_block_id;
    uint32_t break_block_id;
    uint32_t next_block_id;
    uint32_t redo_block_id;
    uint32_t it_local_id;
    uint32_t rest_local_id;
    uint32_t keyword_rest_local_id;
    uint32_t block_local_id;
    int32_t lineno;
    const pm_constant_id_list_t *locals;
    uint32_t *shadowed;
} PrismBuilderState;

typedef struct {
    const pm_parser_t *parser;
    pm_arena_t *arena;
    pm_arena_t scratch;
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

void
pm_unit_free(PrismUnit *unit) {
    xfree_sized(unit, sizeof(PrismUnit));
}

uint32_t
pm_unit_nconstants(const PrismUnit *unit) {
    return unit->nconstants;
}

const pm_constant_t *
pm_unit_constant(const PrismUnit *unit, uint32_t index) {
    assert(index < unit->nconstants);
    return &unit->constants[index];
}

uint32_t
pm_unit_constant_index(const PrismUnit *unit, pm_constant_id_t constant_id) {
    uint32_t index = UINT32_MAX - constant_id;
    return index < nbuiltin_constants ? unit->nconstants - nbuiltin_constants + index : (uint32_t) pm_constant_id_index(constant_id);
}

uint32_t
pm_unit_nonce_sites(const PrismUnit *unit) {
    return unit->nonce_sites;
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

pm_constant_id_t
pm_local_name_id(const PrismLocal *local) {
    return local->name_id;
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
pm_graph_scope_id(const PrismGraph *graph) {
    return graph->scope_id;
}

const PrismSignature *
pm_graph_signature(const PrismGraph *graph) {
    return &graph->signature;
}

uint32_t
pm_signature_nrequired_ids(const PrismSignature *signature) {
    return signature->nrequired_ids;
}

uint32_t
pm_signature_required_id(const PrismSignature *signature, uint32_t required_idx) {
    assert(required_idx < signature->nrequired_ids);
    return signature->required_ids[required_idx];
}

uint32_t
pm_signature_noptional_ids(const PrismSignature *signature) {
    return signature->noptional_ids;
}

uint32_t
pm_signature_optional_id(const PrismSignature *signature, uint32_t optional_idx) {
    assert(optional_idx < signature->noptional_ids);
    return signature->optional_ids[optional_idx];
}

uint32_t
pm_signature_optional_specified_id(const PrismSignature *signature, uint32_t optional_idx) {
    assert(optional_idx < signature->noptional_ids);
    return signature->optional_specified_ids[optional_idx];
}

uint32_t
pm_signature_rest_id(const PrismSignature *signature) {
    return signature->rest_id;
}

uint32_t
pm_signature_npost_ids(const PrismSignature *signature) {
    return signature->npost_ids;
}

uint32_t
pm_signature_post_id(const PrismSignature *signature, uint32_t post_idx) {
    assert(post_idx < signature->npost_ids);
    return signature->post_ids[post_idx];
}

uint32_t
pm_signature_nrequired_keyword_ids(const PrismSignature *signature) {
    return signature->nrequired_keyword_ids;
}

uint32_t
pm_signature_required_keyword_id(const PrismSignature *signature, uint32_t keyword_idx) {
    assert(keyword_idx < signature->nrequired_keyword_ids);
    return signature->required_keyword_ids[keyword_idx];
}

pm_constant_id_t
pm_signature_required_keyword_name_id(const PrismSignature *signature, uint32_t keyword_idx) {
    assert(keyword_idx < signature->nrequired_keyword_ids);
    return signature->required_keyword_names[keyword_idx];
}

uint32_t
pm_signature_noptional_keyword_ids(const PrismSignature *signature) {
    return signature->noptional_keyword_ids;
}

uint32_t
pm_signature_optional_keyword_id(const PrismSignature *signature, uint32_t keyword_idx) {
    assert(keyword_idx < signature->noptional_keyword_ids);
    return signature->optional_keyword_ids[keyword_idx];
}

uint32_t
pm_signature_optional_keyword_specified_id(const PrismSignature *signature, uint32_t keyword_idx) {
    assert(keyword_idx < signature->noptional_keyword_ids);
    return signature->optional_keyword_specified_ids[keyword_idx];
}

pm_constant_id_t
pm_signature_optional_keyword_name_id(const PrismSignature *signature, uint32_t keyword_idx) {
    assert(keyword_idx < signature->noptional_keyword_ids);
    return signature->optional_keyword_names[keyword_idx];
}

uint32_t
pm_signature_keyword_rest_id(const PrismSignature *signature) {
    return signature->keyword_rest_id;
}

uint32_t
pm_signature_block_id(const PrismSignature *signature) {
    return signature->block_id;
}

bool
pm_signature_no_keywords(const PrismSignature *signature) {
    return signature->no_keywords;
}

bool
pm_signature_no_block(const PrismSignature *signature) {
    return signature->no_block;
}

bool
pm_signature_autosplat(const PrismSignature *signature) {
    return signature->autosplat;
}

uint32_t
pm_graph_nregions(const PrismGraph *graph) {
    return graph->nregions;
}

const PrismRegion *
pm_graph_region(const PrismGraph *graph, uint32_t region_id) {
    assert(region_id < graph->nregions);
    return graph->regions + region_id;
}

PrismRegionKind
pm_region_kind(const PrismRegion *region) {
    return region->kind;
}

uint32_t
pm_region_parent_id(const PrismRegion *region) {
    return region->parent_id;
}

uint32_t
pm_region_entry_block_id(const PrismRegion *region) {
    return region->entry_block_id;
}

uint32_t
pm_region_handler_block_id(const PrismRegion *region) {
    return region->handler_block_id;
}

uint32_t
pm_block_region_id(const PrismBlock *block) {
    return block->region_id;
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
pm_graph_nflip_flops(const PrismGraph *graph) {
    return graph->nflip_flops;
}

uint32_t
pm_graph_nvalues(const PrismGraph *graph) {
    return graph->value_id;
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

pm_node_flags_t
pm_object_concat_flags(const PrismObject *object) {
    return object->as.concat.flags;
}

uint32_t
pm_object_concat_size(const PrismObject *object) {
    return object->as.concat.nobject_ids;
}

uint32_t
pm_object_concat_object_id(const PrismObject *object, uint32_t idx) {
    return object->as.concat.object_ids[idx];
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

uint32_t
pm_object_range_left_id(const PrismObject *object) {
    return object->as.range.left_id;
}

uint32_t
pm_object_range_right_id(const PrismObject *object) {
    return object->as.range.right_id;
}

bool
pm_object_range_exclude_end(const PrismObject *object) {
    return object->as.range.exclude_end;
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

pm_constant_id_t
pm_object_constant_id(const PrismObject *object) {
    return object->as.string.constant_id;
}

pm_node_flags_t
pm_object_flags(const PrismObject *object) {
    return object->as.string.flags;
}

uint32_t
pm_insn_branch_block_id(const PrismInsn *insn) {
    return insn->as.branch.block_id;
}

uint32_t
pm_insn_branchif_then_block_id(const PrismInsn *insn) {
    return insn->as.branchif.then_block_id;
}

uint32_t
pm_insn_branchif_else_block_id(const PrismInsn *insn) {
    return insn->as.branchif.else_block_id;
}

uint32_t
pm_insn_branchif_then_nopnds(const PrismInsn *insn) {
    return insn->as.branchif.then_opnds_len;
}

bool
pm_insn_call_splat(const PrismInsn *insn) {
    return insn->as.call.splat;
}

bool
pm_insn_call_keywords(const PrismInsn *insn) {
    return insn->as.call.keywords;
}

bool
pm_insn_call_ignore_visibility(const PrismInsn *insn) {
    return insn->as.call.ignore_visibility;
}

bool
pm_insn_call_variable_call(const PrismInsn *insn) {
    return insn->as.call.variable_call;
}

bool
pm_insn_call_block(const PrismInsn *insn) {
    return insn->as.call.block;
}

bool
pm_insn_call_block_argument(const PrismInsn *insn) {
    return insn->as.call.block_argument;
}

pm_constant_id_t
pm_insn_call_name_id(const PrismInsn *insn) {
    return insn->as.call.name_id;
}

pm_constant_id_t
pm_insn_name_id(const PrismInsn *insn) {
    return insn->as.name.name_id;
}

pm_constant_id_t
pm_insn_define_name_id(const PrismInsn *insn) {
    return insn->as.define.name_id;
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
pm_insn_new_block_graph_id(const PrismInsn *insn) {
    return insn->as.new_block.graph_id;
}

uint32_t
pm_insn_ensure_return_region_id(const PrismInsn *insn) {
    return insn->as.ensure_return.region_id;
}

uint32_t
pm_insn_once_region_id(const PrismInsn *insn) {
    return insn->as.once.region_id;
}

uint32_t
pm_insn_once_site_id(const PrismInsn *insn) {
    return insn->as.once.site_id;
}

uint32_t
pm_insn_post_execution_graph_id(const PrismInsn *insn) {
    return insn->as.post_execution.graph_id;
}

uint32_t
pm_insn_expand_array_lefts(const PrismInsn *insn) {
    return insn->as.expand_array.lefts;
}

uint32_t
pm_insn_expand_array_rights(const PrismInsn *insn) {
    return insn->as.expand_array.rights;
}

bool
pm_insn_expand_array_rest(const PrismInsn *insn) {
    return insn->as.expand_array.rest;
}

uint32_t
pm_insn_last_match_group_number(const PrismInsn *insn) {
    return insn->as.last_match_group.number;
}

const PrismConstantPath *
pm_insn_constant_path(const PrismInsn *insn) {
    return &insn->as.constant_path;
}

uint32_t
pm_insn_flip_flop_index(const PrismInsn *insn) {
    return insn->as.flip_flop.index;
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

pm_constant_id_t
PrismConstantPath_constant_id(const PrismConstantPath *constant_path, uint32_t idx) {
    assert(idx < constant_path->size);

    pm_constant_id_t constant_id;
    if (constant_path->size == 1) {
        constant_id = constant_path->as.constant_id;
    } else {
        constant_id = constant_path->as.constant_ids[idx];
    }

    return constant_id;
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
make_flip_flop(PrismBuilder *builder) {
    uint32_t graph_id = PrismBuilder_graph(builder)->scope_id;
    while (builder->unit->graphs[graph_id].kind == kPrismGraphBlock || builder->unit->graphs[graph_id].kind == kPrismGraphLambda) {
        uint32_t parent_id = builder->unit->graphs[graph_id].parent_id;
        graph_id = builder->unit->graphs[parent_id].scope_id;
    }
    return builder->unit->graphs[graph_id].nflip_flops++;
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
    unit->graphs[graph_id] = (PrismGraph) {
        .signature = {
            .rest_id = UINT32_MAX,
            .keyword_rest_id = UINT32_MAX,
            .block_id = UINT32_MAX
        },
        .kind = kind,
        .parent_id = parent_id,
        .scope_id = graph_id,
        .local_ids = local_ids,
        .nlocal_ids = nlocal_ids
    };

    return graph_id;
}

static inline uint32_t
make_value(PrismBuilder *builder) {
    return PrismBuilder_graph(builder)->value_id++;
}

static void
make_signature(PrismBuilder *builder, uint32_t graph_id, PrismSignature *signature, uint32_t nrequired_ids, uint32_t noptional_ids, bool has_rest, uint32_t npost_ids) {
    PrismGraph *graph = builder->unit->graphs + graph_id;

    *signature = (PrismSignature) {
        .nrequired_ids = nrequired_ids,
        .noptional_ids = noptional_ids,
        .rest_id = UINT32_MAX,
        .keyword_rest_id = UINT32_MAX,
        .block_id = UINT32_MAX,
        .npost_ids = npost_ids
    };

    if (nrequired_ids) {
        signature->required_ids = pm_arena_alloc(builder->arena, sizeof(uint32_t) * nrequired_ids, PRISM_ALIGNOF(uint32_t));
        for (uint32_t idx = 0; idx < nrequired_ids; ++idx) {
            signature->required_ids[idx] = graph->value_id++;
        }
    }

    if (noptional_ids) {
        signature->optional_ids = pm_arena_alloc(builder->arena, sizeof(uint32_t) * noptional_ids, PRISM_ALIGNOF(uint32_t));
        signature->optional_specified_ids = pm_arena_alloc(builder->arena, sizeof(uint32_t) * noptional_ids, PRISM_ALIGNOF(uint32_t));
        for (uint32_t idx = 0; idx < noptional_ids; ++idx) {
            signature->optional_ids[idx] = graph->value_id++;
            signature->optional_specified_ids[idx] = graph->value_id++;
        }
    }

    if (has_rest) {
        signature->rest_id = graph->value_id++;
    }

    if (npost_ids) {
        signature->post_ids = pm_arena_alloc(builder->arena, sizeof(uint32_t) * npost_ids, PRISM_ALIGNOF(uint32_t));
        for (uint32_t idx = 0; idx < npost_ids; ++idx) {
            signature->post_ids[idx] = graph->value_id++;
        }
    }
}

static void
compile_parameters_signature(PrismBuilder *builder, uint32_t graph_id, PrismSignature *signature, const pm_parameters_node_t *parameters) {
    uint32_t nrequired_ids = parameters ? (uint32_t) parameters->requireds.size : 0;
    uint32_t noptional_ids = parameters ? (uint32_t) parameters->optionals.size : 0;
    uint32_t npost_ids = parameters ? (uint32_t) parameters->posts.size : 0;

    bool forwarding = parameters && parameters->keyword_rest && PM_NODE_TYPE_P(parameters->keyword_rest, PM_FORWARDING_PARAMETER_NODE);
    bool has_rest = forwarding || (parameters && parameters->rest && PM_NODE_TYPE_P(parameters->rest, PM_REST_PARAMETER_NODE));

    make_signature(builder, graph_id, signature, nrequired_ids, noptional_ids, has_rest, npost_ids);
    signature->no_keywords = parameters && parameters->keyword_rest && PM_NODE_TYPE_P(parameters->keyword_rest, PM_NO_KEYWORDS_PARAMETER_NODE);
    signature->no_block = parameters && parameters->block && PM_NODE_TYPE_P(parameters->block, PM_NO_BLOCK_PARAMETER_NODE);

    if (parameters && parameters->keywords.size) {
        uint32_t nrequired_keyword_ids = 0;
        uint32_t noptional_keyword_ids = 0;

        for (size_t idx = 0; idx < parameters->keywords.size; ++idx) {
            if (PM_NODE_TYPE_P(parameters->keywords.nodes[idx], PM_REQUIRED_KEYWORD_PARAMETER_NODE)) {
                nrequired_keyword_ids++;
            } else if (PM_NODE_TYPE_P(parameters->keywords.nodes[idx], PM_OPTIONAL_KEYWORD_PARAMETER_NODE)) {
                noptional_keyword_ids++;
            }
        }

        signature->nrequired_keyword_ids = nrequired_keyword_ids;
        signature->noptional_keyword_ids = noptional_keyword_ids;

        if (nrequired_keyword_ids) {
            PrismGraph *graph = builder->unit->graphs + graph_id;
            signature->required_keyword_names = pm_arena_alloc(builder->arena, sizeof(pm_constant_id_t) * nrequired_keyword_ids, PRISM_ALIGNOF(pm_constant_id_t));
            signature->required_keyword_ids = pm_arena_alloc(builder->arena, sizeof(uint32_t) * nrequired_keyword_ids, PRISM_ALIGNOF(uint32_t));

            uint32_t keyword_idx = 0;
            for (size_t idx = 0; idx < parameters->keywords.size; ++idx) {
                const pm_node_t *keyword = parameters->keywords.nodes[idx];

                if (PM_NODE_TYPE_P(keyword, PM_REQUIRED_KEYWORD_PARAMETER_NODE)) {
                    signature->required_keyword_names[keyword_idx] = ((const pm_required_keyword_parameter_node_t *) keyword)->name;
                    signature->required_keyword_ids[keyword_idx++] = graph->value_id++;
                }
            }
        }

        if (noptional_keyword_ids) {
            PrismGraph *graph = builder->unit->graphs + graph_id;
            signature->optional_keyword_names = pm_arena_alloc(builder->arena, sizeof(pm_constant_id_t) * noptional_keyword_ids, PRISM_ALIGNOF(pm_constant_id_t));
            signature->optional_keyword_ids = pm_arena_alloc(builder->arena, sizeof(uint32_t) * noptional_keyword_ids, PRISM_ALIGNOF(uint32_t));
            signature->optional_keyword_specified_ids = pm_arena_alloc(builder->arena, sizeof(uint32_t) * noptional_keyword_ids, PRISM_ALIGNOF(uint32_t));

            uint32_t keyword_idx = 0;
            for (size_t idx = 0; idx < parameters->keywords.size; ++idx) {
                const pm_node_t *keyword = parameters->keywords.nodes[idx];
                if (PM_NODE_TYPE_P(keyword, PM_OPTIONAL_KEYWORD_PARAMETER_NODE)) {
                    signature->optional_keyword_names[keyword_idx] = ((const pm_optional_keyword_parameter_node_t *) keyword)->name;
                    signature->optional_keyword_ids[keyword_idx] = graph->value_id++;
                    signature->optional_keyword_specified_ids[keyword_idx++] = graph->value_id++;
                }
            }
        }
    }

    if (forwarding || (parameters && parameters->keyword_rest && PM_NODE_TYPE_P(parameters->keyword_rest, PM_KEYWORD_REST_PARAMETER_NODE))) {
        signature->keyword_rest_id = builder->unit->graphs[graph_id].value_id++;
    }

    if (forwarding || (parameters && parameters->block && PM_NODE_TYPE_P(parameters->block, PM_BLOCK_PARAMETER_NODE))) {
        signature->block_id = builder->unit->graphs[graph_id].value_id++;
    }
}

static uint32_t
make_region(PrismBuilder *builder, PrismRegionKind kind, uint32_t parent_id, uint32_t entry_block_id, uint32_t handler_block_id) {
    PrismGraph *graph = PrismBuilder_graph(builder);
    if (graph->nregions == graph->regions_capa) {
        uint32_t next_capa = graph->regions_capa ? graph->regions_capa * 2 : 4;
        graph->regions = pm_arena_realloc(builder->arena, graph->regions, sizeof(PrismRegion) * next_capa, sizeof(PrismRegion) * graph->regions_capa, PRISM_ALIGNOF(PrismRegion));
        graph->regions_capa = next_capa;
    }

    uint32_t region_id = graph->nregions++;
    graph->regions[region_id] = (PrismRegion) {
        .kind = kind,
        .parent_id = parent_id,
        .entry_block_id = entry_block_id,
        .handler_block_id = handler_block_id
    };
    return region_id;
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
    graph->blocks[block_id] = (PrismBlock) { .insns = NULL, .params = params, .ninsns = 0, .nparams = nparams, .insns_capa = 0, .region_id = builder->state.region_id };
    return block_id;
}

static uint32_t
make_entry_block(PrismBuilder *builder, const PrismSignature *signature) {
    uint32_t block_id = make_block(builder, 0);

    if (signature) {
        PrismBlock *block = PrismBuilder_graph(builder)->blocks + block_id;

        block->nparams = (
            signature->nrequired_ids +
            2 * signature->noptional_ids +
            (signature->rest_id != UINT32_MAX ? 1 : 0) +
            signature->npost_ids +
            signature->nrequired_keyword_ids +
            2 * signature->noptional_keyword_ids +
            (signature->keyword_rest_id != UINT32_MAX ? 1 : 0) +
            (signature->block_id != UINT32_MAX ? 1 : 0)
        );

        if (block->nparams) {
            block->params = pm_arena_alloc(builder->arena, sizeof(uint32_t) * block->nparams, PRISM_ALIGNOF(uint32_t));

            if (signature->nrequired_ids) {
                memcpy(block->params, signature->required_ids, sizeof(uint32_t) * signature->nrequired_ids);
            }

            uint32_t idx = signature->nrequired_ids;

            for (uint32_t optional_idx = 0; optional_idx < signature->noptional_ids; ++optional_idx) {
                block->params[idx++] = signature->optional_ids[optional_idx];
                block->params[idx++] = signature->optional_specified_ids[optional_idx];
            }

            if (signature->rest_id != UINT32_MAX) {
                block->params[idx++] = signature->rest_id;
            }

            if (signature->npost_ids) {
                memcpy(block->params + idx, signature->post_ids, sizeof(uint32_t) * signature->npost_ids);
                idx += signature->npost_ids;
            }

            if (signature->nrequired_keyword_ids) {
                memcpy(block->params + idx, signature->required_keyword_ids, sizeof(uint32_t) * signature->nrequired_keyword_ids);
                idx += signature->nrequired_keyword_ids;
            }

            for (uint32_t keyword_idx = 0; keyword_idx < signature->noptional_keyword_ids; ++keyword_idx) {
                block->params[idx++] = signature->optional_keyword_ids[keyword_idx];
                block->params[idx++] = signature->optional_keyword_specified_ids[keyword_idx];
            }

            if (signature->keyword_rest_id != UINT32_MAX) {
                block->params[idx++] = signature->keyword_rest_id;
            }

            if (signature->block_id != UINT32_MAX) {
                block->params[idx] = signature->block_id;
            }
        }
    }

    return block_id;
}

static uint32_t
compile_parameters_local(PrismBuilder *builder, pm_constant_id_t name_id, uint32_t *local_index) {
    uint32_t local_id = make_local(builder, name_id);
    PrismBuilder_graph(builder)->local_ids[(*local_index)++] = local_id;
    return local_id;
}

static uint32_t
layout_parameters_local(PrismBuilder *builder, const pm_node_t *node, pm_constant_id_t name_id, pm_constant_id_t anonymous_name_id, uint32_t *local_index) {
    uint32_t local_id = compile_parameters_local(builder, name_id ? name_id : anonymous_name_id, local_index);

    if (name_id && !PM_NODE_FLAG_P(node, PM_PARAMETER_FLAGS_REPEATED_PARAMETER)) {
        builder->bindings[name_id] = local_id;
    }

    return local_id;
}

static uint32_t
layout_parameters_locals(PrismBuilder *builder, const pm_parameters_node_t *parameters, const PrismSignature *signature) {
    uint32_t local_index = 0;

    bool forwarding = parameters->keyword_rest && PM_NODE_TYPE_P(parameters->keyword_rest, PM_FORWARDING_PARAMETER_NODE);

    for (size_t idx = 0; idx < parameters->requireds.size; ++idx) {
        const pm_node_t *required = parameters->requireds.nodes[idx];
        pm_constant_id_t name_id = PM_NODE_TYPE_P(required, PM_REQUIRED_PARAMETER_NODE) ? ((const pm_required_parameter_node_t *) required)->name : PM_CONSTANT_ID_UNSET;
        layout_parameters_local(builder, required, name_id, PM_CONSTANT_ID_DESTRUCTURED, &local_index);
    }

    for (size_t idx = 0; idx < parameters->optionals.size; ++idx) {
        const pm_optional_parameter_node_t *optional = (const pm_optional_parameter_node_t *) parameters->optionals.nodes[idx];
        layout_parameters_local(builder, PM_NODE_UPCAST(optional), optional->name, PM_CONSTANT_ID_UNSET, &local_index);
    }

    if (signature->rest_id != UINT32_MAX) {
        const pm_rest_parameter_node_t *rest = (const pm_rest_parameter_node_t *) parameters->rest;
        uint32_t local_id = forwarding ? compile_parameters_local(builder, PM_CONSTANT_ID_REST, &local_index) : layout_parameters_local(builder, PM_NODE_UPCAST(rest), rest->name, PM_CONSTANT_ID_REST, &local_index);
        if (forwarding || !rest->name) builder->state.rest_local_id = local_id;
    }

    for (size_t idx = 0; idx < parameters->posts.size; ++idx) {
        const pm_node_t *post = parameters->posts.nodes[idx];
        pm_constant_id_t name_id = PM_NODE_TYPE_P(post, PM_REQUIRED_PARAMETER_NODE) ? ((const pm_required_parameter_node_t *) post)->name : PM_CONSTANT_ID_UNSET;
        layout_parameters_local(builder, post, name_id, PM_CONSTANT_ID_DESTRUCTURED, &local_index);
    }

    for (size_t idx = 0; idx < parameters->keywords.size; ++idx) {
        const pm_node_t *keyword = parameters->keywords.nodes[idx];
        if (PM_NODE_TYPE_P(keyword, PM_REQUIRED_KEYWORD_PARAMETER_NODE)) {
            const pm_required_keyword_parameter_node_t *required = (const pm_required_keyword_parameter_node_t *) keyword;
            layout_parameters_local(builder, keyword, required->name, PM_CONSTANT_ID_UNSET, &local_index);
        }
    }

    for (size_t idx = 0; idx < parameters->keywords.size; ++idx) {
        const pm_node_t *keyword = parameters->keywords.nodes[idx];
        if (PM_NODE_TYPE_P(keyword, PM_OPTIONAL_KEYWORD_PARAMETER_NODE)) {
            const pm_optional_keyword_parameter_node_t *optional = (const pm_optional_keyword_parameter_node_t *) keyword;
            layout_parameters_local(builder, keyword, optional->name, PM_CONSTANT_ID_UNSET, &local_index);
        }
    }

    if (signature->keyword_rest_id != UINT32_MAX) {
        const pm_keyword_rest_parameter_node_t *rest = (const pm_keyword_rest_parameter_node_t *) parameters->keyword_rest;

        uint32_t local_id;
        if (forwarding) {
            local_id = compile_parameters_local(builder, PM_CONSTANT_ID_KEYWORD_REST, &local_index);
        } else {
            local_id = layout_parameters_local(builder, PM_NODE_UPCAST(rest), rest->name, PM_CONSTANT_ID_KEYWORD_REST, &local_index);
        }

        if (forwarding || !rest->name) builder->state.keyword_rest_local_id = local_id;
    }

    if (signature->block_id != UINT32_MAX) {
        const pm_block_parameter_node_t *block = (const pm_block_parameter_node_t *) parameters->block;

        uint32_t local_id;
        if (forwarding) {
            local_id = compile_parameters_local(builder, PM_CONSTANT_ID_BLOCK, &local_index);
        } else {
            local_id = layout_parameters_local(builder, PM_NODE_UPCAST(block), block->name, PM_CONSTANT_ID_BLOCK, &local_index);
        }

        if (forwarding || !block->name) builder->state.block_local_id = local_id;
    }

    return local_index;
}

static PrismBuilderState
push_scope(PrismBuilder *builder, uint32_t graph_id, const PrismSignature *signature, const pm_parameters_node_t *parameters, const pm_constant_id_list_t *locals) {
    PrismBuilderState state = builder->state;
    bool captures = locals == NULL || builder->unit->graphs[graph_id].kind == kPrismGraphBlock || builder->unit->graphs[graph_id].kind == kPrismGraphLambda;

    builder->state = (PrismBuilderState) {
        .graph_id = graph_id,
        .retry_block_id = UINT32_MAX,
        .break_block_id = UINT32_MAX,
        .next_block_id = UINT32_MAX,
        .redo_block_id = UINT32_MAX,
        .it_local_id = locals == NULL ? state.it_local_id : UINT32_MAX,
        .rest_local_id = captures ? state.rest_local_id : UINT32_MAX,
        .keyword_rest_local_id = captures ? state.keyword_rest_local_id : UINT32_MAX,
        .block_local_id = captures ? state.block_local_id : UINT32_MAX,
        .lineno = builder->parser->start_line - 1,
        .locals = locals
    };

    builder->state.region_id = make_region(builder, kPrismRegionDefault, UINT32_MAX, UINT32_MAX, UINT32_MAX);
    builder->state.block_id = make_entry_block(builder, signature);
    PrismBuilder_graph(builder)->regions[builder->state.region_id].entry_block_id = builder->state.block_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    if (signature) graph->signature = *signature;

    if (locals == NULL) {
        uint32_t scope_id = builder->unit->graphs[state.graph_id].scope_id;
        builder->unit->graphs[graph_id].scope_id = scope_id;
    }

    if (locals) {
        if (locals->size) {
            uint32_t *shadowed = pm_arena_alloc(&builder->scratch, sizeof(uint32_t) * locals->size, PRISM_ALIGNOF(uint32_t));
            for (size_t idx = 0; idx < locals->size; ++idx) {
                shadowed[idx] = builder->bindings[locals->ids[idx]];
            }

            builder->state.shadowed = shadowed;
        }

        uint32_t local_index = parameters ? layout_parameters_locals(builder, parameters, signature) : 0;
        for (size_t idx = 0; idx < locals->size; ++idx) {
            pm_constant_id_t name_id = locals->ids[idx];
            uint32_t bound_id = builder->bindings[name_id];

            if (
                bound_id >= builder->unit->nlocals ||
                builder->unit->locals[bound_id].graph_id != graph_id ||
                builder->unit->locals[bound_id].name_id != name_id
            ) {
                uint32_t local_id = make_local(builder, name_id);
                graph->local_ids[local_index++] = local_id;
                builder->bindings[name_id] = local_id;
            }
        }
    }

    return state;
}

static void
pop_scope(PrismBuilder *builder, PrismBuilderState state) {
    const pm_constant_id_list_t *locals = builder->state.locals;

    if (locals) {
        for (size_t idx = 0; idx < locals->size; ++idx) {
            builder->bindings[locals->ids[idx]] = builder->state.shadowed[idx];
        }
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

    builder->unit->objects[object_id].as.string.constant_id = constant_id;
    builder->unit->objects[object_id].as.string.flags = 0;
    builder->unit->objects[object_id].as.string.unescaped = name;
    return object_id;
}

static uint32_t
make_object_string(PrismBuilder *builder, const char *value, size_t length) {
    void *allocation = pm_arena_alloc(builder->arena, sizeof(pm_string_t) + length, PRISM_ALIGNOF(pm_string_t));

    pm_string_t *unescaped = (pm_string_t *) allocation;
    uint8_t *source = ((uint8_t *) allocation) + sizeof(pm_string_t);

    *unescaped = (pm_string_t) { .length = length, .source = source };
    memcpy(source, value, length);

    uint32_t object_id = make_object(builder, kPrismObjectString);
    PrismObject *object = builder->unit->objects + object_id;

    object->as.string.flags = 0;
    object->as.string.unescaped = unescaped;

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

static PrismInsn *
emit_insn(PrismBuilder *builder, PrismInsnKind kind, uint32_t node_id, uint32_t opnds_len, const uint32_t *opnd_ids) {
    PrismInsn *insn = make_insn(builder, kind, node_id, opnds_len);
    if (opnds_len) {
        memcpy(PrismBuilder_graph(builder)->opnds + insn->opnds_off, opnd_ids, opnds_len * sizeof(uint32_t));
    }
    return insn;
}

/******************************************************************************/

static void
emit_alias_gvar(PrismBuilder *builder, uint32_t node_id, uint32_t new_name_id, uint32_t old_name_id) {
    emit_insn(builder, kPrismInsnAliasGVar, node_id, 2, (uint32_t[]) { new_name_id, old_name_id });
}

static void
emit_alias_method(PrismBuilder *builder, uint32_t node_id, uint32_t new_name_id, uint32_t old_name_id) {
    emit_insn(builder, kPrismInsnAliasMethod, node_id, 2, (uint32_t[]) { new_name_id, old_name_id });
}

static uint32_t
emit_any_truthy(PrismBuilder *builder, uint32_t node_id, uint32_t array_id) {
    uint32_t value_id = make_value(builder);
    emit_insn(builder, kPrismInsnAnyTruthy, node_id, 2, (uint32_t[]) { value_id, array_id });
    return value_id;
}

static void
emit_branch(PrismBuilder *builder, uint32_t node_id, uint32_t block_id, uint32_t opnds_len, uint32_t *opnd_ids) {
    PrismInsn *insn = emit_insn(builder, kPrismInsnBranch, node_id, opnds_len, opnd_ids);
    insn->as.branch.block_id = block_id;
}

static void
emit_branchif(PrismBuilder *builder, uint32_t node_id, uint32_t predicate_id, uint32_t then_block_id, uint32_t then_opnds_len, uint32_t *then_opnd_ids, uint32_t else_block_id, uint32_t else_opnds_len, uint32_t *else_opnd_ids) {
    PrismInsn *insn = make_insn(builder, kPrismInsnBranchIf, node_id, 1 + then_opnds_len + else_opnds_len);
    insn->as.branchif.then_block_id = then_block_id;
    insn->as.branchif.else_block_id = else_block_id;
    insn->as.branchif.then_opnds_len = then_opnds_len;

    uint32_t *cursor = PrismBuilder_graph(builder)->opnds + insn->opnds_off;
    *cursor++ = predicate_id;
    if (then_opnds_len) {
        memcpy(cursor, then_opnd_ids, then_opnds_len * sizeof(uint32_t));
        cursor += then_opnds_len;
    }
    if (else_opnds_len) {
        memcpy(cursor, else_opnd_ids, else_opnds_len * sizeof(uint32_t));
    }
}

static void
emit_break(PrismBuilder *builder, uint32_t node_id, uint32_t value_id) {
    emit_insn(builder, kPrismInsnBreak, node_id, 1, &value_id);
}

static uint32_t
emit_call(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t receiver_id, size_t nargument_ids, uint32_t *argument_ids, uint32_t block_id, bool splat, bool keywords, pm_node_flags_t flags, bool block_argument) {
    PrismInsn *insn = make_insn(builder, kPrismInsnCall, node_id, 2 + (uint32_t) nargument_ids + (block_id != UINT32_MAX));
    insn->as.call.name_id = name_id;
    insn->as.call.splat = splat;
    insn->as.call.keywords = keywords;
    insn->as.call.ignore_visibility = (flags & PM_CALL_NODE_FLAGS_IGNORE_VISIBILITY) != 0;
    insn->as.call.variable_call = (flags & PM_CALL_NODE_FLAGS_VARIABLE_CALL) != 0;
    insn->as.call.block = block_id != UINT32_MAX;
    insn->as.call.block_argument = block_argument;

    uint32_t value_id = make_value(builder);
    uint32_t *cursor = PrismBuilder_graph(builder)->opnds + insn->opnds_off;
    *cursor++ = value_id;
    *cursor++ = receiver_id;
    if (nargument_ids) {
        memcpy(cursor, argument_ids, nargument_ids * sizeof(uint32_t));
        cursor += nargument_ids;
    }
    if (block_id != UINT32_MAX) *cursor = block_id;

    return value_id;
}

static uint32_t
emit_call_arguments(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t receiver_id, const PrismArguments *arguments, pm_node_flags_t flags) {
    return emit_call(builder, node_id, name_id, receiver_id, arguments->size, arguments->ids, arguments->block_id, arguments->splat, arguments->keywords, flags, arguments->block_argument);
}

static uint32_t
emit_call_super(PrismBuilder *builder, uint32_t node_id, const PrismArguments *arguments) {
    PrismInsn *insn = make_insn(builder, kPrismInsnCallSuper, node_id, (uint32_t) arguments->size + 2);
    insn->as.call.splat = arguments->splat;
    insn->as.call.keywords = arguments->keywords;
    insn->as.call.ignore_visibility = true;
    insn->as.call.block = true;
    insn->as.call.block_argument = arguments->block_argument;

    uint32_t value_id = make_value(builder);
    uint32_t *cursor = PrismBuilder_graph(builder)->opnds + insn->opnds_off;
    *cursor++ = value_id;
    if (arguments->size) {
        memcpy(cursor, arguments->ids, arguments->size * sizeof(uint32_t));
        cursor += arguments->size;
    }
    *cursor = arguments->block_id;

    return value_id;
}

static uint32_t
emit_coerce_array_to_a(PrismBuilder *builder, uint32_t node_id, uint32_t value_id) {
    uint32_t array_id = make_value(builder);
    emit_insn(builder, kPrismInsnCoerceArrayToA, node_id, 2, (uint32_t[]) { array_id, value_id });
    return array_id;
}

static uint32_t
emit_coerce_array_to_ary(PrismBuilder *builder, uint32_t node_id, uint32_t value_id) {
    uint32_t array_id = make_value(builder);
    emit_insn(builder, kPrismInsnCoerceArrayToAry, node_id, 2, (uint32_t[]) { array_id, value_id });
    return array_id;
}

static uint32_t
emit_coerce_hash(PrismBuilder *builder, uint32_t node_id, uint32_t value_id) {
    uint32_t hash_id = make_value(builder);
    emit_insn(builder, kPrismInsnCoerceHash, node_id, 2, (uint32_t[]) { hash_id, value_id });
    return hash_id;
}

static uint32_t
emit_coerce_string(PrismBuilder *builder, uint32_t node_id, uint32_t value_id) {
    uint32_t string_id = make_value(builder);
    emit_insn(builder, kPrismInsnCoerceString, node_id, 2, (uint32_t[]) { string_id, value_id });
    return string_id;
}

static uint32_t
emit_concat_array(PrismBuilder *builder, uint32_t node_id, uint32_t left_id, uint32_t right_id) {
    uint32_t value_id = make_value(builder);
    emit_insn(builder, kPrismInsnConcatArray, node_id, 3, (uint32_t[]) { value_id, left_id, right_id });
    return value_id;
}

static uint32_t
emit_deconstruct_array(PrismBuilder *builder, uint32_t node_id, uint32_t value_id) {
    uint32_t result_id = make_value(builder);
    emit_insn(builder, kPrismInsnDeconstructArray, node_id, 2, (uint32_t[]) { result_id, value_id });
    return result_id;
}

static uint32_t
emit_deconstruct_hash(PrismBuilder *builder, uint32_t node_id, uint32_t value_id, uint32_t keys_id) {
    uint32_t result_id = make_value(builder);
    emit_insn(builder, kPrismInsnDeconstructHash, node_id, 3, (uint32_t[]) { result_id, value_id, keys_id });
    return result_id;
}

static uint32_t
emit_define_class_abs(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t graph_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnDefineClassAbs, node_id, 1, &value_id);
    insn->as.define.name_id = name_id;
    insn->as.define.graph_id = graph_id;
    return value_id;
}

static uint32_t
emit_define_class_abs_super(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t superclass_id, uint32_t graph_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnDefineClassAbsSuper, node_id, 2, (uint32_t[]) { value_id, superclass_id });
    insn->as.define.name_id = name_id;
    insn->as.define.graph_id = graph_id;
    return value_id;
}

static uint32_t
emit_define_class_nest_rel(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t graph_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnDefineClassNestRel, node_id, 1, &value_id);
    insn->as.define.name_id = name_id;
    insn->as.define.graph_id = graph_id;
    return value_id;
}

static uint32_t
emit_define_class_nest_rel_super(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t superclass_id, uint32_t graph_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnDefineClassNestRelSuper, node_id, 2, (uint32_t[]) { value_id, superclass_id });
    insn->as.define.name_id = name_id;
    insn->as.define.graph_id = graph_id;
    return value_id;
}

static uint32_t
emit_define_class_recv_rel(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t receiver_id, uint32_t graph_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnDefineClassRecvRel, node_id, 2, (uint32_t[]) { value_id, receiver_id });
    insn->as.define.name_id = name_id;
    insn->as.define.graph_id = graph_id;
    return value_id;
}

static uint32_t
emit_define_class_recv_rel_super(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t receiver_id, uint32_t superclass_id, uint32_t graph_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnDefineClassRecvRelSuper, node_id, 3, (uint32_t[]) { value_id, receiver_id, superclass_id });
    insn->as.define.name_id = name_id;
    insn->as.define.graph_id = graph_id;
    return value_id;
}

static uint32_t
emit_define_module_abs(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t graph_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnDefineModuleAbs, node_id, 1, &value_id);
    insn->as.define.name_id = name_id;
    insn->as.define.graph_id = graph_id;
    return value_id;
}

static uint32_t
emit_define_module_nest_rel(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t graph_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnDefineModuleNestRel, node_id, 1, &value_id);
    insn->as.define.name_id = name_id;
    insn->as.define.graph_id = graph_id;
    return value_id;
}

static uint32_t
emit_define_module_recv_rel(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t receiver_id, uint32_t graph_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnDefineModuleRecvRel, node_id, 2, (uint32_t[]) { value_id, receiver_id });
    insn->as.define.name_id = name_id;
    insn->as.define.graph_id = graph_id;
    return value_id;
}

static void
emit_define_method(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t graph_id) {
    PrismInsn *insn = emit_insn(builder, kPrismInsnDefineMethod, node_id, 0, NULL);
    insn->as.define.name_id = name_id;
    insn->as.define.graph_id = graph_id;
}

static uint32_t
emit_define_singleton_class(PrismBuilder *builder, uint32_t node_id, uint32_t receiver_id, uint32_t graph_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnDefineSingletonClass, node_id, 2, (uint32_t[]) { value_id, receiver_id });
    insn->as.define_singleton_class.graph_id = graph_id;
    return value_id;
}

static void
emit_define_singleton_method(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t receiver_id, uint32_t graph_id) {
    PrismInsn *insn = emit_insn(builder, kPrismInsnDefineSingletonMethod, node_id, 1, &receiver_id);
    insn->as.define.name_id = name_id;
    insn->as.define.graph_id = graph_id;
}

static uint32_t
emit_defined_const_abs(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnDefinedConstAbs, node_id, 1, &value_id);
    insn->as.name.name_id = name_id;
    return value_id;
}

static uint32_t
emit_defined_const_nest_rel(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnDefinedConstNestRel, node_id, 1, &value_id);
    insn->as.name.name_id = name_id;
    return value_id;
}

static uint32_t
emit_defined_const_recv_rel(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t parent_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnDefinedConstRecvRel, node_id, 2, (uint32_t[]) { value_id, parent_id });
    insn->as.name.name_id = name_id;
    return value_id;
}

static uint32_t
emit_defined_cvar(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnDefinedCVar, node_id, 1, &value_id);
    insn->as.name.name_id = name_id;
    return value_id;
}

static uint32_t
emit_defined_explicit_method(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t receiver_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnDefinedExplicitMethod, node_id, 2, (uint32_t[]) { value_id, receiver_id });
    insn->as.name.name_id = name_id;
    return value_id;
}

static uint32_t
emit_defined_gvar(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnDefinedGVar, node_id, 1, &value_id);
    insn->as.name.name_id = name_id;
    return value_id;
}

static uint32_t
emit_defined_implicit_method(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t receiver_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnDefinedImplicitMethod, node_id, 2, (uint32_t[]) { value_id, receiver_id });
    insn->as.name.name_id = name_id;
    return value_id;
}

static uint32_t
emit_defined_ivar(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnDefinedIVar, node_id, 1, &value_id);
    insn->as.name.name_id = name_id;
    return value_id;
}

static uint32_t
emit_defined_super(PrismBuilder *builder, uint32_t node_id) {
    uint32_t value_id = make_value(builder);
    emit_insn(builder, kPrismInsnDefinedSuper, node_id, 1, &value_id);
    return value_id;
}

static void
emit_ensure_return(PrismBuilder *builder, uint32_t node_id, uint32_t region_id) {
    PrismInsn *insn = emit_insn(builder, kPrismInsnEnsureReturn, node_id, 0, NULL);
    insn->as.ensure_return.region_id = region_id;
}

static uint32_t
emit_ensure_shareable(PrismBuilder *builder, uint32_t node_id, uint32_t value_id, uint32_t name_id) {
    uint32_t result_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnEnsureShareable, node_id, 2, (uint32_t[]) { result_id, value_id });
    insn->as.object.object_id = name_id;
    return result_id;
}

static uint32_t *
emit_expand_array(PrismBuilder *builder, uint32_t node_id, uint32_t value_id, uint32_t lefts, uint32_t rights, bool rest) {
    uint32_t nvalues = lefts + rights + (rest ? 1 : 0);
    uint32_t *value_ids = nvalues ? pm_arena_alloc(&builder->scratch, sizeof(uint32_t) * nvalues, PRISM_ALIGNOF(uint32_t)) : NULL;

    PrismInsn *insn = make_insn(builder, kPrismInsnExpandArray, node_id, nvalues + 1);
    insn->as.expand_array.lefts = lefts;
    insn->as.expand_array.rights = rights;
    insn->as.expand_array.rest = rest;

    uint32_t *cursor = PrismBuilder_graph(builder)->opnds + insn->opnds_off;
    *cursor++ = value_id;

    for (uint32_t idx = 0; idx < nvalues; ++idx) {
        value_ids[idx] = make_value(builder);
        *cursor++ = value_ids[idx];
    }

    return value_ids;
}

static uint32_t
emit_load_block(PrismBuilder *builder, uint32_t node_id) {
    uint32_t value_id = make_value(builder);
    emit_insn(builder, kPrismInsnLoadBlock, node_id, 1, &value_id);
    return value_id;
}

static uint32_t
emit_load_const_abs(PrismBuilder *builder, uint32_t node_id, PrismConstantPath constant_path) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnLoadConstAbs, node_id, 1, &value_id);
    insn->as.constant_path = constant_path;
    return value_id;
}

static uint32_t
emit_load_const_nest_rel(PrismBuilder *builder, uint32_t node_id, PrismConstantPath constant_path) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnLoadConstNestRel, node_id, 1, &value_id);
    insn->as.constant_path = constant_path;
    return value_id;
}

static uint32_t
emit_load_const_recv_rel(PrismBuilder *builder, uint32_t node_id, uint32_t receiver_id, PrismConstantPath constant_path) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnLoadConstRecvRel, node_id, 2, (uint32_t[]) { value_id, receiver_id });
    insn->as.constant_path = constant_path;
    return value_id;
}

static uint32_t
emit_load_name(PrismBuilder *builder, uint32_t node_id, PrismInsnKind kind, pm_constant_id_t name_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kind, node_id, 1, &value_id);
    insn->as.name.name_id = name_id;
    return value_id;
}

static uint32_t
emit_load_cvar(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id) {
    return emit_load_name(builder, node_id, kPrismInsnLoadCVar, name_id);
}

static uint32_t
emit_load_flip_flop(PrismBuilder *builder, uint32_t node_id, uint32_t index) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnLoadFlipFlop, node_id, 1, &value_id);
    insn->as.flip_flop.index = index;
    return value_id;
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
    uint32_t value_id = make_value(builder);
    emit_insn(builder, kPrismInsnLoadLastMatch, node_id, 1, &value_id);
    return value_id;
}

static uint32_t
emit_load_last_match_group(PrismBuilder *builder, uint32_t node_id, uint32_t last_match_id, uint32_t number) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnLoadLastMatchGroup, node_id, 2, (uint32_t[]) { value_id, last_match_id });
    insn->as.last_match_group.number = number;
    return value_id;
}

static uint32_t
emit_load_last_match_match(PrismBuilder *builder, uint32_t node_id, uint32_t last_match_id) {
    uint32_t value_id = make_value(builder);
    emit_insn(builder, kPrismInsnLoadLastMatchMatch, node_id, 2, (uint32_t[]) { value_id, last_match_id });
    return value_id;
}

static uint32_t
emit_load_last_match_named_group(PrismBuilder *builder, uint32_t node_id, uint32_t last_match_id, pm_constant_id_t name_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnLoadLastMatchNamedGroup, node_id, 2, (uint32_t[]) { value_id, last_match_id });
    insn->as.name.name_id = name_id;
    return value_id;
}

static uint32_t
emit_load_last_match_paren(PrismBuilder *builder, uint32_t node_id, uint32_t last_match_id) {
    uint32_t value_id = make_value(builder);
    emit_insn(builder, kPrismInsnLoadLastMatchParen, node_id, 2, (uint32_t[]) { value_id, last_match_id });
    return value_id;
}

static uint32_t
emit_load_last_match_post(PrismBuilder *builder, uint32_t node_id, uint32_t last_match_id) {
    uint32_t value_id = make_value(builder);
    emit_insn(builder, kPrismInsnLoadLastMatchPost, node_id, 2, (uint32_t[]) { value_id, last_match_id });
    return value_id;
}

static uint32_t
emit_load_last_match_pre(PrismBuilder *builder, uint32_t node_id, uint32_t last_match_id) {
    uint32_t value_id = make_value(builder);
    emit_insn(builder, kPrismInsnLoadLastMatchPre, node_id, 2, (uint32_t[]) { value_id, last_match_id });
    return value_id;
}

static uint32_t
emit_load_lvar(PrismBuilder *builder, uint32_t node_id, uint32_t local_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnLoadLVar, node_id, 1, &value_id);
    insn->as.lvar.local_id = local_id;
    return value_id;
}

static uint32_t
emit_nil_p(PrismBuilder *builder, uint32_t node_id, uint32_t value_id) {
    uint32_t predicate_id = make_value(builder);
    emit_insn(builder, kPrismInsnNilP, node_id, 2, (uint32_t[]) { predicate_id, value_id });
    return predicate_id;
}

static uint32_t
emit_load_object(PrismBuilder *builder, uint32_t node_id, uint32_t object_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnLoadObject, node_id, 1, &value_id);
    insn->as.object.object_id = object_id;
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
emit_load_integer(PrismBuilder *builder, uint32_t node_id, uint32_t number) {
    pm_integer_t *integer = pm_arena_alloc(builder->arena, sizeof(pm_integer_t), PRISM_ALIGNOF(pm_integer_t));
    *integer = pm_integer_uint64(number);

    uint32_t object_id = make_object(builder, kPrismObjectInteger);
    builder->unit->objects[object_id].as.integer.value = integer;
    return emit_load_object(builder, node_id, object_id);
}

static uint32_t
emit_load_self(PrismBuilder *builder, uint32_t node_id) {
    uint32_t value_id = make_value(builder);
    emit_insn(builder, kPrismInsnLoadSelf, node_id, 1, &value_id);
    return value_id;
}

static uint32_t
emit_make_shareable(PrismBuilder *builder, uint32_t node_id, uint32_t value_id, bool copy) {
    uint32_t result_id = make_value(builder);
    emit_insn(builder, copy ? kPrismInsnMakeShareableCopy : kPrismInsnMakeShareable, node_id, 2, (uint32_t[]) { result_id, value_id });
    return result_id;
}

static uint32_t
emit_match(PrismBuilder *builder, uint32_t node_id, uint32_t value_id, uint32_t pattern_id) {
    uint32_t result_id = make_value(builder);
    emit_insn(builder, kPrismInsnMatch, node_id, 3, (uint32_t[]) { result_id, value_id, pattern_id });
    return result_id;
}

static uint32_t
emit_match_array(PrismBuilder *builder, uint32_t node_id, uint32_t value_id, uint32_t array_id) {
    uint32_t result_id = make_value(builder);
    emit_insn(builder, kPrismInsnMatchArray, node_id, 3, (uint32_t[]) { result_id, value_id, array_id });
    return result_id;
}

static uint32_t
emit_merge_hash(PrismBuilder *builder, uint32_t node_id, uint32_t left_id, uint32_t right_id) {
    uint32_t value_id = make_value(builder);
    emit_insn(builder, kPrismInsnMergeHash, node_id, 3, (uint32_t[]) { value_id, left_id, right_id });
    return value_id;
}

static uint32_t
emit_new_array(PrismBuilder *builder, uint32_t node_id, uint32_t nelement_ids, uint32_t *element_ids) {
    PrismInsn *insn = make_insn(builder, kPrismInsnNewArray, node_id, 1 + nelement_ids);

    uint32_t value_id = make_value(builder);
    uint32_t *cursor = PrismBuilder_graph(builder)->opnds + insn->opnds_off;
    *cursor++ = value_id;
    if (nelement_ids) memcpy(cursor, element_ids, nelement_ids * sizeof(uint32_t));

    return value_id;
}

static uint32_t
emit_new_block(PrismBuilder *builder, uint32_t node_id, uint32_t graph_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnNewBlock, node_id, 1, &value_id);
    insn->as.new_block.graph_id = graph_id;
    return value_id;
}

static uint32_t
emit_new_array_static(PrismBuilder *builder, uint32_t node_id, uint32_t object_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnNewArrayStatic, node_id, 1, &value_id);
    insn->as.object.object_id = object_id;
    return value_id;
}

static uint32_t
emit_new_hash(PrismBuilder *builder, uint32_t node_id, uint32_t nelement_ids, uint32_t *element_ids) {
    PrismInsn *insn = make_insn(builder, kPrismInsnNewHash, node_id, 1 + nelement_ids);

    uint32_t value_id = make_value(builder);
    uint32_t *cursor = PrismBuilder_graph(builder)->opnds + insn->opnds_off;
    *cursor++ = value_id;
    if (nelement_ids) memcpy(cursor, element_ids, nelement_ids * sizeof(uint32_t));

    return value_id;
}

static uint32_t
emit_new_hash_static(PrismBuilder *builder, uint32_t node_id, uint32_t object_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnNewHashStatic, node_id, 1, &value_id);
    insn->as.object.object_id = object_id;
    return value_id;
}

static uint32_t
emit_new_range(PrismBuilder *builder, bool exclusive, uint32_t node_id, uint32_t left_id, uint32_t right_id) {
    uint32_t value_id = make_value(builder);
    emit_insn(builder, exclusive ? kPrismInsnNewRangeExc : kPrismInsnNewRangeInc, node_id, 3, (uint32_t[]) { value_id, left_id, right_id });
    return value_id;
}

static uint32_t
emit_new_regexp(PrismBuilder *builder, uint32_t node_id, uint32_t nvalue_ids, uint32_t *value_ids, pm_node_flags_t flags) {
    PrismInsn *insn = make_insn(builder, kPrismInsnNewRegexp, node_id, 1 + nvalue_ids);
    insn->as.regexp.flags = flags;

    uint32_t value_id = make_value(builder);
    uint32_t *cursor = PrismBuilder_graph(builder)->opnds + insn->opnds_off;
    *cursor++ = value_id;
    if (nvalue_ids) memcpy(cursor, value_ids, nvalue_ids * sizeof(uint32_t));

    return value_id;
}

static uint32_t
emit_new_string(PrismBuilder *builder, uint32_t node_id, uint32_t nvalue_ids, uint32_t *value_ids) {
    PrismInsn *insn = make_insn(builder, kPrismInsnNewString, node_id, 1 + nvalue_ids);

    uint32_t value_id = make_value(builder);
    uint32_t *cursor = PrismBuilder_graph(builder)->opnds + insn->opnds_off;
    *cursor++ = value_id;
    if (nvalue_ids) memcpy(cursor, value_ids, nvalue_ids * sizeof(uint32_t));

    return value_id;
}

static uint32_t
emit_new_symbol(PrismBuilder *builder, uint32_t node_id, uint32_t nvalue_ids, uint32_t *value_ids) {
    PrismInsn *insn = make_insn(builder, kPrismInsnNewSymbol, node_id, 1 + nvalue_ids);

    uint32_t value_id = make_value(builder);
    uint32_t *cursor = PrismBuilder_graph(builder)->opnds + insn->opnds_off;
    *cursor++ = value_id;
    if (nvalue_ids) memcpy(cursor, value_ids, nvalue_ids * sizeof(uint32_t));

    return value_id;
}

static uint32_t
emit_once(PrismBuilder *builder, uint32_t node_id, uint32_t region_id) {
    uint32_t value_id = make_value(builder);
    PrismInsn *insn = emit_insn(builder, kPrismInsnOnce, node_id, 1, &value_id);
    insn->as.once.region_id = region_id;
    insn->as.once.site_id = builder->unit->nonce_sites++;
    return value_id;
}

static void
emit_once_return(PrismBuilder *builder, uint32_t node_id, uint32_t region_id, uint32_t value_id) {
    PrismInsn *insn = emit_insn(builder, kPrismInsnOnceReturn, node_id, 1, &value_id);
    insn->as.once.region_id = region_id;
}

static void
emit_raise_pattern_deconstruct(PrismBuilder *builder, uint32_t node_id, uint32_t root_id, uint32_t value_id) {
    emit_insn(builder, kPrismInsnRaisePatternDeconstruct, node_id, 2, (uint32_t[]) { root_id, value_id });
}

static void
emit_raise_pattern_deconstruct_keys(PrismBuilder *builder, uint32_t node_id, uint32_t root_id, uint32_t value_id) {
    emit_insn(builder, kPrismInsnRaisePatternDeconstructKeys, node_id, 2, (uint32_t[]) { root_id, value_id });
}

static void
emit_raise_pattern_empty(PrismBuilder *builder, uint32_t node_id, uint32_t root_id, uint32_t value_id) {
    emit_insn(builder, kPrismInsnRaisePatternEmpty, node_id, 2, (uint32_t[]) { root_id, value_id });
}

static void
emit_raise_pattern_find(PrismBuilder *builder, uint32_t node_id, uint32_t root_id, uint32_t array_id) {
    emit_insn(builder, kPrismInsnRaisePatternFind, node_id, 2, (uint32_t[]) { root_id, array_id });
}

static void
emit_raise_pattern_guard(PrismBuilder *builder, uint32_t node_id, uint32_t value_id) {
    emit_insn(builder, kPrismInsnRaisePatternGuard, node_id, 1, &value_id);
}

static void
emit_raise_pattern_key(PrismBuilder *builder, uint32_t node_id, uint32_t root_id, uint32_t value_id, uint32_t key_id) {
    emit_insn(builder, kPrismInsnRaisePatternKey, node_id, 3, (uint32_t[]) { root_id, value_id, key_id });
}

static void
emit_raise_pattern_length(PrismBuilder *builder, uint32_t node_id, uint32_t root_id, uint32_t array_id, uint32_t given_id, uint32_t expected_id) {
    emit_insn(builder, kPrismInsnRaisePatternLength, node_id, 4, (uint32_t[]) { root_id, array_id, given_id, expected_id });
}

static void
emit_raise_pattern_min_length(PrismBuilder *builder, uint32_t node_id, uint32_t root_id, uint32_t array_id, uint32_t given_id, uint32_t expected_id) {
    emit_insn(builder, kPrismInsnRaisePatternMinLength, node_id, 4, (uint32_t[]) { root_id, array_id, given_id, expected_id });
}

static void
emit_raise_pattern_mismatch(PrismBuilder *builder, uint32_t node_id, uint32_t root_id, uint32_t value_id, uint32_t pattern_id) {
    emit_insn(builder, kPrismInsnRaisePatternMismatch, node_id, 3, (uint32_t[]) { root_id, value_id, pattern_id });
}

static void
emit_raise_pattern_nomatch(PrismBuilder *builder, uint32_t node_id, uint32_t value_id) {
    emit_insn(builder, kPrismInsnRaisePatternNomatch, node_id, 1, &value_id);
}

static void
emit_raise_pattern_rest_empty(PrismBuilder *builder, uint32_t node_id, uint32_t root_id, uint32_t value_id) {
    emit_insn(builder, kPrismInsnRaisePatternRestEmpty, node_id, 2, (uint32_t[]) { root_id, value_id });
}

static void
emit_reraise(PrismBuilder *builder, uint32_t node_id) {
    emit_insn(builder, kPrismInsnReraise, node_id, 0, NULL);
}

static uint32_t
emit_rescue_match(PrismBuilder *builder, uint32_t node_id, uint32_t exception_id, uint32_t class_id) {
    uint32_t value_id = make_value(builder);
    emit_insn(builder, kPrismInsnRescueMatch, node_id, 3, (uint32_t[]) { value_id, exception_id, class_id });
    return value_id;
}

static uint32_t
emit_rescue_match_array(PrismBuilder *builder, uint32_t node_id, uint32_t exception_id, uint32_t class_id) {
    uint32_t value_id = make_value(builder);
    emit_insn(builder, kPrismInsnRescueMatchArray, node_id, 3, (uint32_t[]) { value_id, exception_id, class_id });
    return value_id;
}

static void
emit_return(PrismBuilder *builder, uint32_t node_id, uint32_t value_id) {
    emit_insn(builder, kPrismInsnReturn, node_id, 1, &value_id);
}

static uint32_t
emit_store_const_abs(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t value_id) {
    PrismInsn *insn = emit_insn(builder, kPrismInsnStoreConstAbs, node_id, 1, &value_id);
    insn->as.name.name_id = name_id;
    return value_id;
}

static uint32_t
emit_store_const_nest_rel(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t value_id) {
    PrismInsn *insn = emit_insn(builder, kPrismInsnStoreConstNestRel, node_id, 1, &value_id);
    insn->as.name.name_id = name_id;
    return value_id;
}

static uint32_t
emit_store_const_recv_rel(PrismBuilder *builder, uint32_t node_id, uint32_t receiver_id, pm_constant_id_t name_id, uint32_t value_id) {
    PrismInsn *insn = emit_insn(builder, kPrismInsnStoreConstRecvRel, node_id, 2, (uint32_t[]) { receiver_id, value_id });
    insn->as.name.name_id = name_id;
    return value_id;
}

static void
emit_store_name(PrismBuilder *builder, uint32_t node_id, PrismInsnKind kind, pm_constant_id_t name_id, uint32_t value_id) {
    PrismInsn *insn = emit_insn(builder, kind, node_id, 1, &value_id);
    insn->as.name.name_id = name_id;
}

static void
emit_store_cvar(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t value_id) {
    emit_store_name(builder, node_id, kPrismInsnStoreCVar, name_id, value_id);
}

static void
emit_store_flip_flop(PrismBuilder *builder, uint32_t node_id, uint32_t index, uint32_t value_id) {
    PrismInsn *insn = emit_insn(builder, kPrismInsnStoreFlipFlop, node_id, 1, &value_id);
    insn->as.flip_flop.index = index;
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
    PrismInsn *insn = emit_insn(builder, kPrismInsnStoreLVar, node_id, 1, &value_id);
    insn->as.lvar.local_id = local_id;
}

static void
emit_trace_b_call(PrismBuilder *builder, uint32_t node_id) {
    emit_insn(builder, kPrismInsnTraceBCall, node_id, 0, NULL);
}

static void
emit_trace_b_return(PrismBuilder *builder, uint32_t node_id, uint32_t value_id) {
    emit_insn(builder, kPrismInsnTraceBReturn, node_id, 1, &value_id);
}

static void
emit_trace_call(PrismBuilder *builder, uint32_t node_id) {
    emit_insn(builder, kPrismInsnTraceCall, node_id, 0, NULL);
}

static void
emit_trace_class(PrismBuilder *builder, uint32_t node_id) {
    emit_insn(builder, kPrismInsnTraceClass, node_id, 0, NULL);
}

static void
emit_trace_end(PrismBuilder *builder, uint32_t node_id) {
    emit_insn(builder, kPrismInsnTraceEnd, node_id, 0, NULL);
}

static void
emit_trace_line(PrismBuilder *builder, uint32_t node_id, int32_t lineno) {
    PrismInsn *insn = emit_insn(builder, kPrismInsnTraceLine, node_id, 0, NULL);
    insn->as.trace_line.lineno = lineno;
}

static void
emit_trace_rescue(PrismBuilder *builder, uint32_t node_id) {
    emit_insn(builder, kPrismInsnTraceRescue, node_id, 0, NULL);
}

static void
emit_trace_return(PrismBuilder *builder, uint32_t node_id, uint32_t value_id) {
    emit_insn(builder, kPrismInsnTraceReturn, node_id, 1, &value_id);
}

static void
emit_undef_method(PrismBuilder *builder, uint32_t node_id, uint32_t name_id) {
    emit_insn(builder, kPrismInsnUndefMethod, node_id, 1, &name_id);
}

/******************************************************************************/

typedef struct {
    uint32_t body_block_id;
    uint32_t handler_region_id;
    uint32_t handler_block_id;
} PrismRescueRegion;

/* Create a handler outside its protected region and enter the protected body. */
static PrismRescueRegion
make_rescue_region(PrismBuilder *builder, uint32_t node_id) {
    uint32_t parent_id = builder->state.region_id;
    uint32_t handler_region_id = make_region(builder, kPrismRegionDefault, parent_id, UINT32_MAX, UINT32_MAX);
    builder->state.region_id = handler_region_id;
    uint32_t handler_block_id = make_block(builder, 1);
    PrismBuilder_graph(builder)->regions[handler_region_id].entry_block_id = handler_block_id;

    uint32_t region_id = make_region(builder, kPrismRegionRescue, parent_id, UINT32_MAX, handler_block_id);
    builder->state.region_id = region_id;
    uint32_t body_block_id = make_block(builder, 0);
    PrismBuilder_graph(builder)->regions[region_id].entry_block_id = body_block_id;
    emit_branch(builder, node_id, body_block_id, 0, NULL);
    builder->state.block_id = body_block_id;

    return (PrismRescueRegion) { .body_block_id = body_block_id, .handler_region_id = handler_region_id, .handler_block_id = handler_block_id };
}

static uint32_t
resolve_local(PrismBuilder *builder, pm_constant_id_t name_id, uint32_t depth) {
    uint32_t local_id = builder->bindings[name_id];

#ifndef NDEBUG
    uint32_t graph_id = builder->unit->graphs[builder->state.graph_id].scope_id;
    for (uint32_t level = 0; level < depth; ++level) {
        uint32_t parent_id = builder->unit->graphs[graph_id].parent_id;
        assert(parent_id != UINT32_MAX);
        graph_id = builder->unit->graphs[parent_id].scope_id;
    }

    assert(local_id < builder->unit->nlocals);
    assert(builder->unit->locals[local_id].name_id == name_id);
    assert(builder->unit->locals[local_id].graph_id == graph_id);
#else
    (void) depth;
#endif

    return local_id;
}

/* Preserve fragment encodings until literal objects are materialized. */
static uint32_t
make_object_concat(PrismBuilder *builder, const pm_node_list_t *parts, PrismObjectKind kind, pm_node_flags_t flags) {
    uint32_t *object_ids = pm_arena_alloc(builder->arena, parts->size * sizeof(uint32_t), PRISM_ALIGNOF(uint32_t));

    for (size_t idx = 0; idx < parts->size; ++idx) {
        const pm_node_t *part = parts->nodes[idx];

        if (PM_NODE_TYPE_P(part, PM_STRING_NODE)) {
            uint32_t object_id = make_object(builder, kind == kPrismObjectRegexpConcat ? kPrismObjectRegexpString : kPrismObjectString);
            PrismObject *object = builder->unit->objects + object_id;
            object->as.string.flags = kind == kPrismObjectRegexpConcat ? flags : part->flags;
            object->as.string.unescaped = &((const pm_string_node_t *) part)->unescaped;
            object_ids[idx] = object_id;
        } else if (PM_NODE_TYPE_P(part, PM_EMBEDDED_STATEMENTS_NODE)) {
            const pm_embedded_statements_node_t *cast = (const pm_embedded_statements_node_t *) part;
            object_ids[idx] = make_object_concat(builder, &cast->statements->body, kPrismObjectStringConcat, 0);
        } else {
            assert(PM_NODE_TYPE_P(part, PM_INTERPOLATED_STRING_NODE));
            object_ids[idx] = make_object_concat(builder, &((const pm_interpolated_string_node_t *) part)->parts, kPrismObjectStringConcat, 0);
        }
    }

    uint32_t object_id = make_object(builder, kind);
    PrismObject *object = builder->unit->objects + object_id;
    object->as.concat.flags = flags;
    object->as.concat.nobject_ids = (uint32_t) parts->size;
    object->as.concat.object_ids = object_ids;
    return object_id;
}

static uint32_t
literal_value(PrismBuilder *builder, const pm_node_t *node) {
    switch (PM_NODE_TYPE(node)) {
        case PM_ARRAY_NODE: {
            const pm_array_node_t *cast = (const pm_array_node_t *) node;
            uint32_t nobject_ids = (uint32_t) cast->elements.size;
            uint32_t *object_ids = pm_arena_alloc(builder->arena, sizeof(uint32_t) * nobject_ids, PRISM_ALIGNOF(uint32_t));

            for (uint32_t idx = 0; idx < nobject_ids; ++idx) {
                object_ids[idx] = literal_value(builder, cast->elements.nodes[idx]);
            }

            uint32_t object_id = make_object(builder, kPrismObjectArray);
            PrismObject *object = builder->unit->objects + object_id;
            object->as.array.nobject_ids = nobject_ids;
            object->as.array.object_ids = object_ids;

            return object_id;
        }
        case PM_FALSE_NODE:
            return make_object(builder, kPrismObjectFalse);
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
                object_ids[idx] = literal_value(builder, assoc->key);
                object_ids[idx + 1] = literal_value(builder, assoc->value);
            }

            uint32_t object_id = make_object(builder, kPrismObjectHash);
            PrismObject *object = builder->unit->objects + object_id;
            object->as.hash.nobject_ids = nobject_ids;
            object->as.hash.object_ids = object_ids;

            return object_id;
        }
        case PM_IMAGINARY_NODE: {
            const pm_imaginary_node_t *cast = (const pm_imaginary_node_t *) node;

            uint32_t numeric_id = literal_value(builder, cast->numeric);
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
        case PM_INTERPOLATED_REGULAR_EXPRESSION_NODE:
            return make_object_concat(builder, &((const pm_interpolated_regular_expression_node_t *) node)->parts, kPrismObjectRegexpConcat, node->flags);
        case PM_INTERPOLATED_STRING_NODE:
            return make_object_concat(builder, &((const pm_interpolated_string_node_t *) node)->parts, kPrismObjectStringConcat, 0);
        case PM_INTERPOLATED_SYMBOL_NODE:
            return make_object_concat(builder, &((const pm_interpolated_symbol_node_t *) node)->parts, kPrismObjectSymbolConcat, 0);
        case PM_NIL_NODE:
            return make_object(builder, kPrismObjectNil);
        case PM_RANGE_NODE: {
            const pm_range_node_t *cast = (const pm_range_node_t *) node;
            uint32_t left_id = cast->left ? literal_value(builder, cast->left) : UINT32_MAX;
            uint32_t right_id = cast->right ? literal_value(builder, cast->right) : UINT32_MAX;

            uint32_t object_id = make_object(builder, kPrismObjectRange);
            PrismObject *object = builder->unit->objects + object_id;
            object->as.range.left_id = left_id;
            object->as.range.right_id = right_id;
            object->as.range.exclude_end = PM_NODE_FLAG_P(node, PM_RANGE_FLAGS_EXCLUDE_END);

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
        case PM_REGULAR_EXPRESSION_NODE: {
            const pm_regular_expression_node_t *cast = (const pm_regular_expression_node_t *) node;

            uint32_t object_id = make_object(builder, kPrismObjectRegexp);
            PrismObject *object = builder->unit->objects + object_id;
            object->as.string.flags = node->flags;
            object->as.string.unescaped = &cast->unescaped;

            return object_id;
        }
        case PM_SOURCE_ENCODING_NODE: {
            uint32_t object_id = make_object(builder, kPrismObjectEncoding);
            builder->unit->objects[object_id].as.encoding.name = builder->parser->encoding->name;
            return object_id;
        }
        case PM_SOURCE_FILE_NODE: {
            const pm_source_file_node_t *cast = (const pm_source_file_node_t *) node;

            uint32_t object_id = make_object(builder, kPrismObjectString);
            PrismObject *object = builder->unit->objects + object_id;
            object->as.string.flags = node->flags;
            object->as.string.unescaped = &cast->filepath;

            return object_id;
        }
        case PM_SOURCE_LINE_NODE: {
            pm_integer_t *integer = pm_arena_alloc(builder->arena, sizeof(pm_integer_t), PRISM_ALIGNOF(pm_integer_t));
            *integer = pm_integer_int32(pm_line_offset_list_line(&builder->parser->line_offsets, node->location.start, builder->parser->start_line));

            uint32_t object_id = make_object(builder, kPrismObjectInteger);
            builder->unit->objects[object_id].as.integer.value = integer;

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
        case PM_TRUE_NODE:
            return make_object(builder, kPrismObjectTrue);
        default:
            fprintf(stderr, "unsupported static literal node type: %s\n", pm_node_type(node->type));
            abort();
    }
}

static uint32_t
static_literal(PrismBuilder *builder, const pm_node_t *node) {
    assert(PM_NODE_FLAG_P(node, PM_NODE_FLAG_STATIC_LITERAL));
    return literal_value(builder, node);
}

/******************************************************************************/

typedef enum {
    kPrismBuilderValue,
    kPrismBuilderEffect
} PrismBuilderContext;

#ifdef NDEBUG
#define PM_ASSERT_VALUE_CONTEXT(context_) ((void) (context_))
#else
#define PM_ASSERT_VALUE_CONTEXT(context_) assert((context_) == kPrismBuilderValue)
#endif

static uint32_t compile_node(PrismBuilder *builder, PrismBuilderContext context, const pm_node_t *node);

static uint32_t
compile_node_or_nil(PrismBuilder *builder, PrismBuilderContext context, const pm_node_t *node, uint32_t node_id) {
    if (node) {
        return compile_node(builder, context, node);
    } else if (context == kPrismBuilderValue) {
        return emit_load_nil(builder, node_id);
    } else {
        return UINT32_MAX;
    }
}

static void
compile_arguments_splat(PrismBuilder *builder, uint32_t node_id, PrismArguments *arguments, uint32_t array_id) {
    if (arguments->splat) {
        size_t index = arguments->size - 1;
        arguments->ids[index] = emit_concat_array(builder, node_id, arguments->ids[index], array_id);
    } else {
        arguments->ids[arguments->size++] = array_id;
        arguments->splat = true;
    }
}

static void
compile_arguments_append(PrismBuilder *builder, uint32_t node_id, PrismArguments *arguments, uint32_t nvalue_ids, uint32_t *value_ids) {
    if (arguments->splat) {
        uint32_t array_id = emit_new_array(builder, node_id, nvalue_ids, value_ids);
        compile_arguments_splat(builder, node_id, arguments, array_id);
    } else {
        memmove(arguments->ids + arguments->size, value_ids, sizeof(uint32_t) * nvalue_ids);
        arguments->size += nvalue_ids;
    }
}

typedef struct {
    uint32_t *ids;
    uint32_t size;
    uint32_t capacity;
    uint32_t index;
} PrismTargetParents;

static void
PrismTargetParents_push(PrismBuilder *builder, PrismTargetParents *parents, uint32_t parent_id) {
    if (parents->size == parents->capacity) {
        uint32_t capacity = parents->capacity ? parents->capacity * 2 : 4;
        parents->ids = pm_arena_realloc(&builder->scratch, parents->ids, capacity * sizeof(uint32_t), parents->capacity * sizeof(uint32_t), PRISM_ALIGNOF(uint32_t));
        parents->capacity = capacity;
    }
    parents->ids[parents->size++] = parent_id;
}

static void compile_target_node_parents(PrismBuilder *builder, const pm_node_t *node, PrismTargetParents *parents);

static void
compile_multi_target_parents(PrismBuilder *builder, const pm_node_list_t *lefts, const pm_node_t *rest, const pm_node_list_t *rights, PrismTargetParents *parents) {
    for (size_t idx = 0; idx < lefts->size; ++idx) compile_target_node_parents(builder, lefts->nodes[idx], parents);
    if (rest) compile_target_node_parents(builder, rest, parents);
    for (size_t idx = 0; idx < rights->size; ++idx) compile_target_node_parents(builder, rights->nodes[idx], parents);
}

static void
compile_target_node_parents(PrismBuilder *builder, const pm_node_t *node, PrismTargetParents *parents) {
    switch (PM_NODE_TYPE(node)) {
        case PM_CALL_TARGET_NODE: {
            const pm_call_target_node_t *target = (const pm_call_target_node_t *) node;

            uint32_t receiver_id = compile_node(builder, kPrismBuilderValue, target->receiver);
            PrismTargetParents_push(builder, parents, receiver_id);

            break;
        }
        case PM_CONSTANT_PATH_TARGET_NODE: {
            const pm_constant_path_target_node_t *target = (const pm_constant_path_target_node_t *) node;

            if (target->parent) {
                uint32_t parent_id = compile_node(builder, kPrismBuilderValue, target->parent);
                PrismTargetParents_push(builder, parents, parent_id);
            }

            break;
        }
        case PM_INDEX_TARGET_NODE: {
            const pm_index_target_node_t *target = (const pm_index_target_node_t *) node;

            uint32_t receiver_id = compile_node(builder, kPrismBuilderValue, target->receiver);
            PrismTargetParents_push(builder, parents, receiver_id);

            if (target->arguments) {
                for (size_t idx = 0; idx < target->arguments->arguments.size; ++idx) {
                    uint32_t argument_id = compile_node(builder, kPrismBuilderValue, target->arguments->arguments.nodes[idx]);
                    PrismTargetParents_push(builder, parents, argument_id);
                }
            }

            break;
        }
        case PM_MULTI_TARGET_NODE: {
            const pm_multi_target_node_t *target = (const pm_multi_target_node_t *) node;
            compile_multi_target_parents(builder, &target->lefts, target->rest, &target->rights, parents);
            break;
        }
        case PM_SPLAT_NODE: {
            const pm_splat_node_t *target = (const pm_splat_node_t *) node;
            if (target->expression) compile_target_node_parents(builder, target->expression, parents);
            break;
        }
        default:
            break;
    }
}

static void compile_target_node(PrismBuilder *builder, const pm_node_t *node, uint32_t value_id, PrismTargetParents *parents);

static void
compile_multi_target(PrismBuilder *builder, uint32_t node_id, const pm_node_list_t *lefts, const pm_node_t *rest, const pm_node_list_t *rights, uint32_t value_id, PrismTargetParents *parents) {
    const pm_node_t *rest_target = rest && PM_NODE_TYPE_P(rest, PM_SPLAT_NODE) ? ((const pm_splat_node_t *) rest)->expression : NULL;
    uint32_t array_id = emit_coerce_array_to_ary(builder, node_id, value_id);
    uint32_t *value_ids = emit_expand_array(builder, node_id, array_id, (uint32_t) lefts->size, (uint32_t) rights->size, rest_target != NULL);
    uint32_t idx = 0;

    for (size_t left = 0; left < lefts->size; ++left) compile_target_node(builder, lefts->nodes[left], value_ids[idx++], parents);
    if (rest_target) compile_target_node(builder, rest_target, value_ids[idx++], parents);
    for (size_t right = 0; right < rights->size; ++right) compile_target_node(builder, rights->nodes[right], value_ids[idx++], parents);
}

static void
compile_target_node(PrismBuilder *builder, const pm_node_t *node, uint32_t value_id, PrismTargetParents *parents) {
    switch (PM_NODE_TYPE(node)) {
        case PM_CALL_TARGET_NODE: {
            const pm_call_target_node_t *target = (const pm_call_target_node_t *) node;
            assert(parents->index < parents->size);
            uint32_t receiver_id = parents->ids[parents->index++];
            uint32_t join_block_id = UINT32_MAX;

            if (PM_NODE_FLAG_P(target, PM_CALL_NODE_FLAGS_SAFE_NAVIGATION)) {
                uint32_t call_block_id = make_block(builder, 0);
                join_block_id = make_block(builder, 0);
                uint32_t nil_id = emit_nil_p(builder, node->node_id, receiver_id);
                emit_branchif(builder, node->node_id, nil_id, join_block_id, 0, NULL, call_block_id, 0, NULL);
                builder->state.block_id = call_block_id;
            }

            emit_call(builder, node->node_id, target->name, receiver_id, 1, &value_id, UINT32_MAX, false, false, target->base.flags, false);

            if (join_block_id != UINT32_MAX) {
                emit_branch(builder, node->node_id, join_block_id, 0, NULL);
                builder->state.block_id = join_block_id;
            }
            break;
        }
        case PM_CLASS_VARIABLE_TARGET_NODE: {
            const pm_class_variable_target_node_t *target = (const pm_class_variable_target_node_t *) node;
            emit_store_cvar(builder, target->base.node_id, target->name, value_id);
            break;
        }
        case PM_CONSTANT_TARGET_NODE: {
            const pm_constant_target_node_t *target = (const pm_constant_target_node_t *) node;
            emit_store_const_nest_rel(builder, target->base.node_id, target->name, value_id);
            break;
        }
        case PM_CONSTANT_PATH_TARGET_NODE: {
            const pm_constant_path_target_node_t *target = (const pm_constant_path_target_node_t *) node;
            if (target->parent) {
                assert(parents->index < parents->size);
                uint32_t parent_id = parents->ids[parents->index++];
                emit_store_const_recv_rel(builder, target->base.node_id, parent_id, target->name, value_id);
            } else {
                emit_store_const_abs(builder, target->base.node_id, target->name, value_id);
            }
            break;
        }
        case PM_GLOBAL_VARIABLE_TARGET_NODE: {
            const pm_global_variable_target_node_t *target = (const pm_global_variable_target_node_t *) node;
            emit_store_gvar(builder, target->base.node_id, target->name, value_id);
            break;
        }
        case PM_INDEX_TARGET_NODE: {
            const pm_index_target_node_t *target = (const pm_index_target_node_t *) node;
            uint32_t nindex_ids = target->arguments ? (uint32_t) target->arguments->arguments.size : 0;
            assert(parents->index + nindex_ids < parents->size);

            uint32_t receiver_id = parents->ids[parents->index++];
            PrismArguments arguments = {
                .ids = pm_arena_alloc(&builder->scratch, sizeof(uint32_t) * (nindex_ids + 1), PRISM_ALIGNOF(uint32_t)),
                .block_id = UINT32_MAX
            };
            uint32_t keyword_id = UINT32_MAX;

            for (uint32_t idx = 0; idx < nindex_ids; ++idx) {
                const pm_node_t *argument = target->arguments->arguments.nodes[idx];
                uint32_t argument_id = parents->ids[parents->index++];

                if (PM_NODE_TYPE_P(argument, PM_SPLAT_NODE)) {
                    compile_arguments_splat(builder, argument->node_id, &arguments, argument_id);
                } else if (PM_NODE_TYPE_P(argument, PM_KEYWORD_HASH_NODE)) {
                    keyword_id = argument_id;
                } else {
                    compile_arguments_append(builder, argument->node_id, &arguments, 1, &argument_id);
                }
            }

            compile_arguments_append(builder, node->node_id, &arguments, 1, &value_id);
            if (keyword_id != UINT32_MAX) {
                arguments.ids[arguments.size++] = keyword_id;
                arguments.keywords = true;
            }
            emit_call_arguments(builder, node->node_id, PM_CONSTANT_ID_ASET, receiver_id, &arguments, target->base.flags);
            break;
        }
        case PM_INSTANCE_VARIABLE_TARGET_NODE: {
            const pm_instance_variable_target_node_t *target = (const pm_instance_variable_target_node_t *) node;
            emit_store_ivar(builder, target->base.node_id, target->name, value_id);
            break;
        }
        case PM_LOCAL_VARIABLE_TARGET_NODE: {
            const pm_local_variable_target_node_t *target = (const pm_local_variable_target_node_t *) node;
            uint32_t local_id = resolve_local(builder, target->name, target->depth);
            emit_store_lvar(builder, target->base.node_id, local_id, value_id);
            break;
        }
        case PM_REQUIRED_PARAMETER_NODE: {
            const pm_required_parameter_node_t *parameter = (const pm_required_parameter_node_t *) node;
            uint32_t local_id = resolve_local(builder, parameter->name, 0);
            emit_store_lvar(builder, node->node_id, local_id, value_id);
            break;
        }
        case PM_MULTI_TARGET_NODE: {
            const pm_multi_target_node_t *target = (const pm_multi_target_node_t *) node;
            compile_multi_target(builder, node->node_id, &target->lefts, target->rest, &target->rights, value_id, parents);
            break;
        }
        case PM_SPLAT_NODE: {
            const pm_splat_node_t *target = (const pm_splat_node_t *) node;

            uint32_t array_id = emit_coerce_array_to_ary(builder, node->node_id, value_id);
            uint32_t *value_ids = emit_expand_array(builder, node->node_id, array_id, 0, 0, target->expression != NULL);

            if (target->expression) compile_target_node(builder, target->expression, value_ids[0], parents);
            break;
        }
        default:
            fprintf(stderr, "Unsupported target: %s\n", pm_node_type(node->type));
            abort();
    }
}

static uint32_t
compile_begin_body(PrismBuilder *builder, PrismBuilderContext context, const pm_begin_node_t *node) {
    if (node->rescue_clause) {
        uint32_t node_id = node->base.node_id;
        uint32_t retry_block_id = builder->state.retry_block_id;
        uint32_t parent_id = builder->state.region_id;

        uint32_t nparams = context == kPrismBuilderValue;
        uint32_t join_block_id = make_block(builder, nparams);
        uint32_t else_block_id = node->else_clause ? make_block(builder, 0) : UINT32_MAX;

        PrismRescueRegion rescue = make_rescue_region(builder, node_id);
        uint32_t value_id = compile_node_or_nil(builder, context, PM_NODE_UPCAST(node->statements), node_id);

        if (node->else_clause) {
            emit_branch(builder, node_id, else_block_id, 0, NULL);
            builder->state.region_id = parent_id;
            builder->state.block_id = else_block_id;
            value_id = compile_node(builder, context, PM_NODE_UPCAST(node->else_clause));
        }

        emit_branch(builder, node_id, join_block_id, nparams, &value_id);

        builder->state.region_id = rescue.handler_region_id;
        builder->state.block_id = rescue.handler_block_id;
        builder->state.retry_block_id = rescue.body_block_id;
        uint32_t exception_id = PrismBuilder_graph(builder)->blocks[rescue.handler_block_id].params[0];

        for (const pm_rescue_node_t *clause = node->rescue_clause; clause; clause = clause->subsequent) {
            uint32_t matched_block_id = make_block(builder, 0);
            uint32_t next_block_id = make_block(builder, 0);

            if (clause->exceptions.size) {
                for (size_t idx = 0; idx < clause->exceptions.size; ++idx) {
                    const pm_node_t *exception = clause->exceptions.nodes[idx];
                    uint32_t predicate_id;

                    if (!PM_NODE_TYPE_P(exception, PM_SPLAT_NODE)) {
                        uint32_t class_id = compile_node(builder, kPrismBuilderValue, exception);
                        predicate_id = emit_rescue_match(builder, exception->node_id, exception_id, class_id);
                    } else {
                        uint32_t class_id = compile_node(builder, kPrismBuilderValue, ((const pm_splat_node_t *) exception)->expression);
                        class_id = emit_coerce_array_to_a(builder, exception->node_id, class_id);
                        predicate_id = emit_rescue_match_array(builder, exception->node_id, exception_id, class_id);
                    }

                    uint32_t subsequent_block_id = idx + 1 == clause->exceptions.size ? next_block_id : make_block(builder, 0);
                    emit_branchif(builder, exception->node_id, predicate_id, matched_block_id, 0, NULL, subsequent_block_id, 0, NULL);
                    builder->state.block_id = subsequent_block_id;
                }
            } else {
                uint32_t class_id = emit_load_object(builder, clause->base.node_id, make_object(builder, kPrismObjectStandardError));
                uint32_t predicate_id = emit_rescue_match(builder, clause->base.node_id, exception_id, class_id);
                emit_branchif(builder, clause->base.node_id, predicate_id, matched_block_id, 0, NULL, next_block_id, 0, NULL);
            }

            builder->state.block_id = matched_block_id;
            emit_trace_rescue(builder, clause->base.node_id);

            if (clause->reference) {
                PrismTargetParents parents = { 0 };
                compile_target_node_parents(builder, clause->reference, &parents);
                compile_target_node(builder, clause->reference, exception_id, &parents);
                assert(parents.index == parents.size);
            }

            uint32_t result_id = compile_node_or_nil(builder, context, PM_NODE_UPCAST(clause->statements), clause->base.node_id);
            emit_branch(builder, clause->base.node_id, join_block_id, nparams, &result_id);

            builder->state.block_id = next_block_id;
        }

        emit_reraise(builder, node_id);
        builder->state.retry_block_id = retry_block_id;
        builder->state.region_id = parent_id;
        builder->state.block_id = join_block_id;

        return nparams ? PrismBuilder_graph(builder)->blocks[join_block_id].params[0] : UINT32_MAX;
    } else {
        return compile_node_or_nil(builder, context, PM_NODE_UPCAST(node->statements), node->base.node_id);
    }
}


static uint32_t
compile_call_logical_write_node(PrismBuilder *builder, const pm_node_t *node, const pm_node_t *receiver, pm_constant_id_t read_name, pm_constant_id_t write_name, const pm_node_t *value) {
    uint32_t receiver_id = receiver ? compile_node(builder, kPrismBuilderValue, receiver) : emit_load_self(builder, node->node_id);
    uint32_t write_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    if (PM_NODE_FLAG_P(node, PM_CALL_NODE_FLAGS_SAFE_NAVIGATION)) {
        uint32_t read_block_id = make_block(builder, 0);
        uint32_t nil_id = emit_nil_p(builder, node->node_id, receiver_id);
        emit_branchif(builder, node->node_id, nil_id, join_block_id, 1, &receiver_id, read_block_id, 0, NULL);
        builder->state.block_id = read_block_id;
    }

    uint32_t current_id = emit_call(builder, node->node_id, read_name, receiver_id, 0, NULL, UINT32_MAX, false, false, node->flags & PM_CALL_NODE_FLAGS_IGNORE_VISIBILITY, false);
    if (PM_NODE_TYPE_P(node, PM_CALL_AND_WRITE_NODE)) {
        emit_branchif(builder, node->node_id, current_id, write_block_id, 0, NULL, join_block_id, 1, &current_id);
    } else {
        emit_branchif(builder, node->node_id, current_id, join_block_id, 1, &current_id, write_block_id, 0, NULL);
    }

    builder->state.block_id = write_block_id;
    uint32_t value_id = compile_node(builder, kPrismBuilderValue, value);
    emit_call(builder, node->node_id, write_name, receiver_id, 1, &value_id, UINT32_MAX, false, false, node->flags & PM_CALL_NODE_FLAGS_IGNORE_VISIBILITY, false);
    emit_branch(builder, node->node_id, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

static uint32_t
compile_conditional_node(PrismBuilder *builder, const pm_node_t *node, const pm_node_t *predicate, const pm_statements_node_t *statements, const pm_node_t *subsequent) {
    uint32_t then_block_id = make_block(builder, 0);
    uint32_t else_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    uint32_t predicate_id = compile_node(builder, kPrismBuilderValue, predicate);
    if (PM_NODE_TYPE_P(node, PM_IF_NODE)) {
        emit_branchif(builder, node->node_id, predicate_id, then_block_id, 0, NULL, else_block_id, 0, NULL);
    } else {
        emit_branchif(builder, node->node_id, predicate_id, else_block_id, 0, NULL, then_block_id, 0, NULL);
    }

    builder->state.block_id = then_block_id;
    uint32_t then_value_id = compile_node_or_nil(builder, kPrismBuilderValue, PM_NODE_UPCAST(statements), node->node_id);
    emit_branch(builder, node->node_id, join_block_id, 1, &then_value_id);

    builder->state.block_id = else_block_id;
    uint32_t else_value_id = compile_node_or_nil(builder, kPrismBuilderValue, subsequent, node->node_id);
    emit_branch(builder, node->node_id, join_block_id, 1, &else_value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

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
    uint32_t value_id = compile_node(builder, kPrismBuilderValue, value);
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
    uint32_t value_id = compile_node(builder, kPrismBuilderValue, value);
    emit_store_lvar(builder, node->node_id, resolved_id, value_id);
    emit_branch(builder, node->node_id, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

static uint32_t
compile_logical_node(PrismBuilder *builder, PrismBuilderContext context, const pm_node_t *node, const pm_node_t *left, const pm_node_t *right) {
    uint32_t right_block_id = make_block(builder, 0);
    uint32_t nparams = context == kPrismBuilderValue;
    uint32_t join_block_id = make_block(builder, nparams);

    uint32_t left_value_id = compile_node(builder, kPrismBuilderValue, left);
    if (PM_NODE_TYPE(node) == PM_AND_NODE) {
        emit_branchif(builder, node->node_id, left_value_id, right_block_id, 0, NULL, join_block_id, nparams, &left_value_id);
    } else {
        emit_branchif(builder, node->node_id, left_value_id, join_block_id, nparams, &left_value_id, right_block_id, 0, NULL);
    }

    builder->state.block_id = right_block_id;
    uint32_t right_value_id = compile_node(builder, context, right);
    emit_branch(builder, node->node_id, join_block_id, nparams, &right_value_id);

    builder->state.block_id = join_block_id;
    return nparams ? PrismBuilder_graph(builder)->blocks[join_block_id].params[0] : UINT32_MAX;
}

static uint32_t
compile_loop_node(PrismBuilder *builder, const pm_node_t *node, const pm_node_t *predicate, const pm_statements_node_t *statements) {
    uint32_t break_block_id = builder->state.break_block_id;
    uint32_t next_block_id = builder->state.next_block_id;
    uint32_t redo_block_id = builder->state.redo_block_id;

    uint32_t predicate_block_id = make_block(builder, 0);
    uint32_t loop_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    builder->state.break_block_id = join_block_id;
    builder->state.next_block_id = predicate_block_id;
    builder->state.redo_block_id = loop_block_id;

    emit_branch(builder, node->node_id, PM_NODE_FLAG_P(node, PM_LOOP_FLAGS_BEGIN_MODIFIER) ? loop_block_id : predicate_block_id, 0, NULL);

    builder->state.block_id = predicate_block_id;
    uint32_t predicate_id = compile_node(builder, kPrismBuilderValue, predicate);
    uint32_t nil_id = emit_load_nil(builder, node->node_id);
    if (PM_NODE_TYPE_P(node, PM_WHILE_NODE)) {
        emit_branchif(builder, node->node_id, predicate_id, loop_block_id, 0, NULL, join_block_id, 1, &nil_id);
    } else {
        emit_branchif(builder, node->node_id, predicate_id, join_block_id, 1, &nil_id, loop_block_id, 0, NULL);
    }

    builder->state.block_id = loop_block_id;
    if (statements) {
        compile_node(builder, kPrismBuilderValue, PM_NODE_UPCAST(statements));
    }
    emit_branch(builder, node->node_id, predicate_block_id, 0, NULL);

    builder->state.block_id = join_block_id;
    builder->state.break_block_id = break_block_id;
    builder->state.next_block_id = next_block_id;
    builder->state.redo_block_id = redo_block_id;

    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

typedef struct {
    uint32_t block_id;
    bool terminal;
} PrismPatternFailure;

static uint32_t
compile_pattern_deconstruct(PrismBuilder *builder, uint32_t node_id, uint32_t value_id, uint32_t root_id, PrismPatternFailure failure) {
    uint32_t array_id = emit_deconstruct_array(builder, node_id, value_id);
    uint32_t deconstructed_block_id = make_block(builder, 0);

    if (failure.terminal) {
        uint32_t error_block_id = make_block(builder, 0);
        emit_branchif(builder, node_id, array_id, deconstructed_block_id, 0, NULL, error_block_id, 0, NULL);

        builder->state.block_id = error_block_id;
        emit_raise_pattern_deconstruct(builder, node_id, root_id, value_id);
    } else {
        emit_branchif(builder, node_id, array_id, deconstructed_block_id, 0, NULL, failure.block_id, 0, NULL);
    }

    builder->state.block_id = deconstructed_block_id;
    return array_id;
}

static uint32_t
compile_pattern_length(PrismBuilder *builder, uint32_t node_id, uint32_t array_id, uint32_t root_id, uint32_t minimum, bool rest, PrismPatternFailure failure) {
    uint32_t length_id = emit_call(builder, node_id, PM_CONSTANT_ID_LENGTH, array_id, 0, NULL, UINT32_MAX, false, false, 0, false);
    uint32_t minimum_id = emit_load_integer(builder, node_id, minimum);
    uint32_t predicate_id = emit_call(builder, node_id, rest ? PM_CONSTANT_ID_GREATER_EQUAL : PM_CONSTANT_ID_EQUAL, length_id, 1, &minimum_id, UINT32_MAX, false, false, 0, false);
    uint32_t elements_block_id = make_block(builder, 0);

    if (failure.terminal) {
        uint32_t error_block_id = make_block(builder, 0);
        emit_branchif(builder, node_id, predicate_id, elements_block_id, 0, NULL, error_block_id, 0, NULL);

        builder->state.block_id = error_block_id;
        uint32_t actual_id = emit_call(builder, node_id, PM_CONSTANT_ID_LENGTH, array_id, 0, NULL, UINT32_MAX, false, false, 0, false);

        if (rest) {
            emit_raise_pattern_min_length(builder, node_id, root_id, array_id, actual_id, minimum_id);
        } else {
            emit_raise_pattern_length(builder, node_id, root_id, array_id, actual_id, minimum_id);
        }
    } else {
        emit_branchif(builder, node_id, predicate_id, elements_block_id, 0, NULL, failure.block_id, 0, NULL);
    }

    builder->state.block_id = elements_block_id;
    return minimum_id;
}

static void compile_pattern_match(PrismBuilder *builder, const pm_node_t *node, uint32_t value_id, uint32_t root_id, uint32_t matched_block_id, PrismPatternFailure failure);
static void compile_array_pattern_node(PrismBuilder *builder, const pm_array_pattern_node_t *node, uint32_t value_id, uint32_t root_id, uint32_t matched_block_id, PrismPatternFailure failure);
static void compile_find_pattern_node(PrismBuilder *builder, const pm_find_pattern_node_t *node, uint32_t value_id, uint32_t root_id, uint32_t matched_block_id, PrismPatternFailure failure);
static void compile_hash_pattern_node(PrismBuilder *builder, const pm_hash_pattern_node_t *node, uint32_t value_id, uint32_t root_id, uint32_t matched_block_id, PrismPatternFailure failure);

static void
compile_pattern_step(PrismBuilder *builder, const pm_node_t *node, uint32_t value_id, uint32_t root_id, PrismPatternFailure failure) {
    uint32_t next_block_id = make_block(builder, 0);
    compile_pattern_match(builder, node, value_id, root_id, next_block_id, failure);

    builder->state.block_id = next_block_id;
}

static void
compile_pattern_compare(PrismBuilder *builder, uint32_t node_id, uint32_t value_id, uint32_t pattern_id, uint32_t root_id, uint32_t matched_block_id, PrismPatternFailure failure) {
    uint32_t predicate_id = emit_match(builder, node_id, value_id, pattern_id);

    if (failure.terminal) {
        uint32_t error_block_id = make_block(builder, 0);
        emit_branchif(builder, node_id, predicate_id, matched_block_id, 0, NULL, error_block_id, 0, NULL);

        builder->state.block_id = error_block_id;
        emit_raise_pattern_mismatch(builder, node_id, root_id, value_id, pattern_id);
    } else {
        emit_branchif(builder, node_id, predicate_id, matched_block_id, 0, NULL, failure.block_id, 0, NULL);
    }
}

static void
compile_pattern_match(PrismBuilder *builder, const pm_node_t *node, uint32_t value_id, uint32_t root_id, uint32_t matched_block_id, PrismPatternFailure failure) {
    switch (PM_NODE_TYPE(node)) {
        case PM_HASH_PATTERN_NODE:
            compile_hash_pattern_node(builder, (const pm_hash_pattern_node_t *) node, value_id, root_id, matched_block_id, failure);
            break;
        case PM_FIND_PATTERN_NODE:
            compile_find_pattern_node(builder, (const pm_find_pattern_node_t *) node, value_id, root_id, matched_block_id, failure);
            break;
        case PM_ARRAY_PATTERN_NODE:
            compile_array_pattern_node(builder, (const pm_array_pattern_node_t *) node, value_id, root_id, matched_block_id, failure);
            break;
        case PM_IMPLICIT_NODE: {
            const pm_implicit_node_t *cast = (const pm_implicit_node_t *) node;
            compile_pattern_match(builder, cast->value, value_id, root_id, matched_block_id, failure);
            break;
        }
        case PM_PARENTHESES_NODE: {
            const pm_parentheses_node_t *cast = (const pm_parentheses_node_t *) node;
            compile_pattern_match(builder, cast->body, value_id, root_id, matched_block_id, failure);
            break;
        }
        case PM_CAPTURE_PATTERN_NODE: {
            const pm_capture_pattern_node_t *cast = (const pm_capture_pattern_node_t *) node;
            uint32_t capture_block_id = make_block(builder, 0);
            compile_pattern_match(builder, cast->value, value_id, root_id, capture_block_id, failure);
            builder->state.block_id = capture_block_id;
            uint32_t local_id = resolve_local(builder, cast->target->name, cast->target->depth);
            emit_store_lvar(builder, cast->target->base.node_id, local_id, value_id);
            emit_branch(builder, node->node_id, matched_block_id, 0, NULL);
            break;
        }
        case PM_PINNED_EXPRESSION_NODE: {
            const pm_pinned_expression_node_t *cast = (const pm_pinned_expression_node_t *) node;
            uint32_t pattern_id = compile_node(builder, kPrismBuilderValue, cast->expression);
            compile_pattern_compare(builder, node->node_id, value_id, pattern_id, root_id, matched_block_id, failure);
            break;
        }
        case PM_PINNED_VARIABLE_NODE: {
            const pm_pinned_variable_node_t *cast = (const pm_pinned_variable_node_t *) node;
            uint32_t pattern_id = compile_node(builder, kPrismBuilderValue, cast->variable);
            compile_pattern_compare(builder, node->node_id, value_id, pattern_id, root_id, matched_block_id, failure);
            break;
        }
        case PM_ALTERNATION_PATTERN_NODE: {
            const pm_alternation_pattern_node_t *cast = (const pm_alternation_pattern_node_t *) node;
            uint32_t else_block_id = make_block(builder, 0);
            compile_pattern_match(builder, cast->left, value_id, root_id, matched_block_id, (PrismPatternFailure) { .block_id = else_block_id });
            builder->state.block_id = else_block_id;
            compile_pattern_match(builder, cast->right, value_id, root_id, matched_block_id, failure);
            break;
        }
        case PM_LOCAL_VARIABLE_TARGET_NODE:
            compile_target_node(builder, node, value_id, NULL);
            emit_branch(builder, node->node_id, matched_block_id, 0, NULL);
            break;
        case PM_ARRAY_NODE:
        case PM_CONSTANT_PATH_NODE:
        case PM_CONSTANT_READ_NODE:
        case PM_FALSE_NODE:
        case PM_FLOAT_NODE:
        case PM_GLOBAL_VARIABLE_READ_NODE:
        case PM_IMAGINARY_NODE:
        case PM_INSTANCE_VARIABLE_READ_NODE:
        case PM_IT_LOCAL_VARIABLE_READ_NODE:
        case PM_INTEGER_NODE:
        case PM_INTERPOLATED_REGULAR_EXPRESSION_NODE:
        case PM_INTERPOLATED_STRING_NODE:
        case PM_INTERPOLATED_SYMBOL_NODE:
        case PM_INTERPOLATED_X_STRING_NODE:
        case PM_LAMBDA_NODE:
        case PM_LOCAL_VARIABLE_READ_NODE:
        case PM_NIL_NODE:
        case PM_SOURCE_ENCODING_NODE:
        case PM_SOURCE_FILE_NODE:
        case PM_SOURCE_LINE_NODE:
        case PM_RANGE_NODE:
        case PM_RATIONAL_NODE:
        case PM_REGULAR_EXPRESSION_NODE:
        case PM_SELF_NODE:
        case PM_STRING_NODE:
        case PM_SYMBOL_NODE:
        case PM_TRUE_NODE:
        case PM_X_STRING_NODE: {
            uint32_t pattern_id = compile_node(builder, kPrismBuilderValue, node);
            compile_pattern_compare(builder, node->node_id, value_id, pattern_id, root_id, matched_block_id, failure);
            break;
        }
        default:
            fprintf(stderr, "Unsupported pattern: %s\n", pm_node_type(node->type));
            abort();
    }
}

static uint32_t
compile_hash_elements(PrismBuilder *builder, const pm_node_t *node, const pm_node_list_t *elements) {
    size_t nelements = elements->size;
    uint32_t value_id = UINT32_MAX;

    for (uint32_t element_idx = 0; element_idx < nelements; ++element_idx) {
        uint32_t assocs_start_idx = element_idx;
        while (element_idx < nelements && PM_NODE_TYPE_P(elements->nodes[element_idx], PM_ASSOC_NODE)) element_idx++;

        if (assocs_start_idx < element_idx) {
            uint32_t nvalue_ids = (element_idx - assocs_start_idx) * 2;
            uint32_t *value_ids = pm_arena_alloc(builder->arena, sizeof(uint32_t) * nvalue_ids, PRISM_ALIGNOF(uint32_t));

            for (uint32_t assoc_idx = assocs_start_idx; assoc_idx < element_idx; ++assoc_idx) {
                const pm_assoc_node_t *assoc = (const pm_assoc_node_t *) elements->nodes[assoc_idx];
                value_ids[(assoc_idx - assocs_start_idx) * 2] = compile_node(builder, kPrismBuilderValue, assoc->key);
                value_ids[(assoc_idx - assocs_start_idx) * 2 + 1] = compile_node(builder, kPrismBuilderValue, assoc->value);
            }

            uint32_t hash_id = emit_new_hash(builder, node->node_id, nvalue_ids, value_ids);
            value_id = value_id == UINT32_MAX ? hash_id : emit_merge_hash(builder, node->node_id, value_id, hash_id);
        }

        if (element_idx < nelements) {
            const pm_assoc_splat_node_t *assoc_splat = (const pm_assoc_splat_node_t *) elements->nodes[element_idx];
            uint32_t splat_id = assoc_splat->value ? compile_node(builder, kPrismBuilderValue, assoc_splat->value) : emit_load_lvar(builder, assoc_splat->base.node_id, builder->state.keyword_rest_local_id);
            uint32_t hash_id = emit_coerce_hash(builder, assoc_splat->base.node_id, splat_id);
            value_id = value_id == UINT32_MAX ? hash_id : emit_merge_hash(builder, node->node_id, value_id, hash_id);
        }
    }

    if (value_id == UINT32_MAX) value_id = emit_new_hash(builder, node->node_id, 0, NULL);
    return value_id;
}


static void
compile_parameter_default(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name, const pm_node_t *value, uint32_t value_id, uint32_t specified_id, uint32_t local_id) {
    uint32_t default_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);
    emit_branchif(builder, node_id, specified_id, join_block_id, 1, &value_id, default_block_id, 0, NULL);

    builder->state.block_id = default_block_id;
    uint32_t default_id = compile_node(builder, kPrismBuilderValue, value);
    uint32_t named_local_id = resolve_local(builder, name, 0);

    if (local_id != named_local_id) emit_store_lvar(builder, node_id, named_local_id, default_id);
    emit_branch(builder, node_id, join_block_id, 1, &default_id);

    builder->state.block_id = join_block_id;
    emit_store_lvar(builder, node_id, local_id, PrismBuilder_graph(builder)->blocks[join_block_id].params[0]);
}

static uint32_t
parameters_locals(const pm_parameters_node_t *parameters) {
    uint32_t nlocals = 0;

    if (parameters) {
        if (parameters->keyword_rest && PM_NODE_TYPE_P(parameters->keyword_rest, PM_FORWARDING_PARAMETER_NODE)) {
            nlocals += 3;
        }

        if (parameters->rest && PM_NODE_TYPE_P(parameters->rest, PM_REST_PARAMETER_NODE)) {
            const pm_rest_parameter_node_t *rest = (const pm_rest_parameter_node_t *) parameters->rest;
            if (!rest->name) nlocals++;
        }

        if (parameters->keyword_rest && PM_NODE_TYPE_P(parameters->keyword_rest, PM_KEYWORD_REST_PARAMETER_NODE)) {
            const pm_keyword_rest_parameter_node_t *keyword_rest = (const pm_keyword_rest_parameter_node_t *) parameters->keyword_rest;
            if (!keyword_rest->name) nlocals++;
        }

        if (parameters->block && PM_NODE_TYPE_P(parameters->block, PM_BLOCK_PARAMETER_NODE)) {
            const pm_block_parameter_node_t *block = (const pm_block_parameter_node_t *) parameters->block;
            if (!block->name) nlocals++;
        }

        const pm_node_list_t *lists[] = {
            &parameters->requireds,
            &parameters->optionals,
            &parameters->posts,
            &parameters->keywords
        };

        for (size_t list = 0; list < sizeof(lists) / sizeof(lists[0]); ++list) {
            for (size_t idx = 0; idx < lists[list]->size; ++idx) {
                const pm_node_t *node = lists[list]->nodes[idx];

                if (PM_NODE_TYPE_P(node, PM_MULTI_TARGET_NODE) || PM_NODE_FLAG_P(node, PM_PARAMETER_FLAGS_REPEATED_PARAMETER)) {
                    nlocals++;
                }
            }
        }

        const pm_node_t *nodes[] = {
            parameters->rest,
            parameters->keyword_rest,
            parameters->block
        };

        for (size_t idx = 0; idx < sizeof(nodes) / sizeof(nodes[0]); ++idx) {
            if (nodes[idx] && PM_NODE_FLAG_P(nodes[idx], PM_PARAMETER_FLAGS_REPEATED_PARAMETER)) {
                nlocals++;
            }
        }
    }

    return nlocals;
}

static void
compile_parameters(PrismBuilder *builder, const pm_parameters_node_t *parameters, const PrismSignature *signature) {
    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t index = 0;

    for (uint32_t idx = 0; idx < signature->nrequired_ids; ++idx) {
        emit_store_lvar(builder, parameters->base.node_id, graph->local_ids[index++], signature->required_ids[idx]);
    }

    for (uint32_t idx = 0; idx < signature->noptional_ids; ++idx) {
        emit_store_lvar(builder, parameters->base.node_id, graph->local_ids[index++], signature->optional_ids[idx]);
    }

    if (signature->rest_id != UINT32_MAX) {
        emit_store_lvar(builder, parameters->base.node_id, graph->local_ids[index++], signature->rest_id);
    }

    for (uint32_t idx = 0; idx < signature->npost_ids; ++idx) {
        emit_store_lvar(builder, parameters->base.node_id, graph->local_ids[index++], signature->post_ids[idx]);
    }

    for (uint32_t idx = 0; idx < signature->nrequired_keyword_ids; ++idx) {
        emit_store_lvar(builder, parameters->base.node_id, graph->local_ids[index++], signature->required_keyword_ids[idx]);
    }

    for (uint32_t idx = 0; idx < signature->noptional_keyword_ids; ++idx) {
        emit_store_lvar(builder, parameters->base.node_id, graph->local_ids[index++], signature->optional_keyword_ids[idx]);
    }

    if (signature->keyword_rest_id != UINT32_MAX) {
        emit_store_lvar(builder, parameters->base.node_id, graph->local_ids[index++], signature->keyword_rest_id);
    }

    if (signature->block_id != UINT32_MAX) {
        emit_store_lvar(builder, parameters->base.node_id, graph->local_ids[index++], signature->block_id);
    }

    for (uint32_t idx = 0; idx < signature->noptional_ids; ++idx) {
        const pm_optional_parameter_node_t *optional = (const pm_optional_parameter_node_t *) parameters->optionals.nodes[idx];
        uint32_t local_id = PrismBuilder_graph(builder)->local_ids[signature->nrequired_ids + idx];
        compile_parameter_default(builder, optional->base.node_id, optional->name, optional->value, signature->optional_ids[idx], signature->optional_specified_ids[idx], local_id);
    }

    uint32_t keyword_idx = 0;
    for (size_t idx = 0; idx < parameters->keywords.size; ++idx) {
        const pm_node_t *keyword = parameters->keywords.nodes[idx];

        if (PM_NODE_TYPE_P(keyword, PM_OPTIONAL_KEYWORD_PARAMETER_NODE)) {
            const pm_optional_keyword_parameter_node_t *optional = (const pm_optional_keyword_parameter_node_t *) keyword;

            uint32_t local_index = signature->nrequired_ids + signature->noptional_ids + (signature->rest_id != UINT32_MAX) + signature->npost_ids + signature->nrequired_keyword_ids + keyword_idx;
            uint32_t local_id = PrismBuilder_graph(builder)->local_ids[local_index];

            compile_parameter_default(builder, optional->base.node_id, optional->name, optional->value, signature->optional_keyword_ids[keyword_idx], signature->optional_keyword_specified_ids[keyword_idx], local_id);
            keyword_idx++;
        }
    }

    for (uint32_t idx = 0; idx < signature->nrequired_ids; ++idx) {
        const pm_node_t *required = parameters->requireds.nodes[idx];

        if (PM_NODE_TYPE_P(required, PM_MULTI_TARGET_NODE)) {
            compile_target_node(builder, required, signature->required_ids[idx], NULL);
        }
    }

    for (uint32_t idx = 0; idx < signature->npost_ids; ++idx) {
        const pm_node_t *post = parameters->posts.nodes[idx];

        if (PM_NODE_TYPE_P(post, PM_MULTI_TARGET_NODE)) {
            compile_target_node(builder, post, signature->post_ids[idx], NULL);
        }
    }
}

static uint32_t
compile_program_node_statements(PrismBuilder *builder, PrismBuilderContext context, const pm_statements_node_t *statements, uint32_t node_id) {
    PrismBuilderState pre_state = builder->state;
    uint32_t body_block_id = make_block(builder, 0);
    builder->state.block_id = body_block_id;
    uint32_t value_id;

    if (statements && statements->body.size) {
        for (size_t idx = 0; idx < statements->body.size; ++idx) {
            const pm_node_t *statement = statements->body.nodes[idx];

            if (PM_NODE_TYPE_P(statement, PM_PRE_EXECUTION_NODE)) {
                const pm_pre_execution_node_t *cast = (const pm_pre_execution_node_t *) statement;
                PrismBuilderState body_state = builder->state;
                builder->state = pre_state;
                compile_program_node_statements(builder, kPrismBuilderEffect, cast->statements, statement->node_id);
                pre_state = builder->state;
                builder->state = body_state;
                statement = NULL;
            }

            value_id = compile_node_or_nil(builder, idx + 1 < statements->body.size ? kPrismBuilderEffect : context, statement, node_id);
        }
    } else {
        value_id = compile_node_or_nil(builder, context, NULL, node_id);
    }

    PrismBuilderState body_state = builder->state;
    builder->state = pre_state;
    emit_branch(builder, node_id, body_block_id, 0, NULL);
    builder->state = body_state;
    return value_id;
}

/******************************************************************************/

static uint32_t
compile_regexp_parts(PrismBuilder *builder, const pm_node_t *node, const pm_node_list_t *parts) {
    uint32_t nvalue_ids = (uint32_t) parts->size;
    uint32_t *value_ids = pm_arena_alloc(&builder->scratch, nvalue_ids * sizeof(uint32_t), PRISM_ALIGNOF(uint32_t));
    for (uint32_t idx = 0; idx < nvalue_ids; ++idx) {
        const pm_node_t *part = parts->nodes[idx];
        if (PM_NODE_TYPE_P(part, PM_STRING_NODE)) {
            uint32_t object_id = make_object(builder, kPrismObjectRegexpString);
            PrismObject *object = builder->unit->objects + object_id;
            object->as.string.flags = node->flags;
            object->as.string.unescaped = &((const pm_string_node_t *) part)->unescaped;
            value_ids[idx] = emit_load_object(builder, part->node_id, object_id);
        } else {
            value_ids[idx] = compile_node(builder, kPrismBuilderValue, part);
        }
    }
    return emit_new_regexp(builder, node->node_id, nvalue_ids, value_ids, node->flags & ~PM_REGULAR_EXPRESSION_FLAGS_ONCE);
}

static uint32_t
compile_once_regexp(PrismBuilder *builder, const pm_node_t *node, const pm_node_list_t *parts) {
    uint32_t parent_id = builder->state.region_id;
    uint32_t continuation_block_id = make_block(builder, 0);
    uint32_t region_id = make_region(builder, kPrismRegionOnce, parent_id, UINT32_MAX, UINT32_MAX);
    uint32_t value_id = emit_once(builder, node->node_id, region_id);
    emit_branch(builder, node->node_id, continuation_block_id, 0, NULL);

    builder->state.region_id = region_id;
    uint32_t entry_block_id = make_block(builder, 0);
    PrismBuilder_graph(builder)->regions[region_id].entry_block_id = entry_block_id;
    builder->state.block_id = entry_block_id;
    uint32_t regexp_id = compile_regexp_parts(builder, node, parts);
    emit_once_return(builder, node->node_id, region_id, regexp_id);

    builder->state.region_id = parent_id;
    builder->state.block_id = continuation_block_id;
    return value_id;
}

static uint32_t
compile_interpolated_regexp(PrismBuilder *builder, const pm_node_t *node, const pm_node_list_t *parts) {
    if (PM_NODE_FLAG_P(node, PM_REGULAR_EXPRESSION_FLAGS_ONCE)) {
        return compile_once_regexp(builder, node, parts);
    }
    return compile_regexp_parts(builder, node, parts);
}

static uint32_t
compile_flip_flop_bound(PrismBuilder *builder, const pm_node_t *node, uint32_t node_id) {
    uint32_t value_id = compile_node_or_nil(builder, kPrismBuilderValue, node, node_id);

    if (node && PM_NODE_TYPE_P(node, PM_INTEGER_NODE)) {
        uint32_t line_id = emit_load_gvar(builder, node->node_id, PM_CONSTANT_ID_LINE_NUMBER);
        return emit_call(builder, node->node_id, PM_CONSTANT_ID_EQUAL, value_id, 1, &line_id, UINT32_MAX, false, false, 0, false);
    }

    return value_id;
}

static void
compile_block_body(PrismBuilder *builder, uint32_t node_id, const pm_node_t *body) {
    emit_trace_b_call(builder, node_id);
    uint32_t body_block_id = make_block(builder, 0);
    emit_branch(builder, node_id, body_block_id, 0, NULL);
    builder->state.block_id = body_block_id;
    builder->state.redo_block_id = body_block_id;

    uint32_t value_id = compile_node_or_nil(builder, kPrismBuilderValue, body, node_id);
    emit_trace_b_return(builder, node_id, value_id);
    emit_return(builder, node_id, value_id);
}

static uint32_t
compile_closure(PrismBuilder *builder, const pm_node_t *node, PrismGraphKind kind, const pm_node_t *parameters_node, const pm_node_t *body, const pm_constant_id_list_t *locals) {
    const pm_parameters_node_t *parameters = NULL;

    uint32_t nrequired_ids = 0;
    uint32_t nlocal_ids = (uint32_t) locals->size;

    bool numbered = false;
    bool it = false;

    if (parameters_node) {
        switch (PM_NODE_TYPE(parameters_node)) {
            case PM_BLOCK_PARAMETERS_NODE:
                parameters = ((const pm_block_parameters_node_t *) parameters_node)->parameters;
                nlocal_ids += parameters_locals(parameters);
                break;
            case PM_NUMBERED_PARAMETERS_NODE:
                numbered = true;
                nrequired_ids = ((const pm_numbered_parameters_node_t *) parameters_node)->maximum;
                break;
            case PM_IT_PARAMETERS_NODE:
                it = true;
                nrequired_ids = 1;
                nlocal_ids++;
                break;
            default:
                break;
        }
    }

    uint32_t graph_id = make_graph(builder, kind, builder->state.graph_id, nlocal_ids);
    PrismSignature signature;

    if (parameters) {
        compile_parameters_signature(builder, graph_id, &signature, parameters);
    } else {
        make_signature(builder, graph_id, &signature, nrequired_ids, 0, false, 0);
    }

    uint32_t npositional_ids = signature.nrequired_ids + signature.npost_ids;
    signature.autosplat = kind == kPrismGraphBlock && (npositional_ids + signature.noptional_ids > 1 || (npositional_ids > 0 && parameters && parameters->rest));

    PrismBuilderState state = push_scope(builder, graph_id, &signature, parameters, locals);
    const uint32_t *required_ids = PrismBuilder_graph(builder)->signature.required_ids;

    if (numbered) {
        for (uint32_t idx = 0; idx < nrequired_ids; ++idx) {
            const uint8_t name[] = { '_', (uint8_t) ('1' + idx) };
            pm_constant_id_t name_id = pm_parser_constant_find(builder->parser, name, sizeof(name));
            uint32_t local_id = resolve_local(builder, name_id, 0);
            emit_store_lvar(builder, parameters_node->node_id, local_id, required_ids[idx]);
        }
    } else if (it) {
        uint32_t local_id = make_local(builder, PM_CONSTANT_ID_IT);
        builder->state.it_local_id = local_id;
        PrismBuilder_graph(builder)->local_ids[locals->size] = local_id;
        emit_store_lvar(builder, parameters_node->node_id, local_id, required_ids[0]);
    }

    if (parameters) {
        compile_parameters(builder, parameters, &signature);
    }

    compile_block_body(builder, node->node_id, body);
    pop_scope(builder, state);

    return emit_new_block(builder, node->node_id, graph_id);
}

static PrismArguments
compile_arguments(PrismBuilder *builder, const pm_arguments_node_t *arguments, const pm_node_t *block) {
    PrismArguments result = { .block_id = UINT32_MAX, .last_id = UINT32_MAX };

    if (arguments) {
        size_t size = arguments->arguments.size;
        result.ids = pm_arena_alloc(&builder->scratch, sizeof(uint32_t) * (size + 1), PRISM_ALIGNOF(uint32_t));
        uint32_t keyword_id = UINT32_MAX;

        for (size_t idx = 0; idx < size;) {
            const pm_node_t *argument = arguments->arguments.nodes[idx];
            bool forwarding = PM_NODE_TYPE_P(argument, PM_FORWARDING_ARGUMENTS_NODE);

            if (PM_NODE_TYPE_P(argument, PM_KEYWORD_HASH_NODE)) {
                keyword_id = compile_node(builder, kPrismBuilderValue, argument);
                idx++;
            } else if (forwarding || PM_NODE_TYPE_P(argument, PM_SPLAT_NODE)) {
                uint32_t value_id = forwarding ? emit_load_lvar(builder, argument->node_id, builder->state.rest_local_id) : compile_node(builder, kPrismBuilderValue, argument);
                compile_arguments_splat(builder, argument->node_id, &result, value_id);
                if (forwarding) {
                    keyword_id = emit_load_lvar(builder, argument->node_id, builder->state.keyword_rest_local_id);
                    result.block_id = emit_load_lvar(builder, argument->node_id, builder->state.block_local_id);
                    result.block_argument = true;
                }
                idx++;
            } else {
                uint32_t nvalue_ids = 0;

                do {
                    result.last_id = compile_node(builder, kPrismBuilderValue, arguments->arguments.nodes[idx++]);
                    result.ids[result.size + nvalue_ids++] = result.last_id;
                } while (
                    idx < size &&
                    !PM_NODE_TYPE_P(arguments->arguments.nodes[idx], PM_SPLAT_NODE) &&
                    !PM_NODE_TYPE_P(arguments->arguments.nodes[idx], PM_KEYWORD_HASH_NODE) &&
                    !PM_NODE_TYPE_P(arguments->arguments.nodes[idx], PM_FORWARDING_ARGUMENTS_NODE)
                );

                if (nvalue_ids) {
                    compile_arguments_append(builder, argument->node_id, &result, nvalue_ids, result.ids + result.size);
                }
            }
        }

        if (keyword_id != UINT32_MAX) {
            result.ids[result.size++] = keyword_id;
            result.keywords = true;
        }
    }

    if (block) {
        result.block_id = compile_node(builder, kPrismBuilderValue, block);
        result.block_argument = PM_NODE_TYPE_P(block, PM_BLOCK_ARGUMENT_NODE);
    }

    return result;
}

static uint32_t
compile_jump_arguments(PrismBuilder *builder, uint32_t node_id, const pm_arguments_node_t *arguments) {
    if (!arguments) {
        return emit_load_nil(builder, node_id);
    } else if (arguments->arguments.size == 1 && !PM_NODE_TYPE_P(arguments->arguments.nodes[0], PM_SPLAT_NODE)) {
        return compile_node(builder, kPrismBuilderValue, arguments->arguments.nodes[0]);
    } else {
        PrismArguments values = compile_arguments(builder, arguments, NULL);
        uint32_t array_id;

        if (!values.splat) {
            array_id = emit_new_array(builder, node_id, (uint32_t) values.size, values.ids);
        } else {
            uint32_t keyword_id = values.keywords ? values.ids[--values.size] : UINT32_MAX;
            array_id = emit_new_array(builder, node_id, (uint32_t) values.size - 1, values.ids);
            array_id = emit_concat_array(builder, node_id, array_id, values.ids[values.size - 1]);

            if (keyword_id != UINT32_MAX) {
                uint32_t keywords_id = emit_new_array(builder, node_id, 1, &keyword_id);
                array_id = emit_concat_array(builder, node_id, array_id, keywords_id);
            }
        }

        return array_id;
    }
}

static void
compile_index_write(PrismBuilder *builder, uint32_t node_id, uint32_t receiver_id, PrismArguments *arguments, uint32_t value_id, pm_node_flags_t flags) {
    uint32_t *write_ids = pm_arena_alloc(&builder->scratch, sizeof(uint32_t) * (arguments->size + 1), PRISM_ALIGNOF(uint32_t));
    if (arguments->size) memcpy(write_ids, arguments->ids, sizeof(uint32_t) * arguments->size);
    arguments->ids = write_ids;
    uint32_t keyword_id = arguments->keywords ? arguments->ids[--arguments->size] : UINT32_MAX;
    compile_arguments_append(builder, node_id, arguments, 1, &value_id);
    if (keyword_id != UINT32_MAX) arguments->ids[arguments->size++] = keyword_id;
    emit_call_arguments(builder, node_id, PM_CONSTANT_ID_ASET, receiver_id, arguments, flags);
}

static uint32_t
compile_index_logical_write_node(PrismBuilder *builder, const pm_node_t *node, const pm_node_t *receiver, const pm_arguments_node_t *arguments_node, const pm_node_t *block, const pm_node_t *value) {
    uint32_t receiver_id = compile_node(builder, kPrismBuilderValue, receiver);
    uint32_t write_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    if (PM_NODE_FLAG_P(node, PM_CALL_NODE_FLAGS_SAFE_NAVIGATION)) {
        uint32_t read_block_id = make_block(builder, 0);
        uint32_t nil_id = emit_nil_p(builder, node->node_id, receiver_id);
        emit_branchif(builder, node->node_id, nil_id, join_block_id, 1, &receiver_id, read_block_id, 0, NULL);
        builder->state.block_id = read_block_id;
    }

    PrismArguments arguments = compile_arguments(builder, arguments_node, block);
    uint32_t current_id = emit_call_arguments(builder, node->node_id, PM_CONSTANT_ID_AREF, receiver_id, &arguments, node->flags);
    if (PM_NODE_TYPE_P(node, PM_INDEX_AND_WRITE_NODE)) {
        emit_branchif(builder, node->node_id, current_id, write_block_id, 0, NULL, join_block_id, 1, &current_id);
    } else {
        emit_branchif(builder, node->node_id, current_id, join_block_id, 1, &current_id, write_block_id, 0, NULL);
    }

    builder->state.block_id = write_block_id;
    uint32_t value_id = compile_node(builder, kPrismBuilderValue, value);
    compile_index_write(builder, node->node_id, receiver_id, &arguments, value_id, node->flags);
    emit_branch(builder, node->node_id, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

static uint32_t
compile_constexpr_string(PrismBuilder *builder, const char *value, size_t length) {
    uint32_t object_id = make_object_string(builder, value, length);
    builder->unit->objects[object_id].as.string.flags = PM_STRING_FLAGS_FROZEN;
    return emit_load_object(builder, UINT32_MAX, object_id);
}

static uint32_t
compile_call_with_receiver(PrismBuilder *builder, const pm_call_node_t *node, uint32_t receiver_id) {
    bool safe_navigation = PM_NODE_FLAG_P(node, PM_CALL_NODE_FLAGS_SAFE_NAVIGATION);
    uint32_t join_block_id = UINT32_MAX;
    if (safe_navigation) {
        uint32_t call_block_id = make_block(builder, 0);
        join_block_id = make_block(builder, 1);
        uint32_t predicate_id = emit_nil_p(builder, node->base.node_id, receiver_id);
        emit_branchif(builder, node->base.node_id, predicate_id, join_block_id, 1, &receiver_id, call_block_id, 0, NULL);
        builder->state.block_id = call_block_id;
    }

    PrismArguments arguments = compile_arguments(builder, node->arguments, node->block);
    uint32_t value_id = emit_call_arguments(builder, node->base.node_id, node->name, receiver_id, &arguments, node->base.flags);

    if (PM_NODE_FLAG_P(node, PM_CALL_NODE_FLAGS_ATTRIBUTE_WRITE)) {
        value_id = arguments.last_id;
    }

    if (safe_navigation) {
        emit_branch(builder, node->base.node_id, join_block_id, 1, &value_id);
        builder->state.block_id = join_block_id;
        return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
    }

    return value_id;
}

static uint32_t
compile_defined_result(PrismBuilder *builder, uint32_t node_id, uint32_t predicate_id, const char *description) {
    uint32_t defined_block_id = make_block(builder, 0);
    uint32_t undefined_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);
    emit_branchif(builder, node_id, predicate_id, defined_block_id, 0, NULL, undefined_block_id, 0, NULL);

    builder->state.block_id = defined_block_id;
    uint32_t result_id = compile_constexpr_string(builder, description, strlen(description));
    emit_branch(builder, node_id, join_block_id, 1, &result_id);

    builder->state.block_id = undefined_block_id;
    result_id = emit_load_nil(builder, node_id);
    emit_branch(builder, node_id, join_block_id, 1, &result_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

static uint32_t compile_defined_expression(PrismBuilder *builder, const pm_node_t *value);

static uint32_t
compile_defined_elements(PrismBuilder *builder, uint32_t node_id, const pm_node_list_t *elements) {
    if (!elements->size) return compile_constexpr_string(builder, "expression", 10);

    uint32_t undefined_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);
    for (size_t idx = 0; idx < elements->size; ++idx) {
        uint32_t predicate_id = compile_defined_expression(builder, elements->nodes[idx]);
        uint32_t next_block_id = make_block(builder, 0);
        emit_branchif(builder, node_id, predicate_id, next_block_id, 0, NULL, undefined_block_id, 0, NULL);
        builder->state.block_id = next_block_id;
    }

    uint32_t result_id = compile_constexpr_string(builder, "expression", 10);
    emit_branch(builder, node_id, join_block_id, 1, &result_id);

    builder->state.block_id = undefined_block_id;
    result_id = emit_load_nil(builder, node_id);
    emit_branch(builder, node_id, join_block_id, 1, &result_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

/* On success, retain the receiver so a chained call can invoke this method
 * without evaluating its receiver again. Failure branches to the caller. */
static uint32_t
compile_defined_call(PrismBuilder *builder, const pm_call_node_t *node, uint32_t undefined_block_id) {
    uint32_t node_id = node->base.node_id;
    if (node->arguments) {
        uint32_t predicate_id = compile_defined_expression(builder, PM_NODE_UPCAST(node->arguments));
        uint32_t next_block_id = make_block(builder, 0);
        emit_branchif(builder, node_id, predicate_id, next_block_id, 0, NULL, undefined_block_id, 0, NULL);
        builder->state.block_id = next_block_id;
    }

    uint32_t receiver_id;
    if (node->receiver) {
        const pm_call_node_t *receiver = PM_NODE_TYPE_P(node->receiver, PM_CALL_NODE) ? (const pm_call_node_t *) node->receiver : NULL;
        if (receiver && !(receiver->block && PM_NODE_TYPE_P(receiver->block, PM_BLOCK_NODE))) {
            uint32_t parent_id = compile_defined_call(builder, receiver, undefined_block_id);
            receiver_id = compile_call_with_receiver(builder, receiver, parent_id);
        } else {
            uint32_t predicate_id = compile_defined_expression(builder, node->receiver);
            uint32_t next_block_id = make_block(builder, 0);
            emit_branchif(builder, node_id, predicate_id, next_block_id, 0, NULL, undefined_block_id, 0, NULL);
            builder->state.block_id = next_block_id;
            receiver_id = compile_node(builder, kPrismBuilderValue, node->receiver);
        }
    } else {
        receiver_id = emit_load_self(builder, node_id);
    }

    uint32_t predicate_id = node->receiver ? emit_defined_explicit_method(builder, node_id, node->name, receiver_id) : emit_defined_implicit_method(builder, node_id, node->name, receiver_id);
    uint32_t next_block_id = make_block(builder, 0);
    emit_branchif(builder, node_id, predicate_id, next_block_id, 0, NULL, undefined_block_id, 0, NULL);
    builder->state.block_id = next_block_id;
    return receiver_id;
}

static uint32_t
compile_defined_call_expression(PrismBuilder *builder, const pm_call_node_t *node) {
    if (node->block && PM_NODE_TYPE_P(node->block, PM_BLOCK_NODE)) {
        return compile_constexpr_string(builder, "expression", 10);
    }

    uint32_t node_id = node->base.node_id;
    uint32_t parent_id = builder->state.region_id;
    uint32_t undefined_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);
    PrismRescueRegion rescue = { .handler_block_id = UINT32_MAX };
    if (node->receiver || node->arguments || node->block) {
        rescue = make_rescue_region(builder, node_id);
    }

    compile_defined_call(builder, node, undefined_block_id);
    uint32_t result_id = compile_constexpr_string(builder, "method", 6);
    emit_branch(builder, node_id, join_block_id, 1, &result_id);

    if (rescue.handler_block_id != UINT32_MAX) {
        builder->state.region_id = rescue.handler_region_id;
        builder->state.block_id = rescue.handler_block_id;
        emit_branch(builder, node_id, undefined_block_id, 0, NULL);
    }

    builder->state.region_id = parent_id;
    builder->state.block_id = undefined_block_id;
    result_id = emit_load_nil(builder, node_id);
    emit_branch(builder, node_id, join_block_id, 1, &result_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

static uint32_t
compile_defined_constant_path(PrismBuilder *builder, const pm_constant_path_node_t *node) {
    uint32_t node_id = node->base.node_id;
    if (!node->parent) {
        uint32_t predicate_id = emit_defined_const_abs(builder, node_id, node->name);
        return compile_defined_result(builder, node_id, predicate_id, "constant");
    }

    uint32_t parent_id = builder->state.region_id;
    uint32_t undefined_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);
    PrismRescueRegion rescue = make_rescue_region(builder, node_id);
    uint32_t predicate_id = compile_defined_expression(builder, node->parent);
    uint32_t receiver_block_id = make_block(builder, 0);
    emit_branchif(builder, node_id, predicate_id, receiver_block_id, 0, NULL, undefined_block_id, 0, NULL);

    builder->state.block_id = receiver_block_id;
    uint32_t receiver_id = compile_node(builder, kPrismBuilderValue, node->parent);
    predicate_id = emit_defined_const_recv_rel(builder, node_id, node->name, receiver_id);
    uint32_t defined_block_id = make_block(builder, 0);
    emit_branchif(builder, node_id, predicate_id, defined_block_id, 0, NULL, undefined_block_id, 0, NULL);

    builder->state.block_id = defined_block_id;
    uint32_t result_id = compile_constexpr_string(builder, "constant", 8);
    emit_branch(builder, node_id, join_block_id, 1, &result_id);

    builder->state.region_id = rescue.handler_region_id;
    builder->state.block_id = rescue.handler_block_id;
    emit_branch(builder, node_id, undefined_block_id, 0, NULL);

    builder->state.region_id = parent_id;
    builder->state.block_id = undefined_block_id;
    result_id = emit_load_nil(builder, node_id);
    emit_branch(builder, node_id, join_block_id, 1, &result_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

static uint32_t
compile_defined_expression(PrismBuilder *builder, const pm_node_t *value) {
    uint32_t value_id;

    switch (PM_NODE_TYPE(value)) {
        case PM_INSTANCE_VARIABLE_READ_NODE: {
            uint32_t predicate_id = emit_defined_ivar(builder, value->node_id, ((const pm_instance_variable_read_node_t *) value)->name);
            return compile_defined_result(builder, value->node_id, predicate_id, "instance-variable");
        }
        case PM_GLOBAL_VARIABLE_READ_NODE: {
            uint32_t predicate_id = emit_defined_gvar(builder, value->node_id, ((const pm_global_variable_read_node_t *) value)->name);
            return compile_defined_result(builder, value->node_id, predicate_id, "global-variable");
        }
        case PM_CLASS_VARIABLE_READ_NODE: {
            uint32_t predicate_id = emit_defined_cvar(builder, value->node_id, ((const pm_class_variable_read_node_t *) value)->name);
            return compile_defined_result(builder, value->node_id, predicate_id, "class variable");
        }
        case PM_CONSTANT_READ_NODE: {
            uint32_t predicate_id = emit_defined_const_nest_rel(builder, value->node_id, ((const pm_constant_read_node_t *) value)->name);
            return compile_defined_result(builder, value->node_id, predicate_id, "constant");
        }
        case PM_YIELD_NODE: {
            uint32_t predicate_id = emit_load_block(builder, value->node_id);
            return compile_defined_result(builder, value->node_id, predicate_id, "yield");
        }
        case PM_SUPER_NODE: {
            const pm_super_node_t *cast = (const pm_super_node_t *) value;
            if (cast->block && !PM_NODE_TYPE_P(cast->block, PM_BLOCK_ARGUMENT_NODE)) {
                return compile_constexpr_string(builder, "expression", 10);
            }
            uint32_t predicate_id = emit_defined_super(builder, value->node_id);
            return compile_defined_result(builder, value->node_id, predicate_id, "super");
        }
        case PM_FORWARDING_SUPER_NODE: {
            const pm_forwarding_super_node_t *cast = (const pm_forwarding_super_node_t *) value;
            if (cast->block) return compile_constexpr_string(builder, "expression", 10);
            uint32_t predicate_id = emit_defined_super(builder, value->node_id);
            return compile_defined_result(builder, value->node_id, predicate_id, "super");
        }
        case PM_BACK_REFERENCE_READ_NODE:
        case PM_NUMBERED_REFERENCE_READ_NODE: {
            uint32_t predicate_id = compile_node(builder, kPrismBuilderValue, value);
            return compile_defined_result(builder, value->node_id, predicate_id, "global-variable");
        }
        case PM_ARRAY_NODE:
            return compile_defined_elements(builder, value->node_id, &((const pm_array_node_t *) value)->elements);
        case PM_HASH_NODE:
            return compile_defined_elements(builder, value->node_id, &((const pm_hash_node_t *) value)->elements);
        case PM_KEYWORD_HASH_NODE:
            return compile_defined_elements(builder, value->node_id, &((const pm_keyword_hash_node_t *) value)->elements);
        case PM_ARGUMENTS_NODE:
            return compile_defined_elements(builder, value->node_id, &((const pm_arguments_node_t *) value)->arguments);
        case PM_ASSOC_NODE: {
            const pm_assoc_node_t *cast = (const pm_assoc_node_t *) value;
            pm_node_list_t elements = { .nodes = (pm_node_t *[]) { cast->key, cast->value }, .size = 2 };
            return compile_defined_elements(builder, value->node_id, &elements);
        }
        case PM_ASSOC_SPLAT_NODE: {
            const pm_assoc_splat_node_t *cast = (const pm_assoc_splat_node_t *) value;
            return cast->value ? compile_defined_expression(builder, cast->value) : compile_constexpr_string(builder, "expression", 10);
        }
        case PM_SPLAT_NODE: {
            const pm_splat_node_t *cast = (const pm_splat_node_t *) value;
            if (!cast->expression) return compile_constexpr_string(builder, "expression", 10);
            uint32_t predicate_id = compile_defined_expression(builder, cast->expression);
            return compile_defined_result(builder, value->node_id, predicate_id, "expression");
        }
        case PM_BLOCK_ARGUMENT_NODE:
        case PM_FORWARDING_ARGUMENTS_NODE:
            return compile_constexpr_string(builder, "expression", 10);
        case PM_CALL_NODE:
            return compile_defined_call_expression(builder, (const pm_call_node_t *) value);
        case PM_CONSTANT_PATH_NODE:
            return compile_defined_constant_path(builder, (const pm_constant_path_node_t *) value);
        case PM_LOCAL_VARIABLE_READ_NODE:
        case PM_IT_LOCAL_VARIABLE_READ_NODE:
            value_id = compile_constexpr_string(builder, "local-variable", 14);
            break;
        case PM_BEGIN_NODE: {
            const pm_begin_node_t *cast = (const pm_begin_node_t *) value;
            if (!cast->rescue_clause && !cast->else_clause && !cast->ensure_clause) {
                if (!cast->statements) {
                    value_id = compile_constexpr_string(builder, "nil", 3);
                    break;
                }
                if (cast->statements->body.size == 1) {
                    return compile_defined_expression(builder, cast->statements->body.nodes[0]);
                }
            }
            value_id = compile_constexpr_string(builder, "expression", 10);
            break;
        }
        case PM_PARENTHESES_NODE: {
            const pm_parentheses_node_t *cast = (const pm_parentheses_node_t *) value;
            if (!cast->body) {
                value_id = compile_constexpr_string(builder, "nil", 3);
            } else if (PM_NODE_TYPE_P(cast->body, PM_STATEMENTS_NODE) && !PM_NODE_FLAG_P(value, PM_PARENTHESES_NODE_FLAGS_MULTIPLE_STATEMENTS)) {
                return compile_defined_expression(builder, ((const pm_statements_node_t *) cast->body)->body.nodes[0]);
            } else {
                value_id = compile_constexpr_string(builder, "expression", 10);
            }
            break;
        }
        case PM_IMPLICIT_NODE:
            return compile_defined_expression(builder, ((const pm_implicit_node_t *) value)->value);
        case PM_SHAREABLE_CONSTANT_NODE:
            return compile_defined_expression(builder, ((const pm_shareable_constant_node_t *) value)->write);
        case PM_FALSE_NODE:
            value_id = compile_constexpr_string(builder, "false", 5);
            break;
        case PM_TRUE_NODE:
            value_id = compile_constexpr_string(builder, "true", 4);
            break;
        case PM_NIL_NODE:
            value_id = compile_constexpr_string(builder, "nil", 3);
            break;
        case PM_SELF_NODE:
            value_id = compile_constexpr_string(builder, "self", 4);
            break;
        case PM_CALL_AND_WRITE_NODE:
        case PM_CALL_OPERATOR_WRITE_NODE:
        case PM_CALL_OR_WRITE_NODE:
        case PM_CLASS_VARIABLE_AND_WRITE_NODE:
        case PM_CLASS_VARIABLE_OPERATOR_WRITE_NODE:
        case PM_CLASS_VARIABLE_OR_WRITE_NODE:
        case PM_CLASS_VARIABLE_WRITE_NODE:
        case PM_CONSTANT_AND_WRITE_NODE:
        case PM_CONSTANT_OPERATOR_WRITE_NODE:
        case PM_CONSTANT_OR_WRITE_NODE:
        case PM_CONSTANT_PATH_AND_WRITE_NODE:
        case PM_CONSTANT_PATH_OPERATOR_WRITE_NODE:
        case PM_CONSTANT_PATH_OR_WRITE_NODE:
        case PM_CONSTANT_PATH_WRITE_NODE:
        case PM_CONSTANT_WRITE_NODE:
        case PM_GLOBAL_VARIABLE_AND_WRITE_NODE:
        case PM_GLOBAL_VARIABLE_OPERATOR_WRITE_NODE:
        case PM_GLOBAL_VARIABLE_OR_WRITE_NODE:
        case PM_GLOBAL_VARIABLE_WRITE_NODE:
        case PM_INDEX_AND_WRITE_NODE:
        case PM_INDEX_OPERATOR_WRITE_NODE:
        case PM_INDEX_OR_WRITE_NODE:
        case PM_INSTANCE_VARIABLE_AND_WRITE_NODE:
        case PM_INSTANCE_VARIABLE_OPERATOR_WRITE_NODE:
        case PM_INSTANCE_VARIABLE_OR_WRITE_NODE:
        case PM_INSTANCE_VARIABLE_WRITE_NODE:
        case PM_LOCAL_VARIABLE_AND_WRITE_NODE:
        case PM_LOCAL_VARIABLE_OPERATOR_WRITE_NODE:
        case PM_LOCAL_VARIABLE_OR_WRITE_NODE:
        case PM_LOCAL_VARIABLE_WRITE_NODE:
        case PM_MULTI_WRITE_NODE:
            value_id = compile_constexpr_string(builder, "assignment", 10);
            break;
        case PM_ALIAS_GLOBAL_VARIABLE_NODE:
        case PM_ALIAS_METHOD_NODE:
        case PM_AND_NODE:
        case PM_BREAK_NODE:
        case PM_CASE_MATCH_NODE:
        case PM_CASE_NODE:
        case PM_CLASS_NODE:
        case PM_DEF_NODE:
        case PM_DEFINED_NODE:
        case PM_FLIP_FLOP_NODE:
        case PM_FLOAT_NODE:
        case PM_FOR_NODE:
        case PM_IF_NODE:
        case PM_IMAGINARY_NODE:
        case PM_INTEGER_NODE:
        case PM_INTERPOLATED_MATCH_LAST_LINE_NODE:
        case PM_INTERPOLATED_REGULAR_EXPRESSION_NODE:
        case PM_INTERPOLATED_STRING_NODE:
        case PM_INTERPOLATED_SYMBOL_NODE:
        case PM_INTERPOLATED_X_STRING_NODE:
        case PM_LAMBDA_NODE:
        case PM_MATCH_LAST_LINE_NODE:
        case PM_MATCH_PREDICATE_NODE:
        case PM_MATCH_REQUIRED_NODE:
        case PM_MATCH_WRITE_NODE:
        case PM_MODULE_NODE:
        case PM_NEXT_NODE:
        case PM_OR_NODE:
        case PM_POST_EXECUTION_NODE:
        case PM_RANGE_NODE:
        case PM_RATIONAL_NODE:
        case PM_REDO_NODE:
        case PM_REGULAR_EXPRESSION_NODE:
        case PM_RESCUE_MODIFIER_NODE:
        case PM_RETRY_NODE:
        case PM_RETURN_NODE:
        case PM_SINGLETON_CLASS_NODE:
        case PM_SOURCE_ENCODING_NODE:
        case PM_SOURCE_FILE_NODE:
        case PM_SOURCE_LINE_NODE:
        case PM_STRING_NODE:
        case PM_SYMBOL_NODE:
        case PM_UNDEF_NODE:
        case PM_UNLESS_NODE:
        case PM_UNTIL_NODE:
        case PM_WHILE_NODE:
        case PM_X_STRING_NODE:
            value_id = compile_constexpr_string(builder, "expression", 10);
            break;
        /* unreachable (parameters) *******************************************/
        case PM_BLOCK_LOCAL_VARIABLE_NODE:
        case PM_BLOCK_PARAMETER_NODE:
        case PM_BLOCK_PARAMETERS_NODE:
        case PM_FORWARDING_PARAMETER_NODE:
        case PM_IMPLICIT_REST_NODE:
        case PM_IT_PARAMETERS_NODE:
        case PM_PARAMETERS_NODE:
        case PM_KEYWORD_REST_PARAMETER_NODE:
        case PM_NO_KEYWORDS_PARAMETER_NODE:
        case PM_NO_BLOCK_PARAMETER_NODE:
        case PM_NUMBERED_PARAMETERS_NODE:
        case PM_OPTIONAL_KEYWORD_PARAMETER_NODE:
        case PM_OPTIONAL_PARAMETER_NODE:
        case PM_REQUIRED_KEYWORD_PARAMETER_NODE:
        case PM_REQUIRED_PARAMETER_NODE:
        case PM_REST_PARAMETER_NODE:
        /* unreachable (pattern matching) *************************************/
        case PM_ALTERNATION_PATTERN_NODE:
        case PM_ARRAY_PATTERN_NODE:
        case PM_CAPTURE_PATTERN_NODE:
        case PM_FIND_PATTERN_NODE:
        case PM_HASH_PATTERN_NODE:
        case PM_PINNED_EXPRESSION_NODE:
        case PM_PINNED_VARIABLE_NODE:
        /* unreachable (indirect writes) **************************************/
        case PM_CALL_TARGET_NODE:
        case PM_CLASS_VARIABLE_TARGET_NODE:
        case PM_CONSTANT_PATH_TARGET_NODE:
        case PM_CONSTANT_TARGET_NODE:
        case PM_GLOBAL_VARIABLE_TARGET_NODE:
        case PM_INDEX_TARGET_NODE:
        case PM_INSTANCE_VARIABLE_TARGET_NODE:
        case PM_LOCAL_VARIABLE_TARGET_NODE:
        case PM_MULTI_TARGET_NODE:
        /* unreachable (clauses) **********************************************/
        case PM_ELSE_NODE:
        case PM_ENSURE_NODE:
        case PM_IN_NODE:
        case PM_RESCUE_NODE:
        case PM_WHEN_NODE:
        /* unreachable (miscellaneous) ****************************************/
        case PM_BLOCK_NODE:
        case PM_EMBEDDED_STATEMENTS_NODE:
        case PM_EMBEDDED_VARIABLE_NODE:
        case PM_ERROR_RECOVERY_NODE:
        case PM_PRE_EXECUTION_NODE:
        case PM_PROGRAM_NODE:
        case PM_SCOPE_NODE:
        case PM_STATEMENTS_NODE:
            fprintf(stderr, "Unreachable\n");
            abort();
    }

    return value_id;
}

static uint32_t
make_constant_name(PrismBuilder *builder, pm_constant_id_t name_id, const pm_constant_path_node_t *target) {
    if (!target) {
        const pm_constant_t *name = compile_constant(builder->parser, name_id);
        return make_object_string(builder, (const char *) name->start, name->length);
    }

    size_t capacity = target->base.location.length + 5;
    char *buffer = pm_arena_alloc(&builder->scratch, capacity, 1);
    char *end = buffer + capacity;
    char *cursor = end;
    const pm_node_t *current = PM_NODE_UPCAST(target);
    while (current && PM_NODE_TYPE_P(current, PM_CONSTANT_PATH_NODE)) {
        const pm_constant_path_node_t *path = (const pm_constant_path_node_t *) current;
        const pm_constant_t *name = compile_constant(builder->parser, path->name);
        cursor -= name->length;
        memcpy(cursor, name->start, name->length);
        cursor -= 2;
        memcpy(cursor, "::", 2);
        current = path->parent;
    }
    if (current) {
        if (PM_NODE_TYPE_P(current, PM_CONSTANT_READ_NODE)) {
            const pm_constant_t *name = compile_constant(builder->parser, ((const pm_constant_read_node_t *) current)->name);
            cursor -= name->length;
            memcpy(cursor, name->start, name->length);
        } else {
            cursor -= 3;
            memcpy(cursor, "...", 3);
        }
    }
    return make_object_string(builder, cursor, (size_t) (end - cursor));
}

/* UINT32_MAX means this expression must be evaluated at runtime. */
static uint32_t
shareable_literal(PrismBuilder *builder, const pm_node_t *node) {
    switch (PM_NODE_TYPE(node)) {
        case PM_ARRAY_NODE: {
            const pm_array_node_t *array = (const pm_array_node_t *) node;
            uint32_t *ids = pm_arena_alloc(builder->arena, array->elements.size * sizeof(uint32_t), PRISM_ALIGNOF(uint32_t));
            for (size_t idx = 0; idx < array->elements.size; ++idx) {
                ids[idx] = shareable_literal(builder, array->elements.nodes[idx]);
                if (ids[idx] == UINT32_MAX) return UINT32_MAX;
            }
            uint32_t object_id = make_object(builder, kPrismObjectArray);
            builder->unit->objects[object_id].as.array.nobject_ids = (uint32_t) array->elements.size;
            builder->unit->objects[object_id].as.array.object_ids = ids;
            return object_id;
        }
        case PM_HASH_NODE: {
            const pm_hash_node_t *hash = (const pm_hash_node_t *) node;
            uint32_t *ids = pm_arena_alloc(builder->arena, hash->elements.size * 2 * sizeof(uint32_t), PRISM_ALIGNOF(uint32_t));
            for (size_t idx = 0; idx < hash->elements.size; ++idx) {
                if (!PM_NODE_TYPE_P(hash->elements.nodes[idx], PM_ASSOC_NODE)) return UINT32_MAX;
                const pm_assoc_node_t *assoc = (const pm_assoc_node_t *) hash->elements.nodes[idx];
                ids[idx * 2] = shareable_literal(builder, assoc->key);
                ids[idx * 2 + 1] = shareable_literal(builder, assoc->value);
                if (ids[idx * 2] == UINT32_MAX || ids[idx * 2 + 1] == UINT32_MAX) return UINT32_MAX;
            }
            uint32_t object_id = make_object(builder, kPrismObjectHash);
            builder->unit->objects[object_id].as.hash.nobject_ids = (uint32_t) hash->elements.size * 2;
            builder->unit->objects[object_id].as.hash.object_ids = ids;
            return object_id;
        }
        case PM_FALSE_NODE:
        case PM_FLOAT_NODE:
        case PM_IMAGINARY_NODE:
        case PM_INTEGER_NODE:
        case PM_NIL_NODE:
        case PM_RATIONAL_NODE:
        case PM_REGULAR_EXPRESSION_NODE:
        case PM_SOURCE_ENCODING_NODE:
        case PM_SOURCE_LINE_NODE:
        case PM_STRING_NODE:
        case PM_SYMBOL_NODE:
        case PM_TRUE_NODE:
            return literal_value(builder, node);
        default:
            return UINT32_MAX;
    }
}

static uint32_t
compile_shareable_constant_value(PrismBuilder *builder, const pm_node_t *node, pm_node_flags_t shareability, uint32_t name_id, bool top) {
    uint32_t literal_id = shareable_literal(builder, node);
    if (literal_id != UINT32_MAX) {
        uint32_t value_id = emit_load_object(builder, node->node_id, literal_id);
        return emit_make_shareable(builder, node->node_id, value_id, false);
    }

    uint32_t value_id;
    switch (PM_NODE_TYPE(node)) {
        case PM_ARRAY_NODE: {
            const pm_array_node_t *array = (const pm_array_node_t *) node;
            uint32_t *ids = pm_arena_alloc(&builder->scratch, array->elements.size * sizeof(uint32_t), PRISM_ALIGNOF(uint32_t));
            for (size_t idx = 0; idx < array->elements.size; ++idx) {
                ids[idx] = compile_shareable_constant_value(builder, array->elements.nodes[idx], shareability, name_id, false);
            }
            value_id = emit_new_array(builder, node->node_id, (uint32_t) array->elements.size, ids);
            break;
        }
        case PM_HASH_NODE: {
            const pm_hash_node_t *hash = (const pm_hash_node_t *) node;
            value_id = UINT32_MAX;
            for (size_t idx = 0; idx < hash->elements.size; ++idx) {
                const pm_node_t *element = hash->elements.nodes[idx];
                uint32_t hash_id;
                if (PM_NODE_TYPE_P(element, PM_ASSOC_NODE)) {
                    const pm_assoc_node_t *assoc = (const pm_assoc_node_t *) element;
                    uint32_t ids[2];
                    ids[0] = compile_shareable_constant_value(builder, assoc->key, shareability, name_id, false);
                    ids[1] = compile_shareable_constant_value(builder, assoc->value, shareability, name_id, false);
                    hash_id = emit_new_hash(builder, element->node_id, 2, ids);
                } else {
                    uint32_t splat_id = compile_shareable_constant_value(builder, element, shareability, name_id, false);
                    hash_id = emit_coerce_hash(builder, element->node_id, splat_id);
                }
                value_id = value_id == UINT32_MAX ? hash_id : emit_merge_hash(builder, node->node_id, value_id, hash_id);
            }
            if (value_id == UINT32_MAX) value_id = emit_new_hash(builder, node->node_id, 0, NULL);
            break;
        }
        default:
            if (PM_NODE_TYPE_P(node, PM_ASSOC_SPLAT_NODE)) {
                const pm_assoc_splat_node_t *splat = (const pm_assoc_splat_node_t *) node;
                value_id = splat->value ? compile_node(builder, kPrismBuilderValue, splat->value) : emit_load_lvar(builder, node->node_id, builder->state.keyword_rest_local_id);
            } else {
                value_id = compile_node(builder, kPrismBuilderValue, node);
            }
            if (PM_NODE_TYPE_P(node, PM_INTERPOLATED_STRING_NODE)) {
                value_id = emit_call(builder, node->node_id, PM_CONSTANT_ID_UMINUS, value_id, 0, NULL, UINT32_MAX, false, false, 0, false);
            }
            if (shareability & PM_SHAREABLE_CONSTANT_NODE_FLAGS_LITERAL) {
                return emit_ensure_shareable(builder, node->node_id, value_id, name_id);
            }
            break;
    }

    return top ? emit_make_shareable(builder, node->node_id, value_id, (shareability & PM_SHAREABLE_CONSTANT_NODE_FLAGS_EXPERIMENTAL_COPY) != 0) : value_id;
}

static uint32_t
compile_constant_value(PrismBuilder *builder, const pm_node_t *value, pm_node_flags_t shareability, pm_constant_id_t name_id, const pm_constant_path_node_t *target) {
    if (!shareability) return compile_node(builder, kPrismBuilderValue, value);
    uint32_t path_id = make_constant_name(builder, name_id, target);
    return compile_shareable_constant_value(builder, value, shareability, path_id, true);
}

/******************************************************************************/

/*
 * alias $foo $bar
 * ^^^^^^^^^^^^^^^
 */
static uint32_t
compile_alias_global_variable_node(PrismBuilder *builder, PrismBuilderContext context, const pm_alias_global_variable_node_t *node) {
    pm_constant_id_t new_name = ((const pm_global_variable_read_node_t *) node->new_name)->name;
    pm_constant_id_t old_name;

    if (PM_NODE_TYPE_P(node->old_name, PM_BACK_REFERENCE_READ_NODE)) {
        old_name = ((const pm_back_reference_read_node_t *) node->old_name)->name;
    } else {
        old_name = ((const pm_global_variable_read_node_t *) node->old_name)->name;
    }

    uint32_t new_name_id = emit_load_object(builder, node->new_name->node_id, make_object_constant_id(builder, new_name));
    uint32_t old_name_id = emit_load_object(builder, node->old_name->node_id, make_object_constant_id(builder, old_name));

    emit_alias_gvar(builder, node->base.node_id, new_name_id, old_name_id);
    return context == kPrismBuilderValue ? emit_load_nil(builder, node->base.node_id) : UINT32_MAX;
}

/*
 * alias foo bar
 * ^^^^^^^^^^^^^
 */
static uint32_t
compile_alias_method_node(PrismBuilder *builder, PrismBuilderContext context, const pm_alias_method_node_t *node) {
    uint32_t new_name_id = compile_node(builder, kPrismBuilderValue, node->new_name);
    uint32_t old_name_id = compile_node(builder, kPrismBuilderValue, node->old_name);
    emit_alias_method(builder, node->base.node_id, new_name_id, old_name_id);
    return context == kPrismBuilderValue ? emit_load_nil(builder, node->base.node_id) : UINT32_MAX;
}

/*
 * a and b
 * ^^^^^^^
 */
static uint32_t
compile_and_node(PrismBuilder *builder, PrismBuilderContext context, const pm_and_node_t *node) {
    return compile_logical_node(builder, context, PM_NODE_UPCAST(node), node->left, node->right);
}

/*
 * [foo, bar, baz]
 * ^^^^^^^^^^^^^^^
 */
static uint32_t
compile_array_node(PrismBuilder *builder, PrismBuilderContext context, const pm_array_node_t *node) {
    size_t nelements = node->elements.size;

    if (context == kPrismBuilderEffect) {
        if (!PM_NODE_FLAG_P(node, PM_NODE_FLAG_STATIC_LITERAL)) {
            for (size_t idx = 0; idx < nelements; ++idx) {
                compile_node(builder, context, node->elements.nodes[idx]);
            }
        }
        return UINT32_MAX;
    }

    if (PM_NODE_FLAG_P(node, PM_NODE_FLAG_STATIC_LITERAL) && nelements) {
        uint32_t object_id = static_literal(builder, PM_NODE_UPCAST(node));
        return emit_new_array_static(builder, node->base.node_id, object_id);
    }

    uint32_t *element_ids = pm_arena_alloc(&builder->scratch, sizeof(uint32_t) * nelements, PRISM_ALIGNOF(uint32_t));
    uint32_t nelement_ids = 0;
    uint32_t array_id = UINT32_MAX;

    for (size_t idx = 0; idx < nelements; ++idx) {
        const pm_node_t *element = node->elements.nodes[idx];

        if (PM_NODE_TYPE_P(element, PM_SPLAT_NODE)) {
            if (array_id == UINT32_MAX || nelement_ids) {
                uint32_t elements_id = emit_new_array(builder, node->base.node_id, nelement_ids, element_ids);
                array_id = array_id == UINT32_MAX ? elements_id : emit_concat_array(builder, node->base.node_id, array_id, elements_id);
                nelement_ids = 0;
            }

            uint32_t rest_id = compile_node(builder, kPrismBuilderValue, element);
            array_id = emit_concat_array(builder, element->node_id, array_id, rest_id);
        } else {
            element_ids[nelement_ids++] = compile_node(builder, kPrismBuilderValue, element);
        }
    }

    if (array_id == UINT32_MAX) {
        return emit_new_array(builder, node->base.node_id, nelement_ids, element_ids);
    }

    if (nelement_ids) {
        uint32_t elements_id = emit_new_array(builder, node->base.node_id, nelement_ids, element_ids);
        array_id = emit_concat_array(builder, node->base.node_id, array_id, elements_id);
    }

    return array_id;
}

/*
 * [foo, *bar, baz]
 * ^^^^^^^^^^^^^^^^
 */
static void
compile_array_pattern_node(PrismBuilder *builder, const pm_array_pattern_node_t *node, uint32_t value_id, uint32_t root_id, uint32_t matched_block_id, PrismPatternFailure failure) {
    uint32_t node_id = node->base.node_id;
    if (node->constant) {
        compile_pattern_step(builder, node->constant, value_id, root_id, failure);
    }

    uint32_t array_id = compile_pattern_deconstruct(builder, node_id, value_id, root_id, failure);
    uint32_t nrequireds = (uint32_t) (node->requireds.size + node->posts.size);
    uint32_t minimum_id = compile_pattern_length(builder, node_id, array_id, root_id, nrequireds, node->rest != NULL, failure);

    for (size_t idx = 0; idx < node->requireds.size; ++idx) {
        uint32_t index_id = emit_load_integer(builder, node_id, (uint32_t) idx);
        uint32_t element_id = emit_call(builder, node_id, PM_CONSTANT_ID_AREF, array_id, 1, &index_id, UINT32_MAX, false, false, 0, false);
        compile_pattern_step(builder, node->requireds.nodes[idx], element_id, root_id, failure);
    }

    const pm_node_t *rest = node->rest && PM_NODE_TYPE_P(node->rest, PM_SPLAT_NODE) ? ((const pm_splat_node_t *) node->rest)->expression : NULL;
    uint32_t rest_size_id = UINT32_MAX;

    if (rest || node->posts.size) {
        uint32_t current_length_id = emit_call(builder, node_id, PM_CONSTANT_ID_LENGTH, array_id, 0, NULL, UINT32_MAX, false, false, 0, false);
        rest_size_id = emit_call(builder, node_id, PM_CONSTANT_ID_SUBTRACT, current_length_id, 1, &minimum_id, UINT32_MAX, false, false, 0, false);
    }

    if (rest) {
        uint32_t ids[] = { emit_load_integer(builder, node_id, (uint32_t) node->requireds.size), rest_size_id };
        uint32_t rest_id = emit_call(builder, node_id, PM_CONSTANT_ID_AREF, array_id, 2, ids, UINT32_MAX, false, false, 0, false);
        compile_pattern_step(builder, rest, rest_id, root_id, failure);
    }

    for (size_t idx = 0; idx < node->posts.size; ++idx) {
        uint32_t offset_id = emit_load_integer(builder, node_id, (uint32_t) (node->requireds.size + idx));
        uint32_t index_id = emit_call(builder, node_id, PM_CONSTANT_ID_ADD, offset_id, 1, &rest_size_id, UINT32_MAX, false, false, 0, false);
        uint32_t element_id = emit_call(builder, node_id, PM_CONSTANT_ID_AREF, array_id, 1, &index_id, UINT32_MAX, false, false, 0, false);
        compile_pattern_step(builder, node->posts.nodes[idx], element_id, root_id, failure);
    }

    emit_branch(builder, node_id, matched_block_id, 0, NULL);
}

/*
 * $+
 * ^^
 */
static uint32_t
compile_back_reference_read_node(PrismBuilder *builder, PrismBuilderContext context, const pm_back_reference_read_node_t *node) {
    if (context == kPrismBuilderEffect) return UINT32_MAX;

    const pm_constant_t *constant = compile_constant(builder->parser, node->name);
    uint32_t last_match_id = emit_load_last_match(builder, node->base.node_id);
    uint32_t value_id;

    switch (pm_constant_start(constant)[1]) {
        case '&':
            value_id = emit_load_last_match_match(builder, node->base.node_id, last_match_id);
            break;
        case '`':
            value_id = emit_load_last_match_pre(builder, node->base.node_id, last_match_id);
            break;
        case '\'':
            value_id = emit_load_last_match_post(builder, node->base.node_id, last_match_id);
            break;
        case '+':
            value_id = emit_load_last_match_paren(builder, node->base.node_id, last_match_id);
            break;
        default:
            assert(false && "unreachable");
            value_id = UINT32_MAX;
            break;
    }

    return value_id;
}

/*
 * begin end
 * ^^^^^^^^^
 */
static uint32_t
compile_begin_node(PrismBuilder *builder, PrismBuilderContext context, const pm_begin_node_t *node) {
    if (node->ensure_clause) {
        uint32_t node_id = node->base.node_id;
        uint32_t parent_id = builder->state.region_id;
        uint32_t nparams = context == kPrismBuilderValue;
        uint32_t join_block_id = make_block(builder, nparams);

        uint32_t handler_region_id = make_region(builder, kPrismRegionDefault, parent_id, UINT32_MAX, UINT32_MAX);
        builder->state.region_id = handler_region_id;
        uint32_t handler_block_id = make_block(builder, 0);
        PrismBuilder_graph(builder)->regions[handler_region_id].entry_block_id = handler_block_id;

        uint32_t region_id = make_region(builder, kPrismRegionEnsure, parent_id, UINT32_MAX, handler_block_id);
        builder->state.region_id = region_id;
        uint32_t body_block_id = make_block(builder, 0);
        PrismBuilder_graph(builder)->regions[region_id].entry_block_id = body_block_id;
        emit_branch(builder, node_id, body_block_id, 0, NULL);
        builder->state.block_id = body_block_id;

        uint32_t value_id = compile_begin_body(builder, context, node);
        emit_branch(builder, node_id, join_block_id, nparams, &value_id);

        builder->state.region_id = handler_region_id;
        builder->state.block_id = handler_block_id;
        if (node->ensure_clause->statements) {
            compile_node(builder, kPrismBuilderEffect, PM_NODE_UPCAST(node->ensure_clause->statements));
        }

        emit_ensure_return(builder, node_id, region_id);

        builder->state.region_id = parent_id;
        builder->state.block_id = join_block_id;
        return nparams ? PrismBuilder_graph(builder)->blocks[join_block_id].params[0] : UINT32_MAX;
    } else {
        return compile_begin_body(builder, context, node);
    }
}

/*
 * foo(&bar)
 *     ^^^^
 */
static uint32_t
compile_block_argument_node(PrismBuilder *builder, PrismBuilderContext context, const pm_block_argument_node_t *node) {
    PM_ASSERT_VALUE_CONTEXT(context);

    if (node->expression) {
        return compile_node(builder, kPrismBuilderValue, node->expression);
    } else {
        return emit_load_lvar(builder, node->base.node_id, builder->state.block_local_id);
    }
}

static uint32_t
compile_block_node(PrismBuilder *builder, PrismBuilderContext context, const pm_block_node_t *node) {
    PM_ASSERT_VALUE_CONTEXT(context);

    return compile_closure(builder, PM_NODE_UPCAST(node), kPrismGraphBlock, node->parameters, node->body, &node->locals);
}

/*
 * break foo
 * ^^^^^^^^^
 */
static uint32_t
compile_break_node(PrismBuilder *builder, const pm_break_node_t *node) {
    uint32_t value_id = compile_jump_arguments(builder, node->base.node_id, node->arguments);

    if (builder->state.break_block_id != UINT32_MAX) {
        emit_branch(builder, node->base.node_id, builder->state.break_block_id, 1, &value_id);
    } else {
        emit_trace_b_return(builder, node->base.node_id, value_id);

        if (PrismBuilder_graph(builder)->kind == kPrismGraphLambda) {
            emit_return(builder, node->base.node_id, value_id);
        } else {
            emit_break(builder, node->base.node_id, value_id);
        }
    }

    builder->state.block_id = make_block(builder, 0);
    return emit_load_nil(builder, node->base.node_id);
}

/*
 * foo.bar &&= baz
 * ^^^^^^^^^^^^^^^
 */
static uint32_t
compile_call_and_write_node(PrismBuilder *builder, const pm_call_and_write_node_t *node) {
    return compile_call_logical_write_node(builder, PM_NODE_UPCAST(node), node->receiver, node->read_name, node->write_name, node->value);
}

/*
 * foo.bar() {}
 * ^^^^^^^^^^^^
 */
static uint32_t
compile_call_node(PrismBuilder *builder, const pm_call_node_t *node) {
    uint32_t receiver_id;
    if (node->receiver) {
        receiver_id = compile_node(builder, kPrismBuilderValue, node->receiver);
    } else {
        receiver_id = emit_load_self(builder, node->base.node_id);
    }

    return compile_call_with_receiver(builder, node, receiver_id);
}

/*
 * foo.bar += baz
 * ^^^^^^^^^^^^^^^
 */
static uint32_t
compile_call_operator_write_node(PrismBuilder *builder, const pm_call_operator_write_node_t *node) {
    uint32_t receiver_id = node->receiver ? compile_node(builder, kPrismBuilderValue, node->receiver) : emit_load_self(builder, node->base.node_id);
    uint32_t join_block_id = UINT32_MAX;

    if (PM_NODE_FLAG_P(node, PM_CALL_NODE_FLAGS_SAFE_NAVIGATION)) {
        uint32_t call_block_id = make_block(builder, 0);
        join_block_id = make_block(builder, 1);
        uint32_t nil_id = emit_nil_p(builder, node->base.node_id, receiver_id);
        emit_branchif(builder, node->base.node_id, nil_id, join_block_id, 1, &receiver_id, call_block_id, 0, NULL);
        builder->state.block_id = call_block_id;
    }

    uint32_t current_id = emit_call(builder, node->base.node_id, node->read_name, receiver_id, 0, NULL, UINT32_MAX, false, false, node->base.flags & PM_CALL_NODE_FLAGS_IGNORE_VISIBILITY, false);
    uint32_t value_id = compile_node(builder, kPrismBuilderValue, node->value);
    uint32_t result_id = emit_call(builder, node->base.node_id, node->binary_operator, current_id, 1, &value_id, UINT32_MAX, false, false, 0, false);
    emit_call(builder, node->base.node_id, node->write_name, receiver_id, 1, &result_id, UINT32_MAX, false, false, node->base.flags & PM_CALL_NODE_FLAGS_IGNORE_VISIBILITY, false);

    if (join_block_id != UINT32_MAX) {
        emit_branch(builder, node->base.node_id, join_block_id, 1, &result_id);
        builder->state.block_id = join_block_id;
        result_id = PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
    }

    return result_id;
}

/*
 * foo.bar ||= baz
 * ^^^^^^^^^^^^^^^
 */
static uint32_t
compile_call_or_write_node(PrismBuilder *builder, const pm_call_or_write_node_t *node) {
    return compile_call_logical_write_node(builder, PM_NODE_UPCAST(node), node->receiver, node->read_name, node->write_name, node->value);
}

/*
 * case foo; in bar; end
 * ^^^^^^^^^^^^^^^^^^^^^
 */
static uint32_t
compile_case_match_node(PrismBuilder *builder, const pm_case_match_node_t *node) {
    uint32_t value_id = compile_node_or_nil(builder, kPrismBuilderValue, node->predicate, node->base.node_id);
    uint32_t join_block_id = make_block(builder, 1);
    bool single = node->conditions.size == 1 && !node->else_clause;

    for (size_t idx = 0; idx < node->conditions.size; ++idx) {
        const pm_in_node_t *condition = (const pm_in_node_t *) node->conditions.nodes[idx];
        const pm_node_t *pattern = condition->pattern;

        const pm_node_t *predicate = NULL;
        bool guard_if = true;

        switch (PM_NODE_TYPE(pattern)) {
            case PM_IF_NODE: {
                const pm_if_node_t *guard = (const pm_if_node_t *) pattern;
                pattern = guard->statements->body.nodes[0];
                predicate = guard->predicate;
                break;
            }
            case PM_UNLESS_NODE: {
                const pm_unless_node_t *guard = (const pm_unless_node_t *) pattern;
                pattern = guard->statements->body.nodes[0];
                predicate = guard->predicate;
                guard_if = false;
                break;
            }
            default:
                break;
        }

        uint32_t body_block_id = make_block(builder, 0);
        uint32_t next_block_id = single ? UINT32_MAX : make_block(builder, 0);
        uint32_t matched_block_id = predicate ? make_block(builder, 0) : body_block_id;

        PrismPatternFailure failure = { .block_id = next_block_id, .terminal = single };
        compile_pattern_match(builder, pattern, value_id, value_id, matched_block_id, failure);

        if (predicate) {
            builder->state.block_id = matched_block_id;
            uint32_t guard_id = compile_node(builder, kPrismBuilderValue, predicate);
            uint32_t failed_block_id = single ? make_block(builder, 0) : next_block_id;

            if (guard_if) {
                emit_branchif(builder, predicate->node_id, guard_id, body_block_id, 0, NULL, failed_block_id, 0, NULL);
            } else {
                emit_branchif(builder, predicate->node_id, guard_id, failed_block_id, 0, NULL, body_block_id, 0, NULL);
            }

            if (single) {
                builder->state.block_id = failed_block_id;
                emit_raise_pattern_guard(builder, node->base.node_id, value_id);
            }
        }

        builder->state.block_id = body_block_id;
        uint32_t result_id = compile_node_or_nil(builder, kPrismBuilderValue, PM_NODE_UPCAST(condition->statements), condition->base.node_id);
        emit_branch(builder, condition->base.node_id, join_block_id, 1, &result_id);

        if (!single) builder->state.block_id = next_block_id;
    }

    if (node->else_clause) {
        uint32_t result_id = compile_node(builder, kPrismBuilderValue, PM_NODE_UPCAST(node->else_clause));
        emit_branch(builder, node->base.node_id, join_block_id, 1, &result_id);
    } else if (!single) {
        emit_raise_pattern_nomatch(builder, node->base.node_id, value_id);
    }

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

/*
 * case foo; when bar; end
 * ^^^^^^^^^^^^^^^^^^^^^^^
 */
static uint32_t
compile_case_node(PrismBuilder *builder, const pm_case_node_t *node) {
    uint32_t predicate_id = node->predicate ? compile_node(builder, kPrismBuilderValue, node->predicate) : UINT32_MAX;
    uint32_t join_block_id = make_block(builder, 1);

    for (size_t index = 0; index < node->conditions.size; index++) {
        const pm_when_node_t *condition = (const pm_when_node_t *) node->conditions.nodes[index];
        uint32_t body_block_id = make_block(builder, 0);

        for (size_t condition_index = 0; condition_index < condition->conditions.size; condition_index++) {
            const pm_node_t *expression = condition->conditions.nodes[condition_index];
            uint32_t next_block_id = make_block(builder, 0);
            uint32_t condition_id = compile_node(builder, kPrismBuilderValue, expression);
            if (PM_NODE_TYPE_P(expression, PM_SPLAT_NODE)) {
                condition_id = node->predicate
                    ? emit_match_array(builder, expression->node_id, predicate_id, condition_id)
                    : emit_any_truthy(builder, expression->node_id, condition_id);
            } else if (node->predicate) {
                condition_id = emit_match(builder, expression->node_id, predicate_id, condition_id);
            }
            emit_branchif(builder, expression->node_id, condition_id, body_block_id, 0, NULL, next_block_id, 0, NULL);
            builder->state.block_id = next_block_id;
        }

        uint32_t next_block_id = builder->state.block_id;
        builder->state.block_id = body_block_id;
        uint32_t value_id = compile_node_or_nil(builder, kPrismBuilderValue, PM_NODE_UPCAST(condition->statements), condition->base.node_id);
        emit_branch(builder, condition->base.node_id, join_block_id, 1, &value_id);
        builder->state.block_id = next_block_id;
    }

    uint32_t value_id = compile_node_or_nil(builder, kPrismBuilderValue, PM_NODE_UPCAST(node->else_clause), node->base.node_id);
    emit_branch(builder, node->base.node_id, join_block_id, 1, &value_id);
    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

/*
 * class Foo; end
 * ^^^^^^^^^^^^^^
 */
static uint32_t
compile_class_node(PrismBuilder *builder, const pm_class_node_t *node) {
    uint32_t graph_id = make_graph(builder, kPrismGraphClass, UINT32_MAX, (uint32_t) node->locals.size);
    PrismBuilderState state = push_scope(builder, graph_id, NULL, NULL, &node->locals);

    emit_trace_class(builder, node->base.node_id);
    uint32_t value_id = compile_node_or_nil(builder, kPrismBuilderValue, node->body, node->base.node_id);

    emit_trace_end(builder, node->base.node_id);
    emit_return(builder, node->base.node_id, value_id);
    pop_scope(builder, state);

    uint32_t result_id;
    if (PM_NODE_TYPE_P(node->constant_path, PM_CONSTANT_READ_NODE)) {
        if (node->superclass) {
            uint32_t superclass_id = compile_node(builder, kPrismBuilderValue, node->superclass);
            result_id = emit_define_class_nest_rel_super(builder, node->base.node_id, node->name, superclass_id, graph_id);
        } else {
            result_id = emit_define_class_nest_rel(builder, node->base.node_id, node->name, graph_id);
        }
    } else {
        const pm_constant_path_node_t *constant_path = (const pm_constant_path_node_t *) node->constant_path;

        if (constant_path->parent) {
            uint32_t receiver_id = compile_node(builder, kPrismBuilderValue, constant_path->parent);

            if (node->superclass) {
                uint32_t superclass_id = compile_node(builder, kPrismBuilderValue, node->superclass);
                result_id = emit_define_class_recv_rel_super(builder, node->base.node_id, node->name, receiver_id, superclass_id, graph_id);
            } else {
                result_id = emit_define_class_recv_rel(builder, node->base.node_id, node->name, receiver_id, graph_id);
            }
        } else if (node->superclass) {
            uint32_t superclass_id = compile_node(builder, kPrismBuilderValue, node->superclass);
            result_id = emit_define_class_abs_super(builder, node->base.node_id, node->name, superclass_id, graph_id);
        } else {
            result_id = emit_define_class_abs(builder, node->base.node_id, node->name, graph_id);
        }
    }

    return result_id;
}

/*
 * @@foo &&= bar
 * ^^^^^^^^^^^^^
 */
static uint32_t
compile_class_variable_and_write_node(PrismBuilder *builder, const pm_class_variable_and_write_node_t *node) {
    uint32_t set_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    uint32_t predicate_id = emit_load_cvar(builder, node->base.node_id, node->name);
    emit_branchif(builder, node->base.node_id, predicate_id, set_block_id, 0, NULL, join_block_id, 1, &predicate_id);

    builder->state.block_id = set_block_id;
    uint32_t value_id = compile_node(builder, kPrismBuilderValue, node->value);
    emit_store_cvar(builder, node->base.node_id, node->name, value_id);
    emit_branch(builder, node->base.node_id, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

/*
 * @@foo += bar
 * ^^^^^^^^^^^^
 */
static uint32_t
compile_class_variable_operator_write_node(PrismBuilder *builder, const pm_class_variable_operator_write_node_t *node) {
    uint32_t receiver_id = emit_load_cvar(builder, node->base.node_id, node->name);
    uint32_t value_id = compile_node(builder, kPrismBuilderValue, node->value);
    uint32_t result_id = emit_call(builder, node->base.node_id, node->binary_operator, receiver_id, 1, &value_id, UINT32_MAX, false, false, 0, false);
    emit_store_cvar(builder, node->base.node_id, node->name, result_id);
    return result_id;
}

/*
 * @@foo ||= bar
 * ^^^^^^^^^^^^^
 */
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
    uint32_t value_id = compile_node(builder, kPrismBuilderValue, node->value);
    emit_store_cvar(builder, node->base.node_id, node->name, value_id);
    emit_branch(builder, node->base.node_id, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

/*
 * @@foo
 * ^^^^^
 */
static uint32_t
compile_class_variable_read_node(PrismBuilder *builder, const pm_class_variable_read_node_t *node) {
    return emit_load_cvar(builder, node->base.node_id, node->name);
}

/*
 * @@foo = 1
 * ^^^^^^^^^
 */
static uint32_t
compile_class_variable_write_node(PrismBuilder *builder, const pm_class_variable_write_node_t *node) {
    uint32_t value_id = compile_node(builder, kPrismBuilderValue, node->value);
    emit_store_cvar(builder, node->base.node_id, node->name, value_id);
    return value_id;
}

/*
 * Foo &&= bar
 * ^^^^^^^^^^^
 */
static uint32_t
compile_constant_and_write_node(PrismBuilder *builder, const pm_constant_and_write_node_t *node, pm_node_flags_t shareability) {
    uint32_t set_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    PrismConstantPath constant_path = PrismConstantPath_new(builder, 1);
    PrismConstantPath_set(&constant_path, 0, node->name);
    uint32_t current_id = emit_load_const_nest_rel(builder, node->base.node_id, constant_path);

    emit_branchif(builder, node->base.node_id, current_id, set_block_id, 0, NULL, join_block_id, 1, &current_id);

    builder->state.block_id = set_block_id;
    uint32_t value_id = compile_constant_value(builder, node->value, shareability, node->name, NULL);
    emit_store_const_nest_rel(builder, node->base.node_id, node->name, value_id);
    emit_branch(builder, node->base.node_id, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

/*
 * Foo += bar
 * ^^^^^^^^^^
 */
static uint32_t
compile_constant_operator_write_node(PrismBuilder *builder, const pm_constant_operator_write_node_t *node, pm_node_flags_t shareability) {
    PrismConstantPath constant_path = PrismConstantPath_new(builder, 1);
    PrismConstantPath_set(&constant_path, 0, node->name);

    uint32_t receiver_id = emit_load_const_nest_rel(builder, node->base.node_id, constant_path);
    uint32_t value_id = compile_constant_value(builder, node->value, shareability, node->name, NULL);
    uint32_t result_id = emit_call(builder, node->base.node_id, node->binary_operator, receiver_id, 1, &value_id, UINT32_MAX, false, false, 0, false);
    emit_store_const_nest_rel(builder, node->base.node_id, node->name, result_id);

    return result_id;
}

/*
 * Foo ||= bar
 * ^^^^^^^^^^^
 */
static uint32_t
compile_constant_or_write_node(PrismBuilder *builder, const pm_constant_or_write_node_t *node, pm_node_flags_t shareability) {
    uint32_t read_block_id = make_block(builder, 0);
    uint32_t set_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    uint32_t defined_id = emit_defined_const_nest_rel(builder, node->base.node_id, node->name);
    emit_branchif(builder, node->base.node_id, defined_id, read_block_id, 0, NULL, set_block_id, 0, NULL);

    builder->state.block_id = read_block_id;
    PrismConstantPath constant_path = PrismConstantPath_new(builder, 1);
    PrismConstantPath_set(&constant_path, 0, node->name);
    uint32_t current_id = emit_load_const_nest_rel(builder, node->base.node_id, constant_path);

    emit_branchif(builder, node->base.node_id, current_id, join_block_id, 1, &current_id, set_block_id, 0, NULL);

    builder->state.block_id = set_block_id;
    uint32_t value_id = compile_constant_value(builder, node->value, shareability, node->name, NULL);
    emit_store_const_nest_rel(builder, node->base.node_id, node->name, value_id);
    emit_branch(builder, node->base.node_id, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

/*
 * Foo::Bar &&= baz
 * ^^^^^^^^^^^^^^^^
 */
static uint32_t
compile_constant_path_and_write_node(PrismBuilder *builder, const pm_constant_path_and_write_node_t *node, pm_node_flags_t shareability) {
    uint32_t parent_id = node->target->parent ? compile_node(builder, kPrismBuilderValue, node->target->parent) : UINT32_MAX;
    uint32_t set_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    PrismConstantPath constant_path = PrismConstantPath_new(builder, 1);
    PrismConstantPath_set(&constant_path, 0, node->target->name);
    uint32_t current_id;
    if (node->target->parent) {
        current_id = emit_load_const_recv_rel(builder, node->base.node_id, parent_id, constant_path);
    } else {
        current_id = emit_load_const_abs(builder, node->base.node_id, constant_path);
    }

    emit_branchif(builder, node->base.node_id, current_id, set_block_id, 0, NULL, join_block_id, 1, &current_id);

    builder->state.block_id = set_block_id;
    uint32_t value_id = compile_constant_value(builder, node->value, shareability, node->target->name, node->target);
    if (node->target->parent) {
        emit_store_const_recv_rel(builder, node->base.node_id, parent_id, node->target->name, value_id);
    } else {
        emit_store_const_abs(builder, node->base.node_id, node->target->name, value_id);
    }
    emit_branch(builder, node->base.node_id, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

/*
 * Foo::Bar
 * ^^^^^^^^
 */
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
        uint32_t receiver_id = compile_node(builder, kPrismBuilderValue, current);
        value_id = emit_load_const_recv_rel(builder, node->base.node_id, receiver_id, constant_path);
    }

    return value_id;
}

/*
 * Foo::Bar += baz
 * ^^^^^^^^^^^^^^^
 */
static uint32_t
compile_constant_path_operator_write_node(PrismBuilder *builder, const pm_constant_path_operator_write_node_t *node, pm_node_flags_t shareability) {
    PrismConstantPath constant_path = PrismConstantPath_new(builder, 1);
    PrismConstantPath_set(&constant_path, 0, (uint32_t) node->target->name);

    if (node->target->parent) {
        uint32_t parent_id = compile_node(builder, kPrismBuilderValue, node->target->parent);

        uint32_t receiver_id = emit_load_const_recv_rel(builder, node->base.node_id, parent_id, constant_path);
        uint32_t value_id = compile_constant_value(builder, node->value, shareability, node->target->name, node->target);
        uint32_t result_id = emit_call(builder, node->base.node_id, node->binary_operator, receiver_id, 1, &value_id, UINT32_MAX, false, false, 0, false);

        return emit_store_const_recv_rel(builder, node->base.node_id, parent_id, node->target->name, result_id);
    } else {
        uint32_t receiver_id = emit_load_const_abs(builder, node->base.node_id, constant_path);
        uint32_t value_id = compile_constant_value(builder, node->value, shareability, node->target->name, node->target);
        uint32_t result_id = emit_call(builder, node->base.node_id, node->binary_operator, receiver_id, 1, &value_id, UINT32_MAX, false, false, 0, false);

        return emit_store_const_abs(builder, node->base.node_id, node->target->name, result_id);
    }
}

/*
 * Foo::Bar ||= baz
 * ^^^^^^^^^^^^^^^^
 */
static uint32_t
compile_constant_path_or_write_node(PrismBuilder *builder, const pm_constant_path_or_write_node_t *node, pm_node_flags_t shareability) {
    uint32_t parent_id = node->target->parent ? compile_node(builder, kPrismBuilderValue, node->target->parent) : UINT32_MAX;
    uint32_t read_block_id = make_block(builder, 0);
    uint32_t set_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    uint32_t defined_id;
    if (node->target->parent) {
        defined_id = emit_defined_const_recv_rel(builder, node->base.node_id, node->target->name, parent_id);
    } else {
        defined_id = emit_defined_const_abs(builder, node->base.node_id, node->target->name);
    }
    emit_branchif(builder, node->base.node_id, defined_id, read_block_id, 0, NULL, set_block_id, 0, NULL);

    builder->state.block_id = read_block_id;
    PrismConstantPath constant_path = PrismConstantPath_new(builder, 1);
    PrismConstantPath_set(&constant_path, 0, node->target->name);
    uint32_t current_id;
    if (node->target->parent) {
        current_id = emit_load_const_recv_rel(builder, node->base.node_id, parent_id, constant_path);
    } else {
        current_id = emit_load_const_abs(builder, node->base.node_id, constant_path);
    }

    emit_branchif(builder, node->base.node_id, current_id, join_block_id, 1, &current_id, set_block_id, 0, NULL);

    builder->state.block_id = set_block_id;
    uint32_t value_id = compile_constant_value(builder, node->value, shareability, node->target->name, node->target);
    if (node->target->parent) {
        emit_store_const_recv_rel(builder, node->base.node_id, parent_id, node->target->name, value_id);
    } else {
        emit_store_const_abs(builder, node->base.node_id, node->target->name, value_id);
    }
    emit_branch(builder, node->base.node_id, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

/*
 * Foo::Bar = 1
 * ^^^^^^^^^^^^
 */
static uint32_t
compile_constant_path_write_node(PrismBuilder *builder, const pm_constant_path_write_node_t *node, pm_node_flags_t shareability) {
    if (node->target->parent) {
        uint32_t receiver_id = compile_node(builder, kPrismBuilderValue, node->target->parent);
        uint32_t value_id = compile_constant_value(builder, node->value, shareability, node->target->name, node->target);

        return emit_store_const_recv_rel(builder, node->base.node_id, receiver_id, node->target->name, value_id);
    } else {
        uint32_t value_id = compile_constant_value(builder, node->value, shareability, node->target->name, node->target);
        return emit_store_const_abs(builder, node->base.node_id, node->target->name, value_id);
    }
}

/*
 * Foo
 * ^^^
 */
static uint32_t
compile_constant_read_node(PrismBuilder *builder, const pm_constant_read_node_t *node) {
    PrismConstantPath constant_path = PrismConstantPath_new(builder, 1);
    PrismConstantPath_set(&constant_path, 0, node->name);
    return emit_load_const_nest_rel(builder, node->base.node_id, constant_path);
}

/*
 * Foo = 1
 * ^^^^^^^
 */
static uint32_t
compile_constant_write_node(PrismBuilder *builder, const pm_constant_write_node_t *node, pm_node_flags_t shareability) {
    uint32_t value_id = compile_constant_value(builder, node->value, shareability, node->name, NULL);
    emit_store_const_nest_rel(builder, node->base.node_id, node->name, value_id);
    return value_id;
}

/*
 * def foo; end
 * ^^^^^^^^^^^^
 */
static uint32_t
compile_def_node(PrismBuilder *builder, const pm_def_node_t *node) {
    uint32_t graph_id = make_graph(builder, kPrismGraphDef, UINT32_MAX, (uint32_t) node->locals.size + parameters_locals(node->parameters));

    PrismSignature signature;
    compile_parameters_signature(builder, graph_id, &signature, node->parameters);

    PrismBuilderState state = push_scope(builder, graph_id, &signature, node->parameters, &node->locals);

    const pm_parameters_node_t *parameters = node->parameters;
    if (parameters) {
        compile_parameters(builder, parameters, &signature);
    }

    emit_trace_call(builder, node->base.node_id);
    uint32_t value_id = compile_node_or_nil(builder, kPrismBuilderValue, node->body, node->base.node_id);

    emit_trace_return(builder, node->base.node_id, value_id);
    emit_return(builder, node->base.node_id, value_id);

    pop_scope(builder, state);

    if (node->receiver) {
        uint32_t receiver_id = compile_node(builder, kPrismBuilderValue, node->receiver);
        emit_define_singleton_method(builder, node->base.node_id, node->name, receiver_id, graph_id);
    } else {
        emit_define_method(builder, node->base.node_id, node->name, graph_id);
    }

    uint32_t object_id = make_object_constant_id(builder, node->name);
    return emit_load_object(builder, node->base.node_id, object_id);
}

/*
 * defined?(a)
 * ^^^^^^^^^^^
 */
static uint32_t
compile_defined_node(PrismBuilder *builder, const pm_defined_node_t *node) {
    return compile_defined_expression(builder, node->value);
}

/*
 * if foo then bar else baz end
 *                 ^^^^^^^^^^^^
 */
static uint32_t
compile_else_node(PrismBuilder *builder, PrismBuilderContext context, const pm_else_node_t *node) {
    return compile_node_or_nil(builder, context, PM_NODE_UPCAST(node->statements), node->base.node_id);
}

/*
 * "foo #{bar}"
 *      ^^^^^^
 */
static uint32_t
compile_embedded_statements_node(PrismBuilder *builder, const pm_embedded_statements_node_t *node) {
    uint32_t string_id = compile_node_or_nil(builder, kPrismBuilderValue, PM_NODE_UPCAST(node->statements), node->base.node_id);
    return emit_coerce_string(builder, node->base.node_id, string_id);
}

/*
 * "foo #@bar"
 *      ^^^^^
 */
static uint32_t
compile_embedded_variable_node(PrismBuilder *builder, const pm_embedded_variable_node_t *node) {
    uint32_t string_id = compile_node(builder, kPrismBuilderValue, node->variable);
    return emit_coerce_string(builder, node->base.node_id, string_id);
}

/*
 * false
 * ^^^^^
 */
static uint32_t
compile_false_node(PrismBuilder *builder, const pm_false_node_t *node) {
    return emit_load_false(builder, node->base.node_id);
}

/*
 * Find patterns search for consecutive requireds between two optional rest
 * captures: foo => [*left, 1, 2, *right].
 */
static void
compile_find_pattern_node(PrismBuilder *builder, const pm_find_pattern_node_t *node, uint32_t value_id, uint32_t root_id, uint32_t matched_block_id, PrismPatternFailure failure) {
    uint32_t node_id = node->base.node_id;
    if (node->constant) {
        compile_pattern_step(builder, node->constant, value_id, root_id, failure);
    }

    uint32_t array_id = compile_pattern_deconstruct(builder, node_id, value_id, root_id, failure);
    uint32_t nrequireds = (uint32_t) node->requireds.size;
    uint32_t requireds_id = compile_pattern_length(builder, node_id, array_id, root_id, nrequireds, true, failure);

    uint32_t length_id = emit_call(builder, node_id, PM_CONSTANT_ID_LENGTH, array_id, 0, NULL, UINT32_MAX, false, false, 0, false);
    uint32_t limit_id = emit_call(builder, node_id, PM_CONSTANT_ID_SUBTRACT, length_id, 1, &requireds_id, UINT32_MAX, false, false, 0, false);
    uint32_t zero_id = emit_load_integer(builder, node_id, 0);
    uint32_t loop_block_id = make_block(builder, 1);
    uint32_t body_block_id = make_block(builder, 0);
    uint32_t next_block_id = make_block(builder, 0);
    uint32_t failed_block_id = failure.terminal ? make_block(builder, 0) : failure.block_id;
    emit_branch(builder, node_id, loop_block_id, 1, &zero_id);

    builder->state.block_id = loop_block_id;
    uint32_t index_id = PrismBuilder_graph(builder)->blocks[loop_block_id].params[0];
    uint32_t predicate_id = emit_call(builder, node_id, PM_CONSTANT_ID_LESS_EQUAL, index_id, 1, &limit_id, UINT32_MAX, false, false, 0, false);
    emit_branchif(builder, node_id, predicate_id, body_block_id, 0, NULL, failed_block_id, 0, NULL);

    builder->state.block_id = body_block_id;
    for (size_t idx = 0; idx < node->requireds.size; ++idx) {
        uint32_t offset_id = index_id;

        if (idx != 0) {
            uint32_t increment_id = emit_load_integer(builder, node_id, (uint32_t) idx);
            offset_id = emit_call(builder, node_id, PM_CONSTANT_ID_ADD, index_id, 1, &increment_id, UINT32_MAX, false, false, 0, false);
        }

        uint32_t element_id = emit_call(builder, node_id, PM_CONSTANT_ID_AREF, array_id, 1, &offset_id, UINT32_MAX, false, false, 0, false);
        compile_pattern_step(builder, node->requireds.nodes[idx], element_id, root_id, (PrismPatternFailure) { .block_id = next_block_id });
    }

    PrismPatternFailure rest_failure = { .block_id = failed_block_id };
    if (node->left->expression) {
        uint32_t ids[] = { zero_id, index_id };
        uint32_t left_id = emit_call(builder, node_id, PM_CONSTANT_ID_AREF, array_id, 2, ids, UINT32_MAX, false, false, 0, false);
        compile_pattern_step(builder, node->left->expression, left_id, root_id, rest_failure);
    }

    if (node->right->expression) {
        uint32_t start_id = emit_call(builder, node_id, PM_CONSTANT_ID_ADD, index_id, 1, &requireds_id, UINT32_MAX, false, false, 0, false);
        uint32_t ids[] = { start_id, limit_id };
        uint32_t right_id = emit_call(builder, node_id, PM_CONSTANT_ID_AREF, array_id, 2, ids, UINT32_MAX, false, false, 0, false);
        compile_pattern_step(builder, node->right->expression, right_id, root_id, rest_failure);
    }

    emit_branch(builder, node_id, matched_block_id, 0, NULL);

    builder->state.block_id = next_block_id;
    uint32_t one_id = emit_load_integer(builder, node_id, 1);
    uint32_t next_id = emit_call(builder, node_id, PM_CONSTANT_ID_ADD, index_id, 1, &one_id, UINT32_MAX, false, false, 0, false);
    emit_branch(builder, node_id, loop_block_id, 1, &next_id);

    if (failure.terminal) {
        builder->state.block_id = failed_block_id;
        emit_raise_pattern_find(builder, node_id, root_id, array_id);
    }
}

/*
 * if foo .. bar; end
 *    ^^^^^^^^^^
 */
static uint32_t
compile_flip_flop_node(PrismBuilder *builder, const pm_flip_flop_node_t *node) {
    uint32_t index = make_flip_flop(builder);
    uint32_t left_block_id = make_block(builder, 0);
    uint32_t right_block_id = make_block(builder, 0);
    uint32_t activate_block_id = make_block(builder, 0);
    uint32_t deactivate_block_id = make_block(builder, 0);
    uint32_t true_block_id = make_block(builder, 0);
    uint32_t false_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    uint32_t state_id = emit_load_flip_flop(builder, node->base.node_id, index);
    emit_branchif(builder, node->base.node_id, state_id, right_block_id, 0, NULL, left_block_id, 0, NULL);

    builder->state.block_id = left_block_id;
    uint32_t left_id = compile_flip_flop_bound(builder, node->left, node->base.node_id);
    emit_branchif(builder, node->base.node_id, left_id, activate_block_id, 0, NULL, false_block_id, 0, NULL);

    builder->state.block_id = activate_block_id;
    uint32_t active_id = emit_load_true(builder, node->base.node_id);
    emit_store_flip_flop(builder, node->base.node_id, index, active_id);
    emit_branch(builder, node->base.node_id, PM_NODE_FLAG_P(node, PM_RANGE_FLAGS_EXCLUDE_END) ? true_block_id : right_block_id, 0, NULL);

    builder->state.block_id = right_block_id;
    uint32_t right_id = compile_flip_flop_bound(builder, node->right, node->base.node_id);
    emit_branchif(builder, node->base.node_id, right_id, deactivate_block_id, 0, NULL, true_block_id, 0, NULL);

    builder->state.block_id = deactivate_block_id;
    uint32_t inactive_id = emit_load_false(builder, node->base.node_id);
    emit_store_flip_flop(builder, node->base.node_id, index, inactive_id);
    emit_branch(builder, node->base.node_id, true_block_id, 0, NULL);

    builder->state.block_id = true_block_id;
    uint32_t true_id = emit_load_true(builder, node->base.node_id);
    emit_branch(builder, node->base.node_id, join_block_id, 1, &true_id);

    builder->state.block_id = false_block_id;
    uint32_t false_id = emit_load_false(builder, node->base.node_id);
    emit_branch(builder, node->base.node_id, join_block_id, 1, &false_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

/*
 * 1.0
 * ^^^
 */
static uint32_t
compile_float_node(PrismBuilder *builder, const pm_float_node_t *node) {
    uint32_t object_id = static_literal(builder, PM_NODE_UPCAST(node));
    return emit_load_object(builder, node->base.node_id, object_id);
}

/*
 * for foo in bar do end
 * ^^^^^^^^^^^^^^^^^^^^^
 */
static uint32_t
compile_for_node(PrismBuilder *builder, const pm_for_node_t *node) {
    uint32_t collection_id = compile_node(builder, kPrismBuilderValue, node->collection);
    uint32_t graph_id = make_graph(builder, kPrismGraphBlock, builder->state.graph_id, 0);
    bool multi_target = PM_NODE_TYPE_P(node->index, PM_MULTI_TARGET_NODE) || PM_NODE_TYPE_P(node->index, PM_SPLAT_NODE);

    PrismSignature signature;
    make_signature(builder, graph_id, &signature, multi_target ? 0 : 1, 0, multi_target, 0);
    PrismBuilderState state = push_scope(builder, graph_id, &signature, NULL, NULL);
    uint32_t param_id = multi_target ? signature.rest_id : signature.required_ids[0];

    PrismTargetParents parents = { 0 };
    compile_target_node_parents(builder, node->index, &parents);

    if (multi_target) {
        pm_integer_t *one = pm_arena_alloc(builder->arena, sizeof(pm_integer_t), PRISM_ALIGNOF(pm_integer_t));
        *one = pm_integer_uint64(1);

        uint32_t length_id = emit_call(builder, node->base.node_id, PM_CONSTANT_ID_LENGTH, param_id, 0, NULL, UINT32_MAX, false, false, 0, false);
        uint32_t object_id = make_object(builder, kPrismObjectInteger);
        builder->unit->objects[object_id].as.integer.value = one;

        uint32_t one_id = emit_load_object(builder, node->base.node_id, object_id);
        uint32_t single_id = emit_call(builder, node->base.node_id, PM_CONSTANT_ID_EQUAL, length_id, 1, &one_id, UINT32_MAX, false, false, 0, false);
        uint32_t single_block_id = make_block(builder, 0);
        uint32_t join_block_id = make_block(builder, 1);
        emit_branchif(builder, node->base.node_id, single_id, single_block_id, 0, NULL, join_block_id, 1, &param_id);

        builder->state.block_id = single_block_id;
        uint32_t *first_id = emit_expand_array(builder, node->base.node_id, param_id, 1, 0, false);
        emit_branch(builder, node->base.node_id, join_block_id, 1, first_id);

        builder->state.block_id = join_block_id;
        param_id = PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
    }

    compile_target_node(builder, node->index, param_id, &parents);
    assert(parents.index == parents.size);

    compile_block_body(builder, node->base.node_id, PM_NODE_UPCAST(node->statements));
    pop_scope(builder, state);

    uint32_t block_id = emit_new_block(builder, node->base.node_id, graph_id);
    return emit_call(builder, node->base.node_id, PM_CONSTANT_ID_EACH, collection_id, 0, NULL, block_id, false, false, 0, false);
}

/*
 * super {}
 * ^^^^^^^^
 */
static uint32_t
compile_forwarding_super_node(PrismBuilder *builder, const pm_forwarding_super_node_t *node) {
    PrismArguments arguments = { .block_id = UINT32_MAX };
    const PrismGraph *method = builder->unit->graphs + PrismBuilder_graph(builder)->scope_id;

    while (method->kind == kPrismGraphBlock || method->kind == kPrismGraphLambda) {
        uint32_t parent_id = method->parent_id;
        method = builder->unit->graphs + builder->unit->graphs[parent_id].scope_id;
    }

    if (method->kind == kPrismGraphDef) {
        const PrismSignature *signature = &method->signature;
        uint32_t npositional_ids = signature->nrequired_ids + signature->noptional_ids;
        uint32_t nkeyword_ids = signature->nrequired_keyword_ids + signature->noptional_keyword_ids;
        uint32_t local_index = 0;

        arguments.ids = pm_arena_alloc(&builder->scratch, sizeof(uint32_t) * (npositional_ids + signature->npost_ids + 2), PRISM_ALIGNOF(uint32_t));

        if (npositional_ids) {
            for (uint32_t idx = 0; idx < npositional_ids; ++idx) {
                arguments.ids[idx] = emit_load_lvar(builder, node->base.node_id, method->local_ids[local_index++]);
            }
            compile_arguments_append(builder, node->base.node_id, &arguments, npositional_ids, arguments.ids);
        }

        if (signature->rest_id != UINT32_MAX) {
            uint32_t value_id = emit_load_lvar(builder, node->base.node_id, method->local_ids[local_index++]);
            uint32_t array_id = emit_coerce_array_to_a(builder, node->base.node_id, value_id);
            compile_arguments_splat(builder, node->base.node_id, &arguments, array_id);
        }

        if (signature->npost_ids) {
            for (uint32_t idx = 0; idx < signature->npost_ids; ++idx) {
                arguments.ids[arguments.size + idx] = emit_load_lvar(builder, node->base.node_id, method->local_ids[local_index++]);
            }
            compile_arguments_append(builder, node->base.node_id, &arguments, signature->npost_ids, arguments.ids + arguments.size);
        }

        uint32_t keyword_index = local_index;
        local_index += nkeyword_ids;

        uint32_t hash_id = UINT32_MAX;
        if (signature->keyword_rest_id != UINT32_MAX) {
            uint32_t value_id = emit_load_lvar(builder, node->base.node_id, method->local_ids[local_index]);
            hash_id = emit_coerce_hash(builder, node->base.node_id, value_id);
        }

        if (nkeyword_ids) {
            uint32_t *ids = pm_arena_alloc(&builder->scratch, sizeof(uint32_t) * nkeyword_ids * 2, PRISM_ALIGNOF(uint32_t));
            for (uint32_t idx = 0; idx < nkeyword_ids; ++idx) {
                pm_constant_id_t name_id = idx < signature->nrequired_keyword_ids ? signature->required_keyword_names[idx] : signature->optional_keyword_names[idx - signature->nrequired_keyword_ids];
                ids[2 * idx] = emit_load_object(builder, node->base.node_id, make_object_constant_id(builder, name_id));
                ids[2 * idx + 1] = emit_load_lvar(builder, node->base.node_id, method->local_ids[keyword_index + idx]);
            }
            uint32_t keywords_id = emit_new_hash(builder, node->base.node_id, nkeyword_ids * 2, ids);
            hash_id = hash_id == UINT32_MAX ? keywords_id : emit_merge_hash(builder, node->base.node_id, hash_id, keywords_id);
        }

        if (hash_id != UINT32_MAX) {
            arguments.ids[arguments.size++] = hash_id;
            arguments.keywords = true;
        }
    }

    if (node->block) {
        arguments.block_id = compile_node(builder, kPrismBuilderValue, PM_NODE_UPCAST(node->block));
    } else {
        arguments.block_id = emit_load_block(builder, node->base.node_id);
    }

    return emit_call_super(builder, node->base.node_id, &arguments);
}

/*
 * $foo &&= bar
 * ^^^^^^^^^^^^
 */
static uint32_t
compile_global_variable_and_write_node(PrismBuilder *builder, const pm_global_variable_and_write_node_t *node) {
    uint32_t set_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    uint32_t predicate_id = emit_load_gvar(builder, node->base.node_id, node->name);
    emit_branchif(builder, node->base.node_id, predicate_id, set_block_id, 0, NULL, join_block_id, 1, &predicate_id);

    builder->state.block_id = set_block_id;
    uint32_t value_id = compile_node(builder, kPrismBuilderValue, node->value);
    emit_store_gvar(builder, node->base.node_id, node->name, value_id);
    emit_branch(builder, node->base.node_id, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

/*
 * $foo += bar
 * ^^^^^^^^^^^
 */
static uint32_t
compile_global_variable_operator_write_node(PrismBuilder *builder, const pm_global_variable_operator_write_node_t *node) {
    uint32_t receiver_id = emit_load_gvar(builder, node->base.node_id, node->name);
    uint32_t value_id = compile_node(builder, kPrismBuilderValue, node->value);
    uint32_t result_id = emit_call(builder, node->base.node_id, node->binary_operator, receiver_id, 1, &value_id, UINT32_MAX, false, false, 0, false);
    emit_store_gvar(builder, node->base.node_id, node->name, result_id);
    return result_id;
}

/*
 * $foo ||= bar
 * ^^^^^^^^^^^^
 */
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
    uint32_t value_id = compile_node(builder, kPrismBuilderValue, node->value);
    emit_store_gvar(builder, node->base.node_id, node->name, value_id);
    emit_branch(builder, node->base.node_id, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

/*
 * $foo
 * ^^^^
 */
static uint32_t
compile_global_variable_read_node(PrismBuilder *builder, const pm_global_variable_read_node_t *node) {
    return emit_load_gvar(builder, node->base.node_id, node->name);
}

/*
 * $foo = 1
 * ^^^^^^^^
 */
static uint32_t
compile_global_variable_write_node(PrismBuilder *builder, const pm_global_variable_write_node_t *node) {
    uint32_t value_id = compile_node(builder, kPrismBuilderValue, node->value);
    emit_store_gvar(builder, node->base.node_id, node->name, value_id);
    return value_id;
}

/*
 * {}
 * ^^
 */
static uint32_t
compile_hash_node(PrismBuilder *builder, const pm_hash_node_t *node) {
    if (PM_NODE_FLAG_P(node, PM_NODE_FLAG_STATIC_LITERAL) && node->elements.size) {
        uint32_t object_id = static_literal(builder, PM_NODE_UPCAST(node));
        return emit_new_hash_static(builder, node->base.node_id, object_id);
    }

    return compile_hash_elements(builder, PM_NODE_UPCAST(node), &node->elements);
}

/*
 * foo => { a: 1, b: 2, **rest }
 *        ^^^^^^^^^^^^^^^^^^^^^^
 */
static void
compile_hash_pattern_node(PrismBuilder *builder, const pm_hash_pattern_node_t *node, uint32_t value_id, uint32_t root_id, uint32_t matched_block_id, PrismPatternFailure failure) {
    uint32_t node_id = node->base.node_id;
    bool has_rest = node->rest && !(PM_NODE_TYPE_P(node->rest, PM_ASSOC_SPLAT_NODE) && !((const pm_assoc_splat_node_t *) node->rest)->value);
    bool has_keys = node->elements.size || node->rest;

    if (node->constant) {
        compile_pattern_step(builder, node->constant, value_id, root_id, failure);
    }

    uint32_t *key_ids = node->elements.size ? pm_arena_alloc(&builder->scratch, sizeof(uint32_t) * node->elements.size, PRISM_ALIGNOF(uint32_t)) : NULL;
    for (size_t idx = 0; idx < node->elements.size; ++idx) {
        const pm_assoc_node_t *assoc = (const pm_assoc_node_t *) node->elements.nodes[idx];
        key_ids[idx] = compile_node(builder, kPrismBuilderValue, assoc->key);
    }

    uint32_t keys_id = has_keys && !has_rest ? emit_new_array(builder, node_id, (uint32_t) node->elements.size, key_ids) : emit_load_nil(builder, node_id);
    uint32_t hash_id = emit_deconstruct_hash(builder, node_id, value_id, keys_id);
    uint32_t deconstructed_block_id = make_block(builder, 0);

    if (failure.terminal) {
        uint32_t error_block_id = make_block(builder, 0);
        emit_branchif(builder, node_id, hash_id, deconstructed_block_id, 0, NULL, error_block_id, 0, NULL);
        builder->state.block_id = error_block_id;
        emit_raise_pattern_deconstruct_keys(builder, node_id, root_id, value_id);
    } else {
        emit_branchif(builder, node_id, hash_id, deconstructed_block_id, 0, NULL, failure.block_id, 0, NULL);
    }

    builder->state.block_id = deconstructed_block_id;
    if (has_rest) {
        hash_id = emit_call(builder, node_id, PM_CONSTANT_ID_DUP, hash_id, 0, NULL, UINT32_MAX, false, false, 0, false);
    }

    for (size_t idx = 0; idx < node->elements.size; ++idx) {
        uint32_t predicate_id = emit_call(builder, node_id, PM_CONSTANT_ID_KEY_P, hash_id, 1, &key_ids[idx], UINT32_MAX, false, false, 0, false);
        uint32_t next_block_id = make_block(builder, 0);

        if (failure.terminal) {
            uint32_t error_block_id = make_block(builder, 0);
            emit_branchif(builder, node_id, predicate_id, next_block_id, 0, NULL, error_block_id, 0, NULL);

            builder->state.block_id = error_block_id;
            emit_raise_pattern_key(builder, node_id, root_id, hash_id, key_ids[idx]);
        } else {
            emit_branchif(builder, node_id, predicate_id, next_block_id, 0, NULL, failure.block_id, 0, NULL);
        }

        builder->state.block_id = next_block_id;
    }

    for (size_t idx = 0; idx < node->elements.size; ++idx) {
        const pm_assoc_node_t *assoc = (const pm_assoc_node_t *) node->elements.nodes[idx];
        uint32_t element_id = emit_call(builder, node_id, has_rest ? PM_CONSTANT_ID_DELETE : PM_CONSTANT_ID_AREF, hash_id, 1, &key_ids[idx], UINT32_MAX, false, false, 0, false);

        compile_pattern_step(builder, assoc->value, element_id, root_id, failure);
    }

    if (!has_keys || (has_rest && PM_NODE_TYPE_P(node->rest, PM_NO_KEYWORDS_PARAMETER_NODE))) {
        uint32_t predicate_id = emit_call(builder, node_id, PM_CONSTANT_ID_EMPTY_P, hash_id, 0, NULL, UINT32_MAX, false, false, 0, false);

        if (failure.terminal) {
            uint32_t error_block_id = make_block(builder, 0);
            emit_branchif(builder, node_id, predicate_id, matched_block_id, 0, NULL, error_block_id, 0, NULL);
            builder->state.block_id = error_block_id;

            if (has_rest) {
                emit_raise_pattern_rest_empty(builder, node_id, root_id, hash_id);
            } else {
                emit_raise_pattern_empty(builder, node_id, root_id, hash_id);
            }
        } else {
            emit_branchif(builder, node_id, predicate_id, matched_block_id, 0, NULL, failure.block_id, 0, NULL);
        }
    } else if (has_rest) {
        compile_pattern_match(builder, ((const pm_assoc_splat_node_t *) node->rest)->value, hash_id, root_id, matched_block_id, failure);
    } else {
        emit_branch(builder, node_id, matched_block_id, 0, NULL);
    }
}

/*
 * if foo then bar end
 * ^^^^^^^^^^^^^^^^^^^
 */
static uint32_t
compile_if_node(PrismBuilder *builder, const pm_if_node_t *node) {
    return compile_conditional_node(builder, PM_NODE_UPCAST(node), node->predicate, node->statements, node->subsequent);
}

/*
 * 1i
 * ^^
 */
static uint32_t
compile_imaginary_node(PrismBuilder *builder, const pm_imaginary_node_t *node) {
    uint32_t object_id = static_literal(builder, PM_NODE_UPCAST(node));
    return emit_load_object(builder, node->base.node_id, object_id);
}

/*
 * { foo: }
 *   ^^^^
 */
static uint32_t
compile_implicit_node(PrismBuilder *builder, const pm_implicit_node_t *node) {
    return compile_node(builder, kPrismBuilderValue, node->value);
}

/*
 * foo[bar] &&= baz
 * ^^^^^^^^^^^^^^^^
 */
static uint32_t
compile_index_and_write_node(PrismBuilder *builder, const pm_index_and_write_node_t *node) {
    return compile_index_logical_write_node(builder, PM_NODE_UPCAST(node), node->receiver, node->arguments, PM_NODE_UPCAST(node->block), node->value);
}

/*
 * foo[bar] += baz
 * ^^^^^^^^^^^^^^^
 */
static uint32_t
compile_index_operator_write_node(PrismBuilder *builder, const pm_index_operator_write_node_t *node) {
    uint32_t receiver_id = compile_node(builder, kPrismBuilderValue, node->receiver);
    uint32_t join_block_id = UINT32_MAX;

    if (PM_NODE_FLAG_P(node, PM_CALL_NODE_FLAGS_SAFE_NAVIGATION)) {
        uint32_t call_block_id = make_block(builder, 0);
        join_block_id = make_block(builder, 1);
        uint32_t nil_id = emit_nil_p(builder, node->base.node_id, receiver_id);
        emit_branchif(builder, node->base.node_id, nil_id, join_block_id, 1, &receiver_id, call_block_id, 0, NULL);
        builder->state.block_id = call_block_id;
    }

    PrismArguments arguments = compile_arguments(builder, node->arguments, PM_NODE_UPCAST(node->block));
    uint32_t current_id = emit_call_arguments(builder, node->base.node_id, PM_CONSTANT_ID_AREF, receiver_id, &arguments, node->base.flags);
    uint32_t value_id = compile_node(builder, kPrismBuilderValue, node->value);
    uint32_t result_id = emit_call(builder, node->base.node_id, node->binary_operator, current_id, 1, &value_id, UINT32_MAX, false, false, 0, false);

    compile_index_write(builder, node->base.node_id, receiver_id, &arguments, result_id, node->base.flags);

    if (join_block_id != UINT32_MAX) {
        emit_branch(builder, node->base.node_id, join_block_id, 1, &result_id);
        builder->state.block_id = join_block_id;
        result_id = PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
    }

    return result_id;
}

/*
 * foo[bar] ||= baz
 * ^^^^^^^^^^^^^^^^
 */
static uint32_t
compile_index_or_write_node(PrismBuilder *builder, const pm_index_or_write_node_t *node) {
    return compile_index_logical_write_node(builder, PM_NODE_UPCAST(node), node->receiver, node->arguments, PM_NODE_UPCAST(node->block), node->value);
}

/*
 * @foo &&= bar
 * ^^^^^^^^^^^^
 */
static uint32_t
compile_instance_variable_and_write_node(PrismBuilder *builder, const pm_instance_variable_and_write_node_t *node) {
    return compile_instance_variable_logical_write_node(builder, PM_NODE_UPCAST(node), node->name, node->value);
}

/*
 * @foo += bar
 * ^^^^^^^^^^^
 */
static uint32_t
compile_instance_variable_operator_write_node(PrismBuilder *builder, const pm_instance_variable_operator_write_node_t *node) {
    uint32_t receiver_id = emit_load_ivar(builder, node->base.node_id, node->name);
    uint32_t value_id = compile_node(builder, kPrismBuilderValue, node->value);
    uint32_t result_id = emit_call(builder, node->base.node_id, node->binary_operator, receiver_id, 1, &value_id, UINT32_MAX, false, false, 0, false);
    emit_store_ivar(builder, node->base.node_id, node->name, result_id);
    return result_id;
}

/*
 * @foo ||= bar
 * ^^^^^^^^^^^^
 */
static uint32_t
compile_instance_variable_or_write_node(PrismBuilder *builder, const pm_instance_variable_or_write_node_t *node) {
    return compile_instance_variable_logical_write_node(builder, PM_NODE_UPCAST(node), node->name, node->value);
}

/*
 * @foo
 * ^^^^
 */
static uint32_t
compile_instance_variable_read_node(PrismBuilder *builder, const pm_instance_variable_read_node_t *node) {
    return emit_load_ivar(builder, node->base.node_id, node->name);
}

/*
 * @foo = 1
 * ^^^^^^^^
 */
static uint32_t
compile_instance_variable_write_node(PrismBuilder *builder, const pm_instance_variable_write_node_t *node) {
    uint32_t value_id = compile_node(builder, kPrismBuilderValue, node->value);
    emit_store_ivar(builder, node->base.node_id, node->name, value_id);
    return value_id;
}

/*
 * 1
 * ^
 */
static uint32_t
compile_integer_node(PrismBuilder *builder, const pm_integer_node_t *node) {
    uint32_t object_id = static_literal(builder, PM_NODE_UPCAST(node));
    return emit_load_object(builder, node->base.node_id, object_id);
}

/*
 * if /foo #{bar}/ then end
 *    ^^^^^^^^^^^^
 */
static uint32_t
compile_interpolated_match_last_line_node(PrismBuilder *builder, const pm_interpolated_match_last_line_node_t *node) {
    uint32_t regexp_id = compile_interpolated_regexp(builder, PM_NODE_UPCAST(node), &node->parts);
    uint32_t last_line_id = emit_load_gvar(builder, node->base.node_id, PM_CONSTANT_ID_LAST_LINE);
    return emit_call(builder, node->base.node_id, PM_CONSTANT_ID_MATCH, regexp_id, 1, &last_line_id, UINT32_MAX, false, false, 0, false);
}

/*
 * /foo #{bar}/
 * ^^^^^^^^^^^^
 */
static uint32_t
compile_interpolated_regular_expression_node(PrismBuilder *builder, const pm_interpolated_regular_expression_node_t *node) {
    return compile_interpolated_regexp(builder, PM_NODE_UPCAST(node), &node->parts);
}

/*
 * "foo #{bar}"
 * ^^^^^^^^^^^^
 */
static uint32_t
compile_interpolated_string_node(PrismBuilder *builder, const pm_interpolated_string_node_t *node) {
    uint32_t nvalue_ids = (uint32_t) node->parts.size;
    uint32_t *value_ids = pm_arena_alloc(builder->arena, nvalue_ids * sizeof(uint32_t), PRISM_ALIGNOF(uint32_t));

    for (uint32_t idx = 0; idx < nvalue_ids; ++idx) {
        value_ids[idx] = compile_node(builder, kPrismBuilderValue, node->parts.nodes[idx]);
    }

    return emit_new_string(builder, node->base.node_id, nvalue_ids, value_ids);
}

/*
 * :"foo #{bar}"
 * ^^^^^^^^^^^^^
 */
static uint32_t
compile_interpolated_symbol_node(PrismBuilder *builder, const pm_interpolated_symbol_node_t *node) {
    uint32_t nvalue_ids = (uint32_t) node->parts.size;
    uint32_t *value_ids = pm_arena_alloc(builder->arena, nvalue_ids * sizeof(uint32_t), PRISM_ALIGNOF(uint32_t));

    for (uint32_t idx = 0; idx < nvalue_ids; ++idx) {
        value_ids[idx] = compile_node(builder, kPrismBuilderValue, node->parts.nodes[idx]);
    }

    return emit_new_symbol(builder, node->base.node_id, nvalue_ids, value_ids);
}

/*
 * `foo #{bar}`
 * ^^^^^^^^^^^^
 */
static uint32_t
compile_interpolated_x_string_node(PrismBuilder *builder, const pm_interpolated_x_string_node_t *node) {
    uint32_t receiver_id = emit_load_self(builder, node->base.node_id);
    uint32_t nvalue_ids = (uint32_t) node->parts.size;
    uint32_t *value_ids = pm_arena_alloc(builder->arena, nvalue_ids * sizeof(uint32_t), PRISM_ALIGNOF(uint32_t));

    for (uint32_t idx = 0; idx < nvalue_ids; ++idx) {
        value_ids[idx] = compile_node(builder, kPrismBuilderValue, node->parts.nodes[idx]);
    }

    uint32_t string_id = emit_new_string(builder, node->base.node_id, nvalue_ids, value_ids);
    return emit_call(builder, node->base.node_id, PM_CONSTANT_ID_BACKTICK, receiver_id, 1, &string_id, UINT32_MAX, false, false, PM_CALL_NODE_FLAGS_IGNORE_VISIBILITY, false);
}

/*
 * -> { it }
 *      ^^
 */
static uint32_t
compile_it_local_variable_read_node(PrismBuilder *builder, const pm_it_local_variable_read_node_t *node) {
    return emit_load_lvar(builder, node->base.node_id, builder->state.it_local_id);
}

/*
 * foo(bar: baz)
 *     ^^^^^^^^
 */
static uint32_t
compile_keyword_hash_node(PrismBuilder *builder, const pm_node_t *node, const pm_keyword_hash_node_t *keyword_hash) {
    return compile_hash_elements(builder, node, &keyword_hash->elements);
}

/*
 * -> {}
 * ^^^^^
 */
static uint32_t
compile_lambda_node(PrismBuilder *builder, const pm_lambda_node_t *node) {
    return compile_closure(builder, PM_NODE_UPCAST(node), kPrismGraphLambda, node->parameters, node->body, &node->locals);
}

/*
 * foo &&= bar
 * ^^^^^^^^^^^
 */
static uint32_t
compile_local_variable_and_write_node(PrismBuilder *builder, const pm_local_variable_and_write_node_t *node) {
    return compile_local_variable_logical_write_node(builder, PM_NODE_UPCAST(node), node->name, node->depth, node->value);
}

/*
 * foo += bar
 * ^^^^^^^^^^
 */
static uint32_t
compile_local_variable_operator_write_node(PrismBuilder *builder, const pm_local_variable_operator_write_node_t *node) {
    uint32_t resolved_id = resolve_local(builder, node->name, node->depth);
    uint32_t local_id = emit_load_lvar(builder, node->base.node_id, resolved_id);
    uint32_t value_id = compile_node(builder, kPrismBuilderValue, node->value);
    uint32_t result_id = emit_call(builder, node->base.node_id, node->binary_operator, local_id, 1, &value_id, UINT32_MAX, false, false, 0, false);
    emit_store_lvar(builder, node->base.node_id, resolved_id, result_id);
    return result_id;
}

/*
 * foo ||= bar
 * ^^^^^^^^^^^
 */
static uint32_t
compile_local_variable_or_write_node(PrismBuilder *builder, const pm_local_variable_or_write_node_t *node) {
    return compile_local_variable_logical_write_node(builder, PM_NODE_UPCAST(node), node->name, node->depth, node->value);
}

/*
 * foo
 * ^^^
 */
static uint32_t
compile_local_variable_read_node(PrismBuilder *builder, const pm_local_variable_read_node_t *node) {
    uint32_t local_id = resolve_local(builder, node->name, node->depth);
    return emit_load_lvar(builder, node->base.node_id, local_id);
}

/*
 * foo = 1
 * ^^^^^^^
 */
static uint32_t
compile_local_variable_write_node(PrismBuilder *builder, const pm_local_variable_write_node_t *node) {
    uint32_t local_id = resolve_local(builder, node->name, node->depth);
    uint32_t value_id = compile_node(builder, kPrismBuilderValue, node->value);
    emit_store_lvar(builder, node->base.node_id, local_id, value_id);
    return value_id;
}

/*
 * if /foo/ then end
 *    ^^^^^
 */
static uint32_t
compile_match_last_line_node(PrismBuilder *builder, const pm_match_last_line_node_t *node) {
    uint32_t object_id = make_object(builder, kPrismObjectRegexp);
    PrismObject *object = builder->unit->objects + object_id;
    object->as.string.flags = node->base.flags;
    object->as.string.unescaped = &node->unescaped;

    uint32_t regexp_id = emit_load_object(builder, node->base.node_id, object_id);
    uint32_t last_line_id = emit_load_gvar(builder, node->base.node_id, PM_CONSTANT_ID_LAST_LINE);
    return emit_call(builder, node->base.node_id, PM_CONSTANT_ID_MATCH, regexp_id, 1, &last_line_id, UINT32_MAX, false, false, 0, false);
}

/*
 * foo in bar
 * ^^^^^^^^^^
 */
static uint32_t
compile_match_predicate_node(PrismBuilder *builder, const pm_match_predicate_node_t *node) {
    uint32_t value_id = compile_node(builder, kPrismBuilderValue, node->value);
    uint32_t matched_block_id = make_block(builder, 0);
    uint32_t unmatched_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);
    compile_pattern_match(builder, node->pattern, value_id, value_id, matched_block_id, (PrismPatternFailure) { .block_id = unmatched_block_id });

    builder->state.block_id = matched_block_id;
    uint32_t result_id = emit_load_true(builder, node->base.node_id);
    emit_branch(builder, node->base.node_id, join_block_id, 1, &result_id);

    builder->state.block_id = unmatched_block_id;
    result_id = emit_load_false(builder, node->base.node_id);
    emit_branch(builder, node->base.node_id, join_block_id, 1, &result_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

/*
 * foo => bar
 * ^^^^^^^^^^
 */
static uint32_t
compile_match_required_node(PrismBuilder *builder, const pm_match_required_node_t *node) {
    uint32_t value_id = compile_node(builder, kPrismBuilderValue, node->value);
    uint32_t matched_block_id = make_block(builder, 0);
    compile_pattern_match(builder, node->pattern, value_id, value_id, matched_block_id, (PrismPatternFailure) { .terminal = true });

    builder->state.block_id = matched_block_id;
    return emit_load_nil(builder, node->base.node_id);
}

/*
 * /(?<foo>foo)/ =~ bar
 * ^^^^^^^^^^^^^^^^^^^^
 */
static uint32_t
compile_match_write_node(PrismBuilder *builder, const pm_match_write_node_t *node) {
    uint32_t result_id = compile_node(builder, kPrismBuilderValue, PM_NODE_UPCAST(node->call));
    uint32_t last_match_id = emit_load_last_match(builder, node->base.node_id);

    for (size_t idx = 0; idx < node->targets.size; ++idx) {
        const pm_local_variable_target_node_t *target = (const pm_local_variable_target_node_t *) node->targets.nodes[idx];
        uint32_t local_id = resolve_local(builder, target->name, target->depth);
        uint32_t value_id = emit_load_last_match_named_group(builder, target->base.node_id, last_match_id, target->name);
        emit_store_lvar(builder, target->base.node_id, local_id, value_id);
    }

    return result_id;
}

/*
 * module Foo; end
 * ^^^^^^^^^^^^^^^
 */
static uint32_t
compile_module_node(PrismBuilder *builder, const pm_module_node_t *node) {
    uint32_t graph_id = make_graph(builder, kPrismGraphModule, UINT32_MAX, (uint32_t) node->locals.size);
    PrismBuilderState state = push_scope(builder, graph_id, NULL, NULL, &node->locals);

    emit_trace_class(builder, node->base.node_id);
    uint32_t value_id = compile_node_or_nil(builder, kPrismBuilderValue, node->body, node->base.node_id);
    emit_trace_end(builder, node->base.node_id);
    emit_return(builder, node->base.node_id, value_id);
    pop_scope(builder, state);

    if (PM_NODE_TYPE_P(node->constant_path, PM_CONSTANT_READ_NODE)) {
        return emit_define_module_nest_rel(builder, node->base.node_id, node->name, graph_id);
    }

    const pm_constant_path_node_t *constant_path = (const pm_constant_path_node_t *) node->constant_path;
    if (constant_path->parent) {
        uint32_t receiver_id = compile_node(builder, kPrismBuilderValue, constant_path->parent);
        return emit_define_module_recv_rel(builder, node->base.node_id, node->name, receiver_id, graph_id);
    }

    return emit_define_module_abs(builder, node->base.node_id, node->name, graph_id);
}

/*
 * foo, bar = baz
 * ^^^^^^^^^^^^^^
 */
static uint32_t
compile_multi_write_node(PrismBuilder *builder, const pm_multi_write_node_t *node) {
    PrismTargetParents parents = { 0 };
    compile_multi_target_parents(builder, &node->lefts, node->rest, &node->rights, &parents);
    uint32_t value_id = compile_node(builder, kPrismBuilderValue, node->value);
    compile_multi_target(builder, node->base.node_id, &node->lefts, node->rest, &node->rights, value_id, &parents);
    assert(parents.index == parents.size);
    return value_id;
}

/*
 * next foo
 * ^^^^^^^^
 */
static uint32_t
compile_next_node(PrismBuilder *builder, const pm_next_node_t *node) {
    uint32_t value_id = compile_jump_arguments(builder, node->base.node_id, node->arguments);
    if (builder->state.next_block_id != UINT32_MAX) {
        emit_branch(builder, node->base.node_id, builder->state.next_block_id, 0, NULL);
    } else {
        emit_trace_b_return(builder, node->base.node_id, value_id);
        emit_return(builder, node->base.node_id, value_id);
    }

    builder->state.block_id = make_block(builder, 0);
    return emit_load_nil(builder, node->base.node_id);
}

/*
 * nil
 * ^^^
 */
static uint32_t
compile_nil_node(PrismBuilder *builder, const pm_nil_node_t *node) {
    uint32_t object_id = make_object(builder, kPrismObjectNil);
    return emit_load_object(builder, node->base.node_id, object_id);
}

/*
 * $1
 * ^^
 */
static uint32_t
compile_numbered_reference_read_node(PrismBuilder *builder, const pm_numbered_reference_read_node_t *node) {
    uint32_t last_match_id = emit_load_last_match(builder, node->base.node_id);
    return emit_load_last_match_group(builder, node->base.node_id, last_match_id, node->number);
}

/*
 * a or b
 * ^^^^^^
 */
static uint32_t
compile_or_node(PrismBuilder *builder, const pm_or_node_t *node) {
    return compile_logical_node(builder, kPrismBuilderValue, PM_NODE_UPCAST(node), node->left, node->right);
}

/*
 * (1 + 2)
 * ^^^^^^^
 */
static uint32_t
compile_parentheses_node(PrismBuilder *builder, const pm_parentheses_node_t *node) {
    return compile_node_or_nil(builder, kPrismBuilderValue, node->body, node->base.node_id);
}

/*
 * END {}
 * ^^^^^^
 */
static uint32_t
compile_post_execution_node(PrismBuilder *builder, const pm_post_execution_node_t *node) {
    uint32_t graph_id = make_graph(builder, kPrismGraphPostExecution, builder->state.graph_id, 0);
    PrismBuilderState state = push_scope(builder, graph_id, NULL, NULL, NULL);
    uint32_t value_id = compile_node_or_nil(builder, kPrismBuilderValue, PM_NODE_UPCAST(node->statements), node->base.node_id);
    emit_return(builder, node->base.node_id, value_id);
    pop_scope(builder, state);

    PrismInsn *insn = emit_insn(builder, kPrismInsnPostExecution, node->base.node_id, 0, NULL);
    insn->as.post_execution.graph_id = graph_id;
    return emit_load_nil(builder, node->base.node_id);
}

static uint32_t
compile_program_node(PrismBuilder *builder, const pm_program_node_t *node) {
    uint32_t graph_id = make_graph(builder, kPrismGraphProgram, UINT32_MAX, (uint32_t) node->locals.size);
    PrismBuilderState state = push_scope(builder, graph_id, NULL, NULL, &node->locals);
    uint32_t value_id = compile_program_node_statements(builder, kPrismBuilderValue, node->statements, node->base.node_id);

    emit_return(builder, node->base.node_id, value_id);
    pop_scope(builder, state);
    return UINT32_MAX;
}

/*
 * 0..5
 * ^^^^
 */
static uint32_t
compile_range_node(PrismBuilder *builder, const pm_range_node_t *node) {
    if (PM_NODE_FLAG_P(node, PM_NODE_FLAG_STATIC_LITERAL)) {
        return emit_load_object(builder, node->base.node_id, static_literal(builder, PM_NODE_UPCAST(node)));
    } else {
        uint32_t left_id = compile_node_or_nil(builder, kPrismBuilderValue, node->left, node->base.node_id);
        uint32_t right_id = compile_node_or_nil(builder, kPrismBuilderValue, node->right, node->base.node_id);
        return emit_new_range(builder, PM_NODE_FLAG_P(node, PM_RANGE_FLAGS_EXCLUDE_END), node->base.node_id, left_id, right_id);
    }
}

/*
 * 1r
 * ^^
 */
static uint32_t
compile_rational_node(PrismBuilder *builder, const pm_rational_node_t *node) {
    uint32_t object_id = static_literal(builder, PM_NODE_UPCAST(node));
    return emit_load_object(builder, node->base.node_id, object_id);
}

/*
 * redo
 * ^^^^
 */
static uint32_t
compile_redo_node(PrismBuilder *builder, const pm_redo_node_t *node) {
    emit_branch(builder, node->base.node_id, builder->state.redo_block_id, 0, NULL);
    builder->state.block_id = make_block(builder, 0);
    return emit_load_nil(builder, node->base.node_id);
}

/*
 * /foo/
 * ^^^^^
 */
static uint32_t
compile_regular_expression_node(PrismBuilder *builder, const pm_regular_expression_node_t *node) {
    uint32_t object_id = make_object(builder, kPrismObjectRegexp);
    PrismObject *object = builder->unit->objects + object_id;

    object->as.string.flags = node->base.flags;
    object->as.string.unescaped = &node->unescaped;

    return emit_load_object(builder, node->base.node_id, object_id);
}

/*
 * foo rescue bar
 * ^^^^^^^^^^^^^^
 */
static uint32_t
compile_rescue_modifier_node(PrismBuilder *builder, const pm_rescue_modifier_node_t *node) {
    uint32_t node_id = node->base.node_id;
    uint32_t parent_id = builder->state.region_id;
    uint32_t retry_block_id = builder->state.retry_block_id;
    uint32_t join_block_id = make_block(builder, 1);

    PrismRescueRegion rescue = make_rescue_region(builder, node_id);
    uint32_t value_id = compile_node(builder, kPrismBuilderValue, node->expression);
    emit_branch(builder, node_id, join_block_id, 1, &value_id);

    builder->state.region_id = rescue.handler_region_id;
    builder->state.block_id = rescue.handler_block_id;
    uint32_t matched_block_id = make_block(builder, 0);
    uint32_t unmatched_block_id = make_block(builder, 0);
    uint32_t exception_id = PrismBuilder_graph(builder)->blocks[rescue.handler_block_id].params[0];
    uint32_t class_id = emit_load_object(builder, node_id, make_object(builder, kPrismObjectStandardError));
    uint32_t predicate_id = emit_rescue_match(builder, node_id, exception_id, class_id);
    emit_branchif(builder, node_id, predicate_id, matched_block_id, 0, NULL, unmatched_block_id, 0, NULL);

    builder->state.block_id = unmatched_block_id;
    emit_reraise(builder, node_id);

    builder->state.block_id = matched_block_id;
    builder->state.retry_block_id = rescue.body_block_id;
    emit_trace_rescue(builder, node_id);
    value_id = compile_node(builder, kPrismBuilderValue, node->rescue_expression);
    emit_branch(builder, node_id, join_block_id, 1, &value_id);

    builder->state.region_id = parent_id;
    builder->state.retry_block_id = retry_block_id;
    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

/*
 * retry
 * ^^^^^
 */
static uint32_t
compile_retry_node(PrismBuilder *builder, const pm_retry_node_t *node) {
    emit_branch(builder, node->base.node_id, builder->state.retry_block_id, 0, NULL);
    builder->state.block_id = make_block(builder, 0);
    return emit_load_nil(builder, node->base.node_id);
}

/*
 * return 1
 * ^^^^^^^^
 */
static uint32_t
compile_return_node(PrismBuilder *builder, const pm_return_node_t *node) {
    uint32_t value_id = compile_jump_arguments(builder, node->base.node_id, node->arguments);

    if (builder->unit->graphs[builder->state.graph_id].kind == kPrismGraphDef) {
        emit_trace_return(builder, node->base.node_id, value_id);
    } else if (builder->unit->graphs[builder->state.graph_id].kind == kPrismGraphLambda) {
        emit_trace_b_return(builder, node->base.node_id, value_id);
    }

    emit_return(builder, node->base.node_id, value_id);

    builder->state.block_id = make_block(builder, 0);
    return emit_load_nil(builder, node->base.node_id);
}

/*
 * self
 * ^^^^
 */
static uint32_t
compile_self_node(PrismBuilder *builder, const pm_self_node_t *node) {
    return emit_load_self(builder, node->base.node_id);
}

/*
 * A value that is being written to a constant that is being marked as
 * shared depending on the current lexical context.
 */
static uint32_t
compile_shareable_constant_node(PrismBuilder *builder, const pm_shareable_constant_node_t *node) {
    pm_node_flags_t shareability = node->base.flags & (PM_SHAREABLE_CONSTANT_NODE_FLAGS_LITERAL | PM_SHAREABLE_CONSTANT_NODE_FLAGS_EXPERIMENTAL_COPY | PM_SHAREABLE_CONSTANT_NODE_FLAGS_EXPERIMENTAL_EVERYTHING);
    switch (PM_NODE_TYPE(node->write)) {
        case PM_CONSTANT_AND_WRITE_NODE:
            return compile_constant_and_write_node(builder, (const pm_constant_and_write_node_t *) node->write, shareability);
        case PM_CONSTANT_OPERATOR_WRITE_NODE:
            return compile_constant_operator_write_node(builder, (const pm_constant_operator_write_node_t *) node->write, shareability);
        case PM_CONSTANT_OR_WRITE_NODE:
            return compile_constant_or_write_node(builder, (const pm_constant_or_write_node_t *) node->write, shareability);
        case PM_CONSTANT_PATH_AND_WRITE_NODE:
            return compile_constant_path_and_write_node(builder, (const pm_constant_path_and_write_node_t *) node->write, shareability);
        case PM_CONSTANT_PATH_OPERATOR_WRITE_NODE:
            return compile_constant_path_operator_write_node(builder, (const pm_constant_path_operator_write_node_t *) node->write, shareability);
        case PM_CONSTANT_PATH_OR_WRITE_NODE:
            return compile_constant_path_or_write_node(builder, (const pm_constant_path_or_write_node_t *) node->write, shareability);
        case PM_CONSTANT_PATH_WRITE_NODE:
            return compile_constant_path_write_node(builder, (const pm_constant_path_write_node_t *) node->write, shareability);
        case PM_CONSTANT_WRITE_NODE:
            return compile_constant_write_node(builder, (const pm_constant_write_node_t *) node->write, shareability);
        default:
            return compile_node(builder, kPrismBuilderValue, node->write);
    }
}

/*
 * class << self; end
 * ^^^^^^^^^^^^^^^^^^
 */
static uint32_t
compile_singleton_class_node(PrismBuilder *builder, const pm_singleton_class_node_t *node) {
    uint32_t graph_id = make_graph(builder, kPrismGraphSingletonClass, UINT32_MAX, (uint32_t) node->locals.size);
    PrismBuilderState state = push_scope(builder, graph_id, NULL, NULL, &node->locals);
    uint32_t value_id = compile_node_or_nil(builder, kPrismBuilderValue, node->body, node->base.node_id);

    emit_return(builder, node->base.node_id, value_id);
    pop_scope(builder, state);

    uint32_t receiver_id = compile_node(builder, kPrismBuilderValue, node->expression);
    return emit_define_singleton_class(builder, node->base.node_id, receiver_id, graph_id);
}

/*
 * __ENCODING__
 * ^^^^^^^^^^^^
 */
static uint32_t
compile_source_encoding_node(PrismBuilder *builder, const pm_source_encoding_node_t *node) {
    uint32_t object_id = make_object(builder, kPrismObjectEncoding);
    PrismObject *object = builder->unit->objects + object_id;

    object->as.encoding.name = builder->parser->encoding->name;

    return emit_load_object(builder, node->base.node_id, object_id);
}

/*
 * __FILE__
 * ^^^^^^^^
 */
static uint32_t
compile_source_file_node(PrismBuilder *builder, const pm_source_file_node_t *node) {
    uint32_t object_id = make_object(builder, kPrismObjectString);
    PrismObject *object = builder->unit->objects + object_id;
    object->as.string.flags = node->base.flags;
    object->as.string.unescaped = &node->filepath;
    return emit_load_object(builder, node->base.node_id, object_id);
}

/*
 * __LINE__
 * ^^^^^^^^
 */
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

/*
 * foo(*bar)
 *     ^^^^
 */
static uint32_t
compile_splat_node(PrismBuilder *builder, const pm_splat_node_t *node) {
    if (node->expression) {
        uint32_t value_id = compile_node(builder, kPrismBuilderValue, node->expression);
        return emit_coerce_array_to_a(builder, node->base.node_id, value_id);
    } else {
        return emit_load_lvar(builder, node->base.node_id, builder->state.rest_local_id);
    }
}

static uint32_t
compile_statements_node(PrismBuilder *builder, PrismBuilderContext context, const pm_statements_node_t *node) {
    uint32_t value_id;
    for (size_t idx = 0; idx < node->body.size; ++idx) {
        value_id = compile_node(builder, idx + 1 < node->body.size ? kPrismBuilderEffect : context, node->body.nodes[idx]);
    }

    return value_id;
}

/*
 * "foo"
 * ^^^^^
 */
static uint32_t
compile_string_node(PrismBuilder *builder, const pm_string_node_t *node) {
    uint32_t object_id = make_object(builder, kPrismObjectString);
    PrismObject *object = builder->unit->objects + object_id;

    object->as.string.flags = node->base.flags;
    object->as.string.unescaped = &node->unescaped;

    return emit_load_object(builder, node->base.node_id, object_id);
}

/*
 * super(foo)
 * ^^^^^^^^^^
 */
static uint32_t
compile_super_node(PrismBuilder *builder, const pm_super_node_t *node) {
    PrismArguments arguments = compile_arguments(builder, node->arguments, node->block);

    if (arguments.block_id == UINT32_MAX) {
        arguments.block_id = emit_load_block(builder, node->base.node_id);
    }

    return emit_call_super(builder, node->base.node_id, &arguments);
}


/*
 * :foo
 * ^^^^
 */
static uint32_t
compile_symbol_node(PrismBuilder *builder, const pm_symbol_node_t *node) {
    uint32_t object_id = make_object(builder, kPrismObjectSymbol);
    PrismObject *object = builder->unit->objects + object_id;

    object->as.string.flags = node->base.flags;
    object->as.string.unescaped = &node->unescaped;

    return emit_load_object(builder, node->base.node_id, object_id);
}

/*
 * true
 * ^^^^
 */
static uint32_t
compile_true_node(PrismBuilder *builder, const pm_true_node_t *node) {
    return emit_load_true(builder, node->base.node_id);
}

/*
 * undef foo
 * ^^^^^^^^^
 */
static uint32_t
compile_undef_node(PrismBuilder *builder, const pm_undef_node_t *node) {
    for (size_t idx = 0; idx < node->names.size; ++idx) {
        uint32_t name_id = compile_node(builder, kPrismBuilderValue, node->names.nodes[idx]);
        emit_undef_method(builder, node->base.node_id, name_id);
    }
    return emit_load_nil(builder, node->base.node_id);
}

/*
 * unless foo; bar end
 * ^^^^^^^^^^^^^^^^^^^
 */
static uint32_t
compile_unless_node(PrismBuilder *builder, const pm_unless_node_t *node) {
    return compile_conditional_node(builder, PM_NODE_UPCAST(node), node->predicate, node->statements, PM_NODE_UPCAST(node->else_clause));
}

/*
 * until foo; bar end
 * ^^^^^^^^^^^^^^^^^
 */
static uint32_t
compile_until_node(PrismBuilder *builder, const pm_until_node_t *node) {
    return compile_loop_node(builder, PM_NODE_UPCAST(node), node->predicate, node->statements);
}

/*
 * while foo; bar end
 * ^^^^^^^^^^^^^^^^^^
 */
static uint32_t
compile_while_node(PrismBuilder *builder, const pm_while_node_t *node) {
    return compile_loop_node(builder, PM_NODE_UPCAST(node), node->predicate, node->statements);
}

/*
 * `foo`
 * ^^^^^
 */
static uint32_t
compile_x_string_node(PrismBuilder *builder, const pm_x_string_node_t *node) {
    uint32_t object_id = make_object(builder, kPrismObjectString);
    PrismObject *object = builder->unit->objects + object_id;

    object->as.string.flags = node->base.flags;
    object->as.string.unescaped = &node->unescaped;

    uint32_t receiver_id = emit_load_self(builder, node->base.node_id);
    uint32_t argument_id = emit_load_object(builder, node->base.node_id, object_id);
    return emit_call(builder, node->base.node_id, PM_CONSTANT_ID_BACKTICK, receiver_id, 1, &argument_id, UINT32_MAX, false, false, PM_CALL_NODE_FLAGS_IGNORE_VISIBILITY, false);
}

/*
 * yield 1
 * ^^^^^^^
 */
static uint32_t
compile_yield_node(PrismBuilder *builder, const pm_yield_node_t *node) {
    PrismArguments arguments = compile_arguments(builder, node->arguments, NULL);
    PrismInsn *insn = make_insn(builder, kPrismInsnYield, node->base.node_id, 1 + (uint32_t) arguments.size);
    insn->as.call.splat = arguments.splat;
    insn->as.call.keywords = arguments.keywords;
    uint32_t value_id = make_value(builder);
    uint32_t *opnds = PrismBuilder_graph(builder)->opnds + insn->opnds_off;
    opnds[0] = value_id;
    if (arguments.size) memcpy(opnds + 1, arguments.ids, arguments.size * sizeof(uint32_t));

    return value_id;
}

static uint32_t
compile_node(PrismBuilder *builder, PrismBuilderContext context, const pm_node_t *node) {
    if (PM_NODE_FLAG_P(node, PM_NODE_FLAG_NEWLINE)) {
        int32_t lineno = pm_line_offset_list_line(&builder->parser->line_offsets, node->location.start, builder->parser->start_line);
        if (builder->state.lineno != lineno) {
            emit_trace_line(builder, node->node_id, lineno);
            builder->state.lineno = lineno;
        }
    }

    switch (PM_NODE_TYPE(node)) {
        case PM_ALIAS_GLOBAL_VARIABLE_NODE:
            return compile_alias_global_variable_node(builder, context, (const pm_alias_global_variable_node_t *) node);
        case PM_ALIAS_METHOD_NODE:
            return compile_alias_method_node(builder, context, (const pm_alias_method_node_t *) node);
        case PM_AND_NODE:
            return compile_and_node(builder, context, (const pm_and_node_t *) node);
        case PM_ARRAY_NODE:
            return compile_array_node(builder, context, (const pm_array_node_t *) node);
        case PM_BACK_REFERENCE_READ_NODE:
            return compile_back_reference_read_node(builder, context, (const pm_back_reference_read_node_t *) node);
        case PM_BEGIN_NODE:
            return compile_begin_node(builder, context, (const pm_begin_node_t *) node);
        case PM_BLOCK_ARGUMENT_NODE:
            return compile_block_argument_node(builder, context, (const pm_block_argument_node_t *) node);
        case PM_BLOCK_NODE:
            return compile_block_node(builder, context, (const pm_block_node_t *) node);
        case PM_BREAK_NODE:
            return compile_break_node(builder, (const pm_break_node_t *) node);
        case PM_CALL_AND_WRITE_NODE:
            return compile_call_and_write_node(builder, (const pm_call_and_write_node_t *) node);
        case PM_CALL_NODE:
            return compile_call_node(builder, (const pm_call_node_t *) node);
        case PM_CALL_OPERATOR_WRITE_NODE:
            return compile_call_operator_write_node(builder, (const pm_call_operator_write_node_t *) node);
        case PM_CALL_OR_WRITE_NODE:
            return compile_call_or_write_node(builder, (const pm_call_or_write_node_t *) node);
        case PM_CASE_MATCH_NODE:
            return compile_case_match_node(builder, (const pm_case_match_node_t *) node);
        case PM_CASE_NODE:
            return compile_case_node(builder, (const pm_case_node_t *) node);
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
            return compile_constant_write_node(builder, (const pm_constant_write_node_t *) node, 0);
        case PM_CONSTANT_AND_WRITE_NODE:
            return compile_constant_and_write_node(builder, (const pm_constant_and_write_node_t *) node, 0);
        case PM_CONSTANT_OR_WRITE_NODE:
            return compile_constant_or_write_node(builder, (const pm_constant_or_write_node_t *) node, 0);
        case PM_CONSTANT_OPERATOR_WRITE_NODE:
            return compile_constant_operator_write_node(builder, (const pm_constant_operator_write_node_t *) node, 0);
        case PM_CONSTANT_PATH_NODE:
            return compile_constant_path_node(builder, (const pm_constant_path_node_t *) node);
        case PM_CONSTANT_PATH_WRITE_NODE:
            return compile_constant_path_write_node(builder, (const pm_constant_path_write_node_t *) node, 0);
        case PM_CONSTANT_PATH_AND_WRITE_NODE:
            return compile_constant_path_and_write_node(builder, (const pm_constant_path_and_write_node_t *) node, 0);
        case PM_CONSTANT_PATH_OR_WRITE_NODE:
            return compile_constant_path_or_write_node(builder, (const pm_constant_path_or_write_node_t *) node, 0);
        case PM_CONSTANT_PATH_OPERATOR_WRITE_NODE:
            return compile_constant_path_operator_write_node(builder, (const pm_constant_path_operator_write_node_t *) node, 0);
        case PM_DEF_NODE:
            return compile_def_node(builder, (const pm_def_node_t *) node);
        case PM_DEFINED_NODE:
            return compile_defined_node(builder, (const pm_defined_node_t *) node);
        case PM_ELSE_NODE:
            return compile_else_node(builder, context, (const pm_else_node_t *) node);
        case PM_EMBEDDED_STATEMENTS_NODE:
            return compile_embedded_statements_node(builder, (const pm_embedded_statements_node_t *) node);
        case PM_EMBEDDED_VARIABLE_NODE:
            return compile_embedded_variable_node(builder, (const pm_embedded_variable_node_t *) node);
        case PM_FALSE_NODE:
            return compile_false_node(builder, (const pm_false_node_t *) node);
        case PM_FLIP_FLOP_NODE:
            return compile_flip_flop_node(builder, (const pm_flip_flop_node_t *) node);
        case PM_FLOAT_NODE:
            return compile_float_node(builder, (const pm_float_node_t *) node);
        case PM_FOR_NODE:
            return compile_for_node(builder, (const pm_for_node_t *) node);
        case PM_GLOBAL_VARIABLE_READ_NODE:
            return compile_global_variable_read_node(builder, (const pm_global_variable_read_node_t *) node);
        case PM_GLOBAL_VARIABLE_WRITE_NODE:
            return compile_global_variable_write_node(builder, (const pm_global_variable_write_node_t *) node);
        case PM_GLOBAL_VARIABLE_OPERATOR_WRITE_NODE:
            return compile_global_variable_operator_write_node(builder, (const pm_global_variable_operator_write_node_t *) node);
        case PM_FORWARDING_SUPER_NODE:
            return compile_forwarding_super_node(builder, (const pm_forwarding_super_node_t *) node);
        case PM_GLOBAL_VARIABLE_AND_WRITE_NODE:
            return compile_global_variable_and_write_node(builder, (const pm_global_variable_and_write_node_t *) node);
        case PM_GLOBAL_VARIABLE_OR_WRITE_NODE:
            return compile_global_variable_or_write_node(builder, (const pm_global_variable_or_write_node_t *) node);
        case PM_HASH_NODE:
            return compile_hash_node(builder, (const pm_hash_node_t *) node);
        case PM_IF_NODE:
            return compile_if_node(builder, (const pm_if_node_t *) node);
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
        case PM_INDEX_AND_WRITE_NODE:
            return compile_index_and_write_node(builder, (const pm_index_and_write_node_t *) node);
        case PM_INDEX_OPERATOR_WRITE_NODE:
            return compile_index_operator_write_node(builder, (const pm_index_operator_write_node_t *) node);
        case PM_INDEX_OR_WRITE_NODE:
            return compile_index_or_write_node(builder, (const pm_index_or_write_node_t *) node);
        case PM_INSTANCE_VARIABLE_AND_WRITE_NODE:
            return compile_instance_variable_and_write_node(builder, (const pm_instance_variable_and_write_node_t *) node);
        case PM_INSTANCE_VARIABLE_OR_WRITE_NODE:
            return compile_instance_variable_or_write_node(builder, (const pm_instance_variable_or_write_node_t *) node);
        case PM_INTEGER_NODE:
            return compile_integer_node(builder, (const pm_integer_node_t *) node);
        case PM_INTERPOLATED_MATCH_LAST_LINE_NODE:
            return compile_interpolated_match_last_line_node(builder, (const pm_interpolated_match_last_line_node_t *) node);
        case PM_INTERPOLATED_REGULAR_EXPRESSION_NODE:
            return compile_interpolated_regular_expression_node(builder, (const pm_interpolated_regular_expression_node_t *) node);
        case PM_INTERPOLATED_STRING_NODE:
            return compile_interpolated_string_node(builder, (const pm_interpolated_string_node_t *) node);
        case PM_INTERPOLATED_SYMBOL_NODE:
            return compile_interpolated_symbol_node(builder, (const pm_interpolated_symbol_node_t *) node);
        case PM_INTERPOLATED_X_STRING_NODE:
            return compile_interpolated_x_string_node(builder, (const pm_interpolated_x_string_node_t *) node);
        case PM_IT_LOCAL_VARIABLE_READ_NODE:
            return compile_it_local_variable_read_node(builder, (const pm_it_local_variable_read_node_t *) node);
        case PM_KEYWORD_HASH_NODE:
            return compile_keyword_hash_node(builder, node, (const pm_keyword_hash_node_t *) node);
        case PM_LAMBDA_NODE:
            return compile_lambda_node(builder, (const pm_lambda_node_t *) node);
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
        case PM_MATCH_LAST_LINE_NODE:
            return compile_match_last_line_node(builder, (const pm_match_last_line_node_t *) node);
        case PM_MATCH_PREDICATE_NODE:
            return compile_match_predicate_node(builder, (const pm_match_predicate_node_t *) node);
        case PM_MATCH_REQUIRED_NODE:
            return compile_match_required_node(builder, (const pm_match_required_node_t *) node);
        case PM_MATCH_WRITE_NODE:
            return compile_match_write_node(builder, (const pm_match_write_node_t *) node);
        case PM_MODULE_NODE:
            return compile_module_node(builder, (const pm_module_node_t *) node);
        case PM_MULTI_WRITE_NODE:
            return compile_multi_write_node(builder, (const pm_multi_write_node_t *) node);
        case PM_NEXT_NODE:
            return compile_next_node(builder, (const pm_next_node_t *) node);
        case PM_NIL_NODE:
            return compile_nil_node(builder, (const pm_nil_node_t *) node);
        case PM_NUMBERED_REFERENCE_READ_NODE:
            return compile_numbered_reference_read_node(builder, (const pm_numbered_reference_read_node_t *) node);
        case PM_OR_NODE:
            return compile_or_node(builder, (const pm_or_node_t *) node);
        case PM_PARENTHESES_NODE:
            return compile_parentheses_node(builder, (const pm_parentheses_node_t *) node);
        case PM_POST_EXECUTION_NODE:
            return compile_post_execution_node(builder, (const pm_post_execution_node_t *) node);
        case PM_PROGRAM_NODE:
            return compile_program_node(builder, (const pm_program_node_t *) node);
        case PM_RANGE_NODE:
            return compile_range_node(builder, (const pm_range_node_t *) node);
        case PM_RATIONAL_NODE:
            return compile_rational_node(builder, (const pm_rational_node_t *) node);
        case PM_REDO_NODE:
            return compile_redo_node(builder, (const pm_redo_node_t *) node);
        case PM_REGULAR_EXPRESSION_NODE:
            return compile_regular_expression_node(builder, (const pm_regular_expression_node_t *) node);
        case PM_RESCUE_MODIFIER_NODE:
            return compile_rescue_modifier_node(builder, (const pm_rescue_modifier_node_t *) node);
        case PM_RETRY_NODE:
            return compile_retry_node(builder, (const pm_retry_node_t *) node);
        case PM_RETURN_NODE:
            return compile_return_node(builder, (const pm_return_node_t *) node);
        case PM_SELF_NODE:
            return compile_self_node(builder, (const pm_self_node_t *) node);
        case PM_SHAREABLE_CONSTANT_NODE:
            return compile_shareable_constant_node(builder, (const pm_shareable_constant_node_t *) node);
        case PM_SINGLETON_CLASS_NODE:
            return compile_singleton_class_node(builder, (const pm_singleton_class_node_t *) node);
        case PM_SOURCE_ENCODING_NODE:
            return compile_source_encoding_node(builder, (const pm_source_encoding_node_t *) node);
        case PM_SOURCE_FILE_NODE:
            return compile_source_file_node(builder, (const pm_source_file_node_t *) node);
        case PM_SOURCE_LINE_NODE:
            return compile_source_line_node(builder, (const pm_source_line_node_t *) node);
        case PM_SPLAT_NODE:
            return compile_splat_node(builder, (const pm_splat_node_t *) node);
        case PM_STATEMENTS_NODE:
            return compile_statements_node(builder, context, (const pm_statements_node_t *) node);
        case PM_STRING_NODE:
            return compile_string_node(builder, (const pm_string_node_t *) node);
        case PM_SUPER_NODE:
            return compile_super_node(builder, (const pm_super_node_t *) node);
        case PM_SYMBOL_NODE:
            return compile_symbol_node(builder, (const pm_symbol_node_t *) node);
        case PM_TRUE_NODE:
            return compile_true_node(builder, (const pm_true_node_t *) node);
        case PM_UNDEF_NODE:
            return compile_undef_node(builder, (const pm_undef_node_t *) node);
        case PM_UNLESS_NODE:
            return compile_unless_node(builder, (const pm_unless_node_t *) node);
        case PM_UNTIL_NODE:
            return compile_until_node(builder, (const pm_until_node_t *) node);
        case PM_WHILE_NODE:
            return compile_while_node(builder, (const pm_while_node_t *) node);
        case PM_X_STRING_NODE:
            return compile_x_string_node(builder, (const pm_x_string_node_t *) node);
        case PM_YIELD_NODE:
            return compile_yield_node(builder, (const pm_yield_node_t *) node);
        case PM_ERROR_RECOVERY_NODE:
            fprintf(stderr, "Cannot compile syntax errors\n");
            abort();
        case PM_ALTERNATION_PATTERN_NODE:
        case PM_ARGUMENTS_NODE:
        case PM_ARRAY_PATTERN_NODE:
        case PM_ASSOC_NODE:
        case PM_ASSOC_SPLAT_NODE:
        case PM_BLOCK_LOCAL_VARIABLE_NODE:
        case PM_BLOCK_PARAMETER_NODE:
        case PM_BLOCK_PARAMETERS_NODE:
        case PM_CALL_TARGET_NODE:
        case PM_CAPTURE_PATTERN_NODE:
        case PM_CLASS_VARIABLE_TARGET_NODE:
        case PM_CONSTANT_PATH_TARGET_NODE:
        case PM_CONSTANT_TARGET_NODE:
        case PM_ENSURE_NODE:
        case PM_FIND_PATTERN_NODE:
        case PM_FORWARDING_ARGUMENTS_NODE:
        case PM_FORWARDING_PARAMETER_NODE:
        case PM_GLOBAL_VARIABLE_TARGET_NODE:
        case PM_HASH_PATTERN_NODE:
        case PM_IMPLICIT_REST_NODE:
        case PM_IN_NODE:
        case PM_INDEX_TARGET_NODE:
        case PM_INSTANCE_VARIABLE_TARGET_NODE:
        case PM_IT_PARAMETERS_NODE:
        case PM_KEYWORD_REST_PARAMETER_NODE:
        case PM_LOCAL_VARIABLE_TARGET_NODE:
        case PM_MULTI_TARGET_NODE:
        case PM_NO_BLOCK_PARAMETER_NODE:
        case PM_NO_KEYWORDS_PARAMETER_NODE:
        case PM_NUMBERED_PARAMETERS_NODE:
        case PM_OPTIONAL_KEYWORD_PARAMETER_NODE:
        case PM_OPTIONAL_PARAMETER_NODE:
        case PM_PARAMETERS_NODE:
        case PM_PINNED_EXPRESSION_NODE:
        case PM_PINNED_VARIABLE_NODE:
        case PM_PRE_EXECUTION_NODE:
        case PM_REQUIRED_KEYWORD_PARAMETER_NODE:
        case PM_REQUIRED_PARAMETER_NODE:
        case PM_RESCUE_NODE:
        case PM_REST_PARAMETER_NODE:
        case PM_SCOPE_NODE:
        case PM_WHEN_NODE:
            fprintf(stderr, "Handled elsewhere: %s\n", pm_node_type(node->type));
            abort();
    }
}

/******************************************************************************/

void
pm_compile(const pm_parser_t *parser, const pm_node_t *node, pm_arena_t *arena, PrismUnit *unit) {
    PrismBuilder builder = {
        .parser = parser,
        .arena = arena,
        .unit = unit,
        .state = {
            .graph_id = 0,
            .block_id = 0,
            .retry_block_id = UINT32_MAX,
            .break_block_id = UINT32_MAX,
            .next_block_id = UINT32_MAX,
            .redo_block_id = UINT32_MAX,
            .it_local_id = UINT32_MAX,
            .rest_local_id = UINT32_MAX,
            .keyword_rest_local_id = UINT32_MAX,
            .block_local_id = UINT32_MAX,
            .lineno = parser->start_line - 1
        }
    };

    uint32_t nparser_constants = (uint32_t) pm_parser_constants_size(parser);
    unit->nconstants = nparser_constants + nbuiltin_constants;
    unit->constants = pm_arena_alloc(arena, unit->nconstants * sizeof(pm_constant_t), PRISM_ALIGNOF(pm_constant_t));
    for (uint32_t index = 0; index < nparser_constants; ++index) {
        unit->constants[index] = *pm_parser_constant_at(parser, index);
    }
    memcpy(unit->constants + nparser_constants, builtin_constants, sizeof(builtin_constants));

    builder.bindings = pm_arena_zalloc(&builder.scratch, sizeof(uint32_t) * ((size_t) parser->constant_pool.size + 1), PRISM_ALIGNOF(uint32_t));
    compile_node(&builder, kPrismBuilderEffect, node);
    pm_arena_cleanup(&builder.scratch);
}
