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
static const pm_constant_t backtick_constant = { .start = (const uint8_t *) "`", .length = 1 };

static const pm_constant_t last_line_constant = { .start = (const uint8_t *) "$_", .length = 2 };
static const pm_constant_t match_constant = { .start = (const uint8_t *) "=~", .length = 2 };
static const pm_constant_t each_constant = { .start = (const uint8_t *) "each", .length = 4 };
static const pm_constant_t it_constant = { .start = (const uint8_t *) "it", .length = 2 };
static const pm_constant_t aset_constant = { .start = (const uint8_t *) "[]=", .length = 3 };

static const pm_constant_t *
compile_constant(const pm_parser_t *parser, pm_constant_id_t constant_id) {
    switch (constant_id) {
        case PM_CONSTANT_ID_BACKTICK:
            return &backtick_constant;
        case PM_CONSTANT_ID_LAST_LINE:
            return &last_line_constant;
        case PM_CONSTANT_ID_MATCH:
            return &match_constant;
        case PM_CONSTANT_ID_EACH:
            return &each_constant;
        case PM_CONSTANT_ID_IT:
            return &it_constant;
        case PM_CONSTANT_ID_ASET:
            return &aset_constant;
        default:
            return pm_parser_constant(parser, constant_id);
    }
}

typedef struct {
    uint32_t graph_id;
    uint32_t block_id;
    uint32_t it_local_id;
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

const pm_constant_t *
pm_signature_required_keyword_name(const pm_parser_t *parser, const PrismSignature *signature, uint32_t keyword_idx) {
    assert(keyword_idx < signature->nrequired_keyword_ids);
    return compile_constant(parser, signature->required_keyword_names[keyword_idx]);
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

const pm_constant_t *
pm_signature_optional_keyword_name(const pm_parser_t *parser, const PrismSignature *signature, uint32_t keyword_idx) {
    assert(keyword_idx < signature->noptional_keyword_ids);
    return compile_constant(parser, signature->optional_keyword_names[keyword_idx]);
}

uint32_t
pm_signature_keyword_rest_id(const PrismSignature *signature) {
    return signature->keyword_rest_id;
}

bool
pm_signature_no_keywords(const PrismSignature *signature) {
    return signature->no_keywords;
}

bool
pm_signature_autosplat(const PrismSignature *signature) {
    return signature->autosplat;
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
pm_insn_call_keywords(const PrismInsn *insn) {
    return insn->as.call.keywords;
}

const pm_constant_t *
pm_insn_call_name(const pm_parser_t *parser, const PrismInsn *insn) {
    return compile_constant(parser, insn->as.call.name_id);
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
pm_insn_new_block_graph_id(const PrismInsn *insn) {
    return insn->as.new_block.graph_id;
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
    unit->graphs[graph_id] = (PrismGraph) {
        .signature = {
            .rest_id = UINT32_MAX,
            .keyword_rest_id = UINT32_MAX
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
    bool has_rest = parameters && parameters->rest && PM_NODE_TYPE_P(parameters->rest, PM_REST_PARAMETER_NODE);

    make_signature(builder, graph_id, signature, nrequired_ids, noptional_ids, has_rest, npost_ids);
    signature->no_keywords = parameters && parameters->keyword_rest && PM_NODE_TYPE_P(parameters->keyword_rest, PM_NO_KEYWORDS_PARAMETER_NODE);

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
    if (parameters && parameters->keyword_rest && PM_NODE_TYPE_P(parameters->keyword_rest, PM_KEYWORD_REST_PARAMETER_NODE)) {
        signature->keyword_rest_id = builder->unit->graphs[graph_id].value_id++;
    }
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
            (signature->keyword_rest_id != UINT32_MAX ? 1 : 0)
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
                block->params[idx] = signature->keyword_rest_id;
            }
        }
    }

    return block_id;
}

static PrismBuilderState
push_scope(PrismBuilder *builder, uint32_t graph_id, const PrismSignature *signature, const pm_constant_id_list_t *locals) {
    PrismBuilderState state = builder->state;

    builder->state = (PrismBuilderState) {
        .graph_id = graph_id,
        .it_local_id = locals == NULL ? state.it_local_id : UINT32_MAX,
        .lineno = builder->parser->start_line - 1,
        .locals = locals
    };

    builder->state.block_id = make_entry_block(builder, signature);

    PrismGraph *graph = PrismBuilder_graph(builder);
    if (signature) graph->signature = *signature;

    if (locals == NULL) {
        uint32_t scope_id = builder->unit->graphs[state.graph_id].scope_id;
        builder->unit->graphs[graph_id].scope_id = scope_id;
    }

    if (locals && locals->size) {
        uint32_t *shadowed = pm_arena_alloc(&builder->scratch, sizeof(uint32_t) * locals->size, PRISM_ALIGNOF(uint32_t));

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
emit_call(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t receiver_id, size_t nargument_ids, uint32_t *argument_ids, bool keywords) {
    PrismInsn *insn = make_insn(builder, kPrismInsnCall, node_id, 2 + (uint32_t) nargument_ids);
    insn->as.call.name_id = name_id;
    insn->as.call.keywords = keywords;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;
    graph->opnds[insn->opnds_off + 1] = receiver_id;
    memcpy(graph->opnds + insn->opnds_off + 2, argument_ids, sizeof(uint32_t) * nargument_ids);

    return value_id;
}

static uint32_t
emit_call_with_block(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t receiver_id, size_t nargument_ids, uint32_t *argument_ids, uint32_t block_id, bool keywords) {
    PrismInsn *insn = make_insn(builder, kPrismInsnCallWithBlock, node_id, 3 + (uint32_t) nargument_ids);
    insn->as.call.name_id = name_id;
    insn->as.call.keywords = keywords;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;
    graph->opnds[insn->opnds_off + 1] = receiver_id;
    memcpy(graph->opnds + insn->opnds_off + 2, argument_ids, sizeof(uint32_t) * nargument_ids);
    graph->opnds[insn->opnds_off + 2 + nargument_ids] = block_id;

    return value_id;
}

static uint32_t
emit_coerce_array(PrismBuilder *builder, uint32_t node_id, uint32_t value_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnCoerceArray, node_id, 2);
    uint32_t array_id = make_value(builder);

    PrismGraph *graph = PrismBuilder_graph(builder);
    graph->opnds[insn->opnds_off] = array_id;
    graph->opnds[insn->opnds_off + 1] = value_id;

    return array_id;
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

static uint32_t
emit_define_module_abs(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t graph_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnDefineModuleAbs, node_id, 1);
    insn->as.define.name_id = name_id;
    insn->as.define.graph_id = graph_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_define_module_nest_rel(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t graph_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnDefineModuleNestRel, node_id, 1);
    insn->as.define.name_id = name_id;
    insn->as.define.graph_id = graph_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_define_module_recv_rel(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t receiver_id, uint32_t graph_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnDefineModuleRecvRel, node_id, 2);
    insn->as.define.name_id = name_id;
    insn->as.define.graph_id = graph_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;
    graph->opnds[insn->opnds_off + 1] = receiver_id;

    return value_id;
}

static void
emit_define_method(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t graph_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnDefineMethod, node_id, 0);
    insn->as.define.name_id = name_id;
    insn->as.define.graph_id = graph_id;
}

static uint32_t
emit_define_singleton_class(PrismBuilder *builder, uint32_t node_id, uint32_t receiver_id, uint32_t graph_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnDefineSingletonClass, node_id, 2);
    insn->as.define_singleton_class.graph_id = graph_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;
    graph->opnds[insn->opnds_off + 1] = receiver_id;

    return value_id;
}

static void
emit_define_singleton_method(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t receiver_id, uint32_t graph_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnDefineSingletonMethod, node_id, 1);
    insn->as.define.name_id = name_id;
    insn->as.define.graph_id = graph_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    graph->opnds[insn->opnds_off] = receiver_id;
}

static uint32_t
emit_defined_const_abs(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnDefinedConstAbs, node_id, 1);
    insn->as.name.name_id = name_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_defined_const_nest_rel(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnDefinedConstNestRel, node_id, 1);
    insn->as.name.name_id = name_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;

    return value_id;
}

