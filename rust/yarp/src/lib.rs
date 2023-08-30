//! # yarp
//!
//! Rustified version of Ruby's YARP parser.
//!
#![warn(
    clippy::all,
    clippy::nursery,
    clippy::pedantic,
    future_incompatible,
    missing_docs,
    nonstandard_style,
    rust_2018_idioms,
    trivial_casts,
    trivial_numeric_casts,
    unreachable_pub,
    unused_qualifications
)]

// Most of the code in this file is generated, so sometimes it generates code
// that doesn't follow the clippy rules. We don't want to see those warnings.
#[allow(clippy::too_many_lines, clippy::use_self)]
mod bindings {
    // In `build.rs`, we generate bindings based on the config.yml file. Here is
    // where we pull in those bindings and make them part of our library.
    include!(concat!(env!("OUT_DIR"), "/bindings.rs"));
}

use std::ffi::{CStr, c_char};
use std::marker::PhantomData;
use std::mem::MaybeUninit;
use std::ptr::NonNull;

use yarp_sys::{yp_parser_t, yp_parser_init, yp_parse, yp_parser_free, yp_node_destroy, yp_node_t, yp_comment_t, yp_diagnostic_t};
pub use self::bindings::*;

/// A diagnostic message that came back from the parser.
#[derive(Debug)]
pub struct Diagnostic<'pr> {
    diagnostic: NonNull<yp_diagnostic_t>,
    marker: PhantomData<&'pr yp_diagnostic_t>
}

impl<'pr> Diagnostic<'pr> {
    /// Returns the message associated with the diagnostic.
    /// 
    /// # Panics
    ///
    /// Panics if the message is not able to be converted into a `CStr`.
    ///
    #[must_use]
    pub fn message(&self) -> &str {
        unsafe {
            let message: *mut c_char = self.diagnostic.as_ref().message as *mut c_char;
            CStr::from_ptr(message).to_str().expect("YARP allows only UTF-8 for diagnostics.")
        }
    }
}

/// A comment that was found during parsing.
#[derive(Debug)]
pub struct Comment<'pr> {
    comment: NonNull<yp_comment_t>,
    marker: PhantomData<&'pr yp_comment_t>
}

impl<'pr> Comment<'pr> {
    /// Returns the text of the comment.
    #[must_use]
    pub fn text(&self) -> &[u8] {
        unsafe {
            let start = self.comment.as_ref().start;
            let end = self.comment.as_ref().end;

            let len = usize::try_from(end.offset_from(start)).expect("end should point to memory after start");
            std::slice::from_raw_parts(start, len)
        }
    }
}

/// A struct created by the `errors` or `warnings` methods on `ParseResult`. It
/// can be used to iterate over the diagnostics in the parse result.
pub struct Diagnostics<'pr> {
    diagnostic: *mut yp_diagnostic_t,
    marker: PhantomData<&'pr yp_diagnostic_t>
}

impl<'pr> Iterator for Diagnostics<'pr> {
    type Item = Diagnostic<'pr>;

    fn next(&mut self) -> Option<Self::Item> {
        if let Some(diagnostic) = NonNull::new(self.diagnostic) {
            let current = Diagnostic { diagnostic, marker: PhantomData };
            self.diagnostic = unsafe { diagnostic.as_ref().node.next.cast::<yp_diagnostic_t>() };
            Some(current)
        } else {
            None
        }
    }
}

/// A struct created by the `comments` method on `ParseResult`. It can be used
/// to iterate over the comments in the parse result.
pub struct Comments<'pr> {
    comment: *mut yp_comment_t,
    marker: PhantomData<&'pr yp_comment_t>
}

impl<'pr> Iterator for Comments<'pr> {
    type Item = Comment<'pr>;

    fn next(&mut self) -> Option<Self::Item> {
        if let Some(comment) = NonNull::new(self.comment) {
            let current = Comment { comment, marker: PhantomData };
            self.comment = unsafe { comment.as_ref().node.next.cast::<yp_comment_t>() };
            Some(current)
        } else {
            None
        }
    }
}

/// The result of parsing a source string.
#[derive(Debug)]
pub struct ParseResult<'pr> {
    source: &'pr [u8],
    parser: NonNull<yp_parser_t>,
    node: NonNull<yp_node_t>
}

