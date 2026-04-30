#include "prism/internal/comments.h"

#include "prism/compiler/align.h"
#include "prism/internal/allocator.h"
#include "prism/internal/parser.h"
#include "prism/internal/node.h"
#include "prism/internal/line_offset_list.h"

#include <assert.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

/* The context passed around while visiting nodes to attach comments. */
typedef struct {
    pm_parser_t *parser;
    pm_comments_map_t *map;
    const pm_comment_t **comments;
    int32_t min_line;
    int32_t max_line;
} pm_comments_context_t;

#define PM_COMMENTS_UPCAST(value_) ((pm_comments_t *) (value_))
#define PM_COMMENTS_ALLOC(ctx_, type_) ((type_ *) pm_arena_zalloc((ctx_)->parser->arena, sizeof(type_), PRISM_ALIGNOF(type_)))

/******************************************************************************/
/* Functions that create comments objects.                                    */
/******************************************************************************/

static pm_alias_method_comments_t *
pm_alias_method_comments_new(pm_comments_context_t *ctx, pm_comments_list_t *gap_comments) {
    pm_alias_method_comments_t *comments = PM_COMMENTS_ALLOC(ctx, pm_alias_method_comments_t);
    comments->base.type = PM_COMMENTS_ALIAS_METHOD;
    comments->gap_comments = *gap_comments;
    return comments;
}

static pm_binary_comments_t *
pm_binary_comments_new(pm_comments_context_t *ctx, const pm_comment_t *operator_comment, const pm_comments_list_t *gap_comments) {
    pm_binary_comments_t *comments = PM_COMMENTS_ALLOC(ctx, pm_binary_comments_t);
    comments->base.type = PM_COMMENTS_BINARY;
    comments->operator_comment = operator_comment;
    comments->gap_comments = *gap_comments;
    return comments;
}

static pm_body_comments_t *
pm_body_comments_new(pm_comments_context_t *ctx, const pm_comment_t *opening_comment, const pm_comment_t *end_comment) {
    pm_body_comments_t *comments = PM_COMMENTS_ALLOC(ctx, pm_body_comments_t);
    comments->base.type = PM_COMMENTS_BODY;
    comments->opening_comment = opening_comment;
    comments->end_comment = end_comment;
    return comments;
}

static pm_call_comments_t *
pm_call_comments_new(pm_comments_context_t *ctx, const pm_comment_t *trailing_comment, const pm_comments_list_t *receiver_gap, const pm_comment_t *operator_comment, const pm_comments_list_t *message_gap) {
    pm_call_comments_t *comments = PM_COMMENTS_ALLOC(ctx, pm_call_comments_t);
    comments->base.type = PM_COMMENTS_CALL;
    comments->trailing_comment = trailing_comment;
    comments->receiver_gap_comments = *receiver_gap;
    comments->operator_comment = operator_comment;
    comments->message_gap_comments = *message_gap;
    return comments;
}

static pm_call_write_comments_t *
pm_call_write_comments_new(pm_comments_context_t *ctx, const pm_comment_t *call_operator_comment, const pm_comments_list_t *call_gap, const pm_comment_t *operator_comment, const pm_comments_list_t *operator_gap) {
    pm_call_write_comments_t *comments = PM_COMMENTS_ALLOC(ctx, pm_call_write_comments_t);
    comments->base.type = PM_COMMENTS_CALL_WRITE;
    comments->call_operator_comment = call_operator_comment;
    comments->call_gap_comments = *call_gap;
    comments->operator_comment = operator_comment;
    comments->operator_gap_comments = *operator_gap;
    return comments;
}

static pm_case_comments_t *
pm_case_comments_new(pm_comments_context_t *ctx, const pm_comment_t *opening_comment, const pm_comments_list_t *keyword_gap, const pm_comments_list_t *predicate_gap, const pm_comment_t *end_comment) {
    pm_case_comments_t *comments = PM_COMMENTS_ALLOC(ctx, pm_case_comments_t);
    comments->base.type = PM_COMMENTS_CASE;
    comments->opening_comment = opening_comment;
    comments->keyword_gap_comments = *keyword_gap;
    comments->predicate_gap_comments = *predicate_gap;
    comments->end_comment = end_comment;
    return comments;
}

static pm_class_comments_t *
pm_class_comments_new(pm_comments_context_t *ctx, const pm_comment_t *opening_comment, const pm_comments_list_t *keyword_gap_comments, const pm_comment_t *inheritance_operator_comment, const pm_comments_list_t *inheritance_gap_comments, const pm_comment_t *end_comment) {
    pm_class_comments_t *comments = PM_COMMENTS_ALLOC(ctx, pm_class_comments_t);
    comments->base.type = PM_COMMENTS_CLASS;
    comments->opening_comment = opening_comment;
    comments->keyword_gap_comments = *keyword_gap_comments;
    comments->inheritance_operator_comment = inheritance_operator_comment;
    comments->inheritance_gap_comments = *inheritance_gap_comments;
    comments->end_comment = end_comment;
    return comments;
}

static pm_clause_comments_t *
pm_clause_comments_new(pm_comments_context_t *ctx, const pm_comment_t *opening_comment) {
    pm_clause_comments_t *comments = PM_COMMENTS_ALLOC(ctx, pm_clause_comments_t);
    comments->base.type = PM_COMMENTS_CLAUSE;
    comments->opening_comment = opening_comment;
    return comments;
}

static pm_collection_comments_t *
pm_collection_comments_new(pm_comments_context_t *ctx, const pm_comment_t *opening_comment, const pm_comment_t *closing_comment) {
    pm_collection_comments_t *comments = PM_COMMENTS_ALLOC(ctx, pm_collection_comments_t);
    comments->base.type = PM_COMMENTS_COLLECTION;
    comments->opening_comment = opening_comment;
    comments->closing_comment = closing_comment;
    return comments;
}

static pm_def_comments_t *
pm_def_comments_new(pm_comments_context_t *ctx, const pm_comment_t *opening_comment, const pm_comments_list_t *keyword_gap_comments, const pm_comment_t *lparen_comment, const pm_comment_t *rparen_comment, const pm_comment_t *end_comment) {
    pm_def_comments_t *comments = PM_COMMENTS_ALLOC(ctx, pm_def_comments_t);
    comments->base.type = PM_COMMENTS_DEF;
    comments->opening_comment = opening_comment;
    comments->keyword_gap_comments = *keyword_gap_comments;
    comments->lparen_comment = lparen_comment;
    comments->rparen_comment = rparen_comment;
    comments->end_comment = end_comment;
    return comments;
}

static pm_embedded_statements_comments_t *
pm_embedded_statements_comments_new(pm_comments_context_t *ctx, const pm_comment_t *opening_comment) {
    pm_embedded_statements_comments_t *comments = PM_COMMENTS_ALLOC(ctx, pm_embedded_statements_comments_t);
    comments->base.type = PM_COMMENTS_EMBEDDED_STATEMENTS;
    comments->opening_comment = opening_comment;
    return comments;
}

static pm_endless_def_comments_t *
pm_endless_def_comments_new(pm_comments_context_t *ctx, const pm_comment_t *opening_comment, const pm_comments_list_t *keyword_gap_comments, const pm_comment_t *lparen_comment, const pm_comment_t *rparen_comment, const pm_comment_t *operator_comment) {
    pm_endless_def_comments_t *comments = PM_COMMENTS_ALLOC(ctx, pm_endless_def_comments_t);
    comments->base.type = PM_COMMENTS_ENDLESS_DEF;
    comments->opening_comment = opening_comment;
    comments->keyword_gap_comments = *keyword_gap_comments;
    comments->lparen_comment = lparen_comment;
    comments->rparen_comment = rparen_comment;
    comments->operator_comment = operator_comment;
    return comments;
}

static pm_find_pattern_comments_t *
pm_find_pattern_comments_new(pm_comments_context_t *ctx, const pm_comment_t *opening_comment, const pm_comment_t *closing_comment, const pm_comments_list_t *pre_left_gap, const pm_comments_list_t *post_right_gap) {
    pm_find_pattern_comments_t *comments = PM_COMMENTS_ALLOC(ctx, pm_find_pattern_comments_t);
    comments->base.type = PM_COMMENTS_FIND_PATTERN;
    comments->opening_comment = opening_comment;
    comments->closing_comment = closing_comment;
    comments->pre_left_gap_comments = *pre_left_gap;
    comments->post_right_gap_comments = *post_right_gap;
    return comments;
}

static pm_for_comments_t *
pm_for_comments_new(pm_comments_context_t *ctx, const pm_comment_t *for_comment, const pm_comment_t *in_comment, const pm_comment_t *do_comment, const pm_comment_t *end_comment) {
    pm_for_comments_t *comments = PM_COMMENTS_ALLOC(ctx, pm_for_comments_t);
    comments->base.type = PM_COMMENTS_FOR;
    comments->for_comment = for_comment;
    comments->in_comment = in_comment;
    comments->do_comment = do_comment;
    comments->end_comment = end_comment;
    return comments;
}

static pm_hash_pattern_comments_t *
pm_hash_pattern_comments_new(pm_comments_context_t *ctx, const pm_comment_t *opening_comment, const pm_comment_t *closing_comment, const pm_comments_list_t *post_rest_gap) {
    pm_hash_pattern_comments_t *comments = PM_COMMENTS_ALLOC(ctx, pm_hash_pattern_comments_t);
    comments->base.type = PM_COMMENTS_HASH_PATTERN;
    comments->opening_comment = opening_comment;
    comments->closing_comment = closing_comment;
    comments->post_rest_gap_comments = *post_rest_gap;
    return comments;
}

static pm_keyword_call_comments_t *
pm_keyword_call_comments_new(pm_comments_context_t *ctx, const pm_comment_t *lparen_comment, const pm_comment_t *rparen_comment) {
    pm_keyword_call_comments_t *comments = PM_COMMENTS_ALLOC(ctx, pm_keyword_call_comments_t);
    comments->base.type = PM_COMMENTS_KEYWORD_CALL;
    comments->lparen_comment = lparen_comment;
    comments->rparen_comment = rparen_comment;
    return comments;
}

static pm_leaf_comments_t *
pm_leaf_comments_new(pm_comments_context_t *ctx, const pm_comment_t *trailing_comment) {
    pm_leaf_comments_t *comments = PM_COMMENTS_ALLOC(ctx, pm_leaf_comments_t);
    comments->base.type = PM_COMMENTS_LEAF;
    comments->trailing_comment = trailing_comment;
    return comments;
}

static pm_logical_keyword_comments_t *
pm_logical_keyword_comments_new(pm_comments_context_t *ctx, const pm_comment_t *operator_comment, const pm_comments_list_t *left_gap, const pm_comments_list_t *right_gap) {
    pm_logical_keyword_comments_t *comments = PM_COMMENTS_ALLOC(ctx, pm_logical_keyword_comments_t);
    comments->base.type = PM_COMMENTS_LOGICAL_KEYWORD;
    comments->operator_comment = operator_comment;
    comments->left_gap_comments = *left_gap;
    comments->right_gap_comments = *right_gap;
    return comments;
}

static pm_module_comments_t *
pm_module_comments_new(pm_comments_context_t *ctx, const pm_comment_t *opening_comment, const pm_comments_list_t *keyword_gap, const pm_comment_t *end_comment) {
    pm_module_comments_t *comments = PM_COMMENTS_ALLOC(ctx, pm_module_comments_t);
    comments->base.type = PM_COMMENTS_MODULE;
    comments->opening_comment = opening_comment;
    comments->keyword_gap_comments = *keyword_gap;
    comments->end_comment = end_comment;
    return comments;
}

static pm_parenthesized_comments_t *
pm_parenthesized_comments_new(pm_comments_context_t *ctx, const pm_comment_t *opening_comment, const pm_comments_list_t *opening_gap, const pm_comments_list_t *closing_gap) {
    pm_parenthesized_comments_t *comments = PM_COMMENTS_ALLOC(ctx, pm_parenthesized_comments_t);
    comments->base.type = PM_COMMENTS_PARENTHESIZED;
    comments->opening_comment = opening_comment;
    comments->opening_gap_comments = *opening_gap;
    comments->closing_gap_comments = *closing_gap;
    return comments;
}

static pm_prefix_comments_t *
pm_prefix_comments_new(pm_comments_context_t *ctx, const pm_comment_t *operator_comment, const pm_comments_list_t *gap) {
    pm_prefix_comments_t *comments = PM_COMMENTS_ALLOC(ctx, pm_prefix_comments_t);
    comments->base.type = PM_COMMENTS_PREFIX;
    comments->operator_comment = operator_comment;
    comments->gap_comments = *gap;
    return comments;
}

