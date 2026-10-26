#include "prism_test.hpp"

#include <cstdint>
#include <string_view>
#include <utility>

static_assert(noexcept(prism::view(std::declval<const pm_string_t &>())));

PRISM_TEST(view_returns_the_unescaped_bytes) {
    prism_test::parse_result result("\"a\\nb\"; :sym; 'raw\\n'");

    CHECK(prism::view(prism::cast<pm_string_node_t>(result.statement(0))->unescaped) == "a\nb");
    CHECK(prism::view(prism::cast<pm_symbol_node_t>(result.statement(1))->unescaped) == "sym");
    CHECK(prism::view(prism::cast<pm_string_node_t>(result.statement(2))->unescaped) == "raw\\n");
}

PRISM_TEST(view_keeps_embedded_null_bytes) {
    prism_test::parse_result result("\"a\\0b\"");
    std::string_view bytes = prism::view(prism::cast<pm_string_node_t>(result.statement(0))->unescaped);

    CHECK(bytes.size() == 3);
    CHECK(bytes == std::string_view("a\0b", 3));
}

PRISM_TEST(view_of_an_initialized_string) {
    static const uint8_t bytes[] = { 'h', 'i' };
    pm_string_t string;
    pm_string_init(&string, bytes, sizeof(bytes));

    CHECK(prism::view(string) == "hi");
    CHECK(prism::view(string).data() == reinterpret_cast<const char *>(bytes));
}
