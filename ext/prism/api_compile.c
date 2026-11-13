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
static VALUE rb_cPrismCompileCallInfo;
static VALUE rb_cPrismCompileBlock;
static VALUE rb_cPrismCompileRegion;
static VALUE rb_cPrismCompileGraph;
static VALUE rb_cPrismCompileSignature;
static VALUE rb_cPrismCompileUnit;

static ID
compile_insn_kind(PrismInsnKind kind) {
    switch (kind) {
        case kPrismInsnAliasGVar: return rb_intern_const("alias_gvar");
        case kPrismInsnAliasMethod: return rb_intern_const("alias_method");
        case kPrismInsnBranch: return rb_intern_const("branch");
        case kPrismInsnBranchIf: return rb_intern_const("branch_if");
        case kPrismInsnCall: return rb_intern_const("call");
        case kPrismInsnCoerceArrayToA: return rb_intern_const("coerce_array_to_a");
        case kPrismInsnCoerceArrayToAry: return rb_intern_const("coerce_array_to_ary");
        case kPrismInsnCoerceHash: return rb_intern_const("coerce_hash");
        case kPrismInsnCoerceString: return rb_intern_const("coerce_string");
        case kPrismInsnConcatArray: return rb_intern_const("concat_array");
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
        case kPrismInsnExpandArray: return rb_intern_const("expand_array");
        case kPrismInsnExtractLastMatchGroup: return rb_intern_const("extract_last_match_group");
        case kPrismInsnExtractLastMatchNamedGroup: return rb_intern_const("extract_last_match_named_group");
        case kPrismInsnExtractLastMatchMatch: return rb_intern_const("extract_last_match_match");
        case kPrismInsnExtractLastMatchParen: return rb_intern_const("extract_last_match_paren");
        case kPrismInsnExtractLastMatchPost: return rb_intern_const("extract_last_match_post");
        case kPrismInsnExtractLastMatchPre: return rb_intern_const("extract_last_match_pre");
        case kPrismInsnNilP: return rb_intern_const("nil_p");
        case kPrismInsnLoadBlock: return rb_intern_const("load_block");
        case kPrismInsnLoadConstAbs: return rb_intern_const("load_const_abs");
        case kPrismInsnLoadConstNestRel: return rb_intern_const("load_const_nest_rel");
        case kPrismInsnLoadConstRecvRel: return rb_intern_const("load_const_recv_rel");
        case kPrismInsnLoadCVar: return rb_intern_const("load_cvar");
        case kPrismInsnLoadFlipFlop: return rb_intern_const("load_flip_flop");
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
        case kPrismInsnRaisePatternGuard: return rb_intern_const("raise_pattern_guard");
        case kPrismInsnRaisePatternMismatch: return rb_intern_const("raise_pattern_mismatch");
        case kPrismInsnRaisePatternNomatch: return rb_intern_const("raise_pattern_nomatch");
        case kPrismInsnReraise: return rb_intern_const("reraise");
        case kPrismInsnRescueMatch: return rb_intern_const("rescue_match");
        case kPrismInsnRescueMatchArray: return rb_intern_const("rescue_match_array");
        case kPrismInsnReturn: return rb_intern_const("return");
        case kPrismInsnStoreConstAbs: return rb_intern_const("store_const_abs");
        case kPrismInsnStoreConstNestRel: return rb_intern_const("store_const_nest_rel");
        case kPrismInsnStoreConstRecvRel: return rb_intern_const("store_const_recv_rel");
        case kPrismInsnStoreCVar: return rb_intern_const("store_cvar");
        case kPrismInsnStoreFlipFlop: return rb_intern_const("store_flip_flop");
        case kPrismInsnStoreGVar: return rb_intern_const("store_gvar");
        case kPrismInsnStoreIVar: return rb_intern_const("store_ivar");
        case kPrismInsnStoreLVar: return rb_intern_const("store_lvar");
        case kPrismInsnCallSuper: return rb_intern_const("call_super");
        case kPrismInsnTraceBCall: return rb_intern_const("trace_b_call");
        case kPrismInsnTraceBReturn: return rb_intern_const("trace_b_return");
        case kPrismInsnTraceCall: return rb_intern_const("trace_call");
        case kPrismInsnTraceClass: return rb_intern_const("trace_class");
        case kPrismInsnTraceEnd: return rb_intern_const("trace_end");
        case kPrismInsnTraceLine: return rb_intern_const("trace_line");
        case kPrismInsnTraceRescue: return rb_intern_const("trace_rescue");
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
        case kPrismInsnCall:
        case kPrismInsnCallSuper: {
            VALUE name = Qnil;
            if (pm_insn_kind(insn) != kPrismInsnCallSuper) {
                const pm_constant_t *constant = pm_insn_call_name(parser, insn);
                name = ID2SYM(rb_intern2((const char *) pm_constant_start(constant), pm_constant_length(constant)));
            }
            VALUE argv[] = {
                name,
                pm_insn_call_keywords(insn) ? Qtrue : Qfalse,
                pm_insn_call_splat(insn) ? Qtrue : Qfalse,
                pm_insn_call_ignore_visibility(insn) ? Qtrue : Qfalse,
                pm_insn_call_variable_call(insn) ? Qtrue : Qfalse,
                pm_insn_call_block(insn) ? Qtrue : Qfalse,
                pm_insn_call_block_argument(insn) ? Qtrue : Qfalse
            };
            return compile_freeze(rb_class_new_instance(7, argv, rb_cPrismCompileCallInfo), freeze);
        }
        case kPrismInsnExtractLastMatchNamedGroup:
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
        case kPrismInsnExpandArray:
            return compile_freeze(rb_ary_new_from_args(3, UINT2NUM(pm_insn_expand_array_lefts(insn)), UINT2NUM(pm_insn_expand_array_rights(insn)), pm_insn_expand_array_rest(insn) ? Qtrue : Qfalse), freeze);
        case kPrismInsnLoadFlipFlop:
        case kPrismInsnStoreFlipFlop:
            return UINT2NUM(pm_insn_flip_flop_index(insn));
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
            case kPrismObjectRange: {
                uint32_t left_id = pm_object_range_left_id(object);
                uint32_t right_id = pm_object_range_right_id(object);
                bool exclude_end = pm_object_range_exclude_end(object);

                vobject = rb_range_new(rb_ary_entry(vobjects_unit, left_id), rb_ary_entry(vobjects_unit, right_id), exclude_end);
                break;
            }
            case kPrismObjectRegexp: {
                const pm_string_t *string = pm_object_string(object);
                pm_node_flags_t flags = pm_object_flags(object);
                vobject = rb_reg_new((const char *) pm_string_source(string), pm_string_length(string), (flags >> 2) & 7);
                break;
            }
            case kPrismObjectStandardError:
                vobject = rb_eStandardError;
                break;
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
            case kPrismGraphLambda: vgraph_kind = ID2SYM(rb_intern("lambda")); break;
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

        uint32_t nregions = pm_graph_nregions(graph);
        VALUE vregions = rb_ary_new_capa(nregions);

        for (uint32_t region_id = 0; region_id < nregions; ++region_id) {
            const PrismRegion *region = pm_graph_region(graph, region_id);

            VALUE vkind;
            switch (pm_region_kind(region)) {
                case kPrismRegionDefault: vkind = ID2SYM(rb_intern_const("default")); break;
                case kPrismRegionRescue: vkind = ID2SYM(rb_intern_const("rescue")); break;
                case kPrismRegionEnsure: vkind = ID2SYM(rb_intern_const("ensure")); break;
            }

            uint32_t parent_id = pm_region_parent_id(region);
            uint32_t handler_id = pm_region_handler_block_id(region);
            assert(parent_id == UINT32_MAX || parent_id < region_id);

            VALUE argv[] = {
                UINT2NUM(region_id),
                vkind,
                parent_id == UINT32_MAX ? Qnil : rb_ary_entry(vregions, parent_id),
                vblocks,
                UINT2NUM(pm_region_entry_block_id(region)),
                handler_id == UINT32_MAX ? Qnil : UINT2NUM(handler_id)
            };

            rb_ary_push(vregions, compile_freeze(rb_class_new_instance(6, argv, rb_cPrismCompileRegion), freeze));
        }

        compile_freeze(vregions, freeze);

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

            VALUE vblock_argv[] = {
                UINT2NUM(block_id),
                vinsns,
                vparams,
                rb_ary_entry(vregions, pm_block_region_id(block))
            };

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

        const PrismSignature *signature = pm_graph_signature(graph);
        uint32_t nrequired_ids = pm_signature_nrequired_ids(signature);
        VALUE vrequired_ids = rb_ary_new_capa(nrequired_ids);
        for (uint32_t required_idx = 0; required_idx < nrequired_ids; ++required_idx) {
            rb_ary_push(vrequired_ids, UINT2NUM(pm_signature_required_id(signature, required_idx)));
        }
        compile_freeze(vrequired_ids, freeze);

        uint32_t noptional_ids = pm_signature_noptional_ids(signature);
        VALUE voptional_ids = rb_ary_new_capa(noptional_ids);
        VALUE voptional_specified_ids = rb_ary_new_capa(noptional_ids);
        for (uint32_t optional_idx = 0; optional_idx < noptional_ids; ++optional_idx) {
            rb_ary_push(voptional_ids, UINT2NUM(pm_signature_optional_id(signature, optional_idx)));
            rb_ary_push(voptional_specified_ids, UINT2NUM(pm_signature_optional_specified_id(signature, optional_idx)));
        }
        compile_freeze(voptional_ids, freeze);
        compile_freeze(voptional_specified_ids, freeze);

        uint32_t npost_ids = pm_signature_npost_ids(signature);
        VALUE vpost_ids = rb_ary_new_capa(npost_ids);
        for (uint32_t post_idx = 0; post_idx < npost_ids; ++post_idx) {
            rb_ary_push(vpost_ids, UINT2NUM(pm_signature_post_id(signature, post_idx)));
        }
        compile_freeze(vpost_ids, freeze);

        uint32_t nrequired_keyword_ids = pm_signature_nrequired_keyword_ids(signature);
        VALUE vrequired_keywords = rb_hash_new();
        for (uint32_t keyword_idx = 0; keyword_idx < nrequired_keyword_ids; ++keyword_idx) {
            const pm_constant_t *name = pm_signature_required_keyword_name(parser, signature, keyword_idx);
            VALUE key = ID2SYM(rb_intern2((const char *) pm_constant_start(name), pm_constant_length(name)));
            rb_hash_aset(vrequired_keywords, key, UINT2NUM(pm_signature_required_keyword_id(signature, keyword_idx)));
        }
        compile_freeze(vrequired_keywords, freeze);

        uint32_t noptional_keyword_ids = pm_signature_noptional_keyword_ids(signature);
        VALUE voptional_keywords = rb_hash_new();
        VALUE voptional_keyword_specifieds = rb_hash_new();
        for (uint32_t keyword_idx = 0; keyword_idx < noptional_keyword_ids; ++keyword_idx) {
            const pm_constant_t *name = pm_signature_optional_keyword_name(parser, signature, keyword_idx);
            VALUE key = ID2SYM(rb_intern2((const char *) pm_constant_start(name), pm_constant_length(name)));
            rb_hash_aset(voptional_keywords, key, UINT2NUM(pm_signature_optional_keyword_id(signature, keyword_idx)));
            rb_hash_aset(voptional_keyword_specifieds, key, UINT2NUM(pm_signature_optional_keyword_specified_id(signature, keyword_idx)));
        }
        compile_freeze(voptional_keywords, freeze);
        compile_freeze(voptional_keyword_specifieds, freeze);

        uint32_t rest_id = pm_signature_rest_id(signature);
        uint32_t keyword_rest_id = pm_signature_keyword_rest_id(signature);
        uint32_t block_id = pm_signature_block_id(signature);
        VALUE vsignature_argv[] = {
            vrequired_ids,
            voptional_ids,
            voptional_specified_ids,
            rest_id == UINT32_MAX ? Qnil : UINT2NUM(rest_id),
            vpost_ids,
            vrequired_keywords,
            voptional_keywords,
            voptional_keyword_specifieds,
            keyword_rest_id == UINT32_MAX ? Qnil : UINT2NUM(keyword_rest_id),
            block_id == UINT32_MAX ? Qnil : UINT2NUM(block_id),
            pm_signature_no_keywords(signature) ? Qtrue : Qfalse,
            pm_signature_no_block(signature) ? Qtrue : Qfalse,
            pm_signature_autosplat(signature) ? Qtrue : Qfalse
        };
        VALUE vsignature = compile_freeze(rb_class_new_instance(13, vsignature_argv, rb_cPrismCompileSignature), freeze);

        uint32_t nvalues = pm_graph_nvalues(graph);
        VALUE vnvalues = UINT2NUM(nvalues);

        uint32_t scope_id = pm_graph_scope_id(graph);
        VALUE vscope = scope_id == graph_id ? Qnil : rb_ary_entry(vgraphs, scope_id);

        VALUE vgraph_argv[] = {
            UINT2NUM(graph_id),
            vgraph_kind,
            vparent,
            vscope,
            vblocks,
            vregions,
            vlocals,
            vnvalues,
            UINT2NUM(pm_graph_nflip_flops(graph)),
            vsignature
        };

        VALUE vgraph = compile_freeze(rb_class_new_instance(10, vgraph_argv, rb_cPrismCompileGraph), freeze);
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
    rb_cPrismCompileCallInfo = rb_define_class_under(rb_cPrismCompile, "CallInfo", rb_cObject);
    rb_cPrismCompileInsn = rb_define_class_under(rb_cPrismCompile, "Insn", rb_cObject);
    rb_cPrismCompileRegion = rb_define_class_under(rb_cPrismCompile, "Region", rb_cObject);
    rb_cPrismCompileBlock = rb_define_class_under(rb_cPrismCompile, "Block", rb_cObject);
    rb_cPrismCompileSignature = rb_define_class_under(rb_cPrismCompile, "Signature", rb_cObject);
    rb_cPrismCompileGraph = rb_define_class_under(rb_cPrismCompile, "Graph", rb_cObject);
    rb_cPrismCompileUnit = rb_define_class_under(rb_cPrismCompile, "Unit", rb_cObject);
}
