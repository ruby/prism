/**
 * @file api_compile.c
 *
 * Build the Ruby representation (Prism::Compile::Unit and friends) of a unit
 * produced by the compiler.
 */
#include "prism/extension.h"

extern VALUE rb_cPrism;
extern VALUE rb_cPrismResult;

VALUE rb_cPrismCompileResult;

static VALUE rb_cPrismCompileLocal;
static VALUE rb_cPrismCompileInsn;
static VALUE rb_cPrismCompileBlock;
static VALUE rb_cPrismCompileGraph;
static VALUE rb_cPrismCompileUnit;

static ID
compile_insn_kind(PrismInsnKind kind) {
    switch (kind) {
        case kPrismInsnAliasMethod: return rb_intern_const("alias_method");
        case kPrismInsnBranch: return rb_intern_const("branch");
        case kPrismInsnBranchIf: return rb_intern_const("branch_if");
        case kPrismInsnCallWithBlock: return rb_intern_const("call_with_block");
        case kPrismInsnCall: return rb_intern_const("call");
        case kPrismInsnCoerceHash: return rb_intern_const("coerce_hash");
        case kPrismInsnCoerceString: return rb_intern_const("coerce_string");
        case kPrismInsnDefineClassAbs: return rb_intern_const("define_class_abs");
        case kPrismInsnDefineClassAbsSuper: return rb_intern_const("define_class_abs_super");
        case kPrismInsnDefineClassNestRel: return rb_intern_const("define_class_nest_rel");
        case kPrismInsnDefineClassNestRelSuper: return rb_intern_const("define_class_nest_rel_super");
        case kPrismInsnDefineClassRecvRel: return rb_intern_const("define_class_recv_rel");
        case kPrismInsnDefineClassRecvRelSuper: return rb_intern_const("define_class_recv_rel_super");
        case kPrismInsnDefineMethod: return rb_intern_const("define_method");
        case kPrismInsnDefineModuleAbs: return rb_intern_const("define_module_abs");
        case kPrismInsnDefineModuleNestRel: return rb_intern_const("define_module_nest_rel");
        case kPrismInsnDefineModuleRecvRel: return rb_intern_const("define_module_recv_rel");
        case kPrismInsnDefineSingletonClass: return rb_intern_const("define_singleton_class");
        case kPrismInsnDefineSingletonMethod: return rb_intern_const("define_singleton_method");
        case kPrismInsnDefinedConstAbs: return rb_intern_const("defined_const_abs");
        case kPrismInsnDefinedConstNestRel: return rb_intern_const("defined_const_nest_rel");
        case kPrismInsnDefinedConstRecvRel: return rb_intern_const("defined_const_recv_rel");
        case kPrismInsnDefinedCVar: return rb_intern_const("defined_cvar");
        case kPrismInsnDefinedGVar: return rb_intern_const("defined_gvar");
        case kPrismInsnExtractLastMatchGroup: return rb_intern_const("extract_last_match_group");
        case kPrismInsnExtractLastMatchNamedGroup: return rb_intern_const("extract_last_match_named_group");
        case kPrismInsnExtractLastMatchMatch: return rb_intern_const("extract_last_match_match");
        case kPrismInsnExtractLastMatchParen: return rb_intern_const("extract_last_match_paren");
        case kPrismInsnExtractLastMatchPost: return rb_intern_const("extract_last_match_post");
        case kPrismInsnExtractLastMatchPre: return rb_intern_const("extract_last_match_pre");
        case kPrismInsnNilP: return rb_intern_const("nil_p");
        case kPrismInsnLoadConstAbs: return rb_intern_const("load_const_abs");
        case kPrismInsnLoadConstNestRel: return rb_intern_const("load_const_nest_rel");
        case kPrismInsnLoadConstRecvRel: return rb_intern_const("load_const_recv_rel");
        case kPrismInsnLoadCVar: return rb_intern_const("load_cvar");
        case kPrismInsnLoadGVar: return rb_intern_const("load_gvar");
        case kPrismInsnLoadIVar: return rb_intern_const("load_ivar");
        case kPrismInsnLoadLastMatch: return rb_intern_const("load_last_match");
        case kPrismInsnLoadLVar: return rb_intern_const("load_lvar");
        case kPrismInsnLoadObject: return rb_intern_const("load_object");
        case kPrismInsnLoadSelf: return rb_intern_const("load_self");
        case kPrismInsnMatch: return rb_intern_const("match");
        case kPrismInsnMergeHash: return rb_intern_const("merge_hash");
        case kPrismInsnNewArray: return rb_intern_const("new_array");
        case kPrismInsnNewBlock: return rb_intern_const("new_block");
        case kPrismInsnNewArrayStatic: return rb_intern_const("new_array_static");
        case kPrismInsnNewHash: return rb_intern_const("new_hash");
        case kPrismInsnNewHashStatic: return rb_intern_const("new_hash_static");
        case kPrismInsnNewRangeExc: return rb_intern_const("new_range_exc");
        case kPrismInsnNewRangeInc: return rb_intern_const("new_range_inc");
        case kPrismInsnNewRegexp: return rb_intern_const("new_regexp");
        case kPrismInsnNewString: return rb_intern_const("new_string");
        case kPrismInsnNewSymbol: return rb_intern_const("new_symbol");
        case kPrismInsnPostExecution: return rb_intern_const("post_execution");
        case kPrismInsnReturn: return rb_intern_const("return");
        case kPrismInsnStoreConstAbs: return rb_intern_const("store_const_abs");
        case kPrismInsnStoreConstNestRel: return rb_intern_const("store_const_nest_rel");
        case kPrismInsnStoreConstRecvRel: return rb_intern_const("store_const_recv_rel");
        case kPrismInsnStoreCVar: return rb_intern_const("store_cvar");
        case kPrismInsnStoreGVar: return rb_intern_const("store_gvar");
        case kPrismInsnStoreIVar: return rb_intern_const("store_ivar");
        case kPrismInsnStoreLVar: return rb_intern_const("store_lvar");
        case kPrismInsnTraceBCall: return rb_intern_const("trace_b_call");
        case kPrismInsnTraceBReturn: return rb_intern_const("trace_b_return");
        case kPrismInsnTraceCall: return rb_intern_const("trace_call");
        case kPrismInsnTraceClass: return rb_intern_const("trace_class");
        case kPrismInsnTraceEnd: return rb_intern_const("trace_end");
        case kPrismInsnTraceLine: return rb_intern_const("trace_line");
        case kPrismInsnTraceReturn: return rb_intern_const("trace_return");
        case kPrismInsnYield: return rb_intern_const("yield");
        case kPrismInsnUndefMethod: return rb_intern_const("undef_method");
    }
}

