/* Each public header is included on its own, without going through prism.h,
 * and one function from each is referenced. If a header does not declare its
 * functions with C linkage, the reference is to a C++-mangled name and this
 * file fails to link. */
#include "prism/arena.h"
#include "prism/ast.h"
#include "prism/buffer.h"
#include "prism/comments.h"
#include "prism/constant_pool.h"
#include "prism/diagnostic.h"
#include "prism/errors_format.h"
#include "prism/json.h"
#include "prism/line_offset_list.h"
#include "prism/magic_comments.h"
#include "prism/node.h"
#include "prism/options.h"
#include "prism/parser.h"
#include "prism/prettyprint.h"
#include "prism/serialize.h"
#include "prism/source.h"
#include "prism/stream.h"
#include "prism/string_query.h"
#include "prism/stringy.h"
#include "prism/version.h"

#include <iostream>

typedef void (*Function)(void);

/* This has external linkage so that every entry is emitted and must resolve at
 * link time, regardless of optimization level. */
Function functions[] = {
    reinterpret_cast<Function>(pm_arena_new),
    reinterpret_cast<Function>(pm_token_type),
    reinterpret_cast<Function>(pm_buffer_new),
    reinterpret_cast<Function>(pm_comment_location),
    reinterpret_cast<Function>(pm_constant_start),
    reinterpret_cast<Function>(pm_diagnostic_type),
    reinterpret_cast<Function>(pm_errors_format),
    reinterpret_cast<Function>(pm_dump_json),
    reinterpret_cast<Function>(pm_line_offset_list_line_column),
    reinterpret_cast<Function>(pm_magic_comment_key),
    reinterpret_cast<Function>(pm_node_type),
    reinterpret_cast<Function>(pm_options_new),
    reinterpret_cast<Function>(pm_parser_new),
    reinterpret_cast<Function>(pm_prettyprint),
    reinterpret_cast<Function>(pm_serialize),
    reinterpret_cast<Function>(pm_source_constant_new),
    reinterpret_cast<Function>(pm_parse_stream),
    reinterpret_cast<Function>(pm_string_query_local),
    reinterpret_cast<Function>(pm_string_init),
    reinterpret_cast<Function>(pm_version)
};

int main() {
    std::cout << pm_version() << std::endl;
    return 0;
}
