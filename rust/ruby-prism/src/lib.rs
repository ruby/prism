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
use ruby_prism_sys::{
    pm_buffer_free, pm_buffer_init, pm_buffer_length, pm_buffer_t, pm_buffer_value, pm_comment_t, pm_constant_id_list_t, pm_constant_id_t, pm_diagnostic_t, pm_integer_t, pm_location_t, pm_magic_comment_t, pm_node_destroy, pm_node_list, pm_node_t, pm_options_free, pm_options_read, pm_options_t,
    pm_options_version_t, pm_parse, pm_parser_free, pm_parser_init, pm_parser_t, pm_serialize, pm_serialize_parse,
};

/// A range in the source file.
pub struct Location<'pr> {
    parser: NonNull<pm_parser_t>,
    pub(crate) start: *const u8,
    pub(crate) end: *const u8,
    marker: PhantomData<&'pr [u8]>,
}

impl<'pr> Location<'pr> {
    /// Returns a byte slice for the range.
    #[must_use]
    pub fn as_slice(&self) -> &'pr [u8] {
        unsafe {
            let len = usize::try_from(self.end.offset_from(self.start)).expect("end should point to memory after start");
            std::slice::from_raw_parts(self.start, len)
        }
    }

    /// Return a Location from the given `pm_location_t`.
    #[must_use]
    pub(crate) const fn new(parser: NonNull<pm_parser_t>, loc: &'pr pm_location_t) -> Location<'pr> {
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
    pub fn join(&self, other: &Location<'pr>) -> Option<Location<'pr>> {
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
    #[must_use]
    pub fn start_offset(&self) -> usize {
        unsafe {
            let parser_start = (*self.parser.as_ptr()).start;
            usize::try_from(self.start.offset_from(parser_start)).expect("start should point to memory after the parser's start")
        }
    }

    /// Return the end offset from the beginning of the parsed source.
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
    pub fn iter(&self) -> NodeListIter<'pr> {
        NodeListIter {
            parser: self.parser,
            pointer: self.pointer,
            index: 0,
            marker: PhantomData,
        }
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
    fn new(parser: NonNull<pm_parser_t>, id: pm_constant_id_t) -> Self {
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
    pub fn iter(&self) -> ConstantListIter<'pr> {
        ConstantListIter {
            parser: self.parser,
            pointer: self.pointer,
            index: 0,
            marker: PhantomData,
        }
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

impl<'pr> Integer<'pr> {
    fn new(pointer: *const pm_integer_t) -> Self {
        Integer { pointer, marker: PhantomData }
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
    diagnostic: NonNull<pm_diagnostic_t>,
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
            let message: *mut c_char = self.diagnostic.as_ref().message.cast_mut();
            CStr::from_ptr(message).to_str().expect("prism allows only UTF-8 for diagnostics.")
        }
    }

    /// The location of the diagnostic in the source.
    #[must_use]
    pub fn location(&self) -> Location<'pr> {
        Location::new(self.parser, unsafe { &self.diagnostic.as_ref().location })
    }
}

/// A comment that was found during parsing.
#[derive(Debug)]
pub struct Comment<'pr> {
    comment: NonNull<pm_comment_t>,
    parser: NonNull<pm_parser_t>,
    marker: PhantomData<&'pr pm_comment_t>,
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

    /// The location of the comment in the source.
    #[must_use]
    pub fn location(&self) -> Location<'pr> {
        Location::new(self.parser, unsafe { &self.comment.as_ref().location })
    }
}

/// A magic comment that was found during parsing.
#[derive(Debug)]
pub struct MagicComment<'pr> {
    comment: NonNull<pm_magic_comment_t>,
    marker: PhantomData<&'pr pm_magic_comment_t>,
}

impl<'pr> MagicComment<'pr> {
    /// Returns the text of the comment's key.
    #[must_use]
    pub fn key(&self) -> &[u8] {
        unsafe {
            let start = self.comment.as_ref().key_start;
            let len = self.comment.as_ref().key_length as usize;
            std::slice::from_raw_parts(start, len)
        }
    }