/**
 * Freeze the given value if requested, and return it.
 */
static inline VALUE
compile_freeze(VALUE value, bool freeze) {
    if (freeze) rb_obj_freeze(value);
    return value;
}

/**
 * Build the data attached to an instruction. Arrays that are created here are
 * frozen along with the rest of the unit when requested.
 */
static VALUE
compile_insn_data(VALUE vobjects_unit, VALUE vlocals_unit, VALUE vgraphs, VALUE vblocks, const pm_parser_t *parser, const PrismGraph *graph, const PrismInsn *insn, PrismInsnKind kind, bool freeze) {
    switch (kind) {
        case kPrismInsnBranch:
            return rb_ary_entry(vblocks, pm_insn_branch_block_id(insn));
        case kPrismInsnBranchIf: {
            VALUE then_block = rb_ary_entry(vblocks, pm_insn_branchif_then_block_id(insn));
            VALUE else_block = rb_ary_entry(vblocks, pm_insn_branchif_else_block_id(insn));
            VALUE then_nopnds = UINT2NUM(pm_insn_branchif_then_nopnds(insn));
            return compile_freeze(rb_ary_new_from_args(3, then_block, else_block, then_nopnds), freeze);
        }
        case kPrismInsnExtractLastMatchNamedGroup:
        case kPrismInsnCallWithBlock:
        case kPrismInsnCall:
        case kPrismInsnDefinedConstAbs:
        case kPrismInsnDefinedConstNestRel:
        case kPrismInsnDefinedConstRecvRel:
        case kPrismInsnDefinedCVar:
        case kPrismInsnDefinedGVar:
        case kPrismInsnLoadCVar:
        case kPrismInsnLoadGVar:
        case kPrismInsnLoadIVar:
        case kPrismInsnStoreConstAbs:
        case kPrismInsnStoreConstNestRel:
        case kPrismInsnStoreConstRecvRel:
        case kPrismInsnStoreCVar:
        case kPrismInsnStoreGVar:
        case kPrismInsnStoreIVar: {
            const pm_constant_t *constant = pm_insn_name(parser, insn);
            return ID2SYM(rb_intern2((const char *) pm_constant_start(constant), pm_constant_length(constant)));
        }
        case kPrismInsnDefineClassAbs:
        case kPrismInsnDefineClassAbsSuper:
        case kPrismInsnDefineClassNestRel:
        case kPrismInsnDefineClassNestRelSuper:
        case kPrismInsnDefineClassRecvRel:
        case kPrismInsnDefineClassRecvRelSuper:
        case kPrismInsnDefineModuleAbs:
        case kPrismInsnDefineModuleNestRel:
        case kPrismInsnDefineModuleRecvRel:
        case kPrismInsnDefineMethod:
        case kPrismInsnDefineSingletonMethod: {
            const pm_constant_t *constant = pm_insn_define_name(parser, insn);
            VALUE name = ID2SYM(rb_intern2((const char *) pm_constant_start(constant), pm_constant_length(constant)));
            VALUE graph = rb_ary_entry(vgraphs, pm_insn_define_graph_id(insn));
            return compile_freeze(rb_ary_new_from_args(2, name, graph), freeze);
        }
        case kPrismInsnDefineSingletonClass:
            return rb_ary_entry(vgraphs, pm_insn_define_singleton_class_graph_id(insn));
        case kPrismInsnNewBlock:
            return rb_ary_entry(vgraphs, pm_insn_new_block_graph_id(insn));
        case kPrismInsnPostExecution:
            return rb_ary_entry(vgraphs, pm_insn_post_execution_graph_id(insn));
        case kPrismInsnExtractLastMatchGroup:
            return UINT2NUM(pm_insn_extract_group_number(insn));
        case kPrismInsnLoadConstAbs:
        case kPrismInsnLoadConstNestRel:
        case kPrismInsnLoadConstRecvRel: {
            const PrismConstantPath *constant_path = pm_insn_constant_path(insn);
            uint32_t size = PrismConstantPath_size(constant_path);

            VALUE parts = rb_ary_new_capa(size);
            for (uint32_t idx = 0; idx < size; ++idx) {
                const pm_constant_t *constant = PrismConstantPath_constant(parser, constant_path, idx);
                rb_ary_push(parts, ID2SYM(rb_intern2((const char *) pm_constant_start(constant), pm_constant_length(constant))));
            }

            return compile_freeze(parts, freeze);
        }
        case kPrismInsnLoadLVar:
        case kPrismInsnStoreLVar:
            return rb_ary_entry(vlocals_unit, pm_insn_local_id(insn));
        case kPrismInsnLoadObject:
        case kPrismInsnNewArrayStatic:
        case kPrismInsnNewHashStatic:
            return rb_ary_entry(vobjects_unit, pm_insn_object_id(insn));
        case kPrismInsnNewRegexp:
            return UINT2NUM(pm_insn_regexp_flags(insn));
        case kPrismInsnTraceLine:
            return INT2NUM(pm_insn_trace_lineno(insn));
        default:
            return Qnil;
    }
}

