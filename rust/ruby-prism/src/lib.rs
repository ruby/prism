//! # ruby-prism
//!
//! Rustified version of Ruby's prism parser.
//!
#![warn(clippy::all, clippy::nursery, clippy::pedantic, future_incompatible, missing_docs, nonstandard_style, rust_2018_idioms, trivial_casts, trivial_numeric_casts, unreachable_pub, unused_qualifications)]

// Most of the code in this file is generated, so sometimes it generates code
// that doesn't follow the clippy rules. We don't want to see those warnings.
#[allow(clippy::too_many_lines, clippy::use_self)]
mod bindings {
    // In `build.rs`, we generate bindings based on the config.yml file. Here is
    // where we pull in those bindings and make them part of our library.
    include!(concat!(env!("OUT_DIR"), "/bindings.rs"));
}

mod node;
mod node_ext;
mod parse_result;

use std::mem::MaybeUninit;
use std::ptr::NonNull;

pub use self::bindings::*;
pub use self::node::{ConstantId, ConstantList, ConstantListIter, Integer, NodeList, NodeListIter};
pub use self::node_ext::ConstantPathError;
pub use self::parse_result::{Comment, CommentType, Comments, Diagnostic, Diagnostics, Location, MagicComment, MagicComments, ParseResult};

use ruby_prism_sys::{pm_parse, pm_parser_init, pm_parser_t};

/// Parses the given source string and returns a parse result.
///
/// # Panics
///
/// Panics if the parser fails to initialize.
///
#[must_use]
pub fn parse(source: &[u8]) -> ParseResult<'_> {
    unsafe {
        let uninit = Box::new(MaybeUninit::<pm_parser_t>::uninit());
        let uninit = Box::into_raw(uninit);

        pm_parser_init((*uninit).as_mut_ptr(), source.as_ptr(), source.len(), std::ptr::null());

        let parser = (*uninit).assume_init_mut();
        let parser = NonNull::new_unchecked(parser);

        let node = pm_parse(parser.as_ptr());
        let node = NonNull::new_unchecked(node);

        ParseResult::new(source, parser, node)
    }
}

#[cfg(test)]
mod tests {
    use super::parse;

    #[test]
    fn comments_test() {
        let source = "# comment 1\n# comment 2\n# comment 3\n";
        let result = parse(source.as_ref());

        for comment in result.comments() {
            assert_eq!(super::CommentType::InlineComment, comment.type_());
            let text = std::str::from_utf8(comment.text()).unwrap();
            assert!(text.starts_with("# comment"));
        }
    }

    #[test]
    fn magic_comments_test() {
        use crate::MagicComment;

        let source = "# typed: ignore\n# typed:true\n#typed: strict\n";
        let result = parse(source.as_ref());

        let comments: Vec<MagicComment<'_>> = result.magic_comments().collect();
        assert_eq!(3, comments.len());

        assert_eq!(b"typed", comments[0].key());
        assert_eq!(b"ignore", comments[0].value());

        assert_eq!(b"typed", comments[1].key());
        assert_eq!(b"true", comments[1].value());

        assert_eq!(b"typed", comments[2].key());
        assert_eq!(b"strict", comments[2].value());
    }

    #[test]
    fn data_loc_test() {
        let source = "1";
        let result = parse(source.as_ref());
        let data_loc = result.data_loc();
        assert!(data_loc.is_none());

        let source = "__END__\nabc\n";
        let result = parse(source.as_ref());
        let data_loc = result.data_loc().unwrap();
        let slice = std::str::from_utf8(result.as_slice(&data_loc)).unwrap();
        assert_eq!(slice, "__END__\nabc\n");

        let source = "1\n2\n3\n__END__\nabc\ndef\n";
        let result = parse(source.as_ref());
        let data_loc = result.data_loc().unwrap();
        let slice = std::str::from_utf8(result.as_slice(&data_loc)).unwrap();
        assert_eq!(slice, "__END__\nabc\ndef\n");
    }