    /// Returns the text of the comment's value.
    #[must_use]
    pub fn value(&self) -> &[u8] {
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
            let current = Diagnostic { diagnostic, parser: self.parser, marker: PhantomData };
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
            let current = Comment { comment, parser: self.parser, marker: PhantomData };
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
    options_string: Vec<u8>,
    options: NonNull<pm_options_t>,
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

    /// Returns the serialized representation of the parse result.
    #[must_use]
    pub fn serialize(&self) -> Vec<u8> {
        let mut buffer = Buffer::default();
        unsafe {
            pm_serialize(self.parser.as_ptr(), self.node.as_ptr(), &mut buffer.buffer);
        }
        buffer.value().into()
    }
}

impl<'pr> Drop for ParseResult<'pr> {
    fn drop(&mut self) {
        unsafe {
            pm_node_destroy(self.parser.as_ptr(), self.node.as_ptr());
            pm_parser_free(self.parser.as_ptr());
            drop(Box::from_raw(self.parser.as_ptr()));

            pm_options_free(self.options.as_ptr());
            drop(Box::from_raw(self.options.as_ptr()));
        }
    }
}

/**
 * A scope of locals surrounding the code that is being parsed.
 */
#[derive(Debug, Default, Clone)]
pub struct OptionsScope {
    /** Flags for the set of forwarding parameters in this scope. */
    pub forwarding_flags: u8,
    /** The names of the locals in the scope. */
    pub locals: Vec<String>,
}

/// The options that can be passed to the parser.
#[allow(clippy::struct_excessive_bools)]
#[derive(Debug, Clone)]
pub struct Options {
    /** The name of the file that is currently being parsed. */
    pub filepath: String,
    /**
     * The line within the file that the parse starts on. This value is
     * 1-indexed.
     */
    pub line: i32,
    /**
     * The name of the encoding that the source file is in. Note that this must
     * correspond to a name that can be found with Encoding.find in Ruby.
     */
    pub encoding: String,
    /**
     * Whether or not the frozen string literal option has been set.
     * May be:
     *  - PM_OPTIONS_FROZEN_STRING_LITERAL_DISABLED
     *  - PM_OPTIONS_FROZEN_STRING_LITERAL_ENABLED
     *  - PM_OPTIONS_FROZEN_STRING_LITERAL_UNSET
     */
    pub frozen_string_literal: Option<bool>,
    /** A bitset of the various options that were set on the command line. */
    pub command_line: u8,
    /**
     * The version of prism that we should be parsing with. This is used to
     * allow consumers to specify which behavior they want in case they need to
     * parse exactly as a specific version of CRuby.
     */
    pub version: pm_options_version_t,
    /**
     * Whether or not the encoding magic comments should be respected. This is a
     * niche use-case where you want to parse a file with a specific encoding
     * but ignore any encoding magic comments at the top of the file.
     */
    pub encoding_locked: bool,
    /**
     * When the file being parsed is the main script, the shebang will be
     * considered for command-line flags (or for implicit -x). The caller needs
     * to pass this information to the parser so that it can behave correctly.
     */
    pub main_script: bool,
    /**
     * When the file being parsed is considered a "partial" script, jumps will
     * not be marked as errors if they are not contained within loops/blocks.
     * This is used in the case that you're parsing a script that you know will
     * be embedded inside another script later, but you do not have that context
     * yet. For example, when parsing an ERB template that will be evaluated
     * inside another script.
     */
    pub partial_script: bool,
    /**
     * Whether or not the parser should freeze the nodes that it creates. This
     * makes it possible to have a deeply frozen AST that is safe to share
     * between concurrency primitives.
     */
    pub freeze: bool,
    /**
     * The scopes surrounding the code that is being parsed. For most parses
     * this will be empty, but for evals it will be the locals that are in scope
     * surrounding the eval. Scopes are ordered from the outermost scope to the
     * innermost one.
     */
    pub scopes: Vec<OptionsScope>,
}

impl Default for Options {
    fn default() -> Self {
        Self {
            filepath: String::new(),
            line: 1,
            encoding: String::new(),
            frozen_string_literal: None,
            command_line: 0,
            version: pm_options_version_t::PM_OPTIONS_VERSION_LATEST,
            encoding_locked: false,
            main_script: true,
            partial_script: false,
            freeze: false,
            scopes: Vec::new(),
        }
    }
}

impl Options {
    #[allow(clippy::cast_possible_truncation)]
    fn to_binary_string(&self) -> Vec<u8> {
        let mut output = Vec::new();

        output.extend((self.filepath.len() as u32).to_ne_bytes());
        output.extend(self.filepath.as_bytes());
        output.extend(self.line.to_ne_bytes());
        output.extend((self.encoding.len() as u32).to_ne_bytes());
        output.extend(self.encoding.as_bytes());
        output.extend(self.frozen_string_literal.map_or_else(|| 0i8, |frozen| if frozen { 1 } else { -1 }).to_ne_bytes());
        output.push(self.command_line);
        output.extend((self.version as u8).to_ne_bytes());
        output.push(self.encoding_locked.into());
        output.push(self.main_script.into());
        output.push(self.partial_script.into());
        output.push(self.freeze.into());
        output.extend((self.scopes.len() as u32).to_ne_bytes());
        for scope in &self.scopes {
            output.extend((scope.locals.len() as u32).to_ne_bytes());
            output.extend(scope.forwarding_flags.to_ne_bytes());
            for local in &scope.locals {
                output.extend((local.len() as u32).to_ne_bytes());
                output.extend(local.as_bytes());
            }
        }
        output
    }
}

struct Buffer {
    buffer: pm_buffer_t,
}

impl Default for Buffer {
    fn default() -> Self {
        let buffer = unsafe {
            let mut uninit = MaybeUninit::<pm_buffer_t>::uninit();
            let initialized = pm_buffer_init(uninit.as_mut_ptr());
            assert!(initialized);
            uninit.assume_init()
        };
        Self { buffer }
    }
}

impl Buffer {
    fn length(&self) -> usize {
        unsafe { pm_buffer_length(&self.buffer) }
    }

