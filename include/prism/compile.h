/**
 * @file compile.h
 *
 * Compile the Prism AST to a CFG.
 */
#ifndef PRISM_COMPILE_H
#define PRISM_COMPILE_H

#include "prism/compiler/exported.h"

#include "prism/ast.h"
#include "prism/parser.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct PrismUnit PrismUnit;
typedef struct PrismLocal PrismLocal;
typedef struct PrismGraph PrismGraph;
typedef struct PrismBlock PrismBlock;
typedef struct PrismInsn PrismInsn;
typedef struct PrismConstantPath PrismConstantPath;
typedef struct PrismObject PrismObject;

typedef enum {
    kPrismInsnAliasMethod,
    kPrismInsnBranch,
    kPrismInsnBranchIf,
    kPrismInsnCall,
    kPrismInsnCoerceHash,
    kPrismInsnCoerceString,
    kPrismInsnDefineClassAbs,
    kPrismInsnDefineClassAbsSuper,
    kPrismInsnDefineClassNestRel,
    kPrismInsnDefineClassNestRelSuper,
    kPrismInsnDefineClassRecvRel,
    kPrismInsnDefineClassRecvRelSuper,
    kPrismInsnDefineMethod,
    kPrismInsnDefineSingletonClass,
    kPrismInsnDefinedCVar,
    kPrismInsnDefinedGVar,
    kPrismInsnExtractLastMatchGroup,
    kPrismInsnExtractLastMatchMatch,
    kPrismInsnExtractLastMatchParen,
    kPrismInsnExtractLastMatchPost,
    kPrismInsnExtractLastMatchPre,
    kPrismInsnLoadConstAbs,
    kPrismInsnLoadConstNestRel,
    kPrismInsnLoadConstRecvRel,
    kPrismInsnLoadCVar,
    kPrismInsnLoadGVar,
    kPrismInsnLoadIVar,
    kPrismInsnLoadLastMatch,
    kPrismInsnLoadLVar,
    kPrismInsnLoadObject,
    kPrismInsnLoadSelf,
    kPrismInsnMatch,
    kPrismInsnMergeHash,
    kPrismInsnNewArray,
    kPrismInsnNewArrayStatic,
    kPrismInsnNewHash,
    kPrismInsnNewHashStatic,
    kPrismInsnNewRangeInc,
    kPrismInsnNewRangeExc,
    kPrismInsnNewRegexp,
    kPrismInsnNewString,
    kPrismInsnNewSymbol,
    kPrismInsnReturn,
    kPrismInsnStoreConstAbs,
    kPrismInsnStoreConstNestRel,
    kPrismInsnStoreConstRecvRel,
    kPrismInsnStoreCVar,
    kPrismInsnStoreGVar,
    kPrismInsnStoreIVar,
    kPrismInsnStoreLVar,
    kPrismInsnTraceCall,
    kPrismInsnTraceClass,
    kPrismInsnTraceEnd,
    kPrismInsnTraceLine,
    kPrismInsnTraceReturn,
    kPrismInsnUndefMethod
} PrismInsnKind;

typedef enum {
    kPrismGraphClass,
    kPrismGraphDef,
    kPrismGraphProgram,
    kPrismGraphSingletonClass
} PrismGraphKind;

typedef enum {
    kPrismObjectArray,
    kPrismObjectEncoding,
    kPrismObjectFalse,
    kPrismObjectFloat,
    kPrismObjectHash,
    kPrismObjectImaginary,
    kPrismObjectInteger,
    kPrismObjectNil,
    kPrismObjectRational,
    kPrismObjectRegexp,
    kPrismObjectString,
    kPrismObjectSymbol,
    kPrismObjectTrue
} PrismObjectKind;

PRISM_EXPORTED_FUNCTION PrismUnit * pm_unit_new(void);
PRISM_EXPORTED_FUNCTION uint32_t pm_unit_nobjects(const PrismUnit *unit);
PRISM_EXPORTED_FUNCTION const PrismObject * pm_unit_object(const PrismUnit *unit, uint32_t object_id);
PRISM_EXPORTED_FUNCTION PrismObjectKind pm_object_kind(const PrismObject *object);
PRISM_EXPORTED_FUNCTION uint32_t pm_unit_nlocals(const PrismUnit *unit);
PRISM_EXPORTED_FUNCTION const PrismLocal * pm_unit_local(const PrismUnit *unit, uint32_t local_id);
PRISM_EXPORTED_FUNCTION const pm_constant_t * pm_local_name(const pm_parser_t *parser, const PrismLocal *local);
PRISM_EXPORTED_FUNCTION uint32_t pm_unit_ngraphs(const PrismUnit *unit);
PRISM_EXPORTED_FUNCTION const PrismGraph * pm_unit_graph(const PrismUnit *unit, uint32_t graph_id);
PRISM_EXPORTED_FUNCTION PrismGraphKind pm_graph_kind(const PrismGraph *graph);
PRISM_EXPORTED_FUNCTION uint32_t pm_graph_parent_id(const PrismGraph *graph);
PRISM_EXPORTED_FUNCTION uint32_t pm_graph_nblocks(const PrismGraph *graph);
PRISM_EXPORTED_FUNCTION const PrismBlock * pm_graph_block(const PrismGraph *graph, uint32_t block_id);
PRISM_EXPORTED_FUNCTION uint32_t pm_graph_nlocals(const PrismGraph *graph);
PRISM_EXPORTED_FUNCTION uint32_t pm_graph_local_id(const PrismGraph *graph, uint32_t local_idx);
PRISM_EXPORTED_FUNCTION uint32_t pm_block_ninsns(const PrismBlock *block);
PRISM_EXPORTED_FUNCTION uint32_t pm_block_nparams(const PrismBlock *block);
PRISM_EXPORTED_FUNCTION uint32_t pm_block_param(const PrismBlock *block, uint32_t param_idx);
PRISM_EXPORTED_FUNCTION const PrismInsn * pm_block_insn(const PrismBlock *block, uint32_t insn_idx);
PRISM_EXPORTED_FUNCTION PrismInsnKind pm_insn_kind(const PrismInsn *insn);
PRISM_EXPORTED_FUNCTION uint32_t pm_insn_node_id(const PrismInsn *insn);
PRISM_EXPORTED_FUNCTION uint32_t pm_insn_nopnds(const PrismInsn *insn);
PRISM_EXPORTED_FUNCTION uint32_t pm_insn_opnd(const PrismGraph *graph, const PrismInsn *insn, uint32_t opnd_idx);