    #[test]
    fn location_test() {
        let source = "111 + 222 + 333";
        let result = parse(source.as_ref());

        let node = result.node();
        let node = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let node = node.as_call_node().unwrap().receiver().unwrap();
        let plus = node.as_call_node().unwrap();
        let node = plus.arguments().unwrap().arguments().iter().next().unwrap();

        let location = node.as_integer_node().unwrap().location();
        let slice = std::str::from_utf8(result.as_slice(&location)).unwrap();

        assert_eq!(slice, "222");
        assert_eq!(6, location.start);
        assert_eq!(9, location.end());

        let recv_loc = plus.receiver().unwrap().location();
        assert_eq!(recv_loc.as_slice(), b"111");
        assert_eq!(0, recv_loc.start);
        assert_eq!(3, recv_loc.end());

        let joined = recv_loc.join(&location).unwrap();
        assert_eq!(joined.as_slice(), b"111 + 222");

        let not_joined = location.join(&recv_loc);
        assert!(not_joined.is_none());

        {
            let result = parse(source.as_ref());
            let node = result.node();
            let node = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
            let node = node.as_call_node().unwrap().receiver().unwrap();
            let plus = node.as_call_node().unwrap();
            let node = plus.arguments().unwrap().arguments().iter().next().unwrap();

            let location = node.as_integer_node().unwrap().location();
            let not_joined = recv_loc.join(&location);
            assert!(not_joined.is_none());

            let not_joined = location.join(&recv_loc);
            assert!(not_joined.is_none());
        }

        let location = node.location();
        let slice = std::str::from_utf8(result.as_slice(&location)).unwrap();

        assert_eq!(slice, "222");

        let slice = std::str::from_utf8(location.as_slice()).unwrap();

        assert_eq!(slice, "222");
    }

    #[test]
    fn visitor_test() {
        use super::{visit_interpolated_regular_expression_node, visit_regular_expression_node, InterpolatedRegularExpressionNode, RegularExpressionNode, Visit};

        struct RegularExpressionVisitor {
            count: usize,
        }

        impl Visit<'_> for RegularExpressionVisitor {
            fn visit_interpolated_regular_expression_node(&mut self, node: &InterpolatedRegularExpressionNode<'_>) {
                self.count += 1;
                visit_interpolated_regular_expression_node(self, node);
            }

            fn visit_regular_expression_node(&mut self, node: &RegularExpressionNode<'_>) {
                self.count += 1;
                visit_regular_expression_node(self, node);
            }
        }

        let source = "# comment 1\n# comment 2\nmodule Foo; class Bar; /abc #{/def/}/; end; end";
        let result = parse(source.as_ref());

        let mut visitor = RegularExpressionVisitor { count: 0 };
        visitor.visit(&result.node());