/**
 * Build the Ruby representation of the given compiled unit. When freeze is set,
 * the unit and every graph, block, instruction, and local within it are frozen
 * along with the arrays that hold them.
 */
VALUE
pm_compile_unit_new(const pm_parser_t *parser, const PrismUnit *unit, bool freeze) {
    uint32_t nobjects_unit = pm_unit_nobjects(unit);
    VALUE vobjects_unit = rb_ary_new_capa(nobjects_unit);
    rb_encoding *encoding = rb_enc_find(pm_parser_encoding_name(parser));

    for (uint32_t object_id = 0; object_id < nobjects_unit; ++object_id) {
        const PrismObject *object = pm_unit_object(unit, object_id);
        VALUE vobject;

        switch (pm_object_kind(object)) {
            case kPrismObjectArray: {
                uint32_t size = pm_object_array_size(object);
                vobject = rb_ary_new_capa(size);
                for (uint32_t idx = 0; idx < size; ++idx) {
                    rb_ary_push(vobject, rb_ary_entry(vobjects_unit, pm_object_array_object_id(object, idx)));
                }
                break;
            }
            case kPrismObjectHash: {
                uint32_t size = pm_object_hash_size(object);

                VALUE vbulk = rb_ary_hidden_new(size * 2);
                for (uint32_t idx = 0; idx < size; ++idx) {
                    VALUE vpair[] = {
                        rb_ary_entry(vobjects_unit, pm_object_hash_key_object_id(object, idx)),
                        rb_ary_entry(vobjects_unit, pm_object_hash_value_object_id(object, idx))
                    };

                    rb_ary_cat(vbulk, vpair, 2);
                }

                vobject = rb_hash_new();
                rb_hash_bulk_insert(RARRAY_LEN(vbulk), RARRAY_CONST_PTR(vbulk), vobject);
                break;
            }
            case kPrismObjectRegexp: {
                const pm_string_t *string = pm_object_string(object);
                pm_node_flags_t flags = pm_object_flags(object);
                vobject = rb_reg_new((const char *) pm_string_source(string), pm_string_length(string), (flags >> 2) & 7);
                break;
            }
            case kPrismObjectString: {
                const pm_string_t *string = pm_object_string(object);
                vobject = rb_enc_str_new((const char *) pm_string_source(string), pm_string_length(string), encoding);
                break;
            }
            case kPrismObjectSymbol: {
                const pm_string_t *string = pm_object_string(object);
                vobject = ID2SYM(rb_intern3((const char *) pm_string_source(string), pm_string_length(string), encoding));
                break;
            }
            case kPrismObjectEncoding: vobject = rb_enc_from_encoding(rb_enc_find(pm_object_encoding_name(object))); break;
            case kPrismObjectFalse: vobject = Qfalse; break;
            case kPrismObjectFloat: vobject = DBL2NUM(pm_object_float(object)); break;
            case kPrismObjectImaginary: vobject = rb_complex_raw(INT2FIX(0), rb_ary_entry(vobjects_unit, pm_object_imaginary_object_id(object))); break;
            case kPrismObjectInteger: vobject = pm_integer_new(pm_object_integer(object)); break;
            case kPrismObjectNil: vobject = Qnil; break;
            case kPrismObjectRational: vobject = rb_rational_new(pm_integer_new(pm_object_rational_numerator(object)), pm_integer_new(pm_object_rational_denominator(object))); break;
            case kPrismObjectTrue: vobject = Qtrue; break;
        }

        rb_ary_push(vobjects_unit, vobject);
    }

    uint32_t nlocals_unit = pm_unit_nlocals(unit);
    VALUE vlocals_unit = rb_ary_new_capa(nlocals_unit);

    for (uint32_t local_id = 0; local_id < nlocals_unit; ++local_id) {
        const PrismLocal *local = pm_unit_local(unit, local_id);
        const pm_constant_t *constant = pm_local_name(parser, local);
        VALUE vlocal_argv[] = { UINT2NUM(local_id), ID2SYM(rb_intern2((const char *) pm_constant_start(constant), pm_constant_length(constant))) };
        VALUE vlocal = compile_freeze(rb_class_new_instance(2, vlocal_argv, rb_cPrismCompileLocal), freeze);
        rb_ary_push(vlocals_unit, vlocal);
    }

    uint32_t ngraphs = pm_unit_ngraphs(unit);
    VALUE vgraphs = rb_ary_new_capa(ngraphs);

    for (uint32_t graph_id = 0; graph_id < ngraphs; ++graph_id) {
        const PrismGraph *graph = pm_unit_graph(unit, graph_id);

        VALUE vgraph_kind;
        switch (pm_graph_kind(graph)) {
            case kPrismGraphBlock: vgraph_kind = ID2SYM(rb_intern("block")); break;
            case kPrismGraphClass: vgraph_kind = ID2SYM(rb_intern("class")); break;
            case kPrismGraphDef: vgraph_kind = ID2SYM(rb_intern("def")); break;
            case kPrismGraphModule: vgraph_kind = ID2SYM(rb_intern("module")); break;
            case kPrismGraphPostExecution: vgraph_kind = ID2SYM(rb_intern("post_execution")); break;
            case kPrismGraphProgram: vgraph_kind = ID2SYM(rb_intern("program")); break;
            case kPrismGraphSingletonClass: vgraph_kind = ID2SYM(rb_intern("singleton_class")); break;
        }

        VALUE vparent = Qnil;
        uint32_t parent_id = pm_graph_parent_id(graph);
        if (parent_id != UINT32_MAX) {
            vparent = rb_ary_entry(vgraphs, parent_id);
        }

        uint32_t nblocks = pm_graph_nblocks(graph);
        VALUE vblocks = rb_ary_new_capa(nblocks);
        for (uint32_t block_id = 0; block_id < nblocks; ++block_id) {
            const PrismBlock *block = pm_graph_block(graph, block_id);

            uint32_t ninsns = pm_block_ninsns(block);
            VALUE vinsns = rb_ary_new_capa(ninsns);

            uint32_t nparams = pm_block_nparams(block);
            VALUE vparams = rb_ary_new_capa(nparams);
            for (uint32_t param_idx = 0; param_idx < nparams; ++param_idx) {
                uint32_t param = pm_block_param(block, param_idx);
                rb_ary_push(vparams, UINT2NUM(param));
            }
            compile_freeze(vparams, freeze);

            /* The instructions array is filled in once every graph and block
             * exists, since instructions refer to them. It is frozen then. */
            VALUE vblock_argv[] = { UINT2NUM(block_id), vinsns, vparams, pm_block_autosplat(block) ? Qtrue : Qfalse };
            VALUE vblock = compile_freeze(rb_class_new_instance(4, vblock_argv, rb_cPrismCompileBlock), freeze);
            rb_ary_push(vblocks, vblock);
        }
        compile_freeze(vblocks, freeze);

        uint32_t nlocals = pm_graph_nlocals(graph);
        VALUE vlocals = rb_ary_new_capa(nlocals);
        for (uint32_t local_idx = 0; local_idx < nlocals; ++local_idx) {
            uint32_t local_id = pm_graph_local_id(graph, local_idx);
            rb_ary_push(vlocals, rb_ary_entry(vlocals_unit, local_id));
        }
        compile_freeze(vlocals, freeze);

        uint32_t nvalues = pm_graph_nvalues(graph);
        VALUE vnvalues = UINT2NUM(nvalues);

        uint32_t scope_id = pm_graph_scope_id(graph);
        VALUE vscope = scope_id == graph_id ? Qnil : rb_ary_entry(vgraphs, scope_id);
        VALUE vgraph_argv[] = { UINT2NUM(graph_id), vgraph_kind, vparent, vscope, vblocks, vlocals, vnvalues };
        VALUE vgraph = compile_freeze(rb_class_new_instance(7, vgraph_argv, rb_cPrismCompileGraph), freeze);
        rb_ary_push(vgraphs, vgraph);
    }
    compile_freeze(vgraphs, freeze);

    VALUE vunit_argv[] = { vgraphs };
    VALUE vunit = compile_freeze(rb_class_new_instance(1, vunit_argv, rb_cPrismCompileUnit), freeze);

    for (uint32_t graph_id = 0; graph_id < ngraphs; ++graph_id) {
        const PrismGraph *graph = pm_unit_graph(unit, graph_id);

        VALUE vgraph = rb_ary_entry(vgraphs, graph_id);
        VALUE vblocks = rb_ivar_get(vgraph, rb_intern_const("@blocks"));

        for (uint32_t block_id = 0; block_id < pm_graph_nblocks(graph); ++block_id) {
            const PrismBlock *block = pm_graph_block(graph, block_id);

            VALUE vblock = rb_ary_entry(vblocks, block_id);
            VALUE vinsns = rb_ivar_get(vblock, rb_intern_const("@insns"));

            for (uint32_t insn_idx = 0; insn_idx < pm_block_ninsns(block); ++insn_idx) {
                const PrismInsn *insn = pm_block_insn(block, insn_idx);

                PrismInsnKind kind = pm_insn_kind(insn);
                VALUE vkind = ID2SYM(compile_insn_kind(kind));

                uint32_t nopnds = pm_insn_nopnds(insn);
                VALUE vopnds = rb_ary_new_capa(nopnds);
                for (uint32_t opnd_idx = 0; opnd_idx < nopnds; ++opnd_idx) {
                    uint32_t opnd = pm_insn_opnd(graph, insn, opnd_idx);
                    rb_ary_push(vopnds, UINT2NUM(opnd));
                }
                compile_freeze(vopnds, freeze);

                VALUE vdata = compile_insn_data(vobjects_unit, vlocals_unit, vgraphs, vblocks, parser, graph, insn, kind, freeze);

                uint32_t node_id = pm_insn_node_id(insn);
                VALUE vnode_id = UINT2NUM(node_id);

                VALUE vinsn_argv[] = { vkind, vnode_id, vopnds, vdata };
                VALUE vinsn = compile_freeze(rb_class_new_instance(4, vinsn_argv, rb_cPrismCompileInsn), freeze);
                rb_ary_push(vinsns, vinsn);
            }

            compile_freeze(vinsns, freeze);
        }
    }

    return vunit;
}

/**
 * Define the classes that make up the Ruby representation of a compiled unit.
 */
void
Init_prism_api_compile(void) {
    VALUE rb_cPrismCompile = rb_define_module_under(rb_cPrism, "Compile");
    rb_cPrismCompileResult = rb_define_class_under(rb_cPrismCompile, "Result", rb_cPrismResult);
    rb_cPrismCompileLocal = rb_define_class_under(rb_cPrismCompile, "Local", rb_cObject);
    rb_cPrismCompileInsn = rb_define_class_under(rb_cPrismCompile, "Insn", rb_cObject);
    rb_cPrismCompileBlock = rb_define_class_under(rb_cPrismCompile, "Block", rb_cObject);
    rb_cPrismCompileGraph = rb_define_class_under(rb_cPrismCompile, "Graph", rb_cObject);
    rb_cPrismCompileUnit = rb_define_class_under(rb_cPrismCompile, "Unit", rb_cObject);
}
