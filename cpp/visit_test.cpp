#include "prism_test.hpp"

#include <cstddef>
#include <stdexcept>
#include <string_view>
#include <vector>

static pm_visit_result_t
descend(const pm_node_t *) {
    return PM_VISIT_DESCEND;
}

/* A visitor that keeps state in itself, to check that the walk calls the
 * caller's object rather than a copy of it. */
struct counter {
    std::size_t count = 0;

    pm_visit_result_t
    operator()(const pm_node_t *) {
        count++;
        return PM_VISIT_DESCEND;
    }
};

PRISM_TEST(visit_node_visits_every_node) {
    /* ProgramNode, StatementsNode, CallNode, ArgumentsNode, IntegerNode */
    prism_test::parse_result result("foo(1)");
    std::size_t count = 0;

    bool completed = prism::visit_node(result.root, [&](const pm_node_t *) {
        count++;
        return PM_VISIT_DESCEND;
    });

    CHECK(completed);
    CHECK(count == 5);
}

PRISM_TEST(visit_node_visits_in_pre_order) {
    prism_test::parse_result result("foo(bar)");
    std::vector<pm_node_type_t> types;

    prism::visit_node(result.root, [&](const pm_node_t *node) {
        types.push_back(node->type);
        return PM_VISIT_DESCEND;
    });

    std::vector<pm_node_type_t> expected = { PM_PROGRAM_NODE, PM_STATEMENTS_NODE, PM_CALL_NODE, PM_ARGUMENTS_NODE, PM_CALL_NODE };
    CHECK(types == expected);
}

PRISM_TEST(visit_node_skips_children) {
    prism_test::parse_result result("foo(bar(baz)); qux");
    std::size_t count = 0;

    bool completed = prism::visit_node(result.root, [&](const pm_node_t *node) {
        count++;
        return prism::isa<pm_call_node_t>(node) ? PM_VISIT_SKIP : PM_VISIT_DESCEND;
    });

    /* ProgramNode, StatementsNode, and the two top-level calls. */
    CHECK(completed);
    CHECK(count == 4);
}

PRISM_TEST(visit_node_stops_the_whole_walk) {
    prism_test::parse_result result("a; b(1); c; d");
    std::size_t count = 0;
    const pm_node_t *found = nullptr;

    bool completed = prism::visit_node(result.root, [&](const pm_node_t *node) {
        count++;
        const pm_call_node_t *call = prism::dyn_cast<pm_call_node_t>(node);

        if (call != nullptr && call->arguments != nullptr) {
            found = node;
            return PM_VISIT_STOP;
        }

        return PM_VISIT_DESCEND;
    });

    /* ProgramNode, StatementsNode, a, and then b, where the walk stops. */
    CHECK(!completed);
    CHECK(count == 4);
    CHECK(found != nullptr && prism::slice(result.parser.get(), found->location) == "b(1)");
}

PRISM_TEST(visit_child_nodes_skips_the_node_itself) {
    prism_test::parse_result result("a; b");
    std::size_t count = 0;

    bool completed = prism::visit_child_nodes(result.root, [&](const pm_node_t *node) {
        count++;
        CHECK(node != result.root);
        return PM_VISIT_DESCEND;
    });

    /* StatementsNode and the two calls. */
    CHECK(completed);
    CHECK(count == 3);
}

PRISM_TEST(visit_child_nodes_stops_the_whole_walk) {
    prism_test::parse_result result("a; b; c");
    std::size_t count = 0;

    bool completed = prism::visit_child_nodes(result.root, [&](const pm_node_t *node) {
        count++;
        return prism::isa<pm_call_node_t>(node) ? PM_VISIT_STOP : PM_VISIT_DESCEND;
    });

    CHECK(!completed);
    CHECK(count == 2);
}

PRISM_TEST(visit_node_accepts_any_callable) {
    prism_test::parse_result result("foo(1)");

    /* A function by name and by pointer. */
    CHECK(prism::visit_node(result.root, descend));
    CHECK(prism::visit_node(result.root, &descend));

    /* An object passed by reference keeps the state it accumulates. */
    counter visitor;
    prism::visit_node(result.root, visitor);
    CHECK(visitor.count == 5);

    /* A const lambda and a mutable one. */
    const auto const_lambda = [](const pm_node_t *) { return PM_VISIT_DESCEND; };
    CHECK(prism::visit_node(result.root, const_lambda));

    std::size_t count = 0;
    auto mutable_lambda = [count](const pm_node_t *) mutable { count++; return PM_VISIT_DESCEND; };
    CHECK(prism::visit_node(result.root, mutable_lambda));
}

#ifdef PRISM_HAS_EXCEPTIONS

struct found_it : std::runtime_error {
    using std::runtime_error::runtime_error;
};

PRISM_TEST(visit_node_propagates_exceptions) {
    prism_test::parse_result result("a; b(1); c");
    std::size_t count = 0;
    bool caught = false;

    try {
        prism::visit_node(result.root, [&](const pm_node_t *node) {
            count++;
            const pm_call_node_t *call = prism::dyn_cast<pm_call_node_t>(node);
            if (call != nullptr && call->arguments != nullptr) throw found_it("b(1)");
            return PM_VISIT_DESCEND;
        });
    } catch (const found_it &error) {
        caught = std::string_view(error.what()) == "b(1)";
    }

    /* The walk stops at the throw: nothing after b(1) is visited. */
    CHECK(caught);
    CHECK(count == 4);
}

PRISM_TEST(visit_child_nodes_propagates_exceptions_of_any_type) {
    prism_test::parse_result result("a; b");
    int caught = 0;

    try {
        prism::visit_child_nodes(result.root, [](const pm_node_t *) -> pm_visit_result_t { throw 42; });
    } catch (int value) {
        caught = value;
    }

    CHECK(caught == 42);
}

PRISM_TEST(visit_node_is_reusable_after_an_exception) {
    prism_test::parse_result result("foo(1)");

    try {
        prism::visit_node(result.root, [](const pm_node_t *) -> pm_visit_result_t { throw 1; });
    } catch (int) {
    }

    counter visitor;
    CHECK(prism::visit_node(result.root, visitor));
    CHECK(visitor.count == 5);
}

#endif