static pm_undef_comments_t *
pm_undef_comments_new(pm_comments_context_t *ctx, const pm_comment_t *keyword_comment, const pm_comments_list_t *inner_comments) {
    pm_undef_comments_t *comments = PM_COMMENTS_ALLOC(ctx, pm_undef_comments_t);
    comments->base.type = PM_COMMENTS_UNDEF;
    comments->keyword_comment = keyword_comment;
    comments->inner_comments = *inner_comments;
    return comments;
}

static pm_arguments_comments_t *
pm_arguments_comments_new(pm_comments_context_t *ctx, const pm_comments_list_t *inner_comments) {
    pm_arguments_comments_t *comments = PM_COMMENTS_ALLOC(ctx, pm_arguments_comments_t);
    comments->base.type = PM_COMMENTS_ARGUMENTS;
    comments->inner_comments = *inner_comments;
    return comments;
}

static pm_keyword_hash_comments_t *
pm_keyword_hash_comments_new(pm_comments_context_t *ctx, const pm_comments_list_t *inner_comments) {
    pm_keyword_hash_comments_t *comments = PM_COMMENTS_ALLOC(ctx, pm_keyword_hash_comments_t);
    comments->base.type = PM_COMMENTS_KEYWORD_HASH;
    comments->inner_comments = *inner_comments;
    return comments;
}

static pm_parameters_comments_t *
pm_parameters_comments_new(pm_comments_context_t *ctx, const pm_comments_list_t *inner_comments) {
    pm_parameters_comments_t *comments = PM_COMMENTS_ALLOC(ctx, pm_parameters_comments_t);
    comments->base.type = PM_COMMENTS_PARAMETERS;
    comments->inner_comments = *inner_comments;
    return comments;
}

/******************************************************************************/
/* Helper functions that are used by the various visitors.                    */
/******************************************************************************/

/* Store comments for a node in the comments map. */
static void
comments_store(pm_comments_context_t *ctx, uint32_t node_id, const pm_comments_t *comments) {
    assert(node_id < ctx->map->size);
    assert(ctx->map->entries[node_id] == NULL);
    ctx->map->entries[node_id] = comments;
}

/* Return the line number for a given byte offset. */
static inline int32_t
comments_line(const pm_comments_context_t *ctx, uint32_t offset) {
    return pm_line_offset_list_line(&ctx->parser->line_offsets, offset, ctx->parser->start_line);
}

/* Return the start line of a node. */
static inline int32_t
comments_node_start_line(const pm_comments_context_t *ctx, const pm_node_t *node) {
    return comments_line(ctx, node->location.start);
}

/* Return the end line of a node. */
static inline int32_t
comments_node_end_line(const pm_comments_context_t *ctx, const pm_node_t *node) {
    uint32_t end_offset = node->location.start + node->location.length;
    return comments_line(ctx, end_offset > 0 ? end_offset - 1 : 0);
}

/* Return the start line of a location. */
static inline int32_t
comments_loc_start_line(const pm_comments_context_t *ctx, pm_location_t loc) {
    return comments_line(ctx, loc.start);
}

/* Return the end line of a location. */
static inline int32_t
comments_loc_end_line(const pm_comments_context_t *ctx, pm_location_t loc) {
    uint32_t end_offset = loc.start + loc.length;
    return comments_line(ctx, end_offset > 0 ? end_offset - 1 : 0);
}

/* Checks if an optional location is set. */
static inline bool
comments_loc_set(pm_location_t loc) {
    return loc.length > 0;
}

/* Claim the comment at a specific line, returning NULL if there is no comment
 * or if the line has already been claimed. */
static const pm_comment_t *
comments_claim_comment(pm_comments_context_t *ctx, int32_t line) {
    if (line < ctx->min_line || line > ctx->max_line) return NULL;

    int32_t idx = line - ctx->min_line;
    const pm_comment_t *comment = ctx->comments[idx];

    /* Clear the comments map at this line so that subsequent claims will not
     * find it. */
    if (comment != NULL) ctx->comments[idx] = NULL;

    return comment;
}

/* Claim comments in the range [start_line, end_line], returning them in a list.
 */
static void
comments_claim_comments(pm_comments_context_t *ctx, int32_t start_line, int32_t end_line, pm_comments_list_t *list) {
    /* First pass: count. */
    size_t size = 0;
    for (int32_t line = start_line; line <= end_line; line++) {
        if (line >= ctx->min_line && line <= ctx->max_line) {
            if (ctx->comments[line - ctx->min_line] != NULL) {
                size++;
            }
        }
    }

    if (size == 0) {
        list->comments = NULL;
        list->size = 0;
        return;
    }

    const pm_comment_t **comments = (const pm_comment_t **) pm_arena_alloc(
        ctx->parser->arena,
        sizeof(pm_comment_t *) * size,
        PRISM_ALIGNOF(pm_comment_t *)
    );

    /* Second pass: collect and clear. */
    size_t index = 0;
    for (int32_t line = start_line; line <= end_line; line++) {
        if (line >= ctx->min_line && line <= ctx->max_line) {
            const pm_comment_t *comment = ctx->comments[line - ctx->min_line];

            if (comment != NULL) {
                comments[index++] = comment;
                ctx->comments[line - ctx->min_line] = NULL;
            }
        }
    }

    list->comments = comments;
    list->size = size;
}

static void comments_visit(pm_comments_context_t *ctx, pm_node_t *node);

/* Visit the children of a node in reverse order, so that later children get to
 * claim comments before earlier children. */
static void
comments_visit_reverse(pm_comments_context_t *ctx, pm_node_list_t *list) {
    for (size_t index = list->size; index > 0; index--) {
        comments_visit(ctx, list->nodes[index - 1]);
    }
}

/* Claim a trailing comment on the end line of the give node if one exists. */
static void
comments_attach_leaf_comments(pm_comments_context_t *ctx, pm_node_t *node) {
    const pm_comment_t *trailing = comments_claim_comment(ctx, comments_node_end_line(ctx, node));

    if (trailing != NULL) {
        comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_leaf_comments_new(ctx, trailing)));
    }
}

/* If the keyword has arguments, then visit them, because that means comments
 * should necessarily be attached to the arguments. Otherwise, attach leaf
 * comments to the bare keyword. */
static void
comments_attach_keyword_comments(pm_comments_context_t *ctx, pm_node_t *node, pm_arguments_node_t *arguments) {
    if (arguments != NULL) {
        comments_visit(ctx, PM_NODE_UPCAST(arguments));
    } else {
        comments_attach_leaf_comments(ctx, node);
    }
}

/* Visit the right, claim the operator, visit the left, then claim any comments
 * in the gap between the start of the node and the end of the right. */
static void
comments_attach_binary_comments(pm_comments_context_t *ctx, pm_node_t *node, pm_node_t *left, pm_node_t *right, pm_location_t operator_loc) {
    comments_visit(ctx, right);
    const pm_comment_t *operator_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, operator_loc));
    comments_visit(ctx, left);
    pm_comments_list_t gap_comments;
    comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &gap_comments);

    if (operator_comment != NULL || gap_comments.size > 0) {
        comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_binary_comments_new(ctx, operator_comment, &gap_comments)));
    }
}

/* Handle "and" and "or" keyword forms which are allowed to have newlines
 * between the left and the operator. */
static void
comments_attach_logical_keyword_comments(pm_comments_context_t *ctx, pm_node_t *node, pm_node_t *left, pm_node_t *right, pm_location_t operator_loc) {
    comments_visit(ctx, right);

    const pm_comment_t *operator_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, operator_loc));
    comments_visit(ctx, left);

    pm_comments_list_t right_gap_comments;
    comments_claim_comments(ctx, comments_loc_end_line(ctx, operator_loc), comments_node_end_line(ctx, node), &right_gap_comments);

    pm_comments_list_t left_gap_comments;
    comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_loc_start_line(ctx, operator_loc), &left_gap_comments);

    if (operator_comment != NULL || left_gap_comments.size > 0 || right_gap_comments.size > 0) {
        comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_logical_keyword_comments_new(ctx, operator_comment, &left_gap_comments, &right_gap_comments)));
    }
}

/* Visit the value, claim the comment on the operator, then claim any comments
 * in the gap between the start of the node and the end of the value. */
static void
comments_attach_write_comments(pm_comments_context_t *ctx, pm_node_t *node, pm_node_t *value, pm_location_t operator_loc) {
    comments_visit(ctx, value);
    const pm_comment_t *operator_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, operator_loc));

    pm_comments_list_t gap_comments;
    comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &gap_comments);

    if (operator_comment != NULL || gap_comments.size > 0) {
        comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_binary_comments_new(ctx, operator_comment, &gap_comments)));
    }
}

/* Visit the child, claim the comment on the operator, then claim any comments
 * in the gap between the start of the node and the end of the child. */
static void
comments_attach_prefix_comments(pm_comments_context_t *ctx, pm_node_t *node, pm_node_t *child, pm_location_t operator_loc) {
    comments_visit(ctx, child);
    const pm_comment_t *operator_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, operator_loc));
    pm_comments_list_t gap_comments;
    comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &gap_comments);

    if (operator_comment != NULL || gap_comments.size > 0) {
        comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_prefix_comments_new(ctx, operator_comment, &gap_comments)));
    }
}

/* If the parameter has a name, claim the operator and gap comments as prefix
 * comments. Otherwise treat the bare operator as a leaf. */
static void
comments_attach_prefix_parameter_comments(pm_comments_context_t *ctx, pm_node_t *node, pm_constant_id_t name, pm_location_t operator_loc) {
    if (name != 0) {
        const pm_comment_t *operator_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, operator_loc));
        pm_comments_list_t gap_comments;
        comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &gap_comments);

        if (operator_comment != NULL || gap_comments.size > 0) {
            comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_prefix_comments_new(ctx, operator_comment, &gap_comments)));
        }
    } else {
        comments_attach_leaf_comments(ctx, node);
    }
}

/* Claim the opening and trailing comments, visit the body, and claim any
 * remaining comments in the body range. */
static void
comments_attach_body_comments_generic(pm_comments_context_t *ctx, pm_node_t *node, pm_location_t opening_loc, pm_location_t closing_loc, pm_statements_node_t **statements_ptr) {
    const pm_comment_t *trailing = comments_claim_comment(ctx, comments_loc_start_line(ctx, closing_loc));
    if (*statements_ptr != NULL) {
        comments_visit(ctx, PM_NODE_UPCAST(*statements_ptr));
    }
    const pm_comment_t *opening = comments_claim_comment(ctx, comments_loc_start_line(ctx, opening_loc));
    pm_comments_list_t body_comments_list;
    comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &body_comments_list);

    if (opening != NULL || trailing != NULL || body_comments_list.size > 0) {
        pm_body_comments_t *c = pm_body_comments_new(ctx, opening, trailing);
        c->body_comments = body_comments_list;
        comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
    }
}

/* Like binary comments, but both left and right are optional. */
static void
comments_attach_range_comments(pm_comments_context_t *ctx, pm_node_t *node, pm_node_t *left, pm_node_t *right, pm_location_t operator_loc) {
    if (right != NULL) comments_visit(ctx, right);
    const pm_comment_t *operator_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, operator_loc));
    if (left != NULL) comments_visit(ctx, left);
    pm_comments_list_t gap_comments;
    comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &gap_comments);

    if (operator_comment != NULL || gap_comments.size > 0) {
        comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_binary_comments_new(ctx, operator_comment, &gap_comments)));
    }
}

/* Claim a trailing comment and visit the interpolated parts in reverse. */
static void
comments_attach_interpolated_comments(pm_comments_context_t *ctx, pm_node_t *node, pm_node_list_t *parts) {
    const pm_comment_t *trailing_comment = comments_claim_comment(ctx, comments_node_end_line(ctx, node));
    comments_visit_reverse(ctx, parts);

    if (trailing_comment != NULL) {
        comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_leaf_comments_new(ctx, trailing_comment)));
    }
}

/* Claim trailing and operator comments, visit the parent, then split gap
 * comments into receiver and message gaps. */
static void
comments_attach_constant_path_comments(pm_comments_context_t *ctx, pm_node_t *node, pm_node_t *parent, pm_location_t delimiter_loc) {
    const pm_comment_t *trailing = comments_claim_comment(ctx, comments_node_end_line(ctx, node));
    const pm_comment_t *operator_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, delimiter_loc));
    if (parent != NULL) comments_visit(ctx, parent);

    int32_t op_line = comments_loc_start_line(ctx, delimiter_loc);
    pm_comments_list_t receiver_gap;
    comments_claim_comments(ctx, comments_node_start_line(ctx, node), op_line, &receiver_gap);
    pm_comments_list_t message_gap;
    comments_claim_comments(ctx, op_line, comments_node_end_line(ctx, node), &message_gap);

    if (trailing != NULL || receiver_gap.size > 0 || operator_comment != NULL || message_gap.size > 0) {
        comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_call_comments_new(ctx, trailing, &receiver_gap, operator_comment, &message_gap)));
    }
}