impl<'pr> ParseResult<'pr> {
    /// Returns the source string that was parsed.
    #[must_use]
    pub const fn source(&self) -> &'pr [u8] {
        self.source
    }

    /// Returns a slice of the source string that was parsed using the given
    /// location range.
    #[must_use]
    pub fn as_slice(&self, location: &Location<'pr>) -> &'pr [u8] {
        let root = self.source.as_ptr();

        let start = usize::try_from(unsafe { location.start().offset_from(root) }).expect("start should point to memory after root");
        let end = usize::try_from(unsafe { location.end().offset_from(root) }).expect("end should point to memory after root");

        &self.source[start..end]
    }

    /// Returns an iterator that can be used to iterate over the errors in the
    /// parse result.
    #[must_use]
    pub fn errors(&self) -> Diagnostics<'_> {
        unsafe {
            let list = &mut (*self.parser.as_ptr()).error_list;
            Diagnostics { diagnostic: list.head.cast::<yp_diagnostic_t>(), marker: PhantomData }
        }
    }

    /// Returns an iterator that can be used to iterate over the warnings in the
    /// parse result.
    #[must_use]
    pub fn warnings(&self) -> Diagnostics<'_> {
        unsafe {
            let list = &mut (*self.parser.as_ptr()).warning_list;
            Diagnostics { diagnostic: list.head.cast::<yp_diagnostic_t>(), marker: PhantomData }
        }
    }

    /// Returns an iterator that can be used to iterate over the comments in the
    /// parse result.
    #[must_use]
    pub fn comments(&self) -> Comments<'_> {
        unsafe {
            let list = &mut (*self.parser.as_ptr()).comment_list;
            Comments { comment: list.head.cast::<yp_comment_t>(), marker: PhantomData }
        }
    }

    /// Returns the root node of the parse result.
    #[must_use]
    pub fn node(&self) -> Node<'pr> {
        Node::new(self.parser, self.node.as_ptr())
    }
}

impl<'pr> Drop for ParseResult<'pr> {
    fn drop(&mut self) {
        unsafe {
            yp_node_destroy(self.parser.as_ptr(), self.node.as_ptr());
            yp_parser_free(self.parser.as_ptr());
            drop(Box::from_raw(self.parser.as_ptr()));
        }
    }
}

/// Parses the given source string and returns a parse result.
/// 
/// # Panics
///
/// Panics if the parser fails to initialize.
///
#[must_use]
pub fn parse(source: &[u8]) -> ParseResult<'_> {
    unsafe {
        let uninit = Box::new(MaybeUninit::<yp_parser_t>::uninit());
        let uninit = Box::into_raw(uninit);

        yp_parser_init(
            (*uninit).as_mut_ptr(),
            source.as_ptr(),
            source.len(),
            std::ptr::null(),
        );

        let parser = (*uninit).assume_init_mut();
        let parser = NonNull::new_unchecked(parser);

        let node = yp_parse(parser.as_ptr());
        let node = NonNull::new_unchecked(node);

        ParseResult { source, parser, node }
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
            let text = std::str::from_utf8(comment.text()).unwrap();
            assert!(text.starts_with("# comment"));
        }
    }

    #[test]
    fn location_test() {
        let source = "111 + 222 + 333";
        let result = parse(source.as_ref());

        let node = result.node();
        let node = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let node = node.as_call_node().unwrap().receiver().unwrap();
        let node = node.as_call_node().unwrap().arguments().unwrap().arguments().iter().next().unwrap();

        let location = node.as_integer_node().unwrap().location();
        let slice = std::str::from_utf8(result.as_slice(&location)).unwrap();

        assert_eq!(slice, "222");

        let location = node.location();
        let slice = std::str::from_utf8(result.as_slice(&location)).unwrap();

        assert_eq!(slice, "222");

        let slice = std::str::from_utf8(location.as_slice()).unwrap();

        assert_eq!(slice, "222");
    }

    #[test]
    fn location_list_test() {
        use super::{
            Visit,
            visit_block_parameters_node, BlockParametersNode
        };

        struct BlockLocalsVisitor {}

        impl Visit<'_> for BlockLocalsVisitor {
            fn visit_block_parameters_node(&mut self, node: &BlockParametersNode<'_>) {
                println!("{:?}", node.locals());
                visit_block_parameters_node(self, node);
            }
        }

        let source = "-> (; foo, bar) {}";
        let result = parse(source.as_ref());

        let mut visitor = BlockLocalsVisitor {};
        visitor.visit(&result.node());
    }

    #[test]
    fn visitor_test() {
        use super::{
            Visit,
            visit_interpolated_regular_expression_node, InterpolatedRegularExpressionNode,
            visit_regular_expression_node, RegularExpressionNode,
        };
    
        struct RegularExpressionVisitor {
            count: usize
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
        let source = "module Foo; x = 1; end";
        let result = parse(source.as_ref());

        let node = result.node();
        let module = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let module = module.as_module_node().unwrap();
        let locals = module.locals().iter().collect::<Vec<_>>();

        assert_eq!(locals.len(), 1);

        assert_eq!(locals[0].as_slice(), b"x");
    }

    #[test]
    fn optional_loc_test() {
        let source = r#"
module Example
  x = call_func(3, 4)
  y = x.call_func 5, 6
end
"#;
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

        let operator_loc = call.operator_loc();
        assert!(operator_loc.is_none());
        let closing_loc = call.closing_loc();
        assert!(closing_loc.is_some());

        let asgn = &writes[1];
        let call = asgn.as_local_variable_write_node().unwrap().value();
        let call = call.as_call_node().unwrap();

        let operator_loc = call.operator_loc();
        assert!(operator_loc.is_some());
        let closing_loc = call.closing_loc();
        assert!(closing_loc.is_none());
    }
}
