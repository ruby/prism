#include "prism_test.hpp"

#include <algorithm>
#include <cstring>
#include <iterator>
#include <string_view>
#include <type_traits>
#include <vector>
#if __cplusplus >= 202002L
#include <ranges>
#endif

/* The ranges are forward ranges of pointers to the C structs. */
using comment_iterator = prism::comment_range::iterator;
static_assert(std::is_same_v<std::iterator_traits<comment_iterator>::iterator_category, std::forward_iterator_tag>);
static_assert(std::is_same_v<std::iterator_traits<comment_iterator>::value_type, const pm_comment_t *>);
static_assert(std::is_default_constructible_v<comment_iterator>);
static_assert(std::is_trivially_copyable_v<comment_iterator>);
static_assert(std::is_same_v<decltype(prism::errors(nullptr)), prism::diagnostic_range>);
static_assert(std::is_same_v<decltype(prism::warnings(nullptr)), prism::diagnostic_range>);
static_assert(std::is_same_v<decltype(prism::comments(nullptr)), prism::comment_range>);
static_assert(std::is_same_v<decltype(prism::magic_comments(nullptr)), prism::magic_comment_range>);
#if __cplusplus >= 202002L
static_assert(std::forward_iterator<comment_iterator>);
static_assert(std::ranges::forward_range<prism::diagnostic_range>);
static_assert(std::ranges::sized_range<prism::comment_range>);
#endif

/* Counts the items in a range by walking it. */
template <typename R> static std::size_t
walked(const R &range) {
    std::size_t count = 0;
    for (auto item : range) {
        (void) item;
        count++;
    }
    return count;
}

PRISM_TEST(constant_names_a_node) {
    prism_test::parse_result result("foo; Bar");

    CHECK(prism::constant(result.parser.get(), prism::cast<pm_call_node_t>(result.statement(0))->name) == "foo");
    CHECK(prism::constant(result.parser.get(), prism::cast<pm_constant_read_node_t>(result.statement(1))->name) == "Bar");
}

PRISM_TEST(slice_returns_the_source_of_a_location) {
    prism_test::parse_result result("foo.bar(1, 2)");
    const pm_call_node_t *call = prism::cast<pm_call_node_t>(result.statement(0));
    const pm_parser_t *parser = result.parser.get();

    CHECK(prism::slice(parser, result.root->location) == "foo.bar(1, 2)");
    CHECK(prism::slice(parser, call->message_loc) == "bar");
    CHECK(prism::slice(parser, call->receiver->location) == "foo");
    CHECK(prism::slice(parser, call->arguments->base.location) == "1, 2");
}

PRISM_TEST(line_column_locates_an_offset) {
    prism_test::parse_result result("foo\n  bar\n");
    const pm_parser_t *parser = result.parser.get();
    pm_line_column_t first = prism::line_column(parser, result.statement(0)->location.start);
    pm_line_column_t second = prism::line_column(parser, result.statement(1)->location.start);

    CHECK(first.line == 1 && first.column == 0);
    CHECK(second.line == 2 && second.column == 2);
}

PRISM_TEST(errors_are_all_visited) {
    std::string_view source = "def (; 1 +; [";
    prism_test::parse_result result(source);
    prism::diagnostic_range errors = prism::errors(result.parser.get());

    CHECK(!errors.empty());
    CHECK(walked(errors) == errors.size());

    for (const pm_diagnostic_t *error : errors) {
        pm_location_t location = pm_diagnostic_location(error);
        CHECK(std::strlen(pm_diagnostic_message(error)) > 0);
        CHECK(location.start + location.length <= source.size());
    }
}

PRISM_TEST(valid_source_has_no_errors) {
    prism_test::parse_result result("x = 1\nx");
    prism::diagnostic_range errors = prism::errors(result.parser.get());

    CHECK(errors.empty());
    CHECK(errors.size() == 0);
    CHECK(errors.begin() == errors.end());
}

PRISM_TEST(warnings_are_separate_from_errors) {
    /* Warns that the addition is useless in a void context. */
    prism_test::parse_result result("1 + 2");

    CHECK(prism::errors(result.parser.get()).empty());
    CHECK(prism::warnings(result.parser.get()).size() == 1);
    CHECK(walked(prism::warnings(result.parser.get())) == 1);
}

PRISM_TEST(comments_are_visited_in_source_order) {
    prism_test::parse_result result("# one\nfoo # two\n=begin\nthree\n=end\n");
    const pm_parser_t *parser = result.parser.get();
    prism::comment_range comments = prism::comments(parser);

    std::vector<std::string_view> texts;
    for (const pm_comment_t *comment : comments) texts.push_back(prism::slice(parser, pm_comment_location(comment)));

    CHECK(comments.size() == 3);
    CHECK(texts.size() == 3);
    CHECK(texts[0] == "# one");
    CHECK(texts[1] == "# two");
    CHECK(texts[2].substr(0, 6) == "=begin");

    auto embdocs = std::count_if(comments.begin(), comments.end(), [](const pm_comment_t *comment) {
        return pm_comment_type(comment) == PM_COMMENT_EMBDOC;
    });
    CHECK(embdocs == 1);
}

PRISM_TEST(magic_comments_have_keys_and_values) {
    prism_test::parse_result result("# frozen_string_literal: true\n# encoding: ascii\n");
    const pm_parser_t *parser = result.parser.get();
    prism::magic_comment_range magic = prism::magic_comments(parser);

    CHECK(magic.size() == 2);

    auto encoding = std::find_if(magic.begin(), magic.end(), [&](const pm_magic_comment_t *comment) {
        return prism::slice(parser, pm_magic_comment_key(comment)) == "encoding";
    });
    CHECK(encoding != magic.end());
    CHECK(encoding != magic.end() && prism::slice(parser, pm_magic_comment_value(*encoding)) == "ascii");
}

PRISM_TEST(ranges_stop_early_with_break) {
    prism_test::parse_result result("# a\n# b\n# c\n# d\n");
    std::size_t seen = 0;

    for (const pm_comment_t *comment : prism::comments(result.parser.get())) {
        seen++;
        if (prism::slice(result.parser.get(), pm_comment_location(comment)) == "# b") break;
    }

    CHECK(seen == 2);
}

PRISM_TEST(range_iterators_advance_both_ways) {
    prism_test::parse_result result("# a\n# b\n");
    prism::comment_range comments = prism::comments(result.parser.get());

    comment_iterator prefix = comments.begin();
    comment_iterator postfix = comments.begin();
    comment_iterator previous = postfix++;

    CHECK(previous == comments.begin());
    CHECK(++prefix == postfix);
    CHECK(++prefix == comments.end());
}

#if __cplusplus >= 202002L
PRISM_TEST(ranges_compose_with_views) {
    prism_test::parse_result result("# a\n=begin\nb\n=end\n# c\n");
    auto inline_comments = prism::comments(result.parser.get()) | std::views::filter([](const pm_comment_t *comment) {
        return pm_comment_type(comment) == PM_COMMENT_INLINE;
    });

    CHECK(std::ranges::distance(inline_comments) == 2);
}
#endif