/* Visit the value, claim the call operator and assignment operator comments,
 * visit the receiver, then split gap comments around the operators. */
static void
comments_attach_call_write_comments(pm_comments_context_t *ctx, pm_node_t *node, pm_node_t *receiver, pm_node_t *value, pm_location_t call_operator_loc, pm_location_t operator_loc) {
    comments_visit(ctx, value);
    const pm_comment_t *operator_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, operator_loc));
    const pm_comment_t *call_operator_comment = NULL;
    if (comments_loc_set(call_operator_loc)) {
        call_operator_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, call_operator_loc));
    }
    if (receiver != NULL) comments_visit(ctx, receiver);

    /* Split gap comments: after operator vs before */
    pm_comments_list_t operator_gap_comments;
    comments_claim_comments(ctx, comments_loc_start_line(ctx, operator_loc), comments_node_end_line(ctx, node), &operator_gap_comments);
    pm_comments_list_t call_gap_comments;
    comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &call_gap_comments);

    if (call_operator_comment != NULL || operator_comment != NULL || call_gap_comments.size > 0 || operator_gap_comments.size > 0) {
        comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_call_write_comments_new(ctx, call_operator_comment, &call_gap_comments, operator_comment, &operator_gap_comments)));
    }
}

/* Visit the value, claim the operator comment, visit the block/arguments/
 * receiver, then claim gap comments. */
static void
comments_attach_index_write_comments(pm_comments_context_t *ctx, pm_node_t *node, pm_node_t *receiver, pm_arguments_node_t *arguments, pm_block_argument_node_t *block, pm_node_t *value, pm_location_t operator_loc) {
    comments_visit(ctx, value);
    const pm_comment_t *operator_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, operator_loc));
    if (block != NULL) comments_visit(ctx, PM_NODE_UPCAST(block));
    if (arguments != NULL) comments_visit(ctx, PM_NODE_UPCAST(arguments));
    if (receiver != NULL) comments_visit(ctx, receiver);
    pm_comments_list_t gap_comments;
    comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &gap_comments);

    if (operator_comment != NULL || gap_comments.size > 0) {
        comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_binary_comments_new(ctx, operator_comment, &gap_comments)));
    }
}

/* Visit the child, claim the opening comment, then split gap comments into
 * before and after the child. */
static void
comments_attach_parenthesized_comments(pm_comments_context_t *ctx, pm_node_t *node, pm_node_t *child, pm_location_t lparen_loc) {
    comments_visit(ctx, child);
    const pm_comment_t *opening = comments_claim_comment(ctx, comments_loc_start_line(ctx, lparen_loc));

    pm_comments_list_t closing_gap_comments;
    comments_claim_comments(ctx, comments_node_end_line(ctx, child), comments_node_end_line(ctx, node), &closing_gap_comments);

    pm_comments_list_t opening_gap_comments;
    comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &opening_gap_comments);

    if (opening != NULL || opening_gap_comments.size > 0 || closing_gap_comments.size > 0) {
        comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_parenthesized_comments_new(ctx, opening, &opening_gap_comments, &closing_gap_comments)));
    }
}

/* Shared handler for CaseNode and CaseMatchNode. Claims keyword and trailing
 * comments, visits conditions via a callback, then splits gap comments. */
typedef void (*comments_case_condition_visitor_t)(pm_comments_context_t *ctx, pm_node_t *condition, int32_t effective_end);

static void
comments_attach_case_comments(pm_comments_context_t *ctx, pm_node_t *node, pm_node_t *predicate, pm_node_list_t *conditions, pm_else_node_t *else_clause, pm_location_t case_keyword_loc, pm_location_t end_keyword_loc, comments_case_condition_visitor_t condition_visitor) {
    /* Trailing comment on end keyword */
    const pm_comment_t *trailing = comments_claim_comment(ctx, comments_loc_start_line(ctx, end_keyword_loc));

    /* Visit else clause */
    if (else_clause != NULL) {
        comments_visit(ctx, PM_NODE_UPCAST(else_clause));
    }

    /* Build boundaries: each condition's boundary is the start_line of the
     * next condition (or else clause keyword, or end keyword).
     */
    int32_t final_boundary;
    if (else_clause != NULL) {
        final_boundary = comments_loc_start_line(ctx, else_clause->else_keyword_loc);
    } else {
        final_boundary = comments_loc_start_line(ctx, end_keyword_loc);
    }

    /* Visit conditions in reverse */
    for (size_t index = conditions->size; index > 0; index--) {
        size_t condition_index = index - 1;
        int32_t effective_end;

        if (condition_index + 1 < conditions->size) {
            effective_end = comments_node_start_line(ctx, conditions->nodes[condition_index + 1]) - 1;
        } else {
            effective_end = final_boundary - 1;
        }

        condition_visitor(ctx, conditions->nodes[condition_index], effective_end);
    }

    /* Visit predicate */
    if (predicate != NULL) comments_visit(ctx, predicate);

    /* Claim keyword comment */
    const pm_comment_t *keyword = comments_claim_comment(ctx, comments_loc_start_line(ctx, case_keyword_loc));

    /* Split: comments between keyword and predicate vs between predicate and first when/in */
    pm_comments_list_t keyword_gap_comments = { NULL, 0 };
    pm_comments_list_t predicate_gap_comments = { NULL, 0 };

    if (predicate != NULL) {
        comments_claim_comments(ctx, comments_node_end_line(ctx, predicate), comments_node_end_line(ctx, node), &predicate_gap_comments);
    }
    comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &keyword_gap_comments);

    if (keyword != NULL || trailing != NULL || keyword_gap_comments.size > 0 || predicate_gap_comments.size > 0) {
        comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_case_comments_new(ctx, keyword, &keyword_gap_comments, &predicate_gap_comments, trailing)));
    }
}

/* Case condition visitor for CaseNode (WhenNode). */
static void
comments_visit_when_condition(pm_comments_context_t *ctx, pm_node_t *condition_node, int32_t effective_end) {
    pm_when_node_t *condition = (pm_when_node_t *) condition_node;

    pm_statements_node_t *statements = condition->statements;
    if (statements != NULL) {
        comments_visit(ctx, PM_NODE_UPCAST(statements));
    }
    comments_visit_reverse(ctx, &condition->conditions);

    int32_t body_start;
    if (comments_loc_set(condition->then_keyword_loc)) {
        body_start = comments_loc_start_line(ctx, condition->then_keyword_loc);
    } else if (condition->conditions.size > 0) {
        body_start = comments_node_end_line(ctx, condition->conditions.nodes[condition->conditions.size - 1]);
    } else {
        body_start = comments_loc_start_line(ctx, condition->keyword_loc);
    }

    pm_comments_list_t body_comments_list;
    comments_claim_comments(ctx, body_start, effective_end, &body_comments_list);

    /* Claim any remaining comments in the condition range (e.g., comments
     * between the when keyword and the first condition). */
    pm_comments_list_t conditions_comments;
    comments_claim_comments(ctx, comments_node_start_line(ctx, condition_node), effective_end, &conditions_comments);

    if (body_comments_list.size > 0 || conditions_comments.size > 0) {
        pm_clause_comments_t *c = pm_clause_comments_new(ctx, NULL);

        /* Merge conditions_comments and body_comments into a single list,
         * with conditions_comments first (they appear earlier in source). */
        size_t total = conditions_comments.size + body_comments_list.size;
        const pm_comment_t **merged = (const pm_comment_t **) pm_arena_alloc(
            ctx->parser->arena,
            sizeof(pm_comment_t *) * total,
            PRISM_ALIGNOF(pm_comment_t *)
        );
        size_t idx = 0;
        for (size_t i = 0; i < conditions_comments.size; i++) merged[idx++] = conditions_comments.comments[i];
        for (size_t i = 0; i < body_comments_list.size; i++) merged[idx++] = body_comments_list.comments[i];
        c->body_comments.comments = merged;
        c->body_comments.size = total;

        comments_store(ctx, condition_node->node_id, PM_COMMENTS_UPCAST(c));
    }
}

/* Case condition visitor for CaseMatchNode (InNode). */
static void
comments_visit_in_condition(pm_comments_context_t *ctx, pm_node_t *condition_node, int32_t effective_end) {
    pm_in_node_t *condition = (pm_in_node_t *) condition_node;

    pm_statements_node_t *statements = condition->statements;
    if (statements != NULL) {
        comments_visit(ctx, PM_NODE_UPCAST(statements));
    }
    comments_visit(ctx, condition->pattern);

    int32_t body_start;
    if (comments_loc_set(condition->then_loc)) {
        body_start = comments_loc_start_line(ctx, condition->then_loc);
    } else {
        body_start = comments_node_end_line(ctx, condition->pattern);
    }

    pm_comments_list_t body_comments_list;
    comments_claim_comments(ctx, body_start, effective_end, &body_comments_list);

    if (body_comments_list.size > 0) {
        pm_clause_comments_t *c = pm_clause_comments_new(ctx, NULL);
        c->body_comments = body_comments_list;
        comments_store(ctx, condition_node->node_id, PM_COMMENTS_UPCAST(c));
    }
}

/*
 * The main visit function responsible for traversing the parse tree and
 * claiming/storing comments as needed.
 */