static uint32_t
emit_defined_const_recv_rel(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name_id, uint32_t parent_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnDefinedConstRecvRel, node_id, 2);
    insn->as.name.name_id = name_id;

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t value_id = make_value(builder);
    graph->opnds[insn->opnds_off] = value_id;
    graph->opnds[insn->opnds_off + 1] = parent_id;

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

static uint32_t *
emit_expand_array(PrismBuilder *builder, uint32_t node_id, uint32_t value_id, uint32_t lefts, uint32_t rights, bool rest) {
    uint32_t nvalues = lefts + rights + (rest ? 1 : 0);
    uint32_t *value_ids = nvalues ? pm_arena_alloc(&builder->scratch, sizeof(uint32_t) * nvalues, PRISM_ALIGNOF(uint32_t)) : NULL;

    PrismInsn *insn = make_insn(builder, kPrismInsnExpandArray, node_id, nvalues + 1);
    insn->as.expand_array.lefts = lefts;
    insn->as.expand_array.rights = rights;
    insn->as.expand_array.rest = rest;

    PrismGraph *graph = PrismBuilder_graph(builder);
    graph->opnds[insn->opnds_off] = value_id;
    for (uint32_t idx = 0; idx < nvalues; ++idx) {
        value_ids[idx] = make_value(builder);
        graph->opnds[insn->opnds_off + idx + 1] = value_ids[idx];
    }

    return value_ids;
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
emit_extract_last_match_named_group(PrismBuilder *builder, uint32_t node_id, uint32_t last_match_id, pm_constant_id_t name_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnExtractLastMatchNamedGroup, node_id, 2);
    insn->as.name.name_id = name_id;

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
emit_nil_p(PrismBuilder *builder, uint32_t node_id, uint32_t value_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnNilP, node_id, 2);

    PrismGraph *graph = PrismBuilder_graph(builder);
    uint32_t predicate_id = make_value(builder);
    graph->opnds[insn->opnds_off] = predicate_id;
    graph->opnds[insn->opnds_off + 1] = value_id;

    return predicate_id;
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
emit_new_block(PrismBuilder *builder, uint32_t node_id, uint32_t graph_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnNewBlock, node_id, 1);
    insn->as.new_block.graph_id = graph_id;

    uint32_t value_id = make_value(builder);
    PrismBuilder_graph(builder)->opnds[insn->opnds_off] = value_id;

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
emit_trace_b_call(PrismBuilder *builder, uint32_t node_id) {
    make_insn(builder, kPrismInsnTraceBCall, node_id, 0);
}

static void
emit_trace_b_return(PrismBuilder *builder, uint32_t node_id, uint32_t value_id) {
    PrismInsn *insn = make_insn(builder, kPrismInsnTraceBReturn, node_id, 1);

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
compile_node_or_nil(PrismBuilder *builder, const pm_node_t *node, uint32_t node_id) {
    return node ? compile_node(builder, node) : emit_load_nil(builder, node_id);
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

static void
compile_target_node_parents(PrismBuilder *builder, const pm_node_t *node, PrismTargetParents *parents) {
    switch (PM_NODE_TYPE(node)) {
        case PM_CALL_TARGET_NODE: {
            const pm_call_target_node_t *target = (const pm_call_target_node_t *) node;

            uint32_t receiver_id = compile_node(builder, target->receiver);
            PrismTargetParents_push(builder, parents, receiver_id);

            break;
        }
        case PM_CONSTANT_PATH_TARGET_NODE: {
            const pm_constant_path_target_node_t *target = (const pm_constant_path_target_node_t *) node;

            if (target->parent) {
                uint32_t parent_id = compile_node(builder, target->parent);
                PrismTargetParents_push(builder, parents, parent_id);
            }

            break;
        }
        case PM_INDEX_TARGET_NODE: {
            const pm_index_target_node_t *target = (const pm_index_target_node_t *) node;

            uint32_t receiver_id = compile_node(builder, target->receiver);
            PrismTargetParents_push(builder, parents, receiver_id);

            if (target->arguments) {
                for (size_t idx = 0; idx < target->arguments->arguments.size; ++idx) {
                    uint32_t argument_id = compile_node(builder, target->arguments->arguments.nodes[idx]);
                    PrismTargetParents_push(builder, parents, argument_id);
                }
            }

            break;
        }
        default:
            break;
    }
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

            emit_call(builder, node->node_id, target->name, receiver_id, 1, &value_id, false);

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
            uint32_t *argument_ids = pm_arena_alloc(&builder->scratch, sizeof(uint32_t) * (nindex_ids + 1), PRISM_ALIGNOF(uint32_t));

            if (nindex_ids) {
                memcpy(argument_ids, parents->ids + parents->index, sizeof(uint32_t) * nindex_ids);
                parents->index += nindex_ids;
            }

            argument_ids[nindex_ids] = value_id;
            emit_call(builder, node->node_id, PM_CONSTANT_ID_ASET, receiver_id, nindex_ids + 1, argument_ids, false);
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
        default:
            fprintf(stderr, "Unsupported target: %s\n", pm_node_type(node->type));
            abort();
    }
}

static uint32_t
compile_conditional_node(PrismBuilder *builder, const pm_node_t *node, const pm_node_t *predicate, const pm_statements_node_t *statements, const pm_node_t *subsequent) {
    uint32_t then_block_id = make_block(builder, 0);
    uint32_t else_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    uint32_t predicate_id = compile_node(builder, predicate);
    if (PM_NODE_TYPE_P(node, PM_IF_NODE)) {
        emit_branchif(builder, node->node_id, predicate_id, then_block_id, 0, NULL, else_block_id, 0, NULL);
    } else {
        emit_branchif(builder, node->node_id, predicate_id, else_block_id, 0, NULL, then_block_id, 0, NULL);
    }

    builder->state.block_id = then_block_id;
    uint32_t then_value_id = compile_node_or_nil(builder, PM_NODE_UPCAST(statements), node->node_id);
    emit_branch(builder, node->node_id, join_block_id, 1, &then_value_id);

    builder->state.block_id = else_block_id;
    uint32_t else_value_id = compile_node_or_nil(builder, subsequent, node->node_id);
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
        case PM_PARENTHESES_NODE: {
            const pm_parentheses_node_t *cast = (const pm_parentheses_node_t *) node;
            compile_pattern_match(builder, cast->body, value_id, matched_block_id, unmatched_block_id);
            break;
        }
        case PM_CAPTURE_PATTERN_NODE: {
            const pm_capture_pattern_node_t *cast = (const pm_capture_pattern_node_t *) node;
            uint32_t capture_block_id = make_block(builder, 0);
            compile_pattern_match(builder, cast->value, value_id, capture_block_id, unmatched_block_id);

            builder->state.block_id = capture_block_id;
            uint32_t local_id = resolve_local(builder, cast->target->name, cast->target->depth);
            emit_store_lvar(builder, cast->target->base.node_id, local_id, value_id);
            emit_branch(builder, node->node_id, matched_block_id, 0, NULL);
            break;
        }
        case PM_PINNED_EXPRESSION_NODE: {
            const pm_pinned_expression_node_t *cast = (const pm_pinned_expression_node_t *) node;
            uint32_t pattern_id = compile_node(builder, cast->expression);
            uint32_t predicate_id = emit_match(builder, node->node_id, value_id, pattern_id);
            emit_branchif(builder, node->node_id, predicate_id, matched_block_id, 0, NULL, unmatched_block_id, 0, NULL);
            break;
        }
        case PM_PINNED_VARIABLE_NODE: {
            const pm_pinned_variable_node_t *cast = (const pm_pinned_variable_node_t *) node;
            uint32_t pattern_id = compile_node(builder, cast->variable);
            uint32_t predicate_id = emit_match(builder, node->node_id, value_id, pattern_id);
            emit_branchif(builder, node->node_id, predicate_id, matched_block_id, 0, NULL, unmatched_block_id, 0, NULL);
            break;
        }
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
        case PM_IT_LOCAL_VARIABLE_READ_NODE:
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
                value_ids[(assoc_idx - assocs_start_idx) * 2] = compile_node(builder, assoc->key);
                value_ids[(assoc_idx - assocs_start_idx) * 2 + 1] = compile_node(builder, assoc->value);
            }

            uint32_t hash_id = emit_new_hash(builder, node->node_id, nvalue_ids, value_ids);
            value_id = value_id == UINT32_MAX ? hash_id : emit_merge_hash(builder, node->node_id, value_id, hash_id);
        }

        if (element_idx < nelements) {
            const pm_assoc_splat_node_t *assoc_splat = (const pm_assoc_splat_node_t *) elements->nodes[element_idx];
            uint32_t splat_id = compile_node(builder, assoc_splat->value);
            uint32_t hash_id = emit_coerce_hash(builder, assoc_splat->base.node_id, splat_id);
            value_id = value_id == UINT32_MAX ? hash_id : emit_merge_hash(builder, node->node_id, value_id, hash_id);
        }
    }

    if (value_id == UINT32_MAX) value_id = emit_new_hash(builder, node->node_id, 0, NULL);
    return value_id;
}

