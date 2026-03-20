extern "C" {
    #include "prism.h"
}

#include <iostream>

int main() {
    pm_arena_t *arena = pm_arena_new();
    pm_parser_t *parser = pm_parser_new(arena, reinterpret_cast<const uint8_t *>("1 + 2"), 5, NULL);

    pm_node_t *root = pm_parse(parser);
    pm_buffer_t *buffer = pm_buffer_new();

    pm_prettyprint(buffer, parser, root);

    std::string_view view(pm_buffer_value(buffer), pm_buffer_length(buffer));
    std::cout << view << std::endl;

    pm_buffer_free(buffer);
    pm_parser_free(parser);
    pm_arena_free(arena);

    return 0;
}
