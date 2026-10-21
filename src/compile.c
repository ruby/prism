#include "prism/internal/allocator.h"
#include "prism/node.h"

#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

typedef enum {
    kPrismInsnLoadObject,
    kPrismInsnLoadSelf,
    kPrismInsnReturn
} PrismInsnKind;

typedef struct {
    PrismInsnKind kind;
    uint32_t node_id;
    uint32_t offset;
    uint32_t opnds_idx;
    uint32_t opnds_len;
    union {
        struct { uint32_t block_id; } branch;
        struct { uint32_t object_id; } object;
    } as;
} PrismInsn;

typedef struct {
    struct {
        PrismInsn *mem;
        uint32_t size;
        uint32_t capa;
    } insns;
} PrismBlock;

typedef enum {
    kPrismObjectFalse,
    kPrismObjectFloat,
    kPrismObjectInteger,
    kPrismObjectNil,
    kPrismObjectTrue
} PrismObjectKind;

typedef struct {
    PrismObjectKind kind;
    union {
        struct { double value; } floating;
        struct { const pm_integer_t *value; } integer;
    } as;
} PrismObject;

typedef struct {
    struct {
        PrismBlock *mem;
        uint32_t size;
        uint32_t capa;
    } blocks;

    struct {
        uint32_t *mem;
        uint32_t size;
        uint32_t capa;
    } opnds;

    struct {
        PrismObject *mem;
        uint32_t size;
        uint32_t capa;
    } objects;

    uint32_t next_value_id;
} PrismGraph;

typedef struct {
    uint32_t block_id;
} PrismBuilder;

static inline uint32_t
make_value(PrismGraph *graph) {
    return graph->next_value_id++;
}

static uint32_t
make_block(PrismGraph *graph) {
    if (graph->blocks.size == graph->blocks.capa) {
        uint32_t next_capa = graph->blocks.capa ? graph->blocks.capa * 2 : 8;
        PrismBlock *next_mem = xrealloc_sized(graph->blocks.mem, sizeof(PrismBlock) * next_capa, sizeof(PrismBlock) * graph->blocks.capa);
        if (!next_mem) abort();

        graph->blocks.capa = next_capa;
        graph->blocks.mem = next_mem;
    }

    uint32_t block_id = graph->blocks.size++;
    graph->blocks.mem[block_id] = (PrismBlock) { 0 };
    return block_id;
}

static uint32_t
make_object(PrismGraph *graph, PrismObjectKind kind) {
    if (graph->objects.size == graph->objects.capa) {
        uint32_t next_capa = graph->objects.capa ? graph->objects.capa * 2 : 8;
        PrismObject *next_mem = xrealloc_sized(graph->objects.mem, sizeof(PrismObject) * next_capa, sizeof(PrismObject) * graph->objects.capa);
        if (!next_mem) abort();

        graph->objects.capa = next_capa;
        graph->objects.mem = next_mem;
    }

    uint32_t obj_id = graph->objects.size++;
    graph->objects.mem[obj_id] = (PrismObject) { .kind = kind };
    return obj_id;
}

static PrismInsn *
make_insn(PrismBuilder *builder, PrismGraph *graph, PrismInsnKind kind, uint32_t node_id, uint32_t offset, uint32_t opnds_len) {
    PrismBlock *block = &graph->blocks.mem[builder->block_id];

    if (block->insns.size == block->insns.capa) {
        uint32_t next_capa = block->insns.capa ? block->insns.capa * 2 : 8;
        PrismInsn *next_mem = xrealloc_sized(block->insns.mem, sizeof(PrismInsn) * next_capa, sizeof(PrismInsn) * block->insns.capa);
        if (!next_mem) abort();

        block->insns.capa = next_capa;
        block->insns.mem = next_mem;
    }

    PrismInsn *insn = &block->insns.mem[block->insns.size++];
    *insn = (PrismInsn) {
        .kind = kind,
        .node_id = node_id,
        .offset = offset,
        .opnds_idx = graph->opnds.size,
        .opnds_len = opnds_len
    };

    if (opnds_len) {
        if ((opnds_len > graph->opnds.capa) || (graph->opnds.size > graph->opnds.capa - opnds_len)) {
            uint32_t next_capa = graph->opnds.capa ? graph->opnds.capa * 2 : 8;
            while ((opnds_len > next_capa) || (graph->opnds.size > next_capa - opnds_len)) {
                next_capa *= 2;
            }

            uint32_t *next_mem = xrealloc_sized(graph->opnds.mem, sizeof(uint32_t) * next_capa, sizeof(uint32_t) * graph->opnds.capa);
            if (!next_mem) abort();

            graph->opnds.capa = next_capa;
            graph->opnds.mem = next_mem;
        }

        graph->opnds.size += opnds_len;
    }

    return insn;
}

static uint32_t
emit_load_object(PrismBuilder *builder, PrismGraph *graph, uint32_t node_id, uint32_t offset, uint32_t object_id) {
    PrismInsn *insn = make_insn(builder, graph, kPrismInsnLoadObject, node_id, offset, 1);
    insn->as.object.object_id = object_id;

    uint32_t value_id = make_value(graph);
    graph->opnds.mem[insn->opnds_idx] = value_id;

    return value_id;
}

