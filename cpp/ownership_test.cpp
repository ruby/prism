#include "prism_test.hpp"

#include <string_view>
#include <type_traits>
#include <utility>

/* The deleters are empty, so each owned handle is the size of a pointer. */
static_assert(sizeof(prism::unique_arena) == sizeof(pm_arena_t *));
static_assert(sizeof(prism::unique_parser) == sizeof(pm_parser_t *));
static_assert(sizeof(prism::unique_options) == sizeof(pm_options_t *));
static_assert(sizeof(prism::unique_buffer) == sizeof(pm_buffer_t *));

/* Freeing never throws, which unique_ptr's destructor relies on. */
static_assert(std::is_nothrow_invocable_v<prism::arena_deleter, pm_arena_t *>);
static_assert(std::is_nothrow_invocable_v<prism::parser_deleter, pm_parser_t *>);
static_assert(std::is_nothrow_invocable_v<prism::options_deleter, pm_options_t *>);
static_assert(std::is_nothrow_invocable_v<prism::buffer_deleter, pm_buffer_t *>);

/* Allocation failure aborts instead of throwing. */
static_assert(noexcept(prism::make_arena()));
static_assert(noexcept(prism::make_options()));
static_assert(noexcept(prism::make_buffer()));
static_assert(noexcept(prism::make_parser(nullptr, std::string_view())));

/* Owned handles move but do not copy. */
static_assert(std::is_nothrow_move_constructible_v<prism::unique_parser>);
static_assert(!std::is_copy_constructible_v<prism::unique_parser>);

PRISM_TEST(make_returns_owned_handles) {
    prism::unique_arena arena = prism::make_arena();
    prism::unique_options options = prism::make_options();
    prism::unique_buffer buffer = prism::make_buffer();
    prism::unique_parser parser = prism::make_parser(arena.get(), "1 + 2", options.get());

    CHECK(arena != nullptr);
    CHECK(options != nullptr);
    CHECK(buffer != nullptr);
    CHECK(parser != nullptr);
}

PRISM_TEST(make_parser_parses_the_given_source) {
    prism::unique_arena arena = prism::make_arena();
    prism::unique_parser parser = prism::make_parser(arena.get(), "foo");
    pm_node_t *root = pm_parse(parser.get());

    CHECK(prism::isa<pm_program_node_t>(root));
    CHECK(prism::slice(parser.get(), root->location) == "foo");
}

PRISM_TEST(moving_a_parser_keeps_its_tree_usable) {
    prism::unique_arena arena = prism::make_arena();
    prism::unique_parser original = prism::make_parser(arena.get(), "foo");
    pm_node_t *root = pm_parse(original.get());

    prism::unique_parser moved = std::move(original);
    CHECK(original == nullptr);
    CHECK(prism::slice(moved.get(), root->location) == "foo");
}

PRISM_TEST(options_reach_the_parser) {
    prism::unique_options options = prism::make_options();
    pm_options_filepath_set(options.get(), "example.rb");
    pm_options_line_set(options.get(), 10);

    prism_test::parse_result result("foo\nbar", options.get());
    CHECK(prism::view(*pm_parser_filepath(result.parser.get())) == "example.rb");
    CHECK(prism::line_column(result.parser.get(), result.statement(1)->location.start).line == 11);
}

PRISM_TEST(default_options_start_at_line_one) {
    prism::unique_options options = prism::make_options();
    prism_test::parse_result with_options("foo\nbar", options.get());
    prism_test::parse_result without_options("foo\nbar");

    CHECK(prism::line_column(with_options.parser.get(), with_options.statement(1)->location.start).line == 2);
    CHECK(prism::line_column(without_options.parser.get(), without_options.statement(1)->location.start).line == 2);
}

PRISM_TEST(buffer_view_holds_what_was_written) {
    prism_test::parse_result result("foo");
    prism::unique_buffer buffer = prism::make_buffer();
    CHECK(prism::view(buffer.get()).empty());

    pm_prettyprint(buffer.get(), result.parser.get(), result.root);
    std::string_view text = prism::view(buffer.get());
    CHECK(text.substr(0, 14) == "@ ProgramNode ");
    CHECK(text.size() == pm_buffer_length(buffer.get()));
}
