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

use std::ffi::{c_char, CStr};
use std::marker::PhantomData;
use std::mem::MaybeUninit;
use std::ptr::NonNull;

pub use self::bindings::*;
use ruby_prism_sys::{pm_comment_t, pm_comment_type_t, pm_constant_id_list_t, pm_constant_id_t, pm_diagnostic_t, pm_integer_t, pm_location_t, pm_magic_comment_t, pm_node_destroy, pm_node_list, pm_node_t, pm_parse, pm_parser_free, pm_parser_init, pm_parser_t};

/// A range in the source file.
pub struct Location<'pr> {
    parser: NonNull<pm_parser_t>,
    pub(crate) start: *const u8,
    pub(crate) end: *const u8,
    marker: PhantomData<&'pr [u8]>,
}

impl<'pr> Location<'pr> {
    /// Returns a byte slice for the range.
    /// # Panics
    /// Panics if the end offset is not greater than the start offset.
    #[must_use]
    pub fn as_slice(&self) -> &'pr [u8] {
        unsafe {
            let len = usize::try_from(self.end.offset_from(self.start)).expect("end should point to memory after start");
            std::slice::from_raw_parts(self.start, len)
        }
    }

    /// Return a Location from the given `pm_location_t`.
    #[must_use]
    pub(crate) const fn new(parser: NonNull<pm_parser_t>, loc: &'pr pm_location_t) -> Self {
        Location {
            parser,
            start: loc.start,
            end: loc.end,
            marker: PhantomData,
        }
    }

    /// Return a Location starting at self and ending at the end of other.
    /// Returns None if both locations did not originate from the same parser,
    /// or if self starts after other.
    #[must_use]
    pub fn join(&self, other: &Self) -> Option<Self> {
        if self.parser != other.parser || self.start > other.start {
            None
        } else {
            Some(Location {
                parser: self.parser,
                start: self.start,
                end: other.end,
                marker: PhantomData,
            })
        }
    }

    /// Return the start offset from the beginning of the parsed source.
    /// # Panics
    /// Panics if the start offset is not greater than the parser's start.
    #[must_use]
    pub fn start_offset(&self) -> usize {
        unsafe {
            let parser_start = (*self.parser.as_ptr()).start;
            usize::try_from(self.start.offset_from(parser_start)).expect("start should point to memory after the parser's start")
        }
    }

    /// Return the end offset from the beginning of the parsed source.
    /// # Panics
    /// Panics if the end offset is not greater than the parser's start.
    #[must_use]
    pub fn end_offset(&self) -> usize {
        unsafe {
            let parser_start = (*self.parser.as_ptr()).start;
            usize::try_from(self.end.offset_from(parser_start)).expect("end should point to memory after the parser's start")
        }
    }
}

impl std::fmt::Debug for Location<'_> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let slice: &[u8] = self.as_slice();

        let mut visible = String::new();
        visible.push('"');

        for &byte in slice {
            let part: Vec<u8> = std::ascii::escape_default(byte).collect();
            visible.push_str(std::str::from_utf8(&part).unwrap());
        }

        visible.push('"');
        write!(f, "{visible}")
    }
}

/// An iterator over the nodes in a list.
pub struct NodeListIter<'pr> {
    parser: NonNull<pm_parser_t>,
    pointer: NonNull<pm_node_list>,
    index: usize,
    marker: PhantomData<&'pr mut pm_node_list>,
}

impl<'pr> Iterator for NodeListIter<'pr> {
    type Item = Node<'pr>;

    fn next(&mut self) -> Option<Self::Item> {
        if self.index >= unsafe { self.pointer.as_ref().size } {
            None
        } else {
            let node: *mut pm_node_t = unsafe { *(self.pointer.as_ref().nodes.add(self.index)) };
            self.index += 1;
            Some(Node::new(self.parser, node))
        }
    }
}

/// A list of nodes.
pub struct NodeList<'pr> {
    parser: NonNull<pm_parser_t>,
    pointer: NonNull<pm_node_list>,
    marker: PhantomData<&'pr mut pm_node_list>,
}

impl<'pr> NodeList<'pr> {
    /// Returns an iterator over the nodes.
    #[must_use]
    pub const fn iter(&self) -> NodeListIter<'pr> {
        NodeListIter {
            parser: self.parser,
            pointer: self.pointer,
            index: 0,
            marker: PhantomData,
        }
    }

    /// Returns the length of the list.
    #[must_use]
    pub const fn len(&self) -> usize {
        unsafe { self.pointer.as_ref().size }
    }
}

impl<'pr> IntoIterator for &NodeList<'pr> {
    type Item = Node<'pr>;
    type IntoIter = NodeListIter<'pr>;
    fn into_iter(self) -> Self::IntoIter {
        self.iter()
    }
}

