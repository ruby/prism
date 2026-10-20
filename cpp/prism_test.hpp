/* A minimal test harness for the C++ interface, so that the tests build with
 * nothing but a C++17 compiler and prism itself. Each *_test.cpp file
 * registers its tests with PRISM_TEST, and prism_test.cpp runs them all. */
#ifndef PRISM_TEST_HPP
#define PRISM_TEST_HPP

#include "prism.hpp"

#include <cstdio>
#include <string_view>
#include <vector>

namespace prism_test {

/* A registered test. */
struct test_case {
    const char *name;
    void (*function)();
};

/* Every registered test, in the order the files registered them. This is a
 * function-local static so that it exists before any registration runs,
 * whatever order the files are initialized in. */
inline std::vector<test_case> &
registry() {
    static std::vector<test_case> cases;
    return cases;
}

/* The number of checks that have failed so far. */
inline int &
failures() {
    static int count = 0;
    return count;
}

/* Adds a test to the registry when the file that defines it is initialized. */
struct registrar {
    registrar(const char *name, void (*function)()) {
        registry().push_back(test_case { name, function });
    }
};

/* Records a failed check without stopping the test, so one run reports every
 * failure. */
inline void
check(bool passed, const char *expression, const char *file, int line) {
    if (!passed) {
        failures()++;
        std::fprintf(stderr, "%s:%d: check failed: %s\n", file, line, expression);
    }
}

/* A parsed source, owning everything its tree refers to. The arena is declared
 * first so that it is destroyed after the parser that allocates from it. */
struct parse_result {
    prism::unique_arena arena = prism::make_arena();
    prism::unique_parser parser;
    pm_node_t *root;

    explicit parse_result(std::string_view source, const pm_options_t *options = nullptr) :
        parser(prism::make_parser(arena.get(), source, options)),
        root(pm_parse(parser.get())) {}

    /* The statements at the top level of the program. */
    pm_node_list_t &
    statements() const {
        return prism::cast<pm_program_node_t>(root)->statements->body;
    }

    /* The top-level statement at the given index. */
    pm_node_t *
    statement(std::size_t index) const {
        return statements().nodes[index];
    }
};

}

/* Defines and registers a test. */
#define PRISM_TEST(name) \
    static void name(); \
    static const prism_test::registrar name##_registrar(#name, name); \
    static void name()

/* Checks that the given condition holds, recording a failure otherwise. */
#define CHECK(condition) prism_test::check((condition), #condition, __FILE__, __LINE__)

#endif