static void
compile_parameter_node(PrismBuilder *builder, const pm_node_t *node, uint32_t value_id) {
    switch (PM_NODE_TYPE(node)) {
        case PM_REQUIRED_PARAMETER_NODE: {
            const pm_required_parameter_node_t *parameter = (const pm_required_parameter_node_t *) node;
            uint32_t local_id = resolve_local(builder, parameter->name, 0);
            emit_store_lvar(builder, node->node_id, local_id, value_id);
            break;
        }
        case PM_MULTI_TARGET_NODE: {
            const pm_multi_target_node_t *target = (const pm_multi_target_node_t *) node;
            const pm_node_t *rest = target->rest && PM_NODE_TYPE_P(target->rest, PM_SPLAT_NODE) ? ((const pm_splat_node_t *) target->rest)->expression : NULL;

            uint32_t array_id = emit_coerce_array(builder, node->node_id, value_id);
            uint32_t *value_ids = emit_expand_array(builder, node->node_id, array_id, (uint32_t) target->lefts.size, (uint32_t) target->rights.size, rest != NULL);
            uint32_t idx = 0;

            for (size_t left = 0; left < target->lefts.size; ++left) {
                compile_parameter_node(builder, target->lefts.nodes[left], value_ids[idx++]);
            }

            if (rest) compile_parameter_node(builder, rest, value_ids[idx++]);

            for (size_t right = 0; right < target->rights.size; ++right) {
                compile_parameter_node(builder, target->rights.nodes[right], value_ids[idx++]);
            }

            break;
        }
        default:
            break;
    }
}

static void
compile_parameter_default(PrismBuilder *builder, uint32_t node_id, pm_constant_id_t name, const pm_node_t *value, uint32_t value_id, uint32_t specified_id) {
    uint32_t default_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);
    emit_branchif(builder, node_id, specified_id, join_block_id, 1, &value_id, default_block_id, 0, NULL);

    builder->state.block_id = default_block_id;
    uint32_t default_id = compile_node(builder, value);
    emit_branch(builder, node_id, join_block_id, 1, &default_id);

    builder->state.block_id = join_block_id;
    uint32_t local_id = resolve_local(builder, name, 0);
    emit_store_lvar(builder, node_id, local_id, PrismBuilder_graph(builder)->blocks[join_block_id].params[0]);
}