impl std::fmt::Debug for NodeList<'_> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?}", self.iter().collect::<Vec<_>>())
    }
}

/// A handle for a constant ID.
pub struct ConstantId<'pr> {
    parser: NonNull<pm_parser_t>,
    id: pm_constant_id_t,
    marker: PhantomData<&'pr mut pm_constant_id_t>,
}

impl<'pr> ConstantId<'pr> {
    const fn new(parser: NonNull<pm_parser_t>, id: pm_constant_id_t) -> Self {
        ConstantId { parser, id, marker: PhantomData }
    }

    /// Returns a byte slice for the constant ID.
    ///
    /// # Panics
    ///
    /// Panics if the constant ID is not found in the constant pool.
    #[must_use]
    pub fn as_slice(&self) -> &'pr [u8] {
        unsafe {
            let pool = &(*self.parser.as_ptr()).constant_pool;
            let constant = &(*pool.constants.add((self.id - 1).try_into().unwrap()));
            std::slice::from_raw_parts(constant.start, constant.length)
        }
    }
}

impl std::fmt::Debug for ConstantId<'_> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?}", self.id)
    }
}

/// An iterator over the constants in a list.
pub struct ConstantListIter<'pr> {
    parser: NonNull<pm_parser_t>,
    pointer: NonNull<pm_constant_id_list_t>,
    index: usize,
    marker: PhantomData<&'pr mut pm_constant_id_list_t>,
}

impl<'pr> Iterator for ConstantListIter<'pr> {
    type Item = ConstantId<'pr>;

    fn next(&mut self) -> Option<Self::Item> {
        if self.index >= unsafe { self.pointer.as_ref().size } {
            None
        } else {
            let constant_id: pm_constant_id_t = unsafe { *(self.pointer.as_ref().ids.add(self.index)) };
            self.index += 1;
            Some(ConstantId::new(self.parser, constant_id))
        }
    }
}

/// A list of constants.
pub struct ConstantList<'pr> {
    /// The raw pointer to the parser where this list came from.
    parser: NonNull<pm_parser_t>,

    /// The raw pointer to the list allocated by prism.
    pointer: NonNull<pm_constant_id_list_t>,

    /// The marker to indicate the lifetime of the pointer.
    marker: PhantomData<&'pr mut pm_constant_id_list_t>,
}

impl<'pr> ConstantList<'pr> {
    /// Returns an iterator over the constants in the list.
    #[must_use]
    pub const fn iter(&self) -> ConstantListIter<'pr> {
        ConstantListIter {
            parser: self.parser,
            pointer: self.pointer,
            index: 0,
            marker: PhantomData,
        }
    }
}

impl<'pr> IntoIterator for &ConstantList<'pr> {
    type Item = ConstantId<'pr>;
    type IntoIter = ConstantListIter<'pr>;
    fn into_iter(self) -> Self::IntoIter {
        self.iter()
    }
}

impl std::fmt::Debug for ConstantList<'_> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?}", self.iter().collect::<Vec<_>>())
    }
}

/// A handle for an arbitarily-sized integer.
pub struct Integer<'pr> {
    /// The raw pointer to the integer allocated by prism.
    pointer: *const pm_integer_t,

    /// The marker to indicate the lifetime of the pointer.
    marker: PhantomData<&'pr mut pm_constant_id_t>,
}

impl Integer<'_> {
    const fn new(pointer: *const pm_integer_t) -> Self {
        Integer { pointer, marker: PhantomData }
    }

    /// Returns the sign and the u32 digits representation of the integer,
    /// ordered least significant digit first.
    #[must_use]
    pub const fn to_u32_digits(&self) -> (bool, &[u32]) {
        let negative = unsafe { (*self.pointer).negative };
        let length = unsafe { (*self.pointer).length };
        let values = unsafe { (*self.pointer).values };

        if values.is_null() {
            let value_ptr = unsafe { std::ptr::addr_of!((*self.pointer).value) };
            let slice = unsafe { std::slice::from_raw_parts(value_ptr, 1) };
            (negative, slice)
        } else {
            let slice = unsafe { std::slice::from_raw_parts(values, length) };
            (negative, slice)
        }
    }
}

impl std::fmt::Debug for Integer<'_> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?}", self.pointer)
    }
}

impl TryInto<i32> for Integer<'_> {
    type Error = ();

    fn try_into(self) -> Result<i32, Self::Error> {
        let negative = unsafe { (*self.pointer).negative };
        let length = unsafe { (*self.pointer).length };

        if length == 0 {
            i32::try_from(unsafe { (*self.pointer).value }).map_or(Err(()), |value| if negative { Ok(-value) } else { Ok(value) })
        } else {
            Err(())
        }
    }
}