static uint32_t
emit_load_nil(PrismBuilder *builder, PrismGraph *graph, uint32_t node_id, uint32_t offset) {
    return emit_load_object(builder, graph, node_id, offset, make_object(graph, kPrismObjectNil));
}

static uint32_t
emit_load_self(PrismBuilder *builder, PrismGraph *graph, uint32_t node_id, uint32_t offset) {
    PrismInsn *insn = make_insn(builder, graph, kPrismInsnLoadSelf, node_id, offset, 1);

    uint32_t value_id = make_value(graph);
    graph->opnds.mem[insn->opnds_idx] = value_id;

    return value_id;
}

static void
emit_return(PrismBuilder *builder, PrismGraph *graph, uint32_t node_id, uint32_t offset, uint32_t value_id) {
    PrismInsn *insn = make_insn(builder, graph, kPrismInsnReturn, node_id, offset, 1);
    graph->opnds.mem[insn->opnds_idx] = value_id;
}

static uint32_t
compile_node(PrismBuilder *builder, PrismGraph *graph, const pm_node_t *node) {
    switch (PM_NODE_TYPE(node)) {
        case PM_FALSE_NODE: {
            uint32_t object_id = make_object(graph, kPrismObjectFalse);
            return emit_load_object(builder, graph, node->node_id, node->location.start, object_id);
        }
        case PM_FLOAT_NODE: {
            const pm_float_node_t *cast = (const pm_float_node_t *) node;

            uint32_t object_id = make_object(graph, kPrismObjectFloat);
            graph->objects.mem[object_id].as.floating.value = cast->value;

            return emit_load_object(builder, graph, node->node_id, node->location.start, object_id);
        }
        case PM_INTEGER_NODE: {
            const pm_integer_node_t *cast = (const pm_integer_node_t *) node;

            uint32_t object_id = make_object(graph, kPrismObjectInteger);
            graph->objects.mem[object_id].as.integer.value = &cast->value;

            return emit_load_object(builder, graph, node->node_id, node->location.start, object_id);
        }
        case PM_NIL_NODE: {
            uint32_t object_id = make_object(graph, kPrismObjectNil);
            return emit_load_object(builder, graph, node->node_id, node->location.start, object_id);
        }
        case PM_PROGRAM_NODE: {
            const pm_program_node_t *cast = (const pm_program_node_t *) node;
            const pm_statements_node_t *statements = (const pm_statements_node_t *) cast->statements;

            builder->block_id = make_block(graph);
            uint32_t value_id;

            if (statements->body.size) {
                value_id = compile_node(builder, graph, PM_NODE_UPCAST(statements));
            } else {
                value_id = emit_load_nil(builder, graph, node->node_id, node->location.start);
            }

            emit_return(builder, graph, node->node_id, node->location.start, value_id);
            return UINT32_MAX;
        }
        case PM_SELF_NODE:
            return emit_load_self(builder, graph, node->node_id, node->location.start);
        case PM_STATEMENTS_NODE: {
            const pm_statements_node_t *cast = (const pm_statements_node_t *) node;
            uint32_t value_id;

            for (size_t idx = 0; idx < cast->body.size; ++idx) {
                value_id = compile_node(builder, graph, cast->body.nodes[idx]);
            }

            return value_id;
        }
        case PM_TRUE_NODE: {
            uint32_t object_id = make_object(graph, kPrismObjectTrue);
            return emit_load_object(builder, graph, node->node_id, node->location.start, object_id);
        }
        default:
            fprintf(stderr, "Unhandled node type: %s\n", pm_node_type(node->type));
            abort();
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
        case kPrismObjectTrue:
            printf("true");
            break;
    }
}

static void
dump_graph(PrismGraph *graph) {
    for (uint32_t block_id = 0; block_id < graph->blocks.size; ++block_id) {
        PrismBlock *block = &graph->blocks.mem[block_id];
        printf("bb%" PRIu32 ":\n", block_id);

        for (uint32_t insn_id = 0; insn_id < block->insns.size; ++insn_id) {
            PrismInsn *insn = &block->insns.mem[insn_id];
            uint32_t *opnds = &graph->opnds.mem[insn->opnds_idx];

            switch (insn->kind) {
                case kPrismInsnLoadObject: {
                    printf("  %%%" PRIu32 " = load_object ", opnds[0]);
                    dump_object(&graph->objects.mem[insn->as.object.object_id]);
                    printf("\n");
                    break;
                }
                case kPrismInsnLoadSelf:
                    printf("  %%%" PRIu32 " = load_self\n", opnds[0]);
                    break;
                case kPrismInsnReturn:
                    printf("  return %%%" PRIu32 "\n", opnds[0]);
                    break;
            }
        }
    }
}

void
pm_compile(pm_node_t *node) {
    PrismBuilder builder = { 0 };
    PrismGraph graph = { 0 };
    compile_node(&builder, &graph, node);
    dump_graph(&graph);
}