static void
comments_visit(pm_comments_context_t *ctx, pm_node_t *node) {
    switch (PM_NODE_TYPE(node)) {
        case PM_ERROR_RECOVERY_NODE: {
            pm_error_recovery_node_t *cast = (pm_error_recovery_node_t *) node;
            if (cast->unexpected) comments_visit(ctx, cast->unexpected);
            break;
        }
        case PM_EMBEDDED_VARIABLE_NODE:
        case PM_IN_NODE: /* handled by CaseMatchNode */
        case PM_IT_PARAMETERS_NODE:
        case PM_NUMBERED_PARAMETERS_NODE:
        case PM_SCOPE_NODE:
        case PM_WHEN_NODE: /* handled by CaseNode */
            break;
        case PM_BACK_REFERENCE_READ_NODE:
        case PM_BLOCK_LOCAL_VARIABLE_NODE:
        case PM_CLASS_VARIABLE_READ_NODE:
        case PM_CLASS_VARIABLE_TARGET_NODE:
        case PM_CONSTANT_READ_NODE:
        case PM_CONSTANT_TARGET_NODE:
        case PM_FALSE_NODE:
        case PM_FLOAT_NODE:
        case PM_FORWARDING_ARGUMENTS_NODE:
        case PM_FORWARDING_PARAMETER_NODE:
        case PM_GLOBAL_VARIABLE_READ_NODE:
        case PM_GLOBAL_VARIABLE_TARGET_NODE:
        case PM_IMPLICIT_REST_NODE:
        case PM_INSTANCE_VARIABLE_READ_NODE:
        case PM_INSTANCE_VARIABLE_TARGET_NODE:
        case PM_INTEGER_NODE:
        case PM_IT_LOCAL_VARIABLE_READ_NODE:
        case PM_LOCAL_VARIABLE_READ_NODE:
        case PM_LOCAL_VARIABLE_TARGET_NODE:
        case PM_MATCH_LAST_LINE_NODE:
        case PM_NIL_NODE:
        case PM_NO_BLOCK_PARAMETER_NODE:
        case PM_NO_KEYWORDS_PARAMETER_NODE:
        case PM_NUMBERED_REFERENCE_READ_NODE:
        case PM_RATIONAL_NODE:
        case PM_REDO_NODE:
        case PM_REGULAR_EXPRESSION_NODE:
        case PM_REQUIRED_KEYWORD_PARAMETER_NODE:
        case PM_REQUIRED_PARAMETER_NODE:
        case PM_RETRY_NODE:
        case PM_SELF_NODE:
        case PM_SOURCE_ENCODING_NODE:
        case PM_SOURCE_FILE_NODE:
        case PM_SOURCE_LINE_NODE:
        case PM_STRING_NODE:
        case PM_SYMBOL_NODE:
        case PM_TRUE_NODE:
        case PM_X_STRING_NODE:
            comments_attach_leaf_comments(ctx, node);
            break;
        /*
         *     alias $a $b
         */
        case PM_ALIAS_GLOBAL_VARIABLE_NODE: {
            pm_alias_global_variable_node_t *cast = (pm_alias_global_variable_node_t *) node;

            comments_visit(ctx, cast->old_name);
            comments_visit(ctx, cast->new_name);
            break;
        }
        /*
         *     alias a
         *       # comment
         *       b
         */
        case PM_ALIAS_METHOD_NODE: {
            pm_alias_method_node_t *cast = (pm_alias_method_node_t *) node;
            pm_comments_list_t gap_comments;

            comments_visit(ctx, cast->old_name);
            comments_visit(ctx, cast->new_name);

            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &gap_comments);

            if (gap_comments.size > 0) {
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_alias_method_comments_new(ctx, &gap_comments)));
            }
            break;
        }
        /*
         *     foo in a | # comment
         *       # comment
         *       b
         */
        case PM_ALTERNATION_PATTERN_NODE: {
            pm_alternation_pattern_node_t *cast = (pm_alternation_pattern_node_t *) node;
            comments_attach_binary_comments(ctx, node, cast->left, cast->right, cast->operator_loc);
            break;
        }
        /*
         *     a && # comment
         *       # comment
         *       b
         */
        case PM_AND_NODE: {
            pm_and_node_t *cast = (pm_and_node_t *) node;

            if (cast->operator_loc.length == 3) {
                /* "and" operator can begin a line */
                comments_attach_logical_keyword_comments(ctx, node, cast->left, cast->right, cast->operator_loc);
            } else {
                /* "&&" operator is a normal binary operator */
                comments_attach_binary_comments(ctx, node, cast->left, cast->right, cast->operator_loc);
            }
            break;
        }
        /*
         *     foo(
         *       # comment
         *       a,
         *       # comment
         *       b
         *     )
         */
        case PM_ARGUMENTS_NODE: {
            pm_arguments_node_t *cast = (pm_arguments_node_t *) node;
            pm_comments_list_t inner;

            comments_visit_reverse(ctx, &cast->arguments);
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &inner);

            if (inner.size > 0) {
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_arguments_comments_new(ctx, &inner)));
            }
            break;
        }
        /*
         *     [ # comment
         *       # comment
         *       1,
         *       # comment
         *       2
         *       # comment
         *     ] # comment
         */
        case PM_ARRAY_NODE: {
            pm_array_node_t *cast = (pm_array_node_t *) node;
            const pm_comment_t *opening_comment = NULL;
            pm_comments_list_t inner_comments;
            const pm_comment_t *closing_comment = NULL;

            if (comments_loc_set(cast->closing_loc)) {
                closing_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->closing_loc));
            }

            comments_visit_reverse(ctx, &cast->elements);

            if (comments_loc_set(cast->opening_loc)) {
                opening_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->opening_loc));
            }

            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &inner_comments);

            if (opening_comment != NULL || closing_comment != NULL || inner_comments.size > 0) {
                pm_collection_comments_t *c = pm_collection_comments_new(ctx, opening_comment, closing_comment);
                c->inner_comments = inner_comments;
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
            }
            break;
        }
        /*
         *     foo in [ # comment
         *       1, *a, 2
         *     ] # comment
         */
        case PM_ARRAY_PATTERN_NODE: {
            pm_array_pattern_node_t *cast = (pm_array_pattern_node_t *) node;
            const pm_comment_t *opening_comments = NULL;
            const pm_comment_t *closing_comments = NULL;

            if (comments_loc_set(cast->closing_loc)) {
                closing_comments = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->closing_loc));
            }

            comments_visit_reverse(ctx, &cast->posts);
            if (cast->rest != NULL) comments_visit(ctx, cast->rest);

            comments_visit_reverse(ctx, &cast->requireds);

            if (comments_loc_set(cast->opening_loc)) {
                opening_comments = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->opening_loc));
            }

            if (cast->constant != NULL) comments_visit(ctx, cast->constant);

            pm_comments_list_t body_comments_list;
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &body_comments_list);

            if (opening_comments != NULL || closing_comments != NULL || body_comments_list.size > 0) {
                pm_collection_comments_t *c = pm_collection_comments_new(ctx, opening_comments, closing_comments);
                c->inner_comments = body_comments_list;
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
            }
            break;
        }
        /*
         *     { a => # comment
         *       b }
         */
        case PM_ASSOC_NODE: {
            pm_assoc_node_t *cast = (pm_assoc_node_t *) node;

            if (comments_loc_set(cast->operator_loc)) {
                /* a => b */
                comments_attach_binary_comments(ctx, node, cast->key, cast->value, cast->operator_loc);
            } else if (PM_NODE_TYPE_P(cast->value, PM_IMPLICIT_NODE)) {
                /* a: - implicit value, only the key is visible */
                comments_visit(ctx, cast->key);
            } else {
                /* a: b — key includes the colon, acts like a write */
                comments_attach_write_comments(ctx, node, cast->value, cast->key->location);
            }
            break;
        }
        /*
         *     foo(** # comment
         *       a)
         */
        case PM_ASSOC_SPLAT_NODE: {
            pm_assoc_splat_node_t *cast = (pm_assoc_splat_node_t *) node;

            if (cast->value != NULL) {
                comments_attach_prefix_comments(ctx, node, cast->value, cast->operator_loc);
            } else {
                comments_attach_leaf_comments(ctx, node);
            }
            break;
        }
        /*
         *     begin # comment
         *       foo
         *     rescue
         *       bar
         *     end # comment
         */
        case PM_BEGIN_NODE: {
            pm_begin_node_t *cast = (pm_begin_node_t *) node;
            const pm_comment_t *opening_comment = NULL;
            const pm_comment_t *trailing_comment = NULL;

            if (comments_loc_set(cast->end_keyword_loc)) {
                trailing_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->end_keyword_loc));
            }

            if (cast->ensure_clause != NULL) comments_visit(ctx, PM_NODE_UPCAST(cast->ensure_clause));
            if (cast->else_clause != NULL) comments_visit(ctx, PM_NODE_UPCAST(cast->else_clause));
            if (cast->rescue_clause != NULL) comments_visit(ctx, PM_NODE_UPCAST(cast->rescue_clause));
            if (cast->statements != NULL) comments_visit(ctx, PM_NODE_UPCAST(cast->statements));

            if (comments_loc_set(cast->begin_keyword_loc)) {
                opening_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->begin_keyword_loc));
            }

            pm_comments_list_t body_comments_list;
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &body_comments_list);

            if (opening_comment != NULL || trailing_comment != NULL || body_comments_list.size > 0) {
                pm_body_comments_t *c = pm_body_comments_new(ctx, opening_comment, trailing_comment);
                c->body_comments = body_comments_list;
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
            }
            break;
        }
        /*
         *     foo(& # comment
         *       bar)
         */
        case PM_BLOCK_ARGUMENT_NODE: {
            pm_block_argument_node_t *cast = (pm_block_argument_node_t *) node;

            if (cast->expression != NULL) {
                comments_attach_prefix_comments(ctx, node, cast->expression, cast->operator_loc);
            } else {
                comments_attach_leaf_comments(ctx, node);
            }
            break;
        }
        /*
         *     foo { # comment
         *       bar
         *     } # comment
         */
        case PM_BLOCK_NODE: {
            pm_block_node_t *cast = (pm_block_node_t *) node;
            const pm_comment_t *opening_comment;
            const pm_comment_t *trailing_comment;

            trailing_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->closing_loc));
            if (cast->body != NULL) comments_visit(ctx, cast->body);
            if (cast->parameters != NULL) comments_visit(ctx, cast->parameters);
            opening_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->opening_loc));

            pm_comments_list_t body_comments_list;
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &body_comments_list);

            if (opening_comment != NULL || trailing_comment != NULL || body_comments_list.size > 0) {
                pm_body_comments_t *c = pm_body_comments_new(ctx, opening_comment, trailing_comment);
                c->body_comments = body_comments_list;
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
            }
            break;
        }
        /*
         *     foo { |& # comment
         *       a| }
         */
        case PM_BLOCK_PARAMETER_NODE: {
            pm_block_parameter_node_t *cast = (pm_block_parameter_node_t *) node;
            comments_attach_prefix_parameter_comments(ctx, node, cast->name, cast->operator_loc);
            break;
        }
        /*
         *     foo { | # comment
         *       a, b
         *     | # comment }
         */
        case PM_BLOCK_PARAMETERS_NODE: {
            pm_block_parameters_node_t *cast = (pm_block_parameters_node_t *) node;
            const pm_comment_t *opening = NULL;
            const pm_comment_t *closing = NULL;

            if (comments_loc_set(cast->closing_loc)) {
                closing = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->closing_loc));
            }

            comments_visit_reverse(ctx, &cast->locals);

            if (cast->parameters != NULL) comments_visit(ctx, PM_NODE_UPCAST(cast->parameters));

            if (comments_loc_set(cast->opening_loc)) {
                opening = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->opening_loc));
            }

            pm_comments_list_t body_comments_list;
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &body_comments_list);

            if (opening != NULL || closing != NULL || body_comments_list.size > 0) {
                pm_collection_comments_t *c = pm_collection_comments_new(ctx, opening, closing);
                c->inner_comments = body_comments_list;
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
            }
            break;
        }
        /*
         *     break # comment
         */
        case PM_BREAK_NODE: {
            pm_break_node_t *cast = (pm_break_node_t *) node;
            comments_attach_keyword_comments(ctx, node, cast->arguments);
            break;
        }
        /*
         *     foo. # comment
         *       bar &&= 1
         */
        case PM_CALL_AND_WRITE_NODE: {
            pm_call_and_write_node_t *cast = (pm_call_and_write_node_t *) node;
            comments_attach_call_write_comments(ctx, node, cast->receiver, cast->value, cast->call_operator_loc, cast->operator_loc);
            break;
        }
        /*
         *     foo. # comment
         *       bar # comment
         */
        case PM_CALL_NODE: {
            pm_call_node_t *cast = (pm_call_node_t *) node;

            if (PM_NODE_FLAG_P(node, PM_CALL_NODE_FLAGS_VARIABLE_CALL)) {
                comments_attach_leaf_comments(ctx, node);
            } else {
                pm_comments_list_t receiver_gap = { NULL, 0 };
                const pm_comment_t *operator_comment = NULL;
                pm_comments_list_t message_gap = { NULL, 0 };
                const pm_comment_t *trailing_comment = NULL;

                if (cast->block != NULL && PM_NODE_TYPE_P(cast->block, PM_BLOCK_NODE)) {
                    comments_visit(ctx, cast->block);
                } else {
                    trailing_comment = comments_claim_comment(ctx, comments_node_end_line(ctx, node));
                    if (cast->block != NULL) comments_visit(ctx, cast->block);
                }

                if (cast->arguments != NULL) comments_visit(ctx, PM_NODE_UPCAST(cast->arguments));
                if (comments_loc_set(cast->call_operator_loc)) {
                    operator_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->call_operator_loc));
                }
                if (cast->receiver != NULL) comments_visit(ctx, cast->receiver);

                if (comments_loc_set(cast->call_operator_loc)) {
                    int32_t op_line = comments_loc_start_line(ctx, cast->call_operator_loc);
                    comments_claim_comments(ctx, comments_node_start_line(ctx, node), op_line, &receiver_gap);
                    comments_claim_comments(ctx, op_line, comments_node_end_line(ctx, node), &message_gap);
                } else {
                    comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &message_gap);
                }

                if (trailing_comment != NULL || receiver_gap.size > 0 || operator_comment != NULL || message_gap.size > 0) {
                    comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_call_comments_new(ctx, trailing_comment, &receiver_gap, operator_comment, &message_gap)));
                }
            }
            break;
        }
        /*
         *     foo. # comment
         *       bar += 1
         */
        case PM_CALL_OPERATOR_WRITE_NODE: {
            pm_call_operator_write_node_t *cast = (pm_call_operator_write_node_t *) node;
            comments_attach_call_write_comments(ctx, node, cast->receiver, cast->value, cast->call_operator_loc, cast->binary_operator_loc);
            break;
        }
        /*
         *     foo. # comment
         *       bar ||= 1
         */
        case PM_CALL_OR_WRITE_NODE: {
            pm_call_or_write_node_t *cast = (pm_call_or_write_node_t *) node;
            comments_attach_call_write_comments(ctx, node, cast->receiver, cast->value, cast->call_operator_loc, cast->operator_loc);
            break;
        }
        /*
         *     foo. # comment
         *       bar, baz = 1, 2
         */
        case PM_CALL_TARGET_NODE: {
            pm_call_target_node_t *cast = (pm_call_target_node_t *) node;
            pm_comments_list_t receiver_gap;
            const pm_comment_t *operator_comment;
            pm_comments_list_t message_gap;
            const pm_comment_t *trailing_comment;

            trailing_comment = comments_claim_comment(ctx, comments_node_end_line(ctx, node));
            operator_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->call_operator_loc));
            comments_visit(ctx, cast->receiver);

            int32_t op_line = comments_loc_start_line(ctx, cast->call_operator_loc);
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), op_line, &receiver_gap);
            comments_claim_comments(ctx, op_line, comments_node_end_line(ctx, node), &message_gap);

            if (trailing_comment != NULL || receiver_gap.size > 0 || operator_comment != NULL || message_gap.size > 0) {
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_call_comments_new(ctx, trailing_comment, &receiver_gap, operator_comment, &message_gap)));
            }
            break;
        }
        /*
         *     foo in a => # comment
         *       b
         */
        case PM_CAPTURE_PATTERN_NODE: {
            pm_capture_pattern_node_t *cast = (pm_capture_pattern_node_t *) node;
            comments_attach_binary_comments(ctx, node, cast->value, PM_NODE_UPCAST(cast->target), cast->operator_loc);
            break;
        }
        /*
         *     case foo # comment
         *     in bar
         *       baz
         *     end # comment
         */
        case PM_CASE_MATCH_NODE: {
            pm_case_match_node_t *cast = (pm_case_match_node_t *) node;
            comments_attach_case_comments(ctx, node, cast->predicate, &cast->conditions, cast->else_clause, cast->case_keyword_loc, cast->end_keyword_loc, comments_visit_in_condition);
            break;
        }
        /*
         *     case foo # comment
         *     when bar
         *       baz
         *     end # comment
         */
        case PM_CASE_NODE: {
            pm_case_node_t *cast = (pm_case_node_t *) node;
            comments_attach_case_comments(ctx, node, cast->predicate, &cast->conditions, cast->else_clause, cast->case_keyword_loc, cast->end_keyword_loc, comments_visit_when_condition);
            break;
        }
        /*
         *     class # comment
         *       Foo < # comment
         *       Bar
         *     end # comment
         */
        case PM_CLASS_NODE: {
            pm_class_node_t *cast = (pm_class_node_t *) node;

            const pm_comment_t *trailing_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->end_keyword_loc));
            if (cast->body != NULL) comments_visit(ctx, cast->body);

            pm_comments_list_t inheritance_gap_comments = { 0 };
            const pm_comment_t *inheritance_operator_comment = NULL;

            if (cast->superclass != NULL) {
                comments_visit(ctx, cast->superclass);

                inheritance_operator_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->inheritance_operator_loc));
                comments_claim_comments(ctx, comments_loc_start_line(ctx, cast->inheritance_operator_loc), comments_node_start_line(ctx, cast->superclass), &inheritance_gap_comments);
            }

            comments_visit(ctx, cast->constant_path);

            const pm_comment_t *opening_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->class_keyword_loc));
            pm_comments_list_t keyword_gap_comments;
            comments_claim_comments(ctx, comments_loc_start_line(ctx, cast->class_keyword_loc), comments_node_start_line(ctx, cast->constant_path), &keyword_gap_comments);

            pm_comments_list_t body_comments_list;
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &body_comments_list);

            if (opening_comment != NULL || keyword_gap_comments.size > 0 || inheritance_operator_comment != NULL || inheritance_gap_comments.size > 0 || trailing_comment != NULL || body_comments_list.size > 0) {
                pm_class_comments_t *c = pm_class_comments_new(ctx, opening_comment, &keyword_gap_comments, inheritance_operator_comment, &inheritance_gap_comments, trailing_comment);
                c->body_comments = body_comments_list;
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
            }
            break;
        }
        /*
         *     @@a &&= # comment
         *       1
         */
        case PM_CLASS_VARIABLE_AND_WRITE_NODE: {
            pm_class_variable_and_write_node_t *cast = (pm_class_variable_and_write_node_t *) node;
            comments_attach_write_comments(ctx, node, cast->value, cast->operator_loc);
            break;
        }
        /*
         *     @@a += # comment
         *       1
         */
        case PM_CLASS_VARIABLE_OPERATOR_WRITE_NODE: {
            pm_class_variable_operator_write_node_t *cast = (pm_class_variable_operator_write_node_t *) node;
            comments_attach_write_comments(ctx, node, cast->value, cast->binary_operator_loc);
            break;
        }
        /*
         *     @@a ||= # comment
         *       1
         */
        case PM_CLASS_VARIABLE_OR_WRITE_NODE: {
            pm_class_variable_or_write_node_t *cast = (pm_class_variable_or_write_node_t *) node;
            comments_attach_write_comments(ctx, node, cast->value, cast->operator_loc);
            break;
        }
        /*
         *     @@a = # comment
         *       1
         */
        case PM_CLASS_VARIABLE_WRITE_NODE: {
            pm_class_variable_write_node_t *cast = (pm_class_variable_write_node_t *) node;
            comments_attach_write_comments(ctx, node, cast->value, cast->operator_loc);
            break;
        }
        /*
         *     A &&= # comment
         *       1
         */
        case PM_CONSTANT_AND_WRITE_NODE: {
            pm_constant_and_write_node_t *cast = (pm_constant_and_write_node_t *) node;
            comments_attach_write_comments(ctx, node, cast->value, cast->operator_loc);
            break;
        }
        /*
         *     A += # comment
         *       1
         */
        case PM_CONSTANT_OPERATOR_WRITE_NODE: {
            pm_constant_operator_write_node_t *cast = (pm_constant_operator_write_node_t *) node;
            comments_attach_write_comments(ctx, node, cast->value, cast->binary_operator_loc);
            break;
        }
        /*
         *     A ||= # comment
         *       1
         */
        case PM_CONSTANT_OR_WRITE_NODE: {
            pm_constant_or_write_node_t *cast = (pm_constant_or_write_node_t *) node;
            comments_attach_write_comments(ctx, node, cast->value, cast->operator_loc);
            break;
        }
        /*
         *     A::B &&= # comment
         *       1
         */
        case PM_CONSTANT_PATH_AND_WRITE_NODE: {
            pm_constant_path_and_write_node_t *cast = (pm_constant_path_and_write_node_t *) node;
            comments_attach_binary_comments(ctx, node, PM_NODE_UPCAST(cast->target), cast->value, cast->operator_loc);
            break;
        }
        /*
         *     A:: # comment
         *       B
         */
        case PM_CONSTANT_PATH_NODE: {
            pm_constant_path_node_t *cast = (pm_constant_path_node_t *) node;
            comments_attach_constant_path_comments(ctx, node, cast->parent, cast->delimiter_loc);
            break;
        }
        /*
         *     A::B += # comment
         *       1
         */
        case PM_CONSTANT_PATH_OPERATOR_WRITE_NODE: {
            pm_constant_path_operator_write_node_t *cast = (pm_constant_path_operator_write_node_t *) node;
            comments_attach_binary_comments(ctx, node, PM_NODE_UPCAST(cast->target), cast->value, cast->binary_operator_loc);
            break;
        }
        /*
         *     A::B ||= # comment
         *       1
         */
        case PM_CONSTANT_PATH_OR_WRITE_NODE: {
            pm_constant_path_or_write_node_t *cast = (pm_constant_path_or_write_node_t *) node;
            comments_attach_binary_comments(ctx, node, PM_NODE_UPCAST(cast->target), cast->value, cast->operator_loc);
            break;
        }
        /*
         *     A:: # comment
         *       B, C = 1, 2
         */
        case PM_CONSTANT_PATH_TARGET_NODE: {
            pm_constant_path_target_node_t *cast = (pm_constant_path_target_node_t *) node;
            comments_attach_constant_path_comments(ctx, node, cast->parent, cast->delimiter_loc);
            break;
        }
        /*
         *     A::B = # comment
         *       1
         */
        case PM_CONSTANT_PATH_WRITE_NODE: {
            pm_constant_path_write_node_t *cast = (pm_constant_path_write_node_t *) node;
            comments_attach_binary_comments(ctx, node, PM_NODE_UPCAST(cast->target), cast->value, cast->operator_loc);
            break;
        }
        /*
         *     A = # comment
         *       1
         */
        case PM_CONSTANT_WRITE_NODE: {
            pm_constant_write_node_t *cast = (pm_constant_write_node_t *) node;
            comments_attach_write_comments(ctx, node, cast->value, cast->operator_loc);
            break;
        }
        /*
         *     def foo( # comment
         *       a
         *     ) # comment
         *       bar
         *     end # comment
         */
        case PM_DEF_NODE: {
            pm_def_node_t *cast = (pm_def_node_t *) node;

            if (comments_loc_set(cast->equal_loc)) {
                const pm_comment_t *opening_comment;
                const pm_comment_t *lparen_comment = NULL;
                const pm_comment_t *rparen_comment = NULL;
                const pm_comment_t *equal_comment;

                if (cast->body != NULL) comments_visit(ctx, cast->body);
                equal_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->equal_loc));

                if (comments_loc_set(cast->rparen_loc)) {
                    rparen_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->rparen_loc));
                }
                if (cast->parameters != NULL) comments_visit(ctx, PM_NODE_UPCAST(cast->parameters));
                if (comments_loc_set(cast->lparen_loc)) {
                    lparen_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->lparen_loc));
                }

                if (cast->receiver != NULL) comments_visit(ctx, cast->receiver);
                opening_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->def_keyword_loc));

                pm_comments_list_t keyword_gap;
                comments_claim_comments(ctx, comments_loc_start_line(ctx, cast->def_keyword_loc), comments_loc_start_line(ctx, cast->name_loc), &keyword_gap);

                if (opening_comment != NULL || keyword_gap.size > 0 || lparen_comment != NULL || rparen_comment != NULL || equal_comment != NULL) {
                    comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_endless_def_comments_new(ctx, opening_comment, &keyword_gap, lparen_comment, rparen_comment, equal_comment)));
                }
            } else {
                const pm_comment_t *opening_comment;
                const pm_comment_t *lparen_comment = NULL;
                const pm_comment_t *rparen_comment = NULL;
                const pm_comment_t *trailing_comment = NULL;

                if (comments_loc_set(cast->end_keyword_loc)) {
                    trailing_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->end_keyword_loc));
                }

                if (cast->body != NULL) comments_visit(ctx, cast->body);

                if (comments_loc_set(cast->rparen_loc)) {
                    rparen_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->rparen_loc));
                }
                if (cast->parameters != NULL) comments_visit(ctx, PM_NODE_UPCAST(cast->parameters));
                if (comments_loc_set(cast->lparen_loc)) {
                    lparen_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->lparen_loc));
                }

                if (cast->receiver != NULL) comments_visit(ctx, cast->receiver);
                opening_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->def_keyword_loc));

                pm_comments_list_t keyword_gap;
                comments_claim_comments(ctx, comments_loc_start_line(ctx, cast->def_keyword_loc), comments_loc_start_line(ctx, cast->name_loc), &keyword_gap);

                pm_comments_list_t body_comments_list;
                comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &body_comments_list);

                if (opening_comment != NULL || keyword_gap.size > 0 || trailing_comment != NULL || lparen_comment != NULL || rparen_comment != NULL || body_comments_list.size > 0) {
                    pm_def_comments_t *c = pm_def_comments_new(ctx, opening_comment, &keyword_gap, lparen_comment, rparen_comment, trailing_comment);
                    c->body_comments = body_comments_list;
                    comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
                }
            }
            break;
        }
        /*
         *     defined?( # comment
         *       foo)
         */
        case PM_DEFINED_NODE: {
            pm_defined_node_t *cast = (pm_defined_node_t *) node;

            if (comments_loc_set(cast->lparen_loc)) {
                comments_attach_parenthesized_comments(ctx, node, cast->value, cast->lparen_loc);
            } else {
                comments_attach_prefix_comments(ctx, node, cast->value, cast->keyword_loc);
            }
            break;
        }
        /*
         *     if a
         *     else # comment
         *       b
         *     end
         */
        case PM_ELSE_NODE: {
            pm_else_node_t *cast = (pm_else_node_t *) node;

            if (cast->statements != NULL) comments_visit(ctx, PM_NODE_UPCAST(cast->statements));
            const pm_comment_t *opening_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->else_keyword_loc));
            pm_comments_list_t body_comments_list;
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &body_comments_list);

            if (opening_comment != NULL || body_comments_list.size > 0) {
                pm_clause_comments_t *c = pm_clause_comments_new(ctx, opening_comment);
                c->body_comments = body_comments_list;
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
            }
            break;
        }
        /*
         *     "foo #{ # comment
         *       bar}"
         */
        case PM_EMBEDDED_STATEMENTS_NODE: {
            pm_embedded_statements_node_t *cast = (pm_embedded_statements_node_t *) node;

            if (cast->statements != NULL) comments_visit(ctx, PM_NODE_UPCAST(cast->statements));

            const pm_comment_t *opening_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->opening_loc));
            pm_comments_list_t body_comments_list;
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &body_comments_list);

            if (opening_comment != NULL || body_comments_list.size > 0) {
                pm_embedded_statements_comments_t *c = pm_embedded_statements_comments_new(ctx, opening_comment);
                c->body_comments = body_comments_list;
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
            }
            break;
        }
        /*
         *     begin
         *     ensure # comment
         *       foo
         *     end
         */
        case PM_ENSURE_NODE: {
            pm_ensure_node_t *cast = (pm_ensure_node_t *) node;

            if (cast->statements != NULL) comments_visit(ctx, PM_NODE_UPCAST(cast->statements));

            const pm_comment_t *opening_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->ensure_keyword_loc));
            pm_comments_list_t body_comments_list;
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &body_comments_list);

            if (opening_comment != NULL || body_comments_list.size > 0) {
                pm_clause_comments_t *c = pm_clause_comments_new(ctx, opening_comment);
                c->body_comments = body_comments_list;
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
            }
            break;
        }
        /*
         *     foo in [ # comment
         *       *a, b, *c
         *     ] # comment
         */
        case PM_FIND_PATTERN_NODE: {
            pm_find_pattern_node_t *cast = (pm_find_pattern_node_t *) node;
            const pm_comment_t *closing_comment = NULL;
            const pm_comment_t *opening_comment = NULL;

            if (comments_loc_set(cast->closing_loc)) {
                closing_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->closing_loc));
            }

            comments_visit(ctx, PM_NODE_UPCAST(cast->right));
            comments_visit_reverse(ctx, &cast->requireds);
            comments_visit(ctx, PM_NODE_UPCAST(cast->left));

            if (comments_loc_set(cast->opening_loc)) {
                opening_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->opening_loc));
            }

            if (cast->constant != NULL) comments_visit(ctx, cast->constant);

            pm_comments_list_t pre_left_comments;
            pm_comments_list_t requireds_comments;
            pm_comments_list_t post_right_comments;

            comments_claim_comments(ctx, comments_node_end_line(ctx, PM_NODE_UPCAST(cast->left)), comments_node_start_line(ctx, PM_NODE_UPCAST(cast->right)), &requireds_comments);

            comments_claim_comments(ctx, comments_node_end_line(ctx, PM_NODE_UPCAST(cast->right)), comments_node_end_line(ctx, node), &post_right_comments);
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &pre_left_comments);

            if (opening_comment != NULL || closing_comment != NULL || pre_left_comments.size > 0 || post_right_comments.size > 0 || requireds_comments.size > 0) {
                pm_find_pattern_comments_t *c = pm_find_pattern_comments_new(ctx, opening_comment, closing_comment, &pre_left_comments, &post_right_comments);
                c->inner_comments = requireds_comments;
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
            }
            break;
        }
        /*
         *     a .. # comment
         *       b
         */
        case PM_FLIP_FLOP_NODE: {
            pm_flip_flop_node_t *cast = (pm_flip_flop_node_t *) node;
            comments_attach_range_comments(ctx, node, cast->left, cast->right, cast->operator_loc);
            break;
        }
        /*
         *     for a in b do # comment
         *       c
         *     end # comment
         */
        case PM_FOR_NODE: {
            pm_for_node_t *cast = (pm_for_node_t *) node;

            const pm_comment_t *trailing_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->end_keyword_loc));
            const pm_comment_t *do_comment = NULL;
            if (comments_loc_set(cast->do_keyword_loc)) {
                do_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->do_keyword_loc));
            }

            if (cast->statements != NULL) comments_visit(ctx, PM_NODE_UPCAST(cast->statements));
            comments_visit(ctx, cast->collection);
            const pm_comment_t *in_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->in_keyword_loc));
            comments_visit(ctx, cast->index);
            const pm_comment_t *for_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->for_keyword_loc));

            pm_comments_list_t body_comments_list;
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &body_comments_list);

            if (for_comment != NULL || in_comment != NULL || do_comment != NULL || trailing_comment != NULL || body_comments_list.size > 0) {
                pm_for_comments_t *c = pm_for_comments_new(ctx, for_comment, in_comment, do_comment, trailing_comment);
                c->body_comments = body_comments_list;
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
            }
            break;
        }
        /*
         *     super # comment
         */
        case PM_FORWARDING_SUPER_NODE: {
            pm_forwarding_super_node_t *cast = (pm_forwarding_super_node_t *) node;
            if (cast->block != NULL) {
                comments_visit(ctx, PM_NODE_UPCAST(cast->block));
            } else {
                comments_attach_leaf_comments(ctx, node);
            }
            break;
        }
        /*
         *     $a &&= # comment
         *       1
         */
        case PM_GLOBAL_VARIABLE_AND_WRITE_NODE: {
            pm_global_variable_and_write_node_t *cast = (pm_global_variable_and_write_node_t *) node;
            comments_attach_write_comments(ctx, node, cast->value, cast->operator_loc);
            break;
        }
        /*
         *     $a += # comment
         *       1
         */
        case PM_GLOBAL_VARIABLE_OPERATOR_WRITE_NODE: {
            pm_global_variable_operator_write_node_t *cast = (pm_global_variable_operator_write_node_t *) node;
            comments_attach_write_comments(ctx, node, cast->value, cast->binary_operator_loc);
            break;
        }
        /*
         *     $a ||= # comment
         *       1
         */
        case PM_GLOBAL_VARIABLE_OR_WRITE_NODE: {
            pm_global_variable_or_write_node_t *cast = (pm_global_variable_or_write_node_t *) node;
            comments_attach_write_comments(ctx, node, cast->value, cast->operator_loc);
            break;
        }
        /*
         *     $a = # comment
         *       1
         */
        case PM_GLOBAL_VARIABLE_WRITE_NODE: {
            pm_global_variable_write_node_t *cast = (pm_global_variable_write_node_t *) node;
            comments_attach_write_comments(ctx, node, cast->value, cast->operator_loc);
            break;
        }
        /*
         *     { # comment
         *       a: 1
         *     } # comment
         */
        case PM_HASH_NODE: {
            pm_hash_node_t *cast = (pm_hash_node_t *) node;

            const pm_comment_t *closing = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->closing_loc));
            comments_visit_reverse(ctx, &cast->elements);
            const pm_comment_t *opening = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->opening_loc));

            pm_comments_list_t inner;
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &inner);

            if (opening != NULL || closing != NULL || inner.size > 0) {
                pm_collection_comments_t *c = pm_collection_comments_new(ctx, opening, closing);
                c->inner_comments = inner;
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
            }
            break;
        }
        /*
         *     foo in { # comment
         *       a:, **b
         *     } # comment
         */
        case PM_HASH_PATTERN_NODE: {
            pm_hash_pattern_node_t *cast = (pm_hash_pattern_node_t *) node;
            const pm_comment_t *closing = NULL;
            const pm_comment_t *opening = NULL;

            if (comments_loc_set(cast->closing_loc)) {
                closing = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->closing_loc));
            }

            if (cast->rest != NULL) comments_visit(ctx, cast->rest);
            comments_visit_reverse(ctx, &cast->elements);

            if (comments_loc_set(cast->opening_loc)) {
                opening = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->opening_loc));
            }

            if (cast->constant != NULL) comments_visit(ctx, cast->constant);

            pm_comments_list_t post_rest_comments = { NULL, 0 };
            if (cast->rest != NULL) {
                comments_claim_comments(ctx, comments_node_end_line(ctx, cast->rest), comments_node_end_line(ctx, node), &post_rest_comments);
            }

            pm_comments_list_t elements_comments;

            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &elements_comments);

            if (opening != NULL || closing != NULL || post_rest_comments.size > 0 || elements_comments.size > 0) {
                pm_hash_pattern_comments_t *c = pm_hash_pattern_comments_new(ctx, opening, closing, &post_rest_comments);
                c->inner_comments = elements_comments;
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
            }
            break;
        }
        /*
         *     if a # comment
         *       b
         *     end # comment
         */
        case PM_IF_NODE: {
            pm_if_node_t *cast = (pm_if_node_t *) node;
            const pm_comment_t *trailing_comment = NULL;

            if (comments_loc_set(cast->end_keyword_loc)) {
                trailing_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->end_keyword_loc));
            }
            if (cast->subsequent != NULL) comments_visit(ctx, cast->subsequent);
            if (cast->statements != NULL) comments_visit(ctx, PM_NODE_UPCAST(cast->statements));
            comments_visit(ctx, cast->predicate);

            const pm_comment_t *opening_comment = NULL;
            if (comments_loc_set(cast->if_keyword_loc)) {
                opening_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->if_keyword_loc));
            }
            pm_comments_list_t body_comments_list;
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &body_comments_list);

            if (opening_comment != NULL || trailing_comment != NULL || body_comments_list.size > 0) {
                pm_body_comments_t *c = pm_body_comments_new(ctx, opening_comment, trailing_comment);
                c->body_comments = body_comments_list;
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
            }
            break;
        }
        /*
         *     1i # comment
         */
        case PM_IMAGINARY_NODE: {
            pm_imaginary_node_t *cast = (pm_imaginary_node_t *) node;

            const pm_comment_t *trailing_comment = comments_claim_comment(ctx, comments_node_end_line(ctx, node));
            comments_visit(ctx, cast->numeric);

            if (trailing_comment != NULL) {
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_leaf_comments_new(ctx, trailing_comment)));
            }
            break;
        }
        case PM_IMPLICIT_NODE: {
            pm_implicit_node_t *cast = (pm_implicit_node_t *) node;
            comments_visit(ctx, cast->value);
            break;
        }
        /*
         *     foo[bar] &&= baz
         */
        case PM_INDEX_AND_WRITE_NODE: {
            pm_index_and_write_node_t *cast = (pm_index_and_write_node_t *) node;
            comments_attach_index_write_comments(ctx, node, cast->receiver, cast->arguments, cast->block, cast->value, cast->operator_loc);
            break;
        }
        /*
         *     foo[bar] += baz
         */
        case PM_INDEX_OPERATOR_WRITE_NODE: {
            pm_index_operator_write_node_t *cast = (pm_index_operator_write_node_t *) node;
            comments_attach_index_write_comments(ctx, node, cast->receiver, cast->arguments, cast->block, cast->value, cast->binary_operator_loc);
            break;
        }
        /*
         *     foo[bar] ||= baz
         */
        case PM_INDEX_OR_WRITE_NODE: {
            pm_index_or_write_node_t *cast = (pm_index_or_write_node_t *) node;
            comments_attach_index_write_comments(ctx, node, cast->receiver, cast->arguments, cast->block, cast->value, cast->operator_loc);
            break;
        }
        /*
         *     foo[bar], baz = 1, 2
         */
        case PM_INDEX_TARGET_NODE: {
            pm_index_target_node_t *cast = (pm_index_target_node_t *) node;

            const pm_comment_t *trailing = comments_claim_comment(ctx, comments_node_end_line(ctx, node));
            if (cast->block != NULL) comments_visit(ctx, PM_NODE_UPCAST(cast->block));
            if (cast->arguments != NULL) comments_visit(ctx, PM_NODE_UPCAST(cast->arguments));
            comments_visit(ctx, cast->receiver);

            if (trailing != NULL) {
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_leaf_comments_new(ctx, trailing)));
            }
            break;
        }
        /*
         *     @a &&= # comment
         *       1
         */
        case PM_INSTANCE_VARIABLE_AND_WRITE_NODE: {
            pm_instance_variable_and_write_node_t *cast = (pm_instance_variable_and_write_node_t *) node;
            comments_attach_write_comments(ctx, node, cast->value, cast->operator_loc);
            break;
        }
        /*
         *     @a += # comment
         *       1
         */
        case PM_INSTANCE_VARIABLE_OPERATOR_WRITE_NODE: {
            pm_instance_variable_operator_write_node_t *cast = (pm_instance_variable_operator_write_node_t *) node;
            comments_attach_write_comments(ctx, node, cast->value, cast->binary_operator_loc);
            break;
        }
        /*
         *     @a ||= # comment
         *       1
         */
        case PM_INSTANCE_VARIABLE_OR_WRITE_NODE: {
            pm_instance_variable_or_write_node_t *cast = (pm_instance_variable_or_write_node_t *) node;
            comments_attach_write_comments(ctx, node, cast->value, cast->operator_loc);
            break;
        }
        /*
         *     @a = # comment
         *       1
         */
        case PM_INSTANCE_VARIABLE_WRITE_NODE: {
            pm_instance_variable_write_node_t *cast = (pm_instance_variable_write_node_t *) node;
            comments_attach_write_comments(ctx, node, cast->value, cast->operator_loc);
            break;
        }
        case PM_INTERPOLATED_MATCH_LAST_LINE_NODE: {
            pm_interpolated_match_last_line_node_t *cast = (pm_interpolated_match_last_line_node_t *) node;
            comments_attach_interpolated_comments(ctx, node, &cast->parts);
            break;
        }
        case PM_INTERPOLATED_REGULAR_EXPRESSION_NODE: {
            pm_interpolated_regular_expression_node_t *cast = (pm_interpolated_regular_expression_node_t *) node;
            comments_attach_interpolated_comments(ctx, node, &cast->parts);
            break;
        }
        case PM_INTERPOLATED_STRING_NODE: {
            pm_interpolated_string_node_t *cast = (pm_interpolated_string_node_t *) node;
            comments_attach_interpolated_comments(ctx, node, &cast->parts);
            break;
        }
        case PM_INTERPOLATED_SYMBOL_NODE: {
            pm_interpolated_symbol_node_t *cast = (pm_interpolated_symbol_node_t *) node;
            comments_attach_interpolated_comments(ctx, node, &cast->parts);
            break;
        }
        case PM_INTERPOLATED_X_STRING_NODE: {
            pm_interpolated_x_string_node_t *cast = (pm_interpolated_x_string_node_t *) node;
            comments_attach_interpolated_comments(ctx, node, &cast->parts);
            break;
        }
        case PM_KEYWORD_HASH_NODE: {
            pm_keyword_hash_node_t *cast = (pm_keyword_hash_node_t *) node;
            comments_visit_reverse(ctx, &cast->elements);

            pm_comments_list_t inner;
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &inner);

            if (inner.size > 0) {
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_keyword_hash_comments_new(ctx, &inner)));
            }
            break;
        }
        /*
         *     def foo(** # comment
         *       a) end
         */
        case PM_KEYWORD_REST_PARAMETER_NODE: {
            pm_keyword_rest_parameter_node_t *cast = (pm_keyword_rest_parameter_node_t *) node;
            comments_attach_prefix_parameter_comments(ctx, node, cast->name, cast->operator_loc);
            break;
        }
        /*
         *     -> { # comment
         *       foo
         *     } # comment
         */
        case PM_LAMBDA_NODE: {
            pm_lambda_node_t *cast = (pm_lambda_node_t *) node;
            const pm_comment_t *trailing_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->closing_loc));

            if (cast->body != NULL) comments_visit(ctx, cast->body);
            if (cast->parameters != NULL) comments_visit(ctx, cast->parameters);

            const pm_comment_t *opening_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->opening_loc));
            pm_comments_list_t body_comments_list;
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &body_comments_list);

            if (opening_comment != NULL || trailing_comment != NULL || body_comments_list.size > 0) {
                pm_body_comments_t *c = pm_body_comments_new(ctx, opening_comment, trailing_comment);
                c->body_comments = body_comments_list;
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
            }
            break;
        }
        /*
         *     a &&= # comment
         *       1
         */
        case PM_LOCAL_VARIABLE_AND_WRITE_NODE: {
            pm_local_variable_and_write_node_t *cast = (pm_local_variable_and_write_node_t *) node;
            comments_attach_write_comments(ctx, node, cast->value, cast->operator_loc);
            break;
        }
        /*
         *     a += # comment
         *       1
         */
        case PM_LOCAL_VARIABLE_OPERATOR_WRITE_NODE: {
            pm_local_variable_operator_write_node_t *cast = (pm_local_variable_operator_write_node_t *) node;
            comments_attach_write_comments(ctx, node, cast->value, cast->binary_operator_loc);
            break;
        }
        /*
         *     a ||= # comment
         *       1
         */
        case PM_LOCAL_VARIABLE_OR_WRITE_NODE: {
            pm_local_variable_or_write_node_t *cast = (pm_local_variable_or_write_node_t *) node;
            comments_attach_write_comments(ctx, node, cast->value, cast->operator_loc);
            break;
        }
        /*
         *     a = # comment
         *       1
         */
        case PM_LOCAL_VARIABLE_WRITE_NODE: {
            pm_local_variable_write_node_t *cast = (pm_local_variable_write_node_t *) node;
            comments_attach_write_comments(ctx, node, cast->value, cast->operator_loc);
            break;
        }
        /*
         *     foo in # comment
         *       bar
         */
        case PM_MATCH_PREDICATE_NODE: {
            pm_match_predicate_node_t *cast = (pm_match_predicate_node_t *) node;
            comments_attach_binary_comments(ctx, node, cast->value, cast->pattern, cast->operator_loc);
            break;
        }
        /*
         *     foo => # comment
         *       bar
         */
        case PM_MATCH_REQUIRED_NODE: {
            pm_match_required_node_t *cast = (pm_match_required_node_t *) node;
            comments_attach_binary_comments(ctx, node, cast->value, cast->pattern, cast->operator_loc);
            break;
        }
        case PM_MATCH_WRITE_NODE: {
            pm_match_write_node_t *cast = (pm_match_write_node_t *) node;
            comments_visit(ctx, PM_NODE_UPCAST(cast->call));
            break;
        }
        /*
         *     module # comment
         *       Foo
         *     end # comment
         */
        case PM_MODULE_NODE: {
            pm_module_node_t *cast = (pm_module_node_t *) node;
            const pm_comment_t *trailing_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->end_keyword_loc));
            if (cast->body != NULL) comments_visit(ctx, cast->body);
            comments_visit(ctx, cast->constant_path);

            const pm_comment_t *opening_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->module_keyword_loc));
            pm_comments_list_t keyword_gap_comments;
            comments_claim_comments(ctx, comments_loc_start_line(ctx, cast->module_keyword_loc), comments_node_start_line(ctx, cast->constant_path), &keyword_gap_comments);

            pm_comments_list_t body_comments_list;
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &body_comments_list);

            if (opening_comment != NULL || keyword_gap_comments.size > 0 || trailing_comment != NULL || body_comments_list.size > 0) {
                pm_module_comments_t *c = pm_module_comments_new(ctx, opening_comment, &keyword_gap_comments, trailing_comment);
                c->body_comments = body_comments_list;
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
            }
            break;
        }
        /*
         *     a, b = 1, 2
         */
        case PM_MULTI_TARGET_NODE: {
            pm_multi_target_node_t *cast = (pm_multi_target_node_t *) node;
            const pm_comment_t *rparen = NULL;
            const pm_comment_t *lparen = NULL;

            if (comments_loc_set(cast->rparen_loc))
                rparen = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->rparen_loc));

            comments_visit_reverse(ctx, &cast->rights);
            if (cast->rest != NULL) comments_visit(ctx, cast->rest);
            comments_visit_reverse(ctx, &cast->lefts);

            if (comments_loc_set(cast->lparen_loc))
                lparen = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->lparen_loc));

            pm_comments_list_t body_comments_list;
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &body_comments_list);

            if (lparen != NULL || rparen != NULL || body_comments_list.size > 0) {
                pm_collection_comments_t *c = pm_collection_comments_new(ctx, lparen, rparen);
                c->inner_comments = body_comments_list;
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
            }
            break;
        }
        /*
         *     a, b = # comment
         *       1, 2
         */
        case PM_MULTI_WRITE_NODE: {
            pm_multi_write_node_t *cast = (pm_multi_write_node_t *) node;

            comments_visit(ctx, cast->value);
            const pm_comment_t *operator_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->operator_loc));

            comments_visit_reverse(ctx, &cast->rights);
            if (cast->rest != NULL) comments_visit(ctx, cast->rest);
            comments_visit_reverse(ctx, &cast->lefts);

            pm_comments_list_t gap_comments;
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &gap_comments);

            if (operator_comment != NULL || gap_comments.size > 0) {
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_binary_comments_new(ctx, operator_comment, &gap_comments)));
            }
            break;
        }
        /*
         *     next # comment
         */
        case PM_NEXT_NODE: {
            pm_next_node_t *cast = (pm_next_node_t *) node;
            comments_attach_keyword_comments(ctx, node, cast->arguments);
            break;
        }
        /*
         *     def foo(a: # comment
         *       1) end
         */
        case PM_OPTIONAL_KEYWORD_PARAMETER_NODE: {
            pm_optional_keyword_parameter_node_t *cast = (pm_optional_keyword_parameter_node_t *) node;
            comments_attach_write_comments(ctx, node, cast->value, cast->name_loc);
            break;
        }
        /*
         *     def foo(a = # comment
         *       1) end
         */
        case PM_OPTIONAL_PARAMETER_NODE: {
            pm_optional_parameter_node_t *cast = (pm_optional_parameter_node_t *) node;
            comments_attach_write_comments(ctx, node, cast->value, cast->operator_loc);
            break;
        }
        /*
         *     a || # comment
         *       b
         */
        case PM_OR_NODE: {
            pm_or_node_t *cast = (pm_or_node_t *) node;

            if (ctx->parser->start[cast->operator_loc.start] == 'o') {
                comments_attach_logical_keyword_comments(ctx, node, cast->left, cast->right, cast->operator_loc);
            } else {
                comments_attach_binary_comments(ctx, node, cast->left, cast->right, cast->operator_loc);
            }
            break;
        }
        case PM_PARAMETERS_NODE: {
            pm_parameters_node_t *cast = (pm_parameters_node_t *) node;

            if (cast->block != NULL) comments_visit(ctx, cast->block);
            if (cast->keyword_rest != NULL) comments_visit(ctx, cast->keyword_rest);
            comments_visit_reverse(ctx, &cast->keywords);
            comments_visit_reverse(ctx, &cast->posts);
            if (cast->rest != NULL) comments_visit(ctx, cast->rest);
            comments_visit_reverse(ctx, &cast->optionals);
            comments_visit_reverse(ctx, &cast->requireds);

            /* Claim remaining gap comments in the parameter range. */
            pm_comments_list_t param_gap;
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &param_gap);

            if (param_gap.size > 0) {
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_parameters_comments_new(ctx, &param_gap)));
            }
            break;
        }
        /*
         *     (# comment
         *       foo
         *     )
         */
        case PM_PARENTHESES_NODE: {
            pm_parentheses_node_t *cast = (pm_parentheses_node_t *) node;
            const pm_comment_t *trailing_comment = comments_claim_comment(ctx, comments_node_end_line(ctx, node));

            if (cast->body != NULL && PM_NODE_TYPE_P(cast->body, PM_STATEMENTS_NODE)) {
                comments_visit(ctx, cast->body);

                const pm_comment_t *opening_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->opening_loc));
                pm_comments_list_t body_comments_list;
                comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &body_comments_list);

                if (opening_comment != NULL || trailing_comment != NULL || body_comments_list.size > 0) {
                    pm_body_comments_t *c = pm_body_comments_new(ctx, opening_comment, trailing_comment);
                    c->body_comments = body_comments_list;
                    comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
                }
            } else if (cast->body != NULL) {
                comments_visit(ctx, cast->body);
                const pm_comment_t *opening_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->opening_loc));

                pm_comments_list_t closing_gap_comments;
                comments_claim_comments(ctx, comments_node_end_line(ctx, cast->body), comments_node_end_line(ctx, node), &closing_gap_comments);

                pm_comments_list_t opening_gap_comments;
                comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &opening_gap_comments);

                if (opening_comment != NULL || opening_gap_comments.size > 0 || closing_gap_comments.size > 0) {
                    comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_parenthesized_comments_new(ctx, opening_comment, &opening_gap_comments, &closing_gap_comments)));
                }
            } else {
                const pm_comment_t *opening_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->opening_loc));
                pm_comments_list_t body_comments_list;
                comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &body_comments_list);

                if (opening_comment != NULL || trailing_comment != NULL || body_comments_list.size > 0) {
                    pm_body_comments_t *c = pm_body_comments_new(ctx, opening_comment, trailing_comment);
                    c->body_comments = body_comments_list;
                    comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
                }
            }
            break;
        }
        case PM_PINNED_EXPRESSION_NODE: {
            pm_pinned_expression_node_t *cast = (pm_pinned_expression_node_t *) node;
            comments_attach_parenthesized_comments(ctx, node, cast->expression, cast->lparen_loc);
            break;
        }
        /*
         *     foo in ^ # comment
         *       a
         */
        case PM_PINNED_VARIABLE_NODE: {
            pm_pinned_variable_node_t *cast = (pm_pinned_variable_node_t *) node;
            comments_attach_prefix_comments(ctx, node, cast->variable, cast->operator_loc);
            break;
        }
        /*
         *     END { # comment
         *       foo
         *     } # comment
         */
        case PM_POST_EXECUTION_NODE: {
            pm_post_execution_node_t *cast = (pm_post_execution_node_t *) node;
            comments_attach_body_comments_generic(ctx, node, cast->opening_loc, cast->closing_loc, (pm_statements_node_t **)&cast->statements);
            break;
        }
        /*
         *     BEGIN { # comment
         *       foo
         *     } # comment
         */
        case PM_PRE_EXECUTION_NODE: {
            pm_pre_execution_node_t *cast = (pm_pre_execution_node_t *) node;
            comments_attach_body_comments_generic(ctx, node, cast->opening_loc, cast->closing_loc, (pm_statements_node_t **)&cast->statements);
            break;
        }
        case PM_PROGRAM_NODE: {
            pm_program_node_t *cast = (pm_program_node_t *) node;
            comments_visit(ctx, PM_NODE_UPCAST(cast->statements));
            pm_comments_list_t body_comments_list;
            comments_claim_comments(ctx, ctx->min_line, ctx->max_line, &body_comments_list);
            break;
        }
        /*
         *     a .. # comment
         *       b
         */
        case PM_RANGE_NODE: {
            pm_range_node_t *cast = (pm_range_node_t *) node;
            comments_attach_range_comments(ctx, node, cast->left, cast->right, cast->operator_loc);
            break;
        }
        /*
         *     foo rescue # comment
         *       bar
         */
        case PM_RESCUE_MODIFIER_NODE: {
            pm_rescue_modifier_node_t *cast = (pm_rescue_modifier_node_t *) node;
            comments_attach_binary_comments(ctx, node, cast->expression, cast->rescue_expression, cast->keyword_loc);
            break;
        }
        /*
         *     begin
         *     rescue # comment
         *       foo
         *     end
         */
        case PM_RESCUE_NODE: {
            pm_rescue_node_t *cast = (pm_rescue_node_t *) node;

            if (cast->subsequent != NULL) comments_visit(ctx, PM_NODE_UPCAST(cast->subsequent));
            if (cast->statements != NULL) comments_visit(ctx, PM_NODE_UPCAST(cast->statements));
            if (cast->reference != NULL) comments_visit(ctx, cast->reference);
            comments_visit_reverse(ctx, &cast->exceptions);

            const pm_comment_t *opening = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->keyword_loc));
            pm_comments_list_t body_comments_list;
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &body_comments_list);

            if (opening != NULL || body_comments_list.size > 0) {
                pm_clause_comments_t *c = pm_clause_comments_new(ctx, opening);
                c->body_comments = body_comments_list;
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
            }
            break;
        }
        /*
         *     def foo(* # comment
         *       a) end
         */
        case PM_REST_PARAMETER_NODE: {
            pm_rest_parameter_node_t *cast = (pm_rest_parameter_node_t *) node;
            comments_attach_prefix_parameter_comments(ctx, node, cast->name, cast->operator_loc);
            break;
        }
        /*
         *     return # comment
         */
        case PM_RETURN_NODE: {
            pm_return_node_t *cast = (pm_return_node_t *) node;
            comments_attach_keyword_comments(ctx, node, cast->arguments);
            break;
        }
        case PM_SHAREABLE_CONSTANT_NODE: {
            pm_shareable_constant_node_t *cast = (pm_shareable_constant_node_t *) node;
            comments_visit(ctx, cast->write);
            break;
        }
        /*
         *     class << # comment
         *       self
         *     end # comment
         */
        case PM_SINGLETON_CLASS_NODE: {
            pm_singleton_class_node_t *cast = (pm_singleton_class_node_t *) node;

            const pm_comment_t *trailing_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->end_keyword_loc));
            if (cast->body != NULL) comments_visit(ctx, cast->body);
            comments_visit(ctx, cast->expression);
            const pm_comment_t *opening_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->operator_loc));

            pm_comments_list_t body_comments_list;
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &body_comments_list);

            if (opening_comment != NULL || trailing_comment != NULL || body_comments_list.size > 0) {
                pm_body_comments_t *c = pm_body_comments_new(ctx, opening_comment, trailing_comment);
                c->body_comments = body_comments_list;
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
            }
            break;
        }
        /*
         *     * # comment
         *       a
         */
        case PM_SPLAT_NODE: {
            pm_splat_node_t *cast = (pm_splat_node_t *) node;

            if (cast->expression != NULL) {
                comments_attach_prefix_comments(ctx, node, cast->expression, cast->operator_loc);
            } else {
                comments_attach_leaf_comments(ctx, node);
            }
            break;
        }
        case PM_STATEMENTS_NODE: {
            pm_statements_node_t *cast = (pm_statements_node_t *) node;
            comments_visit_reverse(ctx, &cast->body);
            break;
        }
        /*
         *     super(# comment
         *       foo
         *     ) # comment
         */
        case PM_SUPER_NODE: {
            pm_super_node_t *cast = (pm_super_node_t *) node;

            if (cast->block != NULL && PM_NODE_TYPE_P(cast->block, PM_BLOCK_NODE)) {
                comments_visit(ctx, cast->block);
            }

            const pm_comment_t *rparen = NULL;
            if (comments_loc_set(cast->rparen_loc))
                rparen = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->rparen_loc));

            if (cast->arguments != NULL) comments_visit(ctx, PM_NODE_UPCAST(cast->arguments));
            if (cast->block != NULL && !PM_NODE_TYPE_P(cast->block, PM_BLOCK_NODE))
                comments_visit(ctx, cast->block);

            const pm_comment_t *lparen = NULL;
            if (comments_loc_set(cast->lparen_loc))
                lparen = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->lparen_loc));

            if (lparen != NULL || rparen != NULL) {
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_keyword_call_comments_new(ctx, lparen, rparen)));
            }
            break;
        }
        /*
         *     undef a, b
         */
        case PM_UNDEF_NODE: {
            pm_undef_node_t *cast = (pm_undef_node_t *) node;
            comments_visit_reverse(ctx, &cast->names);
            const pm_comment_t *keyword = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->keyword_loc));

            pm_comments_list_t inner;
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &inner);

            if (keyword != NULL || inner.size > 0) {
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_undef_comments_new(ctx, keyword, &inner)));
            }
            break;
        }
        /*
         *     unless a # comment
         *       b
         *     end # comment
         */
        case PM_UNLESS_NODE: {
            pm_unless_node_t *cast = (pm_unless_node_t *) node;
            const pm_comment_t *trailing_comment = NULL;

            if (comments_loc_set(cast->end_keyword_loc)) {
                trailing_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->end_keyword_loc));
            }

            if (cast->else_clause != NULL) comments_visit(ctx, PM_NODE_UPCAST(cast->else_clause));
            if (cast->statements != NULL) comments_visit(ctx, PM_NODE_UPCAST(cast->statements));
            comments_visit(ctx, cast->predicate);

            const pm_comment_t *opening_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->keyword_loc));
            pm_comments_list_t body_comments_list;
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &body_comments_list);

            if (opening_comment != NULL || trailing_comment != NULL || body_comments_list.size > 0) {
                pm_body_comments_t *c = pm_body_comments_new(ctx, opening_comment, trailing_comment);
                c->body_comments = body_comments_list;
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
            }
            break;
        }
        /*
         *     until a # comment
         *       b
         *     end # comment
         */
        case PM_UNTIL_NODE: {
            pm_until_node_t *cast = (pm_until_node_t *) node;
            const pm_comment_t *trailing_comment = NULL;

            if (comments_loc_set(cast->closing_loc)) {
                trailing_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->closing_loc));
            }
            if (cast->statements != NULL) comments_visit(ctx, PM_NODE_UPCAST(cast->statements));
            comments_visit(ctx, cast->predicate);

            const pm_comment_t *opening_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->keyword_loc));
            pm_comments_list_t body_comments_list;
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &body_comments_list);

            if (opening_comment != NULL || trailing_comment != NULL || body_comments_list.size > 0) {
                pm_body_comments_t *c = pm_body_comments_new(ctx, opening_comment, trailing_comment);
                c->body_comments = body_comments_list;
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
            }
            break;
        }
        /*
         *     while a # comment
         *       b
         *     end # comment
         */
        case PM_WHILE_NODE: {
            pm_while_node_t *cast = (pm_while_node_t *) node;
            const pm_comment_t *trailing_comment = NULL;

            if (comments_loc_set(cast->closing_loc)) {
                trailing_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->closing_loc));
            }
            if (cast->statements != NULL) comments_visit(ctx, PM_NODE_UPCAST(cast->statements));
            comments_visit(ctx, cast->predicate);

            const pm_comment_t *opening_comment = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->keyword_loc));
            pm_comments_list_t body_comments_list;
            comments_claim_comments(ctx, comments_node_start_line(ctx, node), comments_node_end_line(ctx, node), &body_comments_list);

            if (opening_comment != NULL || trailing_comment != NULL || body_comments_list.size > 0) {
                pm_body_comments_t *c = pm_body_comments_new(ctx, opening_comment, trailing_comment);
                c->body_comments = body_comments_list;
                comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(c));
            }
            break;
        }
        /*
         *     yield( # comment
         *       foo
         *     ) # comment
         */
        case PM_YIELD_NODE: {
            pm_yield_node_t *cast = (pm_yield_node_t *) node;

            if (cast->arguments != NULL) {
                const pm_comment_t *rparen = NULL;
                if (comments_loc_set(cast->rparen_loc))
                    rparen = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->rparen_loc));

                comments_visit(ctx, PM_NODE_UPCAST(cast->arguments));

                const pm_comment_t *lparen = NULL;
                if (comments_loc_set(cast->lparen_loc))
                    lparen = comments_claim_comment(ctx, comments_loc_start_line(ctx, cast->lparen_loc));

                if (lparen != NULL || rparen != NULL) {
                    comments_store(ctx, node->node_id, PM_COMMENTS_UPCAST(pm_keyword_call_comments_new(ctx, lparen, rparen)));
                }
            } else {
                comments_attach_leaf_comments(ctx, node);
            }
            break;
        }
    }
}