    fn value(&self) -> &[u8] {
        unsafe {
            let value = pm_buffer_value(&self.buffer);
            let value = value.cast::<u8>().cast_const();
            std::slice::from_raw_parts(value, self.length())
        }
    }
}

impl Drop for Buffer {
    fn drop(&mut self) {
        unsafe { pm_buffer_free(&mut self.buffer) }
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
    parse_with_options(source, &Options::default())
}

/// Parses the given source string and returns a parse result.
///
/// # Panics
///
/// Panics if the parser fails to initialize.
///
#[must_use]
pub fn parse_with_options<'pr>(source: &'pr [u8], options: &Options) -> ParseResult<'pr> {
    let options_string = options.to_binary_string();
    unsafe {
        let uninit = Box::new(MaybeUninit::<pm_parser_t>::uninit());
        let uninit = Box::into_raw(uninit);

        let options = Box::into_raw(Box::new(MaybeUninit::<pm_options_t>::zeroed()));
        pm_options_read((*options).as_mut_ptr(), options_string.as_ptr().cast());
        let options = NonNull::new((*options).assume_init_mut()).unwrap();

        pm_parser_init((*uninit).as_mut_ptr(), source.as_ptr(), source.len(), options.as_ptr());

        let parser = (*uninit).assume_init_mut();
        let parser = NonNull::new_unchecked(parser);

        let node = pm_parse(parser.as_ptr());
        let node = NonNull::new_unchecked(node);

        ParseResult { source, parser, node, options_string, options }
    }
}

/// Serializes the given source string and returns a parse result.
///
/// # Panics
///
/// Panics if the parser fails to initialize.
#[must_use]
pub fn serialize_parse(source: &[u8], options: &Options) -> Vec<u8> {
    let mut buffer = Buffer::default();
    let opts = options.to_binary_string();
    unsafe {
        pm_serialize_parse(&mut buffer.buffer, source.as_ptr(), source.len(), opts.as_ptr().cast());
    }
    buffer.value().into()
}

