#include "prism_test.hpp"

#include <algorithm>
#include <iterator>
#include <type_traits>
#if __cplusplus >= 202002L
#include <ranges>
#endif

/* Every node struct maps to its node type. */
static_assert(prism::node_type_v<pm_call_node_t> == PM_CALL_NODE);
static_assert(prism::node_type_v<pm_program_node_t> == PM_PROGRAM_NODE);
static_assert(prism::node_type_v<pm_yield_node_t> == PM_YIELD_NODE);

/* Only the node structs declared in ast.h are nodes. */
static_assert(prism::is_node_v<pm_call_node_t>);
static_assert(prism::is_node_v<pm_statements_node_t>);
static_assert(!prism::is_node_v<pm_node_t>);
static_assert(!prism::is_node_v<pm_location_t>);
static_assert(!prism::is_node_v<int>);

/* Casts keep the constness of their argument. */
static_assert(std::is_same_v<decltype(prism::cast<pm_call_node_t>(std::declval<pm_node_t *>())), pm_call_node_t *>);
static_assert(std::is_same_v<decltype(prism::cast<pm_call_node_t>(std::declval<const pm_node_t *>())), const pm_call_node_t *>);
static_assert(std::is_same_v<decltype(prism::dyn_cast<pm_call_node_t>(std::declval<pm_node_t *>())), pm_call_node_t *>);
static_assert(std::is_same_v<decltype(prism::dyn_cast<pm_call_node_t>(std::declval<const pm_node_t *>())), const pm_call_node_t *>);
static_assert(std::is_same_v<decltype(prism::upcast(std::declval<pm_call_node_t *>())), pm_node_t *>);
static_assert(std::is_same_v<decltype(prism::upcast(std::declval<const pm_call_node_t *>())), const pm_node_t *>);

/* None of the casts can throw. */
static_assert(noexcept(prism::isa<pm_call_node_t>(std::declval<const pm_node_t *>())));
static_assert(noexcept(prism::cast<pm_call_node_t>(std::declval<pm_node_t *>())));
static_assert(noexcept(prism::dyn_cast<pm_call_node_t>(std::declval<pm_node_t *>())));
static_assert(noexcept(prism::upcast(std::declval<pm_call_node_t *>())));

/* A node_range is a contiguous range of node pointers. */
static_assert(std::is_same_v<decltype(*std::declval<prism::node_range>().begin()), pm_node_t *const &>);
#if __cplusplus >= 202002L
static_assert(std::ranges::contiguous_range<prism::node_range>);
static_assert(std::ranges::sized_range<prism::node_range>);
#endif

PRISM_TEST(isa_matches_only_the_node_type) {
    prism_test::parse_result result("foo; 1");

    CHECK(prism::isa<pm_program_node_t>(result.root));
    CHECK(prism::isa<pm_call_node_t>(result.statement(0)));
    CHECK(!prism::isa<pm_integer_node_t>(result.statement(0)));
    CHECK(prism::isa<pm_integer_node_t>(result.statement(1)));
}

PRISM_TEST(cast_points_at_the_same_node) {
    prism_test::parse_result result("foo");
    pm_node_t *node = result.statement(0);
    const pm_node_t *const_node = node;

    pm_call_node_t *call = prism::cast<pm_call_node_t>(node);
    const pm_call_node_t *const_call = prism::cast<pm_call_node_t>(const_node);

    CHECK(prism::upcast(call) == node);
    CHECK(prism::upcast(const_call) == const_node);
    CHECK(prism::constant(result.parser.get(), call->name) == "foo");
}

PRISM_TEST(dyn_cast_returns_null_on_a_mismatch_or_null) {
    prism_test::parse_result result("foo");
    pm_node_t *node = result.statement(0);
    const pm_node_t *const_node = node;

    CHECK(prism::dyn_cast<pm_call_node_t>(node) == prism::cast<pm_call_node_t>(node));
    CHECK(prism::dyn_cast<pm_call_node_t>(const_node) == prism::cast<pm_call_node_t>(const_node));
    CHECK(prism::dyn_cast<pm_integer_node_t>(node) == nullptr);
    CHECK(prism::dyn_cast<pm_integer_node_t>(const_node) == nullptr);
    CHECK(prism::dyn_cast<pm_call_node_t>(static_cast<pm_node_t *>(nullptr)) == nullptr);
    CHECK(prism::dyn_cast<pm_call_node_t>(static_cast<const pm_node_t *>(nullptr)) == nullptr);
}

PRISM_TEST(dyn_cast_reads_an_optional_child) {
    prism_test::parse_result result("foo.bar; baz");
    const pm_call_node_t *with_receiver = prism::cast<pm_call_node_t>(result.statement(0));
    const pm_call_node_t *without_receiver = prism::cast<pm_call_node_t>(result.statement(1));

    CHECK(prism::dyn_cast<pm_call_node_t>(with_receiver->receiver) != nullptr);
    CHECK(prism::dyn_cast<pm_call_node_t>(without_receiver->receiver) == nullptr);
}

PRISM_TEST(node_range_iterates_in_order) {
    prism_test::parse_result result("a; b; c");
    prism::node_range statements(result.statements());

    CHECK(statements.size() == 3);
    CHECK(!statements.empty());

    const char *names[] = { "a", "b", "c" };
    std::size_t index = 0;
    for (pm_node_t *statement : statements) {
        CHECK(prism::slice(result.parser.get(), statement->location) == names[index++]);
    }
    CHECK(index == 3);
}

PRISM_TEST(node_range_works_with_algorithms) {
    prism_test::parse_result result("a; 1; b; 2; c");
    prism::node_range statements(result.statements());

    CHECK(std::count_if(statements.begin(), statements.end(), prism::isa<pm_integer_node_t>) == 2);
    CHECK(std::distance(statements.begin(), statements.end()) == 5);

    auto found = std::find_if(statements.begin(), statements.end(), prism::isa<pm_integer_node_t>);
    CHECK(found != statements.end() && prism::slice(result.parser.get(), (*found)->location) == "1");
}

PRISM_TEST(node_range_of_an_empty_list) {
    pm_node_list_t list = {};
    prism::node_range nodes(list);

    CHECK(nodes.empty());
    CHECK(nodes.size() == 0);
    CHECK(nodes.begin() == nodes.end());
}

PRISM_TEST(node_range_reads_child_lists) {
    prism_test::parse_result result("foo(1, 2, 3)");
    const pm_call_node_t *call = prism::cast<pm_call_node_t>(result.statement(0));
    prism::node_range arguments(call->arguments->arguments);

    CHECK(arguments.size() == 3);
    CHECK(std::all_of(arguments.begin(), arguments.end(), prism::isa<pm_integer_node_t>));
}
