#ifndef PRISM_INTERNAL_COMPILE_H
#define PRISM_INTERNAL_COMPILE_H

#include "prism/ast.h"
#include "prism/constant_pool.h"
#include "prism/integer.h"
#include "prism/stringy.h"

#include <stdint.h>

struct PrismConstantPath {
    uint32_t size;
    union {
        pm_constant_id_t constant_id;
        pm_constant_id_t *constant_ids;
    } as;
};

struct PrismInsn {
    PrismInsnKind kind;
    uint32_t node_id;
    uint32_t opnds_off;
    uint32_t opnds_len;
    union {
        struct { uint32_t block_id; } branch;
        struct { uint32_t then_block_id; uint32_t else_block_id; uint32_t then_opnds_len; } branchif;
        PrismConstantPath constant_path;
        struct { pm_constant_id_t name_id; uint32_t graph_id; } define;
        struct { uint32_t graph_id; } define_singleton_class;
        struct { uint32_t number; } extract_group;
        struct { uint32_t local_id; } lvar;
        struct { pm_constant_id_t name_id; } name;
        struct { uint32_t object_id; } object;
        struct { pm_node_flags_t flags; } regexp;
        struct { int32_t lineno; } trace_line;
    } as;
};

struct PrismBlock {
    PrismInsn *insns;
    uint32_t *params;
    uint32_t ninsns;
    uint32_t nparams;
    uint32_t insns_capa;
};

struct PrismObject {
    PrismObjectKind kind;
    union {
        struct { uint32_t nobject_ids; uint32_t *object_ids; } array;
        struct { const char *name; } encoding;
        struct { double value; } floating;
        struct { uint32_t nobject_ids; uint32_t *object_ids; } hash;
        struct { uint32_t numeric_id; } imaginary;
        struct { const pm_integer_t *value; } integer;
        struct { const pm_integer_t *numerator; const pm_integer_t *denominator; } rational;
        struct { pm_node_flags_t flags; const pm_string_t *unescaped; } string;
    } as;
};

struct PrismGraph {
    PrismBlock *blocks;
    uint32_t *opnds;
    uint32_t *local_ids;
    PrismGraphKind kind;
    uint32_t nblocks;
    uint32_t nopnds;
    uint32_t nlocal_ids;
    uint32_t blocks_capa;
    uint32_t opnds_capa;
    uint32_t value_id;
    uint32_t parent_id;
};

struct PrismLocal {
    pm_constant_id_t name_id;
    uint32_t graph_id;
};

struct PrismUnit {
    PrismGraph *graphs;
    PrismObject *objects;
    PrismLocal *locals;
    uint32_t ngraphs;
    uint32_t nobjects;
    uint32_t nlocals;
    uint32_t graphs_capa;
    uint32_t objects_capa;
    uint32_t locals_capa;
};

#endif