/// A diagnostic message that came back from the parser.
#[derive(Debug)]
pub struct Diagnostic<'pr> {
    diag: NonNull<pm_diagnostic_t>,
    parser: NonNull<pm_parser_t>,
    marker: PhantomData<&'pr pm_diagnostic_t>,
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
            let message: *mut c_char = self.diag.as_ref().message.cast_mut();
            CStr::from_ptr(message).to_str().expect("prism allows only UTF-8 for diagnostics.")
        }
    }

    /// The location of the diagnostic in the source.
    #[must_use]
    pub const fn location(&self) -> Location<'pr> {
        Location::new(self.parser, unsafe { &self.diag.as_ref().location })
    }
}

/// A comment that was found during parsing.
#[derive(Debug)]
pub struct Comment<'pr> {
    content: NonNull<pm_comment_t>,
    parser: NonNull<pm_parser_t>,
    marker: PhantomData<&'pr pm_comment_t>,
}

/// The type of the comment
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CommentType {
    /// `InlineComment` corresponds to comments that start with #.
    InlineComment,
    /// `EmbDocComment` corresponds to comments that are surrounded by =begin and =end.
    EmbDocComment,
}

impl<'pr> Comment<'pr> {
    /// Returns the text of the comment.
    ///
    /// # Panics
    /// Panics if the end offset is not greater than the start offset.
    #[must_use]
    pub fn text(&self) -> &[u8] {
        self.location().as_slice()
    }

    /// Returns the type of the comment.
    #[must_use]
    pub fn type_(&self) -> CommentType {
        let type_ = unsafe { self.content.as_ref().type_ };
        if type_ == pm_comment_type_t::PM_COMMENT_EMBDOC {
            CommentType::EmbDocComment
        } else {
            CommentType::InlineComment
        }
    }

    /// The location of the comment in the source.
    #[must_use]
    pub const fn location(&self) -> Location<'pr> {
        Location::new(self.parser, unsafe { &self.content.as_ref().location })
    }
}

/// A magic comment that was found during parsing.
#[derive(Debug)]
pub struct MagicComment<'pr> {
    comment: NonNull<pm_magic_comment_t>,
    marker: PhantomData<&'pr pm_magic_comment_t>,
}

impl MagicComment<'_> {
    /// Returns the text of the comment's key.
    #[must_use]
    pub const fn key(&self) -> &[u8] {
        unsafe {
            let start = self.comment.as_ref().key_start;
            let len = self.comment.as_ref().key_length as usize;
            std::slice::from_raw_parts(start, len)
        }
    }

    /// Returns the text of the comment's value.
    #[must_use]
    pub const fn value(&self) -> &[u8] {
        unsafe {
            let start = self.comment.as_ref().value_start;
            let len = self.comment.as_ref().value_length as usize;
            std::slice::from_raw_parts(start, len)
        }
    }
}

/// A struct created by the `errors` or `warnings` methods on `ParseResult`. It
/// can be used to iterate over the diagnostics in the parse result.
pub struct Diagnostics<'pr> {
    diagnostic: *mut pm_diagnostic_t,
    parser: NonNull<pm_parser_t>,
    marker: PhantomData<&'pr pm_diagnostic_t>,
}

impl<'pr> Iterator for Diagnostics<'pr> {
    type Item = Diagnostic<'pr>;

    fn next(&mut self) -> Option<Self::Item> {
        if let Some(diagnostic) = NonNull::new(self.diagnostic) {
            let current = Diagnostic {
                diag: diagnostic,
                parser: self.parser,
                marker: PhantomData,
            };
            self.diagnostic = unsafe { diagnostic.as_ref().node.next.cast::<pm_diagnostic_t>() };
            Some(current)
        } else {
            None
        }
    }
}

/// A struct created by the `comments` method on `ParseResult`. It can be used
/// to iterate over the comments in the parse result.
pub struct Comments<'pr> {
    comment: *mut pm_comment_t,
    parser: NonNull<pm_parser_t>,
    marker: PhantomData<&'pr pm_comment_t>,
}

impl<'pr> Iterator for Comments<'pr> {
    type Item = Comment<'pr>;

    fn next(&mut self) -> Option<Self::Item> {
        if let Some(comment) = NonNull::new(self.comment) {
            let current = Comment {
                content: comment,
                parser: self.parser,
                marker: PhantomData,
            };
            self.comment = unsafe { comment.as_ref().node.next.cast::<pm_comment_t>() };
            Some(current)
        } else {
            None
        }
    }
}

/// A struct created by the `magic_comments` method on `ParseResult`. It can be used
/// to iterate over the magic comments in the parse result.
pub struct MagicComments<'pr> {
    comment: *mut pm_magic_comment_t,
    marker: PhantomData<&'pr pm_magic_comment_t>,
}

impl<'pr> Iterator for MagicComments<'pr> {
    type Item = MagicComment<'pr>;

