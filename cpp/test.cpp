extern "C" {
    #include "prism.h"
}

#include <iostream>

int main() {
    pm_parser_t parser;
    pm_parser_init(&parser, reinterpret_cast<const uint8_t *>("1 + 2"), 5, NULL);

    pm_node_t *root = pm_parse(&parser);
    pm_buffer_t buffer = { 0 };

    pm_prettyprint(&buffer, &parser, root);
    pm_buffer_append_byte(&buffer, '\0');

    std::cout << buffer.value << std::endl;

    pm_buffer_free(&buffer);
    pm_node_destroy(&parser, root);
    pm_parser_free(&parser);

    return 0;
}