        assert_eq!(visitor.count, 2);
    }

    #[test]
    fn node_upcast_test() {
        use super::Node;

        let source = "module Foo; end";
        let result = parse(source.as_ref());

        let node = result.node();
        let upcast_node = node.as_program_node().unwrap().as_node();
        assert!(matches!(upcast_node, Node::ProgramNode { .. }));

        let node = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let upcast_node = node.as_module_node().unwrap().as_node();
        assert!(matches!(upcast_node, Node::ModuleNode { .. }));
    }

    #[test]
    fn constant_id_test() {
        let source = "module Foo; x = 1; y = 2; end";
        let result = parse(source.as_ref());

        let node = result.node();
        assert_eq!(node.as_program_node().unwrap().statements().body().len(), 1);
        assert!(!node.as_program_node().unwrap().statements().body().is_empty());
        let module = node.as_program_node().and_then(|pn| pn.statements().body().first()).unwrap();
        let module = module.as_module_node().unwrap();

        assert_eq!(module.locals().len(), 2);
        assert!(!module.locals().is_empty());

        assert_eq!(module.locals().first().unwrap().as_slice(), b"x");
        assert_eq!(module.locals().last().unwrap().as_slice(), b"y");

        let source = "module Foo; end";
        let result = parse(source.as_ref());

        let node = result.node();
        assert_eq!(node.as_program_node().unwrap().statements().body().len(), 1);
        assert!(!node.as_program_node().unwrap().statements().body().is_empty());
        let module = node.as_program_node().and_then(|pn| pn.statements().body().first()).unwrap();
        let module = module.as_module_node().unwrap();

        assert_eq!(module.locals().len(), 0);
        assert!(module.locals().is_empty());
    }

    #[test]
    fn optional_loc_test() {
        let source = r"
module Example
  x = call_func(3, 4)
  y = x.call_func 5, 6
end
";
        let result = parse(source.as_ref());

        let node = result.node();
        let module = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let module = module.as_module_node().unwrap();
        let body = module.body();
        let writes = body.iter().next().unwrap().as_statements_node().unwrap().body().iter().collect::<Vec<_>>();
        assert_eq!(writes.len(), 2);

        let asgn = &writes[0];
        let call = asgn.as_local_variable_write_node().unwrap().value();
        let call = call.as_call_node().unwrap();

        let call_operator_loc = call.call_operator_loc();
        assert!(call_operator_loc.is_none());
        let closing_loc = call.closing_loc();
        assert!(closing_loc.is_some());

        let asgn = &writes[1];
        let call = asgn.as_local_variable_write_node().unwrap().value();
        let call = call.as_call_node().unwrap();

        let call_operator_loc = call.call_operator_loc();
        assert!(call_operator_loc.is_some());
        let closing_loc = call.closing_loc();
        assert!(closing_loc.is_none());
    }

    #[test]
    fn frozen_strings_test() {
        let source = r#"
# frozen_string_literal: true
"foo"
"#;
        let result = parse(source.as_ref());
        assert!(result.frozen_string_literals());

        let source = "3";
        let result = parse(source.as_ref());
        assert!(!result.frozen_string_literals());
    }

    #[test]
    fn string_flags_test() {
        let source = r#"
# frozen_string_literal: true
"foo"
"#;
        let result = parse(source.as_ref());

        let node = result.node();
        let string = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let string = string.as_string_node().unwrap();
        assert!(string.is_frozen());

        let source = r#"
"foo"
"#;
        let result = parse(source.as_ref());

        let node = result.node();
        let string = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let string = string.as_string_node().unwrap();
        assert!(!string.is_frozen());
    }

    #[test]
    fn call_flags_test() {
        let source = r"
x
";
        let result = parse(source.as_ref());

        let node = result.node();
        let call = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let call = call.as_call_node().unwrap();
        assert!(call.is_variable_call());

        let source = r"
x&.foo
";
        let result = parse(source.as_ref());

        let node = result.node();
        let call = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let call = call.as_call_node().unwrap();
        assert!(call.is_safe_navigation());
    }

    #[test]
    fn integer_flags_test() {
        let source = r"
0b1
";
        let result = parse(source.as_ref());

        let node = result.node();
        let i = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let i = i.as_integer_node().unwrap();
        assert!(i.is_binary());
        assert!(!i.is_decimal());
        assert!(!i.is_octal());
        assert!(!i.is_hexadecimal());

        let source = r"
1
";
        let result = parse(source.as_ref());

        let node = result.node();
        let i = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let i = i.as_integer_node().unwrap();
        assert!(!i.is_binary());
        assert!(i.is_decimal());
        assert!(!i.is_octal());
        assert!(!i.is_hexadecimal());

        let source = r"
0o1
";
        let result = parse(source.as_ref());

        let node = result.node();
        let i = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let i = i.as_integer_node().unwrap();
        assert!(!i.is_binary());
        assert!(!i.is_decimal());
        assert!(i.is_octal());
        assert!(!i.is_hexadecimal());

        let source = r"
0x1
";
        let result = parse(source.as_ref());

        let node = result.node();
        let i = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let i = i.as_integer_node().unwrap();
        assert!(!i.is_binary());
        assert!(!i.is_decimal());
        assert!(!i.is_octal());
        assert!(i.is_hexadecimal());
    }

    #[test]
    fn range_flags_test() {
        let source = r"
0..1
";
        let result = parse(source.as_ref());

        let node = result.node();
        let range = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let range = range.as_range_node().unwrap();
        assert!(!range.is_exclude_end());

        let source = r"
0...1
";
        let result = parse(source.as_ref());

        let node = result.node();
        let range = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let range = range.as_range_node().unwrap();
        assert!(range.is_exclude_end());
    }

    #[allow(clippy::too_many_lines, clippy::cognitive_complexity)]
    #[test]
    fn regex_flags_test() {
        let source = r"
/a/i
";
        let result = parse(source.as_ref());

        let node = result.node();
        let regex = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let regex = regex.as_regular_expression_node().unwrap();
        assert!(regex.is_ignore_case());
        assert!(!regex.is_extended());
        assert!(!regex.is_multi_line());
        assert!(!regex.is_euc_jp());
        assert!(!regex.is_ascii_8bit());
        assert!(!regex.is_windows_31j());
        assert!(!regex.is_utf_8());
        assert!(!regex.is_once());

        let source = r"
/a/x
";
        let result = parse(source.as_ref());

        let node = result.node();
        let regex = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let regex = regex.as_regular_expression_node().unwrap();
        assert!(!regex.is_ignore_case());
        assert!(regex.is_extended());
        assert!(!regex.is_multi_line());
        assert!(!regex.is_euc_jp());
        assert!(!regex.is_ascii_8bit());
        assert!(!regex.is_windows_31j());
        assert!(!regex.is_utf_8());
        assert!(!regex.is_once());

        let source = r"
/a/m
";
        let result = parse(source.as_ref());

        let node = result.node();
        let regex = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let regex = regex.as_regular_expression_node().unwrap();
        assert!(!regex.is_ignore_case());
        assert!(!regex.is_extended());
        assert!(regex.is_multi_line());
        assert!(!regex.is_euc_jp());
        assert!(!regex.is_ascii_8bit());
        assert!(!regex.is_windows_31j());
        assert!(!regex.is_utf_8());
        assert!(!regex.is_once());

        let source = r"
/a/e
";
        let result = parse(source.as_ref());

        let node = result.node();
        let regex = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let regex = regex.as_regular_expression_node().unwrap();
        assert!(!regex.is_ignore_case());
        assert!(!regex.is_extended());
        assert!(!regex.is_multi_line());
        assert!(regex.is_euc_jp());
        assert!(!regex.is_ascii_8bit());
        assert!(!regex.is_windows_31j());
        assert!(!regex.is_utf_8());
        assert!(!regex.is_once());

        let source = r"
/a/n
";
        let result = parse(source.as_ref());

        let node = result.node();
        let regex = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let regex = regex.as_regular_expression_node().unwrap();
        assert!(!regex.is_ignore_case());
        assert!(!regex.is_extended());
        assert!(!regex.is_multi_line());
        assert!(!regex.is_euc_jp());
        assert!(regex.is_ascii_8bit());
        assert!(!regex.is_windows_31j());
        assert!(!regex.is_utf_8());
        assert!(!regex.is_once());

        let source = r"
/a/s
";
        let result = parse(source.as_ref());

        let node = result.node();
        let regex = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let regex = regex.as_regular_expression_node().unwrap();
        assert!(!regex.is_ignore_case());
        assert!(!regex.is_extended());
        assert!(!regex.is_multi_line());
        assert!(!regex.is_euc_jp());
        assert!(!regex.is_ascii_8bit());
        assert!(regex.is_windows_31j());
        assert!(!regex.is_utf_8());
        assert!(!regex.is_once());

        let source = r"
/a/u
";
        let result = parse(source.as_ref());

        let node = result.node();
        let regex = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let regex = regex.as_regular_expression_node().unwrap();
        assert!(!regex.is_ignore_case());
        assert!(!regex.is_extended());
        assert!(!regex.is_multi_line());
        assert!(!regex.is_euc_jp());
        assert!(!regex.is_ascii_8bit());
        assert!(!regex.is_windows_31j());
        assert!(regex.is_utf_8());
        assert!(!regex.is_once());

        let source = r"
/a/o
";
        let result = parse(source.as_ref());

        let node = result.node();
        let regex = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let regex = regex.as_regular_expression_node().unwrap();
        assert!(!regex.is_ignore_case());
        assert!(!regex.is_extended());
        assert!(!regex.is_multi_line());
        assert!(!regex.is_euc_jp());
        assert!(!regex.is_ascii_8bit());
        assert!(!regex.is_windows_31j());
        assert!(!regex.is_utf_8());
        assert!(regex.is_once());
    }

    #[test]
    fn visitor_traversal_test() {
        use crate::{Node, Visit};

        #[derive(Default)]
        struct NodeCounts {
            pre_parent: usize,
            post_parent: usize,
            pre_leaf: usize,
            post_leaf: usize,
        }

        #[derive(Default)]
        struct CountingVisitor {
            counts: NodeCounts,
        }

        impl Visit<'_> for CountingVisitor {
            fn visit_branch_node_enter(&mut self, _node: Node<'_>) {
                self.counts.pre_parent += 1;
            }

            fn visit_branch_node_leave(&mut self) {
                self.counts.post_parent += 1;
            }

            fn visit_leaf_node_enter(&mut self, _node: Node<'_>) {
                self.counts.pre_leaf += 1;
            }

            fn visit_leaf_node_leave(&mut self) {
                self.counts.post_leaf += 1;
            }
        }

        let source = r"
