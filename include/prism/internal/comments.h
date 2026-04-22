#ifndef PRISM_INTERNAL_COMMENTS_H
#define PRISM_INTERNAL_COMMENTS_H

#include "prism/comments.h"
#include "prism/parser.h"

#include "prism/internal/list.h"

/* A comment found while parsing. */
struct pm_comment_t {
    /* The embedded base node. */
    pm_list_node_t node;

    /* The location of the comment in the source. */
    pm_location_t location;

    /* The type of the comment. */
    pm_comment_type_t type;
};

/**
 * The comment attachment map, storing pointers indexed by node_id.
 */
typedef struct {
    const pm_comments_t **entries;
    size_t size;
} pm_comments_map_t;

/**
 * Attach comments to the AST. This modifies the AST in place and populates the
 * comment map on the parser.
 */
void pm_attach_comments(pm_parser_t *parser, pm_node_t *root);

#endif