    fn next(&mut self) -> Option<Self::Item> {
        if let Some(comment) = NonNull::new(self.comment) {
            let current = MagicComment { comment, marker: PhantomData };
            self.comment = unsafe { comment.as_ref().node.next.cast::<pm_magic_comment_t>() };
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
    parser: NonNull<pm_parser_t>,
    node: NonNull<pm_node_t>,
}

impl<'pr> ParseResult<'pr> {
    /// Returns the source string that was parsed.
    #[must_use]
    pub const fn source(&self) -> &'pr [u8] {
        self.source
    }

    /// Returns whether we found a `frozen_string_literal` magic comment with a true value.
    #[must_use]
    pub fn frozen_string_literals(&self) -> bool {
        unsafe { (*self.parser.as_ptr()).frozen_string_literal == 1 }
    }

    /// Returns a slice of the source string that was parsed using the given
    /// location range.
    ///
    /// # Panics
    /// Panics if start offset or end offset are not valid offsets from the root.
    #[must_use]
    pub fn as_slice(&self, location: &Location<'pr>) -> &'pr [u8] {
        let root = self.source.as_ptr();

        let start = usize::try_from(unsafe { location.start.offset_from(root) }).expect("start should point to memory after root");
        let end = usize::try_from(unsafe { location.end.offset_from(root) }).expect("end should point to memory after root");

        &self.source[start..end]
    }

    /// Returns an iterator that can be used to iterate over the errors in the
    /// parse result.
    #[must_use]
    pub fn errors(&self) -> Diagnostics<'_> {
        unsafe {
            let list = &mut (*self.parser.as_ptr()).error_list;
            Diagnostics {
                diagnostic: list.head.cast::<pm_diagnostic_t>(),
                parser: self.parser,
                marker: PhantomData,
            }
        }
    }

    /// Returns an iterator that can be used to iterate over the warnings in the
    /// parse result.
    #[must_use]
    pub fn warnings(&self) -> Diagnostics<'_> {
        unsafe {
            let list = &mut (*self.parser.as_ptr()).warning_list;
            Diagnostics {
                diagnostic: list.head.cast::<pm_diagnostic_t>(),
                parser: self.parser,
                marker: PhantomData,
            }
        }
    }

    /// Returns an iterator that can be used to iterate over the comments in the
    /// parse result.
    #[must_use]
    pub fn comments(&self) -> Comments<'_> {
        unsafe {
            let list = &mut (*self.parser.as_ptr()).comment_list;
            Comments {
                comment: list.head.cast::<pm_comment_t>(),
                parser: self.parser,
                marker: PhantomData,
            }
        }
    }

    /// Returns an iterator that can be used to iterate over the magic comments in the
    /// parse result.
    #[must_use]
    pub fn magic_comments(&self) -> MagicComments<'_> {
        unsafe {
            let list = &mut (*self.parser.as_ptr()).magic_comment_list;
            MagicComments {
                comment: list.head.cast::<pm_magic_comment_t>(),
                marker: PhantomData,
            }
        }
    }

    /// Returns an optional location of the __END__ marker and the rest of the content of the file.
    #[must_use]
    pub fn data_loc(&self) -> Option<Location<'_>> {
        let location = unsafe { &(*self.parser.as_ptr()).data_loc };
        if location.start.is_null() {
            None
        } else {
            Some(Location::new(self.parser, location))
        }
    }

    /// Returns the root node of the parse result.
    #[must_use]
    pub fn node(&self) -> Node<'_> {
        Node::new(self.parser, self.node.as_ptr())
    }
}

impl Drop for ParseResult<'_> {
    fn drop(&mut self) {
        unsafe {
            pm_node_destroy(self.parser.as_ptr(), self.node.as_ptr());
            pm_parser_free(self.parser.as_ptr());
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
        let uninit = Box::new(MaybeUninit::<pm_parser_t>::uninit());
        let uninit = Box::into_raw(uninit);

        pm_parser_init((*uninit).as_mut_ptr(), source.as_ptr(), source.len(), std::ptr::null());

        let parser = (*uninit).assume_init_mut();
        let parser = NonNull::new_unchecked(parser);

        let node = pm_parse(parser.as_ptr());
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
        assert_eq!(6, location.start_offset());
        assert_eq!(9, location.end_offset());

        let recv_loc = plus.receiver().unwrap().location();
        assert_eq!(recv_loc.as_slice(), b"111");
        assert_eq!(0, recv_loc.start_offset());
        assert_eq!(3, recv_loc.end_offset());

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
        let source = "module Foo; x = 1; end";
        let result = parse(source.as_ref());

        let node = result.node();
        assert_eq!(node.as_program_node().unwrap().statements().body().len(), 1);
        let module = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let module = module.as_module_node().unwrap();
        let locals = module.locals().iter().collect::<Vec<_>>();

        assert_eq!(locals.len(), 1);

        assert_eq!(locals[0].as_slice(), b"x");
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
