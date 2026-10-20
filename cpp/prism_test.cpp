#include "prism_test.hpp"

#include <cstdio>

int main() {
    for (const prism_test::test_case &test : prism_test::registry()) {
        int before = prism_test::failures();
        test.function();
        std::printf("%s %s\n", prism_test::failures() == before ? "ok    " : "FAILED", test.name);
    }

    std::printf("%zu tests, %d failed checks\n", prism_test::registry().size(), prism_test::failures());
    return prism_test::failures() == 0 ? 0 : 1;
}