module Example
  x = call_func(3, 4)
  y = x.call_func 5, 6
end
";
        let result = parse(source.as_ref());
        let node = result.node();
        let mut visitor = CountingVisitor::default();
        visitor.visit(&node);

        assert_eq!(7, visitor.counts.pre_parent);
        assert_eq!(7, visitor.counts.post_parent);
        assert_eq!(6, visitor.counts.pre_leaf);
        assert_eq!(6, visitor.counts.post_leaf);
    }

    #[test]
    fn visitor_lifetime_test() {
        use crate::{Node, Visit};

        #[derive(Default)]
        struct StackingNodeVisitor<'a> {
            stack: Vec<Node<'a>>,
            max_depth: usize,
        }

        impl<'pr> Visit<'pr> for StackingNodeVisitor<'pr> {
            fn visit_branch_node_enter(&mut self, node: Node<'pr>) {
                self.stack.push(node);
            }

            fn visit_branch_node_leave(&mut self) {
                self.stack.pop();
            }

            fn visit_leaf_node_leave(&mut self) {
                self.max_depth = self.max_depth.max(self.stack.len());
            }
        }

        let source = r"
module Example
  x = call_func(3, 4)
  y = x.call_func 5, 6
end
";
        let result = parse(source.as_ref());
        let node = result.node();
        let mut visitor = StackingNodeVisitor::default();
        visitor.visit(&node);

        assert_eq!(0, visitor.stack.len());
        assert_eq!(5, visitor.max_depth);
    }

    #[test]
    fn integer_value_test() {
        let result = parse("0xA".as_ref());
        let integer = result.node().as_program_node().unwrap().statements().body().iter().next().unwrap().as_integer_node().unwrap().value();
        let value: i32 = integer.try_into().unwrap();

        assert_eq!(value, 10);
    }

    #[test]
    fn integer_small_value_to_u32_digits_test() {
        let result = parse("0xA".as_ref());
        let integer = result.node().as_program_node().unwrap().statements().body().iter().next().unwrap().as_integer_node().unwrap().value();
        let (negative, digits) = integer.to_u32_digits();

        assert!(!negative);
        assert_eq!(digits, &[10]);
    }

    #[test]
    fn integer_large_value_to_u32_digits_test() {
        let result = parse("0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF".as_ref());
        let integer = result.node().as_program_node().unwrap().statements().body().iter().next().unwrap().as_integer_node().unwrap().value();
        let (negative, digits) = integer.to_u32_digits();

        assert!(!negative);
        assert_eq!(digits, &[4_294_967_295, 4_294_967_295, 4_294_967_295, 2_147_483_647]);
    }

    #[test]
    fn float_value_test() {
        let result = parse("1.0".as_ref());
        let value: f64 = result.node().as_program_node().unwrap().statements().body().iter().next().unwrap().as_float_node().unwrap().value();

        assert!((value - 1.0).abs() < f64::EPSILON);
    }

    #[test]
    fn regex_value_test() {
        let result = parse(b"//");
        let node = result.node().as_program_node().unwrap().statements().body().iter().next().unwrap().as_regular_expression_node().unwrap();
        assert_eq!(node.unescaped(), b"");
    }

    #[test]
    fn node_field_lifetime_test() {
        // The code below wouldn't typecheck prior to https://github.com/ruby/prism/pull/2519,
        // but we need to stop clippy from complaining about it.
        #![allow(clippy::needless_pass_by_value)]

        use crate::Node;

        #[derive(Default)]
        struct Extract<'pr> {
            scopes: Vec<crate::ConstantId<'pr>>,
        }

        impl<'pr> Extract<'pr> {
            fn push_scope(&mut self, path: Node<'pr>) {
                if let Some(cread) = path.as_constant_read_node() {
                    self.scopes.push(cread.name());
                } else if let Some(cpath) = path.as_constant_path_node() {
                    if let Some(parent) = cpath.parent() {
                        self.push_scope(parent);
                    }
                    self.scopes.push(cpath.name().unwrap());
                } else {
                    panic!("Wrong node kind!");
                }
            }
        }

        let source = "Some::Random::Constant";
        let result = parse(source.as_ref());
        let node = result.node();
        let mut extractor = Extract::default();
        extractor.push_scope(node.as_program_node().unwrap().statements().body().iter().next().unwrap());
        assert_eq!(3, extractor.scopes.len());
    }

    #[test]
    fn malformed_shebang() {
        let source = "#!\x00";
        let result = parse(source.as_ref());
        assert!(result.errors().next().is_none());
        assert!(result.warnings().next().is_none());
    }
}
