#include "prism.h"

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int
main(void) {
    static const char source[] = "def foo = bar(0x1FFFFFFFFFFFFFFFF)\n";

    pm_arena_t *arena = pm_arena_new();
    pm_parser_t *parser = pm_parser_new(arena, (const uint8_t *) source, sizeof(source) - 1, NULL);
    pm_node_t *node = pm_parse(parser);
    int status = EXIT_SUCCESS;

    if (PM_NODE_TYPE(node) != PM_PROGRAM_NODE) {
        printf("expected a program node, got type %d\n", (int) PM_NODE_TYPE(node));
        status = EXIT_FAILURE;
    }

    if (pm_parser_errors_size(parser) != 0) {
        printf("expected no errors, got %zu\n", pm_parser_errors_size(parser));
        status = EXIT_FAILURE;
    }

#ifndef PRISM_EXCLUDE_PRETTYPRINT
    pm_buffer_t *buffer = pm_buffer_new();
    pm_prettyprint(buffer, parser, node);

    const char *haystack = pm_buffer_value(buffer);
    const char *haystack_end = haystack + pm_buffer_length(buffer);
    const char *needle = "36893488147419103231";
    size_t needle_length = strlen(needle);

    bool found = false;

    for (const char *cursor = haystack; !found && (cursor = memchr(cursor, needle[0], (size_t) (haystack_end - cursor))) != NULL; cursor++) {
        found = (size_t) (haystack_end - cursor) >= needle_length && memcmp(cursor, needle, needle_length) == 0;
    }

    if (!found) {
        fprintf(stderr, "expected the pretty-printed tree to contain %s\n", needle);
        status = EXIT_FAILURE;
    }

    pm_buffer_free(buffer);
#endif

    pm_parser_free(parser);
    pm_arena_free(arena);

    if (status == EXIT_SUCCESS) printf("ok\n");
    return status;
}