static void
compile_parameters(PrismBuilder *builder, const pm_parameters_node_t *parameters, const PrismSignature *signature) {
    if (!parameters) return;

    for (uint32_t idx = 0; idx < signature->nrequired_ids; ++idx) {
        const pm_node_t *required = parameters->requireds.nodes[idx];
        if (PM_NODE_TYPE_P(required, PM_REQUIRED_PARAMETER_NODE)) {
            compile_parameter_node(builder, required, signature->required_ids[idx]);
        }
    }

    if (parameters->rest && PM_NODE_TYPE_P(parameters->rest, PM_REST_PARAMETER_NODE)) {
        const pm_rest_parameter_node_t *rest = (const pm_rest_parameter_node_t *) parameters->rest;
        if (rest->name) {
            uint32_t local_id = resolve_local(builder, rest->name, 0);
            emit_store_lvar(builder, rest->base.node_id, local_id, signature->rest_id);
        }
    }

    for (uint32_t idx = 0; idx < signature->npost_ids; ++idx) {
        const pm_node_t *post = parameters->posts.nodes[idx];
        if (PM_NODE_TYPE_P(post, PM_REQUIRED_PARAMETER_NODE)) {
            compile_parameter_node(builder, post, signature->post_ids[idx]);
        }
    }

    uint32_t keyword_idx = 0;
    for (size_t idx = 0; idx < parameters->keywords.size; ++idx) {
        const pm_node_t *keyword = parameters->keywords.nodes[idx];
        if (PM_NODE_TYPE_P(keyword, PM_REQUIRED_KEYWORD_PARAMETER_NODE)) {
            uint32_t local_id = resolve_local(builder, ((const pm_required_keyword_parameter_node_t *) keyword)->name, 0);
            emit_store_lvar(builder, keyword->node_id, local_id, signature->required_keyword_ids[keyword_idx++]);
        }
    }

    if (parameters->keyword_rest && PM_NODE_TYPE_P(parameters->keyword_rest, PM_KEYWORD_REST_PARAMETER_NODE)) {
        const pm_keyword_rest_parameter_node_t *rest = (const pm_keyword_rest_parameter_node_t *) parameters->keyword_rest;
        if (rest->name) {
            uint32_t local_id = resolve_local(builder, rest->name, 0);
            emit_store_lvar(builder, rest->base.node_id, local_id, signature->keyword_rest_id);
        }
    }

    for (uint32_t idx = 0; idx < signature->noptional_ids; ++idx) {
        const pm_optional_parameter_node_t *optional = (const pm_optional_parameter_node_t *) parameters->optionals.nodes[idx];
        compile_parameter_default(builder, optional->base.node_id, optional->name, optional->value, signature->optional_ids[idx], signature->optional_specified_ids[idx]);
    }

    keyword_idx = 0;
    for (size_t idx = 0; idx < parameters->keywords.size; ++idx) {
        const pm_node_t *keyword = parameters->keywords.nodes[idx];
        if (PM_NODE_TYPE_P(keyword, PM_OPTIONAL_KEYWORD_PARAMETER_NODE)) {
            const pm_optional_keyword_parameter_node_t *optional = (const pm_optional_keyword_parameter_node_t *) keyword;
            compile_parameter_default(builder, optional->base.node_id, optional->name, optional->value, signature->optional_keyword_ids[keyword_idx], signature->optional_keyword_specified_ids[keyword_idx]);
            keyword_idx++;
        }
    }

    for (uint32_t idx = 0; idx < signature->nrequired_ids; ++idx) {
        const pm_node_t *required = parameters->requireds.nodes[idx];
        if (PM_NODE_TYPE_P(required, PM_MULTI_TARGET_NODE)) {
            compile_parameter_node(builder, required, signature->required_ids[idx]);
        }
    }

    for (uint32_t idx = 0; idx < signature->npost_ids; ++idx) {
        const pm_node_t *post = parameters->posts.nodes[idx];
        if (PM_NODE_TYPE_P(post, PM_MULTI_TARGET_NODE)) {
            compile_parameter_node(builder, post, signature->post_ids[idx]);
        }
    }
}