#[cfg(test)]
mod tests {
    use super::{parse, parse_with_options, serialize_parse};

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
        let source = r#"
x
"#;
        let result = parse(source.as_ref());

        let node = result.node();
        let call = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let call = call.as_call_node().unwrap();
        assert!(call.is_variable_call());

        let source = r#"
x&.foo
"#;
        let result = parse(source.as_ref());

        let node = result.node();
        let call = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let call = call.as_call_node().unwrap();
        assert!(call.is_safe_navigation());
    }

    #[test]
    fn integer_flags_test() {
        let source = r#"
0b1
"#;
        let result = parse(source.as_ref());

        let node = result.node();
        let i = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let i = i.as_integer_node().unwrap();
        assert!(i.is_binary());
        assert!(!i.is_decimal());
        assert!(!i.is_octal());
        assert!(!i.is_hexadecimal());

        let source = r#"
1
"#;
        let result = parse(source.as_ref());

        let node = result.node();
        let i = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let i = i.as_integer_node().unwrap();
        assert!(!i.is_binary());
        assert!(i.is_decimal());
        assert!(!i.is_octal());
        assert!(!i.is_hexadecimal());

        let source = r#"
0o1
"#;
        let result = parse(source.as_ref());

        let node = result.node();
        let i = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let i = i.as_integer_node().unwrap();
        assert!(!i.is_binary());
        assert!(!i.is_decimal());
        assert!(i.is_octal());
        assert!(!i.is_hexadecimal());

        let source = r#"
0x1
"#;
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
        let source = r#"
0..1
"#;
        let result = parse(source.as_ref());

        let node = result.node();
        let range = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let range = range.as_range_node().unwrap();
        assert!(!range.is_exclude_end());

        let source = r#"
0...1
"#;
        let result = parse(source.as_ref());

        let node = result.node();
        let range = node.as_program_node().unwrap().statements().body().iter().next().unwrap();
        let range = range.as_range_node().unwrap();
        assert!(range.is_exclude_end());
    }

    #[allow(clippy::too_many_lines, clippy::cognitive_complexity)]
    #[test]
    fn regex_flags_test() {
        let source = r#"
/a/i
"#;
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

        let source = r#"
/a/x
"#;
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

        let source = r#"
/a/m
"#;
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

        let source = r#"
/a/e
"#;
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

        let source = r#"
/a/n
"#;
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

        let source = r#"
/a/s
"#;
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

        let source = r#"
/a/u
"#;
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

        let source = r#"
/a/o
"#;
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

        impl<'pr> Visit<'pr> for CountingVisitor {
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

        let source = r#"
module Example
  x = call_func(3, 4)
  y = x.call_func 5, 6
end
"#;
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

        let source = r#"
module Example
  x = call_func(3, 4)
  y = x.call_func 5, 6
end
"#;
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
        let value: i32 = result.node().as_program_node().unwrap().statements().body().iter().next().unwrap().as_integer_node().unwrap().value().try_into().unwrap();

        assert_eq!(value, 10);
    }

    #[test]
    fn float_value_test() {
        let result = parse("1.0".as_ref());
        let value: f64 = result.node().as_program_node().unwrap().statements().body().iter().next().unwrap().as_float_node().unwrap().value();

        assert!((value - 1.0).abs() < f64::EPSILON);
    }

    #[test]
    fn serialize_parse_test() {
        let source = r#"__FILE__"#;
        let options = crate::Options { filepath: "test.rb".to_string(), ..Default::default() };
        let bytes = serialize_parse(source.as_ref(), &options);

        let result = parse_with_options(source.as_bytes(), &options);

        assert_eq!(bytes, result.serialize());

        let expected = r#"@ ProgramNode (location: (1,0)-(1,8))
+-- locals: []
+-- statements:
    @ StatementsNode (location: (1,0)-(1,8))
    +-- body: (length: 1)
        +-- @ SourceFileNode (location: (1,0)-(1,8))
            +-- StringFlags: nil
            +-- filepath: "test.rb"
"#;
        assert_eq!(expected, result.node().pretty_print().as_str());
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
}