/**
 * After parsing, traverse the AST and attach each comment to the most
 * appropriate node based on its position in the source.
 *
 * 1. Build a map of comments keyed by their start line
 * 2. Walk the AST, visiting children in reverse order (right-to-left)
 * 3. At each node, claim comments from the map based on line positions
 * 4. Insert CommentNode instances into node lists where appropriate
 */
void
pm_attach_comments(pm_parser_t *parser, pm_node_t *root) {
    /* Allocate the comments map from the metadata arena. */
    pm_comments_map_t *map = pm_arena_alloc(&parser->metadata_arena, sizeof(pm_comments_map_t), PRISM_ALIGNOF(pm_comments_map_t));
    map->size = parser->node_id;
    map->entries = pm_arena_zalloc(&parser->metadata_arena, map->size * sizeof(const pm_comments_t *), PRISM_ALIGNOF(pm_comments_t *));
    parser->comments_map = map;

    /* If there are no comments, then the empty map is enough. */
    if (parser->comment_list.head == NULL) return;

    /* Determine the range of lines that could have comments. */
    int32_t min_line = INT32_MAX;
    int32_t max_line = INT32_MIN;

    for (pm_list_node_t *list_node = parser->comment_list.head; list_node != NULL; list_node = list_node->next) {
        const pm_comment_t *comment = (const pm_comment_t *) list_node;

        int32_t line = pm_line_offset_list_line(&parser->line_offsets, comment->location.start, parser->start_line);
        if (line < min_line) min_line = line;
        if (line > max_line) max_line = line;
    }

    assert(min_line <= max_line);

    /* Build a context object and fill in the comments per line list. */
    const pm_comment_t **comments = xcalloc((size_t) (max_line - min_line + 1), sizeof(pm_comment_t *));
    pm_comments_context_t ctx = {
        .parser = parser,
        .map = map,
        .comments = comments,
        .min_line = min_line,
        .max_line = max_line
    };

    for (pm_list_node_t *list_node = parser->comment_list.head; list_node != NULL; list_node = list_node->next) {
        const pm_comment_t *comment = (const pm_comment_t *) list_node;

        int32_t line = pm_line_offset_list_line(&parser->line_offsets, comment->location.start, parser->start_line);
        ctx.comments[line - min_line] = comment;
    }

    /* Walk the AST and attach comments to nodes. */
    comments_visit(&ctx, root);
    xfree(comments);
}