PRISM_EXPORTED_FUNCTION uint32_t pm_object_array_size(const PrismObject *object);
PRISM_EXPORTED_FUNCTION uint32_t pm_object_array_object_id(const PrismObject *object, uint32_t idx);
PRISM_EXPORTED_FUNCTION const char * pm_object_encoding_name(const PrismObject *object);
PRISM_EXPORTED_FUNCTION double pm_object_float(const PrismObject *object);
PRISM_EXPORTED_FUNCTION uint32_t pm_object_hash_size(const PrismObject *object);
PRISM_EXPORTED_FUNCTION uint32_t pm_object_hash_key_object_id(const PrismObject *object, uint32_t idx);
PRISM_EXPORTED_FUNCTION uint32_t pm_object_hash_value_object_id(const PrismObject *object, uint32_t idx);
PRISM_EXPORTED_FUNCTION uint32_t pm_object_imaginary_object_id(const PrismObject *object);
PRISM_EXPORTED_FUNCTION const pm_integer_t * pm_object_integer(const PrismObject *object);
PRISM_EXPORTED_FUNCTION const pm_integer_t * pm_object_rational_numerator(const PrismObject *object);
PRISM_EXPORTED_FUNCTION const pm_integer_t * pm_object_rational_denominator(const PrismObject *object);
PRISM_EXPORTED_FUNCTION const pm_string_t * pm_object_string(const PrismObject *object);
PRISM_EXPORTED_FUNCTION pm_node_flags_t pm_object_flags(const PrismObject *object);

PRISM_EXPORTED_FUNCTION uint32_t pm_insn_branch_block_id(const PrismInsn *insn);
PRISM_EXPORTED_FUNCTION uint32_t pm_insn_branchif_then_block_id(const PrismInsn *insn);
PRISM_EXPORTED_FUNCTION uint32_t pm_insn_branchif_else_block_id(const PrismInsn *insn);
PRISM_EXPORTED_FUNCTION uint32_t pm_insn_branchif_then_nopnds(const PrismInsn *insn);
PRISM_EXPORTED_FUNCTION const pm_constant_t * pm_insn_name(const pm_parser_t *parser, const PrismInsn *insn);
PRISM_EXPORTED_FUNCTION const pm_constant_t * pm_insn_define_name(const pm_parser_t *parser, const PrismInsn *insn);
PRISM_EXPORTED_FUNCTION uint32_t pm_insn_define_graph_id(const PrismInsn *insn);
PRISM_EXPORTED_FUNCTION uint32_t pm_insn_define_singleton_class_graph_id(const PrismInsn *insn);
PRISM_EXPORTED_FUNCTION uint32_t pm_insn_extract_group_number(const PrismInsn *insn);
PRISM_EXPORTED_FUNCTION const PrismConstantPath * pm_insn_constant_path(const PrismInsn *insn);
PRISM_EXPORTED_FUNCTION uint32_t pm_insn_local_id(const PrismInsn *insn);
PRISM_EXPORTED_FUNCTION uint32_t pm_insn_object_id(const PrismInsn *insn);
PRISM_EXPORTED_FUNCTION pm_node_flags_t pm_insn_regexp_flags(const PrismInsn *insn);
PRISM_EXPORTED_FUNCTION int32_t pm_insn_trace_lineno(const PrismInsn *insn);

PRISM_EXPORTED_FUNCTION uint32_t PrismConstantPath_size(const PrismConstantPath *constant_path);
PRISM_EXPORTED_FUNCTION const pm_constant_t * PrismConstantPath_constant(const pm_parser_t *parser, const PrismConstantPath *constant_path, uint32_t idx);

PRISM_EXPORTED_FUNCTION void pm_compile(const pm_parser_t *parser, const pm_node_t *node, pm_arena_t *arena, PrismUnit *unit);

#ifdef __cplusplus
}
#endif

#endif