static uint32_t
compile_program_node_statements(PrismBuilder *builder, const pm_statements_node_t *statements, uint32_t node_id) {
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
                compile_program_node_statements(builder, cast->statements, statement->node_id);
                pre_state = builder->state;
                builder->state = body_state;
                statement = NULL;
            }

            value_id = compile_node_or_nil(builder, statement, node_id);
        }
    } else {
        value_id = emit_load_nil(builder, node_id);
    }

    PrismBuilderState body_state = builder->state;
    builder->state = pre_state;
    emit_branch(builder, node_id, body_block_id, 0, NULL);
    builder->state = body_state;
    return value_id;
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
compile_block_node(PrismBuilder *builder, const pm_block_node_t *node) {
    const pm_parameters_node_t *parameters = NULL;

    uint32_t nrequired_ids = 0;
    uint32_t nlocal_ids = (uint32_t) node->locals.size;

    bool numbered = false;
    bool it = false;

    if (node->parameters) {
        switch (PM_NODE_TYPE(node->parameters)) {
            case PM_BLOCK_PARAMETERS_NODE:
                parameters = ((const pm_block_parameters_node_t *) node->parameters)->parameters;
                break;
            case PM_NUMBERED_PARAMETERS_NODE:
                numbered = true;
                nrequired_ids = ((const pm_numbered_parameters_node_t *) node->parameters)->maximum;
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

    uint32_t graph_id = make_graph(builder, kPrismGraphBlock, builder->state.graph_id, nlocal_ids);

    PrismSignature signature;
    if (parameters) {
        compile_parameters_signature(builder, graph_id, &signature, parameters);
    } else {
        make_signature(builder, graph_id, &signature, nrequired_ids, 0, false, 0);
    }

    uint32_t npositional_ids = signature.nrequired_ids + signature.npost_ids;
    signature.autosplat = npositional_ids + signature.noptional_ids > 1 || (npositional_ids > 0 && signature.rest_id != UINT32_MAX);

    PrismBuilderState state = push_scope(builder, graph_id, &signature, &node->locals);
    const uint32_t *required_ids = PrismBuilder_graph(builder)->signature.required_ids;

    if (numbered) {
        for (uint32_t idx = 0; idx < nrequired_ids; ++idx) {
            const uint8_t name[] = { '_', (uint8_t) ('1' + idx) };
            pm_constant_id_t name_id = pm_parser_constant_find(builder->parser, name, sizeof(name));
            uint32_t local_id = resolve_local(builder, name_id, 0);
            emit_store_lvar(builder, node->parameters->node_id, local_id, required_ids[idx]);
        }
    } else if (it) {
        uint32_t local_id = make_local(builder, PM_CONSTANT_ID_IT);
        builder->state.it_local_id = local_id;
        PrismBuilder_graph(builder)->local_ids[node->locals.size] = local_id;
        emit_store_lvar(builder, node->parameters->node_id, local_id, required_ids[0]);
    }

    compile_parameters(builder, parameters, &signature);

    emit_trace_b_call(builder, node->base.node_id);
    uint32_t body_id = compile_node_or_nil(builder, node->body, node->base.node_id);
    emit_trace_b_return(builder, node->base.node_id, body_id);
    emit_return(builder, node->base.node_id, body_id);
    pop_scope(builder, state);

    return emit_new_block(builder, node->base.node_id, graph_id);
}

static uint32_t
compile_call_node(PrismBuilder *builder, const pm_call_node_t *node) {
    uint32_t receiver_id;
    if (node->receiver) {
        receiver_id = compile_node(builder, node->receiver);
    } else {
        receiver_id = emit_load_self(builder, node->base.node_id);
    }

    bool safe_navigation = PM_NODE_FLAG_P(node, PM_CALL_NODE_FLAGS_SAFE_NAVIGATION);
    uint32_t join_block_id = UINT32_MAX;
    if (safe_navigation) {
        uint32_t call_block_id = make_block(builder, 0);
        join_block_id = make_block(builder, 1);
        uint32_t predicate_id = emit_nil_p(builder, node->base.node_id, receiver_id);
        emit_branchif(builder, node->base.node_id, predicate_id, join_block_id, 1, &receiver_id, call_block_id, 0, NULL);
        builder->state.block_id = call_block_id;
    }

    size_t nargument_ids = 0;
    uint32_t *argument_ids = NULL;
    bool keywords = false;

    if (node->arguments) {
        nargument_ids = node->arguments->arguments.size;
        argument_ids = pm_arena_alloc(builder->arena, sizeof(uint32_t) * nargument_ids, PRISM_ALIGNOF(uint32_t));

        for (size_t idx = 0; idx < nargument_ids; ++idx) {
            const pm_node_t *argument = node->arguments->arguments.nodes[idx];
            if (PM_NODE_TYPE_P(argument, PM_KEYWORD_HASH_NODE)) keywords = true;
            argument_ids[idx] = compile_node(builder, argument);
        }
    }

    uint32_t value_id;
    if (node->block) {
        uint32_t block_id = compile_node(builder, node->block);
        value_id = emit_call_with_block(builder, node->base.node_id, node->name, receiver_id, nargument_ids, argument_ids, block_id, keywords);
    } else {
        value_id = emit_call(builder, node->base.node_id, node->name, receiver_id, nargument_ids, argument_ids, keywords);
    }

    if (PM_NODE_FLAG_P(node, PM_CALL_NODE_FLAGS_ATTRIBUTE_WRITE)) {
        value_id = argument_ids[nargument_ids - 1];
    }

    if (safe_navigation) {
        emit_branch(builder, node->base.node_id, join_block_id, 1, &value_id);
        builder->state.block_id = join_block_id;
        return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
    }

    return value_id;
}

static uint32_t
compile_call_operator_write_node(PrismBuilder *builder, const pm_call_operator_write_node_t *node) {
    uint32_t receiver_id = node->receiver ? compile_node(builder, node->receiver) : emit_load_self(builder, node->base.node_id);
    uint32_t join_block_id = UINT32_MAX;

    if (PM_NODE_FLAG_P(node, PM_CALL_NODE_FLAGS_SAFE_NAVIGATION)) {
        uint32_t call_block_id = make_block(builder, 0);
        join_block_id = make_block(builder, 1);
        uint32_t nil_id = emit_nil_p(builder, node->base.node_id, receiver_id);
        emit_branchif(builder, node->base.node_id, nil_id, join_block_id, 1, &receiver_id, call_block_id, 0, NULL);
        builder->state.block_id = call_block_id;
    }

    uint32_t current_id = emit_call(builder, node->base.node_id, node->read_name, receiver_id, 0, NULL, false);
    uint32_t value_id = compile_node(builder, node->value);
    uint32_t result_id = emit_call(builder, node->base.node_id, node->binary_operator, current_id, 1, &value_id, false);
    emit_call(builder, node->base.node_id, node->write_name, receiver_id, 1, &result_id, false);

    if (join_block_id != UINT32_MAX) {
        emit_branch(builder, node->base.node_id, join_block_id, 1, &result_id);
        builder->state.block_id = join_block_id;
        result_id = PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
    }

    return result_id;
}

static uint32_t
compile_class_node(PrismBuilder *builder, const pm_class_node_t *node) {
    uint32_t graph_id = make_graph(builder, kPrismGraphClass, UINT32_MAX, (uint32_t) node->locals.size);
    PrismBuilderState state = push_scope(builder, graph_id, NULL, &node->locals);

    emit_trace_class(builder, node->base.node_id);
    uint32_t value_id = compile_node_or_nil(builder, node->body, node->base.node_id);

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
compile_class_variable_operator_write_node(PrismBuilder *builder, const pm_class_variable_operator_write_node_t *node) {
    uint32_t receiver_id = emit_load_cvar(builder, node->base.node_id, node->name);
    uint32_t value_id = compile_node(builder, node->value);
    uint32_t result_id = emit_call(builder, node->base.node_id, node->binary_operator, receiver_id, 1, &value_id, false);
    emit_store_cvar(builder, node->base.node_id, node->name, result_id);
    return result_id;
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
compile_constant_and_write_node(PrismBuilder *builder, const pm_constant_and_write_node_t *node) {
    uint32_t set_block_id = make_block(builder, 0);
    uint32_t join_block_id = make_block(builder, 1);

    PrismConstantPath constant_path = PrismConstantPath_new(builder, 1);
    PrismConstantPath_set(&constant_path, 0, node->name);
    uint32_t current_id = emit_load_const_nest_rel(builder, node->base.node_id, constant_path);

    emit_branchif(builder, node->base.node_id, current_id, set_block_id, 0, NULL, join_block_id, 1, &current_id);

    builder->state.block_id = set_block_id;
    uint32_t value_id = compile_node(builder, node->value);
    emit_store_const_nest_rel(builder, node->base.node_id, node->name, value_id);
    emit_branch(builder, node->base.node_id, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

static uint32_t
compile_constant_operator_write_node(PrismBuilder *builder, const pm_constant_operator_write_node_t *node) {
    PrismConstantPath constant_path = PrismConstantPath_new(builder, 1);
    PrismConstantPath_set(&constant_path, 0, node->name);

    uint32_t receiver_id = emit_load_const_nest_rel(builder, node->base.node_id, constant_path);
    uint32_t value_id = compile_node(builder, node->value);
    uint32_t result_id = emit_call(builder, node->base.node_id, node->binary_operator, receiver_id, 1, &value_id, false);
    emit_store_const_nest_rel(builder, node->base.node_id, node->name, result_id);

    return result_id;
}

static uint32_t
compile_constant_or_write_node(PrismBuilder *builder, const pm_constant_or_write_node_t *node) {
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
    uint32_t value_id = compile_node(builder, node->value);
    emit_store_const_nest_rel(builder, node->base.node_id, node->name, value_id);
    emit_branch(builder, node->base.node_id, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
}

static uint32_t
compile_constant_path_and_write_node(PrismBuilder *builder, const pm_constant_path_and_write_node_t *node) {
    uint32_t parent_id = node->target->parent ? compile_node(builder, node->target->parent) : UINT32_MAX;
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
    uint32_t value_id = compile_node(builder, node->value);
    if (node->target->parent) {
        emit_store_const_recv_rel(builder, node->base.node_id, parent_id, node->target->name, value_id);
    } else {
        emit_store_const_abs(builder, node->base.node_id, node->target->name, value_id);
    }
    emit_branch(builder, node->base.node_id, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
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
compile_constant_path_operator_write_node(PrismBuilder *builder, const pm_constant_path_operator_write_node_t *node) {
    PrismConstantPath constant_path = PrismConstantPath_new(builder, 1);
    PrismConstantPath_set(&constant_path, 0, (uint32_t) node->target->name);

    if (node->target->parent) {
        uint32_t parent_id = compile_node(builder, node->target->parent);

        uint32_t receiver_id = emit_load_const_recv_rel(builder, node->base.node_id, parent_id, constant_path);
        uint32_t value_id = compile_node(builder, node->value);
        uint32_t result_id = emit_call(builder, node->base.node_id, node->binary_operator, receiver_id, 1, &value_id, false);

        return emit_store_const_recv_rel(builder, node->base.node_id, parent_id, node->target->name, result_id);
    } else {
        uint32_t receiver_id = emit_load_const_abs(builder, node->base.node_id, constant_path);
        uint32_t value_id = compile_node(builder, node->value);
        uint32_t result_id = emit_call(builder, node->base.node_id, node->binary_operator, receiver_id, 1, &value_id, false);

        return emit_store_const_abs(builder, node->base.node_id, node->target->name, result_id);
    }
}

static uint32_t
compile_constant_path_or_write_node(PrismBuilder *builder, const pm_constant_path_or_write_node_t *node) {
    uint32_t parent_id = node->target->parent ? compile_node(builder, node->target->parent) : UINT32_MAX;
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
    uint32_t value_id = compile_node(builder, node->value);
    if (node->target->parent) {
        emit_store_const_recv_rel(builder, node->base.node_id, parent_id, node->target->name, value_id);
    } else {
        emit_store_const_abs(builder, node->base.node_id, node->target->name, value_id);
    }
    emit_branch(builder, node->base.node_id, join_block_id, 1, &value_id);

    builder->state.block_id = join_block_id;
    return PrismBuilder_graph(builder)->blocks[join_block_id].params[0];
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
compile_def_node(PrismBuilder *builder, const pm_def_node_t *node) {
    uint32_t graph_id = make_graph(builder, kPrismGraphDef, UINT32_MAX, (uint32_t) node->locals.size);

    PrismSignature signature;
    compile_parameters_signature(builder, graph_id, &signature, node->parameters);
    PrismBuilderState state = push_scope(builder, graph_id, &signature, &node->locals);
    compile_parameters(builder, node->parameters, &signature);

    emit_trace_call(builder, node->base.node_id);
    uint32_t value_id = compile_node_or_nil(builder, node->body, node->base.node_id);

    emit_trace_return(builder, node->base.node_id, value_id);
    emit_return(builder, node->base.node_id, value_id);

    pop_scope(builder, state);

    if (node->receiver) {
        uint32_t receiver_id = compile_node(builder, node->receiver);
        emit_define_singleton_method(builder, node->base.node_id, node->name, receiver_id, graph_id);
    } else {
        emit_define_method(builder, node->base.node_id, node->name, graph_id);
    }

    uint32_t object_id = make_object_constant_id(builder, node->name);
    return emit_load_object(builder, node->base.node_id, object_id);
}

static uint32_t
compile_else_node(PrismBuilder *builder, const pm_else_node_t *node) {
    return compile_node_or_nil(builder, PM_NODE_UPCAST(node->statements), node->base.node_id);
}

static uint32_t
compile_embedded_statements_node(PrismBuilder *builder, const pm_embedded_statements_node_t *node) {
    uint32_t string_id = compile_node_or_nil(builder, PM_NODE_UPCAST(node->statements), node->base.node_id);
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
compile_for_node(PrismBuilder *builder, const pm_for_node_t *node) {
    uint32_t collection_id = compile_node(builder, node->collection);
    uint32_t graph_id = make_graph(builder, kPrismGraphBlock, builder->state.graph_id, 0);
    PrismSignature signature;
    make_signature(builder, graph_id, &signature, 1, 0, false, 0);
    PrismBuilderState state = push_scope(builder, graph_id, &signature, NULL);
    uint32_t param_id = PrismBuilder_graph(builder)->signature.required_ids[0];

    PrismTargetParents parents = { 0 };
    compile_target_node_parents(builder, node->index, &parents);
    compile_target_node(builder, node->index, param_id, &parents);
    assert(parents.index == parents.size);

    emit_trace_b_call(builder, node->base.node_id);
    uint32_t body_id = compile_node_or_nil(builder, PM_NODE_UPCAST(node->statements), node->base.node_id);
    emit_trace_b_return(builder, node->base.node_id, body_id);
    emit_return(builder, node->base.node_id, body_id);
    pop_scope(builder, state);

    uint32_t block_id = emit_new_block(builder, node->base.node_id, graph_id);
    return emit_call_with_block(builder, node->base.node_id, PM_CONSTANT_ID_EACH, collection_id, 0, NULL, block_id, false);
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
compile_global_variable_operator_write_node(PrismBuilder *builder, const pm_global_variable_operator_write_node_t *node) {
    uint32_t receiver_id = emit_load_gvar(builder, node->base.node_id, node->name);
    uint32_t value_id = compile_node(builder, node->value);
    uint32_t result_id = emit_call(builder, node->base.node_id, node->binary_operator, receiver_id, 1, &value_id, false);
    emit_store_gvar(builder, node->base.node_id, node->name, result_id);
    return result_id;
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
compile_hash_node(PrismBuilder *builder, const pm_hash_node_t *node) {
    if (PM_NODE_FLAG_P(node, PM_NODE_FLAG_STATIC_LITERAL) && node->elements.size) {
        uint32_t object_id = static_literal(builder, PM_NODE_UPCAST(node));
        return emit_new_hash_static(builder, node->base.node_id, object_id);
    }

    return compile_hash_elements(builder, PM_NODE_UPCAST(node), &node->elements);
}

static uint32_t
compile_if_node(PrismBuilder *builder, const pm_if_node_t *node) {
    return compile_conditional_node(builder, PM_NODE_UPCAST(node), node->predicate, node->statements, node->subsequent);
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
compile_instance_variable_and_write_node(PrismBuilder *builder, const pm_instance_variable_and_write_node_t *node) {
    return compile_instance_variable_logical_write_node(builder, PM_NODE_UPCAST(node), node->name, node->value);
}

static uint32_t
compile_instance_variable_operator_write_node(PrismBuilder *builder, const pm_instance_variable_operator_write_node_t *node) {
    uint32_t receiver_id = emit_load_ivar(builder, node->base.node_id, node->name);
    uint32_t value_id = compile_node(builder, node->value);
    uint32_t result_id = emit_call(builder, node->base.node_id, node->binary_operator, receiver_id, 1, &value_id, false);
    emit_store_ivar(builder, node->base.node_id, node->name, result_id);
    return result_id;
}

static uint32_t
compile_instance_variable_or_write_node(PrismBuilder *builder, const pm_instance_variable_or_write_node_t *node) {
    return compile_instance_variable_logical_write_node(builder, PM_NODE_UPCAST(node), node->name, node->value);
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
compile_integer_node(PrismBuilder *builder, const pm_integer_node_t *node) {
    uint32_t object_id = static_literal(builder, PM_NODE_UPCAST(node));
    return emit_load_object(builder, node->base.node_id, object_id);
}

static uint32_t
compile_interpolated_match_last_line_node(PrismBuilder *builder, const pm_interpolated_match_last_line_node_t *node) {
    uint32_t nvalue_ids = (uint32_t) node->parts.size;
    uint32_t *value_ids = pm_arena_alloc(builder->arena, nvalue_ids * sizeof(uint32_t), PRISM_ALIGNOF(uint32_t));

    for (uint32_t idx = 0; idx < nvalue_ids; ++idx) {
        value_ids[idx] = compile_node(builder, node->parts.nodes[idx]);
    }

    uint32_t regexp_id = emit_new_regexp(builder, node->base.node_id, nvalue_ids, value_ids, node->base.flags);
    uint32_t last_line_id = emit_load_gvar(builder, node->base.node_id, PM_CONSTANT_ID_LAST_LINE);
    return emit_call(builder, node->base.node_id, PM_CONSTANT_ID_MATCH, regexp_id, 1, &last_line_id, false);
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
    return emit_call(builder, node->base.node_id, PM_CONSTANT_ID_BACKTICK, receiver_id, 1, &string_id, false);
}

static uint32_t
compile_it_local_variable_read_node(PrismBuilder *builder, const pm_it_local_variable_read_node_t *node) {
    return emit_load_lvar(builder, node->base.node_id, builder->state.it_local_id);
}

static uint32_t
compile_keyword_hash_node(PrismBuilder *builder, const pm_node_t *node, const pm_keyword_hash_node_t *keyword_hash) {
    return compile_hash_elements(builder, node, &keyword_hash->elements);
}

static uint32_t
compile_local_variable_and_write_node(PrismBuilder *builder, const pm_local_variable_and_write_node_t *node) {
    return compile_local_variable_logical_write_node(builder, PM_NODE_UPCAST(node), node->name, node->depth, node->value);
}

static uint32_t
compile_local_variable_operator_write_node(PrismBuilder *builder, const pm_local_variable_operator_write_node_t *node) {
    uint32_t resolved_id = resolve_local(builder, node->name, node->depth);
    uint32_t local_id = emit_load_lvar(builder, node->base.node_id, resolved_id);
    uint32_t value_id = compile_node(builder, node->value);
    uint32_t result_id = emit_call(builder, node->base.node_id, node->binary_operator, local_id, 1, &value_id, false);
    emit_store_lvar(builder, node->base.node_id, resolved_id, result_id);
    return result_id;
}

static uint32_t
compile_local_variable_or_write_node(PrismBuilder *builder, const pm_local_variable_or_write_node_t *node) {
    return compile_local_variable_logical_write_node(builder, PM_NODE_UPCAST(node), node->name, node->depth, node->value);
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
compile_match_last_line_node(PrismBuilder *builder, const pm_match_last_line_node_t *node) {
    uint32_t object_id = make_object(builder, kPrismObjectRegexp);
    PrismObject *object = builder->unit->objects + object_id;
    object->as.string.flags = node->base.flags;
    object->as.string.unescaped = &node->unescaped;

    uint32_t regexp_id = emit_load_object(builder, node->base.node_id, object_id);
    uint32_t last_line_id = emit_load_gvar(builder, node->base.node_id, PM_CONSTANT_ID_LAST_LINE);
    return emit_call(builder, node->base.node_id, PM_CONSTANT_ID_MATCH, regexp_id, 1, &last_line_id, false);
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
compile_match_write_node(PrismBuilder *builder, const pm_match_write_node_t *node) {
    uint32_t result_id = compile_node(builder, PM_NODE_UPCAST(node->call));
    uint32_t last_match_id = emit_load_last_match(builder, node->base.node_id);

    for (size_t idx = 0; idx < node->targets.size; ++idx) {
        const pm_local_variable_target_node_t *target = (const pm_local_variable_target_node_t *) node->targets.nodes[idx];
        uint32_t local_id = resolve_local(builder, target->name, target->depth);
        uint32_t value_id = emit_extract_last_match_named_group(builder, target->base.node_id, last_match_id, target->name);
        emit_store_lvar(builder, target->base.node_id, local_id, value_id);
    }

    return result_id;
}

static uint32_t
compile_module_node(PrismBuilder *builder, const pm_module_node_t *node) {
    uint32_t graph_id = make_graph(builder, kPrismGraphModule, UINT32_MAX, (uint32_t) node->locals.size);
    PrismBuilderState state = push_scope(builder, graph_id, NULL, &node->locals);

    emit_trace_class(builder, node->base.node_id);
    uint32_t value_id = compile_node_or_nil(builder, node->body, node->base.node_id);
    emit_trace_end(builder, node->base.node_id);
    emit_return(builder, node->base.node_id, value_id);
    pop_scope(builder, state);

    if (PM_NODE_TYPE_P(node->constant_path, PM_CONSTANT_READ_NODE)) {
        return emit_define_module_nest_rel(builder, node->base.node_id, node->name, graph_id);
    }

    const pm_constant_path_node_t *constant_path = (const pm_constant_path_node_t *) node->constant_path;
    if (constant_path->parent) {
        uint32_t receiver_id = compile_node(builder, constant_path->parent);
        return emit_define_module_recv_rel(builder, node->base.node_id, node->name, receiver_id, graph_id);
    }

    return emit_define_module_abs(builder, node->base.node_id, node->name, graph_id);
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
    return compile_node_or_nil(builder, node->body, node->base.node_id);
}

static uint32_t
compile_post_execution_node(PrismBuilder *builder, const pm_post_execution_node_t *node) {
    uint32_t graph_id = make_graph(builder, kPrismGraphPostExecution, builder->state.graph_id, 0);
    PrismBuilderState state = push_scope(builder, graph_id, NULL, NULL);
    uint32_t value_id = compile_node_or_nil(builder, PM_NODE_UPCAST(node->statements), node->base.node_id);
    emit_return(builder, node->base.node_id, value_id);
    pop_scope(builder, state);

    PrismInsn *insn = make_insn(builder, kPrismInsnPostExecution, node->base.node_id, 0);
    insn->as.post_execution.graph_id = graph_id;
    return emit_load_nil(builder, node->base.node_id);
}

static uint32_t
compile_program_node(PrismBuilder *builder, const pm_program_node_t *node) {
    uint32_t graph_id = make_graph(builder, kPrismGraphProgram, UINT32_MAX, (uint32_t) node->locals.size);
    PrismBuilderState state = push_scope(builder, graph_id, NULL, &node->locals);
    uint32_t value_id = compile_program_node_statements(builder, node->statements, node->base.node_id);

    emit_return(builder, node->base.node_id, value_id);
    pop_scope(builder, state);
    return UINT32_MAX;
}

static uint32_t
compile_range_node(PrismBuilder *builder, const pm_range_node_t *node) {
    uint32_t left_id = compile_node_or_nil(builder, node->left, node->base.node_id);
    uint32_t right_id = compile_node_or_nil(builder, node->right, node->base.node_id);
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

    if (!node->arguments) {
        value_id = emit_load_nil(builder, node->base.node_id);
    } else if (node->arguments->arguments.size == 1 && !PM_NODE_TYPE_P(node->arguments->arguments.nodes[0], PM_SPLAT_NODE)) {
        value_id = compile_node(builder, node->arguments->arguments.nodes[0]);
    } else {
        uint32_t nargument_ids = (uint32_t) node->arguments->arguments.size;
        uint32_t *argument_ids = pm_arena_alloc(builder->arena, sizeof(uint32_t) * nargument_ids, PRISM_ALIGNOF(uint32_t));

        for (uint32_t idx = 0; idx < nargument_ids; ++idx) {
            argument_ids[idx] = compile_node(builder, node->arguments->arguments.nodes[idx]);
        }

        value_id = emit_new_array(builder, node->base.node_id, nargument_ids, argument_ids);
    }

    if (builder->unit->graphs[builder->state.graph_id].kind == kPrismGraphDef) {
        emit_trace_return(builder, node->base.node_id, value_id);
    }

    emit_return(builder, node->base.node_id, value_id);

    builder->state.block_id = make_block(builder, 0);
    return emit_load_nil(builder, node->base.node_id);
}

static uint32_t
compile_self_node(PrismBuilder *builder, const pm_self_node_t *node) {
    return emit_load_self(builder, node->base.node_id);
}

static uint32_t
compile_singleton_class_node(PrismBuilder *builder, const pm_singleton_class_node_t *node) {
    uint32_t graph_id = make_graph(builder, kPrismGraphSingletonClass, UINT32_MAX, (uint32_t) node->locals.size);
    PrismBuilderState state = push_scope(builder, graph_id, NULL, &node->locals);
    uint32_t value_id = compile_node_or_nil(builder, node->body, node->base.node_id);

    emit_return(builder, node->base.node_id, value_id);
    pop_scope(builder, state);

    uint32_t receiver_id = compile_node(builder, node->expression);
    return emit_define_singleton_class(builder, node->base.node_id, receiver_id, graph_id);
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
compile_unless_node(PrismBuilder *builder, const pm_unless_node_t *node) {
    return compile_conditional_node(builder, PM_NODE_UPCAST(node), node->predicate, node->statements, PM_NODE_UPCAST(node->else_clause));
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
    return emit_call(builder, node->base.node_id, PM_CONSTANT_ID_BACKTICK, receiver_id, 1, &argument_id, false);
}

static uint32_t
compile_yield_node(PrismBuilder *builder, const pm_yield_node_t *node) {
    PrismInsn *insn = make_insn(builder, kPrismInsnYield, node->base.node_id, 1);
    uint32_t value_id = make_value(builder);
    PrismBuilder_graph(builder)->opnds[insn->opnds_off] = value_id;

    return value_id;
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
        case PM_BLOCK_NODE:
            return compile_block_node(builder, (const pm_block_node_t *) node);
        case PM_CALL_NODE:
            return compile_call_node(builder, (const pm_call_node_t *) node);
        case PM_CALL_OPERATOR_WRITE_NODE:
            return compile_call_operator_write_node(builder, (const pm_call_operator_write_node_t *) node);
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
        case PM_CONSTANT_AND_WRITE_NODE:
            return compile_constant_and_write_node(builder, (const pm_constant_and_write_node_t *) node);
        case PM_CONSTANT_OR_WRITE_NODE:
            return compile_constant_or_write_node(builder, (const pm_constant_or_write_node_t *) node);
        case PM_CONSTANT_OPERATOR_WRITE_NODE:
            return compile_constant_operator_write_node(builder, (const pm_constant_operator_write_node_t *) node);
        case PM_CONSTANT_PATH_NODE:
            return compile_constant_path_node(builder, (const pm_constant_path_node_t *) node);
        case PM_CONSTANT_PATH_WRITE_NODE:
            return compile_constant_path_write_node(builder, (const pm_constant_path_write_node_t *) node);
        case PM_CONSTANT_PATH_AND_WRITE_NODE:
            return compile_constant_path_and_write_node(builder, (const pm_constant_path_and_write_node_t *) node);
        case PM_CONSTANT_PATH_OR_WRITE_NODE:
            return compile_constant_path_or_write_node(builder, (const pm_constant_path_or_write_node_t *) node);
        case PM_CONSTANT_PATH_OPERATOR_WRITE_NODE:
            return compile_constant_path_operator_write_node(builder, (const pm_constant_path_operator_write_node_t *) node);
        case PM_DEF_NODE:
            return compile_def_node(builder, (const pm_def_node_t *) node);
        case PM_ELSE_NODE:
            return compile_else_node(builder, (const pm_else_node_t *) node);
        case PM_EMBEDDED_STATEMENTS_NODE:
            return compile_embedded_statements_node(builder, (const pm_embedded_statements_node_t *) node);
        case PM_EMBEDDED_VARIABLE_NODE:
            return compile_embedded_variable_node(builder, (const pm_embedded_variable_node_t *) node);
        case PM_FALSE_NODE:
            return compile_false_node(builder, (const pm_false_node_t *) node);
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
        case PM_MATCH_WRITE_NODE:
            return compile_match_write_node(builder, (const pm_match_write_node_t *) node);
        case PM_MODULE_NODE:
            return compile_module_node(builder, (const pm_module_node_t *) node);
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
        case PM_ASSOC_NODE:
        case PM_ASSOC_SPLAT_NODE:
        case PM_BLOCK_LOCAL_VARIABLE_NODE:
        case PM_BLOCK_PARAMETERS_NODE:
        case PM_CALL_TARGET_NODE:
        case PM_CAPTURE_PATTERN_NODE:
        case PM_CLASS_VARIABLE_TARGET_NODE:
        case PM_CONSTANT_PATH_TARGET_NODE:
        case PM_CONSTANT_TARGET_NODE:
        case PM_GLOBAL_VARIABLE_TARGET_NODE:
        case PM_INDEX_TARGET_NODE:
        case PM_INSTANCE_VARIABLE_TARGET_NODE:
        case PM_LOCAL_VARIABLE_TARGET_NODE:
        case PM_PINNED_EXPRESSION_NODE:
        case PM_PINNED_VARIABLE_NODE:
        case PM_PRE_EXECUTION_NODE:
        case PM_IT_PARAMETERS_NODE:
        case PM_NUMBERED_PARAMETERS_NODE:
        case PM_KEYWORD_REST_PARAMETER_NODE:
        case PM_MULTI_TARGET_NODE:
        case PM_NO_KEYWORDS_PARAMETER_NODE:
        case PM_OPTIONAL_KEYWORD_PARAMETER_NODE:
        case PM_OPTIONAL_PARAMETER_NODE:
        case PM_REQUIRED_KEYWORD_PARAMETER_NODE:
        case PM_REQUIRED_PARAMETER_NODE:
        case PM_REST_PARAMETER_NODE:
            fprintf(stderr, "Handled elsewhere: %s\n", pm_node_type(node->type));
            abort();
        default:
            fprintf(stderr, "Unhandled node type: %s\n", pm_node_type(node->type));
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
            .it_local_id = UINT32_MAX,
            .lineno = parser->start_line - 1
        }
    };

    builder.bindings = pm_arena_zalloc(&builder.scratch, sizeof(uint32_t) * ((size_t) parser->constant_pool.size + 1), PRISM_ALIGNOF(uint32_t));
    compile_node(&builder, node);
    pm_arena_cleanup(&builder.scratch);
}
